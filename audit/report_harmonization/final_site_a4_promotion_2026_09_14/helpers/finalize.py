"""One immutable, non-circular Order016 completion with inherited qualifications."""
from common import *
assert not IS_FIXTURE
assert not (OUT/'completion_manifest.csv').exists() and not (OUT/'completion_seal.json').exists()
helper_checkpoint();assert json.loads((E/'production_safe_point.json').read_text())['safe_point']
assert (OUT/'completion_report.md').is_file()
images=rows(E/'browser_capture_manifest.csv');assert images
for r in images:assert exact(E/r['image_path'],r['sha256'],r['bytes'])
p=json.loads((OUT/'transaction_plan.json').read_text());final=[]
for r in p['entries']:
    target=ROOT/r['target'];backup=ROOT/r['backup'];assert exact(target,r['post_sha256'],r['bytes']) and exact(backup,r['pre_sha256'],r['pre_bytes'])
    final.append(dict(sequence=r['sequence'],target=r['target'],bytes=r['bytes'],sha256=sha(target),preimage_bytes=r['pre_bytes'],preimage_sha256=r['pre_sha256'],backup=r['backup'],rollback_available=True))
assert len(final)==7 and final[-1]['target']==label(CORPUS);csvout(E/'final_seven_identities.csv',final)
bound=lambda q:dict(path=label(q),bytes=q.stat().st_size,sha256=sha(q))
members=inv(OUT);csvout(OUT/'completion_manifest.csv',members)
seal=dict(utc=utc(),order='016',status='LOCAL_INTEGRATION_COMPLETE_ACCEPTED_WITH_INHERITED_QUALIFICATIONS',unqualified_error_free_claim=False,path_base=label(OUT),members=len(members),manifest=bound(OUT/'completion_manifest.csv'),exclusions=['completion_manifest.csv','completion_seal.json'],release=bound(CONTROL/'site_a4_delta_promotion_order_016.md'),dispatch=bound(CONTROL/'site_a4_delta_promotion_order_016_dispatch_manifest.csv'),independent_acceptance=bound(CONTROL/'site015a_candidate_independent_acceptance.md'),historical_owner_pending_seal=bound(REC/'pending_seal.json'),original_failure_seal=bound(T/'failure_seal.json'),live_files=914,candidate_files=914,website_replacements=6,corpus_replacements=1,additions=0,unchanged_website_files=908,transaction_journal=bound(OUT/'transaction_journal.jsonl'),final_seven_identities=bound(E/'final_seven_identities.csv'),final_closure=bound(E/'final_post_summary.json'),browser_teardown_complete=True,browser_qualifications=bound(E/'browser_observations.json'),render_or_scientific_execution=False,source_or_artwork_edits=False,remote_publication=False)
dump(OUT/'completion_seal.json',seal)
for r in members:assert exact(OUT/r['path'],r['sha256'],r['bytes'])
assert {r['path'] for r in inv(OUT)}=={r['path'] for r in members}|{'completion_manifest.csv','completion_seal.json'}
print(json.dumps(seal,indent=2));print('Completion seal SHA256:',sha(OUT/'completion_seal.json'))
