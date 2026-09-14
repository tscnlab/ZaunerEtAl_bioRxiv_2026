from pathlib import Path
import datetime, hashlib, http.server, json, os, signal

SCRATCH = Path('/private/tmp/site011-independent.r9PH4p')
ROOT = Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/report_harmonization/final_site_integration_2026_09_14/candidate_build')
assert json.loads((SCRATCH/'independent_summary.json').read_text())['candidate_files'] == 914
assert not ROOT.is_symlink() and not any(p.is_symlink() for p in ROOT.rglob('*'))
assert sum(p.is_file() for p in ROOT.rglob('*')) == 914
state = dict(pid=os.getpid(), root=str(ROOT), host='127.0.0.1', get_head_only=True,
             symlinks=0, start=datetime.datetime.now(datetime.timezone.utc).isoformat())
class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)
    def list_directory(self, path):
        self.send_error(403, 'Directory listings disabled')
        return None
    def send_head(self):
        target = Path(self.translate_path(self.path))
        if not target.resolve().is_relative_to(ROOT) or target.is_symlink():
            self.send_error(403, 'Outside candidate root')
            return None
        return super().send_head()
    def log_message(self, message, *args):
        with (SCRATCH/'http.log').open('a') as f:
            f.write(self.log_date_time_string()+' '+message % args+'\n')
def stop(signum, frame):
    raise KeyboardInterrupt
signal.signal(signal.SIGTERM, stop)
with http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler) as server:
    state.update(port=server.server_port, status='listening')
    (SCRATCH/'server.json').write_text(json.dumps(state, indent=2)+'\n')
    print(json.dumps(state), flush=True)
    try:
        server.serve_forever(poll_interval=.25)
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        state.update(status='stopped', stop=datetime.datetime.now(datetime.timezone.utc).isoformat())
        (SCRATCH/'server.json').write_text(json.dumps(state, indent=2)+'\n')
        print('Stopped', flush=True)
