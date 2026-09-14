"""Restart-only GET/HEAD serving of the already staged immutable 12-file preview."""
import csv
import functools
import hashlib
import http.server
import json
import os
import time
from pathlib import Path

RECORD = Path(__file__).resolve().parent
OUT = RECORD.parent
SERVE = OUT / "preview_attempt1"
RECEIPT = RECORD / "server_session.json"

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

class Handler(http.server.SimpleHTTPRequestHandler):
    def list_directory(self, path):
        self.send_error(404, "Directory listing disabled")

def main():
    assert not RECEIPT.exists(), "No implicit server retry"
    assert not SERVE.is_symlink()
    rows = list(csv.DictReader((RECORD / "served_preflight.csv").open()))
    expected = {Path(row["served"]): row for row in rows}
    observed = set()
    for path in SERVE.rglob("*"):
        assert not path.is_symlink(), path
        if path.is_file():
            assert path.suffix.lower() in {".html", ".svg", ".csv", ".md", ".json"}, path
            observed.add(path)
    assert len(expected) == 12 and observed == set(expected)
    for path, row in expected.items():
        assert sha(path) == row["sha256"] and path.stat().st_size == int(row["bytes"])
    server = http.server.HTTPServer(("127.0.0.1", 58005), functools.partial(Handler, directory=str(SERVE)))
    receipt = {"pid":os.getpid(), "host":"127.0.0.1", "port":server.server_port, "root":str(SERVE), "started":time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime()), "status":"running", "immutable_files":12, "symlinks":0, "methods":["GET", "HEAD"], "content_generated_or_replaced":False}
    RECEIPT.write_text(json.dumps(receipt, indent=2)+"\n")
    print(json.dumps(receipt), flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        receipt.update(status="closed", ended=time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime()))
        RECEIPT.write_text(json.dumps(receipt, indent=2)+"\n")

if __name__ == "__main__":
    main()
