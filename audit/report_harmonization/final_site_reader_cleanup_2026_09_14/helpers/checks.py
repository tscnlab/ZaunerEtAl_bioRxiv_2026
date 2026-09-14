"""New frozen Order017 check runner, never invokes historical writing validators."""
from common import *
import ast, subprocess, sys

PY=sys.executable
def command(args,tag,env=None):
    result=subprocess.run(args,cwd=ROOT,env=env,text=True,capture_output=True)
    owned(E/(tag+'.stdout.txt')).write_text(result.stdout)
    owned(E/(tag+'.stderr.txt')).write_text(result.stderr)
    dump(E/(tag+'.command.json'),dict(command=args,returncode=result.returncode,utc=utc()))
    assert result.returncode==0,(tag,result.stderr[-3000:])
    return result
def r_environment(mode,tag):
    env=os.environ.copy(); destination=E/(tag+'_verified_R');destination.mkdir(exist_ok=False)
    env.update(RENV_CONFIG_AUTOLOADER_ENABLED='FALSE',R_LIBS=str(ROOT/'renv/library/macos/R-4.6/aarch64-apple-darwin23'),
        ORDER017_SITE_ROOT=str(site_for(mode)),ORDER017_CORPUS=str(target(CORPUS,mode)),ORDER017_PROFILE=str(target(PROFILE,mode)),ORDER017_EVIDENCE=str(destination))
    return env
def run(mode,tag):
    helper_check(); assert not (E/(tag+'_checks.json')).exists()
    try:
        command([PY,'-B',str(OUT/'helpers/verify_static.py'),mode,tag],tag+'_static_run')
        env=r_environment(mode,tag)
        for name in ['verify_roster_content.R','verify_content.R','verify_targeted.R','verify_semantics.R']:
            command(['Rscript','--vanilla',str(OUT/'helpers'/name)],tag+'_'+name,env)
        dump(E/(tag+'_checks.json'),dict(status='PASS',mode=mode,utc=utc(),static=True,roster_R=True,accepted_content_R=True,targeted_R=True,all44_semantics_R=True,helper_manifest_sha256=sha(E/'helper_manifest.csv')))
    except Exception as exc:
        dump(E/(tag+'_checks_FAILED.json'),dict(status='FAIL',mode=mode,utc=utc(),exception=repr(exc)));raise
    print('PASS',mode,tag,'complete static and three R checks')
def freeze():
    assert not (E/'helper_manifest.csv').exists()
    helpers=sorted(p for p in (OUT/'helpers').iterdir() if p.is_file())
    for p in helpers:
        if p.suffix=='.py': compile(p.read_text(),str(p),'exec');ast.parse(p.read_text())
    rfiles=[str(p) for p in helpers if p.suffix=='.R']
    env=os.environ.copy(); env['RENV_CONFIG_AUTOLOADER_ENABLED']='FALSE'
    command(['Rscript','--vanilla','-e','stopifnot(getRversion()=="4.6.1"); for(p in commandArgs(TRUE)) parse(p); cat("R helpers parsed successfully\\n")',*rfiles],'helper_R_parse',env)
    csvout(E/'helper_manifest.csv',[dict(path=str(p.relative_to(OUT)),bytes=p.stat().st_size,sha256=sha(p)) for p in helpers])
    csvout(E/'copied_input_manifest.csv',inventory(OUT/'inputs'))
    dump(E/'helper_freeze.json',dict(utc=utc(),status='PASS',members=len(helpers),manifest_sha256=sha(E/'helper_manifest.csv'),python=sys.version,R='4.6.1'))
    print('PASS complete helper freeze:',len(helpers))
if __name__=='__main__':
    if sys.argv[1]=='freeze':freeze()
    else:run(sys.argv[1],sys.argv[2])
