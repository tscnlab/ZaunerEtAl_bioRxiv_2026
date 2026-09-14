"""Compile and constrain every helper, plan, staged payload and rollback fixture."""
from common import *
from transaction import read_plan
import ast,subprocess,difflib

expected_helpers={'common.py','check_closure.py','transaction.py','verify_production.py','verify_content.R','serve_live.py','verify_http_downloads.py','preflight_implementation.py','postflight.py','finalize.py'}
helpers=list(sorted((OUT/'helpers').iterdir()))
assert {p.name for p in helpers}==expected_helpers
for p in helpers:
    if p.suffix=='.py':ast.parse(p.read_text(),filename=str(p))
source=(OLD/'helpers/verify_content.R').read_text()
expected=source.replace('# Order011 exact reported-content reconciliation.','# Order013 production exact reported-content reconciliation.').replace('out <- file.path(root, "audit/report_harmonization/final_site_integration_2026_09_14")','out <- file.path(root, "audit/report_harmonization/final_site_promotion_2026_09_14")').replace('candidate <- file.path(out, "candidate_build")','candidate <- file.path(root, "_build/nathealth")').replace('paste("Candidate SHA256:"','paste("Live SHA256:"')
actual=(OUT/'helpers/verify_content.R').read_text();assert actual==expected
safe(E/'content_verifier_routing.diff').write_text(''.join(difflib.unified_diff(source.splitlines(True),actual.splitlines(True),fromfile='Accepted011 verifier',tofile='Production013 verifier')))
r=subprocess.run(['Rscript','--vanilla','-e','invisible(parse(file=commandArgs(TRUE)[1])); cat("R parse PASS\\n")',str(OUT/'helpers/verify_content.R')],text=True,capture_output=True)
safe(E/'R_parse_preflight.txt').write_text(r.stdout+r.stderr);assert r.returncode==0,r.stderr
p,events=read_plan();assert [e['event'] for e in events]==['prepared']
assert len(p['entries'])==26 and p['entries'][-1]['target']==label(CORPUS)
assert sum(r['action']=='replace' for r in p['entries'])==5 and sum(r['action']=='add' for r in p['entries'])==21
for r in p['entries']:
    checked_path(ROOT/r['target']);assert Path(r['temporary']).parent==Path(r['target']).parent
    assert (ROOT/r['staged']).is_relative_to(OUT/'staged')
    if r['backup']:assert (ROOT/r['backup']).is_relative_to(OUT/'preimages') and exact(ROOT/r['backup'],r['pre_sha256'])
assert json.loads((E/'transaction_selftest.json').read_text())['unexpected_targets_rejected']==2
assert json.loads((E/'candidate_static_summary.json').read_text())['all_pass']
assert json.loads((E/'pre_closure_summary.json').read_text())['all_exact']
assert (E/'process_preflight.txt').is_file()
result=dict(utc=utc(),all_helpers_preflighted=True,helpers=[dict(path=label(p),bytes=p.stat().st_size,sha256=sha(p)) for p in helpers],staged_operations=26,corpus_last=True,atomic_replace_and_rollback_fixture=True,rollback_guard_rejects_unexpected_targets=True,R_scientific_logic_unchanged=True,production_structure_validator_executed_on_accepted_candidate=True,source_Writer012_candidate_pinned=False)
dump(E/'implementation_preflight.json',result);print('PASS: complete promotion, postflight and rollback implementation preflighted.')
