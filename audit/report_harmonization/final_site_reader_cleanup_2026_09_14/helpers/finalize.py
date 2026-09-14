"""One final non-circular combined completion, with inherited qualifications."""
from common import *
from protected import closure
from checks import command,PY

helper_check();assert not (OUT/'completion_manifest.csv').exists() and not (OUT/'completion_seal.json').exists()
for name in ['candidate_checks.json','fixture_suite.json','candidate_browser_acceptance.json','live_checks.json','live_browser_acceptance.json']:
    assert json.loads((E/name).read_text())['status']=='PASS',name
for mode in ['candidate','live']:
    qa=E/(mode+'_qa')
    for name in ['http_summary.json','teardown.json']:assert json.loads((qa/name).read_text())['status']=='PASS'
    assert json.loads((qa/'server_lifecycle.json').read_text())['status']=='stopped'
    assert readcsv(qa/'browser_capture_manifest.csv')
assert invmap(LIVE)==csvmap(E/'candidate_inventory.csv')
assert not (E/'live_rollback.json').exists()
rows=[json.loads(x) for x in (E/'live_transaction_journal.jsonl').read_text().splitlines()]
installed=[r for r in rows if r['event']=='installed'];assert len(installed)==len({r['target'] for r in installed})==62
assert installed[-1]['target']==CORPUS
assert sum(r['action']=='retire' for r in installed)==15
for r in plan():
    assert exact(OUT/r['backup'],r['pre_sha256'],r['pre_bytes'])
    if r['action']=='retire':assert exact(OUT/'live_retired'/r['target'],r['pre_sha256'],r['pre_bytes'])
    assert not target(r['target'],'live').with_name('.order017-stage-'+Path(r['target']).name).exists()
    assert not target(r['target'],'live').with_name('.order017-rollback-'+Path(r['target']).name).exists()
closure('post','final')
summary=dict(status='LOCAL_READER_SCOPE_COMPLETE_WITH_INHERITED_QUALIFICATIONS',utc=utc(),public_files=899,public_replacements=45,retirements=15,unchanged_survivors=854,profile_replacements=1,corpus_replacements=1,corpus_last=True,reader_routes=36,search_records=938,sitemap_entries=38,download_payloads_unchanged=20,SVG_payloads_unchanged=True,
    qualifications=['S2 accepted secondary text remains fixed','Inherited B1 desktop search dropdown overflow remains; no unqualified search-layout PASS','Generated Quarto handler may open ordinary127.0.0.1 links in another task-owned tab; actual destinations checked','S8 whole SVG and internal whitespace remain fixed','Dense artwork on phones may require enlargement','Accepted Word S18 edge/footnote limitation retained; no Office conversion','16 historical source-hash gaps preserved','Four exact inherited font-reference exceptions and five exact unregistered historical links retained','Complete12839 inherited semantic-token occurrences across11 non-entry reports preserved, including some registered preparation/descriptive pages; entries remain strictly valid','Two old unregistered workflow sitemap URLs retained by the exact scope boundary'],no_render_or_analysis=True,no_writer_wakeup=True,no_commit_push_upload=True)
dump(E/'completion_summary.json',summary)
members=inventory(OUT);assert not any(r['path'] in ('completion_manifest.csv','completion_seal.json') for r in members)
csvout(OUT/'completion_manifest.csv',members)
dump(OUT/'completion_seal.json',dict(status=summary['status'],utc=utc(),members=len(members),manifest_sha256=sha(OUT/'completion_manifest.csv'),manifest_bytes=(OUT/'completion_manifest.csv').stat().st_size,helper_manifest_sha256=sha(E/'helper_manifest.csv'),transaction_journal_sha256=sha(E/'live_transaction_journal.jsonl'),profile_sha256=sha(ROOT/PROFILE),corpus_sha256=sha(ROOT/CORPUS),index_sha256=sha(LIVE/'index.html'),supplementary_sha256=sha(LIVE/'supplementary_information.html'),non_circular=True))
assert all(exact(OUT/r['path'],r['sha256'],r['bytes']) for r in members)
print(json.dumps(json.loads((OUT/'completion_seal.json').read_text()),indent=2))
