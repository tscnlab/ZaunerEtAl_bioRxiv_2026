"""Temporary GET/HEAD-only loopback preview of the exact candidate public root."""
import datetime,http.server,signal,os
from common import *

assert json.loads((EVIDENCE/'static_summary.json').read_text())['pass_']
assert (EVIDENCE/'content_reconciliation_R.csv').is_file()
expected=rows(EVIDENCE/'candidate_inventory.csv')
assert inventory(BUILD)==[dict(path=r['path'],bytes=int(r['bytes']),sha256=r['sha256']) for r in expected]
state=dict(pid=os.getpid(),root=str(BUILD),host='127.0.0.1',started_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),get_head_only=True,symlinks=0,candidate_manifest_sha256=sha(EVIDENCE/'candidate_inventory.csv'))
class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self,*args,**kwargs):super().__init__(*args,directory=str(BUILD),**kwargs)
    def list_directory(self,path):self.send_error(403,'Directory listings disabled');return None
    def send_head(self):
        target=Path(self.translate_path(self.path))
        if not target.resolve().is_relative_to(BUILD) or target.is_symlink():
            self.send_error(403,'Outside candidate root');return None
        return super().send_head()
    def log_message(self,format,*args):
        with safe(EVIDENCE/'http_requests.log').open('a') as f:f.write(self.log_date_time_string()+' '+format%args+'\n')
def stop(signum,frame):raise KeyboardInterrupt
signal.signal(signal.SIGTERM,stop)
with http.server.ThreadingHTTPServer(('127.0.0.1',0),Handler) as server:
    state['port']=server.server_port;state['status']='listening'
    write_json(EVIDENCE/'server_lifecycle.json',state)
    print(json.dumps(state),flush=True)
    try:server.serve_forever(poll_interval=.25)
    except KeyboardInterrupt:pass
    finally:
        server.server_close()
        state.update(status='stopped',stopped_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
        write_json(EVIDENCE/'server_lifecycle.json',state)
        print('Server closed',flush=True)
