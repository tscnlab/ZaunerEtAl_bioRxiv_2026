"""Copy 17 identity-verified native documents; never re-export them."""
import csv, hashlib, json, shutil
from pathlib import Path
P=Path(__file__).resolve().parents[1]
ROOT=P.parents[2]
OUT=P/'editable_tables'
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert json.loads((P/'evidence/html_semantic_pass.json').read_text())['status']=='PASS'
old=json.loads((ROOT/'manuscript/R0_NatHealth/editable_tables/table_manifest.json').read_text())
prior=json.loads((P/'evidence/17_native_prior_visual_reuse.json').read_text())
maps={r['label']:r for r in csv.DictReader((P/'maps/native_table_dispositions.csv').open())}
assert len(old)==19 and len(prior)==17
OUT.mkdir(exist_ok=True)
assert not list(OUT.glob('*.docx'))
manifest=[]; provenance=[]
for record in old:
    label=record['label']
    if label in ('Table_2','Table_S2'): continue
    src=Path(record['path']); dst=OUT/src.name
    assert sha(src)==record['sha256']==maps[label]['current_editable_docx_sha256']==prior[label]['sha256']
    shutil.copyfile(src,dst)
    assert sha(dst)==record['sha256']
    current=dict(record)
    current.update(path=str(dst),production_action='byte-exact reuse, not a new export',original_export_path=str(src))
    manifest.append(current)
    provenance.append(dict(label=label,action='byte-exact reuse',original_path=str(src),candidate_path=str(dst),sha256=sha(dst),source_fragment=maps[label]['candidate_source'],source_fragment_sha256=maps[label]['candidate_source_sha256'],prior_visual_qa=prior[label]['prior_pages']))
assert len(manifest)==17
(OUT/'table_manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n')
html=json.loads((P/'evidence/html_semantic_pass.json').read_text())
metadata=dict(candidate_html=html['html'],candidate_html_sha256=html['sha256'],new_exports=['Table_2','Table_S2'],new_export_metadata='Recorded in table_manifest.json by the single current export',reused=provenance,reference_docx=str(P/'project/assets/reference.docx'),reference_sha256=sha(P/'project/assets/reference.docx'),scientific_recalculation=False)
(OUT/'export_provenance.json').write_text(json.dumps(metadata,indent=2,ensure_ascii=False)+'\n')
(P/'evidence/native_reuse_seed.json').write_text(json.dumps(dict(status='PASS',reused=17,new_exports_pending=2,documents=provenance),indent=2,ensure_ascii=False)+'\n')
print('PASS: 17 native Word tables copied byte-exact; two current exports pending.')
