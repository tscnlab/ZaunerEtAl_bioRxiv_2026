"""One exact, preflighted static candidate packaging pass. Never writes live."""
from common import *
from transform import make_postimages
from check_closure import check_closure
import shutil
assert not BUILD.exists() and not (E/'packaging_pass.json').exists()
pre=json.loads((E/'implementation_preflight.json').read_text());assert pre['all_helpers_preflighted']
for r in pre['helpers']:assert exact(ROOT/r['path'],r['sha256'],r['bytes'])
check_closure('pre')
plans,ledger,reversals,search_delta,prospective,corpus_reverse=make_postimages()
assert len(plans)==6
preimages=[]
for p in [ROOT/r['target'] for r in plan_rows()]+[CORPUS]:
    dst=safe(OUT/'preimages'/label(p));assert not dst.exists();shutil.copy2(p,dst);assert sha(dst)==sha(p)
    preimages.append(dict(live_target=label(p),backup=label(dst),bytes=p.stat().st_size,sha256=sha(p)))
assert len(preimages)==7
csvout(E/'seven_backup_manifest.csv',preimages)
dump(E/'raw_operation_ledger.json',ledger);csvout(E/'raw_reversal_checks.csv',reversals);dump(E/'search_delta.json',search_delta)
safe(E/'phase4_corpus_manifest.prospective.csv').write_bytes(prospective);csvout(E/'prospective_corpus_reverse.csv',corpus_reverse)
dump(E/'packaging_pass.json',dict(utc=utc(),pass_number=1,status='started',implementation_sha256=sha(Path(__file__)),live_writes=0,expected_replacements=6))
shutil.copytree(LIVE,BUILD,copy_function=shutil.copy2);assert inv(BUILD)==parsed_inv(PROM/'evidence/post_live_inventory.csv')
for route,payload in plans.items():
    assert (BUILD/route).is_relative_to(BUILD) and (BUILD/route).is_file()
    safe(BUILD/route).write_bytes(payload)
inventory=inv(BUILD);assert len(inventory)==914
expected={r['path']:dict(r) for r in parsed_inv(PROM/'evidence/post_live_inventory.csv')}
promotion=[]
for r in plan_rows():
    route=str(Path(r['target']).relative_to('_build/nathealth'));expected[route]=dict(path=route,bytes=r['bytes'],sha256=r['post_sha256'])
    promotion.append(dict(target=r['target'],candidate=label(BUILD/route),bytes=r['bytes'],preimage_sha256=r['pre_sha256'],candidate_sha256=r['post_sha256'],action='replace'))
assert inventory==[expected[k] for k in sorted(expected)]
csvout(E/'candidate_inventory.csv',inventory);csvout(E/'website_promotion_manifest.csv',promotion)
dump(E/'packaging_pass.json',dict(utc=utc(),pass_number=1,status='complete',implementation_sha256=sha(Path(__file__)),live_writes=0,replacements=6,additions=0,removals=0,candidate_files=914,rollback_preimages=7,corpus_prospective_sha256=hashlib.sha256(prospective).hexdigest(),raw_reversals_exact=True))
print('PASS: one exact candidate pass, six replacements,914 files, seven preimages, corpus live unchanged.')
