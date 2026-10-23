"""Mesh high-poly → asset pronto pro Roblox (Blender headless).

  blender -b -P blender_optimize.py -- IN.glb OUT.fbx [--target 6000] [--tex 1024] [--size 4]

  1. importa (glb/gltf/obj/fbx), junta tudo num objeto "High"
  2. normaliza: maior dimensão = --size studs (opcional), origem no centro da base
  3. cópia "Low" com Decimate (Collapse) até ~--target triângulos
  4. UV Smart Project no Low
  5. bake High→Low (Cycles): NORMAL sempre (guarda o detalhe dos 600k tris);
     COR só se o High tiver material/vertex color (Hi3DGen não tem; generate_3d tem)
  6. exporta OUT.fbx + OUT_normal.png (+ OUT_color.png) + OUT_report.json
  Falha se o Low passar de 20.000 triângulos (limite do Roblox por MeshPart).

No Studio: MeshPart com o FBX + SurfaceAppearance (ColorMap/NormalMap) com os PNGs.
"""

import argparse
import json
import math
import sys
from pathlib import Path

import bpy

ROBLOX_TRI_LIMIT = 20000


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("input", type=Path)
    ap.add_argument("output", type=Path)
    ap.add_argument("--target", type=int, default=6000)
    ap.add_argument("--tex", type=int, default=1024)
    ap.add_argument("--size", type=float, default=0, help="maior dimensão final em studs (0 = mantém)")
    ap.add_argument("--samples", type=int, default=16)
    ap.add_argument("--cage", type=float, default=0.05, help="extrusão da cage, fração da maior dimensão")
    return ap.parse_args(argv)


def tri_count(obj):
    mesh = obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
    mesh.calc_loop_triangles()
    n = len(mesh.loop_triangles)
    obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh_clear()
    return n


def select_only(objs, active):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = active


def import_any(path):
    ext = path.suffix.lower()
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=str(path))
    elif ext == ".obj":
        bpy.ops.wm.obj_import(filepath=str(path))
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=str(path))
    else:
        sys.exit(f"formato não suportado: {ext}")
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        sys.exit("nenhum mesh no arquivo")
    select_only(meshes, meshes[0])
    if len(meshes) > 1:
        bpy.ops.object.join()
    high = bpy.context.view_layer.objects.active
    # remove parents (glTF costuma trazer empties) mantendo a transformação
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    for o in list(bpy.context.scene.objects):
        if o is not high:
            bpy.data.objects.remove(o)
    high.name = "High"
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return high


def normalize(obj, size):
    dims = obj.dimensions
    if size > 0 and max(dims) > 0:
        k = size / max(dims)
        obj.scale = (k, k, k)
        bpy.ops.object.transform_apply(scale=True)
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    offset = ((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, min(zs))
    for v in obj.data.vertices:
        v.co.x -= offset[0]
        v.co.y -= offset[1]
        v.co.z -= offset[2]


def has_color(obj):
    if obj.data.color_attributes:
        return True
    for slot in obj.material_slots:
        mat = slot.material
        if mat and mat.use_nodes and any(n.type == "TEX_IMAGE" and n.image for n in mat.node_tree.nodes):
            return True
    return False


def set_cycles(samples):
    scene = bpy.context.scene
    try:
        scene.render.engine = "CYCLES"
    except TypeError as e:
        sys.exit(f"Cycles indisponível: {e}")
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples


def bake(high, low, kind, image, extrusion):
    mat = low.active_material
    nodes = mat.node_tree.nodes
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    for n in nodes:
        n.select = False
    tex.select = True
    nodes.active = tex

    select_only([high, low], low)
    bake = bpy.context.scene.render.bake
    bake.use_selected_to_active = True
    bake.cage_extrusion = extrusion
    bake.max_ray_distance = 0  # 0 = ilimitado a partir da cage
    bake.margin = 8
    if kind == "NORMAL":
        bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT")
    else:
        bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"})
    return tex


def main():
    args = parse_args()
    bpy.ops.wm.read_factory_settings(use_empty=True)

    high = import_any(args.input.resolve())
    normalize(high, args.size)
    tris_before = tri_count(high)
    color = has_color(high)
    if not high.active_material:  # bake from-selected precisa de material no High também
        high.data.materials.append(bpy.data.materials.new("HighMat"))

    # Low = cópia decimada
    low = high.copy()
    low.data = high.data.copy()
    low.name = "Low"
    bpy.context.collection.objects.link(low)
    if tris_before > args.target:
        mod = low.modifiers.new("Decimate", "DECIMATE")
        mod.decimate_type = "COLLAPSE"
        mod.ratio = args.target / tris_before
        mod.use_collapse_triangulate = True
        select_only([low], low)
        bpy.ops.object.modifier_apply(modifier=mod.name)
    tris_after = tri_count(low)

    # UV
    select_only([low], low)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    # Mesh decimado tem muitas faces pequenas: ângulo alto = ilhas maiores, margem pequena
    # para não desperdiçar textura, depois reempacota. (margin 0.02 deixava ~70% da textura vazia)
    bpy.ops.uv.smart_project(angle_limit=math.radians(80), island_margin=0.002, area_weight=0.5)
    bpy.ops.uv.average_islands_scale()
    bpy.ops.uv.pack_islands(rotate=True, margin=0.002)
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.shade_smooth()

    low.data.materials.clear()
    mat = bpy.data.materials.new("RobloxBaked")
    mat.use_nodes = True
    low.data.materials.append(mat)

    set_cycles(args.samples)
    # Decimação "achata" o relevo: a cage precisa envolver o High inteiro ou os raios erram
    extrusion = max(low.dimensions) * args.cage
    out = args.output.resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    files = {"mesh": out.name}

    normal_img = bpy.data.images.new("normal", args.tex, args.tex, alpha=False)
    normal_img.colorspace_settings.name = "Non-Color"
    normal_tex = bake(high, low, "NORMAL", normal_img, extrusion)
    normal_path = out.with_name(out.stem + "_normal.png")
    normal_img.filepath_raw = str(normal_path)
    normal_img.file_format = "PNG"
    normal_img.save()
    files["normal"] = normal_path.name

    color_tex = None
    if color:
        color_img = bpy.data.images.new("color", args.tex, args.tex, alpha=False)
        color_tex = bake(high, low, "COLOR", color_img, extrusion)
        color_path = out.with_name(out.stem + "_color.png")
        color_img.filepath_raw = str(color_path)
        color_img.file_format = "PNG"
        color_img.save()
        files["color"] = color_path.name

    # Liga as texturas no material final (para o FBX levar as referências)
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    nmap = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(normal_tex.outputs["Color"], nmap.inputs["Color"])
    nt.links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    if color_tex:
        nt.links.new(color_tex.outputs["Color"], bsdf.inputs["Base Color"])

    bpy.data.objects.remove(high)
    select_only([low], low)
    low.name = out.stem
    if out.suffix.lower() == ".fbx":
        bpy.ops.export_scene.fbx(filepath=str(out), use_selection=True, path_mode="COPY", embed_textures=False)
    else:
        bpy.ops.export_scene.gltf(filepath=str(out), use_selection=True)

    report = {
        "input": str(args.input),
        "trianglesBefore": tris_before,
        "trianglesAfter": tris_after,
        "dimensions": [round(d, 3) for d in low.dimensions],
        "bakedColor": color,
        "files": files,
        "robloxOk": tris_after <= ROBLOX_TRI_LIMIT,
    }
    out.with_name(out.stem + "_report.json").write_text(json.dumps(report, indent=2))
    print("REPORT", json.dumps(report))
    if tris_after > ROBLOX_TRI_LIMIT:
        sys.exit(f"Low tem {tris_after} triângulos (> {ROBLOX_TRI_LIMIT}); baixe --target")


if __name__ == "__main__":
    main()
