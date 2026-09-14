"""Seal this complete candidate package without a self-referential manifest."""
import datetime
from common import *

post=json.loads((EVIDENCE/'postflight_summary.json').read_text())
assert post['all_exact'] and post['candidate_files']==914 and post['live_writes']==0
assert all(r['pass']=='TRUE' for r in rows(EVIDENCE/'content_reconciliation_R.csv'))
assert inventory(BUILD)==[dict(path=r['path'],bytes=int(r['bytes']),sha256=r['sha256']) for r in rows(EVIDENCE/'candidate_inventory.csv')]
assert sha(CORPUS)=='01a2fdc1f1d11db45e28834893c79d620aa5321be1f49cff612b34589e068008'
authority=rows(EVIDENCE/'source_artifact_authority.csv')
assert len(authority)==37
gaps=[r for r in authority if r['source_gap_preserved']=='True']
assert len(gaps)==16
assert all(r['fresh_source_render']=='False' for r in authority)
assert (OUT/'candidate_return.md').is_file() and (EVIDENCE/'browser_qa_report.md').is_file()
excluded={'completion_manifest.csv','completion_seal.json'}
assert not any((OUT/p).exists() for p in excluded),'Do not replace an existing final seal.'
members=[r for r in inventory(OUT) if r['path'] not in excluded]
write_csv(OUT/'completion_manifest.csv',members)
seal=dict(time_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    status='CANDIDATE_COMPLETE_FOR_INDEPENDENT_ACCEPTANCE',
    manifest='completion_manifest.csv',members=len(members),
    manifest_sha256=sha(OUT/'completion_manifest.csv'),
    exclusions=sorted(excluded),noncircular=True,
    candidate_files=914,candidate_inventory_sha256=sha(EVIDENCE/'candidate_inventory.csv'),
    website_promotion_rows=25,website_promotion_manifest_sha256=sha(EVIDENCE/'website_promotion_manifest.csv'),
    corpus_prospective_sha256=sha(EVIDENCE/'phase4_corpus_manifest.prospective.csv'),
    corpus_reverse_sha256=sha(EVIDENCE/'prospective_corpus_reverse.csv'),
    backup_manifest_sha256=sha(EVIDENCE/'five_backup_manifest.csv'),
    authority_sidecar_sha256=sha(EVIDENCE/'source_artifact_authority.csv'),
    historical_source_gaps=len(gaps),
    candidate_return_sha256=sha(OUT/'candidate_return.md'),
    qa_report_sha256=sha(EVIDENCE/'browser_qa_report.md'),
    live_promotion=False,writer_woken=False,scientific_recomputation=False)
write_json(OUT/'completion_seal.json',seal)
for r in members:
    p=OUT/r['path'];assert p.stat().st_size==r['bytes'] and sha(p)==r['sha256'],p
assert len(inventory(OUT))==len(members)+2
print(json.dumps(seal,indent=2))
