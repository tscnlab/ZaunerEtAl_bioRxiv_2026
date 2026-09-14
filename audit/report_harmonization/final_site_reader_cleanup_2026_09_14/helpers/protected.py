"""Flatten accepted historical identities without modifying or executing old checks."""
from common import *
import sys

def closure(phase,tag):
    assert phase in ('pre','post','rollback') and tag.replace('_','').isalnum()
    cache={}; checks=[]; transitions={r['target']:r for r in plan()} if (E/'transaction_plan.json').exists() else {}
    def check(key,h,n,category):
        p=Path(key); p=p if p.is_absolute() else ROOT/p
        logical=str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else str(p)
        expected=h; retired=False; transition=False
        if phase=='post' and logical in transitions:
            row=transitions[logical]
            assert h==row['pre_sha256'],('unrecognized historical prehash',logical,h)
            assert exact(OUT/row['backup'],h,row['pre_bytes'])
            transition=True; retired=row['action']=='retire'; expected=row['post_sha256']
        if p not in cache:
            checked(p); cache[p]=(sha(p),p.stat().st_size) if p.is_file() else ('',0)
        actual,size=cache[p]
        ok=(not p.exists()) if retired else (actual==expected and (transition or n is None or size==int(n)))
        checks.append(dict(category=category,path=logical,baseline_sha256=h,expected_sha256=expected,actual_sha256=actual,bytes=size,authorized_transition=transition,retired=retired,exact=ok))
        assert ok,(category,logical,'Unexpected protected change')
    assert exact(O16/'completion_manifest.csv','160d3c47ca07419ba26fb57900637efa7a93f5c3ed48dcede44d6a2d4cab43eb',174930)
    assert exact(O16/'completion_seal.json','f7eb885667564d84107fea24c8f222a6f12e6444cf528943a4226d68ac7883bd')
    oldchecks=readcsv(O16/'evidence/final_post_checks.csv'); assert len(oldchecks)==7763
    for r in oldchecks:
        assert r['exact']=='True' and r['actual_sha256']==r['expected_sha256']
        check(r['path'],r['actual_sha256'],None,'accepted016:'+r['category'])
    oldmembers=readcsv(O16/'completion_manifest.csv'); assert len(oldmembers)==1120
    for r in oldmembers: check(str(O16/r['path']),r['sha256'],r['bytes'],'sealed016_package')
    assert {r['path'] for r in inventory(O16)}=={r['path'] for r in oldmembers}|{'completion_manifest.csv','completion_seal.json'}
    dispatch=CONTROL/'site_reader_scope_cleanup_order_017_dispatch_manifest.csv'
    assert exact(dispatch,'91ad40268f324bb60c1838a0417d06fc4a4069ae8b698d2cc4ac9347904e5167',34522)
    members=readcsv(dispatch); assert len(members)==len({r['path'] for r in members})==180
    for r in members: check(r['path'],r['sha256'],r['bytes'],'dispatch017')
    for p,h in [(CONTROL/'site_reader_scope_cleanup_order_017.md','54ba32fa7e3ea4798378633e4b0857f5d241a2fbceefa2ab7939bc2f0f79f28e'),(CONTROL/'site017_readonly_independent_acceptance.md','569f8c538832d7ec49d76c2d08096b0e0f4ae7f0b4bc83b0b601568f61585b00')]: check(str(p),h,None,'release017_pin')
    classification=CONTROL/'order017_inherited_nonreader_classification_manifest.csv'
    assert exact(classification,'aa7bda0793288cd83c0357dd7ab33e3ebec17c179482e3b48e75c4d28a135f77',1724)
    cm=readcsv(classification);assert len(cm)==len({r['path'] for r in cm})==9
    check(str(classification),'aa7bda0793288cd83c0357dd7ab33e3ebec17c179482e3b48e75c4d28a135f77',1724,'classification_manifest')
    for r in cm:check(r['path'],r['sha256'],r['bytes'],'inherited_exact_classification')
    if (E/'protected_unique_baseline.csv').exists():
        baseline=readcsv(E/'protected_unique_baseline.csv')
        for r in baseline: check(r['path'],r['sha256'],r['bytes'],'own017_initial_snapshot')
    else:
        assert phase=='pre'
        unique={r['path']:dict(path=r['path'],bytes=r['bytes'],sha256=r['actual_sha256']) for r in checks}
        for key in ['_quarto.yml','_quarto-website.yml','_quarto-nathealth.yml','index.qmd','supplementary_information.qmd','notebooks/sensitivity_battery.qmd','renv.lock','scripts/report_harmonization/build_phase4_corpus_manifest.R','tests/report_harmonization/test_navigation_contract.R']:
            p=checked(ROOT/key); assert p.is_file(); unique[key]=dict(path=key,bytes=p.stat().st_size,sha256=sha(p))
        csvout(E/'protected_unique_baseline.csv',list(unique.values()))
    csvout(E/(tag+'_protected_checks.csv'),checks)
    result=dict(utc=utc(),status='PASS',phase=phase,checks=len(checks),unique_paths=len({r['path'] for r in checks}),authorized_transition_rows=sum(r['authorized_transition'] for r in checks),authorized_transition_paths=sorted({r['path'] for r in checks if r['authorized_transition']}))
    dump(E/(tag+'_protected_summary.json'),result);print(json.dumps(result))
if __name__=='__main__': closure(sys.argv[1],sys.argv[2])
