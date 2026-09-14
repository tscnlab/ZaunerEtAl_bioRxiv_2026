"""Prepare verification metadata and checkpoint helpers, never change candidate."""
from common import *
from recovery_guards import original_and_release,helper_checkpoint
from check_closure import check_closure
import ast,subprocess,difflib,shutil

assert not (E/'recovery_helper_manifest.csv').exists()
original_and_release('pre')
assert (E/'process_preflight.txt').is_file()
oldroot=T/'helpers';newroot=OUT/'helpers'
names=['common.py','check_closure.py','transform.py','verify_static.py','verify_content.R','verify_targeted.R','serve_candidate.py','verify_http_downloads.py']
logical=[]
for name in names:
    old=(oldroot/name).read_text();new=(newroot/name).read_text();expected=old
    if name=='common.py':
        expected=expected.replace("OUT=ROOT/'audit/report_harmonization/final_site_a4_delta_2026_09_14'","T=ROOT/'audit/report_harmonization/final_site_a4_delta_2026_09_14'\nOUT=T/'verification_recovery_015a'").replace("BUILD=OUT/'candidate_build'","BUILD=T/'candidate_build'")
    elif name=='check_closure.py':
        before="assert candidate==[expected[k] for k in sorted(expected)]"
        after="assert len(candidate)==len({r['path'] for r in candidate})==len(expected) and {r['path']:r for r in candidate}==expected"
        assert old.count(before)==1
        expected=old.replace(before,after,1)
        assert expected.replace(after,before,1)==old
        logical.append(dict(helper=name,exact_logical_reverse=True,original_sha256=sha(oldroot/name),corrected_sha256=hashlib.sha256(expected.encode()).hexdigest()))
    elif name=='verify_content.R':
        expected=expected.replace('out <- file.path(root, "audit/report_harmonization/final_site_a4_delta_2026_09_14")','out <- file.path(root, "audit/report_harmonization/final_site_a4_delta_2026_09_14/verification_recovery_015a")').replace('candidate <- file.path(out, "candidate_build")','candidate <- file.path(root, "audit/report_harmonization/final_site_a4_delta_2026_09_14/candidate_build")')
    elif name=='verify_targeted.R':
        central=CONTROL/'site015_stop_independent/R_complete'
        before=(central/'exact_old_targeted_fragment.txt').read_text();after=(central/'exact_new_targeted_fragment.txt').read_text()
        assert old.count(before)==1
        template=old.replace(before,after,1)
        assert hashlib.sha256(template.encode()).hexdigest()=='59f910d4352708669ce44d3bf8b2bbac2b0454bde60febe32f9e599f7de05132'
        assert template==(central/'verify_targeted.prospective.R').read_text() and template.replace(after,before,1)==old
        expected=template.replace("file.path(j,'evidence',","file.path(j,'verification_recovery_015a','evidence',")
        assert expected.replace("file.path(j,'verification_recovery_015a','evidence',","file.path(j,'evidence',")==template
        logical.append(dict(helper=name,exact_logical_reverse=True,original_sha256=sha(oldroot/name),corrected_sha256=hashlib.sha256(template.encode()).hexdigest()))
    assert new==expected,name
    safe(E/(name+'.diff')).write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile=label(oldroot/name),tofile=label(newroot/name))))
csvout(E/'logical_reverse_proofs.csv',logical)
helpers=sorted(newroot.iterdir());assert len(helpers)==11 and all(p.is_file() for p in helpers)
for p in helpers:
    if p.suffix=='.py':ast.parse(p.read_text(),filename=str(p))
    if p.suffix=='.R':
        r=subprocess.run(['Rscript','--vanilla','-e','stopifnot(getRversion()=="4.6.1");invisible(parse(file=commandArgs(TRUE)[1]));cat("R4.6.1 parse PASS\\n")',str(p)],text=True,capture_output=True)
        safe(E/(p.stem+'_parse.txt')).write_text(r.stdout+r.stderr);assert r.returncode==0,r.stderr
copies=[]
for name in ['raw_operation_ledger.json','raw_reversal_checks.csv','search_delta.json','seven_backup_manifest.csv','phase4_corpus_manifest.prospective.csv','prospective_corpus_reverse.csv']:
    src=T/'evidence'/name;dst=safe(E/name);assert not dst.exists();shutil.copy2(src,dst);assert src.read_bytes()==dst.read_bytes()
    copies.append(dict(source=label(src),copy=label(dst),bytes=src.stat().st_size,sha256=sha(src),exact=True))
csvout(E/'exact_evidence_copies.csv',copies)
candidate=inv(BUILD);csvout(E/'candidate_inventory.csv',candidate)
promotion=[]
for r in plan_rows():
    route=str(Path(r['target']).relative_to('_build/nathealth'))
    assert exact(BUILD/route,r['post_sha256'],r['bytes'])
    promotion.append(dict(target=r['target'],candidate=label(BUILD/route),bytes=r['bytes'],preimage_sha256=r['pre_sha256'],candidate_sha256=r['post_sha256'],action='replace'))
csvout(E/'website_promotion_manifest.csv',promotion)
csvout(E/'recovery_helper_manifest.csv',[dict(path=label(p),bytes=p.stat().st_size,sha256=sha(p)) for p in helpers])
helper_checkpoint()
check_closure('pre')
dump(E/'recovery_preflight.json',dict(utc=utc(),all_pass=True,new_helper_count=11,original_helpers_exact=True,exact_predicate_reversals=True,metadata_only=True,candidate_files=914,candidate_writes=0,live_writes=0,builds=0))
print('PASS: recovery helper checkpoint, two exact predicate reversals, original961 and live/protected closure; metadata only.')
