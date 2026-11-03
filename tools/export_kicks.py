"""Export manual edits in chutes.blend without rebuilding the authored actions.

Run through tools/blender_mcp.py with the source blend open in Blender.
The CONTACT pose marker is imported as the native Godot ball-contact timestamp.
"""
import bpy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
scene = bpy.data.scenes['Varzea_KickStudio']
bpy.context.window.scene = scene
rig = next(o for o in scene.objects if o.type == 'ARMATURE')
for obj in scene.objects: obj.select_set(obj == rig or obj.name == 'Mannequin')
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=str(ROOT/'tools/source/kicks_authored.glb'),export_format='GLB',
    export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,
    export_frame_range=False,export_frame_step=1,export_yup=True,export_rest_position_armature=True,
    export_skins=True,export_morph=False,use_selection=True,use_active_scene=True)
fps = scene.render.fps/scene.render.fps_base
manifest = {'fps':fps,'skeleton_bones':len(rig.pose.bones),'clips':[]}
for name in ['Kick_Medium','Kick_Strong']:
    action = bpy.data.actions[name]
    contact = action.pose_markers['CONTACT'].frame/fps
    manifest['clips'].append({'name':name,'contact':contact,'length':action.frame_range.y/fps,
        'anticipation':action.pose_markers['ANTICIPATION'].frame/fps,
        'follow_through':action.pose_markers['FOLLOW_THROUGH'].frame/fps})
(ROOT/'docs/kick_animation_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('MANUAL_KICKS_EXPORTED',manifest)
