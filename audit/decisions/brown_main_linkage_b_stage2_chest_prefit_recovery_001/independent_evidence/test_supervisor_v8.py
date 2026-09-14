"""Process-only fixtures. No real R invocation, signals or scientific work."""
import ast,contextlib,csv,io,json,os,runpy,shutil,subprocess,sys,tempfile
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parent
STAGE=Path('/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2')
SUP=ROOT/'run_bounded_job_v8.py';REC='CHEST-ANY-PREFIT-RECOVERY-001'
SUITE=Path(tempfile.mkdtemp(prefix='mocks_',dir=ROOT))
ENV={'RENV_CONFIG_AUTOLOADER_ENABLED':'FALSE','OMP_NUM_THREADS':'1','OPENBLAS_NUM_THREADS':'1','MKL_NUM_THREADS':'1','VECLIB_MAXIMUM_THREADS':'1'}
checks=[];calls=[];signals=[]
with (ROOT/'audit_compute_accounting.csv').open(newline='') as f:
    debit=sum(float(r['charged_seconds']) for r in csv.DictReader(f))
history=sum(json.loads(p.read_text())['elapsed_seconds'] for p in (STAGE/'preflight/execution_jobs').glob('*/finish.json'))
expected=history+debit
def check(name,ok):
    checks.append({'check':name,'pass':bool(ok)});assert ok,name
def scenario(name):
    dst=SUITE/name;(dst/'code').mkdir(parents=True)
    shutil.copytree(STAGE/'preflight/execution_jobs',dst/'preflight/execution_jobs')
    for src in (SUP,ROOT/'19_fit_chest_b_v2.R',STAGE/'code/19_fit_chest_b.R'):
        shutil.copy2(src,dst/'code'/src.name)
    (dst/'code/99_mock.R').write_text('# INERT FIXTURE ONLY\n')
    reg=dst/'preflight/chest_prefit_recovery_001';reg.mkdir()
    with (ROOT/'chest_fit_job_registry.csv').open(newline='') as f: rows=list(csv.DictReader(f))
    rows[0]['driver_path']=str(dst/'code/19_fit_chest_b_v2.R')
    rows[0]['model_path']=str(dst/'models/BA-LB-CHEST-ANY.rds')
    rows[0]['manifest_path']=str(dst/'models/BA-LB-CHEST-ANY_manifest.csv')
    with (reg/'chest_fit_job_registry.csv').open('x',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
    return dst
class Child:
    code=0;timeout=False
    def __init__(self,command,stdout,stderr,start_new_session):
        assert command[:2]==['/usr/local/bin/Rscript','--vanilla'] and Path(command[2]).is_relative_to(SUITE)
        assert start_new_session;calls.append(command);stdout.write(b'INERT PROCESS FIXTURE ONLY\n');self.pid=999997;self.waits=0
    def wait(self,timeout=None):
        self.waits+=1
        if type(self).timeout and self.waits==1: raise subprocess.TimeoutExpired('MOCK',timeout)
        return type(self).code
    def poll(self):return type(self).code
def invoke(dst,job=REC,driver=None,args=(),limit='120'):
    driver=driver or ('19_fit_chest_b_v2.R' if job==REC else '99_mock.R')
    sup=dst/'code/run_bounded_job_v8.py';out=io.StringIO();error=None
    with patch.object(sys,'argv',[str(sup),job,limit,str(dst/'code'/driver),*args]),patch.dict(os.environ,ENV),patch('subprocess.Popen',Child),patch('time.monotonic',side_effect=[100.,101.]),patch('os.killpg',side_effect=lambda p,s:signals.append((p,s))),contextlib.redirect_stdout(out):
        try:runpy.run_path(str(sup),run_name='__main__')
        except SystemExit as ex:
            if ex.code:error=ex
        except Exception as ex:error=ex
    (dst/(job+'.log')).write_text(out.getvalue()+'\n'+repr(error)+'\n');return error
def record(dst,job=REC):return json.loads((dst/'preflight/execution_jobs'/job/'finish.json').read_text())
def warm(name):
    p=scenario(name);assert invoke(p) is None;return p
check('parse_exact_v8',bool(ast.parse(SUP.read_text())))
check('reverse_exact_v7',(ROOT/'supervisor_v7_reconstructed.py').read_bytes()==(STAGE/'code/run_bounded_job_v7.py').read_bytes())
p=warm('positive')
check('single_exact_recovery',record(p)['exit_code']==0 and record(p)['child_reaped'])
check('all71_jobs_and_audit_once',abs(record(p)['budget_used_before_seconds']-expected)<1e-9 and record(p)['independent_audit_seconds_charged_once']==debit)
check('lock_removed',not (p/'preflight/computation.lock').exists())
check('calendar_after_recovery',invoke(p,'CALENDAR-CHUNKS') is None)
check('no_debit_reset',abs(record(p,'CALENDAR-CHUNKS')['budget_used_before_seconds']-expected-1)<1e-9)
check('temporal_after_recovery',invoke(p,'TEMPORAL-ANY-ENDPOINT-R3',limit='180') is None)
check('caps_and_draws',record(p,'TEMPORAL-ANY-ENDPOINT-R3')['effective_wall_limit_seconds']==180 and record(p)['maximum_attempted_diagnostic_draws']==1750 and record(p)['maximum_logical_final_diagnostic_draws']==1500)
check('replay_blocked',isinstance(invoke(p),AssertionError))
p=scenario('ordering')
check('calendar_held_until_recovery',isinstance(invoke(p,'CALENDAR-CHUNKS'),AssertionError))
check('wrong_driver_blocked',isinstance(invoke(p,driver='99_mock.R'),AssertionError))
check('extra_argument_blocked',isinstance(invoke(p,args=('EXTRA',)),AssertionError))
for bad in ('CHEST-ANY','CHEST-ANY-PREFIT-RECOVERY-002','CHEST-ANY-ALIAS','PRIMARY-ANY-RETRY','R2-PRIMARY','SHAPLEY-PRIMARY','ARBITRARY'):
    p=scenario('bad_'+bad);n=len(calls)
    check(bad+'_blocked',isinstance(invoke(p,bad),AssertionError) and len(calls)==n)
p=warm('alias')
check('driver_alias_blocked',isinstance(invoke(p,'COMPARE-SENSITIVITY-CHEST',driver='19_fit_chest_b_v2.R'),AssertionError))
check('old_driver_blocked',isinstance(invoke(p,'COMPARE-SENSITIVITY-OLD',driver='19_fit_chest_b.R'),AssertionError))
p=scenario('changed');q=p/'code/19_fit_chest_b_v2.R';q.write_bytes(q.read_bytes()+b'\n')
check('changed_driver_blocked',isinstance(invoke(p),AssertionError))
for job in ('CHEST-ANY','DERIVE-PRIMARY-ESTIMANDS','CONSTRUCT-CHEST-B'):
    for name in ('start.json','finish.json','execution.log'):
        p=scenario('tamper_'+job+'_'+name);q=p/'preflight/execution_jobs'/job/name;q.write_bytes(q.read_bytes()+b'\n');n=len(calls)
        check('history_'+job+'_'+name,isinstance(invoke(p),AssertionError) and len(calls)==n)
p=scenario('lock');(p/'preflight/computation.lock').write_text('FIXTURE')
check('exclusive_lock',isinstance(invoke(p),FileExistsError))
p=scenario('failure');Child.code=1
check('new_failure_preserved',isinstance(invoke(p),SystemExit));Child.code=0
check('new_failure_blocks_later',isinstance(invoke(p,'CALENDAR-CHUNKS'),AssertionError))
p=scenario('timeout');Child.timeout=True
check('timeout_preserved',isinstance(invoke(p),SystemExit));Child.timeout=False
check('only_mock_child_signalled',record(p)['timed_out'] and record(p)['child_reaped'] and signals[-1][0]==999997)
check('timeout_blocks_later',isinstance(invoke(p,'CALENDAR-CHUNKS'),AssertionError))
p=scenario('cap');check('ordinary121_rejected',isinstance(invoke(p,limit='121'),AssertionError))
for name,extra,ok in (('exhausted',1200.,False),('remaining',1200.-expected-1.5,True)):
    p=scenario(name);q=p/'preflight/execution_jobs/COMPARE-SENSITIVITY-FIXTURE';q.mkdir()
    (q/'finish.json').write_text(json.dumps({'elapsed_seconds':extra,'exit_code':0,'timed_out':False,'child_reaped':True}))
    err=invoke(p)
    check(name+'_ceiling',(err is None) if ok else isinstance(err,AssertionError))
    if ok:check('clamped_to_remaining',abs(record(p)['effective_wall_limit_seconds']-1.5)<1e-9)
with (ROOT/'supervisor_checks.csv').open('x',newline='') as f:
    w=csv.DictWriter(f,fieldnames=['check','pass']);w.writeheader();w.writerows(checks)
(ROOT/'supervisor_summary.json').write_text(json.dumps({'checks':len(checks),'pass':all(r['pass'] for r in checks),'history_seconds':history,'fixed_audit_seconds':debit,'starting_debit':expected,'real_R_children':0,'real_signals':0},indent=2)+'\n')
print('SUPERVISOR_V8=PASS',len(checks),'checks; debit',expected)
