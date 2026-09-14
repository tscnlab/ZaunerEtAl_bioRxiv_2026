"""Prepare an exact versioned infrastructure candidate in temporary audit space."""
import hashlib
import json
from pathlib import Path

root = Path("/private/tmp/ba018-diagnostic-recovery.DfiQe9")
stage2 = Path("/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2")
central = Path("/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026")
digest = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
old = stage2 / "code/run_bounded_job_v3.py"
assert digest(old) == "f4cfa0953a9dabb8a4c76d3847107507657b8e1ec51a35edbbfbd6f67be3e1d9"
original = old.read_text()
failed = stage2 / "preflight/execution_jobs/DIAGNOSTICS-PRIMARY-ANY"
failed_pins = {n: digest(failed / n) for n in ("start.json", "finish.json", "execution.log")}
changes = []
changes.append((
    '"06_derive_primary_estimands_v2.R"}, "No consumed scientific driver may rerun."',
    '"06_derive_primary_estimands_v2.R", "07_run_primary_diagnostics.R"}, "No consumed scientific driver may rerun."'
))
guard = '''# One same-seed diagnostic recovery; no aliases or second diagnostic retry.
recovery_job = "DIAGNOSTICS-PRIMARY-ANY-RECOVERY-001"
recovery_driver = "07_run_primary_diagnostics_v2.R"
recovery_driver_sha = "ed06bbdc1257efbbd543dfd2cedd321d2796c2c1d0baad043e279511deeb5428"
if job_id == recovery_job:
    assert driver_path.name == recovery_driver and driver_args == ["PRIMARY-ANY"]
    assert hashlib.sha256(driver_path.read_bytes()).hexdigest() == recovery_driver_sha
elif job_id == "DIAGNOSTICS-PRIMARY-80":
    assert driver_path.name == recovery_driver and driver_args == ["PRIMARY-80"]
    assert hashlib.sha256(driver_path.read_bytes()).hexdigest() == recovery_driver_sha
else:
    assert not job_id.startswith("DIAGNOSTICS-PRIMARY-ANY"), "No diagnostic retry alias."
    assert driver_path.name != recovery_driver, "The primary diagnostic driver has only two registered jobs."
if job_id != recovery_job:
    assert (jobs_root / recovery_job / "finish.json").is_file(), "Complete the authorized recovery before later jobs."
'''
changes.append(("frozen_continuation_inputs = {\n", guard + "frozen_continuation_inputs = {\n"))
new_pins = {
    str(stage2 / "completion_v2/continued_final_package_003/final_manifest.csv"): "ef06de7af67271cfdd2b6ab4958aede173e5707d1a5d6c8c20f23f63db4877fe",
    str(central / "audit/decisions/brown_main_linkage_b_stage2_diagnostic_status_export_stop_001/independent_manifest.csv"): "2eb0131608191f045b22f1f6abd53df666c7b51d26705eba6a7b7bd0edd81ff6",
    str(stage2 / "code/diagnostic_interface.R"): "6026e55cdb9a1d09920ce796084d32b0d714a990cd894d0bbbbef18efb518f38",
}
addition = "".join(f'    {json.dumps(p)}: {json.dumps(h)},\n' for p, h in new_pins.items())
changes.append(("}\nfor frozen_path, expected_hash in frozen_continuation_inputs.items():", addition + "}\nfor frozen_path, expected_hash in frozen_continuation_inputs.items():"))
changes.append((
    'for required_job in ("DERIVE-PRIMARY-ESTIMANDS", "DERIVE-PRIMARY-ESTIMANDS-V2"):',
    'for required_job in ("DERIVE-PRIMARY-ESTIMANDS", "DERIVE-PRIMARY-ESTIMANDS-V2", "DIAGNOSTICS-PRIMARY-ANY"):'
))
changes.append((
    '"Both preserved failed jobs must remain in the accumulator."',
    '"All three preserved failed jobs must remain in the accumulator."'
))
history = '''    elif previous.name == "DIAGNOSTICS-PRIMARY-ANY":
        historical_pins = FAILED_PINS
        for name, expected_sha256 in historical_pins.items():
            assert hashlib.sha256((previous / name).read_bytes()).hexdigest() == expected_sha256
        assert record["job_id"] == previous.name
        assert record["driver_sha256"] == "20c8a54701b7cd1772ce78aa5b18588dfa9459d08a13dd879ac4716ba58eb5f3"
        assert record["supervisor_sha256"] == "f4cfa0953a9dabb8a4c76d3847107507657b8e1ec51a35edbbfbd6f67be3e1d9"
        assert record["exit_code"] == 1 and not record["timed_out"] and record["child_reaped"]
        assert record["elapsed_seconds"] == 1.0988522499974351
    elif previous.name == recovery_job:
        assert record["job_id"] == recovery_job
        assert record["driver_sha256"] == recovery_driver_sha
        assert record["command"][-1] == "PRIMARY-ANY"
        assert record["exit_code"] == 0 and not record["timed_out"] and record["child_reaped"], "The single recovery failed; no retry is allowed."
'''.replace("FAILED_PINS", repr(failed_pins))
anchor = '    else:\n        assert record["exit_code"] == 0 and not record["timed_out"] and record["child_reaped"], "A new failed execution requires a separate recovery decision."'
changes.append((anchor, history + anchor))
anchor = '    "scientific_calculations_in_supervisor": False,\n'
changes.append((anchor, anchor + '''    "historical_unsaved_diagnostic_draws_charged": 250,
    "maximum_attempted_diagnostic_draws": 1750,
    "maximum_logical_final_diagnostic_draws": 1500,
    "same_seed_recovery_allowance": "BA-018-DIAGNOSTIC-EXPORT-RECOVERY-001",
'''))
candidate = original
for before, after in changes:
    assert candidate.count(before) == 1, before
    candidate = candidate.replace(before, after, 1)
reconstructed = candidate
for before, after in reversed(changes):
    assert reconstructed.count(after) == 1, after
    reconstructed = reconstructed.replace(after, before, 1)
assert reconstructed == original
output = root / "run_bounded_job_v4.py"
assert not output.exists()
output.write_text(candidate)
(root / "reconstructed_run_bounded_job_v3.py").write_text(reconstructed)
(root / "exact_supervisor_changes.json").write_text(json.dumps([{"before": a, "after": b} for a, b in changes], indent=2) + "\n")
(root / "failed_diagnostic_job_pins.json").write_text(json.dumps(failed_pins, indent=2) + "\n")
compile(candidate, str(output), "exec")
print("SUPERVISOR_PREPARED", digest(output), output.stat().st_size, "changes", len(changes), "reverse=exact")
