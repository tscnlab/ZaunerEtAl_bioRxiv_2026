"""Exact once guarded transaction; recoverable retirements; corpus last."""
from common import *
from checks import run,command,PY
import shutil,subprocess,sys

def journal(mode):return E/(mode+'_transaction_journal.jsonl')
def stage_path(p,rollback=False):return p.with_name('.order017-'+('rollback-' if rollback else 'stage-')+p.name)
def preflight(mode):
    assert mode in ('fixture','live');helper_check()
    assert invmap(site_for(mode))==csvmap(E/'baseline_inventory.csv')
    for r in plan():
        assert exact(target(r['target'],mode),r['pre_sha256'],r['pre_bytes']),r['target']
        assert exact(OUT/r['backup'],r['pre_sha256'],r['pre_bytes'])
        if r['action']=='replace':
            assert exact(OUT/r['candidate'],r['post_sha256'],r['post_bytes'])
            assert not stage_path(target(r['target'],mode)).exists()
def process_guard(tag):
    result=subprocess.run(['ps','-axo','pid=,ppid=,command='],text=True,capture_output=True,check=True)
    own={os.getpid(),os.getppid()};matches=[]
    for line in result.stdout.splitlines():
        parts=line.strip().split(None,2)
        if len(parts)<3:continue
        pid,ppid,cmd=parts
        if int(pid) in own:continue
        relevant=any(s in cmd for s in [str(ROOT),'ZaunerEtAl_bioRxiv_2026','final_site_reader_cleanup_2026_09_14'])
        active=any(s in cmd for s in ['quarto render','quarto preview','pandoc ','knitr','semantic_hook','http.server','serve_site.py','transaction.py','build_phase4_corpus_manifest'])
        if relevant and active:matches.append(dict(pid=int(pid),ppid=int(ppid),command=cmd))
    dump(E/(tag+'_process_guard.json'),dict(utc=utc(),status='PASS' if not matches else 'BLOCKED',conflicting_processes=matches,unrelated_readonly_R='Not a blocker'))
    assert not matches,matches
def write_stage(p,payload,h):
    checked(p);assert not p.exists()
    fd=os.open(p,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o644)
    with os.fdopen(fd,'wb') as f:f.write(payload);f.flush();os.fsync(f.fileno())
    assert sha(p)==h
def completed(mode):
    if not journal(mode).exists():return []
    return [r['target'] for r in (json.loads(line) for line in journal(mode).read_text().splitlines()) if r['event']=='installed']
def rollback_preflight(mode):
    operations={r['target']:r for r in plan()}
    for key in completed(mode):
        r=operations[key];p=target(key,mode)
        assert not p.exists() if r['action']=='retire' else exact(p,r['post_sha256'],r['post_bytes']),('rollback concurrency guard',key)
        assert exact(OUT/r['backup'],r['pre_sha256'],r['pre_bytes'])
def rollback(mode,reason):
    helper_check();rollback_preflight(mode)
    operations={r['target']:r for r in plan()};keys=completed(mode)
    for key in reversed(keys):
        r=operations[key];p=target(key,mode)
        if r['action']=='retire':
            archive=OUT/(mode+'_retired')/key
            assert not p.exists() and exact(archive,r['pre_sha256'],r['pre_bytes'])
            jsonl(journal(mode),dict(event='restore_retirement_before',target=key));os.replace(archive,p)
        else:
            assert exact(p,r['post_sha256'],r['post_bytes'])
            st=stage_path(p,True);jsonl(journal(mode),dict(event='rollback_stage_before',target=key,stage=str(st)))
            write_stage(st,(OUT/r['backup']).read_bytes(),r['pre_sha256'])
            assert exact(p,r['post_sha256'],r['post_bytes']);os.replace(st,p)
        assert exact(p,r['pre_sha256'],r['pre_bytes']);jsonl(journal(mode),dict(event='restored',target=key))
    for r in plan():
        st=stage_path(target(r['target'],mode))
        if st.exists():
            assert r['action']=='replace' and exact(st,r['post_sha256'],r['post_bytes']);st.unlink();jsonl(journal(mode),dict(event='remove_exact_uninstalled_stage',target=r['target']))
    assert invmap(site_for(mode))==csvmap(E/'baseline_inventory.csv')
    for r in plan():assert exact(target(r['target'],mode),r['pre_sha256'],r['pre_bytes'])
    dump(E/(mode+'_rollback.json'),dict(status='PASS',utc=utc(),reason=reason,restored_operations=len(keys),files=914,profile_restored=True,corpus_restored=True))
def install(mode):
    preflight(mode);assert not journal(mode).exists(),'Only one transaction per mode'
    if mode=='live':
        for name in ['candidate_checks.json','fixture_suite.json','candidate_browser_acceptance.json']:
            assert json.loads((E/name).read_text())['status']=='PASS',name
        command([PY,'-B',str(OUT/'helpers/protected.py'),'pre','before_production'],'before_production_protected_run')
        process_guard('before_production')
        freeze=dict(utc=utc(),plan_sha256=sha(E/'transaction_plan.json'),helper_manifest_sha256=sha(E/'helper_manifest.csv'),candidate_inventory_sha256=sha(E/'candidate_inventory.csv'),preimage_manifest_sha256=sha(E/'preimage_manifest.csv'),authorized_exact_once=True)
        dump(E/'promotion_freeze.json',freeze)
    jsonl(journal(mode),dict(event='begin',mode=mode,operations=62,corpus_last=True))
    try:
        for r in plan():
            if r['action']!='replace':continue
            p=target(r['target'],mode);st=stage_path(p)
            jsonl(journal(mode),dict(event='stage_before',target=r['target'],stage=str(st),sha256=r['post_sha256']))
            write_stage(st,(OUT/r['candidate']).read_bytes(),r['post_sha256'])
            jsonl(journal(mode),dict(event='staged',target=r['target'],stage=str(st)))
        assert len([r for r in plan() if stage_path(target(r['target'],mode)).is_file()])==47
        for r in plan():
            key=r['target'];p=target(key,mode);assert exact(p,r['pre_sha256'],r['pre_bytes']),('prewrite guard',key)
            jsonl(journal(mode),dict(event='install_before',target=key,action=r['action'],sequence=r['sequence']))
            if r['action']=='replace':
                st=stage_path(p);assert exact(st,r['post_sha256'],r['post_bytes'])
                assert exact(p,r['pre_sha256'],r['pre_bytes']);os.replace(st,p)
                assert exact(p,r['post_sha256'],r['post_bytes'])
            else:
                archive=owned(OUT/(mode+'_retired')/key);assert not archive.exists()
                assert exact(p,r['pre_sha256'],r['pre_bytes']);os.replace(p,archive)
                assert not p.exists() and exact(archive,r['pre_sha256'],r['pre_bytes'])
            jsonl(journal(mode),dict(event='installed',target=key,action=r['action'],sequence=r['sequence']))
        assert completed(mode)==[r['target'] for r in plan()]
        run(mode,mode)
        if mode=='live': command([PY,'-B',str(OUT/'helpers/protected.py'),'post','post_production'],'post_production_protected_run')
        jsonl(journal(mode),dict(event='postflight_pass',mode=mode))
    except Exception as exc:
        jsonl(journal(mode),dict(event='failure',error=repr(exc)))
        rollback(mode,'Automatic exact rollback after transaction/postflight failure');raise
    print('PASS',mode,'single62-operation transaction and complete postflight')
def fixture():
    helper_check();folder=OUT/'fixture';assert not folder.exists()
    shutil.copytree(LIVE,folder/'_build/nathealth')
    for key in [PROFILE,CORPUS]:shutil.copy2(ROOT/key,owned(folder/key))
    # Deliberate isolated conflicting preimage must reject before a single write.
    first=plan()[0];p=target(first['target'],'fixture');original=p.read_bytes();injected=original+b'\n<!-- Order017 isolated concurrency fixture -->\n'
    p.write_bytes(injected);before=invmap(site_for('fixture'))
    try:preflight('fixture')
    except AssertionError:pass
    else:raise AssertionError('Guard failed to reject changed fixture preimage')
    assert invmap(site_for('fixture'))==before and not journal('fixture').exists()
    owned(E/'fixture_injected_preimage.html').write_bytes(injected)
    assert hashbytes(p.read_bytes())==hashbytes(injected);p.write_bytes(original)
    install('fixture')
    # Rollback must refuse to overwrite any concurrent postimage change.
    post=p.read_bytes();injected_post=post+b'\n<!-- Order017 isolated rollback guard -->\n';p.write_bytes(injected_post)
    before=invmap(site_for('fixture'));journal_sha=sha(journal('fixture'))
    try:rollback_preflight('fixture')
    except AssertionError:pass
    else:raise AssertionError('Rollback guard failed to reject conflicting postimage')
    assert invmap(site_for('fixture'))==before and sha(journal('fixture'))==journal_sha
    owned(E/'fixture_injected_postimage.html').write_bytes(injected_post)
    assert hashbytes(p.read_bytes())==hashbytes(injected_post);p.write_bytes(post)
    rollback('fixture','Successful full forward/postflight/concurrency-guard/reverse fixture')
    dump(E/'fixture_suite.json',dict(status='PASS',utc=utc(),forward_operations=62,all_static_R_postflight=True,preimage_guard_rejected_without_write=True,postimage_rollback_guard_rejected_without_write=True,exact_full_reverse=True,original_files_restored=914,profile_and_corpus_restored=True,helper_manifest_sha256=sha(E/'helper_manifest.csv')))
    print('PASS full fixture forward, retirement, static/R postflight, two concurrency rejection guards and exact rollback')
if __name__=='__main__':
    if sys.argv[1]=='fixture':fixture()
    elif sys.argv[1]=='promote':install('live')
    elif sys.argv[1]=='rollback':rollback('live','New postflight/browser defect; stop after recovery')
    else:raise AssertionError('Unknown command')
