"""Complete routed checks and guarded production postflight, no rendering."""
from common import *
from check_closure import check_closure
import subprocess,sys,socket,errno

def run_checks():
    helper_checkpoint()
    env=dict(os.environ,RENV_CONFIG_AUTOLOADER_ENABLED='FALSE',R_LIBS_USER=str(ROOT/'renv/library/macos/R-4.6/aarch64-apple-darwin23'),ORDER016_SITE_ROOT=str(ACTIVE_SITE),ORDER016_EVIDENCE=str(E))
    commands=[([sys.executable,'-B',str(OUT/'helpers/verify_static.py'),'production'],'static'),(['Rscript','--vanilla',str(OUT/'helpers/verify_content.R')],'content_R'),(['Rscript','--vanilla',str(OUT/'helpers/verify_targeted.R')],'targeted_R')]
    for cmd,name in commands:
        result=subprocess.run(cmd,cwd=ROOT,env=env,text=True,capture_output=True)
        safe(E/f'{name}_command.log').write_text(json.dumps(dict(command=cmd,R_LIBS_USER=env['R_LIBS_USER'],autoloader='FALSE',site=str(ACTIVE_SITE),evidence=str(E)))+'\n'+result.stdout+result.stderr)
        assert result.returncode==0,(name,result.returncode,result.stderr)
    verify_counts();check_closure('post','nonbrowser_post')
    dump(E/'nonbrowser_postflight.json',dict(utc=utc(),fixture=IS_FIXTURE,all_pass=True,static=53724,content=75,targeted=[15,15],no_render=True))

def verify_counts():
    s=json.loads((E/'production_static_summary.json').read_text());assert s['all_pass'] and s['checks']==53724
    c=rows(E/'content_reconciliation_R.csv');assert len(c)==75 and all(r['pass']=='TRUE' for r in c)
    for route in ['index.html','supplementary_information.html']:
        c=rows(E/f'targeted_{route}.csv');assert len(c)==15 and all(r['pass']=='TRUE' for r in c)

def final_checks():
    assert not IS_FIXTURE
    helper_checkpoint();verify_counts()
    life=json.loads((E/'server_lifecycle.json').read_text());assert life['status']=='stopped' and life['root']==str(LIVE) and life['host']=='127.0.0.1'
    with socket.socket() as s:
        s.settimeout(2);closed=s.connect_ex(('127.0.0.1',life['port']))
    assert closed==errno.ECONNREFUSED
    assert (E/'no_listener_check.txt').is_file()
    b=json.loads((E/'browser_observations.json').read_text())
    assert b['short_production_QA_complete'] and not b['genuinely_new_defect'] and b['viewport_reset'] and b['own_tabs_closed']
    assert 1440 in b['widths_checked'] and (708 in b['widths_checked'] or 390 in b['widths_checked'])
    assert set(b['entry_routes'])=={'index.html','supplementary_information.html'}
    assert b['desktop_search_inherited_qualification'] and not b['unqualified_error_free_claim']
    assert json.loads((E/'http_download_summary.json').read_text())['all_exact'] and len(rows(E/'http_download_checks.csv'))==22
    check_closure('post','final_post')
    j=[json.loads(x) for x in (OUT/'transaction_journal.jsonl').read_text().splitlines()]
    done=[r for r in j if r['event']=='replace_complete'];assert len(done)==7 and [r['sequence'] for r in done]==list(range(1,8)) and done[-1]['target']==label(CORPUS)
    assert j[-1]['event']=='transaction_complete' and not any('rollback' in r['event'] for r in j)
    for r in json.loads((OUT/'transaction_plan.json').read_text())['entries']:assert not (ROOT/r['temporary']).exists()
    dump(E/'production_safe_point.json',dict(utc=utc(),safe_point=True,accepted_with_inherited_qualifications=True,port=life['port'],closed_port_errno=closed,own_tabs_closed=True,viewport_reset=True,live914_equals_candidate914=True,protected_closure_exact=True,operations_exact_once=7,corpus_last=True,corpus_sha256=sha(CORPUS),Writer_not_woken=True))

if __name__=='__main__':
    try:{'nonbrowser':run_checks,'final':final_checks}[sys.argv[1]]()
    except BaseException:
        if not IS_FIXTURE and (OUT/'transaction_journal.jsonl').exists():
            from transaction import rollback,event
            try:rollback()
            except BaseException as exc:event('postflight_rollback_blocked',error=repr(exc))
        raise
