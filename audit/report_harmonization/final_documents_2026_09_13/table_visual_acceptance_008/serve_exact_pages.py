"""Read-only exact-route localhost review; no render or authoring."""
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import urlsplit
import csv, datetime, hashlib, json, os, signal

AUDIT = Path('/private/tmp/table007-independent.sXVqTc')
PKG = Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14')
ROOT = PKG / 'attempt_02/pages'
def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(PKG / 'package_manifest.csv') == '1b5deb90c0c11cd0e931e6b13c00fedf5551920b9be1e890f86ba878ccfceb3b'
with (PKG / 'package_manifest.csv').open() as f:
    members = list(csv.DictReader(f))
pre = {m['path']: {'bytes': int(m['bytes']), 'sha256': m['sha256']} for m in members}
assert len(pre) == 263
assert all((PKG / p).stat().st_size == m['bytes'] and sha(PKG / p) == m['sha256'] for p, m in pre.items())
expected = {p.removeprefix('attempt_02/pages/'): m['sha256'] for p, m in pre.items() if p.startswith('attempt_02/pages/')}
assert len(expected) == 6 and ROOT.is_dir() and not ROOT.is_symlink()
assert not any(p.is_symlink() for p in ROOT.rglob('*'))
assert {p.name for p in ROOT.iterdir()} == set(expected)
(AUDIT / 'browser_preflight.json').write_text(json.dumps({'root': str(ROOT), 'symlinks': 0, 'members': pre, 'routes': expected}, indent=2))
class Handler(BaseHTTPRequestHandler):
    def do_HEAD(self): self.respond(False)
    def do_GET(self): self.respond(True)
    def respond(self, body):
        u = urlsplit(self.path)
        name = u.path.removeprefix('/')
        if u.query or name not in expected or u.path != '/' + name:
            self.send_error(404); return
        p = ROOT / name
        if p.is_symlink() or sha(p) != expected[name]:
            self.send_error(409); return
        content = p.read_bytes()
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', str(len(content)))
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.end_headers()
        if body: self.wfile.write(content)
server = HTTPServer(('127.0.0.1', 0), Handler)
start = {'pid': os.getpid(), 'host': server.server_address[0], 'port': server.server_address[1], 'root': str(ROOT), 'routes': list(expected), 'methods': ['GET', 'HEAD'], 'time': datetime.datetime.now(datetime.timezone.utc).isoformat()}
(AUDIT / 'browser_server_start.json').write_text(json.dumps(start, indent=2))
print(json.dumps(start), flush=True)
signal.signal(signal.SIGTERM, lambda *_: (_ for _ in ()).throw(KeyboardInterrupt()))
try:
    server.serve_forever()
except KeyboardInterrupt:
    pass
finally:
    server.server_close()
    post = {p: {'bytes': (PKG / p).stat().st_size, 'sha256': sha(PKG / p)} for p in pre}
    result = {'stopped': True, 'all_263_exact': post == pre, 'pid': start['pid'], 'port': start['port'], 'members': post, 'time': datetime.datetime.now(datetime.timezone.utc).isoformat()}
    (AUDIT / 'browser_postflight.json').write_text(json.dumps(result, indent=2))
    print(json.dumps({'stopped': True, 'all_263_exact': post == pre}), flush=True)
    assert post == pre
