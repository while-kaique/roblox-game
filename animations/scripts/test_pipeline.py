import bpy
import math
import os

def setup_test_animation():
    # Reset scene
    bpy.ops.wm.read_factory_settings(use_empty=True)
    
    # Create armature
    bpy.ops.object.armature_add(enter_editmode=True, align='WORLD', location=(0, 0, 0))
    armature_obj = bpy.context.active_object
    armature_obj.name = "RobloxRig"
    armature_data = armature_obj.data
    armature_data.name = "RobloxArmature"
    
    # Configure edit bones
    edit_bones = armature_data.edit_bones
    root_bone = edit_bones[0]
    root_bone.name = "HumanoidRootPart"
    root_bone.head = (0, 0, 3)
    root_bone.tail = (0, 0, 3.5)
    
    torso_bone = edit_bones.new("UpperTorso")
    torso_bone.head = (0, 0, 3.5)
    torso_bone.tail = (0, 0, 4.5)
    torso_bone.parent = root_bone
    
    r_arm = edit_bones.new("RightUpperArm")
    r_arm.head = (1.2, 0, 4.3)
    r_arm.tail = (1.2, 0, 3.2)
    r_arm.parent = torso_bone
    
    # Switch to pose mode
    bpy.ops.object.mode_set(mode='POSE')
    
    # Animate punch/slash
    pose_bones = armature_obj.pose.bones
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 24
    
    # Frame 1: Wind-up
    scene.frame_set(1)
    pose_bones["RightUpperArm"].rotation_mode = 'XYZ'
    pose_bones["RightUpperArm"].rotation_euler = (math.radians(-30), math.radians(20), 0)
    pose_bones["RightUpperArm"].keyframe_insert(data_path="rotation_euler", frame=1)
    
    # Frame 12: Strike / Punch
    scene.frame_set(12)
    pose_bones["RightUpperArm"].rotation_euler = (math.radians(85), math.radians(-10), 0)
    pose_bones["RightUpperArm"].keyframe_insert(data_path="rotation_euler", frame=12)
    
    # Frame 24: Return
    scene.frame_set(24)
    pose_bones["RightUpperArm"].rotation_euler = (math.radians(0), math.radians(0), 0)
    pose_bones["RightUpperArm"].keyframe_insert(data_path="rotation_euler", frame=24)
    
    # Export FBX
    output_dir = os.path.abspath(r"C:\Users\airfryer\.gemini\antigravity\scratch\roblox-game\animations\exports")
    os.makedirs(output_dir, exist_ok=True)
    fbx_path = os.path.join(output_dir, "test_strike.fbx")
    
    bpy.ops.export_scene.fbx(
        filepath=fbx_path,
        use_selection=False,
        bake_anim=True,
        bake_anim_use_all_bones=True,
        bake_anim_step=1.0,
        add_leaf_bones=False
    )
    print("FBX Exported Successfully to:", fbx_path)

if __name__ == "__main__":
    setup_test_animation()
