"""Preserve eighteen exact documents and prepare the S2-only correction export."""
import hashlib,json,shutil
from pathlib import Path
P=Path(__file__).resolve().parents[1]
OUT=P/'editable_tables/round2'
assert not OUT.exists()
assert json.loads((P/'evidence/html_semantic_pass_round2.json').read_text())['status']=='PASS'
OUT.mkdir()
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
records=json.loads((P/'editable_tables/table_manifest.json').read_text())
kept=[]
for r in records:
    if r['label']=='Table_S2':continue
    src=Path(r['path']);dst=OUT/src.name
    assert sha(src)==r['sha256']
    shutil.copyfile(src,dst)
    assert sha(dst)==r['sha256']
    r=dict(r,previous_candidate_path=str(src),path=str(dst),round2_action='byte-exact reuse')
    kept.append(r)
assert len(kept)==18
(OUT/'table_manifest.json').write_text(json.dumps(kept,indent=2,ensure_ascii=False)+'\n')
shutil.copyfile(P/'editable_tables/README.md',OUT/'README.md')
provenance=json.loads((P/'editable_tables/export_provenance.json').read_text())
provenance['round2']=dict(action='Table_S2-only native spacing correction',input_html=json.loads((P/'evidence/html_semantic_pass_round2.json').read_text()),unchanged_Table2_sha256=next(r['sha256']for r in kept if r['label']=='Table_2'),eighteen_byte_exact_reuses=kept,fontsize_reduction=False)
(OUT/'export_provenance.json').write_text(json.dumps(provenance,indent=2,ensure_ascii=False)+'\n')
print('PASS:18 exact native documents staged; S2-only correction export pending.')
