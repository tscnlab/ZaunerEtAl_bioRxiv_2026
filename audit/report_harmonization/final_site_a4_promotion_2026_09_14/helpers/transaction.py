"""Order013 atomic pattern narrowed to seven guarded Order016 replacements."""
from common import *
from check_closure import check_closure
import shutil,sys,uuid

PLAN=TX/'transaction_plan.json';JOURNAL=TX/'transaction_journal.jsonl'
def event(kind,**fields):
    with safe(JOURNAL).open('a',encoding='utf-8') as f:
        f.write(json.dumps(dict(utc=utc(),event=kind,fixture=IS_FIXTURE,**fields))+'\n');f.flush();os.fsync(f.fileno())
def fsync_dir(p):
    fd=os.open(p,os.O_RDONLY)
    try:os.fsync(fd)
    finally:os.close(fd)
def durable_copy(source,target):
    with Path(source).open('rb') as a,Path(target).open('xb') as b:
        shutil.copyfileobj(a,b);b.flush();os.fsync(b.fileno())
    fsync_dir(Path(target).parent)
def current_kind(p,r):
    if exact(p,r['post_sha256'],r['bytes']):return 'post'
    if exact(p,r['pre_sha256'],r['pre_bytes']):return 'pre'
    return 'unexpected'
def rollback_decision(kind):
    if kind=='post':return 'restore'
    if kind=='pre':return 'untouched'
    raise RuntimeError('Unexpected concurrent target; do not overwrite.')
def prepare():
    assert not PLAN.exists() and not JOURNAL.exists(),'Prepare once only.'
    helper_checkpoint();check_closure('pre','prepare_pre')
    entries=transaction_rows();token=uuid.uuid4().hex[:12]
    for r in entries:
        stage=safe(TX/'staged'/r['target']);assert not stage.exists();durable_copy(ROOT/r['source'],stage)
        backup=safe(TX/'preimages'/r['target']);assert not backup.exists();durable_copy(ROOT/r['historical_backup'],backup)
        assert exact(stage,r['post_sha256'],r['bytes']) and exact(backup,r['pre_sha256'],r['pre_bytes'])
        r.update(staged=label(stage),backup=label(backup),physical_target=label(target_path(r['target'])))
        temp=target_path(r['target']).with_name('.order016-'+token+'-'+Path(r['target']).name+'.tmp')
        assert not temp.exists() and temp.parent==target_path(r['target']).parent
        r['temporary']=label(temp)
    assert entries[-1]['sequence']==7 and entries[-1]['target']==label(CORPUS)
    dump(PLAN,dict(order='016',fixture=IS_FIXTURE,created_utc=utc(),token=token,entries=entries))
    with PLAN.open('rb') as f:os.fsync(f.fileno())
    fsync_dir(TX);event('prepared',plan_sha256=sha(PLAN),operations=7)
    print('PREPARED seven exact payloads and seven exact preimages. No target writes.')
def read_plan():
    p=json.loads(PLAN.read_text());assert p['order']=='016' and p['fixture']==IS_FIXTURE
    expected=transaction_rows();assert len(p['entries'])==len(expected)==7
    for a,b in zip(p['entries'],expected):
        assert all(a[k]==v for k,v in b.items())
        assert ROOT/a['physical_target']==target_path(a['target'])
        assert (ROOT/a['staged']).is_relative_to(TX/'staged') and (ROOT/a['backup']).is_relative_to(TX/'preimages')
        assert exact(ROOT/a['staged'],a['post_sha256'],a['bytes']) and exact(ROOT/a['backup'],a['pre_sha256'],a['pre_bytes'])
        assert (ROOT/a['temporary']).parent==target_path(a['target']).parent
    events=[json.loads(x) for x in JOURNAL.read_text().splitlines()]
    assert events[0]['event']=='prepared' and events[0]['plan_sha256']==sha(PLAN)
    return p,events
def rollback():
    p,events=read_plan();intents={x['target'] for x in events if x['event']=='replace_intent'};actions=[]
    for r in reversed(p['entries']):
        if r['target'] not in intents:continue
        decision=rollback_decision(current_kind(target_path(r['target']),r))
        if decision=='restore':assert exact(ROOT/r['backup'],r['pre_sha256'],r['pre_bytes'])
        actions.append((r,decision))
    event('rollback_preflight',operations=len(actions))
    for r,decision in actions:
        target=target_path(r['target']);assert rollback_decision(current_kind(target,r))==decision
        temp=ROOT/r['temporary']
        if temp.exists():
            assert exact(temp,r['post_sha256'],r['bytes']) or exact(temp,r['pre_sha256'],r['pre_bytes'])
            dest=safe(TX/'rollback/temporary_files'/temp.name);assert not dest.exists();os.replace(temp,dest)
        if decision=='restore':
            event('restore_intent',target=r['target'],temporary=r['temporary'])
            durable_copy(ROOT/r['backup'],temp);assert exact(temp,r['pre_sha256'],r['pre_bytes'])
            assert current_kind(target,r)=='post';os.replace(temp,target);fsync_dir(target.parent)
        event('rollback_action',target=r['target'],action=decision)
    for r in p['entries']:
        temp=ROOT/r['temporary']
        if temp.exists():
            assert exact(temp,r['post_sha256'],r['bytes']) or exact(temp,r['pre_sha256'],r['pre_bytes'])
            dest=safe(TX/'rollback/temporary_files'/temp.name);assert not dest.exists();os.replace(temp,dest)
    check_closure('rollback','rollback_final');event('rollback_complete')
def commit():
    p,events=read_plan();assert [e['event'] for e in events]==['prepared'],'No retry.'
    helper_checkpoint()
    if not IS_FIXTURE:
        proof=json.loads((E/'implementation_preflight.json').read_text())
        assert proof['all_helpers_preflighted'] and proof['fixture_complete'] and proof['plan_sha256']==sha(PLAN)
    check_closure('pre','commit_pre');event('transaction_start',operations=7)
    try:
        for r in p['entries']:
            target=target_path(r['target']);temp=checked_path(ROOT/r['temporary'])
            assert target.parent.is_dir() and current_kind(target,r)=='pre' and not temp.exists()
            event('temporary_create',target=r['target'],temporary=r['temporary'])
            durable_copy(ROOT/r['staged'],temp);assert exact(temp,r['post_sha256'],r['bytes'])
            assert current_kind(target,r)=='pre'
            event('replace_intent',sequence=r['sequence'],target=r['target'],temporary=r['temporary'],post_sha256=r['post_sha256'])
            os.replace(temp,target);fsync_dir(target.parent)
            assert exact(target,r['post_sha256'],r['bytes']);event('replace_complete',sequence=r['sequence'],target=r['target'],sha256=sha(target))
        check_closure('post','commit_post');event('transaction_complete',operations=7,corpus_last=True)
    except BaseException as exc:
        event('transaction_failure',error=repr(exc))
        try:rollback()
        except BaseException as recovery:event('rollback_blocked',error=repr(recovery))
        raise
if __name__=='__main__':{'prepare':prepare,'commit':commit,'rollback':rollback}[sys.argv[1]]()
