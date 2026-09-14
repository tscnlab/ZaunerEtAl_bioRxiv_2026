"""Inert infrastructure fixtures. No R subprocess or real signal is permitted."""
import ast, contextlib, csv, io, json, os, runpy, shutil, subprocess, sys, tempfile
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parent
FILES=ROOT/'exact_owner_files'
STAGE=Path('/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2')
SUP=FILES/'run_bounded_job_v10.py'
REC='VERIFY-SENSITIVITY-TEMPORAL-TRANSPORT-RECOVERY-001'
DRIVER='32_verify_prepare_temporal_interfaces_v2.R'
SUITE=Path(tempfile.mkdtemp(prefix='supervisor_fixtures_',dir=ROOT))
ENV={'RENV_CONFIG_AUTOLOADER_ENABLED':'FALSE','OMP_NUM_THREADS':'1','OPENBLAS_NUM_THREADS':'1','MKL_NUM_THREADS':'1','VECLIB_MAXIMUM_THREADS':'1'}
summary=json.loads((ROOT/'summary.json').read_text())
expected=summary['starting_debit'];debit=summary['fixed_audit_seconds']
checks=[];calls=[];signals=[]
def check(name,ok):
    checks.append(dict(check=name,pass_value=bool(ok)));assert ok,name
def scenario(name):
    dst=SUITE/name;(dst/'code').mkdir(parents=True)
    shutil.copytree(STAGE/'preflight/execution_jobs',dst/'preflight/execution_jobs')
    for src in FILES.iterdir():
        if src.suffix in ('.R','.py'):shutil.copy2(src,dst/'code'/src.name)
    (dst/'code/99_inert.R').write_text('# No execution.\n')
    reg=dst/'preflight/temporal_transport_recovery_001';reg.mkdir()
    with (FILES/'temporal_interface_job_registry.csv').open(newline='') as f:rows=list(csv.DictReader(f))
    rows[0]['driver_path']=str(dst/'code'/DRIVER)
    rows[0]['output_root']=str(dst/'temporal/inputs_recovery_001')
    with (reg/'temporal_interface_job_registry.csv').open('x',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
    return dst
class Child:
    code=0;timeout=False
    def __init__(self,command,stdout,stderr,start_new_session):
        assert command[:2]==['/usr/local/bin/Rscript','--vanilla'] and Path(command[2]).is_relative_to(SUITE)
        assert start_new_session;calls.append(command);stdout.write(b'INERT MOCK ONLY\n');self.pid=999996;self.waits=0
    def wait(self,timeout=None):
        self.waits+=1
        if type(self).timeout and self.waits==1:raise subprocess.TimeoutExpired('MOCK',timeout)
        return type(self).code
    def poll(self):return type(self).code
def invoke(dst,job=REC,driver=None,args=None,limit=None):
    if driver is None:
        driver=DRIVER if job==REC else '33_fit_temporal_candidate_v2.R' if job.startswith('TEMPORAL-') else '34_derive_temporal_estimands_v2.R' if job.startswith('DERIVE-SENSITIVITY-TEMPORAL-') else '35_diagnose_selected_temporal_v2.R'
    if args is None:args=[] if job==REC else [job] if job.startswith('TEMPORAL-') else [job.rsplit('-',1)[-1]]
    limit=limit or ('180' if job.startswith('TEMPORAL-') else '120')
    sup=dst/'code/run_bounded_job_v10.py';out=io.StringIO();error=None
    with patch.object(sys,'argv',[str(sup),job,limit,str(dst/'code'/driver),*args]),patch.dict(os.environ,ENV),patch('subprocess.Popen',Child),patch('time.monotonic',side_effect=[100.,101.]),patch('os.killpg',side_effect=lambda p,s:signals.append((p,s))),contextlib.redirect_stdout(out):
        try:runpy.run_path(str(sup),run_name='__main__')
        except SystemExit as ex:
            if ex.code:error=ex
        except Exception as ex:error=ex
    (dst/(job+'.log')).write_text(out.getvalue()+'\n'+repr(error)+'\n');return error
def record(dst,job=REC):return json.loads((dst/'preflight/execution_jobs'/job/'finish.json').read_text())
def warm(name):
    p=scenario(name);err=invoke(p);assert err is None,repr(err);return p
check('v10_parse',bool(ast.parse(SUP.read_text())))
check('exact_v9_reverse',(ROOT/'supervisor_v9_reconstructed.py').read_bytes()==(STAGE/'code/run_bounded_job_v9.py').read_bytes())
p=warm('positive')
check('exact_recovery',record(p)['exit_code']==0 and record(p)['child_reaped'])
check('82_histories_all_audits_once',abs(record(p)['budget_used_before_seconds']-expected)<1e-9 and record(p)['independent_audit_seconds_charged_once']==debit)
check('lock_cleaned',not (p/'preflight/computation.lock').exists())
for sample in ('ANY','80'):
    for route in ('ENDPOINT-R3','BB-R0','BB-R3'):
        job=f'TEMPORAL-{sample}-{route}'
        check(job,invoke(p,job) is None and record(p,job)['effective_wall_limit_seconds']==180)
    for kind in ('DERIVE-SENSITIVITY','DIAGNOSTICS'):
        job=f'{kind}-TEMPORAL-{sample}'
        check(job,invoke(p,job) is None)
check('elapsed_added_once',abs(record(p,'TEMPORAL-ANY-ENDPOINT-R3')['budget_used_before_seconds']-expected-1)<1e-9)
check('draw_caps_unchanged',record(p)['maximum_attempted_diagnostic_draws']==1750 and record(p)['maximum_logical_final_diagnostic_draws']==1500)
check('no_recovery_repeat',isinstance(invoke(p),AssertionError))
p=scenario('before');check('fit_held_before_recovery',isinstance(invoke(p,'TEMPORAL-ANY-ENDPOINT-R3'),AssertionError))
check('wrong_driver_blocked',isinstance(invoke(p,driver='99_inert.R'),AssertionError))
check('extra_arg_blocked',isinstance(invoke(p,args=['EXTRA']),AssertionError))
for job in ('VERIFY-SENSITIVITY-TEMPORAL-INTERFACES',REC+'-ALIAS','TEMPORAL-ANY-BB-R1','TEMPORAL-CHEST-ENDPOINT-R3','PRIMARY-ANY-RETRY','CALENDAR-CHUNKS','CHEST-ANY','R2-PRIMARY','SHAPLEY-PRIMARY','VERIFY-SENSITIVITY-ARBITRARY'):
    p=scenario('bad_'+job);n=len(calls)
    check(job+'_blocked',isinstance(invoke(p,job,driver='99_inert.R',args=[]),AssertionError) and len(calls)==n)
p=scenario('changed_driver');f=p/'code'/DRIVER;f.write_bytes(f.read_bytes()+b'\n')
check('changed_driver',isinstance(invoke(p),AssertionError))
for job in ('VERIFY-SENSITIVITY-TEMPORAL-INTERFACES','CONSTRUCT-CALENDAR-B','DERIVE-PRIMARY-ESTIMANDS'):
    for name in ('start.json','finish.json','execution.log'):
        p=scenario('tamper_'+job+'_'+name);f=p/'preflight/execution_jobs'/job/name;f.write_bytes(f.read_bytes()+b'\n');n=len(calls)
        check('historical_'+job+'_'+name,isinstance(invoke(p),AssertionError) and len(calls)==n)
p=scenario('lock');(p/'preflight/computation.lock').write_text('INERT')
check('exclusive_lock',isinstance(invoke(p),FileExistsError))
p=scenario('existing_output');(p/'temporal/inputs_recovery_001').mkdir(parents=True)
check('existing_output_blocked',isinstance(invoke(p),AssertionError))
p=scenario('failure');Child.code=1
check('failure_recorded',isinstance(invoke(p),SystemExit));Child.code=0
check('failure_blocks_next',isinstance(invoke(p,'TEMPORAL-ANY-ENDPOINT-R3'),AssertionError))
p=scenario('timeout');Child.timeout=True
check('timeout_recorded',isinstance(invoke(p),SystemExit));Child.timeout=False
check('only_mock_child_signalled',record(p)['timed_out'] and record(p)['child_reaped'] and signals[-1][0]==999996)
check('timeout_blocks_next',isinstance(invoke(p,'TEMPORAL-ANY-ENDPOINT-R3'),AssertionError))
p=scenario('cap');check('ordinary121_blocked',isinstance(invoke(p,limit='121'),AssertionError))
for name,extra,ok in (('exhausted',1200.,False),('remaining',1200.-expected-1.5,True)):
    p=scenario(name);q=p/'preflight/execution_jobs/COMPARE-SENSITIVITY-INERT';q.mkdir()
    (q/'finish.json').write_text(json.dumps(dict(elapsed_seconds=extra,exit_code=0,timed_out=False,child_reaped=True)))
    err=invoke(p)
    check(name+'_ceiling',(err is None) if ok else isinstance(err,AssertionError))
    if ok:check('remaining_clamped',abs(record(p)['effective_wall_limit_seconds']-1.5)<1e-9)
with (ROOT/'supervisor_checks.csv').open('x',newline='') as f:
    w=csv.DictWriter(f,fieldnames=['check','pass']);w.writeheader();w.writerows({'check':r['check'],'pass':r['pass_value']} for r in checks)
(ROOT/'supervisor_summary.json').write_text(json.dumps(dict(checks=len(checks),passed=all(r['pass_value'] for r in checks),starting_debit=expected,fixed_audit_seconds=debit,real_R_children=0,real_signals=0),indent=2)+'\n')
print('SUPERVISOR_V10=PASS',len(checks),'checks',expected,'seconds')
