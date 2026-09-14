"""Symlink-checked GET/HEAD-only loopback static output preview."""
import argparse,hashlib,json,os,signal,time
from pathlib import Path
from http.server import HTTPServer,SimpleHTTPRequestHandler
from urllib.parse import unquote,urlsplit
C=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser();ap.add_argument('mode',choices=('s3_preview','html_round1','html_round2'));a=ap.parse_args()
ROOT=C/'project'/a.mode;E=C/'evidence'/('browser_'+a.mode);E.mkdir(exist_ok=True)
assert not (E/'runtime.json').exists(),'Only one started server per preview'
def inventory():
    out=[]
    for p in sorted(ROOT.rglob('*')):
        if p.is_symlink():raise RuntimeError('No preview symlinks')
        if p.is_file():out.append(dict(path=str(p.relative_to(ROOT)),sha256=hashlib.sha256(p.read_bytes()).hexdigest(),bytes=p.stat().st_size))
    return out
before=inventory()
if (E/'before.json').exists():assert json.loads((E/'before.json').read_text())==before
else:(E/'before.json').write_text(json.dumps(before,indent=2))
class Handler(SimpleHTTPRequestHandler):
    def __init__(self,*a,**kw):super().__init__(*a,directory=str(ROOT),**kw)
    def log_message(self,fmt,*v):
        with (E/'requests.log').open('a') as f:f.write('%s %s\n'%(self.log_date_time_string(),fmt%v))
    def allowed(self):
        rel=unquote(urlsplit(self.path).path).lstrip('/');p=(ROOT/rel).resolve()
        return bool(rel) and p.is_relative_to(ROOT.resolve()) and p.is_file() and not p.is_symlink() and p.suffix.lower() in {'.html','.css','.js','.png','.jpg','.jpeg','.svg','.woff','.woff2','.ttf','.docx'}
    def do_GET(self):
        if not self.allowed():self.send_error(404);return
        super().do_GET()
    def do_HEAD(self):
        if not self.allowed():self.send_error(404);return
        super().do_HEAD()
    def list_directory(self,path):self.send_error(403);return None
s=HTTPServer(('127.0.0.1',0),Handler)
r=dict(pid=os.getpid(),port=s.server_port,host='127.0.0.1',root=str(ROOT),methods=['GET','HEAD'],started=time.time())
(E/'runtime.json').write_text(json.dumps(r,indent=2));print(json.dumps(r),flush=True)
def stop(sig,frame):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,stop)
try:s.serve_forever(poll_interval=.2)
except KeyboardInterrupt:pass
finally:
    s.server_close();after=inventory()
    (E/'after.json').write_text(json.dumps(after,indent=2))
    (E/'teardown.json').write_text(json.dumps(dict(closed=True,pid=os.getpid(),content_unchanged=before==after,ended=time.time()),indent=2))
    assert before==after
