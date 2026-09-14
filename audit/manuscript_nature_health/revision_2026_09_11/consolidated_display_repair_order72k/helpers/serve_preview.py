"""Read-only loopback preview of explicitly staged candidate outputs only."""
import functools
import hashlib
import http.server
import json
import os
import shutil
import time
from pathlib import Path

OUT=Path(__file__).resolve().parents[1]
ROOT=OUT.parents[3]
SERVE=OUT/"preview_attempt1"
RECEIPT=OUT/"server_session.json"
sources={"selection":ROOT/"audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k/project/render_attempt1",
         "main":OUT/"project/render_html_attempt1"}

def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def stage():
    if SERVE.exists():raise RuntimeError("Preview root already exists")
    rows=[]
    for label,source in sources.items():
        for p in source.rglob("*"):
            if p.is_symlink():raise RuntimeError(f"Symlink in candidate output {p}")
            if not p.is_file():continue
            if p.suffix.lower() not in {".html",".svg",".csv",".md",".json"}:raise RuntimeError(f"Unexpected served resource {p}")
            dest=SERVE/label/p.relative_to(source)
            dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,dest)
            assert digest(dest)==digest(p)
            rows.append({"source":str(p),"served":str(dest),"sha256":digest(p),"bytes":p.stat().st_size})
    if any(p.is_symlink() for p in SERVE.rglob("*")):raise RuntimeError("Served symlink")
    (OUT/"server_preflight.json").write_text(json.dumps({"root":str(SERVE),"symlinks":0,"private_data_or_execution_files":0,"files":rows},indent=2)+"\n")

class Handler(http.server.SimpleHTTPRequestHandler):
    def list_directory(self,path):self.send_error(404,"Directory listing disabled")
    def do_GET(self):super().do_GET()
    def do_HEAD(self):super().do_HEAD()

def main():
    if RECEIPT.exists():raise RuntimeError("A server session was already recorded")
    stage()
    handler=functools.partial(Handler,directory=str(SERVE))
    server=http.server.HTTPServer(("127.0.0.1",0),handler)
    record={"pid":os.getpid(),"host":"127.0.0.1","port":server.server_port,"root":str(SERVE),"started":time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime()),"methods":["GET","HEAD"],"status":"running"}
    RECEIPT.write_text(json.dumps(record,indent=2)+"\n")
    print(json.dumps(record),flush=True)
    try:server.serve_forever()
    except KeyboardInterrupt:pass
    finally:
        server.server_close();record.update(status="closed",ended=time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime()));RECEIPT.write_text(json.dumps(record,indent=2)+"\n")

if __name__=="__main__":main()
