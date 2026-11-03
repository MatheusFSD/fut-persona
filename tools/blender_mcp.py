"""Local client for the installed Blender MCP add-on (no external service).

python3 tools/blender_mcp.py --script tools/author_kicks.py
"""
import argparse
import json
import socket
from pathlib import Path


def command(kind, params=None):
    with socket.create_connection(('127.0.0.1', 9876), timeout=5) as connection:
        connection.settimeout(120)
        connection.sendall(json.dumps({'type': kind, 'params': params or {}}).encode())
        buffer = bytearray()
        while True:
            block = connection.recv(1024 * 1024)
            if not block:
                raise RuntimeError('Blender MCP closed before returning a response')
            buffer.extend(block)
            try:
                response = json.loads(buffer)
                if response.get('status') != 'success':
                    raise RuntimeError(response)
                return response
            except json.JSONDecodeError:
                continue


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--script', type=Path)
    args = parser.parse_args()
    if args.script:
        path = args.script.resolve()
        code = '__file__=%r; exec(compile(open(__file__, encoding="utf-8").read(), __file__, "exec"))' % str(path)
        result = command('execute_code', {'code': code})
    else:
        result = command('get_scene_info')
    print(json.dumps(result, ensure_ascii=True))
