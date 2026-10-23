"""Rig R15 do Roblox no Blender + export de animação para o Studio (sem FBX).

Uso num gerador (headless ou pelo MCP do Blender):

    import sys; sys.path.insert(0, r"<repo>/animations/scripts")
    import r15_lib
    arm = r15_lib.build_rig()                      # cena nova com o rig + blocos do corpo
    r15_lib.key(arm, 0, {"RightShoulder": (90, 0, 0)})   # graus, eixos do ROBLOX
    r15_lib.export_json(arm, "minha_anim", loop=False)   # → animations/exports/minha_anim.anim.json

Depois, no Studio: studio-tools/anim_import.luau (via MCP) monta a KeyframeSequence.

Convenções
- Bones têm o nome da JUNTA do Roblox (RightShoulder, Root, Waist...), não da parte.
  O nome da parte (Part1) fica em bone["part"].
- 1 unidade do Blender = 1 stud. Pés no chão (z = 0), personagem olhando para -Y
  (vista frontal do Blender mostra o rosto).
- Eixos Roblox → Blender: (x, y, z)_rbx = (-x, z, y)_bl. Por isso `key()` recebe
  rotações nos eixos do Roblox (X = arfagem, Y = guinada, Z = rolagem, no espaço da junta,
  que em repouso é o do HumanoidRootPart). Animar à mão no Blender também funciona: o
  export converte qualquer pose.
- Export = Pose.CFrame (o Transform da junta): T = Rrest · basis · Rrestᵀ, convertido de
  eixo. Amostra todo frame (Easing Linear) → fiel às curvas Bezier do Blender.
"""

import json
import math
import os

import bpy
from mathutils import Euler, Matrix, Quaternion, Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RIG_JSON = os.path.join(ROOT, "animations", "rig", "r15_rig.json")
EXPORTS = os.path.join(ROOT, "animations", "exports")

# Blender ↔ Roblox (simétrica e involutiva: M = M⁻¹).
M = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))


def load_rig():
    with open(RIG_JSON, encoding="utf-8") as f:
        return json.load(f)


def _to_bl(v, ground):
    return Vector((-v[0], v[2], v[1] + ground))


def build_rig(clear=True, with_mesh=True):
    """Cria o armature R15 (bones = juntas) e os blocos do corpo presos aos bones."""
    rig = load_rig()
    if clear:
        _clear_scene()
    ground = rig["hipHeight"] + rig["rootHalfHeight"]
    parts = rig["parts"]
    joints = rig["joints"]
    by_part0 = {}
    for j in joints:
        by_part0.setdefault(j["part0"], []).append(j)

    data = bpy.data.armatures.new("R15")
    arm = bpy.data.objects.new("R15", data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    arm.select_set(True)
    data.display_type = "STICK"
    arm.show_in_front = True
    bpy.ops.object.mode_set(mode="EDIT")

    eb = data.edit_bones
    root = eb.new("HumanoidRootPart")
    root.head = _to_bl(parts["HumanoidRootPart"]["center"], ground)
    root.tail = root.head + Vector((0, 0.6, 0))  # aponta para trás, não atrapalha a vista
    part_bone = {"HumanoidRootPart": "HumanoidRootPart"}

    for j in joints:  # ordem do JSON já é pai antes de filho
        b = eb.new(j["name"])
        head = Vector(j["pivot"])
        children = by_part0.get(j["part1"], [])
        if children:  # 1º filho no JSON: Waist (quadril), Neck (tronco), cotovelo, joelho...
            tail = Vector(children[0]["pivot"])
        else:
            center = Vector(parts[j["part1"]]["center"])
            tail = head + (center - head) * 2
        b.head = _to_bl(head, ground)
        b.tail = _to_bl(tail, ground)
        if (b.tail - b.head).length < 1e-3:
            b.tail = b.head + Vector((0, 0, 0.3))
        b.parent = eb[part_bone[j["part0"]]]
        part_bone[j["part1"]] = j["name"]

    bpy.ops.object.mode_set(mode="OBJECT")
    for j in joints:
        data.bones[j["name"]]["part"] = j["part1"]
        data.bones[j["name"]]["part0"] = j["part0"]
    data.bones["HumanoidRootPart"]["part"] = "HumanoidRootPart"
    for pb in arm.pose.bones:
        # Quaternion: Euler no espaço de um bone inclinado (ombro) interpola fora do eixo e o
        # braço "rebola" no meio do movimento.
        pb.rotation_mode = "QUATERNION"

    if with_mesh:
        _build_body(arm, parts, part_bone, ground)
    bpy.context.scene.render.fps = 24
    return arm


def _clear_scene():
    # Não usar wm.read_factory_settings: no Blender aberto ele recarrega os addons e derruba o
    # servidor do MCP.
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    for coll in (bpy.data.armatures, bpy.data.meshes, bpy.data.materials, bpy.data.actions, bpy.data.cameras):
        for item in list(coll):
            if item.users == 0:
                coll.remove(item)


def _build_body(arm, parts, part_bone, ground):
    mat = bpy.data.materials.new("Corpo")
    mat.diffuse_color = (0.75, 0.62, 0.5, 1)
    head_mat = bpy.data.materials.new("Cabeca")
    head_mat.diffuse_color = (0.95, 0.8, 0.3, 1)
    for name, p in parts.items():
        if name == "HumanoidRootPart":
            continue
        bpy.ops.mesh.primitive_cube_add(size=1, location=_to_bl(p["center"], ground))
        ob = bpy.context.active_object
        ob.name = "Parte_" + name
        sx, sy, sz = p["size"]
        ob.scale = (sx, sz, sy)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        ob.data.materials.append(head_mat if name == "Head" else mat)
        if name == "Head":  # nariz: mostra para onde a cabeça olha
            bpy.ops.mesh.primitive_cube_add(size=0.25, location=ob.location + Vector((0, -0.62, 0)))
            nose = bpy.context.active_object
            nose.name = "Parte_Head_Nariz"
            nose.data.materials.append(mat)
            _parent_to_bone(nose, arm, part_bone[name])
        _parent_to_bone(ob, arm, part_bone[name])
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = arm


def _parent_to_bone(ob, arm, bone_name):
    # Sem o update, matrix_world do objeto recém-criado e a pose do bone ainda não foram
    # avaliados (headless) e a parte cai na origem.
    bpy.context.view_layer.update()
    world = ob.matrix_world.copy()
    ob.parent = arm
    ob.parent_type = "BONE"
    ob.parent_bone = bone_name
    ob.matrix_world = world


def rbx_to_basis(arm, bone_name, rot_deg=(0, 0, 0), pos=(0, 0, 0)):
    """Rotação/posição nos eixos do Roblox (espaço da junta) → matrix_basis do bone."""
    rest = arm.data.bones[bone_name].matrix_local.to_3x3()
    rx, ry, rz = (math.radians(a) for a in rot_deg)
    # CFrame.Angles(rx, ry, rz) = Rx·Ry·Rz (o Euler "XYZ" do Blender é Rz·Ry·Rx).
    r_rbx = Matrix.Rotation(rx, 3, "X") @ Matrix.Rotation(ry, 3, "Y") @ Matrix.Rotation(rz, 3, "Z")
    r_arm = M @ r_rbx @ M
    basis = rest.transposed() @ r_arm @ rest
    t = rest.transposed() @ (M @ Vector(pos))
    return Matrix.Translation(t) @ basis.to_4x4()


def key(arm, frame, poses, interpolation="BEZIER"):
    """poses = {junta: (rx, ry, rz)} ou {junta: ((rx, ry, rz), (px, py, pz))}; graus/studs, eixos Roblox.
    Rotação = CFrame.Angles(rx, ry, rz) do Roblox. Juntas omitidas não recebem chave neste
    frame; a posição só ganha chave na forma com posição (use-a em todas as chaves da junta)."""
    for name, value in poses.items():
        com_pos = isinstance(value[0], (tuple, list))
        rot, pos = value if com_pos else (value, (0, 0, 0))
        pb = arm.pose.bones[name]
        anterior = pb.rotation_quaternion.copy()
        pb.matrix_basis = rbx_to_basis(arm, name, rot, pos)
        if pb.rotation_quaternion.dot(anterior) < 0:  # caminho curto entre chaves
            pb.rotation_quaternion = -pb.rotation_quaternion
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        if com_pos:
            pb.keyframe_insert("location", frame=frame)
    if arm.animation_data and arm.animation_data.action:
        for fc in _fcurves(arm.animation_data.action):
            for kp in fc.keyframe_points:
                if round(kp.co[0]) == frame:
                    kp.interpolation = interpolation


def _fcurves(action):
    if hasattr(action, "fcurves") and len(getattr(action, "fcurves", [])):
        return list(action.fcurves)
    out = []
    for layer in getattr(action, "layers", []):
        for strip in layer.strips:
            for bag in getattr(strip, "channelbags", []):
                out.extend(bag.fcurves)
    return out


def joint_transform(arm, pb):
    """Pose.CFrame do Roblox (12 números: x y z R00..R22) para o pose bone atual."""
    rest = pb.bone.matrix_local.to_3x3()
    basis = pb.matrix_basis
    r = rest @ basis.to_3x3() @ rest.transposed()
    t = rest @ basis.to_translation()
    r_rbx = M @ r @ M
    t_rbx = M @ t
    comps = [t_rbx.x, t_rbx.y, t_rbx.z]
    for i in range(3):
        for k in range(3):
            comps.append(r_rbx[i][k])
    return [round(c, 4) + 0.0 for c in comps]  # + 0.0 tira o "-0.0"


IDENTITY = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]


def export_json(arm, name, frame_start=None, frame_end=None, loop=False, priority="Action", markers=None):
    """Amostra cada frame e grava animations/exports/<name>.anim.json para o anim_import.luau.
    markers = {"Impacto": frame} vira KeyframeMarker (track:GetMarkerReachedSignal)."""
    scene = bpy.context.scene
    fs = scene.frame_start if frame_start is None else frame_start
    fe = scene.frame_end if frame_end is None else frame_end
    fps = scene.render.fps / scene.render.fps_base
    hierarchy = {}
    for b in arm.data.bones:
        if b.name == "HumanoidRootPart":
            continue
        hierarchy[b["part"]] = b["part0"]
    frames = []
    for f in range(fs, fe + 1):
        scene.frame_set(f)
        poses = {}
        for pb in arm.pose.bones:
            if pb.name != "HumanoidRootPart":
                c = joint_transform(arm, pb)
                if c != IDENTITY:  # omitida = identidade no anim_import (JSON menor)
                    poses[pb.bone["part"]] = c
        frames.append({"t": round((f - fs) / fps, 5), "poses": poses})
    out = {
        "name": name,
        "loop": loop,
        "priority": priority,
        "fps": fps,
        "hierarchy": hierarchy,
        "markers": {k: round((v - fs) / fps, 5) for k, v in (markers or {}).items()},
        "frames": frames,
    }
    os.makedirs(EXPORTS, exist_ok=True)
    path = os.path.join(EXPORTS, name + ".anim.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(out, f, separators=(",", ":"))
    print(f"[r15_lib] {len(frames)} frames → {path}")
    return path


def render_frames(name, frames, size=512):
    """Renders de verificação (Workbench, câmera 3/4 frontal) em animations/exports/<name>_fNN.png."""
    scene = bpy.context.scene
    try:
        scene.render.engine = "BLENDER_WORKBENCH"
    except TypeError:
        pass
    cam = scene.camera
    if cam is None:
        cam_data = bpy.data.cameras.new("Cam")
        cam = bpy.data.objects.new("Cam", cam_data)
        scene.collection.objects.link(cam)
        scene.camera = cam
    cam.location = (-7.5, -11, 5.2)
    cam.rotation_euler = Euler((math.radians(78), 0, math.radians(-34)), "XYZ")
    cam.data.lens = 40
    scene.render.resolution_x = scene.render.resolution_y = size
    scene.render.image_settings.file_format = "PNG"
    os.makedirs(EXPORTS, exist_ok=True)
    paths = []
    for f in frames:
        scene.frame_set(f)
        scene.render.filepath = os.path.join(EXPORTS, f"{name}_f{f:02d}.png")
        bpy.ops.render.render(write_still=True)
        paths.append(scene.render.filepath)
    return paths
