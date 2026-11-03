"""Run inside Blender through the local Blender MCP add-on."""
import bpy
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
source = ROOT / 'tools/source/UAL1_Standard.glb'
data = source.read_bytes()
size = struct.unpack_from('<I', data, 12)[0]
doc = json.loads(data[20:20+size])
blob = data[28+size:]
doc['animations'] = [a for a in doc['animations'] if a['name'] == 'Idle_Loop']
encoded = json.dumps(doc, separators=(',', ':')).encode()
encoded += b' ' * (-len(encoded) % 4)
base = ROOT / '.runtime/kick-base.glb'
base.parent.mkdir(parents=True,exist_ok=True)
base.write_bytes(struct.pack('<III', 0x46546c67, 2, 28+len(encoded)+len(blob))+
                 struct.pack('<I4s', len(encoded), b'JSON')+encoded+
                 struct.pack('<I4s', len(blob), b'BIN\0')+blob)
scene = bpy.data.scenes.get('Varzea_KickStudio')
if scene is None:
    scene = bpy.data.scenes.new('Varzea_KickStudio')
    bpy.context.window.scene = scene
    original_debug = bpy.app.debug_value
    try:
        # Importer's documented implementation skips bone prettification at 100.
        # This preserves the exact glTF joint bases used by Godot's RioRig.
        bpy.app.debug_value = 100
        bpy.ops.import_scene.gltf(filepath=str(base), guess_original_bind_pose=False)
    finally:
        bpy.app.debug_value = original_debug
else:
    bpy.context.window.scene = scene
scene.render.fps = 100
rig = next(o for o in scene.objects if o.type == 'ARMATURE')
rig['varzea_authoring'] = True
print('KICK_STUDIO',rig.name,'bones',len(rig.pose.bones),'action',rig.animation_data.action.name)
print('BONES',[(b.name,tuple(round(x,4) for x in b.rotation_quaternion)) for b in rig.pose.bones if b.name in ['pelvis','thigh_r','calf_r','upperarm_l','upperarm_r','spine_02']])
print('ACTIONS',[a.name for a in bpy.data.actions])
