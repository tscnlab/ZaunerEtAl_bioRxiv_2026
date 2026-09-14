"""Process-only mocks of the bounded continuation. No real R child or signal."""
import ast
import contextlib
import csv
import io
import json
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import tempfile
from unittest.mock import patch

ROOT = Path('/private/tmp/ba018-completion-audit.ekpsA4/chest_support_recovery.i5UqmA')
STAGE = Path('/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2')
CENTRAL = Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/decisions/brown_main_linkage_b_stage2_chest_support_recovery_001')
SUP = ROOT / 'run_bounded_job_v7.py'
RECOVERY = 'CONSTRUCT-CHEST-B-SUPPORT-RECOVERY-001'
SUITE = Path(tempfile.mkdtemp(prefix='process_mocks_', dir=ROOT))
ENV = {'RENV_CONFIG_AUTOLOADER_ENABLED':'FALSE','OMP_NUM_THREADS':'1','OPENBLAS_NUM_THREADS':'1','MKL_NUM_THREADS':'1','VECLIB_MAXIMUM_THREADS':'1'}
checks, calls, signals = [], [], []
with (CENTRAL/'audit_compute_accounting.csv').open(newline='') as f:
    audit_seconds = sum(float(row['charged_seconds']) for row in csv.DictReader(f))
history_seconds = sum(json.loads(p.read_text())['elapsed_seconds'] for p in (STAGE/'preflight/execution_jobs').glob('*/finish.json'))
expected = audit_seconds + history_seconds
ast.parse(SUP.read_text())
def check(name, value):
    checks.append({'check':name,'pass':bool(value)})
    assert value, name
def scenario(name):
    dst = SUITE/name
    (dst/'code').mkdir(parents=True)
    (dst/'preflight').mkdir()
    shutil.copytree(STAGE/'preflight/execution_jobs',dst/'preflight/execution_jobs')
    for path in (SUP, ROOT/'18_construct_chest_b_v2.R', STAGE/'code/18_construct_chest_b.R'):
        shutil.copy2(path,dst/'code'/path.name)
    (dst/'code/99_inert_mock.R').write_text('# MOCK ONLY\n')
    return dst
class MockChild:
    code, timeout = 0, False
    def __init__(self, command, stdout, stderr, start_new_session):
        assert command[:2] == ['/usr/local/bin/Rscript','--vanilla'] and Path(command[2]).is_relative_to(SUITE)
        assert start_new_session
        calls.append(command);stdout.write(b'MOCK ONLY. No R process.\n')
        self.pid,self.waits = 999997,0
    def wait(self, timeout=None):
        self.waits += 1
        if type(self).timeout and self.waits == 1:
            raise subprocess.TimeoutExpired('MOCK',timeout)
        return type(self).code
    def poll(self): return type(self).code
def invoke(dst, job=RECOVERY, driver=None, args=(), limit='120'):
    driver = driver or ('18_construct_chest_b_v2.R' if job == RECOVERY else '99_inert_mock.R')
    sup=dst/'code/run_bounded_job_v7.py'
    out=io.StringIO(); error=None
    with patch.object(sys,'argv',[str(sup),job,limit,str(dst/'code'/driver),*args]),patch.dict('os.environ',ENV),patch('subprocess.Popen',MockChild),patch('time.monotonic',side_effect=[100.,101.]),patch('os.killpg',side_effect=lambda p,s:signals.append((p,s))),contextlib.redirect_stdout(out):
        try: runpy.run_path(str(sup),run_name='__main__')
        except SystemExit as exc:
            if exc.code: error=exc
        except Exception as exc: error=exc
    (dst/f'{job}.log').write_text(out.getvalue()+'\n'+repr(error)+'\n')
    return error
def rec(dst, job=RECOVERY): return json.loads((dst/'preflight/execution_jobs'/job/'finish.json').read_text())
def warm(name):
    dst=scenario(name);assert invoke(dst) is None;return dst
check('eight_exact_reverse_blocks', (ROOT/'supervisor_v6_reconstructed.py').read_bytes()==(STAGE/'code/run_bounded_job_v6.py').read_bytes())
p=scenario('positive')
check('one_exact_constructor_job',invoke(p) is None)
check('all69_jobs_and_audits_charged_once',abs(rec(p)['budget_used_before_seconds']-expected)<1e-9 and rec(p)['independent_audit_seconds_charged_once']==audit_seconds)
check('constructor_reaped_and_unlocked',rec(p)['child_reaped'] and not (p/'preflight/computation.lock').exists())
check('registered_chest_after_constructor',invoke(p,'CHEST-ANY') is None)
check('no_accounting_reset',abs(rec(p,'CHEST-ANY')['budget_used_before_seconds']-expected-1)<1e-9)
check('registered_calendar_after_constructor',invoke(p,'CALENDAR-CHUNKS') is None)
check('registered_temporal_route',invoke(p,'TEMPORAL-ANY-ENDPOINT-R3',limit='180') is None)
check('temporal_cap180',rec(p,'TEMPORAL-ANY-ENDPOINT-R3')['effective_wall_limit_seconds']==180)
check('draw_limits_unchanged',rec(p)['maximum_attempted_diagnostic_draws']==1750 and rec(p)['maximum_logical_final_diagnostic_draws']==1500)
check('constructor_repeat_blocked',isinstance(invoke(p),AssertionError))
p=scenario('ordering')
check('chest_before_constructor_blocked',isinstance(invoke(p,'CHEST-ANY'),AssertionError))
check('calendar_before_constructor_blocked',isinstance(invoke(p,'CALENDAR-CHUNKS'),AssertionError))
check('wrong_constructor_driver_blocked',isinstance(invoke(p,driver='99_inert_mock.R'),AssertionError))
check('extra_constructor_argument_blocked',isinstance(invoke(p,args=('EXTRA',)),AssertionError))
for bad in ('CONSTRUCT-CHEST-B-SUPPORT-RECOVERY-002','CONSTRUCT-CHEST-B-OTHER','PRIMARY-ANY-RETRY','DERIVE-PRIMARY-ESTIMANDS-V9','R2-PRIMARY','SHAPLEY-PRIMARY','RENDER-REPORT','ARBITRARY'):
    p=warm('bad_'+bad);before=len(calls)
    check(bad+'_blocked',isinstance(invoke(p,bad),AssertionError) and len(calls)==before)
p=warm('old_driver')
check('original_constructor_blocked',isinstance(invoke(p,'COMPARE-SENSITIVITY-OLD',driver='18_construct_chest_b.R'),AssertionError))
check('new_constructor_alias_blocked',isinstance(invoke(p,'COMPARE-SENSITIVITY-ALIAS',driver='18_construct_chest_b_v2.R'),AssertionError))
p=scenario('changed_driver');path=p/'code/18_construct_chest_b_v2.R';path.write_bytes(path.read_bytes()+b'\n')
check('changed_constructor_blocked',isinstance(invoke(p),AssertionError))
for historical in ('DERIVE-PRIMARY-ESTIMANDS','DERIVE-PRIMARY-ESTIMANDS-V2','DIAGNOSTICS-PRIMARY-ANY','DERIVE-SENSITIVITY-SIMPLE-FRAMES','CONSTRUCT-CHEST-B'):
    for name in ('start.json','finish.json','execution.log'):
        p=scenario('tamper_'+historical+'_'+name);path=p/'preflight/execution_jobs'/historical/name
        path.write_bytes(path.read_bytes()+b'\n');before=len(calls)
        check('tamper_'+historical+'_'+name,isinstance(invoke(p),AssertionError) and len(calls)==before)
p=scenario('lock');(p/'preflight/computation.lock').write_text('MOCK')
check('exclusive_lock',isinstance(invoke(p),FileExistsError))
p=scenario('failure');MockChild.code=1
check('new_failure_preserved',isinstance(invoke(p),SystemExit));MockChild.code=0
check('new_failure_blocks_fit',isinstance(invoke(p,'CHEST-ANY'),AssertionError))
p=scenario('timeout');MockChild.timeout=True
check('timeout_preserved',isinstance(invoke(p),SystemExit));MockChild.timeout=False
check('timeout_reaped_only_mock_child_signalled',rec(p)['timed_out'] and rec(p)['child_reaped'] and signals[-1][0]==999997)
check('timeout_blocks_fit',isinstance(invoke(p,'CHEST-ANY'),AssertionError))
p=scenario('cap');check('ordinary121_rejected',isinstance(invoke(p,limit='121'),AssertionError))
p=scenario('exhausted');extra=p/'preflight/execution_jobs/COMPARE-SENSITIVITY-MOCK-USED';extra.mkdir()
(extra/'finish.json').write_text(json.dumps({'elapsed_seconds':1200.,'exit_code':0,'timed_out':False,'child_reaped':True}))
check('original1200_ceiling',isinstance(invoke(p),AssertionError))
p=scenario('remaining');extra=p/'preflight/execution_jobs/COMPARE-SENSITIVITY-MOCK-USED';extra.mkdir()
(extra/'finish.json').write_text(json.dumps({'elapsed_seconds':1200.-expected-1.5,'exit_code':0,'timed_out':False,'child_reaped':True}))
check('remaining_limited',invoke(p) is None)
check('remaining_cap1_5',abs(rec(p)['effective_wall_limit_seconds']-1.5)<1e-9)
with (ROOT/'supervisor_checks.csv').open('x',newline='') as f:
    w=csv.DictWriter(f,fieldnames=['check','pass']);w.writeheader();w.writerows(checks)
(ROOT/'supervisor_mock_summary.json').write_text(json.dumps({'checks':len(checks),'pass':all(x['pass'] for x in checks),'real_children':0,'real_signals':0,'mock_child_calls':len(calls),'history_seconds':history_seconds,'audit_seconds':audit_seconds,'starting_debit':expected},indent=2)+'\n')
print(f'BA018_SUPERVISOR_V7=PASS checks={len(checks)}/{len(checks)} real_children=0 starting_debit={expected}')
