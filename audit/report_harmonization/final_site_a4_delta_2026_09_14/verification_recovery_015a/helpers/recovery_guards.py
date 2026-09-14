"""Recovery release, old961 preservation, and original/new helper identity gates."""
from common import *

def original_and_release(phase):
    checks=[]
    def verify(p,h,b,group):
        ok=exact(p,h,b);assert ok,(group,p)
        checks.append(dict(group=group,path=label(p),bytes=int(b),sha256=h,exact=ok))
    pins=[('site_verifier_recovery_order_015a.md','d81a8759b88844452b94c738e14ccc5ff717d9097d7478a6ce32df6d93b014cd',9497),('site_verifier_recovery_order_015a_dispatch_manifest.csv','86c4405033bd577aa82527ce536cf555aa9a27d3153a0cea8152b64fea91d80b',8253),('site015_stopped_independent_acceptance.md','c514fefa7a9d44c396e37bd0301208e687d70fc949c31c77c9f33ac8c3ee0493',4359),('site015_stopped_independent_acceptance_manifest.csv','1eb587228a7853b842087298445c68b8c5669058bc9d915e9630fd25427188a5',11747)]
    for n,h,b in pins:verify(CONTROL/n,h,b,'release_pin')
    for name,count in [('site_verifier_recovery_order_015a_dispatch_manifest.csv',49),('site015_stopped_independent_acceptance_manifest.csv',64)]:
        data=rows(CONTROL/name);assert len(data)==len({r['path'] for r in data})==count
        for r in data:verify(ROOT/r['path'],r['sha256'],r['bytes'],name)
    verify(T/'failure_manifest.csv','02a4f39eae1a29971598f3f84f03b6c854a5f6dc53774bd282e6f4e56f54161d',147127,'original_seal')
    verify(T/'failure_seal.json','ff359836235d441f79e7add87471b6f092211154a7b95ab1642d53a4f8054c3f',765,'original_seal')
    original=rows(T/'failure_manifest.csv');assert len(original)==len({r['path'] for r in original})==959
    for r in original:verify(T/r['path'],r['sha256'],r['bytes'],'original959')
    allowed={r['path'] for r in original}|{'failure_manifest.csv','failure_seal.json'}
    current=inv(T);old=[r for r in current if not r['path'].startswith('verification_recovery_015a/')]
    assert len(old)==961 and {r['path'] for r in old}==allowed
    assert all(r['path'] in allowed or r['path'].startswith('verification_recovery_015a/') for r in current)
    helpers=json.loads((T/'evidence/implementation_preflight.json').read_text())['helpers'];assert len(helpers)==11
    for r in helpers:verify(ROOT/r['path'],r['sha256'],r['bytes'],'original_eleven_helpers')
    baseline=parsed_inv(PROM/'evidence/post_live_inventory.csv');assert inv(LIVE)==baseline
    expected={r['path']:dict(r) for r in baseline}
    for r in plan_rows():
        path=str(Path(r['target']).relative_to('_build/nathealth'))
        expected[path]=dict(path=path,bytes=r['bytes'],sha256=r['post_sha256'])
    candidate=inv(BUILD)
    assert len(candidate)==len({r['path'] for r in candidate})==len(expected)==914 and {r['path']:r for r in candidate}==expected
    assert candidate==parsed_inv(T/'evidence/failure_candidate_inventory.csv')
    assert json.loads((T/'evidence/packaging_pass.json').read_text())['status']=='started'
    backups=rows(T/'evidence/seven_backup_manifest.csv');assert len(backups)==7
    for r in backups:
        verify(ROOT/r['backup'],r['sha256'],r['bytes'],'seven_preimages')
        assert exact(ROOT/r['live_target'],r['sha256'],r['bytes'])
    csvout(E/f'{phase}_recovery_guard_checks.csv',checks)
    dump(E/f'{phase}_recovery_guard_summary.json',dict(utc=utc(),all_exact=True,checks=len(checks),original_files=961,original_helpers=13,original_checkpoint_helpers=11,candidate_files=914,added_paths_only_in_recovery=True,live_writes=0,candidate_writes=0))

def helper_checkpoint():
    data=rows(E/'recovery_helper_manifest.csv')
    paths={r['path'] for r in data}
    assert len(data)==len(paths)==11
    assert paths=={label(p) for p in (OUT/'helpers').iterdir() if p.is_file()}
    for r in data:assert exact(ROOT/r['path'],r['sha256'],r['bytes'])
    for r in json.loads((T/'evidence/implementation_preflight.json').read_text())['helpers']:assert exact(ROOT/r['path'],r['sha256'],r['bytes'])
