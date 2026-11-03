"""Bake team shirts onto copies of the original embedded textures.
Uses rest-pose triangle UVs, so the kit follows skinning during the slide too.
Only needed to rebuild the PNGs; the game has no Python dependency.
"""
import io
import json
import math
import struct
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

def prepare(name, color):
    data = (ROOT / 'assets/characters' / f'{name}.glb').read_bytes()
    size = struct.unpack_from('<I', data, 12)[0]
    doc = json.loads(data[20:20 + size])
    buffer = data[28 + size:]

    def accessor(index):
        item = doc['accessors'][index]
        view = doc['bufferViews'][item['bufferView']]
        code = {5126: 'f', 5125: 'I', 5123: 'H', 5121: 'B'}[item['componentType']]
        count = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[item['type']]
        fmt = '<' + code * count
        stride = view.get('byteStride', struct.calcsize(fmt))
        start = view.get('byteOffset', 0) + item.get('byteOffset', 0)
        return [struct.unpack_from(fmt, buffer, start + i * stride) for i in range(item['count'])]

    view = doc['bufferViews'][doc['images'][0]['bufferView']]
    start = view.get('byteOffset', 0)
    image = Image.open(io.BytesIO(buffer[start:start+view['byteLength']])).convert('RGB')
    width, height = image.size
    mask = Image.new('L', image.size)
    pixels = mask.load()
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            positions = accessor(primitive['attributes']['POSITION'])
            uvs = accessor(primitive['attributes']['TEXCOORD_0'])
            indices = [v[0] for v in accessor(primitive['indices'])]
            for start in range(0, len(indices), 3):
                tri = indices[start:start+3]
                p = [positions[i] for i in tri]
                if max(v[1] for v in p) < .9 or min(v[1] for v in p) > 1.54:
                    continue
                uv = [(uvs[i][0]*width, uvs[i][1]*height) for i in tri]
                (ax,ay),(bx,by),(cx,cy) = uv
                denom = (by-cy)*(ax-cx) + (cx-bx)*(ay-cy)
                if abs(denom) < 1e-5:
                    continue
                for y in range(max(0, math.floor(min(v[1] for v in uv))), min(height, math.ceil(max(v[1] for v in uv))+1)):
                    for x in range(max(0, math.floor(min(v[0] for v in uv))), min(width, math.ceil(max(v[0] for v in uv))+1)):
                        a = ((by-cy)*(x+.5-cx) + (cx-bx)*(y+.5-cy)) / denom
                        b = ((cy-ay)*(x+.5-cx) + (ax-cx)*(y+.5-cy)) / denom
                        c = 1-a-b
                        if min(a,b,c) < -.01:
                            continue
                        py = a*p[0][1] + b*p[1][1] + c*p[2][1]
                        px = a*p[0][0] + b*p[1][0] + c*p[2][0]
                        if .90 < py < 1.53 and abs(px) < .81:
                            pixels[x,y] = 255
    # Expand by one texel to prevent the original cloth bleeding at UV edges.
    from PIL import ImageFilter
    mask = mask.filter(ImageFilter.MaxFilter(3))
    result = image.copy()
    for y in range(height):
        for x in range(width):
            if not mask.getpixel((x,y)):
                continue
            original = image.getpixel((x,y))
            shade = .65 + sum(original) / (3*255) * .35
            tinted = tuple(round(component * shade) for component in color)
            result.putpixel((x,y), tinted)
    target = ROOT / 'assets/characters' / f'{name}_kit.png'
    result.save(target)
    print('KIT_READY', target.name)

if __name__ == '__main__':
    prepare('hero', (239,179,78))
    prepare('enemy_a', (69,164,183))
