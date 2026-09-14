"""Bounded GET/HEAD-only loopback server for accepted candidate QA."""
from common import *
import http.server,signal
assert json.loads((E/'candidate_static_summary.json').read_text())['all_pass']
assert len(rows(E/'content_reconciliation_R.csv'))==75
for route in ['index.html','supplementary_information.html']:assert len(rows(E/f'targeted_{route}.csv'))==15 and all(r['pass']=='TRUE' for r in rows(E/f'targeted_{route}.csv'))
assert inv(BUILD)==parsed_inv(E/'candidate_inventory.csv')
state=dict(pid=os.getpid(),root=str(BUILD),host='127.0.0.1',started_utc=utc(),get_head_only=True,symlinks=0,candidate_manifest_sha256=sha(E/'candidate_inventory.csv'))
class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self,*args,**kwargs):super().__init__(*args,directory=str(BUILD),**kwargs)
    def list_directory(self,path):self.send_error(403,'Directory listings disabled');return None
    def send_head(self):
        target=Path(self.translate_path(self.path))
        if not target.resolve().is_relative_to(BUILD) or target.is_symlink():self.send_error(403,'Outside candidate root');return None
        return super().send_head()
    def log_message(self,format,*args):
        with safe(E/'http_requests.log').open('a') as f:f.write(self.log_date_time_string()+' '+format%args+'\n')
def stop(signum,frame):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,stop)
with http.server.ThreadingHTTPServer(('127.0.0.1',0),Handler) as server:
    state.update(port=server.server_port,status='listening');dump(E/'server_lifecycle.json',state);print(json.dumps(state),flush=True)
    try:server.serve_forever(poll_interval=.25)
    except KeyboardInterrupt:pass
    finally:server.server_close();state.update(status='stopped',stopped_utc=utc());dump(E/'server_lifecycle.json',state);print('Server closed',flush=True)
