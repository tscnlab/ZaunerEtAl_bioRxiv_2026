"""Order015 candidate-only infrastructure. No research calculations or output transformations."""
from pathlib import Path
import csv, hashlib, json, os, datetime
ROOT=Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
T=ROOT/'audit/report_harmonization/final_site_a4_delta_2026_09_14'
REC=T/'verification_recovery_015a'
OUT=ROOT/'audit/report_harmonization/final_site_a4_promotion_2026_09_14'
OLD=ROOT/'audit/report_harmonization/final_site_integration_2026_09_14'
LIVE=ROOT/'_build/nathealth'
CORPUS=ROOT/'audit/report_harmonization/phase4_corpus_manifest.csv'
TX=Path(os.environ.get('ORDER016_TX_ROOT',str(OUT)))
assert TX in (OUT,OUT/'fixtures/full')
IS_FIXTURE=TX!=OUT
E=TX/'evidence'
ACTIVE_SITE=TX/'live_site' if IS_FIXTURE else LIVE
ACTIVE_CORPUS=TX/'corpus.csv' if IS_FIXTURE else CORPUS
BASELINE=OLD/'candidate_build'
PRECORPUS=T/'preimages'/str(CORPUS.relative_to(ROOT))
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
CANDIDATE=T/'candidate_build'
BUILD=ACTIVE_SITE
MATRIX=CONTROL/'site_delta_candidate_order_015_target_matrix.csv'
def plan_rows():
    data=rows(MATRIX);assert len(data)==6 and len({r['target'] for r in data})==6
    for r in data:
        checked_path(ROOT/r['target']);assert r['target'].startswith('_build/nathealth/') and r['action']=='replace'
        r['bytes']=int(r['bytes'])
    return data

def transaction_rows():
    data=rows(REC/'evidence/website_promotion_manifest.csv')
    allowed=['index.html','supplementary_information.html','ZaunerEtAl2026_NatHealth_phase3_brown.docx','editable_tables/Table_S4.docx','editable_tables/Table_S7.docx','search.json']
    assert [r['target'] for r in data]==['_build/nathealth/'+x for x in allowed]
    backups={r['live_target']:r for r in rows(REC/'evidence/seven_backup_manifest.csv')}
    result=[]
    for i,r in enumerate(data,1):
        b=backups[r['target']]
        assert r['action']=='replace' and b['sha256']==r['preimage_sha256']
        assert ROOT/r['candidate']==CANDIDATE/allowed[i-1]
        result.append(dict(sequence=i,target=r['target'],source=r['candidate'],bytes=int(r['bytes']),post_sha256=r['candidate_sha256'],pre_sha256=r['preimage_sha256'],pre_bytes=int(b['bytes']),historical_backup=b['backup'],action='replace'))
    b=backups[label(CORPUS)]
    result.append(dict(sequence=7,target=label(CORPUS),source=label(REC/'evidence/phase4_corpus_manifest.prospective.csv'),bytes=11479,post_sha256='642161dfc1ec18572b8b8c124546060c8f889683ebf7ceb8e5e43dc785f77669',pre_sha256='b5b4b009db76e6f869f324a360e6eeafdf63438539382f1b8d85058f277eb93f',pre_bytes=int(b['bytes']),historical_backup=b['backup'],action='replace'))
    assert len(result)==len({r['target'] for r in result})==7
    for r in result:
        checked_path(ROOT/r['target']);checked_path(ROOT/r['source']);checked_path(ROOT/r['historical_backup'])
    return result

def target_path(logical):
    p=Path(logical);p=p if p.is_absolute() else ROOT/p
    if p.is_relative_to(LIVE):return checked_path(ACTIVE_SITE/p.relative_to(LIVE))
    if p==CORPUS:return checked_path(ACTIVE_CORPUS)
    if p.is_relative_to(ROOT):return checked_path(p)
    approved_external={Path(r['path']) for r in rows(REC/'evidence/post_protected_checks.csv') if Path(r['path']).is_absolute() and not Path(r['path']).is_relative_to(ROOT)}
    assert p in approved_external and '..' not in p.parts
    assert not any(q.is_symlink() for q in [p,*p.parents])
    return p

def helper_checkpoint():
    data=rows(OUT/'evidence/helper_manifest.csv')
    assert len(data)==len({r['path'] for r in data})
    assert {r['path'] for r in data}=={label(p) for p in (OUT/'helpers').iterdir() if p.is_file()}
    for r in data:assert exact(ROOT/r['path'],r['sha256'],r['bytes'])
