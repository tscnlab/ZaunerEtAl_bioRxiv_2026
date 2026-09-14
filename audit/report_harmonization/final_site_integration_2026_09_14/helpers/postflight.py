"""Read-only final pin, candidate, backup and live-state checks for Order011.

Writes only evidence in this candidate package. No research result is computed.
"""
import datetime
from collections import Counter
from common import *

checks=[]
def verify(path, expected, expected_bytes, category):
    p=Path(path)
    if not p.is_absolute(): p=ROOT/p
    exact=(not p.is_symlink() and p.is_file() and
           p.stat().st_size==int(expected_bytes) and sha(p)==expected)
    checks.append(dict(category=category,path=label(p),bytes=p.stat().st_size if p.is_file() else '',
                       sha256=sha(p) if p.is_file() else '',expected_sha256=expected,exact=exact))
    return exact

preflight=rows(EVIDENCE/'input_preflight.csv')
for r in preflight:
    verify(r['path'],r['sha256'],r['bytes'],'protected_'+r['category'])

absences=rows(EVIDENCE/'input_absences.csv')
for r in absences:
    p=Path(r['path']); p=p if p.is_absolute() else ROOT/p
    checks.append(dict(category='protected_absence',path=label(p),bytes='',sha256='',expected_sha256='',exact=not p.exists()))

def invmap(data): return {r['path']:(int(r['bytes']),r['sha256']) for r in data}
live=inventory(LIVE)
baseline=rows(EVIDENCE/'baseline_inventory.csv')
checks.append(dict(category='live_complete_inventory',path=label(LIVE),bytes='',sha256='',expected_sha256='',exact=invmap(live)==invmap(baseline) and len(live)==893))
for r in baseline: verify(LIVE/r['path'],r['sha256'],r['bytes'],'live_baseline893')

candidate=inventory(BUILD)
candidate_record=rows(EVIDENCE/'candidate_inventory.csv')
checks.append(dict(category='candidate_complete_inventory',path=label(BUILD),bytes='',sha256='',expected_sha256='',exact=invmap(candidate)==invmap(candidate_record) and len(candidate)==914))
for r in candidate_record: verify(BUILD/r['path'],r['sha256'],r['bytes'],'candidate914')

backups=rows(EVIDENCE/'five_backup_manifest.csv')
assert len(backups)==5
for r in backups:
    verify(r['backup'],r['sha256'],r['bytes'],'backup5')
    verify(r['live_target'],r['sha256'],r['bytes'],'unchanged_replacement_preimage5')

matrix=rows(PROPOSAL/'proposed_integration_matrix.csv')
additions=[r for r in matrix if r['current_exists']=='False']
assert len(additions)==21
for r in additions:
    checks.append(dict(category='live_addition_absent21',path=r['target'],bytes='',sha256='',expected_sha256='',exact=not (ROOT/r['target']).exists()))

promotions=rows(EVIDENCE/'website_promotion_manifest.csv')
assert len(promotions)==25
static=json.loads((EVIDENCE/'static_summary.json').read_text())
assert static['pass_'] and static['candidate_files']==914
content=rows(EVIDENCE/'content_reconciliation_R.csv')
capture_path=EVIDENCE/'browser_capture_identities.tsv'
with capture_path.open(newline='',encoding='utf-8') as f: captures=list(csv.DictReader(f,delimiter='\t'))
assert len(captures)==267 and [int(r['capture_id']) for r in captures]==list(range(1,268))
assert len(set(r['label'] for r in captures))==267
lifecycle=json.loads((EVIDENCE/'server_lifecycle.json').read_text())
assert lifecycle['status']=='stopped' and lifecycle['pid']==19328 and lifecycle['port']==51424
browser=json.loads((EVIDENCE/'browser_measurements.json').read_text())
assert browser['cleanup']['remaining_browser_tabs']==[]
assert browser['cleanup']['listener_check_exit_code']==1 and browser['cleanup']['listener_check_output']==''
assert browser['cleanup']['viewport_reset_called']

write_csv(EVIDENCE/'input_postflight.csv',checks)
write_csv(EVIDENCE/'candidate_inventory.postflight.csv',candidate)
summary=dict(time_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    all_exact=all(r['exact'] for r in checks),checks=len(checks),
    replayed_preflight_rows=len(preflight),protected_absences=len(absences),
    live_files=len(live),candidate_files=len(candidate),unchanged_baseline_files=889,
    unchanged_reader_report_htmls=35,backups=len(backups),live_additions_absent=len(additions),
    website_promotion_rows=len(promotions),R_reconciliation_rows=len(content),
    static_checks=static['checks'],search_records=static['search_records'],search_routes=static['search_routes'],
    browser_capture_rows=len(captures),capture_status_counts=dict(Counter(r['status'] for r in captures)),
    candidate_inventory_sha256=sha(EVIDENCE/'candidate_inventory.csv'),
    candidate_postflight_inventory_sha256=sha(EVIDENCE/'candidate_inventory.postflight.csv'),
    live_corpus_sha256=sha(CORPUS),server_stopped=True,temporary_tabs_closed=True,
    live_writes=0,scientific_recomputation=False,rendering=False)
write_json(EVIDENCE/'postflight_summary.json',summary)
print(json.dumps(summary,indent=2))
assert summary['all_exact'], 'Protected postflight pin changed; do not promote.'
