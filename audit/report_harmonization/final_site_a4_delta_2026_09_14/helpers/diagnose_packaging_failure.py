"""Read-only candidate/input diagnosis; new evidence only, no recovery or build."""
from common import *
from transform import make_postimages

assert json.loads((E/'packaging_pass.json').read_text())['status']=='started'
assert not (E/'candidate_inventory.csv').exists()
assert not (E/'server_lifecycle.json').exists()
actual=inv(BUILD)
baseline=parsed_inv(PROM/'evidence/post_live_inventory.csv')
expected={r['path']:dict(r) for r in baseline}
target_checks=[]
for r in plan_rows():
    route=str(Path(r['target']).relative_to('_build/nathealth'))
    expected[route]=dict(path=route,bytes=r['bytes'],sha256=r['post_sha256'])
    target_checks.append(dict(path=route,bytes=r['bytes'],sha256=r['post_sha256'],exact=exact(BUILD/route,r['post_sha256'],r['bytes'])))
amap={r['path']:r for r in actual}
assert len(actual)==len(amap)==len(expected)==914 and amap==expected
string_sorted=[expected[k] for k in sorted(expected)]
assert actual!=string_sorted
assert sorted(actual,key=lambda r:r['path'])==string_sorted
order_diff=[dict(position=i+1,actual_path=a['path'],string_sorted_path=b['path']) for i,(a,b) in enumerate(zip(actual,string_sorted)) if a!=b]
changed=[p for p in expected if expected[p]!={r['path']:r for r in baseline}[p]]
assert len(changed)==6 and set(changed)=={r['path'] for r in target_checks}
csvout(E/'failure_candidate_inventory.csv',actual)
csvout(E/'failure_six_postimages.csv',target_checks)
csvout(E/'failure_inventory_order_difference.csv',order_diff)
live=inv(LIVE);assert live==baseline
csvout(E/'failure_live_inventory.csv',live)
protected=[]
for r in rows(E/'pre_protected_checks.csv'):
    p=Path(r['path']);p=p if p.is_absolute() else ROOT/p
    ok=exact(p,r['expected_sha256'],r['bytes'])
    protected.append(dict(category=r['category'],path=r['path'],bytes=p.stat().st_size,expected_sha256=r['expected_sha256'],actual_sha256=sha(p),exact=ok))
assert len(protected)==4617 and all(r['exact'] for r in protected)
csvout(E/'failure_protected_checks.csv',protected)
for package,manifest in [(OLD,OLD/'completion_manifest.csv'),(PROM,PROM/'completion_manifest.csv')]:
    assert {r['path'] for r in inv(package)}=={r['path'] for r in rows(manifest)}|{'completion_manifest.csv','completion_seal.json'}
assert inv(OLD/'candidate_build')==parsed_inv(OLD/'evidence/candidate_inventory.csv')
assert not any(p.is_symlink() for p in WRITER.rglob('*'))
for r in json.loads((E/'implementation_preflight.json').read_text())['helpers']:
    assert exact(ROOT/r['path'],r['sha256'],r['bytes'])
backups=rows(E/'seven_backup_manifest.csv');assert len(backups)==7
assert all(exact(ROOT/r['backup'],r['sha256'],r['bytes']) and exact(ROOT/r['live_target'],r['sha256'],r['bytes']) for r in backups)
plans,ledger,reversals,search_delta,prospective,corpus_reverse=make_postimages()
assert all((BUILD/route).read_bytes()==payload for route,payload in plans.items())
assert ledger==json.loads((E/'raw_operation_ledger.json').read_text())
assert all(r['exact_whole_file_reversal'] for r in reversals)
assert search_delta==json.loads((E/'search_delta.json').read_text())
assert prospective==(E/'phase4_corpus_manifest.prospective.csv').read_bytes()
assert sha(CORPUS)=='b5b4b009db76e6f869f324a360e6eeafdf63438539382f1b8d85058f277eb93f'
result=dict(utc=utc(),status='STOPPED_IMPLEMENTATION_ORDER_COMPARISON_DEFECT',finding='ORDER015-BUILD-001',packaging_passes=1,original_helper_modified=False,live_writes=0,candidate_files=914,exact_replacements=6,retained_files=908,additions=0,removals=0,path_keyed_full_identity_exact=True,sequence_comparison_false=True,ordering_difference_positions=len(order_diff),first_order_difference=order_diff[0],protected_hashes_reproduced=len(protected),seven_preimages_exact=True,raw_replay_and_reversals_exact=True,prospective_corpus_exact=True,live_corpus_unchanged=True,browser_started=False,browser_qa_performed=False,R_content_checks_performed=False,recovery_performed=False)
dump(E/'failure_diagnosis.json',result)
print(json.dumps(result,indent=2))
