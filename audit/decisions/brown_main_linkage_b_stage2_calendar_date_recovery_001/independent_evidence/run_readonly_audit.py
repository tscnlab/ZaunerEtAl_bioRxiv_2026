"""Time-bound a read-only temporary R audit and record actual wall time."""
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

script = Path(sys.argv[1]).resolve(strict=True)
destination = Path(sys.argv[2])
extra_args = sys.argv[3:]
allowed = ("/private/tmp/ba018-completion-audit.ekpsA4/",
           "/private/tmp/ba018-deletion-target-recovery.dOzpVc/")
assert str(script).startswith(allowed) and script.suffix == ".R"
assert str(destination).startswith(allowed) and not destination.exists()
destination.mkdir()
command = ["/usr/local/bin/Rscript", "--vanilla", str(script), *extra_args]
record = {"command": command, "script_sha256": hashlib.sha256(script.read_bytes()).hexdigest(),
          "started_utc": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
          "limit_seconds": 120, "scope": "read-only audit; no fit or draw"}
(destination / "start.json").write_text(json.dumps(record, indent=2) + "\n")
start = time.monotonic()
child = None
try:
    with (destination / "execution.log").open("xb") as log:
        child = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            status = child.wait(timeout=120)
            timed_out = False
        except subprocess.TimeoutExpired:
            os.killpg(child.pid, signal.SIGTERM)
            try:
                child.wait(timeout=3)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid, signal.SIGKILL)
                child.wait()
            status, timed_out = 124, True
    record.update(elapsed_seconds=time.monotonic()-start, exit_code=status,
                  timed_out=timed_out, child_reaped=child.poll() is not None,
                  finished_utc=time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()))
    (destination / "finish.json").write_text(json.dumps(record, indent=2) + "\n")
    print((destination / "execution.log").read_text())
    print(json.dumps(record, indent=2))
finally:
    if child is not None and child.poll() is None:
        os.killpg(child.pid, signal.SIGKILL)
        child.wait()
sys.exit(status)
