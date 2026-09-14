"""Rehash immutable live914 and all accepted input/donor closures."""
from common import *
import sys
def check_closure(phase):
    assert phase in ('pre','post');checks=[]
    def verify(p,h,size,category):
        p=Path(p);p=p if p.is_absolute() else ROOT/p
        ok=exact(p,h,size);checks.append(dict(category=category,path=label(p),bytes=p.stat().st_size if p.is_file() else 0,expected_sha256=h,actual_sha256=sha(p) if p.is_file() else '',exact=ok));assert ok,(category,p)
    fixed=[('site_delta_candidate_order_015.md','cce078847312cce996020dc3827ad582d29edb3014c45fbb878a41c03e8d6c97',11272),('site_delta_candidate_order_015_dispatch_manifest.csv','7be09bf79eddf30998bd598a3eec41ea312941e8fa93c7ba93ff09fe9240b469',9468),('site_delta_candidate_order_015_target_matrix.csv','20c3c32eb1fea17c0cc96a9731c0f4b208a46c5f293c9707ce4c7299646a9af6',2028),('writer012_014_final_independent_acceptance_manifest.csv','131c6c2afd6bbedc350bb82dc7a2a055d62403eb46b5c3e8038724d7084cf0ae',11243)]
    for n,h,b in fixed:verify(CONTROL/n,h,b,'release_identity')
    groups=[(CONTROL/'site_delta_candidate_order_015_dispatch_manifest.csv',ROOT,58),(CONTROL/'writer012_014_final_independent_acceptance_manifest.csv',ROOT,63),(CONTROL/'writer012_nonbrowser_independent_review_manifest.csv',ROOT,49),(WRITER/'word_candidate_manifest.csv',WRITER,318),(WRITER/'html_visual_qa/qa_completion_manifest.csv',WRITER/'html_visual_qa',75),(PROM/'completion_manifest.csv',PROM,89)]
    for manifest,base,count in groups:
        members=rows(manifest);assert len(members)==len({r['path'] for r in members})==count
        for r in members:verify(base/r['path'],r['sha256'],r['bytes'],manifest.name)
    regular=rows(PROM/'evidence/post_fixed_closure_checks.csv')
    assert len(regular)==3869 and sum(bool(r['expected_sha256']) for r in regular)==3868
    for r in regular:
        if r['expected_sha256']:verify(r['path'],r['expected_sha256'],None,'fixed3868')
        else:assert r['category']=='complete_live_inventory' and r['path']=='_build/nathealth'
    for name,count in [('source_profile_history49.csv',49),('release44.csv',44)]:
        data=rows(CONTROL/'writer014_independent_evidence'/name);assert len(data)==count
        for r in data:verify(r['path'],r['sha256'],r['bytes'],name)
    live=inv(LIVE);assert live==parsed_inv(PROM/'evidence/post_live_inventory.csv') and len(live)==914
    assert inv(OLD/'candidate_build')==parsed_inv(OLD/'evidence/candidate_inventory.csv')
    for package,manifest,extra in [(OLD,OLD/'completion_manifest.csv',{'completion_manifest.csv','completion_seal.json'}),(PROM,PROM/'completion_manifest.csv',{'completion_manifest.csv','completion_seal.json'})]:
        assert {r['path'] for r in inv(package)}=={r['path'] for r in rows(manifest)}|extra
    assert not any(p.is_symlink() for p in WRITER.rglob('*'))
    assert sha(CORPUS)=='b5b4b009db76e6f869f324a360e6eeafdf63438539382f1b8d85058f277eb93f'
    candidate_count=0
    if phase=='post':
        expected={r['path']:dict(r) for r in live}
        for r in plan_rows():
            path=str(Path(r['target']).relative_to('_build/nathealth'));expected[path]=dict(path=path,bytes=r['bytes'],sha256=r['post_sha256'])
        candidate=inv(BUILD);assert len(candidate)==len({r['path'] for r in candidate})==len(expected) and {r['path']:r for r in candidate}==expected
        assert candidate==parsed_inv(E/'candidate_inventory.csv');candidate_count=len(candidate)
        csvout(E/'post_candidate_inventory.csv',candidate)
    csvout(E/f'{phase}_protected_checks.csv',checks);csvout(E/f'{phase}_live_inventory.csv',live)
    result=dict(utc=utc(),phase=phase,all_exact=True,file_hash_checks=len(checks),live_files=914,candidate_files=candidate_count,protected_regular_rows=3868,Writer318_and_QA75_exact=True,owner011_1026_and_013_89_exact=True,live_corpus_sha256=sha(CORPUS),live_writes=0)
    dump(E/f'{phase}_closure_summary.json',result);print(json.dumps(result,indent=2));return result
if __name__=='__main__':check_closure(sys.argv[1])
