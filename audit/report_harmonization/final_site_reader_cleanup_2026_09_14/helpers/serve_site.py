"""One immutable rendered root, GET/HEAD only, loopback only, no listings."""
from common import *
import http.server,signal,sys

mode=sys.argv[1];assert mode in ('candidate','live');root=site_for(mode);qa=E/(mode+'_qa')
helper_check();assert json.loads((E/(mode+'_checks.json')).read_text())['status']=='PASS'
assert not (qa/'server_lifecycle.json').exists();qa.mkdir(exist_ok=True)
before=inventory(root);assert {r['path']:r for r in before}==csvmap(E/'candidate_inventory.csv')
csvout(qa/'server_pre_inventory.csv',before)
sourcekeys=[PROFILE,CORPUS,'_quarto.yml','_quarto-website.yml','index.qmd','supplementary_information.qmd','notebooks/sensitivity_battery.qmd','renv.lock']
sourcepre=[dict(path=key,bytes=(ROOT/key).stat().st_size,sha256=sha(ROOT/key)) for key in sourcekeys]
csvout(qa/'source_configuration_pre.csv',sourcepre)
state=dict(pid=os.getpid(),root=str(root),host='127.0.0.1',started_utc=utc(),get_head_only=True,symlinks=0,mode=mode)
class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self,*args,**kwargs):super().__init__(*args,directory=str(root),**kwargs)
    def list_directory(self,path):self.send_error(403,'Directory listings disabled');return None
    def send_head(self):
        p=Path(self.translate_path(self.path))
        if not p.resolve().is_relative_to(root) or any(q.is_symlink() for q in [p,*p.parents]):self.send_error(403,'Outside rendered site');return None
        return super().send_head()
    def log_message(self,fmt,*args):
        with owned(qa/'http_requests.log').open('a') as f:f.write(self.log_date_time_string()+' '+fmt%args+'\n')
def stop(signum,frame):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,stop)
with http.server.ThreadingHTTPServer(('127.0.0.1',0),Handler) as server:
    state.update(port=server.server_port,status='listening');dump(qa/'server_lifecycle.json',state);print(json.dumps(state),flush=True)
    try:server.serve_forever(poll_interval=.25)
    except KeyboardInterrupt:pass
    finally:
        server.server_close();after=inventory(root);assert after==before
        sourcepost=[dict(path=key,bytes=(ROOT/key).stat().st_size,sha256=sha(ROOT/key)) for key in sourcekeys]
        assert sourcepost==sourcepre;csvout(qa/'source_configuration_post.csv',sourcepost)
        csvout(qa/'server_post_inventory.csv',after)
        state.update(status='stopped',stopped_utc=utc(),immutable=True);dump(qa/'server_lifecycle.json',state);print('Server stopped; all899 rendered files immutable',flush=True)
