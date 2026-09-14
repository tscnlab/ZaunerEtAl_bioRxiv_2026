"""Infrastructure-only copies, exact source substitutions and wall-time accounting."""
import csv, difflib, hashlib, json, shutil
from pathlib import Path

CENTRAL = Path(__file__).resolve().parent
EVIDENCE = CENTRAL / 'independent_evidence'
assert not EVIDENCE.exists()
EVIDENCE.mkdir()
AUTHOR = CENTRAL.parents[2]
OWNER = Path('/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026')
STAGE = OWNER / 'audit/analyses/brown_adherence/main_linkage_b_amendment/stage2'
TMP = Path('/private/tmp/ba018-completion-audit.ekpsA4')
REG = STAGE / 'preflight/temporal_transport_recovery_001'
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
def csv_write(path, rows):
    assert rows and not path.exists()
    with path.open('x', newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
def load_csv(path):
    with path.open(newline='') as f:return list(csv.DictReader(f))

for name in ('temporal_transport_prospective_001','temporal_transport_prospective_002',
             'temporal_transport_audit_execution_001','temporal_transport_audit_output_001',
             'temporal_transport_audit_execution_002','temporal_transport_audit_output_002',
             'temporal_transport_audit_execution_003','temporal_transport_audit_output_003',
             'calendar_completed_audit_execution_001','calendar_completed_audit_output_001'):
    shutil.copytree(TMP/name,EVIDENCE/name)
for name in ('audit_temporal_transport_recovery.R','audit_temporal_transport_recovery_v2.R',
             'audit_temporal_transport_recovery_v3.R','audit_completed_calendar.R','run_readonly_audit.py'):
    shutil.copy2(TMP/name,EVIDENCE/name)

files=EVIDENCE/'exact_owner_files';files.mkdir()
code_names=('30_temporal_fit_contract_v2.R','32_verify_prepare_temporal_interfaces_v2.R',
            '33_fit_temporal_candidate_v2.R','34_derive_temporal_estimands_v2.R','35_diagnose_selected_temporal_v2.R')
copy_rows=[]
for name in code_names:
    source=files/name;shutil.copy2(TMP/'temporal_transport_prospective_002'/name,source)
    dest=STAGE/'code'/name
    assert not dest.exists()
    copy_rows.append(dict(source_path=str(source),destination_path=str(dest),bytes=source.stat().st_size,sha256=sha(source)))
    old=STAGE/'code'/name.replace('_v2.R','.R')
    (EVIDENCE/(name+'.diff')).write_text(''.join(difflib.unified_diff(old.read_text().splitlines(keepends=True),source.read_text().splitlines(keepends=True),fromfile=str(old),tofile=str(dest))))

account=[dict(component='previous_fixed_audits',basis='BA-018-CALENDAR-DATE-RECOVERY-001 fixed debit',charged_seconds=59.03137896001269),
         dict(component='owner_package009_transport_diagnosis',basis=str(STAGE/'completion_v2/continued_final_package_009/transport_guard_audit/audit_execution.csv'),charged_seconds=0.845)]
for name in ('temporal_transport_audit_execution_001','calendar_completed_audit_execution_001','temporal_transport_audit_execution_002','temporal_transport_audit_execution_003'):
    finish=TMP/name/'finish.json';record=json.loads(finish.read_text())
    assert not record['timed_out'] and record['child_reaped']
    assert record['exit_code']==(1 if name=='temporal_transport_audit_execution_002' else 0)
    account.append(dict(component=name,basis=str(EVIDENCE/name/'finish.json'),charged_seconds=record['elapsed_seconds']))
debit=sum(row['charged_seconds'] for row in account)
csv_write(CENTRAL/'audit_compute_accounting.csv',account)
histories=sorted((STAGE/'preflight/execution_jobs').glob('*/finish.json'))
assert len(histories)==82
records=[json.loads(p.read_text()) for p in histories]
assert sum(r['exit_code']!=0 for r in records)==8
assert all(r['child_reaped'] and not r['timed_out'] for r in records)
used=debit+sum(r['elapsed_seconds'] for r in records)
assert used<1200

old_sup=STAGE/'code/run_bounded_job_v9.py';sup=old_sup.read_text();original=sup;changes=[]
def replace_once(old,new):
    global sup
    assert sup.count(old)==1,old[:100]
    sup=sup.replace(old,new);changes.append([old,new])
REC='VERIFY-SENSITIVITY-TEMPORAL-TRANSPORT-RECOVERY-001'
drivers={REC:('32_verify_prepare_temporal_interfaces_v2.R',sha(files/'32_verify_prepare_temporal_interfaces_v2.R'),[])}
for sample in ('ANY','80'):
    for route in ('ENDPOINT-R3','BB-R0','BB-R3'):
        job=f'TEMPORAL-{sample}-{route}'
        drivers[job]=('33_fit_temporal_candidate_v2.R',sha(files/'33_fit_temporal_candidate_v2.R'),[job])
    drivers[f'DERIVE-SENSITIVITY-TEMPORAL-{sample}']=('34_derive_temporal_estimands_v2.R',sha(files/'34_derive_temporal_estimands_v2.R'),[sample])
    drivers[f'DIAGNOSTICS-TEMPORAL-{sample}']=('35_diagnose_selected_temporal_v2.R',sha(files/'35_diagnose_selected_temporal_v2.R'),[sample])
boundary=f'''# Exact finite temporal continuation. Every other historical route remains closed.
temporal_recovery_job = {REC!r}
temporal_drivers = {drivers!r}
assert job_id in temporal_drivers, "Only the finite temporal recovery and remaining registered ladder are released."
expected_name, expected_sha, expected_args = temporal_drivers[job_id]
assert driver_path.name == expected_name and driver_args == expected_args
assert hashlib.sha256(driver_path.read_bytes()).hexdigest() == expected_sha
if job_id == temporal_recovery_job:
    registration = root / "preflight/temporal_transport_recovery_001/temporal_interface_job_registry.csv"
    with registration.open(newline="") as f:
        rows = list(csv.DictReader(f))
    assert len(rows) == 1 and rows[0]["job_id"] == job_id
    assert Path(rows[0]["driver_path"]).resolve() == driver_path and rows[0]["driver_sha256"] == expected_sha
    assert rows[0]["model_fit_count"] == "0" and rows[0]["diagnostic_draws"] == "0"
    assert not Path(rows[0]["output_root"]).exists()
else:
    assert (jobs_root / temporal_recovery_job / "finish.json").is_file(), "Complete the one temporal input recovery first."
'''
replace_once('frozen_continuation_inputs = {',boundary+'frozen_continuation_inputs = {')
frozen={str(STAGE/'completion_v2/continued_final_package_009/final_manifest.csv'): 'ba20de91310338cfe290c3ff85051c82afccb4261394f14e885ae6bd5313847a',
        str(STAGE/'temporal/inputs/ANY.rds'):sha(STAGE/'temporal/inputs/ANY.rds'),
        str(CENTRAL/'audit_compute_accounting.csv'):sha(CENTRAL/'audit_compute_accounting.csv')}
for name in ('30_temporal_fit_contract.R','31_temporal_reporting_contract.R','32_verify_prepare_temporal_interfaces.R','33_fit_temporal_candidate.R','34_derive_temporal_estimands.R','35_diagnose_selected_temporal.R'):
    frozen[str(STAGE/'code'/name)]=sha(STAGE/'code'/name)
replace_once('for frozen_path, expected_hash in frozen_continuation_inputs.items():',f'frozen_continuation_inputs.update({frozen!r})\nfor frozen_path, expected_hash in frozen_continuation_inputs.items():')
replace_once('independent_audit_seconds = 59.03137896001269',f'independent_audit_seconds = {debit!r}')
failed=STAGE/'preflight/execution_jobs/VERIFY-SENSITIVITY-TEMPORAL-INTERFACES'
failed_pins={n:sha(failed/n) for n in ('start.json','finish.json','execution.log')}
failed_record=json.loads((failed/'finish.json').read_text())
history_branch=f'''    elif previous.name == "VERIFY-SENSITIVITY-TEMPORAL-INTERFACES":
        historical_pins = {failed_pins!r}
        for name, expected_sha256 in historical_pins.items():
            assert hashlib.sha256((previous / name).read_bytes()).hexdigest() == expected_sha256
        assert record["job_id"] == previous.name and record["driver_sha256"] == {failed_record['driver_sha256']!r}
        assert record["supervisor_sha256"] == {failed_record['supervisor_sha256']!r}
        assert record["exit_code"] == 1 and not record["timed_out"] and record["child_reaped"]
        assert record["elapsed_seconds"] == {failed_record['elapsed_seconds']!r}
    elif previous.name == temporal_recovery_job:
        assert record["job_id"] == temporal_recovery_job and record["driver_sha256"] == temporal_drivers[temporal_recovery_job][1]
        assert Path(record["command"][2]).name == temporal_drivers[temporal_recovery_job][0] and len(record["command"]) == 3
        assert record["exit_code"] == 0 and not record["timed_out"] and record["child_reaped"], "A new temporal validation failure requires disposition."
'''
replace_once('    elif previous.name == calendar_recovery_job:',history_branch+'    elif previous.name == calendar_recovery_job:')
replace_once('    "calendar_date_recovery_authority": "BA-018-CALENDAR-DATE-RECOVERY-001",','    "calendar_date_recovery_authority": "BA-018-CALENDAR-DATE-RECOVERY-001",\n    "temporal_transport_recovery_authority": "BA-018-TEMPORAL-TRANSPORT-RECOVERY-001",')
new_sup=files/'run_bounded_job_v10.py';new_sup.write_text(sup)
rev=sup
for old,new in reversed(changes):
    assert rev.count(new)==1;rev=rev.replace(new,old)
assert rev==original
(EVIDENCE/'supervisor_v9_reconstructed.py').write_text(rev)
(EVIDENCE/'supervisor_exact_changes.json').write_text(json.dumps(changes,indent=2)+'\n')
dest=STAGE/'code'/new_sup.name
copy_rows.append(dict(source_path=str(new_sup),destination_path=str(dest),bytes=new_sup.stat().st_size,sha256=sha(new_sup)))
registry=load_csv(STAGE/'preflight/calendar_date_recovery_001/temporal_interface_job_registry.csv')
assert len(registry)==1
r=registry[0];r.update(job_id=REC,driver_path=str(STAGE/'code'/drivers[REC][0]),driver_sha256=drivers[REC][1],output_root=str(STAGE/'temporal/inputs_recovery_001'),scope='Exact grouping-level recovery; reuse immutable ANY input and construct only missing 80 input after complete interfaces; zero fits and draws')
reg_source=files/'temporal_interface_job_registry.csv';csv_write(reg_source,registry)
copy_rows.append(dict(source_path=str(reg_source),destination_path=str(REG/reg_source.name),bytes=reg_source.stat().st_size,sha256=sha(reg_source)))
old_source=load_csv(STAGE/'preflight/calendar_date_recovery_001/temporal_interface_source_manifest.csv')
future={r['destination_path']:r for r in copy_rows}
mapping={str(STAGE/'code'/n.replace('_v2.R','.R')):str(STAGE/'code'/n) for n in code_names}
mapping[str(old_sup)]=str(dest)
mapping[str(STAGE/'preflight/calendar_date_recovery_001/temporal_interface_job_registry.csv')]=str(REG/reg_source.name)
paths=[mapping.get(r['path'],r['path']) for r in old_source]
paths+=list(frozen)+[str(STAGE/'preflight/calendar_date_recovery_001/temporal_interface_source_manifest.csv')]
source_rows=[]
for p in sorted(set(paths)):
    if p in future:source_rows.append(dict(path=p,bytes=future[p]['bytes'],sha256=future[p]['sha256']))
    else:
        q=Path(p);source_rows.append(dict(path=p,bytes=q.stat().st_size,sha256=sha(q)))
source_manifest=files/'temporal_interface_source_manifest.csv';csv_write(source_manifest,source_rows)
copy_rows.append(dict(source_path=str(source_manifest),destination_path=str(REG/source_manifest.name),bytes=source_manifest.stat().st_size,sha256=sha(source_manifest)))
assert len(copy_rows)==8 and all(not Path(r['destination_path']).exists() for r in copy_rows)
csv_write(CENTRAL/'exact_owner_copy_map.csv',copy_rows)
summary=dict(authority='BA-018-TEMPORAL-TRANSPORT-RECOVERY-001',historical_jobs=82,historical_failures=8,
             fixed_audit_seconds=debit,starting_debit=used,remaining_seconds=1200-used,
             source_rows=len(source_rows),copies=len(copy_rows),supervisor_changes=len(changes),
             source_hashes={r['destination_path']:r['sha256'] for r in copy_rows})
(EVIDENCE/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
