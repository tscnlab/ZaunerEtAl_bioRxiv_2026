"""Order017 infrastructure only. No analytical execution or result changes."""
from pathlib import Path
import csv, json, hashlib, os, datetime

ROOT = Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
OUT = ROOT / 'audit/report_harmonization/final_site_reader_cleanup_2026_09_14'
CONTROL = ROOT / 'audit/report_harmonization/final_documents_2026_09_13'
AUDIT = CONTROL / 'reader_scope_017_independent/owner_readonly'
O16 = ROOT / 'audit/report_harmonization/final_site_a4_promotion_2026_09_14'
LIVE = ROOT / '_build/nathealth'
PROFILE = '_quarto-nathealth.yml'
CORPUS = 'audit/report_harmonization/phase4_corpus_manifest.csv'
CAND = OUT / 'candidate_build'
E = OUT / 'evidence'
VOID = set('area base br col embed hr img input link meta param source track wbr'.split())

def utc(): return datetime.datetime.now(datetime.timezone.utc).isoformat()
def sha(p):
    with Path(p).open('rb') as f: return hashlib.file_digest(f, 'sha256').hexdigest()
def hashbytes(b): return hashlib.sha256(b).hexdigest()
def readcsv(p):
    with Path(p).open(newline='', encoding='utf-8-sig') as f: return list(csv.DictReader(f))
def owned(p):
    p = Path(p)
    assert p.is_absolute() and p.is_relative_to(OUT) and '..' not in p.parts, p
    p.parent.mkdir(parents=True, exist_ok=True)
    return p
def dump(p, obj): owned(p).write_text(json.dumps(obj, indent=2, ensure_ascii=False) + '\n')
def csvout(p, data, fields=None):
    with owned(p).open('w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=fields or list(data[0])); w.writeheader(); w.writerows(data)
def checked(p):
    p = Path(p); assert p.is_absolute() and '..' not in p.parts, p
    assert not any(q.is_symlink() for q in [p, *p.parents]), p
    return p
def exact(p, h, n=None):
    p = checked(p)
    return p.is_file() and (n is None or p.stat().st_size == int(n)) and sha(p) == h
def inventory(root):
    root = checked(root); assert root.is_dir(), root
    data = []
    for p in sorted(root.rglob('*')):
        assert not p.is_symlink(), p
        if p.is_file(): data.append(dict(path=str(p.relative_to(root)), bytes=p.stat().st_size, sha256=sha(p)))
    return data
def invmap(root): return {r['path']: r for r in inventory(root)}
def csvmap(p): return {r['path']: dict(path=r['path'], bytes=int(r['bytes']), sha256=r['sha256']) for r in readcsv(p)}
def site_for(mode):
    assert mode in ('candidate', 'fixture', 'live')
    return {'candidate': CAND, 'fixture': OUT/'fixture/_build/nathealth', 'live': LIVE}[mode]
def target(logical, mode):
    assert mode in ('candidate', 'fixture', 'live') and not Path(logical).is_absolute() and '..' not in Path(logical).parts
    if mode == 'live': return checked(ROOT/logical)
    if mode == 'fixture': return checked(OUT/'fixture'/logical)
    if logical.startswith('_build/nathealth/'): return checked(CAND/Path(logical).relative_to('_build/nathealth'))
    return checked(OUT/'postimages'/logical)
def plan(): return json.loads((E/'transaction_plan.json').read_text())
def helper_check():
    m=readcsv(E/'helper_manifest.csv')
    assert {r['path'] for r in m} == {str(p.relative_to(OUT)) for p in (OUT/'helpers').iterdir() if p.is_file()}
    assert all(exact(OUT/r['path'],r['sha256'],r['bytes']) for r in m)
    assert invmap(OUT/'inputs')==csvmap(E/'copied_input_manifest.csv')
def jsonl(p, row):
    with owned(p).open('a', encoding='utf-8') as f:
        f.write(json.dumps(dict(utc=utc(), **row), ensure_ascii=False)+'\n'); f.flush(); os.fsync(f.fileno())
