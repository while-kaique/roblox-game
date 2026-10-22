import bpy
import math

bpy.ops.wm.read_factory_settings(use_empty=True)

# 1. Create Armature
bpy.ops.object.armature_add(enter_editmode=True, align='WORLD', location=(0, 0, 0))
arm_obj = bpy.context.active_object
arm_obj.name = "Roblox_R15_Rig"
arm_data = arm_obj.data
arm_data.name = "Roblox_R15_Armature"

edit_bones = arm_data.edit_bones
for b in list(edit_bones):
    edit_bones.remove(b)

# Bones definitions: (name, head, tail, parent_name)
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

# 2. Create Geometry blocks
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
    
    # Assign vertex group
    vg = obj.vertex_groups.new(name=name)
    vg.add(range(len(obj.data.vertices)), 1.0, 'REPLACE')
    mesh_objects.append(obj)

# Join into single character mesh
bpy.context.view_layer.objects.active = mesh_objects[0]
for o in mesh_objects:
    o.select_set(True)
bpy.ops.object.join()
char_mesh = bpy.context.active_object
char_mesh.name = "Roblox_R15_Mesh"

# Add bevel modifier for sleek edges
bev = char_mesh.modifiers.new("Bevel", 'BEVEL')
bev.width = 0.04
bev.segments = 2

# Add Armature modifier
arm_mod = char_mesh.modifiers.new("Armature", 'ARMATURE')
arm_mod.object = arm_obj

# Camera & Light
bpy.ops.object.camera_add(location=(3.8, -6.5, 3.5), rotation=(math.radians(72), 0, math.radians(30)))
scene = bpy.context.scene
scene.camera = bpy.context.active_object

bpy.ops.object.light_add(type='SUN', location=(4, -4, 8))
sun = bpy.context.active_object
sun.data.energy = 4.0

# Add a ground plane with subtle grid
bpy.ops.mesh.primitive_plane_add(size=15.0, location=(0, 0, 0))

scene.render.resolution_x = 720
scene.render.resolution_y = 720
scene.render.filepath = r"C:\Users\airfryer\.gemini\antigravity\scratch\roblox-game\animations\exports\avatar_rest_test.png"
bpy.ops.render.render(write_still=True)
print("Avatar rest pose rendered successfully!")
