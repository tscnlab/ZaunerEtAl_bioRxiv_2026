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
# Author-approved qualified diagnostics/sensitivities only. Neither failed job becomes PASS.
assert not job_id.startswith(("PRIMARY-", "DERIVE-PRIMARY-ESTIMANDS")), "Completed primary fits and estimands are frozen."
assert driver_path.name not in {"00_preflight.R", "01_validate_and_prepare.R", "02_fit_primary.R", "02_fit_primary_gate_v2.R", "03_audit_derivative_gate_stop.R", "04_seal_prefit_stop.R", "05_saved_derivative_gate_v2.R", "06_derive_primary_estimands.R", "06_derive_primary_estimands_v2.R"}, "No consumed scientific driver may rerun."
allowed_fit_jobs = {
    "SENS-SUPPORT70",
    "SENS-SUPPORT90",
    "SENS-TINYGT5",
    "SENS-TINYGT30",
    "SENS-COMPLETE-TRIADS",
    "SENS-BOTH-DAYTYPES",
    "SENS-STRICT",
    "SENS-EXCLUDE-ZERO",
    "SENS-DISPERSION-D1",
    "CHEST-ANY",
    "CALENDAR-CHUNKS",
    "DIAG-BINOMIAL",
    "FRACTIONAL-EQUAL",
    "FRACTIONAL-MINUTE",
    "LOSO-RISE",
    "LOSO-THUAS",
    "LOSO-BAUA",
    "LOSO-MPI",
    "LOSO-TUM",
    "LOSO-FUSPCEU",
    "LOSO-IZTECH",
    "LOSO-UCR",
    "LOSO-KNUST",
    "INFLUENCE-1",
    "INFLUENCE-2",
    "INFLUENCE-3",
    "INFLUENCE-4",
    "INFLUENCE-5",
    "SENS-EXCLUDE-ZERO-NOZERO",
    "TEMPORAL-ANY-ENDPOINT-R3",
    "TEMPORAL-80-ENDPOINT-R3",
    "TEMPORAL-ANY-BB-R0",
    "TEMPORAL-80-BB-R0",
    "TEMPORAL-ANY-BB-R3",
    "TEMPORAL-80-BB-R3",
}
allowed_support_prefixes = ("DIAGNOSTICS-", "CONSTRUCT-CHEST-", "CONSTRUCT-CALENDAR-", "SCREEN-INFLUENCE-", "DERIVE-SENSITIVITY-", "VERIFY-SENSITIVITY-", "COMPARE-SENSITIVITY-")
assert job_id in allowed_fit_jobs or job_id.startswith(allowed_support_prefixes), "Job is outside this diagnostic/sensitivity continuation."
frozen_continuation_inputs = {
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/models/BA-LB-PRIMARY-ANY.rds": "494b4647e7394b8efcaaf7cd7ae2922ba0669ac609529328d0a5e67cab60c245",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/models/BA-LB-PRIMARY-80.rds": "72cc742f3d60941a5a4fc44361f09a671fea00a4183b85ab932d1d7292a02a74",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/estimands/manifest.csv": "baff7f3cb89565235193a2a74dc64afd82a58e3fea3d519c55fce08318d4863a",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/estimands/boundary_estimands.rds": "b171074e003d565219327482329df4189258a2e2cfaa4d6c2c644b6b0a857490",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/estimands/validation.csv": "bf182db7ccc2546972e1e7352ef40e82a913832c0a9432488e79ffd7c03f831f",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/estimands/B_to_B80_claim_gate.csv": "1dea9c6364e8cb87bf8d52ecb9b7ac8e4d12a739b248d4c96e71cc7df38f1dd6",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/completion_v2/continued_final_package_002/final_manifest.csv": "5753221dd6a001c1715e2ba8e3e34ec2a83976e6d4ed0f637fa2cf3ac22baa80",
    "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/decisions/brown_main_linkage_b_stage2_m1_coverage_gate_stop_001/independent_manifest.csv": "db5cc06168c99ec3f0997483357a2cca6c70f3a54fe5673d58510e98822f52b8",
}
for frozen_path, expected_hash in frozen_continuation_inputs.items():
    assert hashlib.sha256(Path(frozen_path).read_bytes()).hexdigest() == expected_hash, "A frozen scientific stop or primary output changed."
for required_job in ("DERIVE-PRIMARY-ESTIMANDS", "DERIVE-PRIMARY-ESTIMANDS-V2"):
    assert (jobs_root / required_job / "finish.json").is_file(), "Both preserved failed jobs must remain in the accumulator."
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
        assert record["elapsed_seconds"] == 31.045148458011681
    elif previous.name == "DERIVE-PRIMARY-ESTIMANDS-V2":
        historical_pins = {
            "start.json": "10c6750009e87bdb316835932b68121daa462c5813872ece6631d22812808577",
            "finish.json": "c21046b8e617853ef032a62ba8461c14c7a684e37771963027bafbe90bd19ad2",
            "execution.log": "cc48e937c460281eeec2887676cf2b0a5b5788aa7cfb95c4fe9024f8ca7675ac",
        }
        for name, expected_sha256 in historical_pins.items():
            assert hashlib.sha256((previous / name).read_bytes()).hexdigest() == expected_sha256
        assert record["job_id"] == previous.name
        assert record["driver_sha256"] == "729ce699c57d9ab91cc16668c074742cc4929035102a079866390291964037ba"
        assert record["supervisor_sha256"] == "1d108833c89ac2815b01075db8d43a1f527c4fabdd09968c4f89a77efe4f1698"
        assert record["exit_code"] == 1 and not record["timed_out"] and record["child_reaped"]
        assert record["elapsed_seconds"] == 31.406769749999512
    else:
        assert record["exit_code"] == 0 and not record["timed_out"] and record["child_reaped"], "A new failed execution requires a separate recovery decision."
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
