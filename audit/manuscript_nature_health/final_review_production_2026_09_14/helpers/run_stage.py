"""Order 009 serial production with immutable command receipts and finite trials."""
import argparse, hashlib, json, os, subprocess, tempfile, time
from pathlib import Path
P=Path(__file__).resolve().parents[1]
W=P/'project/manuscript/R0_NatHealth'
Q='ZaunerEtAl2026_NatHealth_phase3_brown.qmd'
PY='/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3'
DOC='/Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def plan(stage,r):
    h=P/'helpers'; m=P/'maps'; d=P/'deliverables'
    native_dir=P/'editable_tables' if r==1 else P/'editable_tables/round2'
    raw_round=1
    commands={
      'html':['/Applications/quarto/bin/quarto','render',Q,'--to','html','--no-execute','--output-dir',f'render_html_round{r}'],
      'docx':['/Applications/quarto/bin/quarto','render',Q,'--to','docx','--no-execute','--output-dir',f'render_docx_round{r}'],
      'native':[PY,str(h/'export_editable_tables.py'),str(W/f'render_html_round{r}'/Q.replace('.qmd','.html')),str(P/'project/assets/reference.docx'),str(native_dir), '--only']+(['Table_2','Table_S2'] if r==1 else ['Table_S2']),
      'assembly':[PY,str(h/'prepare_word_manuscript.py'),str(W/f'render_docx_round{raw_round}'/Q.replace('.qmd','.docx')),str(m/'word_table_png_manifest.json'),str(m/'word_figure_svg_manifest.json'),str(d/f'manuscript_assembled_round{r}.docx'),'--part-count-contract',str(m/'part_count_contract.json')],
      'embedding':[PY,str(h/'embed_accepted_svg_figures.py'),str(d/f'manuscript_assembled_round{r}.docx'),str(m/'expanded_svg_manifest.json'),str(d/f'Nature_Health_manuscript_round{r}.docx'),'--report',str(P/'evidence'/f'svg_embedding_round{r}.json')],
    }
    if stage.startswith('qa_'):
        label=stage[3:]
        source=d/f'Nature_Health_manuscript_round{r}.docx' if label=='main' else native_dir/f'{label}.docx'
        return [PY,DOC,str(source),'--output_dir',str(P/'qa'/f'{label}_round{r}'),'--dpi','150','--emit_pdf','--verbose']
    return commands[stage]
def main():
    a=argparse.ArgumentParser();a.add_argument('stage');a.add_argument('--round',type=int,choices=(1,2),default=1);args=a.parse_args()
    if args.stage not in {'html','docx','native','assembly','embedding'} and not args.stage.startswith('qa_'): raise RuntimeError('Unreleased stage')
    if args.round==2 and not (P/'evidence/layout_correction_round2.json').exists(): raise RuntimeError('Correction record required')
    if args.stage=='native' and not (P/'evidence/html_semantic_pass.json').exists(): raise RuntimeError('HTML acceptance required')
    if args.stage=='native' and args.round==2 and not (P/'evidence/html_semantic_pass_round2.json').exists(): raise RuntimeError('Round2 HTML acceptance required')
    if args.stage=='assembly' and not (P/'evidence/production_image_pass.json').exists(): raise RuntimeError('Six image verification required')
    label=f'{args.stage}_round{args.round}'; receipt=P/'evidence'/f'{label}_command.json'; log=P/'evidence'/f'{label}.log'
    if receipt.exists() or log.exists(): raise RuntimeError('This exact attempt was consumed')
    if args.stage.startswith('qa_'):
        previous=list((P/'evidence').glob(f'qa_*_round{args.round}_command.json'))
        if len(previous)>=(20 if args.round==1 else 3): raise RuntimeError('QA budget consumed')
    commands=plan(args.stage,args.round)
    scratch_file=P/'evidence/runtime.json'
    if scratch_file.exists(): scratch=json.loads(scratch_file.read_text())
    else:
        temp=Path(tempfile.mkdtemp(prefix='nh_order009_',dir='/private/tmp'))
        scratch={'scratch':str(temp),'cache':str(temp/'quarto_cache')}
        scratch_file.write_text(json.dumps(scratch,indent=2))
    env=dict(os.environ)
    env.update(RENV_CONFIG_AUTOLOADER_ENABLED='FALSE',R_LIBS_USER='/Users/zauner/Library/R/arm64/4.6/library',TMPDIR=scratch['scratch'],QUARTO_CACHE_DIR=scratch['cache'])
    env['PATH']='/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/override:'+str(Path(PY).parent)+':'+env.get('PATH','')
    cwd=W if args.stage in {'html','docx'} else P
    inputs={str(p):sha(p) for p in (P/'helpers').glob('*') if p.is_file()}
    if args.stage in {'html','docx'}:
        inputs.update({str(p):sha(p) for p in (P/'project').rglob('*') if p.is_file() and not any(x.startswith(('render_','.quarto')) for x in p.parts)})
    record=dict(stage=args.stage,round=args.round,command=commands,cwd=str(cwd),environment={k:env[k] for k in ('RENV_CONFIG_AUTOLOADER_ENABLED','R_LIBS_USER','TMPDIR','QUARTO_CACHE_DIR')},inputs=inputs,status='RUNNING',started=time.time())
    receipt.write_text(json.dumps(record,indent=2))
    with log.open('xb') as output:
        process=subprocess.Popen(commands,cwd=cwd,env=env,stdout=output,stderr=subprocess.STDOUT)
        record['pid']=process.pid; receipt.write_text(json.dumps(record,indent=2))
        result=process.wait()
    record.update(status='PASS' if result==0 else 'FAIL',exit_code=result,ended=time.time())
    receipt.write_text(json.dumps(record,indent=2))
    print(log.read_text()[-5000:]); print(json.dumps(dict(stage=args.stage,round=args.round,exit_code=result,receipt=str(receipt))))
    raise SystemExit(result)
if __name__=='__main__': main()
