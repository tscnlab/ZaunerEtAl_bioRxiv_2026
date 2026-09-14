"""Stage finite byte-exact format inputs. Does not render or analyse data."""
from pathlib import Path
import hashlib, json, shutil, csv

C=Path(__file__).resolve().parents[1]
ROOT=C.parents[2]
P=C.parent/'final_review_production_2026_09_14'
assert ROOT.name=='ZaunerEtAl_bioRxiv_2026'
assert not (C/'evidence/source_to_copy.csv').exists()
for sub in ('inputs','project','production_images','maps','editable_tables','deliverables','qa'):
    (C/sub).mkdir(exist_ok=True)
records=[]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def copy(src,dst,expected=None):
    src=Path(src); dst=Path(dst)
    assert src.is_file() and not src.is_symlink() and not dst.exists()
    if expected: assert sha(src)==expected,(str(src),sha(src),expected)
    dst.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(src,dst)
    assert sha(src)==sha(dst)
    records.append(dict(source=str(src),copy=str(dst),sha256=sha(dst),bytes=dst.stat().st_size))
    return dst
copy(P/'project/manuscript/R0_NatHealth/render_docx_round1/ZaunerEtAl2026_NatHealth_phase3_brown.docx',C/'inputs/raw_static.docx')
copy(P/'deliverables/Nature_Health_manuscript_round2.docx',C/'inputs/prior_main.docx','3f33431ed4e85b042f8a98e232b25b9617d8dae16bc8eff8df9595c05a80d611')
copy(P/'project/manuscript/R0_NatHealth/render_html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html',C/'inputs/prior_integrated.html','0488130aba3ef7b043c743ee879d6e88f9c2ece8ae3c0c2eba89d90e116ea510')
copy(ROOT/'manuscript/R0_NatHealth/display_assets/table_s3_recommendation_windows.html',C/'inputs/table_s3_original.html','33ebc99f976acffb54082eb7afd4a6b44549b3f9de330dea998ce2f69c4ba6e6')
for name in ('prepare_word_manuscript.py','embed_accepted_svg_figures.py'):
    copy(P/'helpers'/name,C/'helpers'/name)
copy(P/'maps/part_count_contract.json',C/'maps/part_count_contract.json')
tables=json.loads((P/'maps/word_table_png_manifest.json').read_text())
for table in tables:
    for part in table['files']:
        old=Path(part['path']);part['previous_path']=str(old)
        if table['key']=='supp_table_s3':
            part['previous_sha256']=part['sha256'];part['sha256']=None
            part['path']=str(C/'production_images/supp_table_s3_part_01.png')
        else: part['path']=str(copy(old,C/'production_images'/old.name,part['sha256']))
(C/'maps/word_table_png_manifest.pending.json').write_text(json.dumps(tables,indent=2)+'\n')
figs=json.loads((P/'maps/expanded_svg_manifest.json').read_text())
rebase={}
for fig in figs['accepted_figures']:
    old=fig['path'];src=Path(old);expected=fig['sha256']
    if fig['word_label']=='Supplementary Figure S15B':
        src=ROOT/'audit/hypotheses/H09/manuscript_s15b_strip_layout_2026_09_14/candidate/H09_observed_timing_patterns.svg'
        expected='0a3d0cabcd6cdb67db072cfa566448a885a774db519bea442a973896a7d616e8'
        fig['previous_sha256']=fig['sha256'];fig['sha256']=expected;fig['source_path']=str(src)
    dest=copy(src,C/'project/accepted_figures'/src.name,expected)
    rebase[old]=str(dest);fig['path']=str(dest)
(C/'maps/expanded_svg_manifest.json').write_text(json.dumps(figs,indent=2)+'\n')
wm=json.loads((P/'maps/word_figure_svg_manifest.json').read_text())
for f in wm: f['path']=rebase[f['path']]
(C/'maps/word_figure_svg_manifest.json').write_text(json.dumps(wm,indent=2)+'\n')
native=P/'editable_tables/round2'
for f in sorted(native.glob('Table*.docx')):copy(f,C/'editable_tables'/f.name)
assert len(list((C/'editable_tables').glob('*.docx')))==19
for name in ('table_manifest.json','export_provenance.json'):
    old=(native/name).read_text()
    # Preserve scientific provenance and old input paths; rebase only output file locations.
    new=old.replace(str(native),str(C/'editable_tables'))
    (C/'editable_tables'/name).write_text(new)
(C/'editable_tables/README.md').write_text('# Editable manuscript tables\n\nAll 19 native Word tables are byte-exact copies of the accepted Order009 set. No re-export, font change, scientific change or new native-table conversion was performed. Their prior native visual QA and the author-approved S2 font size remain controlling. Table S11 has two separately editable files.\n')
with (C/'evidence/source_to_copy.csv').open('w') as f:
    w=csv.DictWriter(f,fieldnames=['source','copy','sha256','bytes']);w.writeheader();w.writerows(records)
print(json.dumps(dict(exact_copies=len(records),unchanged_png_parts=29,svg_sources=23,native_tables=19)))
