"""Run with Blender --background --python tools/build_body_types.py.

Edit the EXISTING indexed GLB vertices into four morph targets. Never remesh,
subdivide, append body parts, change UVs, change weights, or add skeleton bones.
The base positions/indices/skin/animations remain byte-for-byte intact.
Short bodies use the same bones with scaled rest translations and inverse binds
at runtime (scripts/body_types.gd), plus matching animation translations.
"""
import hashlib
import json
import math
import struct
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/characters'
BASES = ROOT / 'tools/source/body_bases'
BASES.mkdir(parents=True, exist_ok=True)
SHORT = .84
TARGETS = [('Magro', 'slim', 1.0), ('Parrudo', 'stocky', 1.0),
           ('BaixoMagro', 'slim', SHORT), ('BaixoParrudo', 'stocky', SHORT)]
TYPES = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}
FORMATS = {5121: 'B', 5123: 'H', 5125: 'I', 5126: 'f'}


def load_glb(path):
    raw = path.read_bytes()
    size = struct.unpack_from('<I', raw, 12)[0]
    doc = json.loads(raw[20:20+size])
    binary_size = struct.unpack_from('<I', raw, 20+size)[0]
    return doc, bytearray(raw[28+size:28+size+binary_size])


def read_accessor(doc, binary, index):
    accessor = doc['accessors'][index]
    view = doc['bufferViews'][accessor['bufferView']]
    fmt = '<' + FORMATS[accessor['componentType']] * TYPES[accessor['type']]
    stride = view.get('byteStride', struct.calcsize(fmt))
    start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
    return [struct.unpack_from(fmt, binary, start+i*stride) for i in range(accessor['count'])]


def accessor_bytes(doc, binary, index):
    return b''.join(struct.pack('<' + FORMATS[doc['accessors'][index]['componentType']] *
                               TYPES[doc['accessors'][index]['type']], *v)
                    for v in read_accessor(doc, binary, index))


def append_vectors(doc, binary, vectors, label):
    while len(binary) % 4:
        binary.append(0)
    offset = len(binary)
    for v in vectors:
        binary.extend(struct.pack('<3f', *v))
    view = len(doc['bufferViews'])
    doc['bufferViews'].append({'buffer': 0, 'byteOffset': offset,
                              'byteLength': len(vectors)*12, 'target': 34962})
    index = len(doc['accessors'])
    doc['accessors'].append({'bufferView': view, 'componentType': 5126,
                            'count': len(vectors), 'type': 'VEC3', 'name': label,
                            'min': [min(v[i] for v in vectors) for i in range(3)],
                            'max': [max(v[i] for v in vectors) for i in range(3)]})
    return index


def save_glb(path, doc, binary):
    doc['buffers'][0]['byteLength'] = len(binary)
    encoded = json.dumps(doc, separators=(',', ':'), ensure_ascii=False).encode('utf8')
    encoded += b' ' * (-len(encoded) % 4)
    binary += b'\0' * (-len(binary) % 4)
    total = 12 + 8 + len(encoded) + 8 + len(binary)
    path.write_bytes(struct.pack('<III', 0x46546c67, 2, total) +
                     struct.pack('<I4s', len(encoded), b'JSON') + encoded +
                     struct.pack('<I4s', len(binary), b'BIN\0') + binary)


def radial_scales(bone, build):
    # Local Y follows the bone. Only the cross-section changes, preserving joints.
    name = bone.lower()
    if build == 'slim':
        if name.startswith('spine'): return (.77, .74)
        if name == 'pelvis': return (.84, .80)
        if name.startswith(('clavicle', 'upperarm')): return (.73, .73)
        if name.startswith('lowerarm'): return (.77, .77)
        if name.startswith('thigh'): return (.74, .74)
        if name.startswith('calf'): return (.75, .75)
        if name.startswith('neck'): return (.88, .88)
    else:
        if name == 'spine_03': return (1.40, 1.46)
        if name.startswith('spine'): return (1.32, 1.42)
        if name == 'pelvis': return (1.21, 1.25)
        if name.startswith(('clavicle', 'upperarm')): return (1.48, 1.48)
        if name.startswith('lowerarm'): return (1.32, 1.32)
        if name.startswith('thigh'): return (1.39, 1.39)
        if name.startswith('calf'): return (1.28, 1.28)
        if name.startswith('neck'): return (1.14, 1.14)
    return (1.0, 1.0)


def deform(positions, joints, weights, names, inverse_bind, build, height):
    rest = [m.inverted() for m in inverse_bind]
    output = []
    for original, ids, values in zip(positions, joints, weights):
        p = Vector(original)
        result = Vector((0, 0, 0))
        total = 0.0
        for joint, weight in zip(ids, values):
            if weight <= 0:
                continue
            bone = names[joint]
            local = inverse_bind[joint] @ p
            sx, sz = radial_scales(bone, build)
            local.x *= sx
            local.z *= sz
            frame = rest[joint]
            # Keep the face/head size recognizable on shorter adult bodies.
            local_size = 1.0 if bone == 'Head' else height
            q = frame.translation * height + frame.to_3x3() @ (local * local_size)
            result += q * weight
            total += weight
        result = result/total if total else p*height
        # Preserve the sole plane; no floating feet or ankle offsets at rest.
        if p.y < .10:
            result.y = p.y * height
        output.append(result)
    return output


def normals_for(positions, triangles, fallback):
    normals = [Vector((0, 0, 0)) for _ in positions]
    for i in range(0, len(triangles), 3):
        a, b, c = triangles[i:i+3]
        normal = (positions[b]-positions[a]).cross(positions[c]-positions[a])
        for vertex in (a, b, c): normals[vertex] += normal
    return [n.normalized() if n.length_squared > 1e-15 else Vector(old)
            for n, old in zip(normals, fallback)]


def build(name):
    source = BASES / f'{name}.glb'
    if not source.exists():
        source.write_bytes((ASSETS / f'{name}.glb').read_bytes())
    doc, binary = load_glb(source)
    original_binary = bytes(binary)
    original_accessor_count = len(doc['accessors'])
    skin = doc['skins'][0]
    names = [doc['nodes'][node]['name'] for node in skin['joints']]
    inverse_bind = [Matrix([v[i:i+4] for i in range(0,16,4)]).transposed()
                    for v in read_accessor(doc, binary, skin['inverseBindMatrices'])]
    report = {'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
              'bones': len(names), 'targets': {}, 'invariants': {}}
    for mesh in doc['meshes']:
        mesh.setdefault('extras', {})['targetNames'] = [entry[0] for entry in TARGETS]
        mesh['weights'] = [0.0]*len(TARGETS)
        for primitive in mesh['primitives']:
            attributes = primitive['attributes']
            positions = read_accessor(doc, binary, attributes['POSITION'])
            normals = read_accessor(doc, binary, attributes['NORMAL'])
            joints = read_accessor(doc, binary, attributes['JOINTS_0'])
            weights = read_accessor(doc, binary, attributes['WEIGHTS_0'])
            triangles = [v[0] for v in read_accessor(doc, binary, primitive['indices'])]
            primitive['targets'] = []
            report['vertices'] = len(positions)
            report['triangles'] = len(triangles)//3
            for label, body, height in TARGETS:
                changed = deform(positions, joints, weights, names, inverse_bind, body, height)
                new_normals = normals_for(changed, triangles, normals)
                position_deltas = [p-Vector(old) for p, old in zip(changed, positions)]
                normal_deltas = [p-Vector(old) for p, old in zip(new_normals, normals)]
                primitive['targets'].append({
                    'POSITION': append_vectors(doc, binary, position_deltas, label+'_positions'),
                    'NORMAL': append_vectors(doc, binary, normal_deltas, label+'_normals')})
                report['targets'][label] = {
                    'height_scale': height,
                    'min': [round(min(v[i] for v in changed),5) for i in range(3)],
                    'max': [round(max(v[i] for v in changed),5) for i in range(3)]}
    # Appending morph deltas must leave every original accessor byte untouched.
    for index in range(original_accessor_count):
        assert accessor_bytes(doc, binary, index) == accessor_bytes(doc, original_binary, index)
    report['invariants'] = {'all_original_accessors_identical': True,
                            'same_vertex_count': True, 'same_triangle_indices': True,
                            'same_uvs': True, 'same_joint_indices_and_weights': True,
                            'same_65_bones': len(names) == 65, 'normal_base_unchanged': True}
    target = ASSETS / f'{name}.glb'
    save_glb(target, doc, binary)
    print('BODY_TYPES_READY', name, json.dumps(report, ensure_ascii=True))
    return report


reports = {name: build(name) for name in ['hero', 'enemy_a']}
# Import in a fresh background Blender scene to confirm real mesh/shape-key/rig integrity.
# The user's open Blender session is never touched, and no remeshing operators are used.
for obj in list(bpy.data.objects): bpy.data.objects.remove(obj, do_unlink=True)
for name in ['hero', 'enemy_a']:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(ASSETS / f'{name}.glb'), merge_vertices=False)
    imported = set(bpy.data.objects)-before
    meshes = [o for o in imported if o.type == 'MESH' and any(m.type == 'ARMATURE' for m in o.modifiers)]
    rigs = [o for o in imported if o.type == 'ARMATURE']
    assert len(meshes) == 1 and len(rigs) == 1
    mesh, rig = meshes[0], rigs[0]
    assert len(mesh.data.vertices) == reports[name]['vertices']
    assert len(rig.data.bones) == 65
    assert len(mesh.data.shape_keys.key_blocks) == 5
    assert sum(len(v.groups) for v in mesh.data.vertices) > 0
    reports[name]['blender_validation'] = {
        'mesh_vertices': len(mesh.data.vertices), 'polygons': len(mesh.data.polygons),
        'bones': len(rig.data.bones),
        'shape_keys': [key.name for key in mesh.data.shape_keys.key_blocks]}
    for obj in imported: bpy.data.objects.remove(obj, do_unlink=True)
(ROOT / 'docs/body_types_manifest.json').write_text(json.dumps(reports, indent=2), encoding='utf8')
print('BODY_TYPES_BLENDER_VALIDATED')
