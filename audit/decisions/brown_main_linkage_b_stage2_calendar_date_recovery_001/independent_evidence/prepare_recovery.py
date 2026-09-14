"""Exact source versioning, archival copies and metadata pins. No scientific calculation."""
import ast,csv,hashlib,json,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parent
TEMP=ROOT.parent
AUTHOR=Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
STAGE=Path('/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2')
CENTRAL=AUTHOR/'audit/decisions/brown_main_linkage_b_stage2_calendar_date_recovery_001'
OLD=AUTHOR/'audit/decisions/brown_main_linkage_b_stage2_chest_prefit_recovery_001'
PACKAGE=STAGE/'completion_v2/continued_final_package_008'
REG=STAGE/'preflight/calendar_date_recovery_001'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def read_csv(p):
    with Path(p).open(newline='') as f:return list(csv.DictReader(f))
def write_csv(p,rows):
    with Path(p).open('x',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def write(p,text):
    with Path(p).open('x') as f:f.write(text)
def identity(p,target=None):return {'path':str(target or p),'bytes':Path(p).stat().st_size,'sha256':sha(p)}
assert sha(PACKAGE/'final_manifest.csv')=='dfae407c449323549930428f73f93792c7c4d2dd895038234fecb2807c5aeab3'
CENTRAL.mkdir()
EVIDENCE=CENTRAL/'independent_evidence';EVIDENCE.mkdir()
copy_sources=[TEMP/'audit_calendar_saved_frame.R',TEMP/'audit_completed_chest.R',TEMP/'audit_completed_diagnostic_tables.R',
 ROOT/'replay_saved_validator.R',ROOT/'25_validate_saved_calendar_b.R',TEMP/'run_readonly_audit.py']
for name in ('calendar_audit_job_001','calendar_audit_output_001','completed_chest_audit_job_001','completed_chest_audit_output_001',
 'completed_diagnostic_audit_job_001','completed_diagnostic_audit_output_001','calendar_validator_replay_job_001','calendar_validator_replay_output_001'):
    shutil.copytree(TEMP/name,EVIDENCE/name)
for p in copy_sources:shutil.copy2(p,EVIDENCE/p.name)
account=read_csv(OLD/'audit_compute_accounting.csv')
owner_audit=PACKAGE/'date_guard_audit/audit_execution.csv'
row=read_csv(owner_audit)
assert len(row)==1 and float(row[0]['elapsed_seconds'])==0.686
account.append({'component':'owner_calendar_date_guard_audit_001','charged_seconds':row[0]['elapsed_seconds'],'basis':str(owner_audit)})
for job,component in (('calendar_audit_job_001','independent_saved_calendar_001'),
 ('completed_chest_audit_job_001','independent_completed_chest_001'),
 ('completed_diagnostic_audit_job_001','independent_saved_diagnostics_001'),
 ('calendar_validator_replay_job_001','independent_full_calendar_validator_replay_001')):
    p=EVIDENCE/job/'finish.json';j=json.loads(p.read_text())
    assert j['exit_code']==0 and j['child_reaped'] and not j['timed_out']
    account.append({'component':component,'charged_seconds':j['elapsed_seconds'],'basis':str(p)})
debit=sum(float(r['charged_seconds']) for r in account)
write_csv(ROOT/'audit_compute_accounting.csv',account)
shutil.copy2(ROOT/'audit_compute_accounting.csv',CENTRAL/'audit_compute_accounting.csv')
driver=ROOT/'25_validate_saved_calendar_b.R'
sup=STAGE/'code/run_bounded_job_v8.py'
assert sha(sup)=='147aea546b5cfd573e13868ff44c2002b585b3e47e4489df8a2b561ab974a296'
original=sup.read_text();text=original;edits=[]
def replace(a,b):
    global text
    assert text.count(a)==1 and a!=b
    text=text.replace(a,b);edits.append((a,b))
replace('"19_fit_chest_b.R"},','"19_fit_chest_b.R", "20_derive_chest_estimands.R", "21_diagnose_chest.R", "22_diagnose_stored_benchmark.R", "23_verify_calendar_count_contract.R", "24_construct_calendar_b.R"},')
block=f'''# Date-label-only saved-frame recovery. No calendar recount or prior-driver alias.
calendar_recovery_job = "VERIFY-SENSITIVITY-CALENDAR-DATE-RECOVERY-001"
calendar_recovery_driver = "25_validate_saved_calendar_b.R"
calendar_recovery_sha = "{sha(driver)}"
assert not job_id.startswith("CONSTRUCT-CALENDAR-"), "Calendar construction is consumed and immutable."
if job_id == calendar_recovery_job:
    assert driver_path.name == calendar_recovery_driver and not driver_args
    assert hashlib.sha256(driver_path.read_bytes()).hexdigest() == calendar_recovery_sha
    registration = root / "preflight/calendar_date_recovery_001/job_registry.csv"
    with registration.open(newline="") as f:
        rows = list(csv.DictReader(f))
    assert len(rows) == 1 and rows[0]["job_id"] == calendar_recovery_job
    assert Path(rows[0]["driver_path"]).resolve() == driver_path and rows[0]["driver_sha256"] == calendar_recovery_sha
    assert rows[0]["model_fit_count"] == "0" and rows[0]["reconstruction_count"] == "0"
    assert not Path(rows[0]["output_root"]).exists()
else:
    assert not job_id.startswith("VERIFY-SENSITIVITY-CALENDAR-DATE-RECOVERY"), "No saved-frame validation retry alias."
    assert driver_path.name != calendar_recovery_driver, "Saved-frame validator has one registered job."
    assert (jobs_root / calendar_recovery_job / "finish.json").is_file(), "Require exact saved-frame validation before remaining jobs."
'''
replace('frozen_continuation_inputs = {',block+'frozen_continuation_inputs = {')
new_pins={str(PACKAGE/'final_manifest.csv'):sha(PACKAGE/'final_manifest.csv'),
 str(STAGE/'calendar/frames/model_input.rds'):sha(STAGE/'calendar/frames/model_input.rds'),
 str(STAGE/'calendar/frames/manifest.csv'):sha(STAGE/'calendar/frames/manifest.csv'),
 str(STAGE/'code/24_construct_calendar_b.R'):sha(STAGE/'code/24_construct_calendar_b.R'),
 str(EVIDENCE/'calendar_audit_output_001/checks.csv'):sha(EVIDENCE/'calendar_audit_output_001/checks.csv'),
 str(CENTRAL/'audit_compute_accounting.csv'):sha(CENTRAL/'audit_compute_accounting.csv')}
replace('for frozen_path, expected_hash in frozen_continuation_inputs.items():',
 'frozen_continuation_inputs.update('+repr(new_pins)+')\nfor frozen_path, expected_hash in frozen_continuation_inputs.items():')
replace('independent_audit_seconds = 37.339253292007136',f'independent_audit_seconds = {debit!r}')
hist=STAGE/'preflight/execution_jobs/CONSTRUCT-CALENDAR-B'
hist_pins={n:sha(hist/n) for n in ('start.json','finish.json','execution.log')}
record=json.loads((hist/'finish.json').read_text())
assert record['exit_code']==1 and record['child_reaped'] and not record['timed_out']
history=f'''    elif previous.name == "CONSTRUCT-CALENDAR-B":
        historical_pins = {hist_pins!r}
        for name, expected_sha256 in historical_pins.items():
            assert hashlib.sha256((previous / name).read_bytes()).hexdigest() == expected_sha256
        assert record["job_id"] == "CONSTRUCT-CALENDAR-B" and record["driver_sha256"] == "{sha(STAGE/'code/24_construct_calendar_b.R')}"
        assert record["supervisor_sha256"] == "{sha(sup)}"
        assert record["exit_code"] == 1 and not record["timed_out"] and record["child_reaped"]
        assert record["elapsed_seconds"] == {record['elapsed_seconds']!r}
    elif previous.name == calendar_recovery_job:
        assert record["job_id"] == calendar_recovery_job and record["driver_sha256"] == calendar_recovery_sha
        assert Path(record["command"][2]).name == calendar_recovery_driver and len(record["command"]) == 3
        assert record["exit_code"] == 0 and not record["timed_out"] and record["child_reaped"], "A new saved-frame validation failure needs a stopped disposition."
'''
replace('    elif previous.name == chest_prefit_job:',history+'    elif previous.name == chest_prefit_job:')
replace('    "prefit_recovery_authority": "BA-018-CHEST-PREFIT-RECOVERY-001",',
 '    "prefit_recovery_authority": "BA-018-CHEST-PREFIT-RECOVERY-001",\n    "calendar_date_recovery_authority": "BA-018-CALENDAR-DATE-RECOVERY-001",')
ast.parse(text)
write(ROOT/'run_bounded_job_v9.py',text)
reverse=text
for a,b in reversed(edits):
    assert reverse.count(b)==1
    reverse=reverse.replace(b,a)
assert reverse==original
write(ROOT/'supervisor_v8_reconstructed.py',reverse)
write(ROOT/'supervisor_exact_changes.json',json.dumps(edits,indent=2)+'\n')
registry=[{'job_id':'VERIFY-SENSITIVITY-CALENDAR-DATE-RECOVERY-001','driver_path':str(STAGE/'code'/driver.name),
 'driver_sha256':sha(driver),'input_path':str(STAGE/'calendar/frames/model_input.rds'),
 'input_sha256':sha(STAGE/'calendar/frames/model_input.rds'),'parent_path':str(STAGE/'frames/model_frames.rds'),
 'parent_sha256':sha(STAGE/'frames/model_frames.rds'),
 'independent_validation_path':str(EVIDENCE/'calendar_audit_output_001/checks.csv'),
 'independent_validation_sha256':sha(EVIDENCE/'calendar_audit_output_001/checks.csv'),
 'output_root':str(STAGE/'calendar/saved_frame_validation_001'),'model_fit_count':0,'reconstruction_count':0,
 'draws':0,'wall_cap_seconds':120}]
write_csv(ROOT/'job_registry.csv',registry)
source=[]
for p in (driver, ROOT/'run_bounded_job_v9.py', ROOT/'job_registry.csv'):
    target=STAGE/'code'/p.name if p.suffix in ('.R','.py') else REG/p.name
    source.append(identity(p,target))
for p in (STAGE/'code/runtime_contract.R',STAGE/'frames/model_frames.rds',STAGE/'calendar/frames/manifest.csv',
 STAGE/'tests/calendar_count_contract/manifest.csv',STAGE/'preflight/chest_prefit_recovery_001/calendar_construction_source_manifest.csv',
 PACKAGE/'final_manifest.csv',PACKAGE/'finalization_checks.csv',EVIDENCE/'calendar_audit_output_001/checks.csv',
 EVIDENCE/'calendar_audit_output_001/input_manifest.csv',EVIDENCE/'calendar_audit_job_001/finish.json',
 EVIDENCE/'calendar_validator_replay_output_001/checks.csv',EVIDENCE/'calendar_validator_replay_output_001/negative_fixtures.csv',
 STAGE.parent/'stage1/plan.md',STAGE.parent/'stage1/formula_registry.csv',CENTRAL/'audit_compute_accounting.csv'):
    source.append(identity(p))
source.extend(read_csv(STAGE/'calendar/frames/manifest.csv'))
assert len({r['path'] for r in source})==len(source)
write_csv(ROOT/'source_manifest.csv',source)
mapping=[]
for name,target in (('25_validate_saved_calendar_b.R',STAGE/'code/25_validate_saved_calendar_b.R'),
 ('run_bounded_job_v9.py',STAGE/'code/run_bounded_job_v9.py'),('job_registry.csv',REG/'job_registry.csv'),
 ('source_manifest.csv',REG/'source_manifest.csv')):
    p=ROOT/name;assert not target.exists()
    mapping.append({'source_path':str(EVIDENCE/name),'destination_path':str(target),'bytes':p.stat().st_size,'sha256':sha(p)})
write_csv(ROOT/'exact_owner_copy_map.csv',mapping)
for p in ROOT.iterdir():
    if p.is_file() and not (EVIDENCE/p.name).exists():shutil.copy2(p,EVIDENCE/p.name)
shutil.copy2(ROOT/'exact_owner_copy_map.csv',CENTRAL/'exact_owner_copy_map.csv')
history_seconds=sum(json.loads(p.read_text())['elapsed_seconds'] for p in (STAGE/'preflight/execution_jobs').glob('*/finish.json'))
write(ROOT/'summary.json',json.dumps({'copies':mapping,'source_rows':len(source),'history_seconds':history_seconds,
 'fixed_audit_seconds':debit,'starting_debit':history_seconds+debit,'changes':len(edits)},indent=2)+'\n')
print((ROOT/'summary.json').read_text())
