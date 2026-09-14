"""One-route, GET/HEAD-only loopback server for immutable Order014 visual QA."""
from pathlib import Path
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlsplit
import hashlib
import json
import os
import signal
import shutil
import tempfile
from datetime import datetime, timezone

qa = Path('audit/manuscript_nature_health/a4_display_revision_2026_09_14/html_visual_qa').resolve()
source = qa.parent / 'html_candidate_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html'
pin = 'd7ee926c0910227004581915040f30ae01142290f0759839e897fa2b3f5f10aa'
digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert digest(source)==pin
preflight = qa/'serve_root_preflight.json'
if preflight.exists():
    serve = Path(json.loads(preflight.read_text())['root'])
    assert serve.parent==Path('/private/tmp') and serve.name.startswith('nh_html_qa014_')
    assert serve.is_dir() and not serve.is_symlink()
    target = serve/'manuscript.html'
else:
    serve = Path(tempfile.mkdtemp(prefix='nh_html_qa014_',dir='/private/tmp'))
    target = serve/'manuscript.html'
    shutil.copy2(source,target)
inventory=[]
for p in serve.rglob('*'):
    assert not p.is_symlink()
    assert p.resolve().is_relative_to(serve.resolve())
    if p.is_file(): inventory.append({'path':str(p.relative_to(serve)), 'bytes':p.stat().st_size, 'sha256':digest(p)})
assert len(inventory)==1 and digest(target)==pin
(qa/'serve_root_preflight.json').write_text(json.dumps({'root':str(serve),'symlink_check':'PASS: no symlinks',
    'inventory':inventory,'allowed_route':'/manuscript.html','directory_listing':False},indent=2)+'\n')
def now(): return datetime.now(timezone.utc).isoformat()
class Handler(BaseHTTPRequestHandler):
    def reply(self,body):
        route=urlsplit(self.path).path
        if route=='/favicon.ico':
            self.send_response(204);self.end_headers();return
        if route!='/manuscript.html':
            self.send_error(404,'Route not exposed');return
        self.send_response(200)
        self.send_header('Content-Type','text/html; charset=utf-8')
        self.send_header('Content-Length',str(target.stat().st_size))
        self.send_header('Cache-Control','no-store')
        self.end_headers()
        if body:
            with target.open('rb') as f: shutil.copyfileobj(f,self.wfile)
    def do_GET(self): self.reply(True)
    def do_HEAD(self): self.reply(False)
    def reject(self):
        self.send_response(405);self.send_header('Allow','GET, HEAD');self.end_headers()
    do_POST=do_PUT=do_DELETE=do_PATCH=do_OPTIONS=reject
    def log_message(self,fmt,*args):
        with (qa/'http_access.jsonl').open('a') as f:
            f.write(json.dumps({'at':now(),'client':self.client_address[0],'message':fmt%args})+'\n')
try:
    server=ThreadingHTTPServer(('127.0.0.1',0),Handler)
except PermissionError as exc:
    (qa/'server_bind_failure.json').write_text(json.dumps({'at':now(),'error':repr(exc),
        'root':str(serve),'address':'127.0.0.1','port':0,'listener_created':False},indent=2)+'\n')
    raise
server.daemon_threads=True
state={'command':'bundled Python html_visual_qa/serve_frozen.py','pid':os.getpid(),'root':str(serve),
       'address':'127.0.0.1','port':server.server_port,'url':f'http://127.0.0.1:{server.server_port}/manuscript.html',
       'started_at':now(),'source':str(source),'source_sha256':pin,'served_sha256':digest(target),
       'methods':['GET','HEAD'],'directory_listing':False}
(qa/'server_lifecycle.json').write_text(json.dumps(state,indent=2)+'\n')
def stop(signum,frame): raise KeyboardInterrupt
signal.signal(signal.SIGTERM,stop)
print(json.dumps(state),flush=True)
try:
    server.serve_forever(poll_interval=.2)
except KeyboardInterrupt:
    pass
finally:
    server.server_close()
    state.update({'stopped_at':now(),'served_final_sha256':digest(target),'source_final_sha256':digest(source)})
    assert state['served_final_sha256']==state['source_final_sha256']==pin
    (qa/'server_lifecycle.json').write_text(json.dumps(state,indent=2)+'\n')
    print('SERVER_STOPPED',flush=True)
