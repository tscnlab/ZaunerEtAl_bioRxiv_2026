"""Rehash all fixed release pins, allowing only the exact authorized live delta."""
from common import *
import sys

def check_closure(phase):
    assert phase in ('pre','post','rollback')
    results=[];targets={r['target']:r for r in plan_rows()}
    def verify(p,digest,size,category,allow_live=True):
        p=Path(p);p=p if p.is_absolute() else ROOT/p
        if phase=='post' and allow_live and label(p) in targets:
            r=targets[label(p)];digest=r['post_sha256'];size=r['bytes']
        ok=exact(p,digest,size)
        results.append(dict(category=category,path=label(p),expected_sha256=digest,actual_sha256=sha(p) if p.is_file() else '',exact=ok))
        return ok
    fixed=[('final_site_promotion_order_013.md','6c5003debe69f12deb854a28fee72f12f656fe90dec9a546ebc9d5f7e59d0741',7312),('final_site_promotion_order_013_dispatch_manifest.csv','53f4b75477bf939c1239135db9b6ed6c930e3239df5ad88449c82828dc0b2d69',17121),('site011_candidate_independent_acceptance.md','02b67a21fecb875fd2727ad1a34840676613e1f21881553b18c61e11cd1efb5b',None),('site011_candidate_independent_acceptance_manifest.csv','262bd42ee46da79a662f044b6e4fa9e4787b289ba0fe1d7a4c413bd87a80bb00',None)]
    for name,h,size in fixed:verify(CONTROL/name,h,size,'release_identity',False)
    for name,count in [('final_site_promotion_order_013_dispatch_manifest.csv',100),('site011_candidate_independent_acceptance_manifest.csv',47)]:
        members=rows(CONTROL/name);assert len(members)==count
        for r in members:verify(r['path'],r['sha256'],r['bytes'],name)
    owner=rows(OLD/'completion_manifest.csv');assert len(owner)==1026
    verify(OLD/'completion_manifest.csv','34c5804faa43c9f71bdd2c9be7cc8bc3e03f85b84227a6d94f10f9ed349e1199',None,'owner_seal',False)
    for r in owner:verify(OLD/r['path'],r['sha256'],r['bytes'],'owner1026',False)
    assert {r['path'] for r in inv(OLD)}=={r['path'] for r in owner}|{'completion_manifest.csv','completion_seal.json'}
    pins=rows(OLD/'evidence/input_preflight.csv');assert len(pins)==1771
    for r in pins:verify(r['path'],r['sha256'],r['bytes'],'fixed1771')
    expected=parsed_inv(OLD/'evidence/candidate_inventory.csv')
    actual_candidate=inv(OLD/'candidate_build')
    assert actual_candidate==expected and len(expected)==914
    live=inv(LIVE)
    expected_live=expected if phase=='post' else parsed_inv(OLD/'evidence/baseline_inventory.csv')
    results.append(dict(category='complete_live_inventory',path=label(LIVE),expected_sha256='',actual_sha256='',exact=live==expected_live))
    for r in expected_live:verify(LIVE/r['path'],r['sha256'],r['bytes'],'live_closure',False)
    for r in rows(OLD/'evidence/five_backup_manifest.csv'):verify(r['backup'],r['sha256'],r['bytes'],'backup5',False)
    for r in plan_rows():
        p=ROOT/r['target']
        if r['action']=='add' and phase!='post':
            results.append(dict(category='addition_absent21',path=r['target'],expected_sha256='',actual_sha256='',exact=not p.exists()))
    csvout(E/f'{phase}_fixed_closure_checks.csv',results)
    csvout(E/f'{phase}_live_inventory.csv',live)
    summary=dict(utc=utc(),phase=phase,checks=len(results),all_exact=all(r['exact'] for r in results),live_files=len(live),candidate_files=914,owner_members=1026,fixed_pin_rows=1771,writer012_candidate_pinned=False,corpus_sha256=sha(CORPUS))
    dump(E/f'{phase}_closure_summary.json',summary)
    assert summary['all_exact'],'Unexplained fixed input or live state drift.'
    print(json.dumps(summary,indent=2));return summary
if __name__=='__main__':check_closure(sys.argv[1])
