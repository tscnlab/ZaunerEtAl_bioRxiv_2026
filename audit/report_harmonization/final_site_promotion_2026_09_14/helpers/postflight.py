"""Durable stopped-listener and unchanged full production/source closure proof."""
from common import *
from check_closure import check_closure
import socket
life=json.loads((E/'server_lifecycle.json').read_text())
assert life['status']=='stopped' and life['host']=='127.0.0.1' and life['root']==str(LIVE)
with socket.socket() as probe:
    probe.settimeout(2);port_closed=probe.connect_ex(('127.0.0.1',int(life['port'])))!=0
assert port_closed
assert (E/'no_listener_check.txt').is_file()
browser=json.loads((E/'browser_observations.json').read_text())
assert browser['viewport_reset'] and browser['own_tabs_closed'] and browser['short_production_QA_pass']
assert set(browser['widths_checked'])=={1440,708,390}
assert set(browser['entry_routes'])=={'index.html','supplementary_information.html'}
assert json.loads((E/'production_static_summary.json').read_text())['all_pass']
assert json.loads((E/'http_download_summary.json').read_text())['all_exact']
assert len(rows(E/'http_download_checks.csv'))==22
assert len(rows(E/'content_reconciliation_R.csv'))==75 and all(r['pass']=='TRUE' for r in rows(E/'content_reconciliation_R.csv'))
summary=check_closure('post')
j=[json.loads(x) for x in (OUT/'transaction_journal.jsonl').read_text().splitlines()]
complete=[r for r in j if r['event']=='replace_complete']
assert len(complete)==26 and [r['sequence'] for r in complete]==list(range(1,27)) and complete[-1]['target']==label(CORPUS)
assert j[-1]['event']=='transaction_complete' and not any('rollback' in r['event'] for r in j)
proof=dict(utc=utc(),safe_point=True,port=int(life['port']),port_closed=port_closed,viewport_reset=True,own_tabs_closed=True,live914_matches_accepted=True,complete_fixed_source_and_candidate_closure_exact=True,corpus_sha256=sha(CORPUS),Writer012_untouched=True,operations_exact_once=26,corpus_last=True)
dump(E/'production_safe_point.json',proof);print(json.dumps(proof,indent=2))
