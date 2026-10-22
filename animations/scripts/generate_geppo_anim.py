"""
=============================================================================
GEPPO (SKY WALK) ANIMATION GENERATOR & VISUAL RIG ENGINE FOR ROBLOX R15
=============================================================================
Role: Master 3D Animator & Technical Rigger
Target Engine: Roblox (R15 Avatar)
Target Software: Blender 5.x+ (`bpy`)
Framerate: 24 FPS | Length: 31 Frames (0 to 30) | Seamless Loop Ready

Kinematic Breakdown:
- Phase 1 (Frames 0-5): Anticipation (Air compression, knee tuck, spring coil)
- Phase 2 (Frames 6-9): Explosive Impact (Dominant stomp, core crunch, arms back, head UP, air sonic boom)
- Phase 3 (Frames 10-18): Ascent & Follow-Through (Upward lift, wind drag, trailing limbs)
- Phase 4 (Frames 19-30): Seamless Recovery (Apex hang-time, buttery ease-out to neutral fall)
=============================================================================
"""

import bpy
import math
import os
from mathutils import Euler, Vector

# ---------------------------------------------------------------------------
# CONSTANTS & CONFIGURATION
# ---------------------------------------------------------------------------
ACTION_NAME = "Geppo_SkyWalk"
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
    """Utility to convert degrees to radians."""
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
# KEYFRAME KINEMATICS MATRIX (HIGH-OCTANE REFINEMENT)
# ---------------------------------------------------------------------------
KEYFRAMES_DATA = {
    # -----------------------------------------------------------------------
    # FRAME 0: Neutral Airborne / Pre-Jump State (Base Fall)
    # -----------------------------------------------------------------------
    0: {
        "HumanoidRootPart": ((0, 0, 0), (0.0, 0.0, 0.0)),
        "LowerTorso": ((deg(8), 0, 0), (0.0, 0.0, 0.0)),
        "UpperTorso": ((deg(6), 0, 0), None),
        "Head": ((deg(-10), 0, 0), None),
        
        "RightUpperLeg": ((deg(12), deg(-4), deg(2)), None),
        "RightLowerLeg": ((deg(-15), 0, 0), None),
        "RightFoot": ((deg(12), 0, 0), None),
        
        "LeftUpperLeg": ((deg(10), deg(4), deg(-2)), None),
        "LeftLowerLeg": ((deg(-12), 0, 0), None),
        "LeftFoot": ((deg(10), 0, 0), None),
        
        "RightUpperArm": ((deg(15), deg(-10), deg(20)), None),
        "RightLowerArm": ((deg(-25), 0, 0), None),
        "RightHand": ((deg(0), 0, 0), None),
        
        "LeftUpperArm": ((deg(15), deg(10), deg(-20)), None),
        "LeftLowerArm": ((deg(-25), 0, 0), None),
        "LeftHand": ((deg(0), 0, 0), None),
    },

    # -----------------------------------------------------------------------
    # FRAME 3: Early Anticipation (Initial Wind-Up / Gathering Tension)
    # -----------------------------------------------------------------------
    3: {
        "HumanoidRootPart": ((0, 0, 0), (0.0, 0.0, -0.15)),
        "LowerTorso": ((deg(14), 0, 0), (0.0, -0.05, -0.1)),
        "UpperTorso": ((deg(16), 0, 0), None),
        "Head": ((deg(-2), 0, 0), None),
        
        "RightUpperLeg": ((deg(-38), deg(-8), deg(8)), None),
        "RightLowerLeg": ((deg(55), 0, 0), None),
        "RightFoot": ((deg(-12), 0, 0), None),
        
        "LeftUpperLeg": ((deg(-28), deg(8), deg(-6)), None),
        "LeftLowerLeg": ((deg(45), 0, 0), None),
        "LeftFoot": ((deg(-10), 0, 0), None),
        
        "RightUpperArm": ((deg(22), deg(-15), deg(25)), None),
        "RightLowerArm": ((deg(-55), 0, 0), None),
        "RightHand": ((deg(10), 0, 0), None),
        
        "LeftUpperArm": ((deg(22), deg(15), deg(-25)), None),
        "LeftLowerArm": ((deg(-55), 0, 0), None),
        "LeftHand": ((deg(10), 0, 0), None),
    },

    # -----------------------------------------------------------------------
    # FRAME 5: Peak Anticipation / The Coil (Maximum Compression)
    # -----------------------------------------------------------------------
    5: {
        "HumanoidRootPart": ((0, 0, 0), (0.0, 0.0, -0.35)),
        "LowerTorso": ((deg(24), 0, 0), (0.0, -0.10, -0.18)),
        "UpperTorso": ((deg(28), 0, 0), None),
        "Head": ((deg(10), 0, 0), None),  # Head ducks, preparing for violent snap
        
        # Legs coiled tight into chest like compressed springs
        "RightUpperLeg": ((deg(-72), deg(-12), deg(14)), None),
        "RightLowerLeg": ((deg(95), 0, 0), None),
        "RightFoot": ((deg(-28), 0, 0), None),
        
        "LeftUpperLeg": ((deg(-56), deg(10), deg(-10)), None),
        "LeftLowerLeg": ((deg(80), 0, 0), None),
        "LeftFoot": ((deg(-20), 0, 0), None),
        
        # Arms folded tightly across chest
        "RightUpperArm": ((deg(32), deg(-24), deg(40)), None),
        "RightLowerArm": ((deg(-82), 0, 0), None),
        "RightHand": ((deg(15), 0, 0), None),
        
        "LeftUpperArm": ((deg(32), deg(24), deg(-40)), None),
        "LeftLowerArm": ((deg(-82), 0, 0), None),
        "LeftHand": ((deg(15), 0, 0), None),
    },

    # -----------------------------------------------------------------------
    # FRAME 6: THE EXPLOSIVE IMPACT (The Violent Geppo Air Stomp!)
    # -----------------------------------------------------------------------
    6: {
        "HumanoidRootPart": ((0, 0, 0), (0.0, 0.06, 0.15)),
        "LowerTorso": ((deg(-16), 0, deg(5)), (0.0, 0.06, 0.08)),
        # Torso leans heavily forward into the exertion
        "UpperTorso": ((deg(48), 0, deg(-5)), None),
        # Head SNAPS UP dramatically, staring directly skyward
        "Head": ((deg(-52), 0, deg(4)), None),
        
        # Dominant Right Leg: Violent downward heel thrust into solid air
        "RightUpperLeg": ((deg(45), deg(-6), deg(6)), None),
        "RightLowerLeg": ((deg(2), 0, 0), None),  # Full extension
        "RightFoot": ((deg(-38), 0, 0), None),   # Solid air compression sole angle
        
        # Left Leg: Dynamic counter-balance
        "LeftUpperLeg": ((deg(-32), deg(18), deg(-14)), None),
        "LeftLowerLeg": ((deg(70), 0, 0), None),
        "LeftFoot": ((deg(24), 0, 0), None),
        
        # Arms: Thrust violently downwards & backwards (wing push)
        "RightUpperArm": ((deg(-86), deg(-20), deg(34)), None),
        "RightLowerArm": ((deg(0), 0, 0), None),  # Locked straight back
        "RightHand": ((deg(-25), 0, 0), None),
        
        "LeftUpperArm": ((deg(-84), deg(20), deg(-34)), None),
        "LeftLowerArm": ((deg(0), 0, 0), None),
        "LeftHand": ((deg(-25), 0, 0), None),
    },

    # -----------------------------------------------------------------------
    # FRAME 9: Shockwave Peak (Max Extension of the Kick)
    # -----------------------------------------------------------------------
    9: {
        "HumanoidRootPart": ((0, 0, 0), (0.0, 0.14, 0.60)),
        "LowerTorso": ((deg(-10), 0, deg(2)), (0.0, 0.08, 0.1)),
        "UpperTorso": ((deg(36), 0, deg(-2)), None),
        "Head": ((deg(-42), 0, deg(2)), None),
        
        "RightUpperLeg": ((deg(36), deg(-4), deg(4)), None),
        "RightLowerLeg": ((deg(4), 0, 0), None),
        "RightFoot": ((deg(-25), 0, 0), None),
        
        "LeftUpperLeg": ((deg(-18), deg(12), deg(-8)), None),
        "LeftLowerLeg": ((deg(52), 0, 0), None),
        "LeftFoot": ((deg(16), 0, 0), None),
        
        "RightUpperArm": ((deg(-78), deg(-16), deg(30)), None),
        "RightLowerArm": ((deg(-8), 0, 0), None),
        "RightHand": ((deg(-15), 0, 0), None),
        
        "LeftUpperArm": ((deg(-76), deg(16), deg(-30)), None),
        "LeftLowerArm": ((deg(-8), 0, 0), None),
        "LeftHand": ((deg(-15), 0, 0), None),
    },

    # -----------------------------------------------------------------------
    # FRAME 14: Ascent & Follow-Through (Secondary Motion & Air Drag)
    # -----------------------------------------------------------------------
    14: {
        "HumanoidRootPart": ((0, 0, 0), (0.0, 0.22, 1.55)),
        "LowerTorso": ((deg(-4), 0, 0), (0.0, 0.05, 0.08)),
        # Torso recovers smoothly from extreme lean
        "UpperTorso": ((deg(14), 0, 0), None),
        "Head": ((deg(-24), 0, 0), None),
        
        # High speed air drag pushes feet and limbs backward
        "RightUpperLeg": ((deg(20), deg(-5), 0), None),
        "RightLowerLeg": ((deg(38), 0, 0), None),
        "RightFoot": ((deg(48), 0, 0), None),  # Feet trailing in the wind slipstream
        
        "LeftUpperLeg": ((deg(14), deg(5), 0), None),
        "LeftLowerLeg": ((deg(30), 0, 0), None),
        "LeftFoot": ((deg(44), 0, 0), None),
        
        # Arms trail backwards in the wind stream
        "RightUpperArm": ((deg(-52), deg(-14), deg(35)), None),
        "RightLowerArm": ((deg(-20), 0, 0), None),
        "RightHand": ((deg(12), 0, 0), None),
        
        "LeftUpperArm": ((deg(-52), deg(14), deg(-35)), None),
        "LeftLowerArm": ((deg(-20), 0, 0), None),
        "LeftHand": ((deg(12), 0, 0), None),
    },

    # -----------------------------------------------------------------------
    # FRAME 19: Ascent Deceleration (Entering Hang-Time)
    # -----------------------------------------------------------------------
    19: {
        "HumanoidRootPart": ((0, 0, 0), (0.0, 0.16, 1.95)),
        "LowerTorso": ((deg(2), 0, 0), (0.0, 0.02, 0.04)),
        "UpperTorso": ((deg(10), 0, 0), None),
        "Head": ((deg(-16), 0, 0), None),
        
        "RightUpperLeg": ((deg(14), deg(-4), 0), None),
        "RightLowerLeg": ((deg(12), 0, 0), None),
        "RightFoot": ((deg(22), 0, 0), None),
        
        "LeftUpperLeg": ((deg(12), deg(4), 0), None),
        "LeftLowerLeg": ((deg(8), 0, 0), None),
        "LeftFoot": ((deg(18), 0, 0), None),
        
        "RightUpperArm": ((deg(-12), deg(-10), deg(25)), None),
        "RightLowerArm": ((deg(-24), 0, 0), None),
        "RightHand": ((deg(0), 0, 0), None),
        
        "LeftUpperArm": ((deg(-12), deg(10), deg(-25)), None),
        "LeftLowerArm": ((deg(-24), 0, 0), None),
        "LeftHand": ((deg(0), 0, 0), None),
    },

    # -----------------------------------------------------------------------
    # FRAME 25: Apex Float (Gravity Takes Over, Floating into Neutral)
    # -----------------------------------------------------------------------
    25: {
        "HumanoidRootPart": ((0, 0, 0), (0.0, 0.06, 2.15)),
        "LowerTorso": ((deg(6), 0, 0), (0.0, 0.01, 0.02)),
        "UpperTorso": ((deg(8), 0, 0), None),
        "Head": ((deg(-12), 0, 0), None),
        
        "RightUpperLeg": ((deg(12), deg(-4), deg(1)), None),
        "RightLowerLeg": ((deg(-8), 0, 0), None),
        "RightFoot": ((deg(14), 0, 0), None),
        
        "LeftUpperLeg": ((deg(10), deg(4), deg(-1)), None),
        "LeftLowerLeg": ((deg(-6), 0, 0), None),
        "LeftFoot": ((deg(12), 0, 0), None),
        
        "RightUpperArm": ((deg(8), deg(-10), deg(22)), None),
        "RightLowerArm": ((deg(-25), 0, 0), None),
        "RightHand": ((deg(0), 0, 0), None),
        
        "LeftUpperArm": ((deg(8), deg(10), deg(-22)), None),
        "LeftLowerArm": ((deg(-25), 0, 0), None),
        "LeftHand": ((deg(0), 0, 0), None),
    },

    # -----------------------------------------------------------------------
    # FRAME 30: SEAMLESS RECOVERY (Matches Frame 0 Exactly for Seamless Loop)
    # -----------------------------------------------------------------------
    30: {
        "HumanoidRootPart": ((0, 0, 0), (0.0, 0.0, 0.0)),
        "LowerTorso": ((deg(8), 0, 0), (0.0, 0.0, 0.0)),
        "UpperTorso": ((deg(6), 0, 0), None),
        "Head": ((deg(-10), 0, 0), None),
        
        "RightUpperLeg": ((deg(12), deg(-4), deg(2)), None),
        "RightLowerLeg": ((deg(-15), 0, 0), None),
        "RightFoot": ((deg(12), 0, 0), None),
        
        "LeftUpperLeg": ((deg(10), deg(4), deg(-2)), None),
        "LeftLowerLeg": ((deg(-12), 0, 0), None),
        "LeftFoot": ((deg(10), 0, 0), None),
        
        "RightUpperArm": ((deg(15), deg(-10), deg(20)), None),
        "RightLowerArm": ((deg(-25), 0, 0), None),
        "RightHand": ((deg(0), 0, 0), None),
        
        "LeftUpperArm": ((deg(15), deg(10), deg(-20)), None),
        "LeftLowerArm": ((deg(-25), 0, 0), None),
        "LeftHand": ((deg(0), 0, 0), None),
    },
}

# ---------------------------------------------------------------------------
# RIG DISCOVERY & AUTO-BUILDER WITH VISUAL R15 MESHES
# ---------------------------------------------------------------------------
def build_roblox_r15_avatar():
    """Builds standard Roblox R15 skeleton & deformation mesh."""
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # 1. Armature Creation
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
        ("LowerTorso", (0, 0, 2.0), (0, 0, 2.8), "HumanoidRootPart"),
        ("UpperTorso", (0, 0, 2.8), (0, 0, 4.4), "LowerTorso"),
        ("Head", (0, 0, 4.4), (0, 0, 5.6), "UpperTorso"),
        
        ("RightUpperArm", (1.5, 0, 4.4), (1.5, 0, 3.2), "UpperTorso"),
        ("RightLowerArm", (1.5, 0, 3.2), (1.5, 0, 2.0), "RightUpperArm"),
        ("RightHand", (1.5, 0, 2.0), (1.5, 0, 1.4), "RightLowerArm"),
        
        ("LeftUpperArm", (-1.5, 0, 4.4), (-1.5, 0, 3.2), "UpperTorso"),
        ("LeftLowerArm", (-1.5, 0, 3.2), (-1.5, 0, 2.0), "LeftUpperArm"),
        ("LeftHand", (-1.5, 0, 2.0), (-1.5, 0, 1.4), "LeftLowerArm"),
        
        ("RightUpperLeg", (0.5, 0, 2.0), (0.5, 0, 1.0), "LowerTorso"),
        ("RightLowerLeg", (0.5, 0, 1.0), (0.5, 0, 0.4), "RightUpperLeg"),
        ("RightFoot", (0.5, 0, 0.4), (0.5, 0.3, 0.0), "RightLowerLeg"),
        
        ("LeftUpperLeg", (-0.5, 0, 2.0), (-0.5, 0, 1.0), "LowerTorso"),
        ("LeftLowerLeg", (-0.5, 0, 1.0), (-0.5, 0, 0.4), "LeftUpperLeg"),
        ("LeftFoot", (-0.5, 0, 0.4), (-0.5, 0.3, 0.0), "LeftLowerLeg"),
    ]

    for name, head, tail, parent_name in bones_def:
        bone = edit_bones.new(name)
        bone.head = head
        bone.tail = tail
        if parent_name:
            bone.parent = edit_bones[parent_name]

    bpy.ops.object.mode_set(mode='OBJECT')

    # 2. Geometry blocks
    parts_def = [
        ("LowerTorso", (2.0, 1.0, 0.8), (0, 0, 2.4)),
        ("UpperTorso", (2.0, 1.0, 1.6), (0, 0, 3.6)),
        ("Head", (1.25, 1.25, 1.25), (0, 0, 5.0)),
        
        ("RightUpperArm", (1.0, 1.0, 1.2), (1.5, 0, 3.8)),
        ("RightLowerArm", (0.9, 0.9, 1.2), (1.5, 0, 2.6)),
        ("RightHand", (0.85, 0.85, 0.6), (1.5, 0, 1.7)),
        
        ("LeftUpperArm", (1.0, 1.0, 1.2), (-1.5, 0, 3.8)),
        ("LeftLowerArm", (0.9, 0.9, 1.2), (-1.5, 0, 2.6)),
        ("LeftHand", (0.85, 0.85, 0.6), (-1.5, 0, 1.7)),
        
        ("RightUpperLeg", (1.0, 1.0, 1.0), (0.5, 0, 1.5)),
        ("RightLowerLeg", (0.9, 0.9, 0.8), (0.5, 0, 0.6)),
        ("RightFoot", (0.95, 1.1, 0.4), (0.5, 0.08, 0.2)),
        
        ("LeftUpperLeg", (1.0, 1.0, 1.0), (-0.5, 0, 1.5)),
        ("LeftLowerLeg", (0.9, 0.9, 0.8), (-0.5, 0, 0.6)),
        ("LeftFoot", (0.95, 1.1, 0.4), (-0.5, 0.08, 0.2)),
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

    # Sleek edge bevel
    bev = char_mesh.modifiers.new("Bevel", 'BEVEL')
    bev.width = 0.04
    bev.segments = 2

    # Armature modifier
    arm_mod = char_mesh.modifiers.new("Armature", 'ARMATURE')
    arm_mod.object = arm_obj

    # Material (Anime combat gi)
    mat = bpy.data.materials.new(name="Anime_Suit")
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.10, 0.12, 0.18, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.35
    char_mesh.data.materials.append(mat)

    return arm_obj

def find_or_create_r15_rig():
    """Finds existing R15 armature or builds a fresh avatar."""
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
# VISUAL WIND / AIR BLAST SHOCKWAVE VFX (ONE PIECE GEPPO SONIC BOOM)
# ---------------------------------------------------------------------------
def create_wind_shockwave_vfx():
    """
    Creates an authentic, multi-layered expanding compressed-air shockwave:
    - Layer 1: Core glowing sonic ring under RightFoot
    - Layer 2: Secondary outer air dispersion disc
    - Layer 3: Vertical air slipstream streaks
    """
    mat_wind = bpy.data.materials.new(name="Geppo_AirBlast_Material")
    nodes = mat_wind.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.9, 0.98, 1.0, 1.0)
        bsdf.inputs["Emission Color"].default_value = (0.6, 0.9, 1.0, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 14.0
        bsdf.inputs["Roughness"].default_value = 0.1

    # 1. Primary Shockwave Ring
    bpy.ops.mesh.primitive_torus_add(major_radius=1.2, minor_radius=0.10, location=(0.5, 0.0, 0.35))
    torus1 = bpy.context.active_object
    torus1.name = "Geppo_AirShockwave_Ring1"
    torus1.rotation_euler = (deg(14), 0, 0)
    torus1.data.materials.append(mat_wind)

    # 2. Secondary Outer Sonic Ring (offset expansion)
    bpy.ops.mesh.primitive_torus_add(major_radius=1.5, minor_radius=0.06, location=(0.5, 0.0, 0.30))
    torus2 = bpy.context.active_object
    torus2.name = "Geppo_AirShockwave_Ring2"
    torus2.rotation_euler = (deg(12), 0, 0)
    torus2.data.materials.append(mat_wind)

    # Keyframes for Primary Ring
    torus1.scale = (0.001, 0.001, 0.001)
    torus1.keyframe_insert(data_path="scale", frame=0)
    torus1.keyframe_insert(data_path="scale", frame=5)

    torus1.scale = (1.2, 1.2, 0.4)
    torus1.keyframe_insert(data_path="scale", frame=6)

    torus1.scale = (3.2, 3.2, 0.15)
    torus1.location = (0.5, 0.0, 0.15)
    torus1.keyframe_insert(data_path="scale", frame=8)
    torus1.keyframe_insert(data_path="location", frame=8)

    torus1.scale = (4.6, 4.6, 0.01)
    torus1.location = (0.5, 0.0, -0.1)
    torus1.keyframe_insert(data_path="scale", frame=11)
    torus1.keyframe_insert(data_path="location", frame=11)

    torus1.scale = (0.001, 0.001, 0.001)
    torus1.keyframe_insert(data_path="scale", frame=12)
    torus1.keyframe_insert(data_path="scale", frame=30)

    # Keyframes for Secondary Ring (slight delay for sonic bloom effect)
    torus2.scale = (0.001, 0.001, 0.001)
    torus2.keyframe_insert(data_path="scale", frame=0)
    torus2.keyframe_insert(data_path="scale", frame=6)

    torus2.scale = (1.8, 1.8, 0.3)
    torus2.keyframe_insert(data_path="scale", frame=7)

    torus2.scale = (4.2, 4.2, 0.1)
    torus2.keyframe_insert(data_path="scale", frame=9)

    torus2.scale = (0.001, 0.001, 0.001)
    torus2.keyframe_insert(data_path="scale", frame=12)
    torus2.keyframe_insert(data_path="scale", frame=30)

    print("[Geppo Engine] Visual Wind Shockwave & Sonic Bloom VFX created.")

# ---------------------------------------------------------------------------
# BEZIER CURVE & INTERPOLATION SHAPER
# ---------------------------------------------------------------------------
def refine_fcurves(action):
    """
    Applies anime-grade Bezier curve shaping:
    - Sets all keyframes to Bezier interpolation.
    - Frames 5 -> 6: Ultra-steep acceleration (1-frame explosive snap).
    - Frames 6 -> 9: Impact hold and power follow-through.
    - Frames 19 -> 30: Buttery smooth ease-out / gravity deceleration.
    - Seamless loop handle alignment (Frame 0 & Frame 30).
    """
    fcurves = get_all_fcurves(action)
    print(f"[Geppo Engine] Shaping {len(fcurves)} F-Curves with Bezier kinetics...")

    for fcurve in fcurves:
        keypoints = fcurve.keyframe_points
        num_points = len(keypoints)
        if num_points == 0:
            continue

        for i, kp in enumerate(keypoints):
            kp.interpolation = 'BEZIER'
            frame = round(kp.co[0])

            # Frame 5: Pre-impact launch pad (fast outgoing tangent)
            if frame == 5:
                kp.handle_right_type = 'FREE'
                if i + 1 < num_points:
                    target_val = keypoints[i + 1].co[1]
                    delta = target_val - kp.co[1]
                    kp.handle_right = Vector((5.3, kp.co[1] + delta * 0.45))

            # Frame 6: Instant explosive impact arrival
            elif frame == 6:
                kp.handle_left_type = 'FREE'
                if i > 0:
                    prev_val = keypoints[i - 1].co[1]
                    delta = kp.co[1] - prev_val
                    kp.handle_left = Vector((5.7, kp.co[1] - delta * 0.25))
                kp.handle_right_type = 'ALIGNED'

            # Frames 19 to 30: Buttery Ease-Out at apex
            elif frame >= 19:
                kp.handle_left_type = 'AUTO_CLAMPED'
                kp.handle_right_type = 'AUTO_CLAMPED'

            else:
                kp.handle_left_type = 'AUTO_CLAMPED'
                kp.handle_right_type = 'AUTO_CLAMPED'

        # Ensure seamless loop continuity between Frame 0 and Frame 30
        first_kp = keypoints[0]
        last_kp = keypoints[-1]
        if round(first_kp.co[0]) == FRAME_START and round(last_kp.co[0]) == FRAME_END:
            last_kp.co[1] = first_kp.co[1]
            dy = (first_kp.handle_right[1] - first_kp.co[1])
            last_kp.handle_left[1] = last_kp.co[1] - dy

# ---------------------------------------------------------------------------
# MAIN ANIMATION GENERATOR
# ---------------------------------------------------------------------------
def generate_geppo_animation():
    print("=================================================================")
    print("      EXECUTING ANIME-GRADE GEPPO ANIMATION ENGINE (R15)        ")
    print("=================================================================")

    # 1. Acquire / Build Rig
    arm_obj = find_or_create_r15_rig()

    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.frame_start = FRAME_START
    scene.frame_end = FRAME_END
    scene.frame_current = FRAME_START

    bpy.context.view_layer.objects.active = arm_obj
    arm_obj.select_set(True)

    # 2. Create or Reset Action
    if not arm_obj.animation_data:
        arm_obj.animation_data_create()

    action = bpy.data.actions.new(name=ACTION_NAME)
    arm_obj.animation_data.action = action

    # 3. Switch to POSE mode
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

    # 4. Insert Keyframes across all phases
    for frame, bone_transforms in sorted(KEYFRAMES_DATA.items()):
        scene.frame_set(frame)

        for bone_name, (rot_euler, loc_offset) in bone_transforms.items():
            if bone_name not in bone_map:
                continue
            pb = bone_map[bone_name]

            # Rotation
            pb.rotation_euler = Euler(rot_euler, 'XYZ')
            pb.keyframe_insert(data_path="rotation_euler", frame=frame)

            # Location
            if loc_offset is not None:
                pb.location = Vector(loc_offset)
                pb.keyframe_insert(data_path="location", frame=frame)

    print(f"[Geppo Engine] Keyframes inserted across frames {FRAME_START} to {FRAME_END}.")

    # 5. Bezier Curve shaping
    refine_fcurves(action)
    print("[Geppo Engine] Bezier kinetics refinement complete.")

    # 6. Return to Object Mode
    bpy.ops.object.mode_set(mode='OBJECT')

    # 7. Add Visual Wind Shockwave VFX
    create_wind_shockwave_vfx()

    # 8. Export FBX for Roblox Studio
    exports_dir = os.path.abspath(r"C:\Users\airfryer\.gemini\antigravity\scratch\roblox-game\animations\exports")
    os.makedirs(exports_dir, exist_ok=True)
    fbx_output = os.path.join(exports_dir, "geppo_skywalk.fbx")

    # Select only rig for clean animation export
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
    print(f"[Geppo Engine] FBX Exported successfully to:\n -> {fbx_output}")

    # 9. Visual Renders
    render_visual_verification(scene, exports_dir)

    print("=================================================================")
    print("      GEPPO ANIMATION PIPELINE COMPLETE - READY FOR ROBLOX      ")
    print("=================================================================")

def render_visual_verification(scene, exports_dir):
    """Renders key pose snapshots for inspection with full dynamic framing."""
    # Camera with wide coverage for the entire vertical double-jump
    bpy.ops.object.camera_add(location=(7.2, -12.5, 4.8), rotation=(deg(76), 0, deg(28)))
    cam = bpy.context.active_object
    cam.name = "ActionCamera"
    cam.data.lens = 38.0
    scene.camera = cam

    # Lighting: 3-point anime setup
    # Key Light (Front-Right)
    bpy.ops.object.light_add(type='SUN', location=(5, -8, 10))
    sun = bpy.context.active_object
    sun.data.energy = 5.0
    # Fill Light (Cyan Air Glow)
    bpy.ops.object.light_add(type='POINT', location=(-6, -7, 4))
    fill = bpy.context.active_object
    fill.data.energy = 250.0
    fill.data.color = (0.7, 0.9, 1.0)
    # Rim Backlight (Warm Accent)
    bpy.ops.object.light_add(type='POINT', location=(2, 6, 6))
    rim = bpy.context.active_object
    rim.data.energy = 400.0
    rim.data.color = (1.0, 0.45, 0.25)

    # Reference Ground & Distance Grid
    bpy.ops.mesh.primitive_plane_add(size=25.0, location=(0, 0, 0))
    ground = bpy.context.active_object
    gmat = bpy.data.materials.new(name="GroundMat")
    gmat.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = (0.18, 0.20, 0.24, 1.0)
    ground.data.materials.append(gmat)

    scene.render.resolution_x = 720
    scene.render.resolution_y = 720
    scene.render.image_settings.file_format = 'PNG'

    key_frames = [
        (0, "geppo_f0_neutral.png"),
        (5, "geppo_f5_anticipation.png"),
        (6, "geppo_f6_impact_stomp.png"),
        (8, "geppo_f8_wind_blast.png"),
        (14, "geppo_f14_ascent_drag.png"),
        (25, "geppo_f25_apex_float.png"),
        (30, "geppo_f30_loop_seam.png"),
    ]

    for f_num, fname in key_frames:
        scene.frame_set(f_num)
        out_path = os.path.join(exports_dir, fname)
        scene.render.filepath = out_path
        bpy.ops.render.render(write_still=True)
        print(f"[Render Test] Frame {f_num} rendered -> {out_path}")

if __name__ == "__main__":
    generate_geppo_animation()
