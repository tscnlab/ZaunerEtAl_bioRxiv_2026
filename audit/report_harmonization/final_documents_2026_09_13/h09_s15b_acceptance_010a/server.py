from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import urlsplit, unquote
import json, os

root = Path('/private/tmp/h09-s15b-independent.ZOy62t/serve').resolve(strict=True)
allowed = {'/', '/index.html', '/H09_observed_timing_patterns.svg'}
for p in root.rglob('*'):
    if p.is_symlink():
        raise RuntimeError('No symlinks allowed')

class Preview(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(root), **kwargs)
    def send_head(self):
        p = unquote(urlsplit(self.path).path)
        if p not in allowed:
            self.send_error(404)
            return None
        return super().send_head()
    def list_directory(self, path):
        self.send_error(403)
        return None

server = HTTPServer(('127.0.0.1', 0), Preview)
print(json.dumps({'pid':os.getpid(), 'host':'127.0.0.1', 'port':server.server_port, 'root':str(root)}),flush=True)
try:
    server.serve_forever()
except KeyboardInterrupt:
    pass
finally:
    server.server_close()
    print('CLOSED',flush=True)
