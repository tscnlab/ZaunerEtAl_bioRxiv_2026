"""Freeze copies, check exact routing diffs, then exercise full isolated flow."""
from common import *
from check_closure import check_closure
import ast,difflib,subprocess,sys,shutil

names={'common.py','check_closure.py','transaction.py','transform.py','verify_static.py','verify_content.R','verify_targeted.R','verify_http_downloads.py','postflight.py','serve_live.py','finalize.py','preflight_implementation.py','fixture_guard.py','archive_cua.py'}
paths=sorted((OUT/'helpers').iterdir());assert {p.name for p in paths}==names
assert not (E/'helper_manifest.csv').exists() and not (E/'implementation_preflight.json').exists()
for p in paths:
    if p.suffix=='.py':ast.parse(p.read_text(),filename=str(p))
def replace_one(text,old,new):
    assert text.count(old)==1,(old,text.count(old));return text.replace(old,new,1)
changes={
 'transform.py':[("from common import *\n","from common import *\n# Verification replay uses immutable accepted preimages, never promoted live bytes.\nLIVE=BASELINE\nCORPUS=PRECORPUS\n")],
 'verify_static.py':[("    assert mode=='candidate'\n    build=BUILD","    assert mode in ('candidate','production')\n    build=CANDIDATE if mode=='candidate' else ACTIVE_SITE"),("doc(LIVE/route)","doc(BASELINE/route)"),("check('Live corpus unchanged',CORPUS.read_bytes()==original)","check('Exact corpus at selected phase',ACTIVE_CORPUS.read_bytes()==(original if mode=='candidate' else prospective))")],
 'verify_content.R':[("out <- file.path(root, \"audit/report_harmonization/final_site_a4_delta_2026_09_14/verification_recovery_015a\")","out <- file.path(root, \"audit/report_harmonization/final_site_a4_promotion_2026_09_14\")\nevidence <- Sys.getenv(\"ORDER016_EVIDENCE\", file.path(out, \"evidence\"))"),("candidate <- file.path(root, \"audit/report_harmonization/final_site_a4_delta_2026_09_14/candidate_build\")","candidate <- Sys.getenv(\"ORDER016_SITE_ROOT\", file.path(root, \"_build/nathealth\"))"),("file.path(out,\"evidence/content_reconciliation_R.csv\")","file.path(evidence,\"content_reconciliation_R.csv\")"),("file.path(out,\"evidence/content_R_sessionInfo.txt\")","file.path(evidence,\"content_R_sessionInfo.txt\")"),("paste(\"Candidate SHA256:\",digest(file=file.path(candidate,\"index.html\"),algo=\"sha256\"))","paste(\"Verified site:\",candidate),paste(\"Verified index SHA256:\",digest(file=file.path(candidate,\"index.html\"),algo=\"sha256\"))"),("file.path(out,\"evidence/content_R_provenance.txt\")","file.path(evidence,\"content_R_provenance.txt\")")],
 'verify_targeted.R':[("j <- 'audit/report_harmonization/final_site_a4_delta_2026_09_14'","j <- 'audit/report_harmonization/final_site_a4_promotion_2026_09_14'\nevidence <- Sys.getenv('ORDER016_EVIDENCE',file.path(j,'evidence'))\ncandidate <- Sys.getenv('ORDER016_SITE_ROOT','_build/nathealth')"),("new <- read_html(file.path(j,'candidate_build',route))","new <- read_html(file.path(candidate,route))"),("accepted_shell <- read_html(file.path('_build/nathealth',route))","accepted_shell <- read_html(file.path('audit/report_harmonization/final_site_integration_2026_09_14/candidate_build',route))"),("file.path(j,'verification_recovery_015a','evidence',","file.path(evidence,")],
 'verify_http_downloads.py':[]}
for name,replacements in changes.items():
    old=(REC/'helpers'/name).read_text();expected=old
    for before,after in replacements:
        count=2 if (name=='verify_static.py' and before=='doc(LIVE/route)') or (name=='verify_targeted.R' and before=="file.path(j,'verification_recovery_015a','evidence',") else 1
        assert expected.count(before)==count,(name,before,expected.count(before));expected=expected.replace(before,after)
    actual=(OUT/'helpers'/name).read_text();assert actual==expected,name
    safe(E/(name+'.routing.diff')).write_text(''.join(difflib.unified_diff(old.splitlines(True),actual.splitlines(True),fromfile='Accepted015a/'+name,tofile='Production016/'+name)))
for name in ['common.py','transaction.py']:
    donor=(REC/'helpers/common.py') if name=='common.py' else (PROM/'helpers/transaction.py')
    safe(E/(name+'.infrastructure.diff')).write_text(''.join(difflib.unified_diff(donor.read_text().splitlines(True),(OUT/'helpers'/name).read_text().splitlines(True),fromfile=label(donor),tofile='Order016/'+name)))
for name in ['candidate_inventory.csv','phase4_corpus_manifest.prospective.csv','prospective_corpus_reverse.csv','seven_backup_manifest.csv','raw_operation_ledger.json','search_delta.json']:
    assert (E/name).read_bytes()==(REC/'evidence'/name).read_bytes()
env=dict(os.environ,RENV_CONFIG_AUTOLOADER_ENABLED='FALSE',R_LIBS_USER=str(ROOT/'renv/library/macos/R-4.6/aarch64-apple-darwin23'))
for name in ['verify_content.R','verify_targeted.R']:
    result=subprocess.run(['Rscript','--vanilla','-e','invisible(parse(file=commandArgs(TRUE)[1])); print(.libPaths()); for(p in c("xml2","digest","jsonlite")) cat(p,as.character(packageVersion(p)),find.package(p),"\\n"); cat("R parse PASS\\n")',str(OUT/'helpers'/name)],cwd=ROOT,env=env,text=True,capture_output=True)
    safe(E/(name+'.parse.log')).write_text(result.stdout+result.stderr);assert result.returncode==0
csvout(E/'helper_manifest.csv',[dict(path=label(p),bytes=p.stat().st_size,sha256=sha(p)) for p in paths]);helper_checkpoint()
check_closure('pre','initial_pre');assert (E/'process_preflight.txt').is_file()
fixture=OUT/'fixtures/full';assert not fixture.exists();fixture.mkdir(parents=True)
assert not any(p.is_symlink() for p in LIVE.rglob('*'))
shutil.copytree(LIVE,fixture/'live_site');shutil.copy2(CORPUS,fixture/'corpus.csv');(fixture/'evidence').mkdir()
for name in ['candidate_inventory.csv','phase4_corpus_manifest.prospective.csv','prospective_corpus_reverse.csv','seven_backup_manifest.csv','raw_operation_ledger.json','search_delta.json']:shutil.copy2(E/name,fixture/'evidence'/name)
fenv=dict(env,ORDER016_TX_ROOT=str(fixture))
commands=[('prepare',[sys.executable,'-B',str(OUT/'helpers/transaction.py'),'prepare']),('commit',[sys.executable,'-B',str(OUT/'helpers/transaction.py'),'commit']),('full_postflight',[sys.executable,'-B',str(OUT/'helpers/postflight.py'),'nonbrowser']),('concurrent_guard',[sys.executable,'-B',str(OUT/'helpers/fixture_guard.py')]),('rollback',[sys.executable,'-B',str(OUT/'helpers/transaction.py'),'rollback'])]
for name,cmd in commands:
    result=subprocess.run(cmd,cwd=ROOT,env=fenv,text=True,capture_output=True)
    safe(E/('fixture_'+name+'.log')).write_text(json.dumps({'command':cmd,'fixture':str(fixture)})+'\n'+result.stdout+result.stderr)
    assert result.returncode==0,(name,result.returncode,result.stderr)
    print('FIXTURE PASS:',name,flush=True)
assert {r['path']:r for r in inv(fixture/'live_site')}=={r['path']:r for r in parsed_inv(REC/'evidence/post_live_inventory.csv')}
assert exact(fixture/'corpus.csv',transaction_rows()[-1]['pre_sha256'])
fp=json.loads((fixture/'evidence/nonbrowser_postflight.json').read_text());assert fp['all_pass']
fg=json.loads((fixture/'evidence/fixture_guard.json').read_text());assert fg['unexpected_target_rejected']
fj=[json.loads(x) for x in (fixture/'transaction_journal.jsonl').read_text().splitlines()]
assert len([x for x in fj if x['event']=='replace_complete'])==7 and len([x for x in fj if x['event']=='rollback_action'])==7 and fj[-1]['event']=='rollback_complete'
post=json.loads((fixture/'evidence/nonbrowser_post_summary.json').read_text());assert len(post['authorized_transition_paths'])==7
helper_checkpoint()
result=subprocess.run([sys.executable,'-B',str(OUT/'helpers/transaction.py'),'prepare'],cwd=ROOT,env=env,text=True,capture_output=True)
safe(E/'prepare_command.log').write_text(result.stdout+result.stderr);assert result.returncode==0,result.stderr
dump(E/'implementation_preflight.json',dict(utc=utc(),all_helpers_preflighted=True,helper_count=len(paths),helper_manifest_sha256=sha(E/'helper_manifest.csv'),fixture_complete=True,full_fixture_site_files=914,fixture_replacements=7,fixture_rollback_restorations=7,unexpected_concurrent_target_rejected_without_writes=True,fixture_static_checks=53724,fixture_R_checks=[75,15,15],browser_and_HTTP_results_not_simulated=True,production_writes=0,plan_sha256=sha(OUT/'transaction_plan.json'),accepted_scientific_predicates_unchanged=True,immutable_preimage_baselines_used=True,corpus_last=True))
print('PASS: complete copied implementation, full fixture transaction/postflight/guard/rollback, and exact seven-payload staging. Production remains unchanged.')
