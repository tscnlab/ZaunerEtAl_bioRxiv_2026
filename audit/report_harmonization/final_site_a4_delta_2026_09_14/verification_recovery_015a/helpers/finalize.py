"""Seal subsequent verification of the unchanged, previously stopped candidate."""
from common import *
from check_closure import check_closure
from recovery_guards import original_and_release,helper_checkpoint
import socket,errno
assert not (OUT/'completion_manifest.csv').exists()
life=json.loads((E/'server_lifecycle.json').read_text());assert life['status']=='stopped'
with socket.socket() as s:
    s.settimeout(2);connection_result=s.connect_ex(('127.0.0.1',int(life['port'])))
assert connection_result==errno.ECONNREFUSED,connection_result
assert (E/'no_listener_check.txt').is_file()
browser=json.loads((E/'browser_observations.json').read_text());assert browser['all_scoped_checks_pass'] and browser['viewport_reset'] and browser['own_tabs_closed']
assert json.loads((E/'http_download_summary.json').read_text())['all_exact']
static=json.loads((E/'candidate_static_summary.json').read_text());assert static['all_pass'] and static['checks']==53724
assert len(rows(E/'content_reconciliation_R.csv'))==75 and all(r['pass']=='TRUE' for r in rows(E/'content_reconciliation_R.csv'))
for route in ['index.html','supplementary_information.html']:assert len(rows(E/f'targeted_{route}.csv'))==15 and all(r['pass']=='TRUE' for r in rows(E/f'targeted_{route}.csv'))
helper_checkpoint()
check_closure('post')
original_and_release('post')
assert (OUT/'candidate_return.md').is_file()
dump(E/'final_safe_point.json',dict(utc=utc(),candidate_only=True,candidate_verified_without_rebuilding=True,original_build_remains_stopped=True,original961_exact=True,original_helpers_and_checkpoint_exact=True,new_helpers_exact=True,live_writes=0,candidate_writes=0,live914_unchanged=True,live_corpus_unchanged=True,candidate914_exact=True,all_donor_and_protected_closures_exact=True,server_stopped=True,port=life['port'],closed_port_errno=connection_result,own_tabs_closed=True,viewport_reset=True,Writer_not_woken=True))
members=inv(OUT);csvout(OUT/'completion_manifest.csv',members)
bound=lambda p:dict(path=label(p),bytes=p.stat().st_size,sha256=sha(p))
seal=dict(utc=utc(),order='015a',status='EXISTING_CANDIDATE_VERIFIED_AWAITING_INDEPENDENT_ACCEPTANCE',members=len(members),path_base=label(OUT),manifest=bound(OUT/'completion_manifest.csv'),exclusions=['completion_manifest.csv','completion_seal.json'],original_stopped_package=dict(base=label(T),members=959,manifest=bound(T/'failure_manifest.csv'),separate_seal=bound(T/'failure_seal.json'),all961_preserved=True,original_build_exit_reclassified=False),candidate_inventory=bound(E/'candidate_inventory.csv'),six_proposed_replacements=bound(E/'website_promotion_manifest.csv'),seven_preimage_manifest=bound(E/'seven_backup_manifest.csv'),candidate_files=914,replacements=6,additions=0,removals=0,recovery_builds=0,live_writes=0,candidate_writes=0,live_corpus_sha256=sha(CORPUS),prospective_corpus=bound(E/'phase4_corpus_manifest.prospective.csv'),browser_teardown_complete=True)
dump(OUT/'completion_seal.json',seal)
for r in members:assert exact(OUT/r['path'],r['sha256'],r['bytes'])
assert {r['path'] for r in inv(OUT)}=={r['path'] for r in members}|{'completion_manifest.csv','completion_seal.json'}
print(json.dumps(seal,indent=2));print('Seal SHA256:',sha(OUT/'completion_seal.json'))
