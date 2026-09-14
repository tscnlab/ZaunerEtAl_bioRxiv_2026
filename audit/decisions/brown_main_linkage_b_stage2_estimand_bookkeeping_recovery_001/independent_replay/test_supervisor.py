"""Infrastructure-only tests. No R command or scientific function is executed."""

import ast
import contextlib
import csv
import hashlib
import io
import json
from pathlib import Path
import runpy
import shutil
import sys
from unittest.mock import patch

ROOT = Path("/private/tmp/ba018-estimand-driver-audit.0nN7uE")
STAGE2 = Path("/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2")
SUP = ROOT / "run_bounded_job_v2.py"
DRIVER = ROOT / "06_derive_primary_estimands_v2.R"
OLD = STAGE2 / "code/run_bounded_job.py"
digest = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
assert digest(OLD) == "8e24c1f43f9586f6f4d491ffda7fceed0875184fd86504de7e12671eb3b5ff3b"
ast.parse(SUP.read_text())
ast.parse(OLD.read_text())
original = OLD.read_text()
prospective = SUP.read_text()
prefix = prospective[prospective.index('recovery_job_id = '):prospective.index('used = 0.0\n')]
old_line = '    assert record["exit_code"] == 0 and not record["timed_out"], "A failed execution requires a separate recovery decision."\n'
new_block = prospective[prospective.index('    if previous.name == "DERIVE-PRIMARY-ESTIMANDS":'):prospective.index('    used += record["elapsed_seconds"]')]
assert prospective.replace(prefix, "", 1).replace(new_block, old_line, 1) == original
(ROOT / "reconstructed_original_supervisor.py").write_text(prospective.replace(prefix, "", 1).replace(new_block, old_line, 1))
assert digest(ROOT / "reconstructed_original_supervisor.py") == digest(OLD)

checks = []
calls = []


def check(name, value, detail=""):
    checks.append({"check": name, "pass": bool(value), "detail": detail})
    assert value, name


def fixture(name, supervisor=SUP):
    dst = ROOT / ("supervisor_" + name)
    (dst / "code").mkdir(parents=True)
    (dst / "preflight").mkdir()
    shutil.copytree(STAGE2 / "preflight/execution_jobs", dst / "preflight/execution_jobs")
    shutil.copy2(supervisor, dst / "code" / supervisor.name)
    shutil.copy2(DRIVER, dst / "code" / DRIVER.name)
    return dst, dst / "code" / supervisor.name


class MockChild:
    def __init__(self, command, stdout, stderr, start_new_session):
        assert command[0] == "/usr/local/bin/Rscript"
        assert Path(command[2]).is_relative_to(ROOT)
        assert start_new_session is True
        calls.append(command)
        stdout.write(b"SYNTHETIC SUPERVISOR TEST, NO R EXECUTION\n")
        self.pid = 999999

    def wait(self, timeout=None):
        return 0

    def poll(self):
        return 0


ENV = {
    "RENV_CONFIG_AUTOLOADER_ENABLED": "FALSE",
    "OMP_NUM_THREADS": "1", "OPENBLAS_NUM_THREADS": "1",
    "MKL_NUM_THREADS": "1", "VECLIB_MAXIMUM_THREADS": "1",
}


def invoke(dst, supervisor, job="DERIVE-PRIMARY-ESTIMANDS-V2"):
    error = None
    buf = io.StringIO()
    argv = [str(supervisor), job, "120", str(dst / "code" / DRIVER.name)]
    with patch.object(sys, "argv", argv), patch.dict("os.environ", ENV), \
         patch("subprocess.Popen", MockChild), patch("time.monotonic", side_effect=[100.0, 101.0]), \
         contextlib.redirect_stdout(buf):
        try:
            runpy.run_path(str(supervisor), run_name="__main__")
        except SystemExit as exc:
            if exc.code != 0:
                error = exc
        except Exception as exc:
            error = exc
    (ROOT / (dst.name + "_" + job + ".log")).write_text(buf.getvalue() + "\n" + repr(error) + "\n")
    return error


check("exact_supervisor_reverse", True)
dst, sup = fixture("old_rejects", OLD)
err = invoke(dst, sup)
check("old_supervisor_rejects_sealed_failed_job", isinstance(err, AssertionError))
check("old_rejection_has_no_job_write_or_R_call", not (dst / "preflight/execution_jobs/DERIVE-PRIMARY-ESTIMANDS-V2").exists() and len(calls) == 0)

dst, sup = fixture("positive")
err = invoke(dst, sup)
check("new_exact_recovery_passes", err is None)
finish = json.loads((dst / "preflight/execution_jobs/DERIVE-PRIMARY-ESTIMANDS-V2/finish.json").read_text())
check("failed_runtime_retained", abs(finish["budget_used_before_seconds"] - 68.001416874991264) < 1e-10)
check("ordinary_cap_and_new_time_preserved", finish["effective_wall_limit_seconds"] == 120 and finish["elapsed_seconds"] == 1.0)
check("successful_child_reaped_and_lock_removed", finish["child_reaped"] and not (dst / "preflight/computation.lock").exists())
check("duplicate_job_rejected", isinstance(invoke(dst, sup), AssertionError))
check("future_original_plan_job_after_recovery_passes", invoke(dst, sup, "NEXT-UNCONSUMED") is None)
next_finish = json.loads((dst / "preflight/execution_jobs/NEXT-UNCONSUMED/finish.json").read_text())
check("same_accumulator_continues", abs(next_finish["budget_used_before_seconds"] - 69.001416874991264) < 1e-10)

for name in ("start.json", "finish.json", "execution.log"):
    dst, sup = fixture("tampered_" + name.replace(".", "_"))
    path = dst / "preflight/execution_jobs/DERIVE-PRIMARY-ESTIMANDS" / name
    path.write_bytes(path.read_bytes() + b"\n")
    before = len(calls)
    check("tampered_historical_" + name + "_rejected", isinstance(invoke(dst, sup), AssertionError) and len(calls) == before)

dst, sup = fixture("wrong_driver")
path = dst / "code" / DRIVER.name
path.write_bytes(path.read_bytes() + b"\n")
check("nonexact_recovery_driver_rejected", isinstance(invoke(dst, sup), AssertionError))

dst, sup = fixture("additional_failure")
path = dst / "preflight/execution_jobs/PRIMARY-ANY/finish.json"
record = json.loads(path.read_text())
record["exit_code"] = 1
path.write_text(json.dumps(record))
check("any_other_failed_job_rejected", isinstance(invoke(dst, sup), AssertionError))

dst, sup = fixture("missing_failed_job")
path = dst / "preflight/execution_jobs/DERIVE-PRIMARY-ESTIMANDS/finish.json"
path.rename(path.with_name("NOT_finish.json"))
check("missing_failed_history_rejected", isinstance(invoke(dst, sup), AssertionError))

dst, sup = fixture("premature_future")
check("future_job_before_recovery_rejected", isinstance(invoke(dst, sup, "NEXT-UNCONSUMED"), AssertionError))

dst, sup = fixture("new_failure")
check("fixture_recovery_for_new_failure", invoke(dst, sup) is None)
path = dst / "preflight/execution_jobs/DERIVE-PRIMARY-ESTIMANDS-V2/finish.json"
record = json.loads(path.read_text())
record["exit_code"] = 1
path.write_text(json.dumps(record))
check("new_recovery_failure_still_blocks", isinstance(invoke(dst, sup, "NEXT-UNCONSUMED"), AssertionError))

with (ROOT / "supervisor_checks.csv").open("w") as out:
    w = csv.DictWriter(out, fieldnames=["check", "pass", "detail"])
    w.writeheader()
    w.writerows(checks)
(ROOT / "supervisor_scope.txt").write_text(
    f"Python {sys.version}\nInfrastructure-only process, job-record and elapsed-time tests.\n"
    "All subprocess creation mocked; zero R or research execution. No author file mutation.\n"
    f"Original supervisor {digest(OLD)}\nVersioned supervisor {digest(SUP)}\n"
    f"Checks {len(checks)}/{len(checks)}; mock children {len(calls)}\n")
print(f"BA018_SUPERVISOR_REVIEW=PASS checks={len(checks)}/{len(checks)} mocked_only=True supervisor={digest(SUP)} bytes={SUP.stat().st_size}")
