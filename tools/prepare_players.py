"""Bake tiny region masks into the EXISTING UVs; strip unused photo/gun assets.

No vertices, indices, weights, bones or body morphs are changed. The shader
recolors the same masks for every player; the football AnimationLibrary is shared.
Run with Python + Pillow after build_body_types.py when rebuilding the GLBs.
"""
import copy
import json
import math
import struct
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/characters'
BACKUP = ROOT / 'tools/source/appearance_bases'
BACKUP.mkdir(parents=True, exist_ok=True)
REGIONS = {'skin': 1, 'shirt': 2, 'shorts': 3, 'socks': 4,
           'boots': 5, 'head': 6, 'optional_sleeve': 7, 'hand': 8, 'collar': 9}
COUNTS = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}
FORMATS = {5121: 'B', 5123: 'H', 5125: 'I', 5126: 'f'}


def load(path):
    raw = path.read_bytes()
    length = struct.unpack_from('<I', raw, 12)[0]
    doc = json.loads(raw[20:20+length])
    size = struct.unpack_from('<I', raw, 20+length)[0]
    return doc, bytearray(raw[28+length:28+length+size])


def accessor(doc, blob, index):
    item = doc['accessors'][index]; view = doc['bufferViews'][item['bufferView']]
    fmt = '<'+FORMATS[item['componentType']]*COUNTS[item['type']]
    step = view.get('byteStride', struct.calcsize(fmt))
    start = view.get('byteOffset', 0)+item.get('byteOffset', 0)
    return [struct.unpack_from(fmt, blob, start+i*step) for i in range(item['count'])]


def save(path, doc, blob):
    doc['buffers'] = [{'byteLength': len(blob)}]
    text = json.dumps(doc, separators=(',', ':')).encode('utf8')
    text += b' '*(-len(text)%4); blob += b'\0'*(-len(blob)%4)
    path.write_bytes(struct.pack('<III',0x46546c67,2,28+len(text)+len(blob))+
                     struct.pack('<I4s',len(text),b'JSON')+text+
                     struct.pack('<I4s',len(blob),b'BIN\0')+blob)


def region(point, bone):
    x,y,z = point
    bone = bone.lower()
    if bone.startswith(('hand','index','thumb','middle','ring','pinky')): return REGIONS['hand']
    if .94 < y < 1.54 and abs(x) < .30:
        # Neck-weighted collar triangles extend down the chest on these old shirts.
        # Classify their visible surface geometrically, rather than exposing whole triangles.
        neck_radius = math.hypot(x/.052,(z+.006)/.05)
        if y >= 1.518 and neck_radius < 1.12: return REGIONS['skin']
        if 1.50 <= y < 1.522 and neck_radius < 1.36: return REGIONS['collar']
        return REGIONS['shirt']
    if bone == 'head' or (y > 1.53 and abs(x) < .19): return REGIONS['head']
    if bone.startswith('neck') or (y > 1.49 and abs(x) < .13): return REGIONS['skin']
    if bone.startswith(('upperarm','lowerarm','clavicle')) or (abs(x) > .32 and y > 1.08):
        return REGIONS['optional_sleeve'] if abs(x) > .40 else REGIONS['shirt']
    if y < .14 or bone.startswith(('foot','ball')): return REGIONS['boots']
    if y < .37: return REGIONS['socks']
    if y < .67: return REGIONS['skin']
    if y < .94: return REGIONS['shorts']
    return REGIONS['shirt']


def bake_mask(doc, blob, name):
    size = 256
    image = Image.new('RGBA', (size,size), (1,0,0,0))
    painted = bytearray(size*size)
    pixels = image.load()
    skin = doc['skins'][0]
    names = [doc['nodes'][i]['name'] for i in skin['joints']]
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            attributes = primitive['attributes']
            positions = accessor(doc,blob,attributes['POSITION'])
            uv = accessor(doc,blob,attributes['TEXCOORD_0'])
            joints = accessor(doc,blob,attributes['JOINTS_0'])
            weights = accessor(doc,blob,attributes['WEIGHTS_0'])
            indices = [v[0] for v in accessor(doc,blob,primitive['indices'])]
            for i in range(0,len(indices),3):
                tri = indices[i:i+3]
                points = [positions[j] for j in tri]
                coords = [(uv[j][0]*size,uv[j][1]*size) for j in tri]
                (ax,ay),(bx,by),(cx,cy) = coords
                denom = (by-cy)*(ax-cx)+(cx-bx)*(ay-cy)
                if abs(denom) < 1e-7: continue
                # The region uses the triangle's actual skin influence, not its old photo colors.
                influences = {}
                for vertex in tri:
                    for joint,weight in zip(joints[vertex],weights[vertex]):
                        influences[joint] = influences.get(joint,0)+weight
                bone = names[max(influences,key=influences.get)]
                for y in range(max(0,math.floor(min(v[1] for v in coords))),min(size,math.ceil(max(v[1] for v in coords))+1)):
                    for x in range(max(0,math.floor(min(v[0] for v in coords))),min(size,math.ceil(max(v[0] for v in coords))+1)):
                        a = ((by-cy)*(x+.5-cx)+(cx-bx)*(y+.5-cy))/denom
                        b = ((cy-ay)*(x+.5-cx)+(ax-cx)*(y+.5-cy))/denom
                        c = 1-a-b
                        if min(a,b,c) < -.005: continue
                        p = tuple(a*points[0][j]+b*points[1][j]+c*points[2][j] for j in range(3))
                        label = region(p,bone)
                        # Rest-pose coordinates remain attached to the UVs during every animation.
                        h = round(max(0,min(1,p[1]/1.8))*255)
                        across = round(max(0,min(1,abs(p[0])))*255)
                        front = round(max(0,min(1,(p[2]+.2)/.4))*255)
                        pixels[x,y] = (label,h,across,front); painted[y*size+x] = 1
    # One-texel UV gutters prevent seams without creating any player-specific bitmap.
    original = image.copy(); source = original.load()
    for y in range(size):
        for x in range(size):
            if painted[y*size+x]: continue
            for dx,dy in [(0,-1),(0,1),(-1,0),(1,0),(-1,-1),(1,1)]:
                nx,ny = x+dx,y+dy
                if 0 <= nx < size and 0 <= ny < size and painted[ny*size+nx]:
                    pixels[x,y] = source[nx,ny]; break
    target = ASSETS/f'{name}_regions.png'
    image.save(target,optimize=True)
    return {'path': target.name, 'resolution': [size,size], 'bytes': target.stat().st_size,
            'regions': sorted({pixels[x,y][0] for y in range(size) for x in range(size)})}


def compact(doc, blob):
    # Remove the six old gun clips. Keep one tiny rest channel so the importer retains
    # the existing AnimationPlayer node; football clips come from the shared .res file.
    root = next(i for i,n in enumerate(doc['nodes']) if n.get('name') == 'root')
    new_channels = []
    for label,values,kind in [('rest_time',[(0.0,)],'SCALAR'),('rest_rotation',[doc['nodes'][root]['rotation']],'VEC4')]:
        while len(blob)%4: blob.append(0)
        offset = len(blob)
        for value in values: blob.extend(struct.pack('<'+'f'*len(value),*value))
        view = len(doc['bufferViews']); doc['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(blob)-offset})
        index = len(doc['accessors']); item = {'bufferView':view,'componentType':5126,'count':1,'type':kind}
        if kind == 'SCALAR': item.update({'min':[0.0],'max':[0.0]})
        doc['accessors'].append(item); new_channels.append(index)
    doc['animations'] = [{'name':'Rest','samplers':[{'input':new_channels[0],'output':new_channels[1]}],
                          'channels':[{'sampler':0,'target':{'node':root,'path':'rotation'}}]}]
    doc['materials'] = [{'name':'SharedPlayerBase','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1], 'metallicFactor':0,'roughnessFactor':1}}]
    for key in ['images','textures','samplers']: doc.pop(key,None)
    needed = set()
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            primitive['material'] = 0
            needed.update(primitive['attributes'].values()); needed.add(primitive['indices'])
            for target in primitive.get('targets',[]): needed.update(target.values())
    for skin in doc['skins']: needed.add(skin['inverseBindMatrices'])
    needed.update(new_channels)
    accessor_map = {old:new for new,old in enumerate(sorted(needed))}
    used_views = sorted({doc['accessors'][i]['bufferView'] for i in needed})
    views,packed = [],bytearray()
    view_map = {}
    for old in used_views:
        view = copy.deepcopy(doc['bufferViews'][old]); start = view.get('byteOffset',0)
        while len(packed)%4: packed.append(0)
        view['byteOffset'] = len(packed); view['buffer'] = 0
        packed.extend(blob[start:start+view['byteLength']])
        view_map[old] = len(views); views.append(view)
    accessors = []
    for old in sorted(needed):
        item = copy.deepcopy(doc['accessors'][old]); item['bufferView'] = view_map[item['bufferView']]
        accessors.append(item)
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            primitive['attributes'] = {k:accessor_map[v] for k,v in primitive['attributes'].items()}
            primitive['indices'] = accessor_map[primitive['indices']]
            for target in primitive.get('targets',[]):
                for key in target: target[key] = accessor_map[target[key]]
    for skin in doc['skins']: skin['inverseBindMatrices'] = accessor_map[skin['inverseBindMatrices']]
    for sampler in doc['animations'][0]['samplers']:
        sampler['input'] = accessor_map[sampler['input']]; sampler['output'] = accessor_map[sampler['output']]
    doc['accessors'] = accessors; doc['bufferViews'] = views
    doc.setdefault('asset',{}).setdefault('extras',{})['appearance_ready'] = True
    return doc,packed


def prepare(name):
    path = ASSETS/f'{name}.glb'
    doc,blob = load(path)
    source = BACKUP/path.name
    if not doc.get('asset',{}).get('extras',{}).get('appearance_ready'):
        source.write_bytes(path.read_bytes())
    doc,blob = load(source)
    before = copy.deepcopy(doc); original = bytes(blob)
    mask = bake_mask(doc,blob,name)
    doc,blob = compact(doc,blob)
    for old_mesh,new_mesh in zip(before['meshes'],doc['meshes']):
        for old,new in zip(old_mesh['primitives'],new_mesh['primitives']):
            for attribute in old['attributes']:
                assert accessor(before,original,old['attributes'][attribute]) == accessor(doc,blob,new['attributes'][attribute])
            assert accessor(before,original,old['indices']) == accessor(doc,blob,new['indices'])
            for a,b in zip(old['targets'],new['targets']):
                for key in a: assert accessor(before,original,a[key]) == accessor(doc,blob,b[key])
    assert before['nodes'] == doc['nodes']
    save(path,doc,blob)
    return {'mask':mask,'before_bytes':source.stat().st_size,'after_bytes':path.stat().st_size,
            'topology_uv_weights_bones_and_body_morphs_unchanged': True,
            'photo_textures_removed': True,'unused_gun_clips_removed':True}


if __name__ == '__main__':
    report = {name:prepare(name) for name in ['hero','enemy_a']}
    (ROOT/'docs/player_appearance_manifest.json').write_text(json.dumps(report,indent=2),encoding='utf8')
    for key,value in report.items(): print('PLAYER_ASSET',key,value)
