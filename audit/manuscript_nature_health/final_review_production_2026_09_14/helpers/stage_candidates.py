"""Order 009 static dependency staging, never a scientific producer."""
import ast
import csv
import difflib
import hashlib
import html
import json
import os
import re
import shutil
from pathlib import Path

P = Path(__file__).resolve().parents[1]
ROOT = P.parents[2]
A = ROOT / 'audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02'
OLD = ROOT / 'audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/helpers'
GUIDE = ROOT / 'audit/report_harmonization/final_documents_2026_09_12/writer_layout_preflight_archival_001/package/diffs'
PROJECT = P / 'project'
LOGICAL = ROOT / 'manuscript/R0_NatHealth'
DEST = PROJECT / 'manuscript/R0_NatHealth'
QMD = 'ZaunerEtAl2026_NatHealth_phase3_brown.qmd'
copies, changes, visited = [], [], set()

def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p, text):
    if p.exists(): raise RuntimeError(f'Output already exists: {p}')
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding='utf-8')
def copy(source, target, role):
    source = Path(source).resolve()
    if source.is_symlink() or not source.is_file(): raise RuntimeError(f'Invalid source {source}')
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        if sha(target) != sha(source): raise RuntimeError('Copy collision')
    else: shutil.copyfile(source, target)
    copies.append(dict(source=str(source),copy=str(target),sha256=sha(source),bytes=source.stat().st_size,role=role))
    return target
def dependency(source):
    source = Path(source).resolve()
    if not source.is_relative_to(ROOT): raise RuntimeError(f'External dependency {source}')
    if source in visited: return PROJECT/source.relative_to(ROOT)
    visited.add(source)
    if source.suffix.lower() not in {'.html','.css','.svg','.png','.jpg','.jpeg','.woff2','.bib','.csl','.docx','.lua','.yml'}:
        raise RuntimeError(f'Unexpected render dependency {source}')
    target=copy(source, PROJECT/source.relative_to(ROOT), 'static_dependency')
    if source.suffix in {'.html','.css'}:
        text=source.read_text()
        # Embedded PNGs and URLs do not require another input read.
        refs=re.findall(r'(?:src|href)=[\"\']([^\"\']+)[\"\']',text)
        refs+=re.findall(r'url\([\"\']?([^\"\')]+)',text)
        for ref in refs:
            if ref.startswith(('http:','https:','data:','#','mailto:','//')): continue
            candidate=(source.parent/ref.split('#')[0]).resolve()
            if candidate.is_file(): dependency(candidate)
    return target
def literal(text, old, new, reason):
    if old not in text: raise RuntimeError(f'Missing literal {old[:100]}')
    changes.append(dict(old=old,new=new,reason=reason))
    return text.replace(old,new)
def apply_reviewed_diff(base, diff):
    lines=diff.splitlines(keepends=True); out=base
    for match in re.finditer(r'(?m)^@@.*\n',diff):
        start=match.end(); tail=diff[start:]; end=re.search(r'(?m)^@@',tail)
        hunk=tail[:end.start()] if end else tail
        hs=hunk.splitlines(keepends=True)
        old=''.join(x[1:] for x in hs if x.startswith((' ','-')))
        new=''.join(x[1:] for x in hs if x.startswith((' ','+')))
        if out.count(old)!=1: raise RuntimeError('Reviewed hunk is not unique/exact')
        out=out.replace(old,new,1)
    return out

def main():
    if PROJECT.exists(): raise RuntimeError('Do not overwrite a staged project')
    assert json.loads((P/'evidence/preflight_result.json').read_text())['status']=='PASS'
    for name in ('helpers','maps','production_images','editable_tables','qa','deliverables','evidence'):
        (P/name).mkdir(exist_ok=True)
    for p in (A/'maps').glob('*'):
        if p.is_file(): copy(p,P/'maps'/p.name,'accepted_map')
    figure_rows=list(csv.DictReader((A/'maps/complete_SVG_source_map.csv').open()))
    bylabel={r['word_label']:r for r in figure_rows}
    assert len(figure_rows)==23 and sum(int(r['appearances']) for r in figure_rows)==24
    figure_paths={}
    for row in figure_rows:
        assert sha(row['path'])==row['sha256']
        target=copy(row['path'],DEST/'accepted_figures'/(row['sha256'][:12]+'_'+Path(row['path']).name),'accepted_svg')
        figure_paths[row['word_label']]=os.path.relpath(target,DEST)
    texts={name:(A/'source'/name).read_text() for name in (QMD,'supplementary_information_outline.qmd')}
    original_texts=dict(texts)
    for name,text in texts.items():
        for m in list(re.finditer(r'\{\{< include ([^ >]+) >\}\}',text)):
            ref=m.group(1)
            if ref=='supplementary_information_outline.qmd': continue
            dependency(LOGICAL/ref)
        if name==QMD:
            matches=list(re.finditer(r'!\[\]\(([^)]+)\)',text)); assert len(matches)==3
            for n,m in reversed(list(enumerate(matches,1))):
                new=figure_paths[f'Main Figure {n}']
                old=m.group(1)
                changes.append(dict(file=name,old=old,new=new,reason='accepted SVG path'))
                text=text[:m.start(1)]+new+text[m.end(1):]
            for key in ('bibliography','csl','css'):
                dependency(LOGICAL/re.search(rf'^{key}: (.+)$',text,re.M).group(1))
        else:
            for n in range(1,18):
                block=re.search(rf'<figure id="fig-s{n}".*?</figure>',text,re.S).group()
                imgs=list(re.finditer(r'<img\b[^>]*src="([^"]+)"[^>]*>',block))
                if n in {7,15}:
                    assert len(imgs)==1
                    alternatives=[]
                    for tag in 'AB':
                        label=f'Supplementary Figure S{n}{tag}'
                        alternatives.append('<div class="order72k-split-panel"><span class="order72k-panel-tag">'+tag+'</span><img src="'+figure_paths[label]+'" alt="'+html.escape(bylabel[label]['alt'],quote=True)+'"></div>')
                    updated=block.replace(imgs[0].group(),'\n'.join(alternatives))
                else:
                    assert len(imgs)==(2 if n==5 else 1)
                    updated=block
                    for i,m in reversed(list(enumerate(imgs))):
                        label=f'Supplementary Figure S{n}'+('AB'[i] if n==5 else '')
                        updated=updated[:m.start(1)]+figure_paths[label]+updated[m.end(1):]
                changes.append(dict(file=name,old=block,new=updated,reason='accepted display path/split overlay'))
                text=text.replace(block,updated,1)
        texts[name]=text
        save(DEST/name,text)
    for p in (ROOT/'_extensions/kapsner/authors-block').iterdir():
        if p.is_file() and p.suffix in {'.lua','.yml'}: dependency(p)
    dependency(ROOT/'assets/reference.docx')
    copy(LOGICAL/'_quarto.yml',DEST/'_quarto.yml','static_project_config')
    wrapper=(LOGICAL/'supplementary_information_standalone.qmd').read_text()
    old='The multiscale architecture of personal light exposure'
    wrapper=literal(wrapper,old,'The health-relevant architecture of the everyday light exposome','approved standalone subtitle')
    save(DEST/'supplementary_information_standalone.qmd',wrapper)
    # Scoped formatting restores the accepted source sizes after inherited CSS.
    css_path=DEST/'manuscript_displays.css'
    baseline_css=css_path.read_text()
    overlay='''\n/* Order 009: preserve accepted table geometry and typography. */
#supp-table-s2 #near-eye-metric-summary .gt_table,
#supp-table-s2 #near-eye-metric-summary .gt_row,
#supp-table-s2 #near-eye-metric-summary .gt_stub,
#supp-table-s2 #near-eye-metric-summary .gt_col_heading,
#supp-table-s2 #near-eye-metric-summary .gt_group_heading {font-size:16px !important;}
#supp-table-s2 #near-eye-metric-summary {position:relative;max-width:100%;min-width:0;}
#supp-table-s5 *, #supp-table-s6 *, #supp-table-s10 * {font-family:Arial,Helvetica,sans-serif !important;}
.order72k-split-panel {display:block;width:100%;margin:0 0 1.25rem;}
.order72k-panel-tag {display:block;text-align:left;font-weight:700;margin:0 0 .3rem;}
'''
    css_path.write_text(baseline_css+overlay)
    # Store exact baseline and diffs, including every path/split transformation.
    for name,original in original_texts.items():
        save(P/'evidence'/(name+'.baseline'),original)
        save(P/'evidence'/(name+'.diff'),''.join(difflib.unified_diff(original.splitlines(True),texts[name].splitlines(True))))
        reverse=texts[name]
        for change in reversed([r for r in changes if r.get('file')==name]):
            assert change['new'] in reverse
            reverse=reverse.replace(change['new'],change['old'],1)
        assert reverse==original
    save(P/'evidence/manuscript_displays.css.diff',''.join(difflib.unified_diff(baseline_css.splitlines(True),(baseline_css+overlay).splitlines(True))))
    for name in ('run_stage.py','stage_candidates.py','prepare_word_manuscript.py','embed_accepted_svg_figures.py'):
        copy(OLD/name,P/'evidence/helper_baselines'/name,'helper_baseline')
    copy(ROOT/'scripts/manuscript_nature_health/export_editable_tables.py',P/'evidence/helper_baselines/export_editable_tables.py','helper_baseline')
    for name in ('prepare_word_manuscript.py','export_editable_tables.py'):
        base=(P/'evidence/helper_baselines'/name).read_text()
        revised=apply_reviewed_diff(base,(GUIDE/(name+'.diff')).read_text())
        if name=='prepare_word_manuscript.py':
            revised=revised.replace('{7, 15}','{5, 7, 15}')
            revised=revised.replace('{"supp_figure_s7a",','{"supp_figure_s5a", "supp_figure_s5b", "supp_figure_s7a",')
            revised=revised.replace('S7 and S15 each require','S5, S7 and S15 each require')
            revised=revised.replace('expected_images = 23 +','expected_images = 24 +').replace('expected_images != 23 +','expected_images != 24 +')
        else:
            revised=revised.replace('[200, 60, 103] + [96] * 9 + [78, 185]','[210,86,138,146,146,154,138,146,138,146,138,130,120,252]')
            revised=revised.replace('[1.00, 1.75, 1.80, 1.55, 1.55, 1.55, 0.90]','[176,254,230,180,180,200,100]')
            revised=revised.replace('choices=(0,1)','choices=(0,)')
            revised=revised.replace('raise SystemExit("PROSPECTIVE ONLY. Execution requires a separately sealed implementation order.")','main()')
        ast.parse(revised)
        save(P/'helpers'/name,revised)
        save(P/'evidence'/(name+'.diff'),''.join(difflib.unified_diff(base.splitlines(True),revised.splitlines(True))))
    name='embed_accepted_svg_figures.py'; base=(OLD/name).read_text()
    revised=base.replace(' == 22',' == 23').replace(' == 52',' == 54')
    revised=revised.replace('sum(len(record["drawings"]) for record in records) == 23','sum(len(record["drawings"]) for record in records) == 24')
    revised=revised.replace('Order72k non-S5 display-integration candidate, not promoted. Historical Brown S5 and Brown scientific replacement remain held.','Order 009 complete manuscript-plus-SI candidate, not promoted.')
    ast.parse(revised); save(P/'helpers'/name,revised)
    save(P/'evidence'/(name+'.diff'),''.join(difflib.unified_diff(base.splitlines(True),revised.splitlines(True))))
    figures=[]; word=[]
    for r in figure_rows:
        item=dict(r); item['path']=str(DEST/figure_paths[r['word_label']]); item['appearances']=int(r['appearances'])
        figures.append(item)
        if r['word_label'].startswith('Supplementary'):
            word.append(dict(key='supp_figure_'+r['word_label'].split()[-1].lower(),path=item['path']))
    save(P/'maps/expanded_svg_manifest.json',json.dumps(dict(accepted_figures=figures,held_figures=[]),indent=2))
    save(P/'maps/word_figure_svg_manifest.json',json.dumps(word,indent=2))
    # Recursively inspect all copied authoring text without executing it.
    forbidden=[]
    for f in PROJECT.rglob('*'):
        if f.is_file() and f.suffix in {'.qmd','.md','.html','.yml'}:
            t=f.read_text()
            for pattern in (r'```\{(?:r|python|julia)(?:[ ,}]|$)',r'`(?:r|python|julia)\s+[^`]+`',r'(?m)^\s*(?:pre-render|post-render|jupyter|knitr):'):
                if re.search(pattern,t): forbidden.append((str(f),pattern))
    assert not forbidden,forbidden
    save(P/'evidence/staging_copy_map.json',json.dumps(copies,indent=2))
    save(P/'evidence/source_changes.json',json.dumps(changes,indent=2))
    save(P/'evidence/staging_result.json',json.dumps(dict(status='PASS',files=len(copies),executable_units=0,figure_sources=23,figure_appearances=24),indent=2))
    print(json.dumps(dict(status='PASS',static_files=len(copies),project=str(DEST))))

if __name__=='__main__': main()
