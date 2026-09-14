"""Read-only six-route localhost server and complete immutable QA lifecycle."""
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import csv
import hashlib
import json
import os
import signal
import sys
from datetime import datetime, timezone
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parent
candidate = ROOT / sys.argv[1]
session = candidate / sys.argv[2]
if session.exists():
    raise RuntimeError("Retain previous sessions; use a fresh QA directory")
session.mkdir()
pages_root = candidate / "pages"
if not pages_root.is_dir() or pages_root.is_symlink():
    raise RuntimeError("Unexpected page root")

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

with (candidate / "maps/six_page_manifest.csv").open() as file:
    entries = list(csv.DictReader(file))
if len(entries) != 6:
    raise RuntimeError("Only the six approved page roles may be served")
inventory = []
for path in pages_root.rglob("*"):
    if path.is_symlink():
        raise RuntimeError("No symlink is allowed in this narrow QA root")
    if path.is_file():
        inventory.append(path)
expected = [pages_root / entry["page"] for entry in entries]
if set(inventory) != set(expected):
    raise RuntimeError("Unexpected served-root member")
routes = {}
for entry in entries:
    path = pages_root / entry["page"]
    if digest(path) != entry["page_sha256"]:
        raise RuntimeError("Candidate hash mismatch")
    routes["/" + entry["page"]] = (path, path.read_bytes(), digest(path))
protected = {}
with (candidate / "evidence/protected_inputs_prebuild.csv").open() as file:
    for row in csv.DictReader(file):
        protected[row["path"]] = row["sha256"]
for path in candidate.rglob("*"):
    if path.is_file() and session not in path.parents:
        protected[str(path)] = digest(path)
for path, expected_hash in protected.items():
    if digest(Path(path)) != expected_hash:
        raise RuntimeError("Preflight protected-input mismatch")

def stamp():
    return datetime.now(timezone.utc).isoformat()

requests = []
class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        requests.append({"time": stamp(), "message": fmt % args})
    def do_GET(self):
        self.deliver(False)
    def do_HEAD(self):
        self.deliver(True)
    def deliver(self, head):
        url = urlsplit(self.path)
        item = routes.get(url.path)
        if item is None or url.query:
            self.send_error(404, "Only the six exact table-page routes are served")
            return
        path, data, expected_hash = item
        if digest(path) != expected_hash:
            self.send_error(409, "Immutable source changed; stop review")
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        if not head:
            self.wfile.write(data)

server = HTTPServer(("127.0.0.1", 0), Handler)
port = server.server_address[1]
preflight = {"pid": os.getpid(), "started_at": stamp(), "bind": "127.0.0.1", "port": port,
             "root": str(pages_root), "symlink_count": 0, "routes": list(routes),
             "protected": protected, "no_upload_or_directory_listing": True}
(session / "preflight.json").write_text(json.dumps(preflight, indent=2))
print(json.dumps({"pid": os.getpid(), "port": port, "session": str(session), "root": str(pages_root)}), flush=True)
def stop(signum, frame):
    raise KeyboardInterrupt
signal.signal(signal.SIGTERM, stop)
try:
    server.serve_forever(poll_interval=0.2)
except KeyboardInterrupt:
    pass
finally:
    server.server_close()
    after = [{"path": path, "expected": expected_hash, "actual": digest(Path(path)),
              "exact": digest(Path(path)) == expected_hash} for path, expected_hash in protected.items()]
    (session / "postflight.json").write_text(json.dumps({"pid": os.getpid(), "port": port,
        "stopped_at": stamp(), "all_exact": all(row["exact"] for row in after), "members": after,
        "requests": requests}, indent=2))
    print("Server stopped; all protected inputs exact:", all(row["exact"] for row in after), flush=True)
