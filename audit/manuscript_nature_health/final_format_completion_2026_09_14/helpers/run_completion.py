"""Bounded serial Order010b execution, with one immutable log per stage/version."""
from pathlib import Path
import argparse,subprocess,json,os,time,hashlib,shutil
C=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser();ap.add_argument('stage',choices=['html','assemble','svg','render']);ap.add_argument('--round',type=int,choices=(1,2),default=1);a=ap.parse_args()
PY='/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3'
RENDER='/Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py'
version=f'round{a.round}';raw=C/'inputs/raw_static.docx';assembled=C/f'deliverables/manuscript_assembled_{version}.docx';main=C/f'deliverables/Nature_Health_manuscript_{version}.docx'
commands={
 'html':[PY,str(C/'helpers/package_html.py'),'--round',str(a.round)],
 'assemble':[PY,str(C/'helpers/prepare_word_manuscript.py'),str(raw),str(C/'maps/word_table_png_manifest.json'),str(C/'maps/word_figure_svg_manifest.json'),str(assembled),'--part-count-contract',str(C/'maps/part_count_contract.json')],
 'svg':[PY,str(C/'helpers/embed_accepted_svg_figures.py'),str(assembled),str(C/'maps/expanded_svg_manifest.json'),str(main),'--report',str(C/f'evidence/svg_integration_{version}.json')],
 'render':[PY,RENDER,str(main),'--output_dir',str(C/f'qa/main_{version}'),'--dpi','150','--emit_pdf','--verbose'],
}
E=C/f'evidence/{a.stage}_{version}_execution.json';assert not E.exists(),'No duplicate execution'
if a.round==2 and a.stage!='render':assert (C/f'evidence/{a.stage}_round1_execution.json').exists()
if a.stage=='render':
    assert main.is_file() and json.loads((C/f'evidence/svg_{version}_execution.json').read_text())['status']=='complete'
    assert len(list((C/'evidence').glob('render_round*_execution.json')))<2
cmd=commands[a.stage];env=os.environ.copy();env['PATH']='/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/override:'+env.get('PATH','');env['PYTHONDONTWRITEBYTECODE']='1'
record=dict(stage=a.stage,round=a.round,command=cmd,started=time.time(),helper_sha256=hashlib.sha256(Path(cmd[1]).read_bytes()).hexdigest(),status='started')
E.write_text(json.dumps(record,indent=2))
with (C/f'evidence/{a.stage}_{version}.log').open('w') as log:
    proc=subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,env=env)
record.update(ended=time.time(),exit_code=proc.returncode,status='complete' if proc.returncode==0 else 'failed');E.write_text(json.dumps(record,indent=2))
print(json.dumps(record,indent=2))
if proc.returncode: print((C/f'evidence/{a.stage}_{version}.log').read_text()[-8000:]);raise SystemExit(proc.returncode)
if a.stage=='svg':
    download=C/f'project/html_{version}/ZaunerEtAl2026_NatHealth_phase3_brown.docx';assert not download.exists()
    shutil.copy2(main,download)
    assert hashlib.sha256(main.read_bytes()).digest()==hashlib.sha256(download.read_bytes()).digest()
