"""Order015 candidate-only infrastructure. No research calculations or output transformations."""
from pathlib import Path
import csv, hashlib, json, os, datetime
ROOT=Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
T=ROOT/'audit/report_harmonization/final_site_a4_delta_2026_09_14'
OUT=T/'verification_recovery_015a'
OLD=ROOT/'audit/report_harmonization/final_site_integration_2026_09_14'
E=OUT/'evidence'
LIVE=ROOT/'_build/nathealth'
CORPUS=ROOT/'audit/report_harmonization/phase4_corpus_manifest.csv'
CONTROL=ROOT/'audit/report_harmonization/final_documents_2026_09_13'
assert Path(__file__).resolve().parent==OUT/'helpers'
def utc():return datetime.datetime.now(datetime.timezone.utc).isoformat()
def sha(p):
    with Path(p).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def rows(p):
    with Path(p).open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))
def label(p):
    p=Path(p)
    return str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else str(p)
def safe(p):
    p=Path(p);assert p.is_relative_to(OUT),p
    p.parent.mkdir(parents=True,exist_ok=True);return p
def dump(p,obj):safe(p).write_text(json.dumps(obj,indent=2,ensure_ascii=False)+'\n')
def csvout(p,data):
    with safe(p).open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=list(data[0]));w.writeheader();w.writerows(data)
def inv(root):
    result=[]
    for p in sorted(Path(root).rglob('*')):
        assert not p.is_symlink(),p
        if p.is_file():result.append(dict(path=str(p.relative_to(root)),bytes=p.stat().st_size,sha256=sha(p)))
    return result
def parsed_inv(path):return [dict(path=r['path'],bytes=int(r['bytes']),sha256=r['sha256']) for r in rows(path)]
def checked_path(p):
    p=Path(p);assert p.is_absolute() and p.is_relative_to(ROOT),p
    assert '..' not in p.parts
    for q in [p,*p.parents]:
        if q==ROOT.parent:break
        assert not q.is_symlink(),q
    return p
def exact(p,digest,size=None):
    p=Path(p)
    if p.is_relative_to(ROOT):p=checked_path(p)
    else:assert p.is_absolute() and '..' not in p.parts and not p.is_symlink(),p
    return p.is_file() and (size is None or p.stat().st_size==int(size)) and sha(p)==digest
PROM=ROOT/'audit/report_harmonization/final_site_promotion_2026_09_14'
WRITER=ROOT/'audit/manuscript_nature_health/a4_display_revision_2026_09_14'
DELTA=WRITER/'html_candidate_round2'
BUILD=T/'candidate_build'
MATRIX=CONTROL/'site_delta_candidate_order_015_target_matrix.csv'
def plan_rows():
    data=rows(MATRIX);assert len(data)==6 and len({r['target'] for r in data})==6
    for r in data:
        checked_path(ROOT/r['target']);assert r['target'].startswith('_build/nathealth/') and r['action']=='replace'
        r['bytes']=int(r['bytes'])
    return data
