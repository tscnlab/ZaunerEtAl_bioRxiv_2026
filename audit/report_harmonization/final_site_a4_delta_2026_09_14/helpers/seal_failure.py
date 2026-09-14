"""Seal preserved failed attempt only. Does not assert candidate acceptance."""
from common import *
assert not (OUT/'failure_manifest.csv').exists()
assert not (OUT/'completion_manifest.csv').exists()
diagnosis=json.loads((E/'failure_diagnosis.json').read_text())
assert diagnosis['status']=='STOPPED_IMPLEMENTATION_ORDER_COMPARISON_DEFECT'
assert inv(BUILD)==parsed_inv(E/'failure_candidate_inventory.csv')
assert inv(LIVE)==parsed_inv(E/'failure_live_inventory.csv')
assert (OUT/'candidate_stop_return.md').is_file()
assert not (E/'server_lifecycle.json').exists()
members=inv(OUT)
csvout(OUT/'failure_manifest.csv',members)
seal=dict(utc=utc(),order='015',status='STOPPED_IMPLEMENTATION_DEFECT_PENDING_COORDINATOR_DECISION',finding='ORDER015-BUILD-001',members=len(members),manifest=dict(path=label(OUT/'failure_manifest.csv'),bytes=(OUT/'failure_manifest.csv').stat().st_size,sha256=sha(OUT/'failure_manifest.csv')),exclusions=['failure_manifest.csv','failure_seal.json'],packaging_passes=1,candidate_files=914,exact_candidate_replacements=6,live_writes=0,live_corpus_sha256=sha(CORPUS),browser_qa_performed=False,completion_or_promotion_authorized=False)
dump(OUT/'failure_seal.json',seal)
for r in members:assert exact(OUT/r['path'],r['sha256'],r['bytes'])
assert {r['path'] for r in inv(OUT)}=={r['path'] for r in members}|{'failure_manifest.csv','failure_seal.json'}
print(json.dumps(seal,indent=2));print('Failure seal SHA256:',sha(OUT/'failure_seal.json'))
