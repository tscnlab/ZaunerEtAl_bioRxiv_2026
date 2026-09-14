"""Mocked supervision, identity, routing and runtime tests. No R process starts."""
import ast
import contextlib
import csv
import io
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import tempfile
from unittest.mock import patch

ROOT = Path("/private/tmp/ba018-diagnostic-recovery.DfiQe9")
STAGE2 = Path("/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2")
SUP = ROOT / "run_bounded_job_v4.py"
DRIVER = ROOT / "07_run_primary_diagnostics_v2.R"
RECOVERY = "DIAGNOSTICS-PRIMARY-ANY-RECOVERY-001"
SUITE = Path(tempfile.mkdtemp(prefix="supervisor_suite_", dir=ROOT))
ENV = {"RENV_CONFIG_AUTOLOADER_ENABLED": "FALSE", "OMP_NUM_THREADS": "1", "OPENBLAS_NUM_THREADS": "1", "MKL_NUM_THREADS": "1", "VECLIB_MAXIMUM_THREADS": "1"}
checks, calls, signals = [], [], []

def check(name, value):
    checks.append({"check": name, "pass": bool(value)})
    assert value, name

def fixture(name, supervisor=SUP):
    dst = SUITE / name
    (dst / "code").mkdir(parents=True)
    (dst / "preflight").mkdir()
    shutil.copytree(STAGE2 / "preflight/execution_jobs", dst / "preflight/execution_jobs")
    shutil.copy2(supervisor, dst / "code" / supervisor.name)
    driver = dst / "code" / DRIVER.name
    shutil.copy2(DRIVER, driver)
    other = dst / "code/99_inert_fixture.R"
    other.write_text("# INERT. All subprocess operations mocked.\n")
    return dst, dst / "code" / supervisor.name, driver, other

class MockChild:
    code = 0
    timeout = False
    def __init__(self, command, stdout, stderr, start_new_session):
        assert command[:2] == ["/usr/local/bin/Rscript", "--vanilla"]
        assert Path(command[2]).is_relative_to(SUITE)
        assert start_new_session
        calls.append(command)
        stdout.write(b"MOCK ONLY: no R or scientific execution.\n")
        self.pid, self.waits = 999999, 0
    def wait(self, timeout=None):
        self.waits += 1
        if type(self).timeout and self.waits == 1:
            raise subprocess.TimeoutExpired("MOCK", timeout)
        return type(self).code
    def poll(self):
        return type(self).code

def invoke(parts, job=RECOVERY, args=None, limit="120", use_other=False):
    dst, sup, driver, other = parts
    selected = other if use_other else driver
    if args is None: args = ["PRIMARY-ANY"] if job == RECOVERY else []
    error, out = None, io.StringIO()
    with patch.object(sys, "argv", [str(sup), job, limit, str(selected), *args]), patch.dict("os.environ", ENV), patch("subprocess.Popen", MockChild), patch("time.monotonic", side_effect=[100.0, 101.0]), patch("os.killpg", side_effect=lambda p, s: signals.append((p, s))), contextlib.redirect_stdout(out):
        try:
            runpy.run_path(str(sup), run_name="__main__")
        except SystemExit as exc:
            if exc.code != 0: error = exc
        except Exception as exc:
            error = exc
    (ROOT / f"supervisor_{dst.name}_{job}.log").write_text(out.getvalue() + "\n" + repr(error) + "\n")
    return error

def record(parts, job=RECOVERY):
    return json.loads((parts[0] / "preflight/execution_jobs" / job / "finish.json").read_text())

def warm(name):
    parts = fixture(name)
    assert invoke(parts) is None
    return parts

ast.parse(SUP.read_text())
check("exact_seven_block_reverse", (ROOT / "reconstructed_run_bounded_job_v3.py").read_bytes() == (STAGE2 / "code/run_bounded_job_v3.py").read_bytes())
p = fixture("old_v3", STAGE2 / "code/run_bounded_job_v3.py")
check("old_v3_blocks_this_stop", isinstance(invoke(p), AssertionError) and not calls)
p = fixture("positive")
check("v4_recovery_runs_once", invoke(p) is None)
r = record(p)
check("all_eight_old_jobs_charged", abs(r["budget_used_before_seconds"] - 100.50703887498821) < 1e-10)
check("ordinary_120_limit_retained", r["effective_wall_limit_seconds"] == 120 and r["elapsed_seconds"] == 1)
check("draw_exception_explicit", r["historical_unsaved_diagnostic_draws_charged"] == 250 and r["maximum_attempted_diagnostic_draws"] == 1750 and r["maximum_logical_final_diagnostic_draws"] == 1500)
check("child_reaped_lock_removed", r["child_reaped"] and not (p[0] / "preflight/computation.lock").exists())
check("same_job_repeat_blocked", isinstance(invoke(p), AssertionError))
check("primary80_after_recovery", invoke(p, "DIAGNOSTICS-PRIMARY-80", ["PRIMARY-80"]) is None)
check("registered_sensitivity_still_allowed", invoke(p, "SENS-SUPPORT70", use_other=True) is None)
check("elapsed_budget_not_reset", abs(record(p, "SENS-SUPPORT70")["budget_used_before_seconds"] - 102.50703887498821) < 1e-10)

for job in ("DERIVE-PRIMARY-ESTIMANDS", "DERIVE-PRIMARY-ESTIMANDS-V2", "DIAGNOSTICS-PRIMARY-ANY"):
    for name in ("start.json", "finish.json", "execution.log"):
        p = fixture("tamper_" + job + "_" + name)
        path = p[0] / "preflight/execution_jobs" / job / name
        path.write_bytes(path.read_bytes() + b"\n")
        before = len(calls)
        check("tamper_" + job + "_" + name, isinstance(invoke(p), AssertionError) and len(calls) == before)

for job in ("PRIMARY-ANY-RETRY", "DERIVE-PRIMARY-ESTIMANDS-V3", "R2-PRIMARY", "SHAPLEY-PRIMARY", "RENDER-REPORT", "ARBITRARY-NEW-JOB", "DIAGNOSTICS-PRIMARY-ANY-RECOVERY-002"):
    p = fixture("forbidden_" + job)
    before = len(calls)
    check("forbidden_" + job, isinstance(invoke(p, job, use_other=True), AssertionError) and len(calls) == before)

p = fixture("before_recovery")
check("later_job_before_recovery_blocked", isinstance(invoke(p, "SENS-SUPPORT70", use_other=True), AssertionError))
check("wrong_recovery_argument_blocked", isinstance(invoke(p, args=["PRIMARY-80"]), AssertionError))
check("wrong_recovery_driver_blocked", isinstance(invoke(p, use_other=True), AssertionError))
p[2].write_bytes(p[2].read_bytes() + b"\n")
check("altered_recovery_driver_blocked", isinstance(invoke(p), AssertionError))
p = fixture("missing_history")
path = p[0] / "preflight/execution_jobs/DIAGNOSTICS-PRIMARY-ANY/finish.json"
path.rename(path.with_name("retained_not_finish.json"))
check("missing_failed_history_blocked", isinstance(invoke(p), AssertionError))
p = fixture("existing_lock")
(p[0] / "preflight/computation.lock").write_text("MOCK EXISTING JOB")
check("single_process_lock_enforced", isinstance(invoke(p), FileExistsError))
p = fixture("unexpected_failure")
path = p[0] / "preflight/execution_jobs/PRIMARY-ANY/finish.json"
r = json.loads(path.read_text()); r["exit_code"] = 1; path.write_text(json.dumps(r))
check("nonenumerated_failure_blocked", isinstance(invoke(p), AssertionError))
p = fixture("new_failure")
MockChild.code = 1
check("retry_failure_recorded", isinstance(invoke(p), SystemExit))
MockChild.code = 0
check("retry_failure_blocks_all_later_jobs", isinstance(invoke(p, "SENS-SUPPORT70", use_other=True), AssertionError))
p = fixture("timeout")
MockChild.timeout = True
check("timeout_stops", isinstance(invoke(p), SystemExit))
MockChild.timeout = False
r = record(p)
check("timeout_reaped_and_no_real_signal", r["timed_out"] and r["exit_code"] == 124 and r["child_reaped"] and signals[-1][0] == 999999)
check("timeout_blocks_later_jobs", isinstance(invoke(p, "SENS-SUPPORT70", use_other=True), AssertionError))
p = fixture("over_limit")
check("ordinary_above120_rejected", isinstance(invoke(p, limit="121"), AssertionError))
p = warm("temporal_limit")
check("registered_temporal180_allowed", invoke(p, "TEMPORAL-ANY-ENDPOINT-R3", limit="180", use_other=True) is None)
p = fixture("exhausted")
extra = p[0] / "preflight/execution_jobs/DIAGNOSTICS-EXHAUSTED"
extra.mkdir()
(extra / "finish.json").write_text(json.dumps({"elapsed_seconds": 1100, "exit_code": 0, "timed_out": False, "child_reaped": True}))
check("same1200_total_ceiling", isinstance(invoke(p), AssertionError))
p = fixture("reduced_remaining")
extra = p[0] / "preflight/execution_jobs/DIAGNOSTICS-USED"
extra.mkdir()
(extra / "finish.json").write_text(json.dumps({"elapsed_seconds": 1090, "exit_code": 0, "timed_out": False, "child_reaped": True}))
check("remaining_budget_still_allows_bounded_start", invoke(p) is None)
check("per_job_cap_reduced_by_total_remaining", abs(record(p)["effective_wall_limit_seconds"] - 9.4929611250117) < 1e-9)
with (ROOT / "supervisor_checks.csv").open("w") as out:
    w = csv.DictWriter(out, fieldnames=["check", "pass"]); w.writeheader(); w.writerows(checks)
(ROOT / "supervisor_scope.txt").write_text(f"Python {sys.version}\n{len(checks)} mocked-only supervision checks. No real R, child process, signal or author-file modification. Exact old job contents copied to isolated temporary fixtures.\n")
print(f"BA018_RECOVERY_SUPERVISOR=PASS checks={len(checks)}/{len(checks)} mocked_only=True")
