"""Bounded GET/HEAD-only loopback server for one rendered candidate directory."""
import argparse, hashlib, json, os, signal, sys, time
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import unquote, urlsplit
P=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--round',type=int,choices=(1,2),default=1);args=parser.parse_args()
ROOT=P/f'project/manuscript/R0_NatHealth/render_html_round{args.round}'
E=P/f'evidence/html_browser_round{args.round}';E.mkdir(exist_ok=True)
if (E/'runtime.json').exists():raise RuntimeError('A server attempt already bound this review session')
def inventory():
    files=[]
    for f in ROOT.rglob('*'):
        if f.is_symlink(): raise RuntimeError('Symlink in published candidate directory')
        if f.is_file(): files.append(dict(path=str(f.relative_to(ROOT)),bytes=f.stat().st_size,sha256=hashlib.sha256(f.read_bytes()).hexdigest()))
    return sorted(files,key=lambda x:x['path'])
before=inventory()
if (E/'before.json').exists():
    if json.loads((E/'before.json').read_text())!=before:raise RuntimeError('Candidate changed after the recorded permission failure')
else:(E/'before.json').write_text(json.dumps(before,indent=2))
class Handler(SimpleHTTPRequestHandler):
    def __init__(self,*a,**kw):super().__init__(*a,directory=str(ROOT),**kw)
    def log_message(self,fmt,*values):
        with (E/'requests.log').open('a') as out:out.write('%s %s\n'%(self.log_date_time_string(),fmt%values))
    def allowed(self):
        rel=unquote(urlsplit(self.path).path).lstrip('/')
        target=(ROOT/rel).resolve()
        return bool(rel) and target.is_relative_to(ROOT.resolve()) and target.is_file() and not target.is_symlink() and target.suffix.lower() in {'.html','.css','.js','.png','.jpg','.jpeg','.svg','.woff','.woff2','.ttf','.map','.docx'}
    def do_GET(self):
        if not self.allowed():self.send_error(404);return
        super().do_GET()
    def do_HEAD(self):
        if not self.allowed():self.send_error(404);return
        super().do_HEAD()
    def list_directory(self,path):self.send_error(403);return None
server=HTTPServer(('127.0.0.1',0),Handler)
runtime=dict(pid=os.getpid(),host='127.0.0.1',port=server.server_port,root=str(ROOT),started=time.time(),methods=['GET','HEAD'])
(E/'runtime.json').write_text(json.dumps(runtime,indent=2));print(json.dumps(runtime),flush=True)
def stop(sig,frame):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,stop)
try:server.serve_forever(poll_interval=.2)
except KeyboardInterrupt:pass
finally:
    server.server_close();after=inventory();(E/'after.json').write_text(json.dumps(after,indent=2))
    (E/'teardown.json').write_text(json.dumps(dict(pid=os.getpid(),closed=True,ended=time.time(),content_unchanged=before==after),indent=2))
    if before!=after:sys.exit('Published files changed during visual review')
