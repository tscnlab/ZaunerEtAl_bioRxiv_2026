"""Infrastructure-only exact routing, lifecycle and accumulated-time correction."""
import ast
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path('/private/tmp/ba018-completion-audit.ekpsA4/chest_support_recovery.i5UqmA')
AUDIT = ROOT.parent
STAGE = Path('/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2')
CENTRAL = Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/decisions/brown_main_linkage_b_stage2_chest_support_recovery_001')
sha = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
old = STAGE / 'code/run_bounded_job_v6.py'
assert sha(old) == '675443a89be0b07821ebad7c309c665f4ec3f70f4e6dc2fcac8b9692fcb00669'
prior_account = CENTRAL.parent / 'brown_main_linkage_b_stage2_deletion_target_recovery_001/audit_compute_accounting.csv'
with prior_account.open(newline='') as f:
    charges = list(csv.DictReader(f))
assert sum(float(row['charged_seconds']) for row in charges) == 15.252081125009806
for label, name in [
    ('chest_complete_original_UTC_audit', 'chest_audit_job_001'),
    ('fourteen_deletion_fit_audit', 'deletion_fit_audit_job_001'),
    ('fourteen_deletion_reporting_audit', 'deletion_reporting_audit_job_001'),
    ('family_grouping_weighting_audit', 'family_audit_job_001'),
    ('complete_prospective_chest_guards', 'chest_guard_audit_job_001'),
]:
    path = AUDIT / name / 'finish.json'
    rec = json.loads(path.read_text())
    assert rec['exit_code'] == 0 and rec['child_reaped'] and not rec['timed_out']
    charges.append({'component': label, 'charged_seconds': repr(rec['elapsed_seconds']), 'basis': str(path)})
audit_seconds = sum(float(row['charged_seconds']) for row in charges)
assert not CENTRAL.exists()
CENTRAL.mkdir()
with (CENTRAL / 'audit_compute_accounting.csv').open('x', newline='') as f:
    w = csv.DictWriter(f, fieldnames=['component', 'charged_seconds', 'basis'])
    w.writeheader(); w.writerows(charges)
original = old.read_text()
text = original
changes = []
def replace(before, after):
    global text
    assert text.count(before) == 1, before
    text = text.replace(before, after)
    changes.append({'before': before, 'after': after})
replace('"14_fit_registered_deletion.R"},', '"14_fit_registered_deletion.R", "18_construct_chest_b.R"},')
candidate = ROOT / '18_construct_chest_b_v2.R'
guard = f'''# Exact eight-site chest support recovery, with unchanged original count payloads.
chest_recovery_job = "CONSTRUCT-CHEST-B-SUPPORT-RECOVERY-001"
chest_recovery_driver = "18_construct_chest_b_v2.R"
chest_recovery_sha = "{sha(candidate)}"
if job_id == chest_recovery_job:
    assert driver_path.name == chest_recovery_driver and not driver_args
    assert hashlib.sha256(driver_path.read_bytes()).hexdigest() == chest_recovery_sha
else:
    assert not job_id.startswith("CONSTRUCT-CHEST-B"), "No chest reconstruction alias."
    assert driver_path.name != chest_recovery_driver, "The corrected chest constructor has one registered job."
    assert (jobs_root / chest_recovery_job / "finish.json").is_file(), "Require corrected chest support before remaining jobs."
'''
replace('frozen_continuation_inputs = {', guard + 'frozen_continuation_inputs = {')
pins = [STAGE / 'completion_v2/continued_final_package_006/final_manifest.csv',
        STAGE / 'placement/chest_b_frames/manifest.csv', STAGE / 'code/18_construct_chest_b.R',
        CENTRAL / 'audit_compute_accounting.csv']
stopped = STAGE / 'preflight/execution_jobs/CONSTRUCT-CHEST-B'
pins.extend(stopped / name for name in ('start.json', 'finish.json', 'execution.log'))
block = ''.join('    ' + repr(str(path)) + ': ' + repr(sha(path)) + ',\n' for path in pins)
replace('}\nfor frozen_path, expected_hash in frozen_continuation_inputs.items():', block + '}\nfor frozen_path, expected_hash in frozen_continuation_inputs.items():')
replace('"DIAGNOSTICS-PRIMARY-ANY", "DERIVE-SENSITIVITY-SIMPLE-FRAMES"):', '"DIAGNOSTICS-PRIMARY-ANY", "DERIVE-SENSITIVITY-SIMPLE-FRAMES", "CONSTRUCT-CHEST-B"):')
replace('"All four preserved failed jobs must remain in the accumulator."', '"All five preserved failed jobs must remain in the accumulator."')
replace('independent_audit_seconds = 15.252081125009806', f'independent_audit_seconds = {audit_seconds!r}')
record = json.loads((stopped / 'finish.json').read_text())
assert record['exit_code'] == 1 and record['child_reaped'] and not record['timed_out']
history = f'''    elif previous.name == "CONSTRUCT-CHEST-B":
        historical_pins = {repr({name: sha(stopped / name) for name in ('start.json', 'finish.json', 'execution.log')})}
        for name, expected_sha256 in historical_pins.items():
            assert hashlib.sha256((previous / name).read_bytes()).hexdigest() == expected_sha256
        assert record["job_id"] == previous.name
        assert record["driver_sha256"] == "{record['driver_sha256']}"
        assert record["supervisor_sha256"] == "{record['supervisor_sha256']}"
        assert record["exit_code"] == 1 and not record["timed_out"] and record["child_reaped"]
        assert record["elapsed_seconds"] == {record['elapsed_seconds']!r}
    elif previous.name == chest_recovery_job:
        assert record["job_id"] == chest_recovery_job and record["driver_sha256"] == chest_recovery_sha
        assert Path(record["command"][2]).name == chest_recovery_driver and len(record["command"]) == 3
        assert record["exit_code"] == 0 and not record["timed_out"] and record["child_reaped"], "New chest recovery failure needs a stopped disposition."
'''
replace('    elif previous.name in deletion_drivers:', history + '    elif previous.name in deletion_drivers:')
replace('"construction_recovery_authority": "BA-018-DELETION-TARGET-RECOVERY-001",', '"construction_recovery_authority": "BA-018-CHEST-SUPPORT-RECOVERY-001",')
new = ROOT / 'run_bounded_job_v7.py'
assert not new.exists()
new.write_text(text)
ast.parse(text)
reverse = text
for change in reversed(changes):
    assert reverse.count(change['after']) == 1
    reverse = reverse.replace(change['after'], change['before'])
assert reverse == original
(ROOT / 'supervisor_v6_reconstructed.py').write_text(reverse)
(ROOT / 'supervisor_exact_changes.json').write_text(json.dumps(changes, indent=2) + '\n')
(ROOT / 'supervisor_pins.json').write_text(json.dumps({str(p): sha(p) for p in pins}, indent=2) + '\n')
job_seconds = sum(json.loads(p.read_text())['elapsed_seconds'] for p in (STAGE/'preflight/execution_jobs').glob('*/finish.json'))
print(json.dumps({'changes':len(changes), 'sha256':sha(new), 'bytes':new.stat().st_size,
    'audit_seconds':audit_seconds, 'job_seconds':job_seconds, 'next_starting_debit':audit_seconds+job_seconds,
    'reverse_exact':True}, indent=2))
