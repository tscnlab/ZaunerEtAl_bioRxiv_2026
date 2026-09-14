"""Exact Order016 closure with path AND prehash classified live transitions."""
from common import *
import sys

def check_closure(phase,tag):
    assert phase in ('pre','post','rollback') and tag.replace('_','').isalnum()
    entries=transaction_rows();targets={r['target']:r for r in entries};checks=[]
    def verify(path,digest,size,category):
        logical=Path(path);logical=logical if logical.is_absolute() else ROOT/logical
        physical=target_path(logical);key=label(logical);post=False;backup=''
        expected=digest;expected_size=size
        if phase=='post' and key in targets and digest==targets[key]['pre_sha256']:
            r=targets[key];assert size is None or int(size)==r['pre_bytes']
            assert exact(ROOT/r['historical_backup'],digest,r['pre_bytes'])
            own=TX/'preimages'/r['target'];assert exact(own,digest,r['pre_bytes'])
            expected=r['post_sha256'];expected_size=r['bytes'];post=True;backup=label(own)
        ok=exact(physical,expected,expected_size)
        checks.append(dict(category=category,path=key,physical_path=label(physical),historical_sha256=digest,expected_sha256=expected,actual_sha256=sha(physical) if physical.is_file() else '',authorized_transition=post,backup=backup,exact=ok))
        assert ok,(category,key,'Unexpected identity, not an authorized exact prehash transition')
    pins=[('site_a4_delta_promotion_order_016.md','93d5f8afd2579fbd93b3fb07bd906b7ca3cf9a9f7c64d96fd3b8fd9d022a0f5c',9699),('site_a4_delta_promotion_order_016_dispatch_manifest.csv','90d5759e5862ae86541a69bb3af129a1bc48d8983a8912afdd8d958fed192546',10136),('site015a_candidate_independent_acceptance.md','8f04a34880a5d8e280a2171e08cad97fa6a11e785e31e16f7a97f108cc38daa9',7336),('site015a_candidate_independent_acceptance_manifest.csv','c20a7026033021acee1fcadcfccab37c99ea867e8913db87e73fbf68534c5ac5',10850)]
    for n,h,b in pins:verify(CONTROL/n,h,b,'release_pin')
    for name,count in [('site_a4_delta_promotion_order_016_dispatch_manifest.csv',58),('site015a_candidate_independent_acceptance_manifest.csv',58),('site_delta_candidate_order_015_dispatch_manifest.csv',58),('site_verifier_recovery_order_015a_dispatch_manifest.csv',49),('site015_stopped_independent_acceptance_manifest.csv',64),('writer012_014_final_independent_acceptance_manifest.csv',63),('writer012_nonbrowser_independent_review_manifest.csv',49)]:
        data=rows(CONTROL/name);assert len(data)==len({r['path'] for r in data})==count
        for r in data:verify(r['path'],r['sha256'],r['bytes'],name)
    protected=rows(REC/'evidence/post_protected_checks.csv');assert len(protected)==4617
    for r in protected:
        assert r['exact']=='True' and r['expected_sha256']==r['actual_sha256']
        verify(r['path'],r['expected_sha256'],r['bytes'],'protected4617')
    packages=[(REC,'pending_manifest.csv',269,{'pending_manifest.csv','pending_seal.json'}),(OLD,'completion_manifest.csv',1026,{'completion_manifest.csv','completion_seal.json'}),(PROM,'completion_manifest.csv',89,{'completion_manifest.csv','completion_seal.json'})]
    for base,manifest,count,extras in packages:
        data=rows(base/manifest);assert len(data)==len({r['path'] for r in data})==count
        for r in data:verify(base/r['path'],r['sha256'],r['bytes'],str(base.name)+'_members')
        assert {r['path'] for r in inv(base)}=={r['path'] for r in data}|extras
    original=rows(T/'failure_manifest.csv');assert len(original)==len({r['path'] for r in original})==959
    for r in original:verify(T/r['path'],r['sha256'],r['bytes'],'original959')
    allowed={r['path'] for r in original}|{'failure_manifest.csv','failure_seal.json'}|{'verification_recovery_015a/'+r['path'] for r in inv(REC)}
    assert {r['path'] for r in inv(T)}==allowed
    for base,manifest,count in [(WRITER,'word_candidate_manifest.csv',318),(WRITER/'html_visual_qa','qa_completion_manifest.csv',75)]:
        data=rows(base/manifest);assert len(data)==len({r['path'] for r in data})==count
        for r in data:verify(base/r['path'],r['sha256'],r['bytes'],'Writer_'+str(count))
    baseline={r['path']:r for r in parsed_inv(REC/'evidence/post_live_inventory.csv')}
    candidate={r['path']:r for r in parsed_inv(REC/'evidence/candidate_inventory.csv')}
    assert len(baseline)==len(candidate)==914
    assert {r['path']:r for r in inv(CANDIDATE)}==candidate
    assert {r['path']:r for r in inv(BASELINE)}==baseline
    changed={k for k in baseline if baseline[k]!=candidate[k]}
    assert set(baseline)==set(candidate) and changed=={str(Path(r['target']).relative_to('_build/nathealth')) for r in entries[:6]}
    site=inv(ACTIVE_SITE);expected=candidate if phase=='post' else baseline
    assert len(site)==914 and {r['path']:r for r in site}==expected
    for r in entries:
        assert exact(ROOT/r['source'],r['post_sha256'],r['bytes'])
        assert exact(ROOT/r['historical_backup'],r['pre_sha256'],r['pre_bytes'])
        verify(r['target'],r['pre_sha256'],r['pre_bytes'],'seven_live_targets')
    assert json.loads((T/'evidence/packaging_pass.json').read_text())['status']=='started'
    csvout(E/f'{tag}_checks.csv',checks);csvout(E/f'{tag}_site_inventory.csv',site)
    result=dict(utc=utc(),phase=phase,tag=tag,fixture=IS_FIXTURE,all_exact=True,checks=len(checks),protected_rows=4617,original_files=961,owner_members=269,live_files=914,candidate_files=914,exact_changed_site_paths=6,unchanged_site_paths=908,authorized_transition_rows=sum(r['authorized_transition'] for r in checks),authorized_transition_paths=sorted({r['path'] for r in checks if r['authorized_transition']}),corpus_sha256=sha(ACTIVE_CORPUS))
    dump(E/f'{tag}_summary.json',result);print(json.dumps(result,indent=2));return result

if __name__=='__main__':check_closure(sys.argv[1],sys.argv[2])
