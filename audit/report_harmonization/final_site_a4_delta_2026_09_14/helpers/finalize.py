"""Final immutable closure, browser teardown and noncircular candidate seal."""
from common import *
from check_closure import check_closure
import socket,errno
assert not (OUT/'completion_manifest.csv').exists()
life=json.loads((E/'server_lifecycle.json').read_text());assert life['status']=='stopped'
with socket.socket() as s:
    s.settimeout(2);connection_result=s.connect_ex(('127.0.0.1',int(life['port'])))
assert connection_result==errno.ECONNREFUSED,connection_result
assert (E/'no_listener_check.txt').is_file()
browser=json.loads((E/'browser_observations.json').read_text());assert browser['all_scoped_checks_pass'] and browser['viewport_reset'] and browser['own_tabs_closed']
assert json.loads((E/'http_download_summary.json').read_text())['all_exact']
assert json.loads((E/'candidate_static_summary.json').read_text())['all_pass']
assert len(rows(E/'content_reconciliation_R.csv'))==75 and all(r['pass']=='TRUE' for r in rows(E/'content_reconciliation_R.csv'))
for route in ['index.html','supplementary_information.html']:assert len(rows(E/f'targeted_{route}.csv'))==15 and all(r['pass']=='TRUE' for r in rows(E/f'targeted_{route}.csv'))
for r in json.loads((E/'implementation_preflight.json').read_text())['helpers']:assert exact(ROOT/r['path'],r['sha256'],r['bytes'])
check_closure('post')
assert (OUT/'candidate_return.md').is_file()
dump(E/'final_safe_point.json',dict(utc=utc(),candidate_only=True,live_writes=0,live914_unchanged=True,live_corpus_unchanged=True,candidate914_exact=True,all_donor_and_protected_closures_exact=True,server_stopped=True,port=life['port'],closed_port_errno=connection_result,own_tabs_closed=True,viewport_reset=True,Writer_not_woken=True))
members=inv(OUT);csvout(OUT/'completion_manifest.csv',members)
seal=dict(utc=utc(),order='015',status='CANDIDATE_ONLY_COMPLETE_AWAITING_INDEPENDENT_ACCEPTANCE',members=len(members),manifest=dict(path=label(OUT/'completion_manifest.csv'),bytes=(OUT/'completion_manifest.csv').stat().st_size,sha256=sha(OUT/'completion_manifest.csv')),exclusions=['completion_manifest.csv','completion_seal.json'],candidate_files=914,replacements=6,additions=0,removals=0,live_writes=0,live_corpus_sha256=sha(CORPUS),prospective_corpus_sha256=sha(E/'phase4_corpus_manifest.prospective.csv'),backups=7,browser_teardown_complete=True)
dump(OUT/'completion_seal.json',seal)
for r in members:assert exact(OUT/r['path'],r['sha256'],r['bytes'])
assert {r['path'] for r in inv(OUT)}=={r['path'] for r in members}|{'completion_manifest.csv','completion_seal.json'}
print(json.dumps(seal,indent=2));print('Seal SHA256:',sha(OUT/'completion_seal.json'))
