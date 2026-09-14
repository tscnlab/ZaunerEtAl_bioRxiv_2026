"""Read-only implementation rehearsal before the one candidate package."""
from common import *
from transform import make_postimages
import ast,subprocess,difflib
assert not BUILD.exists()
expected={'common.py','check_closure.py','transform.py','build_candidate.py','verify_static.py','verify_content.R','verify_targeted.R','preflight_implementation.py','serve_candidate.py','verify_http_downloads.py','finalize.py'}
helpers=sorted((OUT/'helpers').iterdir());assert {p.name for p in helpers}==expected
for p in helpers:
    if p.suffix=='.py':ast.parse(p.read_text(),filename=str(p))
    if p.suffix=='.R':
        r=subprocess.run(['Rscript','--vanilla','-e','stopifnot(getRversion()=="4.6.1"); invisible(parse(file=commandArgs(TRUE)[1]));cat("R4.6.1 parse PASS\\n")',str(p)],text=True,capture_output=True)
        safe(E/(p.stem+'_parse.txt')).write_text(r.stdout+r.stderr);assert r.returncode==0,r.stderr
for old,new in [(OLD/'helpers/verify_content.R',OUT/'helpers/verify_content.R'),(WRITER/'helpers/verify_html.R',OUT/'helpers/verify_targeted.R'),(PROM/'helpers/verify_production.py',OUT/'helpers/verify_static.py')]:
    safe(E/(new.stem+'_adaptation.diff')).write_text(''.join(difflib.unified_diff(old.read_text().splitlines(True),new.read_text().splitlines(True),fromfile=label(old),tofile=label(new))))
plans,ledger,reversals,search_delta,prospective,corpus_reverse=make_postimages()
assert len(plans)==6 and len(ledger)==20 and all(r['exact_whole_file_reversal'] for r in reversals)
assert json.loads((E/'pre_closure_summary.json').read_text())['all_exact']
assert (E/'process_preflight.txt').is_file()
dump(E/'implementation_preflight.json',dict(utc=utc(),all_helpers_preflighted=True,helpers=[dict(path=label(p),bytes=p.stat().st_size,sha256=sha(p)) for p in helpers],in_memory_postimage_rehearsal=True,exact_six_postimages=True,exact_accepted20_operation_counts=True,both_stepwise_and_whole_reversals=True,exact_two_route_search=True,prospective_corpus_exact=True,live_writes=0,candidate_builds=0))
print('PASS: all downstream helpers parsed; exact accepted postimages and reversals rehearsed in memory; no candidate or live writes.')
