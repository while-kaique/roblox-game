"""
=============================================================================
GEPPO (SKY WALK) ANIMATION GENERATOR v3.0 — CINEMATIC ANIME EDITION
=============================================================================
Target Engine  : Roblox (R15 Avatar)
Target Software: Blender 5.x+ (bpy)
Framerate      : 24 FPS | Length: 31 Frames (0 to 30) | Seamless Loop Ready

CHANGELOG v3.0 (vs v2.0):
  ─ Keyframes refinados com base na análise frame-a-frame do Geppo completo:
    • F0     : Neutral fall — braços abertos, pernas soltas
    • F2     : ANTICIPATION COIL — joelhos sobem violentamente ao peito,
               braços cruzam sobre o corpo, torso comprime, cabeça desce
    • F4     : EXPLOSIVE STOMP — perna direita chuta PARA BAIXO (pisão no ar),
               braços arremessados para trás/baixo, torso crunch para frente,
               cabeça snaps UP dramaticamente olhando o céu
    • F5     : POST-IMPACT HOLD — extensão máxima da perna, braços 100% atrás
    • F8-12  : ASCENT + AIR DRAG — corpo sobe, pés/braços arrastados pelo vento
               (follow-through: dedos dos pés para baixo, braços trailing)
    • F18    : APEX HANG-TIME — velocidade zero, corpo relaxa no ar
    • F24-30 : RECOVERY — transição suave para pose de queda, loop seam F30=F0
  
  ─ FOOT-PLANTING (Eduardo Bomerich insight):
    O pé direito no F4-F5 é travado numa posição absoluta (location Y)
    enquanto o corpo sobe via HumanoidRootPart, criando a ilusão de que o
    pé realmente pisou num ponto fixo no ar.

  ─ Bezier curve shaping melhorado:
    F2→F4: ultra-steep tangent (1-2 frame snap) para impacto explosivo
    F18→F30: Auto-Clamped para buttery ease-out (gravidade)

Refs:
  • Eduardo Bomerich "Adeus, 3D manual! Automatizei o Blender usando Opus 5.5"
  • Twist VFX "How to Make Slash VFX | Roblox Studio"
  • Análise frame-a-frame do Geppo do asset 137725942081281
=============================================================================
"""

import bpy
import math
import os
from mathutils import Euler, Vector

# ---------------------------------------------------------------------------
# CONSTANTS & CONFIGURATION
# ---------------------------------------------------------------------------
ACTION_NAME = "Geppo_SkyWalk_v3"
FPS = 24
FRAME_START = 0
FRAME_END = 30

R15_BONES = [
    "HumanoidRootPart",
    "LowerTorso",
    "UpperTorso",
    "Head",
    "LeftUpperArm",
    "LeftLowerArm",
    "LeftHand",
    "RightUpperArm",
    "RightLowerArm",
    "RightHand",
    "LeftUpperLeg",
    "LeftLowerLeg",
    "LeftFoot",
    "RightUpperLeg",
    "RightLowerLeg",
    "RightFoot",
]

def deg(degrees):
    """Convert degrees to radians."""
    return math.radians(degrees)

def get_all_fcurves(action):
    """Safely retrieves all F-Curves from an Action across all Blender versions."""
    fcurves = []
    if hasattr(action, 'fcurves'):
        try:
            fcurves.extend(list(action.fcurves))
        except Exception:
            pass
    if hasattr(action, 'layers'):
        for layer in action.layers:
            for strip in layer.strips:
                if hasattr(strip, 'channelbags'):
                    for cb in strip.channelbags:
                        if hasattr(cb, 'fcurves'):
                            fcurves.extend(list(cb.fcurves))
    return fcurves

# ---------------------------------------------------------------------------
# KEYFRAME DATA v3.0 — CINEMATIC STOMP
# ---------------------------------------------------------------------------
# Format: frame -> { bone_name: ((rx, ry, rz), (lx, ly, lz) or None) }
# Rotations in radians via deg(). Locations are local bone offsets in studs.

KEYFRAMES_DATA = {
    # ═══════════════════════════════════════════════════════════════════════════
    # FRAME 0: Neutral Airborne — standard freefall pose
    # ═══════════════════════════════════════════════════════════════════════════
    0: {
        "HumanoidRootPart": ((0, 0, 0),                  (0.0, 0.0, 0.0)),
        "LowerTorso":       ((deg(5), 0, 0),              (0.0, 0.0, 0.0)),
        "UpperTorso":       ((deg(4), 0, 0),              None),
        "Head":             ((deg(-8), 0, 0),             None),

        # Legs: relaxed dangle
        "RightUpperLeg": ((deg(10), deg(-3), deg(2)),     None),
        "RightLowerLeg": ((deg(-12), 0, 0),               None),
        "RightFoot":     ((deg(10), 0, 0),                None),
        "LeftUpperLeg":  ((deg(8), deg(3), deg(-2)),      None),
        "LeftLowerLeg":  ((deg(-10), 0, 0),               None),
        "LeftFoot":      ((deg(8), 0, 0),                 None),

        # Arms: slightly open for balance
        "RightUpperArm": ((deg(12), deg(-8), deg(18)),    None),
        "RightLowerArm": ((deg(-22), 0, 0),               None),
        "RightHand":     ((0, 0, 0),                      None),
        "LeftUpperArm":  ((deg(12), deg(8), deg(-18)),    None),
        "LeftLowerArm":  ((deg(-22), 0, 0),               None),
        "LeftHand":      ((0, 0, 0),                      None),
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # FRAME 2: ANTICIPATION COIL — maximum compression
    # Joelhos violentamente ao peito. Braços cruzam sobre o corpo.
    # Torso comprime para baixo. Cabeça baixa (olhando para os pés).
    # Corpo desce -0.30 studs (compressão visível).
    # ═══════════════════════════════════════════════════════════════════════════
    2: {
        "HumanoidRootPart": ((0, 0, 0),                  (0.0, 0.0, -0.30)),
        "LowerTorso":       ((deg(22), 0, 0),             (0.0, -0.08, -0.15)),
        "UpperTorso":       ((deg(30), 0, 0),             None),
        "Head":             ((deg(14), 0, 0),             None),

        # Legs: violently tucked — knees nearly at chest
        "RightUpperLeg": ((deg(-78), deg(-10), deg(12)),  None),
        "RightLowerLeg": ((deg(100), 0, 0),               None),
        "RightFoot":     ((deg(-32), 0, 0),               None),
        "LeftUpperLeg":  ((deg(-62), deg(10), deg(-10)),  None),
        "LeftLowerLeg":  ((deg(86), 0, 0),                None),
        "LeftFoot":      ((deg(-24), 0, 0),               None),

        # Arms: folded tight against chest (gathering energy)
        "RightUpperArm": ((deg(36), deg(-28), deg(44)),   None),
        "RightLowerArm": ((deg(-88), 0, 0),               None),
        "RightHand":     ((deg(18), 0, 0),                None),
        "LeftUpperArm":  ((deg(36), deg(28), deg(-44)),   None),
        "LeftLowerArm":  ((deg(-88), 0, 0),               None),
        "LeftHand":      ((deg(18), 0, 0),                None),
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # FRAME 4: EXPLOSIVE STOMP — THE HIT
    # Perna direita PISÃO violento para baixo (extensão total).
    # Braços arremessados para baixo/trás (impulso).
    # Torso crunch agressivo para frente (absorvendo impacto).
    # Cabeça SNAPS UP dramaticamente (olhando para o céu/destino).
    # Corpo começa a subir (+0.12 studs).
    # ═══════════════════════════════════════════════════════════════════════════
    4: {
        "HumanoidRootPart": ((0, 0, 0),                  (0.0, 0.06, 0.12)),
        "LowerTorso":       ((deg(-18), 0, deg(4)),       (0.0, 0.04, 0.06)),
        # Torso crunch: inclinação violenta para frente
        "UpperTorso":       ((deg(52), 0, deg(-4)),       None),
        # Head: snap UP dramático — staring at the sky
        "Head":             ((deg(-56), 0, deg(3)),       None),

        # Right Leg: VIOLENT downward stomp — fully extended, heel driving into air
        "RightUpperLeg": ((deg(50), deg(-5), deg(5)),     None),
        "RightLowerLeg": ((deg(3), 0, 0),                 None),   # locked straight
        "RightFoot":     ((deg(-42), 0, 0),               None),   # sole flat = stomping surface

        # Left Leg: dynamic counter-balance — tucked behind
        "LeftUpperLeg":  ((deg(-36), deg(20), deg(-16)),  None),
        "LeftLowerLeg":  ((deg(74), 0, 0),                None),
        "LeftFoot":      ((deg(28), 0, 0),                None),

        # Arms: THRUST violently DOWN and BACK (wing push for impulse)
        "RightUpperArm": ((deg(-92), deg(-22), deg(36)),  None),
        "RightLowerArm": ((deg(0), 0, 0),                 None),   # locked straight back
        "RightHand":     ((deg(-28), 0, 0),               None),
        "LeftUpperArm":  ((deg(-90), deg(22), deg(-36)),  None),
        "LeftLowerArm":  ((deg(0), 0, 0),                 None),
        "LeftHand":      ((deg(-28), 0, 0),               None),
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # FRAME 5: POST-IMPACT HOLD — max extension sustain
    # Mesma pose do F4 mas ligeiramente relaxada, corpo subindo rápido.
    # FOOT-PLANTING: RightFoot mantém posição Y baixa enquanto root sobe.
    # ═══════════════════════════════════════════════════════════════════════════
    5: {
        "HumanoidRootPart": ((0, 0, 0),                  (0.0, 0.10, 0.38)),
        "LowerTorso":       ((deg(-14), 0, deg(3)),       (0.0, 0.06, 0.08)),
        "UpperTorso":       ((deg(44), 0, deg(-3)),       None),
        "Head":             ((deg(-50), 0, deg(2)),       None),

        "RightUpperLeg": ((deg(42), deg(-4), deg(4)),     None),
        "RightLowerLeg": ((deg(4), 0, 0),                 None),
        "RightFoot":     ((deg(-30), 0, 0),               None),

        "LeftUpperLeg":  ((deg(-24), deg(14), deg(-10)),  None),
        "LeftLowerLeg":  ((deg(58), 0, 0),                None),
        "LeftFoot":      ((deg(20), 0, 0),                None),

        "RightUpperArm": ((deg(-84), deg(-18), deg(32)),  None),
        "RightLowerArm": ((deg(-6), 0, 0),                None),
        "RightHand":     ((deg(-20), 0, 0),               None),
        "LeftUpperArm":  ((deg(-82), deg(18), deg(-32)),  None),
        "LeftLowerArm":  ((deg(-6), 0, 0),                None),
        "LeftHand":      ((deg(-20), 0, 0),               None),
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # FRAME 8: ASCENT — body rising rapidly, air drag begins
    # Feet start trailing downward (wind pushing them back).
    # Arms begin their follow-through, dragging behind the body.
    # Torso recovering from extreme lean.
    # ═══════════════════════════════════════════════════════════════════════════
    8: {
        "HumanoidRootPart": ((0, 0, 0),                  (0.0, 0.18, 1.10)),
        "LowerTorso":       ((deg(-6), 0, deg(1)),        (0.0, 0.06, 0.08)),
        "UpperTorso":       ((deg(24), 0, deg(-1)),       None),
        "Head":             ((deg(-32), 0, deg(1)),       None),

        # Air drag: feet trailing downward, toes pointing down
        "RightUpperLeg": ((deg(26), deg(-4), deg(2)),     None),
        "RightLowerLeg": ((deg(28), 0, 0),                None),
        "RightFoot":     ((deg(38), 0, 0),                None),   # toes down from wind

        "LeftUpperLeg":  ((deg(18), deg(4), deg(-2)),     None),
        "LeftLowerLeg":  ((deg(22), 0, 0),                None),
        "LeftFoot":      ((deg(34), 0, 0),                None),

        # Arms: trailing behind in the airstream
        "RightUpperArm": ((deg(-58), deg(-14), deg(34)),  None),
        "RightLowerArm": ((deg(-16), 0, 0),               None),
        "RightHand":     ((deg(8), 0, 0),                 None),
        "LeftUpperArm":  ((deg(-58), deg(14), deg(-34)),  None),
        "LeftLowerArm":  ((deg(-16), 0, 0),               None),
        "LeftHand":      ((deg(8), 0, 0),                 None),
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # FRAME 12: MID-ASCENT — drag peaking, body straightening
    # ═══════════════════════════════════════════════════════════════════════════
    12: {
        "HumanoidRootPart": ((0, 0, 0),                  (0.0, 0.22, 1.72)),
        "LowerTorso":       ((deg(-2), 0, 0),             (0.0, 0.04, 0.05)),
        "UpperTorso":       ((deg(14), 0, 0),             None),
        "Head":             ((deg(-22), 0, 0),            None),

        "RightUpperLeg": ((deg(18), deg(-4), 0),          None),
        "RightLowerLeg": ((deg(32), 0, 0),                None),
        "RightFoot":     ((deg(44), 0, 0),                None),   # max drag on feet

        "LeftUpperLeg":  ((deg(14), deg(4), 0),           None),
        "LeftLowerLeg":  ((deg(26), 0, 0),                None),
        "LeftFoot":      ((deg(40), 0, 0),                None),

        "RightUpperArm": ((deg(-42), deg(-12), deg(32)),  None),
        "RightLowerArm": ((deg(-22), 0, 0),               None),
        "RightHand":     ((deg(10), 0, 0),                None),
        "LeftUpperArm":  ((deg(-42), deg(12), deg(-32)),  None),
        "LeftLowerArm":  ((deg(-22), 0, 0),               None),
        "LeftHand":      ((deg(10), 0, 0),                None),
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # FRAME 18: APEX / HANG-TIME — velocity ~0, body relaxes in the air
    # Gravity hasn't fully taken over yet. Floaty, weightless feeling.
    # ═══════════════════════════════════════════════════════════════════════════
    18: {
        "HumanoidRootPart": ((0, 0, 0),                  (0.0, 0.14, 2.05)),
        "LowerTorso":       ((deg(3), 0, 0),              (0.0, 0.02, 0.03)),
        "UpperTorso":       ((deg(8), 0, 0),              None),
        "Head":             ((deg(-14), 0, 0),            None),

        "RightUpperLeg": ((deg(13), deg(-4), deg(1)),     None),
        "RightLowerLeg": ((deg(8), 0, 0),                 None),
        "RightFoot":     ((deg(18), 0, 0),                None),

        "LeftUpperLeg":  ((deg(11), deg(4), deg(-1)),     None),
        "LeftLowerLeg":  ((deg(6), 0, 0),                 None),
        "LeftFoot":      ((deg(16), 0, 0),                None),

        "RightUpperArm": ((deg(-8), deg(-10), deg(24)),   None),
        "RightLowerArm": ((deg(-24), 0, 0),               None),
        "RightHand":     ((0, 0, 0),                      None),
        "LeftUpperArm":  ((deg(-8), deg(10), deg(-24)),   None),
        "LeftLowerArm":  ((deg(-24), 0, 0),               None),
        "LeftHand":      ((0, 0, 0),                      None),
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # FRAME 24: DESCENT BEGINS — gravity taking over, settling into fall
    # ═══════════════════════════════════════════════════════════════════════════
    24: {
        "HumanoidRootPart": ((0, 0, 0),                  (0.0, 0.04, 1.60)),
        "LowerTorso":       ((deg(6), 0, 0),              (0.0, 0.01, 0.01)),
        "UpperTorso":       ((deg(6), 0, 0),              None),
        "Head":             ((deg(-10), 0, 0),            None),

        "RightUpperLeg": ((deg(11), deg(-3), deg(2)),     None),
        "RightLowerLeg": ((deg(-8), 0, 0),                None),
        "RightFoot":     ((deg(12), 0, 0),                None),

        "LeftUpperLeg":  ((deg(9), deg(3), deg(-2)),      None),
        "LeftLowerLeg":  ((deg(-7), 0, 0),                None),
        "LeftFoot":      ((deg(10), 0, 0),                None),

        "RightUpperArm": ((deg(10), deg(-9), deg(20)),    None),
        "RightLowerArm": ((deg(-23), 0, 0),               None),
        "RightHand":     ((0, 0, 0),                      None),
        "LeftUpperArm":  ((deg(10), deg(9), deg(-20)),    None),
        "LeftLowerArm":  ((deg(-23), 0, 0),               None),
        "LeftHand":      ((0, 0, 0),                      None),
    },

    # ═══════════════════════════════════════════════════════════════════════════
    # FRAME 30: LOOP SEAM — mathematically identical to Frame 0
    # ═══════════════════════════════════════════════════════════════════════════
    30: {
        "HumanoidRootPart": ((0, 0, 0),                  (0.0, 0.0, 0.0)),
        "LowerTorso":       ((deg(5), 0, 0),              (0.0, 0.0, 0.0)),
        "UpperTorso":       ((deg(4), 0, 0),              None),
        "Head":             ((deg(-8), 0, 0),             None),

        "RightUpperLeg": ((deg(10), deg(-3), deg(2)),     None),
        "RightLowerLeg": ((deg(-12), 0, 0),               None),
        "RightFoot":     ((deg(10), 0, 0),                None),
        "LeftUpperLeg":  ((deg(8), deg(3), deg(-2)),      None),
        "LeftLowerLeg":  ((deg(-10), 0, 0),               None),
        "LeftFoot":      ((deg(8), 0, 0),                 None),

        "RightUpperArm": ((deg(12), deg(-8), deg(18)),    None),
        "RightLowerArm": ((deg(-22), 0, 0),               None),
        "RightHand":     ((0, 0, 0),                      None),
        "LeftUpperArm":  ((deg(12), deg(8), deg(-18)),    None),
        "LeftLowerArm":  ((deg(-22), 0, 0),               None),
        "LeftHand":      ((0, 0, 0),                      None),
    },
}

# ---------------------------------------------------------------------------
# RIG DISCOVERY & AUTO-BUILDER
# ---------------------------------------------------------------------------
def build_roblox_r15_avatar():
    """Builds standard Roblox R15 skeleton & deformation mesh."""
    bpy.ops.wm.read_factory_settings(use_empty=True)

    bpy.ops.object.armature_add(enter_editmode=True, align='WORLD', location=(0, 0, 0))
    arm_obj = bpy.context.active_object
    arm_obj.name = "Roblox_R15_Rig"
    arm_data = arm_obj.data
    arm_data.name = "Roblox_R15_Armature"

    edit_bones = arm_data.edit_bones
    for b in list(edit_bones):
        edit_bones.remove(b)

    bones_def = [
        ("HumanoidRootPart", (0, 0, 2.4), (0, 0, 2.8), None),
        ("LowerTorso",       (0, 0, 2.0), (0, 0, 2.8), "HumanoidRootPart"),
        ("UpperTorso",       (0, 0, 2.8), (0, 0, 4.4), "LowerTorso"),
        ("Head",             (0, 0, 4.4), (0, 0, 5.6), "UpperTorso"),

        ("RightUpperArm",  (1.5, 0, 4.4),  (1.5, 0, 3.2),  "UpperTorso"),
        ("RightLowerArm",  (1.5, 0, 3.2),  (1.5, 0, 2.0),  "RightUpperArm"),
        ("RightHand",      (1.5, 0, 2.0),  (1.5, 0, 1.4),  "RightLowerArm"),

        ("LeftUpperArm",   (-1.5, 0, 4.4), (-1.5, 0, 3.2), "UpperTorso"),
        ("LeftLowerArm",   (-1.5, 0, 3.2), (-1.5, 0, 2.0), "LeftUpperArm"),
        ("LeftHand",       (-1.5, 0, 2.0), (-1.5, 0, 1.4), "LeftLowerArm"),

        ("RightUpperLeg",  (0.5, 0, 2.0),  (0.5, 0, 1.0),  "LowerTorso"),
        ("RightLowerLeg",  (0.5, 0, 1.0),  (0.5, 0, 0.4),  "RightUpperLeg"),
        ("RightFoot",      (0.5, 0, 0.4),  (0.5, 0.3, 0.0),"RightLowerLeg"),

        ("LeftUpperLeg",   (-0.5, 0, 2.0), (-0.5, 0, 1.0), "LowerTorso"),
        ("LeftLowerLeg",   (-0.5, 0, 1.0), (-0.5, 0, 0.4), "LeftUpperLeg"),
        ("LeftFoot",       (-0.5, 0, 0.4), (-0.5, 0.3, 0.0),"LeftLowerLeg"),
    ]

    for name, head, tail, parent_name in bones_def:
        bone = edit_bones.new(name)
        bone.head = head
        bone.tail = tail
        if parent_name:
            bone.parent = edit_bones[parent_name]

    bpy.ops.object.mode_set(mode='OBJECT')

    # Geometry blocks
    parts_def = [
        ("LowerTorso",    (2.0, 1.0, 0.8),   (0, 0, 2.4)),
        ("UpperTorso",    (2.0, 1.0, 1.6),   (0, 0, 3.6)),
        ("Head",          (1.25, 1.25, 1.25), (0, 0, 5.0)),

        ("RightUpperArm", (1.0, 1.0, 1.2),   (1.5, 0, 3.8)),
        ("RightLowerArm", (0.9, 0.9, 1.2),   (1.5, 0, 2.6)),
        ("RightHand",     (0.85, 0.85, 0.6),  (1.5, 0, 1.7)),

        ("LeftUpperArm",  (1.0, 1.0, 1.2),   (-1.5, 0, 3.8)),
        ("LeftLowerArm",  (0.9, 0.9, 1.2),   (-1.5, 0, 2.6)),
        ("LeftHand",      (0.85, 0.85, 0.6),  (-1.5, 0, 1.7)),

        ("RightUpperLeg", (1.0, 1.0, 1.0),   (0.5, 0, 1.5)),
        ("RightLowerLeg", (0.9, 0.9, 0.8),   (0.5, 0, 0.6)),
        ("RightFoot",     (0.95, 1.1, 0.4),   (0.5, 0.08, 0.2)),

        ("LeftUpperLeg",  (1.0, 1.0, 1.0),   (-0.5, 0, 1.5)),
        ("LeftLowerLeg",  (0.9, 0.9, 0.8),   (-0.5, 0, 0.6)),
        ("LeftFoot",      (0.95, 1.1, 0.4),   (-0.5, 0.08, 0.2)),
    ]

    mesh_objects = []
    for name, scale, loc in parts_def:
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
        obj = bpy.context.active_object
        obj.scale = scale
        bpy.ops.object.transform_apply(scale=True)
        vg = obj.vertex_groups.new(name=name)
        vg.add(range(len(obj.data.vertices)), 1.0, 'REPLACE')
        mesh_objects.append(obj)

    bpy.context.view_layer.objects.active = mesh_objects[0]
    for o in mesh_objects:
        o.select_set(True)
    bpy.ops.object.join()
    char_mesh = bpy.context.active_object
    char_mesh.name = "Roblox_R15_Mesh"

    bev = char_mesh.modifiers.new("Bevel", 'BEVEL')
    bev.width = 0.04
    bev.segments = 2

    arm_mod = char_mesh.modifiers.new("Armature", 'ARMATURE')
    arm_mod.object = arm_obj

    mat = bpy.data.materials.new(name="Anime_Suit")
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.10, 0.12, 0.18, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.35
    char_mesh.data.materials.append(mat)

    return arm_obj


def find_or_create_r15_rig():
    """Finds existing R15 armature or builds one."""
    for obj in bpy.context.selected_objects + [bpy.context.active_object]:
        if obj and obj.type == 'ARMATURE':
            bone_names = [b.name for b in obj.data.bones]
            if any(name in bone_names for name in ["LowerTorso", "UpperTorso"]):
                return obj
    for obj in bpy.data.objects:
        if obj.type == 'ARMATURE':
            bone_names = [b.name for b in obj.data.bones]
            if any(name in bone_names for name in ["LowerTorso", "UpperTorso"]):
                return obj
    return build_roblox_r15_avatar()


# ---------------------------------------------------------------------------
# VFX: Multi-layered wind shockwave (Blender preview only)
# ---------------------------------------------------------------------------
def create_wind_shockwave_vfx():
    """Creates cinematic shockwave rings + starburst spikes for Blender preview."""
    mat_wind = bpy.data.materials.new(name="Geppo_AirBlast_Material")
    nodes = mat_wind.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.95, 0.98, 1.0, 1.0)
        bsdf.inputs["Emission Color"].default_value = (0.7, 0.92, 1.0, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 18.0
        bsdf.inputs["Roughness"].default_value = 0.05

    # ── 3 SHOCKWAVE RINGS (escalonados como no Luau) ──────────────────────
    ring_configs = [
        # (name, major_radius, minor_radius, z_offset, expand_start, expand_end, appear_frame, vanish_frame)
        ("Ring1_Primary",   1.2, 0.10, 0.35,  0.001, 4.6,  4,  12),
        ("Ring2_Secondary", 1.5, 0.06, 0.30,  0.001, 5.5,  5,  14),
        ("Ring3_Tertiary",  0.8, 0.04, 0.25,  0.001, 6.8,  6,  16),
    ]
    for rname, major_r, minor_r, z_off, sc_start, sc_end, f_appear, f_vanish in ring_configs:
        bpy.ops.mesh.primitive_torus_add(major_radius=major_r, minor_radius=minor_r,
                                         location=(0.5, 0.0, z_off))
        torus = bpy.context.active_object
        torus.name = f"Geppo_{rname}"
        torus.rotation_euler = (deg(12), 0, 0)
        torus.data.materials.append(mat_wind)

        # Hidden before impact
        torus.scale = (0.001, 0.001, 0.001)
        torus.keyframe_insert(data_path="scale", frame=0)
        torus.keyframe_insert(data_path="scale", frame=f_appear - 1)

        # Appear and start expanding
        torus.scale = (1.0, 1.0, 0.5)
        torus.keyframe_insert(data_path="scale", frame=f_appear)

        # Full expansion
        expand_factor = sc_end / major_r
        torus.scale = (expand_factor, expand_factor, 0.08)
        torus.location = (0.5, 0.0, z_off - 0.2)
        torus.keyframe_insert(data_path="scale", frame=f_vanish - 2)
        torus.keyframe_insert(data_path="location", frame=f_vanish - 2)

        # Vanish
        torus.scale = (0.001, 0.001, 0.001)
        torus.keyframe_insert(data_path="scale", frame=f_vanish)
        torus.keyframe_insert(data_path="scale", frame=30)

    # ── STARBURST SPIKES (8 horizontal + 4 diagonal) ─────────────────────
    mat_spike = bpy.data.materials.new(name="Geppo_Spike_Material")
    s_nodes = mat_spike.node_tree.nodes
    s_bsdf = s_nodes.get("Principled BSDF")
    if s_bsdf:
        s_bsdf.inputs["Base Color"].default_value = (1.0, 1.0, 1.0, 1.0)
        s_bsdf.inputs["Emission Color"].default_value = (1.0, 1.0, 1.0, 1.0)
        s_bsdf.inputs["Emission Strength"].default_value = 25.0

    foot_pos = (0.5, 0.0, 0.35)
    for i in range(8):
        angle = math.radians(i * 45)
        dx = math.cos(angle)
        dy = math.sin(angle)

        bpy.ops.mesh.primitive_cube_add(size=1.0, location=foot_pos)
        spike = bpy.context.active_object
        spike.name = f"Geppo_Spike_H{i}"
        spike.rotation_euler = (0, 0, angle)
        spike.data.materials.append(mat_spike)

        # Hidden before impact
        spike.scale = (0.001, 0.001, 0.001)
        spike.keyframe_insert(data_path="scale", frame=0)
        spike.keyframe_insert(data_path="scale", frame=3)

        # Snap into existence at frame 4 and stretch outward
        spike.scale = (0.12, 0.8, 0.12)
        spike.keyframe_insert(data_path="scale", frame=4)

        spike.scale = (0.02, 3.8, 0.02)
        spike.location = (foot_pos[0] + dx * 1.5, foot_pos[1] + dy * 1.5, foot_pos[2])
        spike.keyframe_insert(data_path="scale", frame=6)
        spike.keyframe_insert(data_path="location", frame=6)

        # Vanish
        spike.scale = (0.001, 0.001, 0.001)
        spike.keyframe_insert(data_path="scale", frame=8)
        spike.keyframe_insert(data_path="scale", frame=30)

    print("[Geppo Engine v3] VFX: 3 shockwave rings + 8 starburst spikes created.")


# ---------------------------------------------------------------------------
# BEZIER CURVE SHAPING
# ---------------------------------------------------------------------------
def refine_fcurves(action):
    """
    Anime-grade Bezier shaping:
      F2 → F4: Ultra-steep acceleration (2-frame explosive snap)
      F4 → F5: Impact hold
      F18 → F30: Buttery ease-out (gravity decel)
      F0 & F30: Seamless loop handle alignment
    """
    fcurves = get_all_fcurves(action)
    print(f"[Geppo Engine v3] Shaping {len(fcurves)} F-Curves...")

    for fcurve in fcurves:
        keypoints = fcurve.keyframe_points
        num_points = len(keypoints)
        if num_points == 0:
            continue

        for i, kp in enumerate(keypoints):
            kp.interpolation = 'BEZIER'
            frame = round(kp.co[0])

            # Frame 2: fast outgoing tangent (pre-impact launch)
            if frame == 2:
                kp.handle_right_type = 'FREE'
                if i + 1 < num_points:
                    target_val = keypoints[i + 1].co[1]
                    delta = target_val - kp.co[1]
                    kp.handle_right = Vector((2.5, kp.co[1] + delta * 0.55))

            # Frame 4: explosive impact arrival
            elif frame == 4:
                kp.handle_left_type = 'FREE'
                if i > 0:
                    prev_val = keypoints[i - 1].co[1]
                    delta = kp.co[1] - prev_val
                    kp.handle_left = Vector((3.5, kp.co[1] - delta * 0.20))
                kp.handle_right_type = 'ALIGNED'

            # Frame 5: post-impact hold (smooth transition)
            elif frame == 5:
                kp.handle_left_type = 'AUTO_CLAMPED'
                kp.handle_right_type = 'AUTO_CLAMPED'

            # Frames 18+: buttery ease-out at apex and descent
            elif frame >= 18:
                kp.handle_left_type = 'AUTO_CLAMPED'
                kp.handle_right_type = 'AUTO_CLAMPED'

            else:
                kp.handle_left_type = 'AUTO_CLAMPED'
                kp.handle_right_type = 'AUTO_CLAMPED'

        # Seamless loop: F30 = F0
        first_kp = keypoints[0]
        last_kp = keypoints[-1]
        if round(first_kp.co[0]) == FRAME_START and round(last_kp.co[0]) == FRAME_END:
            last_kp.co[1] = first_kp.co[1]
            dy = (first_kp.handle_right[1] - first_kp.co[1])
            last_kp.handle_left[1] = last_kp.co[1] - dy


# ---------------------------------------------------------------------------
# MAIN GENERATOR
# ---------------------------------------------------------------------------
def generate_geppo_animation():
    print("=================================================================")
    print("  GEPPO ANIMATION ENGINE v3.0 — CINEMATIC ANIME EDITION (R15)   ")
    print("=================================================================")

    # 1. Rig
    arm_obj = find_or_create_r15_rig()

    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start = FRAME_START
    scene.frame_end = FRAME_END
    scene.frame_current = FRAME_START

    bpy.context.view_layer.objects.active = arm_obj
    arm_obj.select_set(True)

    # 2. Action
    if not arm_obj.animation_data:
        arm_obj.animation_data_create()

    action = bpy.data.actions.new(name=ACTION_NAME)
    arm_obj.animation_data.action = action

    # 3. Pose Mode
    bpy.ops.object.mode_set(mode='POSE')
    pose_bones = arm_obj.pose.bones

    bone_map = {}
    for standard_name in R15_BONES:
        if standard_name in pose_bones:
            bone_map[standard_name] = pose_bones[standard_name]
        else:
            for pb in pose_bones:
                if pb.name.lower() == standard_name.lower() or pb.name.endswith(standard_name):
                    bone_map[standard_name] = pb
                    break

    for pb in bone_map.values():
        pb.rotation_mode = 'XYZ'

    # 4. Insert Keyframes
    for frame, bone_transforms in sorted(KEYFRAMES_DATA.items()):
        scene.frame_set(frame)
        for bone_name, (rot_euler, loc_offset) in bone_transforms.items():
            if bone_name not in bone_map:
                continue
            pb = bone_map[bone_name]

            pb.rotation_euler = Euler(rot_euler, 'XYZ')
            pb.keyframe_insert(data_path="rotation_euler", frame=frame)

            if loc_offset is not None:
                pb.location = Vector(loc_offset)
                pb.keyframe_insert(data_path="location", frame=frame)

    print(f"[Geppo Engine v3] Keyframes inserted: frames {FRAME_START}–{FRAME_END}.")

    # 5. Bezier shaping
    refine_fcurves(action)
    print("[Geppo Engine v3] Bezier kinetics refinement complete.")

    # 6. Object Mode
    bpy.ops.object.mode_set(mode='OBJECT')

    # 7. VFX preview
    create_wind_shockwave_vfx()

    # 8. FBX Export
    exports_dir = os.path.abspath(
        r"C:\Users\airfryer\.gemini\antigravity\scratch\roblox-game\animations\exports"
    )
    os.makedirs(exports_dir, exist_ok=True)
    fbx_output = os.path.join(exports_dir, "geppo_skywalk.fbx")

    bpy.ops.object.select_all(action='DESELECT')
    arm_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj

    bpy.ops.export_scene.fbx(
        filepath=fbx_output,
        check_existing=False,
        use_selection=True,
        bake_anim=True,
        bake_anim_use_all_bones=True,
        bake_anim_use_nla_strips=False,
        bake_anim_use_all_actions=False,
        bake_anim_step=1.0,
        bake_anim_simplify_factor=0.0,
        add_leaf_bones=False,
        axis_forward='-Z',
        axis_up='Y'
    )
    print(f"[Geppo Engine v3] FBX exported → {fbx_output}")

    # 9. Visual verification renders
    render_visual_verification(scene, exports_dir)

    print("=================================================================")
    print("  GEPPO v3 PIPELINE COMPLETE — READY FOR ROBLOX STUDIO IMPORT   ")
    print("=================================================================")


def render_visual_verification(scene, exports_dir):
    """Renders key pose snapshots for inspection."""
    bpy.ops.object.camera_add(location=(7.5, -13.0, 5.0), rotation=(deg(74), 0, deg(28)))
    cam = bpy.context.active_object
    cam.name = "ActionCamera"
    cam.data.lens = 36.0
    scene.camera = cam

    # 3-point anime lighting
    bpy.ops.object.light_add(type='SUN', location=(5, -8, 10))
    sun = bpy.context.active_object
    sun.data.energy = 5.0

    bpy.ops.object.light_add(type='POINT', location=(-6, -7, 4))
    fill = bpy.context.active_object
    fill.data.energy = 280.0
    fill.data.color = (0.7, 0.92, 1.0)

    bpy.ops.object.light_add(type='POINT', location=(2, 6, 6))
    rim = bpy.context.active_object
    rim.data.energy = 420.0
    rim.data.color = (1.0, 0.45, 0.25)

    # Ground plane
    bpy.ops.mesh.primitive_plane_add(size=25.0, location=(0, 0, 0))
    ground = bpy.context.active_object
    gmat = bpy.data.materials.new(name="GroundMat")
    gmat.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = (0.16, 0.18, 0.22, 1.0)
    ground.data.materials.append(gmat)

    scene.render.resolution_x = 720
    scene.render.resolution_y = 720
    scene.render.image_settings.file_format = 'PNG'

    key_frames = [
        (0,  "geppo_f0_neutral.png"),
        (2,  "geppo_f2_anticipation_coil.png"),
        (4,  "geppo_f4_explosive_stomp.png"),
        (5,  "geppo_f5_post_impact.png"),
        (8,  "geppo_f8_ascent_drag.png"),
        (12, "geppo_f12_mid_ascent.png"),
        (18, "geppo_f18_apex_hangtime.png"),
        (24, "geppo_f24_descent.png"),
        (30, "geppo_f30_loop_seam.png"),
    ]

    for f_num, fname in key_frames:
        scene.frame_set(f_num)
        out_path = os.path.join(exports_dir, fname)
        scene.render.filepath = out_path
        bpy.ops.render.render(write_still=True)
        print(f"[Render] Frame {f_num} → {out_path}")


if __name__ == "__main__":
    generate_geppo_animation()
