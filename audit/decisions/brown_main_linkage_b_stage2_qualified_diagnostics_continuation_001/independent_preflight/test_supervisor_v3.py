"""Mocked process supervision only. Never executes R or edits research files."""

import ast
import contextlib
import csv
import hashlib
import io
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
from unittest.mock import patch

ROOT = Path("/private/tmp/ba018-qualified-continuation.sCpljO")
STAGE2 = Path("/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2")
SUP = ROOT / "run_bounded_job_v3.py"
OLD = STAGE2 / "code/run_bounded_job_v2.py"
ENV = {"RENV_CONFIG_AUTOLOADER_ENABLED": "FALSE", "OMP_NUM_THREADS": "1", "OPENBLAS_NUM_THREADS": "1", "MKL_NUM_THREADS": "1", "VECLIB_MAXIMUM_THREADS": "1"}
digest = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
checks, calls, signals = [], [], []
ast.parse(SUP.read_text())
ast.parse(OLD.read_text())


def check(name, value):
    checks.append({"check": name, "pass": bool(value)})
    assert value, name


def fixture(name, supervisor=SUP):
    dst = ROOT / ("fixture_" + name)
    (dst / "code").mkdir(parents=True)
    (dst / "preflight").mkdir()
    shutil.copytree(STAGE2 / "preflight/execution_jobs", dst / "preflight/execution_jobs")
    shutil.copy2(supervisor, dst / "code" / supervisor.name)
    driver = dst / "code/07_mock_diagnostics.R"
    driver.write_text("# Inert fixture; process creation is fully mocked.\n")
    return dst, dst / "code" / supervisor.name, driver


class MockChild:
    code = 0
    timeout = False

    def __init__(self, command, stdout, stderr, start_new_session):
        assert command[:2] == ["/usr/local/bin/Rscript", "--vanilla"]
        assert Path(command[2]).is_relative_to(ROOT)
        assert start_new_session
        calls.append(command)
        stdout.write(b"MOCK ONLY. NO R OR SCIENTIFIC EXECUTION.\n")
        self.pid = 999999
        self.waits = 0

    def wait(self, timeout=None):
        self.waits += 1
        if type(self).timeout and self.waits == 1:
            raise subprocess.TimeoutExpired("MOCK", timeout)
        return type(self).code

    def poll(self):
        return type(self).code


def invoke(dst, sup, driver, job="DIAGNOSTICS-PRIMARY-ANY", limit="120"):
    result = None
    buf = io.StringIO()
    with patch.object(sys, "argv", [str(sup), job, limit, str(driver)]), \
         patch.dict("os.environ", ENV), patch("subprocess.Popen", MockChild), \
         patch("time.monotonic", side_effect=[100.0, 101.0]), \
         patch("os.killpg", side_effect=lambda pid, sig: signals.append((pid, sig))), \
         contextlib.redirect_stdout(buf):
        try:
            runpy.run_path(str(sup), run_name="__main__")
        except SystemExit as exc:
            if exc.code != 0:
                result = exc
        except Exception as exc:
            result = exc
    (ROOT / f"{dst.name}_{job}.log").write_text(buf.getvalue() + "\n" + repr(result) + "\n")
    return result


check("syntax_and_exact_v2_reverse", digest(ROOT / "reconstructed_run_bounded_job_v2.py") == digest(OLD))
dst, sup, driver = fixture("old_blocks", OLD)
check("unchanged_v2_still_blocks_scientific_stop", isinstance(invoke(dst, sup, driver), AssertionError) and not calls)
dst, sup, driver = fixture("qualified_positive")
check("qualified_v3_continues", invoke(dst, sup, driver) is None)
record = json.loads((dst / "preflight/execution_jobs/DIAGNOSTICS-PRIMARY-ANY/finish.json").read_text())
check("all_seven_job_runtime_including_both_failures", abs(record["budget_used_before_seconds"] - 99.408186624990776) < 1e-10)
check("ordinary_cap_and_new_runtime", record["effective_wall_limit_seconds"] == 120 and record["elapsed_seconds"] == 1)
check("reaped_and_lock_removed", record["child_reaped"] and not (dst / "preflight/computation.lock").exists())
check("consumed_job_blocks", isinstance(invoke(dst, sup, driver), AssertionError))
check("allowed_registered_sensitivity_slot", invoke(dst, sup, driver, "SENS-SUPPORT70") is None)
next_record = json.loads((dst / "preflight/execution_jobs/SENS-SUPPORT70/finish.json").read_text())
check("accumulator_continues_not_reset", abs(next_record["budget_used_before_seconds"] - 100.408186624990776) < 1e-10)

for job in ("DERIVE-PRIMARY-ESTIMANDS", "DERIVE-PRIMARY-ESTIMANDS-V2"):
    for name in ("start.json", "finish.json", "execution.log"):
        dst, sup, driver = fixture("tamper_" + job + "_" + name.replace(".", "_"))
        path = dst / "preflight/execution_jobs" / job / name
        path.write_bytes(path.read_bytes() + b"\n")
        before = len(calls)
        check("tampered_" + job + "_" + name, isinstance(invoke(dst, sup, driver), AssertionError) and len(calls) == before)

for job in ("PRIMARY-ANY-RETRY", "DERIVE-PRIMARY-ESTIMANDS-V3", "R2-PRIMARY", "SHAPLEY-PRIMARY", "RENDER-REPORT", "ARBITRARY-NEW-JOB"):
    dst, sup, driver = fixture("forbidden_" + job)
    before = len(calls)
    check("forbidden_" + job, isinstance(invoke(dst, sup, driver, job), AssertionError) and len(calls) == before)

dst, sup, driver = fixture("old_driver")
forbidden = driver.with_name("02_fit_primary_gate_v2.R")
driver.rename(forbidden)
check("primary_driver_under_new_job_name_blocks", isinstance(invoke(dst, sup, forbidden), AssertionError))

dst, sup, driver = fixture("other_prior_failure")
path = dst / "preflight/execution_jobs/PRIMARY-ANY/finish.json"
record = json.loads(path.read_text())
record["exit_code"] = 1
path.write_text(json.dumps(record))
check("nonenumerated_failure_blocks", isinstance(invoke(dst, sup, driver), AssertionError))

dst, sup, driver = fixture("missing_old_stop")
path = dst / "preflight/execution_jobs/DERIVE-PRIMARY-ESTIMANDS-V2/finish.json"
path.rename(path.with_name("preserved_not_finish.json"))
check("missing_required_history_blocks", isinstance(invoke(dst, sup, driver), AssertionError))

dst, sup, driver = fixture("new_failure")
MockChild.code = 1
check("new_failure_records_nonzero", isinstance(invoke(dst, sup, driver), SystemExit))
MockChild.code = 0
before = len(calls)
check("new_failure_blocks_next_job", isinstance(invoke(dst, sup, driver, "SENS-SUPPORT70"), AssertionError) and len(calls) == before)

dst, sup, driver = fixture("timeout")
MockChild.timeout = True
check("timeout_stops", isinstance(invoke(dst, sup, driver), SystemExit))
MockChild.timeout = False
record = json.loads((dst / "preflight/execution_jobs/DIAGNOSTICS-PRIMARY-ANY/finish.json").read_text())
check("timeout_recorded_reaped_and_no_real_signal", record["exit_code"] == 124 and record["timed_out"] and record["child_reaped"] and signals[-1][0] == 999999)
check("timeout_blocks_next_job", isinstance(invoke(dst, sup, driver, "SENS-SUPPORT70"), AssertionError))

dst, sup, driver = fixture("over_limit")
check("ordinary_limit_above_120_rejected", isinstance(invoke(dst, sup, driver, limit="121"), AssertionError))
check("temporal_at_180_allowed", invoke(dst, sup, driver, "TEMPORAL-ANY-ENDPOINT-R3", "180") is None)

dst, sup, driver = fixture("exhausted")
extra = dst / "preflight/execution_jobs/DIAGNOSTICS-EXHAUSTED"
extra.mkdir()
(extra / "finish.json").write_text(json.dumps({"elapsed_seconds": 1101, "exit_code": 0, "timed_out": False, "child_reaped": True}))
check("original_1200_ceiling_blocks", isinstance(invoke(dst, sup, driver), AssertionError))

dst, sup, driver = fixture("critical_pin")
real_read_bytes = Path.read_bytes
target = STAGE2 / "estimands/validation.csv"
def corrupt_read(path):
    contents = real_read_bytes(path)
    return contents + b"\n" if path == target else contents
with patch.object(Path, "read_bytes", corrupt_read):
    before = len(calls)
    check("critical_gate_tamper_blocks_without_author_edit", isinstance(invoke(dst, sup, driver), AssertionError) and len(calls) == before)

with (ROOT / "supervisor_checks.csv").open("w") as out:
    writer = csv.DictWriter(out, fieldnames=["check", "pass"])
    writer.writeheader()
    writer.writerows(checks)
(ROOT / "supervisor_scope.txt").write_text(
    f"Python {sys.version}\nInfrastructure-only mocked process, file-pin and runtime tests.\n"
    "Zero R execution, process signals or author-file changes. All subprocess/signal calls mocked.\n"
    f"V2 {digest(OLD)}\nV3 {digest(SUP)}\nChecks {len(checks)}/{len(checks)}.\n")
print(f"BA018_QUALIFIED_SUPERVISOR=PASS checks={len(checks)}/{len(checks)} mocked_only=True supervisor={digest(SUP)} bytes={SUP.stat().st_size}")
