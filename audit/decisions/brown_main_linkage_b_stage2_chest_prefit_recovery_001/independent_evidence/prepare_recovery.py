"""Mechanical source versioning and metadata registration. No scientific calculations."""
import ast
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STAGE = Path('/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2')
AUTHOR = Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
CENTRAL = AUTHOR/'audit/decisions/brown_main_linkage_b_stage2_chest_prefit_recovery_001'
OLD_CENTRAL = AUTHOR/'audit/decisions/brown_main_linkage_b_stage2_chest_support_recovery_001'
REG = STAGE/'preflight/chest_prefit_recovery_001'
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def read_csv(p):
    with Path(p).open(newline='') as f: return list(csv.DictReader(f))
def write_csv(p, rows):
    with Path(p).open('x', newline='') as f:
        w=csv.DictWriter(f, fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def write_new(p, text):
    with Path(p).open('x') as f: f.write(text)
def identity(p, target=None):
    return {'path':str(target or p),'bytes':Path(p).stat().st_size,'sha256':sha(p)}

old_driver=STAGE/'code/19_fit_chest_b.R'
assert sha(old_driver)=='7ad21ac552b0c116f1afb38d04fd41e1c1b498e51c369760ed7a8ecb057ecc15'
text=old_driver.read_text()
changes=[
    ('registry_root <- file.path(stage2_root, "preflight/chest_support_recovery_001")',
     'registry_root <- file.path(stage2_root, "preflight/chest_prefit_recovery_001")'),
    ('lb_assert_manifest(file.path(registry_root, "expected_production_payloads.csv"))',
     'lb_assert_manifest(file.path(\n  stage2_root,\n  "preflight/chest_support_recovery_001/expected_production_payloads.csv"\n))'),
    ('sha256(file.path(code_root, "19_fit_chest_b.R")) == job$driver_sha256',
     'sha256(file.path(code_root, "19_fit_chest_b_v2.R")) == job$driver_sha256'),
    ('identical(frame, input$frame)',
     'identical(frame, ba_boundary_prepare_frame(input$frame))'),
]
for before,after in changes:
    assert text.count(before)==1 and after not in text
    text=text.replace(before,after)
new_driver=ROOT/'19_fit_chest_b_v2.R'
write_new(new_driver,text)
reverse=text
for before,after in reversed(changes): reverse=reverse.replace(after,before)
assert reverse==old_driver.read_text()
write_new(ROOT/'driver_reconstructed.R',reverse)
write_new(ROOT/'driver_exact_changes.json',json.dumps(changes,indent=2)+'\n')

audit=read_csv(OLD_CENTRAL/'audit_compute_accounting.csv')
timer=Path('/private/tmp/ba018-completion-audit.ekpsA4/chest_prefit_audit_job_001/finish.json')
finish=json.loads(timer.read_text())
assert finish['exit_code']==0 and finish['child_reaped'] and not finish['timed_out']
assert list(audit[0]) == ['component','charged_seconds','basis']
audit.append({'component':'chest_prefit_complete_interface_001','charged_seconds':finish['elapsed_seconds'],'basis':str(timer)})
write_csv(ROOT/'audit_compute_accounting.csv',audit)
audit_seconds=sum(float(x['charged_seconds']) for x in audit)

sup=STAGE/'code/run_bounded_job_v7.py'
assert sha(sup)=='7d954c50a1b2a3fd2aef68ce635697e0957b5670a0241f89fe8fdeed525c6826'
original=sup.read_text(); text=original; edits=[]
def replace(before,after):
    global text
    assert text.count(before)==1 and before!=after
    text=text.replace(before,after);edits.append((before,after))
replace('"18_construct_chest_b.R"},', '"18_construct_chest_b.R", "19_fit_chest_b.R"},')
replace('    "CHEST-ANY",','    "CHEST-ANY",\n    "CHEST-ANY-PREFIT-RECOVERY-001",')
block=f'''# One exact prefit recovery; the failed job consumed no optimization slot.
chest_prefit_job = "CHEST-ANY-PREFIT-RECOVERY-001"
chest_prefit_driver = "19_fit_chest_b_v2.R"
chest_prefit_sha = "{sha(new_driver)}"
if job_id == chest_prefit_job:
    assert driver_path.name == chest_prefit_driver and not driver_args
    assert hashlib.sha256(driver_path.read_bytes()).hexdigest() == chest_prefit_sha
    registration = root / "preflight/chest_prefit_recovery_001/chest_fit_job_registry.csv"
    with registration.open(newline="") as f:
        rows = list(csv.DictReader(f))
    assert len(rows) == 1 and rows[0]["job_id"] == "CHEST-ANY"
    assert Path(rows[0]["driver_path"]).resolve() == driver_path
    assert rows[0]["driver_sha256"] == chest_prefit_sha
    assert rows[0]["model_id"] == "BA-LB-CHEST-ANY" and rows[0]["model_fit_count"] == "1"
    assert not Path(rows[0]["model_path"]).exists() and not Path(rows[0]["manifest_path"]).exists()
else:
    assert not job_id.startswith("CHEST-ANY"), "No second chest fit or recovery alias."
    assert driver_path.name != chest_prefit_driver, "The chest driver has one exact execution only."
    assert (jobs_root / chest_prefit_job / "finish.json").is_file(), "Require the exact chest prefit recovery before later jobs."
'''
replace('frozen_continuation_inputs = {',block+'frozen_continuation_inputs = {')
pins={
 STAGE/'completion_v2/continued_final_package_007/final_manifest.csv':'946038dbd06d694d27873f47bac8d742dd0cf27be55a2e2d8090ebd522b30865',
 old_driver:sha(old_driver),
 STAGE/'preflight/chest_support_recovery_001/chest_fit_job_registry.csv':sha(STAGE/'preflight/chest_support_recovery_001/chest_fit_job_registry.csv'),
 CENTRAL/'audit_compute_accounting.csv':sha(ROOT/'audit_compute_accounting.csv'),
}
for p,h in list(pins.items())[:-1]: assert sha(p)==h
replace('for frozen_path, expected_hash in frozen_continuation_inputs.items():',
        'frozen_continuation_inputs.update('+repr({str(p):h for p,h in pins.items()})+')\nfor frozen_path, expected_hash in frozen_continuation_inputs.items():')
replace('independent_audit_seconds = 35.4437246250119',f'independent_audit_seconds = {audit_seconds!r}')
hist=STAGE/'preflight/execution_jobs/CHEST-ANY'
hist_pins={name:sha(hist/name) for name in ('start.json','finish.json','execution.log')}
record=json.loads((hist/'finish.json').read_text())
assert record['exit_code']==1 and record['child_reaped'] and not record['timed_out']
history_block=f'''    elif previous.name == "CHEST-ANY":
        historical_pins = {hist_pins!r}
        for name, expected_sha256 in historical_pins.items():
            assert hashlib.sha256((previous / name).read_bytes()).hexdigest() == expected_sha256
        assert record["job_id"] == "CHEST-ANY" and record["driver_sha256"] == "{sha(old_driver)}"
        assert record["supervisor_sha256"] == "{sha(sup)}"
        assert record["exit_code"] == 1 and not record["timed_out"] and record["child_reaped"]
        assert record["elapsed_seconds"] == {record['elapsed_seconds']!r}
    elif previous.name == chest_prefit_job:
        assert record["job_id"] == chest_prefit_job and record["driver_sha256"] == chest_prefit_sha
        assert Path(record["command"][2]).name == chest_prefit_driver and len(record["command"]) == 3
        assert record["exit_code"] == 0 and not record["timed_out"] and record["child_reaped"], "A new prefit recovery failure needs a stopped disposition."
'''
replace('    elif previous.name == chest_recovery_job:',history_block+'    elif previous.name == chest_recovery_job:')
replace('    "construction_recovery_authority": "BA-018-CHEST-SUPPORT-RECOVERY-001",',
        '    "construction_recovery_authority": "BA-018-CHEST-SUPPORT-RECOVERY-001",\n    "prefit_recovery_authority": "BA-018-CHEST-PREFIT-RECOVERY-001",')
ast.parse(text)
write_new(ROOT/'run_bounded_job_v8.py',text)
reverse=text
for before,after in reversed(edits):
    assert reverse.count(after)==1;reverse=reverse.replace(after,before)
assert reverse==original
write_new(ROOT/'supervisor_v7_reconstructed.py',reverse)
write_new(ROOT/'supervisor_exact_changes.json',json.dumps(edits,indent=2)+'\n')

rows=read_csv(STAGE/'preflight/chest_support_recovery_001/chest_fit_job_registry.csv')
rows[0]['driver_path']=str(STAGE/'code/19_fit_chest_b_v2.R')
rows[0]['driver_sha256']=sha(new_driver)
write_csv(ROOT/'chest_fit_job_registry.csv',rows)
source=read_csv(STAGE/'preflight/chest_support_recovery_001/chest_fit_source_manifest.csv')
source.extend([identity(new_driver,STAGE/'code/19_fit_chest_b_v2.R'),
               identity(ROOT/'run_bounded_job_v8.py',STAGE/'code/run_bounded_job_v8.py'),
               identity(ROOT/'chest_fit_job_registry.csv',REG/'chest_fit_job_registry.csv'),
               identity(STAGE/'completion_v2/continued_final_package_007/final_manifest.csv')])
assert len(source)==27 and len({x['path'] for x in source})==27
write_csv(ROOT/'chest_fit_source_manifest.csv',source)
mapping=[]
for name,target in (
 ('19_fit_chest_b_v2.R',STAGE/'code/19_fit_chest_b_v2.R'),
 ('run_bounded_job_v8.py',STAGE/'code/run_bounded_job_v8.py'),
 ('chest_fit_job_registry.csv',REG/'chest_fit_job_registry.csv'),
 ('chest_fit_source_manifest.csv',REG/'chest_fit_source_manifest.csv')):
    p=ROOT/name;assert not target.exists()
    mapping.append({'source_path':str(CENTRAL/'independent_evidence'/name),'destination_path':str(target),'bytes':p.stat().st_size,'sha256':sha(p)})
write_csv(ROOT/'exact_owner_copy_map.csv',mapping)
print(json.dumps({'copies':mapping,'fixed_audit_seconds':audit_seconds,'source_rows':len(source)},indent=2))
