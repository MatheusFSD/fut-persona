"""Author two native Blender actions on the unmodified 65-bone UAL/Rio rig.

Run setup_kick_studio.py first, then this file through tools/blender_mcp.py.
The exported GLB is a source artifact; only its AnimationLibrary ships in Godot.
"""
import bpy
import json
import math
from pathlib import Path
from mathutils import Euler, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[1]
scene = bpy.data.scenes['Varzea_KickStudio']
bpy.context.window.scene = scene
rig = next(o for o in scene.objects if o.type == 'ARMATURE')
rig.animation_data.action = bpy.data.actions['Idle_Loop']
scene.frame_set(0)
bpy.context.view_layer.update()
base = {b.name: (b.location.copy(), b.rotation_quaternion.copy(), b.scale.copy()) for b in rig.pose.bones}
plant = rig.pose.bones['foot_l'].matrix.translation.copy()

# Angles are local radians. Opposite arm sweeps counter the trunk/hip turn.
MEDIUM = {
    'thigh_r': [( .72,0,.08),(-.80,.04,-.10),(-1.02,.12,-.14)],
    'calf_r': [(1.35,0,0),(.14,0,0),(.42,0,0)],
    'foot_r': [(.28,0,0),(-.20,0,0),(-.12,0,0)],
    'thigh_l': [(.10,0,-.04),(.12,0,-.04),(.08,0,-.03)],
    'calf_l': [(.16,0,0),(.20,0,0),(.12,0,0)],
    'pelvis': [(-.04,-.12,.04),(.04,.13,-.03),(.06,.20,-.02)],
    'spine_01': [(-.10,-.12,.04),(.12,.10,-.04),(.16,.16,-.03)],
    'spine_02': [(-.08,-.16,.03),(.16,.12,-.04),(.20,.18,-.04)],
    'upperarm_l': [(-.40,.12,.66),(.36,-.15,.54),(.58,-.22,.40)],
    'upperarm_r': [(.52,-.20,-.45),(-.65,.24,-.58),(-.75,.28,-.42)],
    'lowerarm_l': [(.20,.12,-.24),(.28,.04,-.18),(.38,0,-.14)],
    'lowerarm_r': [(.26,-.10,.24),(.32,0,.20),(.42,.02,.14)],
    'neck_01': [(.04,.06,0),(-.05,-.06,0),(-.07,-.08,0)],
}
STRONG = {
    'thigh_r': [(1.02,-.06,.12),(-1.03,.10,-.16),(-1.32,.22,-.22)],
    'calf_r': [(1.78,0,0),(.10,0,0),(.60,0,0)],
    'foot_r': [(.40,0,0),(-.30,0,0),(-.18,0,0)],
    'thigh_l': [(.14,0,-.06),(.18,0,-.07),(.10,0,-.05)],
    'calf_l': [(.24,0,0),(.30,0,0),(.18,0,0)],
    'pelvis': [(-.07,-.22,.08),(.06,.20,-.06),(.10,.32,-.05)],
    'spine_01': [(-.13,-.18,.06),(.17,.14,-.06),(.24,.22,-.06)],
    'spine_02': [(-.12,-.22,.06),(.22,.19,-.07),(.28,.26,-.07)],
    'upperarm_l': [(-.48,.22,.92),(.42,-.24,.78),(.80,-.32,.50)],
    'upperarm_r': [(.70,-.28,-.68),(-.84,.30,-.78),(-1.02,.38,-.52)],
    'lowerarm_l': [(.30,.16,-.32),(.44,.06,-.24),(.55,.02,-.20)],
    'lowerarm_r': [(.38,-.14,.32),(.50,0,.28),(.60,.03,.22)],
    'neck_01': [(.08,.08,0),(-.08,-.08,0),(-.10,-.12,0)],
}


def curves(action):
    return [f for layer in action.layers for strip in layer.strips
            for bag in strip.channelbags for f in bag.fcurves]


def action_pose(action, frame, bends, phase, amount):
    scene.frame_set(frame)
    for bone in rig.pose.bones:
        loc, rot, scale = base[bone.name]
        bone.rotation_mode = 'QUATERNION'
        bone.location = loc
        bone.scale = scale
        delta = Vector(bends.get(bone.name, [(0,0,0)]*3)[phase])*amount
        bone.rotation_quaternion = rot @ Euler(delta, 'XYZ').to_quaternion()
        bone.keyframe_insert('rotation_quaternion', frame=frame, group=bone.name)
        bone.keyframe_insert('location', frame=frame, group=bone.name)
        bone.keyframe_insert('scale', frame=frame, group=bone.name)


manifest = {'fps': 100, 'skeleton_bones': len(rig.pose.bones), 'clips': []}
for label, bends, contact, follow, length in [
        ('Kick_Medium', MEDIUM, 22, 32, 64),
        ('Kick_Strong', STRONG, 27, 39, 82)]:
    action = bpy.data.actions.get(label) or bpy.data.actions.new(label)
    if action.layers:
        for layer in list(action.layers): action.layers.remove(layer)
    rig.animation_data.action = action
    action.use_fake_user = True
    # Rapid weight shift -> loaded backswing -> contact -> follow-through -> recovery.
    for frame, phase, amount in [(0,0,0), (5,0,.28), (contact-9,0,1),
                                  (contact-4,0,1), (contact,1,1), (follow,2,1),
                                  (length-16,2,.38), (length,2,0)]:
        action_pose(action,frame,bends,phase,amount)
    for curve in curves(action):
        for key in curve.keyframe_points:
            key.interpolation = 'BEZIER'; key.handle_left_type = 'AUTO_CLAMPED'; key.handle_right_type = 'AUTO_CLAMPED'
    # Bake pelvis compensation at 100 Hz. The left support foot stays on its mark;
    # root motion, mesh vertices, weights, inverse binds and rest bones stay intact.
    offsets = []
    for frame in range(length+1):
        scene.frame_set(frame); bpy.context.view_layer.update()
        offset = plant-rig.pose.bones['foot_l'].matrix.translation
        pelvis = rig.pose.bones['pelvis']
        matrix = pelvis.matrix.copy(); matrix.translation += offset
        pelvis.matrix = matrix
        offsets.append((frame,pelvis.location.copy()))
    pelvis = rig.pose.bones['pelvis']
    for frame, location in offsets:
        pelvis.location = location; pelvis.keyframe_insert('location',frame=frame,group='pelvis')
    for curve in curves(action):
        if curve.data_path.endswith('.location') and 'pelvis' in curve.data_path:
            for key in curve.keyframe_points: key.interpolation = 'LINEAR'
    for old_marker in list(action.pose_markers): action.pose_markers.remove(old_marker)
    for label_marker, frame in [('ANTICIPATION',contact-9),('CONTACT',contact),('FOLLOW_THROUGH',follow)]:
        marker = action.pose_markers.new(label_marker); marker.frame = frame
    action['contact_seconds'] = contact/100
    action['length_seconds'] = length/100
    manifest['clips'].append({'name': label,'contact': contact/100,'length': length/100,
                              'anticipation': (contact-9)/100,'follow_through': follow/100})
    print('AUTHORED',label,'contact',contact/100,'length',length/100,'curves',len(curves(action)))

rig.animation_data.action = bpy.data.actions['Kick_Strong']
scene.frame_start = 0; scene.frame_end = 82; scene.frame_set(13)
bpy.context.view_layer.objects.active = rig
rig.select_set(True)
for obj in scene.objects: obj.select_set(obj == rig or obj.name == 'Mannequin')
out = ROOT / 'tools/source/kicks_authored.glb'
bpy.ops.export_scene.gltf(filepath=str(out), export_format='GLB', export_animations=True,
                          export_animation_mode='ACTIONS', export_force_sampling=True,
                          export_frame_range=False, export_frame_step=1,
                          export_yup=True, export_rest_position_armature=True,
                          export_skins=True, export_morph=False,
                          use_selection=True, use_active_scene=True)
(ROOT / 'docs/kick_animation_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'tools/source/chutes.blend'), copy=True)
print('KICKS_SAVED',out,'actions',[(a.name,tuple(a.frame_range)) for a in bpy.data.actions])
