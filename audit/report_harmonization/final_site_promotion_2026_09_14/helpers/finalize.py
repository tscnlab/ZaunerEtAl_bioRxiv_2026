"""Noncircular exact receipt; does not touch any public or accepted011 file."""
from common import *
assert not (OUT/'completion_manifest.csv').exists() and not (OUT/'completion_seal.json').exists()
proof=json.loads((E/'production_safe_point.json').read_text());assert proof['safe_point']
assert (OUT/'promotion_return.md').is_file()
assert inv(LIVE)==parsed_inv(OLD/'evidence/candidate_inventory.csv')
assert sha(CORPUS)=='b5b4b009db76e6f869f324a360e6eeafdf63438539382f1b8d85058f277eb93f'
plan=json.loads((OUT/'transaction_plan.json').read_text())
csvout(E/'changed_paths26.csv',[dict(sequence=r['sequence'],target=r['target'],action=r['action'],bytes=r['bytes'],pre_sha256=r['pre_sha256'],post_sha256=sha(ROOT/r['target']),backup=r['backup'],staged=r['staged']) for r in plan['entries']])
members=inv(OUT);csvout(OUT/'completion_manifest.csv',members)
manifest=OUT/'completion_manifest.csv';seal=dict(utc=utc(),order='013',status='EXACT_STATIC_LOCAL_PROMOTION_COMPLETE',members=len(members),manifest=dict(path=label(manifest),bytes=manifest.stat().st_size,sha256=sha(manifest)),exclusions=['completion_manifest.csv','completion_seal.json'],live_files=914,changed_website_files=25,operations=26,corpus_last=True,corpus_sha256=sha(CORPUS),production_safe_point_sha256=sha(E/'production_safe_point.json'),rollback_available=True,accepted011_unchanged=True,Writer012_not_incorporated=True)
dump(OUT/'completion_seal.json',seal)
for r in members:assert exact(OUT/r['path'],r['sha256'],r['bytes'])
assert {r['path'] for r in inv(OUT)}=={r['path'] for r in members}|{'completion_manifest.csv','completion_seal.json'}
print(json.dumps(seal,indent=2));print('Completion seal SHA256:',sha(OUT/'completion_seal.json'))
