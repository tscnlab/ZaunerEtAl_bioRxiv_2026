"""One read-only SVG compatibility review of the unchanged round-2 HTML."""
import hashlib
import json
import os
import signal
import time
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import unquote, urlsplit

P = Path(__file__).resolve().parents[1]
ROOT = P / 'project/manuscript/R0_NatHealth/render_html_round2'
E = P / 'evidence/svg_browser_adjudication'
E.mkdir(exist_ok=False)

def inventory():
    result = []
    for f in ROOT.rglob('*'):
        if f.is_symlink():
            raise RuntimeError('Symlink in published output')
        if f.is_file():
            result.append(dict(path=str(f.relative_to(ROOT)), bytes=f.stat().st_size,
                               sha256=hashlib.sha256(f.read_bytes()).hexdigest()))
    return sorted(result, key=lambda x: x['path'])

before = inventory()
(E / 'before.json').write_text(json.dumps(before, indent=2))

class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)
    def log_message(self, fmt, *values):
        with (E / 'requests.log').open('a') as out:
            out.write('%s %s\n' % (self.log_date_time_string(), fmt % values))
    def allowed(self):
        rel = unquote(urlsplit(self.path).path).lstrip('/')
        target = (ROOT / rel).resolve()
        return bool(rel) and target.is_relative_to(ROOT.resolve()) and target.is_file() and not target.is_symlink() and target.suffix.lower() in {'.html', '.css', '.js', '.svg', '.png', '.jpg', '.woff', '.woff2', '.ttf'}
    def do_GET(self):
        if not self.allowed():
            self.send_error(404)
            return
        super().do_GET()
    def do_HEAD(self):
        if not self.allowed():
            self.send_error(404)
            return
        super().do_HEAD()
    def list_directory(self, path):
        self.send_error(403)
        return None

server = HTTPServer(('127.0.0.1', 0), Handler)
runtime = dict(pid=os.getpid(), host='127.0.0.1', port=server.server_port,
               root=str(ROOT), started=time.time(), methods=['GET', 'HEAD'])
(E / 'runtime.json').write_text(json.dumps(runtime, indent=2))
print(json.dumps(runtime), flush=True)
def stop(sig, frame):
    raise KeyboardInterrupt
signal.signal(signal.SIGTERM, stop)
try:
    server.serve_forever(poll_interval=.2)
except KeyboardInterrupt:
    pass
finally:
    server.server_close()
    after = inventory()
    (E / 'after.json').write_text(json.dumps(after, indent=2))
    (E / 'teardown.json').write_text(json.dumps(dict(pid=os.getpid(), closed=True,
        ended=time.time(), content_unchanged=before == after), indent=2))
    if before != after:
        raise RuntimeError('Published files changed during read-only review')
