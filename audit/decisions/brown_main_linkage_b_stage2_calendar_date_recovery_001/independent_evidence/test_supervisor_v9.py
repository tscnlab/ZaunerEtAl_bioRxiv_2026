"""Infrastructure-only fixtures. Never starts R, sends real signals or changes owner files."""
import ast,contextlib,csv,io,json,os,runpy,shutil,subprocess,sys,tempfile
from pathlib import Path
from unittest.mock import patch
ROOT=Path(__file__).resolve().parent
STAGE=Path('/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2')
SUP=ROOT/'run_bounded_job_v9.py'
REC='VERIFY-SENSITIVITY-CALENDAR-DATE-RECOVERY-001'
DRIVER='25_validate_saved_calendar_b.R'
SUITE=Path(tempfile.mkdtemp(prefix='supervisor_fixtures_',dir=ROOT))
ENV={'RENV_CONFIG_AUTOLOADER_ENABLED':'FALSE','OMP_NUM_THREADS':'1','OPENBLAS_NUM_THREADS':'1','MKL_NUM_THREADS':'1','VECLIB_MAXIMUM_THREADS':'1'}
summary=json.loads((ROOT/'summary.json').read_text())
expected=summary['starting_debit'];debit=summary['fixed_audit_seconds']
checks=[];calls=[];signals=[]
def check(name,ok):
    checks.append({'check':name,'pass':bool(ok)});assert ok,name
def scenario(name):
    dst=SUITE/name;(dst/'code').mkdir(parents=True)
    shutil.copytree(STAGE/'preflight/execution_jobs',dst/'preflight/execution_jobs')
    for src in (SUP,ROOT/DRIVER,STAGE/'code/24_construct_calendar_b.R'):
        shutil.copy2(src,dst/'code'/src.name)
    (dst/'code/99_inert_fixture.R').write_text('# INERT PROCESS FIXTURE ONLY\n')
    reg=dst/'preflight/calendar_date_recovery_001';reg.mkdir()
    with (ROOT/'job_registry.csv').open(newline='') as f:rows=list(csv.DictReader(f))
    rows[0]['driver_path']=str(dst/'code'/DRIVER)
    rows[0]['output_root']=str(dst/'calendar/saved_frame_validation_001')
    with (reg/'job_registry.csv').open('x',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
    return dst
class Child:
    code=0;timeout=False
    def __init__(self,command,stdout,stderr,start_new_session):
        assert command[:2]==['/usr/local/bin/Rscript','--vanilla'] and Path(command[2]).is_relative_to(SUITE)
        assert start_new_session;calls.append(command);stdout.write(b'INERT PROCESS FIXTURE ONLY\n');self.pid=999997;self.waits=0
    def wait(self,timeout=None):
        self.waits+=1
        if type(self).timeout and self.waits==1:raise subprocess.TimeoutExpired('MOCK',timeout)
        return type(self).code
    def poll(self):return type(self).code
def invoke(dst,job=REC,driver=None,args=(),limit='120'):
    driver=driver or (DRIVER if job==REC else '99_inert_fixture.R')
    sup=dst/'code/run_bounded_job_v9.py';out=io.StringIO();error=None
    with patch.object(sys,'argv',[str(sup),job,limit,str(dst/'code'/driver),*args]),patch.dict(os.environ,ENV),patch('subprocess.Popen',Child),patch('time.monotonic',side_effect=[100.,101.]),patch('os.killpg',side_effect=lambda p,s:signals.append((p,s))),contextlib.redirect_stdout(out):
        try:runpy.run_path(str(sup),run_name='__main__')
        except SystemExit as ex:
            if ex.code:error=ex
        except Exception as ex:error=ex
    (dst/(job+'.log')).write_text(out.getvalue()+'\n'+repr(error)+'\n');return error
def record(dst,job=REC):return json.loads((dst/'preflight/execution_jobs'/job/'finish.json').read_text())
def warm(name):
    p=scenario(name);err=invoke(p);assert err is None,repr(err);return p
check('v9_parse',bool(ast.parse(SUP.read_text())))
check('exact_v8_reverse',(ROOT/'supervisor_v8_reconstructed.py').read_bytes()==(STAGE/'code/run_bounded_job_v8.py').read_bytes())
p=warm('positive')
check('one_exact_saved_validation',record(p)['exit_code']==0 and record(p)['child_reaped'])
check('77_histories_and_every_audit_once',abs(record(p)['budget_used_before_seconds']-expected)<1e-9 and record(p)['independent_audit_seconds_charged_once']==debit)
check('lock_cleaned',not (p/'preflight/computation.lock').exists())
check('calendar_fit_continuation',invoke(p,'CALENDAR-CHUNKS') is None)
check('new_elapsed_is_added_once',abs(record(p,'CALENDAR-CHUNKS')['budget_used_before_seconds']-expected-1)<1e-9)
check('temporal_continuation',invoke(p,'TEMPORAL-ANY-ENDPOINT-R3',limit='180') is None)
check('unchanged_temporal_cap_and_draws',record(p,'TEMPORAL-ANY-ENDPOINT-R3')['effective_wall_limit_seconds']==180 and record(p)['maximum_attempted_diagnostic_draws']==1750 and record(p)['maximum_logical_final_diagnostic_draws']==1500)
check('no_validation_rerun',isinstance(invoke(p),AssertionError))
p=scenario('before');check('calendar_held_before_validation',isinstance(invoke(p,'CALENDAR-CHUNKS'),AssertionError))
check('wrong_driver',isinstance(invoke(p,driver='99_inert_fixture.R'),AssertionError))
check('extra_argument',isinstance(invoke(p,args=('EXTRA',)),AssertionError))
for job in ('CONSTRUCT-CALENDAR-B','CONSTRUCT-CALENDAR-RETRY','VERIFY-SENSITIVITY-CALENDAR-DATE-RECOVERY-002','PRIMARY-ANY-RETRY','CHEST-ANY','R2-PRIMARY','SHAPLEY-PRIMARY','ARBITRARY'):
    p=scenario('bad_'+job);n=len(calls)
    check(job+'_blocked',isinstance(invoke(p,job),AssertionError) and len(calls)==n)
p=warm('alias')
check('validator_alias_blocked',isinstance(invoke(p,'COMPARE-SENSITIVITY-CALENDAR',driver=DRIVER),AssertionError))
check('consumed_constructor_blocked',isinstance(invoke(p,'COMPARE-SENSITIVITY-OLD',driver='24_construct_calendar_b.R'),AssertionError))
p=scenario('changed');f=p/'code'/DRIVER;f.write_bytes(f.read_bytes()+b'\n')
check('changed_validator_blocked',isinstance(invoke(p),AssertionError))
for job in ('CONSTRUCT-CALENDAR-B','CHEST-ANY','DERIVE-PRIMARY-ESTIMANDS'):
    for name in ('start.json','finish.json','execution.log'):
        p=scenario('tamper_'+job+'_'+name);f=p/'preflight/execution_jobs'/job/name;f.write_bytes(f.read_bytes()+b'\n');n=len(calls)
        check('historical_'+job+'_'+name,isinstance(invoke(p),AssertionError) and len(calls)==n)
p=scenario('lock');(p/'preflight/computation.lock').write_text('INERT FIXTURE')
check('exclusive_lock',isinstance(invoke(p),FileExistsError))
p=scenario('existing_output');(p/'calendar/saved_frame_validation_001').mkdir(parents=True)
check('existing_output_blocked',isinstance(invoke(p),AssertionError))
p=scenario('failure');Child.code=1
check('new_failure_sealed',isinstance(invoke(p),SystemExit));Child.code=0
check('failure_blocks_continuation',isinstance(invoke(p,'CALENDAR-CHUNKS'),AssertionError))
p=scenario('timeout');Child.timeout=True
check('timeout_sealed',isinstance(invoke(p),SystemExit));Child.timeout=False
check('only_inert_child_signalled',record(p)['timed_out'] and record(p)['child_reaped'] and signals[-1][0]==999997)
check('timeout_blocks_continuation',isinstance(invoke(p,'CALENDAR-CHUNKS'),AssertionError))
p=scenario('cap');check('ordinary121_blocked',isinstance(invoke(p,limit='121'),AssertionError))
for name,extra,ok in (('exhausted',1200.,False),('remaining',1200.-expected-1.5,True)):
    p=scenario(name);q=p/'preflight/execution_jobs/COMPARE-SENSITIVITY-INERT';q.mkdir()
    (q/'finish.json').write_text(json.dumps({'elapsed_seconds':extra,'exit_code':0,'timed_out':False,'child_reaped':True}))
    err=invoke(p)
    check(name+'_ceiling',(err is None) if ok else isinstance(err,AssertionError))
    if ok:check('remaining_budget_clamped',abs(record(p)['effective_wall_limit_seconds']-1.5)<1e-9)
with (ROOT/'supervisor_checks.csv').open('x',newline='') as f:
    w=csv.DictWriter(f,fieldnames=['check','pass']);w.writeheader();w.writerows(checks)
(ROOT/'supervisor_summary.json').write_text(json.dumps({'checks':len(checks),'pass':all(r['pass'] for r in checks),
 'starting_debit':expected,'fixed_audit_seconds':debit,'real_R_children':0,'real_signals':0},indent=2)+'\n')
print('SUPERVISOR_V9=PASS',len(checks),'checks',expected,'seconds starting debit')
