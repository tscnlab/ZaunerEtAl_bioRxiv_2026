from pathlib import Path
import sys, importlib, types, json, csv, hashlib, shutil, ast
ROOT=Path.cwd();T=ROOT/'audit/report_harmonization/final_site_a4_delta_2026_09_14'
OUT=Path('/private/tmp/site015-stop-independent.73iqRB/Python')
assert not OUT.exists();OUT.mkdir()
sys.dont_write_bytecode=True
sys.path.insert(0,str(T/'helpers'))
c=importlib.import_module('common')
def rows(p):return list(csv.DictReader(Path(p).open(newline='',encoding='utf-8-sig')))
def key(items):
    assert len(items)==len({r['path'] for r in items})
    return {r['path']:r for r in items}
original=c.inv(T)
assert {r['path'] for r in original}=={r['path'] for r in rows(T/'failure_manifest.csv')}|{'failure_manifest.csv','failure_seal.json'}
assert len(original)==961
for r in rows(T/'failure_manifest.csv'):assert c.exact(T/r['path'],r['sha256'],r['bytes'])
actual=c.inv(c.BUILD);baseline=c.parsed_inv(c.PROM/'evidence/post_live_inventory.csv')
expected=key(baseline)
for r in c.plan_rows():
    name=str(Path(r['target']).relative_to('_build/nathealth'))
    expected[name]=dict(path=name,bytes=r['bytes'],sha256=r['post_sha256'])
assert len(actual)==914 and key(actual)==expected
ordered=[expected[k] for k in sorted(expected)]
displaced=[dict(position=i+1,path_order=a['path'],string_order=b['path']) for i,(a,b) in enumerate(zip(actual,ordered)) if a!=b]
assert len(displaced)==36 and sorted(actual,key=lambda r:r['path'])==ordered

# Only copied evidence and in-memory helper bindings are changed.
for name in ['phase4_corpus_manifest.prospective.csv','raw_operation_ledger.json','search_delta.json',
 'seven_backup_manifest.csv','prospective_corpus_reverse.csv','implementation_preflight.json']:
    shutil.copy2(T/'evidence'/name,OUT/name)
c.E=OUT
def safe(p):
    p=Path(p);assert p.is_relative_to(OUT),p
    p.parent.mkdir(parents=True,exist_ok=True);return p
c.safe=safe
c.csvout(OUT/'candidate_inventory.csv',actual)
promotion=[]
for r in c.plan_rows():
    name=str(Path(r['target']).relative_to('_build/nathealth'))
    promotion.append(dict(target=r['target'],candidate=c.label(c.BUILD/name),bytes=r['bytes'],preimage_sha256=r['pre_sha256'],candidate_sha256=r['post_sha256'],action='replace'))
c.csvout(OUT/'website_promotion_manifest.csv',promotion)
src=(T/'helpers/check_closure.py').read_text()
old="candidate=inv(BUILD);assert candidate==[expected[k] for k in sorted(expected)]"
new="candidate=inv(BUILD);assert len(candidate)==len({r['path'] for r in candidate})==len(expected) and {r['path']:r for r in candidate}==expected"
assert src.count(old)==1
repaired=src.replace(old,new)
assert repaired.replace(new,old)==src
module=types.ModuleType('check_closure_replay');module.__file__=str(T/'helpers/check_closure.py')
exec(compile(repaired,module.__file__,'exec'),module.__dict__)
pre=module.check_closure('pre')
v=importlib.import_module('verify_static')
v.verify('candidate')
post=module.check_closure('post')
assert pre['file_hash_checks']==post['file_hash_checks']==4617
assert c.inv(T)==original and key(c.inv(c.BUILD))==expected and c.inv(c.LIVE)==baseline

# Validate all remaining browser/HTTP/finalizer dependencies without claiming or
# simulating browser observations, a listening server, downloads, or acceptance.
for p in (T/'helpers').glob('*.py'):ast.parse(p.read_text(),filename=str(p))
serve=(T/'helpers/serve_candidate.py').read_text()
http=(T/'helpers/verify_http_downloads.py').read_text()
final=(T/'helpers/finalize.py').read_text()
assert "assert inv(BUILD)==parsed_inv(E/'candidate_inventory.csv')" in serve
assert c.inv(c.BUILD)==c.parsed_inv(OUT/'candidate_inventory.csv')
assert len([r for r in actual if r['path'].startswith('editable_tables/')])+3==22
for r in json.loads((T/'evidence/implementation_preflight.json').read_text())['helpers']:
    assert c.exact(ROOT/r['path'],r['sha256'],r['bytes'])
assert "check_closure('post')" in final
assert not (T/'evidence/server_lifecycle.json').exists()
assert not (T/'completion_manifest.csv').exists()
c.csvout(OUT/'independent_order_difference.csv',displaced)
c.dump(OUT/'summary.json',dict(status='PASS',original_members=959,actual_tree_members=961,candidate_files=914,
 replacements=6,preserved=908,sequence_displacements=36,protected_hashes=4617,
 static=json.loads((OUT/'candidate_static_summary.json').read_text()),
 post_closure_keyed_comparison=True,all_original_helper_bytes_unchanged=True,
 remaining_browser_http_finalizer='Parsed and dependency-audited only. Execution and visual acceptance remain pending.',
 owner_writes=0,candidate_writes=0,live_writes=0,browser_started=False))
print('ORDER015_REMAINING_STATIC_REPLAY=PASS actual914 keyed exact; order-only36; protected4617; no rebuild or owner/live write')
