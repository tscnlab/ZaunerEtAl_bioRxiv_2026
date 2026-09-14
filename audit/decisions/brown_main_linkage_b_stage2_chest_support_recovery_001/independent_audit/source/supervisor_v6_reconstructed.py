"""Supervise one R process tree and record infrastructure-only wall time."""

import csv
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
assert driver_path.name not in {"00_preflight.R", "01_validate_and_prepare.R", "02_fit_primary.R", "02_fit_primary_gate_v2.R", "03_audit_derivative_gate_stop.R", "04_seal_prefit_stop.R", "05_saved_derivative_gate_v2.R", "06_derive_primary_estimands.R", "06_derive_primary_estimands_v2.R", "07_run_primary_diagnostics.R", "09_construct_simple_sensitivities.R", "13_construct_deletion_inputs.R", "14_fit_registered_deletion.R"}, "No consumed scientific driver may rerun."
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
# One same-seed diagnostic recovery; no aliases or second diagnostic retry.
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
# Exact metadata-reference recovery. Original construction and diagnostic jobs stay consumed.
simple_fixture_job = "VERIFY-SENSITIVITY-SIMPLE-TIME-RECOVERY-001"
simple_recovery_job = "DERIVE-SENSITIVITY-SIMPLE-FRAMES-RECOVERY-001"
simple_drivers = {
    simple_fixture_job: ("09_verify_simple_time_preservation.R", "199b275f1bb0849c3246ec103dd678dca5ab1f39569c36205191afc8d9434de8"),
    simple_recovery_job: ("09_construct_simple_sensitivities_v2.R", "c3707d1dd2d0ffab8f9fd568a56bfe5466f66e330883560b076819d63c4f8ef8"),
}
if job_id in simple_drivers:
    expected_name, expected_sha = simple_drivers[job_id]
    assert driver_path.name == expected_name and not driver_args
    assert hashlib.sha256(driver_path.read_bytes()).hexdigest() == expected_sha
else:
    assert not job_id.startswith(("DERIVE-SENSITIVITY-SIMPLE-FRAMES", "VERIFY-SENSITIVITY-SIMPLE-TIME-RECOVERY")), "No construction recovery alias."
    assert driver_path.name not in {value[0] for value in simple_drivers.values()}, "Recovery drivers have only their exact registered jobs."
if job_id != simple_fixture_job:
    assert (jobs_root / simple_fixture_job / "finish.json").is_file(), "Run the registered labeled-time fixture first."
if job_id not in simple_drivers:
    assert (jobs_root / simple_recovery_job / "finish.json").is_file(), "Complete construction recovery before later jobs."
# Typed deletion-target recovery. Preserve the completed but invalid construction.
deletion_fixture_job = "VERIFY-SENSITIVITY-DELETION-TARGET-RECOVERY-001"
deletion_recovery_job = "SCREEN-INFLUENCE-B-DELETION-INPUTS-RECOVERY-001"
deletion_drivers = {
    deletion_fixture_job: ("13_verify_deletion_target_transport.R", "4fe27d9976c250b563abf9b50543df85a09b551a324f08d60ec4881840257209"),
    deletion_recovery_job: ("13_construct_deletion_inputs_v2.R", "0667a6d42f4504639944eb12e2f8c720f1d1a8ce035df6af0c937461bb4ee36b"),
}
deletion_fit_jobs = {"LOSO-" + site for site in ("RISE", "THUAS", "BAUA", "MPI", "TUM", "FUSPCEU", "IZTECH", "UCR", "KNUST")} | {"INFLUENCE-" + str(i) for i in range(1, 6)}
if job_id in deletion_drivers:
    name, expected_sha = deletion_drivers[job_id]
    assert driver_path.name == name and not driver_args
    assert hashlib.sha256(driver_path.read_bytes()).hexdigest() == expected_sha
else:
    assert not job_id.startswith(("SCREEN-INFLUENCE-B-DELETION-INPUTS", "VERIFY-SENSITIVITY-DELETION-TARGET")), "No target-recovery alias."
    assert driver_path.name not in {value[0] for value in deletion_drivers.values()}, "Recovery drivers have exact jobs only."
if job_id != deletion_fixture_job:
    assert (jobs_root / deletion_fixture_job / "finish.json").is_file(), "Require typed-target fixture first."
if job_id not in deletion_drivers:
    assert (jobs_root / deletion_recovery_job / "finish.json").is_file(), "Require corrected construction before later jobs."
if job_id in deletion_fit_jobs:
    assert driver_path.name == "14_fit_registered_deletion_v2.R" and driver_args == [job_id]
    assert hashlib.sha256(driver_path.read_bytes()).hexdigest() == "fa2dee5a464cc3aea3909cfbd833019205d6cb925fd45b0fa75f74d4400e3e17"
    registration = root / "preflight/deletion_target_recovery_001/deletion_fit_job_registry.csv"
    with registration.open(newline="") as registration_file:
        registered = list(csv.DictReader(registration_file))
    assert len(registered) == 14 and {row["job_id"] for row in registered} == deletion_fit_jobs
    row = [row for row in registered if row["job_id"] == job_id]
    assert len(row) == 1
    assert Path(row[0]["driver_path"]).resolve() == driver_path
    assert row[0]["driver_sha256"] == "fa2dee5a464cc3aea3909cfbd833019205d6cb925fd45b0fa75f74d4400e3e17"
    assert Path(row[0]["input_path"]).resolve() == (root / "influence/deletion_inputs_recovery_001/model_inputs.rds").resolve()
else:
    assert driver_path.name != "14_fit_registered_deletion_v2.R", "No deletion fit driver alias."
frozen_continuation_inputs = {
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/models/BA-LB-PRIMARY-ANY.rds": "494b4647e7394b8efcaaf7cd7ae2922ba0669ac609529328d0a5e67cab60c245",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/models/BA-LB-PRIMARY-80.rds": "72cc742f3d60941a5a4fc44361f09a671fea00a4183b85ab932d1d7292a02a74",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/estimands/manifest.csv": "baff7f3cb89565235193a2a74dc64afd82a58e3fea3d519c55fce08318d4863a",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/estimands/boundary_estimands.rds": "b171074e003d565219327482329df4189258a2e2cfaa4d6c2c644b6b0a857490",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/estimands/validation.csv": "bf182db7ccc2546972e1e7352ef40e82a913832c0a9432488e79ffd7c03f831f",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/estimands/B_to_B80_claim_gate.csv": "1dea9c6364e8cb87bf8d52ecb9b7ac8e4d12a739b248d4c96e71cc7df38f1dd6",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/completion_v2/continued_final_package_002/final_manifest.csv": "5753221dd6a001c1715e2ba8e3e34ec2a83976e6d4ed0f637fa2cf3ac22baa80",
    "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/decisions/brown_main_linkage_b_stage2_m1_coverage_gate_stop_001/independent_manifest.csv": "db5cc06168c99ec3f0997483357a2cca6c70f3a54fe5673d58510e98822f52b8",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/completion_v2/continued_final_package_003/final_manifest.csv": "ef06de7af67271cfdd2b6ab4958aede173e5707d1a5d6c8c20f23f63db4877fe",
    "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/decisions/brown_main_linkage_b_stage2_diagnostic_status_export_stop_001/independent_manifest.csv": "2eb0131608191f045b22f1f6abd53df666c7b51d26705eba6a7b7bd0edd81ff6",
    "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/code/diagnostic_interface.R": "6026e55cdb9a1d09920ce796084d32b0d714a990cd894d0bbbbef18efb518f38",
    '/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/completion_v2/continued_final_package_004/final_manifest.csv': 'dadaeea48843c05704e129c5903ce84474452b85cf12bc76eb36d7b4f3a8dee3',
    '/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/decisions/brown_main_linkage_b_stage2_simple_frame_preservation_stop_001/independent_manifest.csv': 'ac2c1f75098c41f8a2a2a504b4eb627760a9a94a8e04a76d9bdf3ffc6ec2227b',
    '/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/diagnostics/primary_any_valid/manifest.csv': '295445a4a4a3a738d10af1e9a1a5353beb2c074ab82bf8a64f2a3a67b6c4e01e',
    '/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/diagnostics/support_80/manifest.csv': '7b6da371e8cd4103d89b7c610c641079afdedd38d27dcf508b3245b979b88eb3',
    '/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/code/08_simple_sensitivity_contract.R': '50fe086a4e43537dfb6bb52e438d25ad76c32ce0cb69f51c96ab268fd2a0e194',
    '/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/frames/model_frames.rds': '189e8acf90dd44c4f58a74cd7cc9166bd7ecc451c0da8c150c9197bffd5df035',
    '/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/decisions/brown_main_linkage_b_stage2_simple_frame_preservation_recovery_001/audit_compute_accounting.csv': '6f63ddfcf05a7eaa6fab0331b94210142071bff34ef154b21a9ccf7a32d5d0a2',
    '/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/completion_v2/continued_final_package_005/final_manifest.csv': '6ead246104c7f502b1673572a36d1875aeb3cca776fd86df7df675683dda602a',
    '/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/influence/deletion_inputs/manifest.csv': '8841d3bcb0fd9cb7df82418ce7f6e36a9849f0690387f4cefc8a277681fd97d5',
    '/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/code/13_construct_deletion_inputs.R': '8684d8bab22546bcc238e45e888c00f60615f722f5e98184c352047faac5d28c',
    '/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/code/14_fit_registered_deletion.R': '235664fe3f2968cd61ffe8cdfe90cf72f6a17a30232022ad8cdc1b00d1aa28c8',
    '/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/preflight/qualified_continuation_001/08_register_deletion_fits.R': '1b0f24fa2c235177a026ae37e32ec1de72e9eb12570e095461f5085cd5075658',
    '/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/decisions/brown_main_linkage_b_stage2_deletion_target_recovery_001/audit_compute_accounting.csv': '7abf0ecfc8388784dbaf8d1aca030dcdbda81f4afd4a5be76f81fdabf69611b7',
    '/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/preflight/execution_jobs/SCREEN-INFLUENCE-B-DELETION-INPUTS/start.json': 'f59b0f5e98e855dd855ef8bfb122bd1d4c5de39732a59efb18bb741ad6eb358a',
    '/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/preflight/execution_jobs/SCREEN-INFLUENCE-B-DELETION-INPUTS/finish.json': 'dbe0d528c87034a17ab4db2a9bb9338af499c162dfc43e52e5d2522fd319ef74',
    '/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/preflight/execution_jobs/SCREEN-INFLUENCE-B-DELETION-INPUTS/execution.log': '0c2d073618410aac47b490940bb8cb4f4d57ef11f08ba4d424701b6ec36ee0ed',
}
for frozen_path, expected_hash in frozen_continuation_inputs.items():
    assert hashlib.sha256(Path(frozen_path).read_bytes()).hexdigest() == expected_hash, "A frozen scientific stop or primary output changed."
for required_job in ("DERIVE-PRIMARY-ESTIMANDS", "DERIVE-PRIMARY-ESTIMANDS-V2", "DIAGNOSTICS-PRIMARY-ANY", "DERIVE-SENSITIVITY-SIMPLE-FRAMES"):
    assert (jobs_root / required_job / "finish.json").is_file(), "All four preserved failed jobs must remain in the accumulator."
# Charge the sealed prior read-only R audit once, then sum job elapsed times only.
independent_audit_seconds = 15.252081125009806
used = independent_audit_seconds
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
    elif previous.name == "DIAGNOSTICS-PRIMARY-ANY":
        historical_pins = {'start.json': 'eb6441b5c106b039406a766d65dd8dd6a8c70da6b2ba9c3278980713ca39c1e5', 'finish.json': '752634e1ac84f8b5bf43e4f90ebd77b19f2ccff010699ffb27108458c3774da8', 'execution.log': '2da792f74d500a6e00f08ef791eaa1869184ff7e34ad3aab3563faf550df1d48'}
        for name, expected_sha256 in historical_pins.items():
            assert hashlib.sha256((previous / name).read_bytes()).hexdigest() == expected_sha256
        assert record["job_id"] == previous.name
        assert record["driver_sha256"] == "20c8a54701b7cd1772ce78aa5b18588dfa9459d08a13dd879ac4716ba58eb5f3"
        assert record["supervisor_sha256"] == "f4cfa0953a9dabb8a4c76d3847107507657b8e1ec51a35edbbfbd6f67be3e1d9"
        assert record["exit_code"] == 1 and not record["timed_out"] and record["child_reaped"]
        assert record["elapsed_seconds"] == 1.0988522499974351
    elif previous.name == "DERIVE-SENSITIVITY-SIMPLE-FRAMES":
        historical_pins = {'start.json': '40dde0e229b407afec90fb0be79c3f3c82bf0bfe3e99e89c671caeb6ee44dc0f', 'finish.json': 'f4e7e76a3fe78a045d70ce8cecf558efb0910534be6354390907895575992c07', 'execution.log': '7e43e23bedc4e4aa56389fcea469e2d31b270562674a0449b82f5f5dfea412de'}
        for name, expected_sha256 in historical_pins.items():
            assert hashlib.sha256((previous / name).read_bytes()).hexdigest() == expected_sha256
        assert record["job_id"] == previous.name
        assert record["driver_sha256"] == "83544bf3c563c0cd86065e0d62eead009ad403d91f23a8f47d851d36f58a4e10"
        assert record["supervisor_sha256"] == "c6be41215a27a3ed76f75367336915bbba25537fafa2a4a962de9fa038f994ae"
        assert record["exit_code"] == 1 and not record["timed_out"] and record["child_reaped"]
        assert record["elapsed_seconds"] == 0.7398032499768306
    elif previous.name in deletion_drivers:
        expected_name, expected_sha = deletion_drivers[previous.name]
        assert record["job_id"] == previous.name and record["driver_sha256"] == expected_sha
        assert Path(record["command"][2]).name == expected_name and len(record["command"]) == 3
        assert record["exit_code"] == 0 and not record["timed_out"] and record["child_reaped"], "A new target recovery failure needs a preserved disposition."
    elif previous.name in simple_drivers:
        expected_name, expected_sha = simple_drivers[previous.name]
        assert record["job_id"] == previous.name and record["driver_sha256"] == expected_sha
        assert Path(record["command"][2]).name == expected_name and len(record["command"]) == 3
        assert record["exit_code"] == 0 and not record["timed_out"] and record["child_reaped"], "A new construction/fixture failure requires a sealed disposition."
    elif previous.name == recovery_job:
        assert record["job_id"] == recovery_job
        assert record["driver_sha256"] == recovery_driver_sha
        assert record["command"][-1] == "PRIMARY-ANY"
        assert record["exit_code"] == 0 and not record["timed_out"] and record["child_reaped"], "The single recovery failed; no retry is allowed."
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
    "independent_audit_seconds_charged_once": independent_audit_seconds,
    "construction_recovery_authority": "BA-018-DELETION-TARGET-RECOVERY-001",
    "historical_unsaved_diagnostic_draws_charged": 250,
    "maximum_attempted_diagnostic_draws": 1750,
    "maximum_logical_final_diagnostic_draws": 1500,
    "same_seed_recovery_allowance": "BA-018-DIAGNOSTIC-EXPORT-RECOVERY-001",
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
