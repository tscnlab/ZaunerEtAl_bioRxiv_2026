"""Supervise one R process tree and record infrastructure-only wall time."""

import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

root = Path(__file__).resolve().parent.parent
job_id, requested_limit, driver, *driver_args = sys.argv[1:]
assert job_id and all(ch.isalnum() or ch in "-_" for ch in job_id)
limit = float(requested_limit)
assert 0 < limit <= (180 if job_id.startswith("TEMPORAL-") else 120)
driver_path = Path(driver).resolve(strict=True)
assert driver_path.is_relative_to(root / "code") and driver_path.suffix == ".R"
jobs_root = root / "preflight" / "execution_jobs"
jobs_root.mkdir(exist_ok=True)
job_root = jobs_root / job_id
assert not job_root.exists(), "A consumed job must not be replayed."
recovery_job_id = "DERIVE-PRIMARY-ESTIMANDS-V2"
recovery_driver_sha256 = "729ce699c57d9ab91cc16668c074742cc4929035102a079866390291964037ba"
assert (jobs_root / "DERIVE-PRIMARY-ESTIMANDS" / "finish.json").is_file(), "The preserved failed job must remain in the accumulator."
if job_id == recovery_job_id:
    assert driver_path.name == "06_derive_primary_estimands_v2.R"
    assert hashlib.sha256(driver_path.read_bytes()).hexdigest() == recovery_driver_sha256
else:
    recovery_finish = jobs_root / recovery_job_id / "finish.json"
    assert recovery_finish.exists(), "The authorized estimand recovery must pass first."
    recovery_record = json.loads(recovery_finish.read_text())
    assert recovery_record["job_id"] == recovery_job_id
    assert recovery_record["driver_sha256"] == recovery_driver_sha256
    assert recovery_record["exit_code"] == 0 and not recovery_record["timed_out"]
    assert recovery_record["child_reaped"], "The recovery child must be reaped."
used = 0.0
for previous in sorted(jobs_root.iterdir()):
    if not previous.is_dir():
        continue
    finish = previous / "finish.json"
    assert finish.exists(), "An unfinished job requires a stopped disposition."
    record = json.loads(finish.read_text())
    if previous.name == "DERIVE-PRIMARY-ESTIMANDS":
        historical_pins = {
            "start.json": "ed61889d4a3d264a19edd90245ca85cbcc49bbc4a5e13aa590629a3fa12d796a",
            "finish.json": "e89eac2d66de49112d1bccbfd50c5363760904a1178bbfa6d943cc7ac41c0975",
            "execution.log": "40cc1c6cc6d2e7acdacc39d9745a2a0105bf78837f93eb975e2348e3abd32f3c",
        }
        for name, expected_sha256 in historical_pins.items():
            assert hashlib.sha256((previous / name).read_bytes()).hexdigest() == expected_sha256
        assert record["job_id"] == previous.name
        assert record["driver_sha256"] == "dc88dfca95189435dcf456069d4d69857ecba5c5d2b35abba188c1fca7fc1ea0"
        assert record["supervisor_sha256"] == "8e24c1f43f9586f6f4d491ffda7fceed0875184fd86504de7e12671eb3b5ff3b"
        assert record["exit_code"] == 1 and not record["timed_out"] and record["child_reaped"]
        assert record["elapsed_seconds"] == 31.04514845801168
    else:
        assert record["exit_code"] == 0 and not record["timed_out"], "A new failed execution requires a separate recovery decision."
    used += record["elapsed_seconds"]
remaining = 1200.0 - used
assert remaining > 0, "The statistical compute budget is exhausted."
limit = min(limit, remaining)
lock_path = root / "preflight" / "computation.lock"
lock_fd = os.open(lock_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
os.write(lock_fd, str(os.getpid()).encode())
os.close(lock_fd)
job_root.mkdir()
command = ["/usr/local/bin/Rscript", "--vanilla", str(driver_path), *driver_args]
record = {
    "job_id": job_id,
    "command": command,
    "driver_sha256": hashlib.sha256(driver_path.read_bytes()).hexdigest(),
    "supervisor_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    "started_utc": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
    "budget_used_before_seconds": used,
    "effective_wall_limit_seconds": limit,
    "environment": {key: os.environ.get(key, "") for key in (
        "R_LIBS", "RENV_CONFIG_AUTOLOADER_ENABLED", "BROWN_ADHERENCE_PROJECT_ROOT",
        "BROWN_ADHERENCE_AUTHOR_ROOT", "OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS",
        "MKL_NUM_THREADS", "VECLIB_MAXIMUM_THREADS")},
    "scientific_calculations_in_supervisor": False,
}
assert record["environment"]["RENV_CONFIG_AUTOLOADER_ENABLED"] == "FALSE"
for key in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS", "VECLIB_MAXIMUM_THREADS"):
    assert record["environment"][key] == "1"
(job_root / "start.json").write_text(json.dumps(record, indent=2) + "\n")
print(f"Starting {job_id}; wall limit {limit:.1f}s; prior compute {used:.3f}s", flush=True)
started = time.monotonic()
timed_out = False
child = None
try:
    with (job_root / "execution.log").open("xb") as log:
        child = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            exit_code = child.wait(timeout=limit)
        except subprocess.TimeoutExpired:
            timed_out = True
            os.killpg(child.pid, signal.SIGTERM)
            try:
                child.wait(timeout=3)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid, signal.SIGKILL)
                child.wait()
            exit_code = 124
    record.update({
        "finished_utc": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
        "elapsed_seconds": time.monotonic() - started,
        "exit_code": exit_code,
        "timed_out": timed_out,
        "child_pid": child.pid,
        "process_group": child.pid,
        "child_reaped": child.poll() is not None,
    })
    (job_root / "finish.json").write_text(json.dumps(record, indent=2) + "\n")
    print((job_root / "execution.log").read_text(errors="replace"), flush=True)
    print(f"Finished {job_id}: exit {exit_code}, {record['elapsed_seconds']:.3f}s; cumulative {used + record['elapsed_seconds']:.3f}s", flush=True)
finally:
    if child is not None and child.poll() is None:
        os.killpg(child.pid, signal.SIGKILL)
        child.wait()
    lock_path.unlink()
sys.exit(exit_code)
