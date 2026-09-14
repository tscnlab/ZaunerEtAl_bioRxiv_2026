"""Single exact promotion, durable journal and guarded bounded rollback."""
from common import *
from check_closure import check_closure
import shutil, sys, uuid

PLAN=OUT/'transaction_plan.json'
JOURNAL=OUT/'transaction_journal.jsonl'
def event(kind,**fields):
    with safe(JOURNAL).open('a',encoding='utf-8') as f:
        f.write(json.dumps(dict(utc=utc(),event=kind,**fields))+'\n');f.flush();os.fsync(f.fileno())
def fsync_dir(p):
    fd=os.open(p,os.O_RDONLY)
    try:os.fsync(fd)
    finally:os.close(fd)
def durable_copy(source,target):
    with Path(source).open('rb') as a,Path(target).open('xb') as b:
        shutil.copyfileobj(a,b);b.flush();os.fsync(b.fileno())
    fsync_dir(Path(target).parent)
def current_kind(p,r):
    if not p.exists():return 'absent'
    if exact(p,r['post_sha256'],r['bytes']):return 'post'
    if r['pre_sha256'] and exact(p,r['pre_sha256']):return 'pre'
    return 'unexpected'
def rollback_decision(kind,action):
    if kind=='post':return 'restore' if action=='replace' else 'quarantine'
    if kind=='pre' and action=='replace':return 'untouched'
    if kind=='absent' and action=='add':return 'untouched'
    raise RuntimeError('Unexpected concurrent target; do not overwrite.')
def selftest():
    fixture=OUT/'selftest';assert not fixture.exists();fixture.mkdir()
    old=fixture/'old';new=fixture/'new';target=fixture/'target';addition=fixture/'addition';moved=fixture/'recovered_addition'
    old.write_bytes(b'order013 old fixture\n');new.write_bytes(b'order013 new fixture\n');shutil.copy2(old,target)
    for p in [target,addition]:
        tmp=fixture/(p.name+'.tmp');durable_copy(new,tmp);os.replace(tmp,p);fsync_dir(fixture)
    assert target.read_bytes()==addition.read_bytes()==new.read_bytes()
    restore=fixture/'restore.tmp';durable_copy(old,restore);os.replace(restore,target);os.replace(addition,moved)
    assert target.read_bytes()==old.read_bytes() and not addition.exists() and moved.read_bytes()==new.read_bytes()
    rejected=0
    for action in ['add','replace']:
        try:rollback_decision('unexpected',action)
        except RuntimeError:rejected+=1
    assert rejected==2
    dump(E/'transaction_selftest.json',dict(utc=utc(),exact_atomic_replace=True,exact_addition_quarantine=True,unexpected_targets_rejected=2,live_writes=0))
def prepare():
    assert not PLAN.exists() and not JOURNAL.exists(),'Single release may be prepared once.'
    check_closure('pre');selftest()
    entries=plan_rows();backups={r['live_target']:r for r in rows(OLD/'evidence/five_backup_manifest.csv')}
    token=uuid.uuid4().hex[:12]
    for r in entries:
        source=ROOT/r['source'];assert exact(source,r['post_sha256'],r['bytes'])
        stage=safe(OUT/'staged'/r['target']);assert not stage.exists();durable_copy(source,stage)
        assert exact(stage,r['post_sha256'],r['bytes']);r['staged']=label(stage)
        r['temporary']=label((ROOT/r['target']).with_name('.order013-'+token+'-'+Path(r['target']).name+'.tmp'))
        assert not (ROOT/r['temporary']).exists()
        if r['action']=='replace':
            b=backups[r['target']];assert b['sha256']==r['pre_sha256']
            source_backup=ROOT/b['backup'];backup=safe(OUT/'preimages'/r['target']);durable_copy(source_backup,backup)
            assert exact(backup,b['sha256'],b['bytes']);r['backup']=label(backup)
        else:r['backup']=''
    assert entries[-1]['target']==label(CORPUS) and entries[-1]['sequence']==26
    plan=dict(order='013',created_utc=utc(),token=token,entries=entries,rollback='Only guarded exact postimages; additions moved into rollback evidence; existing files restored atomically from exact preimages.')
    dump(PLAN,plan)
    with PLAN.open('rb') as f:os.fsync(f.fileno())
    fsync_dir(OUT);event('prepared',plan_sha256=sha(PLAN),operations=26)
    print('PREPARED: 26 exact staged payloads; complete rollback and postflight helpers must be present before commit.')
def read_plan():
    p=json.loads(PLAN.read_text());expected=plan_rows()
    assert len(p['entries'])==len(expected)==26
    for a,b in zip(p['entries'],expected):
        assert all(a[k]==v for k,v in b.items())
        assert exact(ROOT/a['staged'],a['post_sha256'],a['bytes'])
    events=[json.loads(x) for x in JOURNAL.read_text().splitlines()]
    assert events[0]['event']=='prepared' and events[0]['plan_sha256']==sha(PLAN)
    return p,events
def rollback():
    p,events=read_plan()
    intents={x['target'] for x in events if x['event']=='replace_intent'}
    actions=[]
    for r in reversed(p['entries']):
        if r['target'] not in intents:continue
        target=ROOT/r['target'];decision=rollback_decision(current_kind(target,r),r['action'])
        if decision=='restore':assert exact(ROOT/r['backup'],r['pre_sha256'])
        actions.append((r,decision))
    event('rollback_preflight',operations=len(actions))
    for r,decision in actions:
        target=ROOT/r['target']
        assert rollback_decision(current_kind(target,r),r['action'])==decision
        if decision=='restore':
            temp=Path(r['temporary']);temp=ROOT/temp
            assert not temp.exists();durable_copy(ROOT/r['backup'],temp)
            assert exact(temp,r['pre_sha256']);os.replace(temp,target);fsync_dir(target.parent)
        elif decision=='quarantine':
            dest=safe(OUT/'rollback/removed_additions'/r['target']);assert not dest.exists();os.replace(target,dest);fsync_dir(target.parent)
        event('rollback_action',target=r['target'],action=decision)
    for r in p['entries']:
        temp=ROOT/r['temporary']
        if temp.exists():
            assert exact(temp,r['post_sha256'],r['bytes']) or (r['pre_sha256'] and exact(temp,r['pre_sha256']))
            dest=safe(OUT/'rollback/temporary_files'/temp.name);assert not dest.exists();os.replace(temp,dest)
    check_closure('rollback');event('rollback_complete')
def commit():
    p,events=read_plan();assert not any(e['event']!='prepared' for e in events),'Transaction already started; do not repeat.'
    assert (E/'implementation_preflight.json').is_file()
    evidence=json.loads((E/'implementation_preflight.json').read_text());assert evidence['all_helpers_preflighted']
    for r in evidence['helpers']:assert exact(ROOT/r['path'],r['sha256'],r['bytes'])
    check_closure('pre')
    event('transaction_start',operations=26)
    try:
        for r in p['entries']:
            target=checked_path(ROOT/r['target']);temp=checked_path(ROOT/r['temporary'])
            kind=current_kind(target,r);assert kind==('pre' if r['action']=='replace' else 'absent'),(r['target'],kind)
            if not target.parent.exists():
                assert target.parent==LIVE/'editable_tables'
                event('create_directory',path=label(target.parent));target.parent.mkdir()
            assert not temp.exists();event('temporary_create',target=r['target'],temporary=r['temporary'])
            durable_copy(ROOT/r['staged'],temp);assert exact(temp,r['post_sha256'],r['bytes'])
            assert current_kind(target,r)==kind
            event('replace_intent',sequence=r['sequence'],target=r['target'],temporary=r['temporary'],post_sha256=r['post_sha256'])
            os.replace(temp,target);fsync_dir(target.parent)
            assert exact(target,r['post_sha256'],r['bytes'])
            event('replace_complete',sequence=r['sequence'],target=r['target'],sha256=sha(target))
        check_closure('post');event('transaction_complete',operations=26,corpus_last=True)
    except BaseException as exc:
        event('transaction_failure',error=repr(exc))
        try:rollback()
        except BaseException as recovery:event('rollback_blocked',error=repr(recovery))
        raise
if __name__=='__main__':
    {'prepare':prepare,'commit':commit,'rollback':rollback}[sys.argv[1]]()
