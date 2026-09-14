"""Order011 static infrastructure; writes are confined to this new audit root."""
from pathlib import Path
import csv, hashlib, json, re
from lxml import etree, html

ROOT=Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
OUT=ROOT/'audit/report_harmonization/final_site_integration_2026_09_14'
assert Path(__file__).resolve().parent==OUT/'helpers'
LIVE=ROOT/'_build/nathealth'
BUILD=OUT/'candidate_build'
EVIDENCE=OUT/'evidence'
PROPOSAL=ROOT/'audit/report_harmonization/final_integration_reconciliation_2026_09_14'
C=ROOT/'audit/manuscript_nature_health/final_format_completion_2026_09_14'
F=ROOT/'audit/manuscript_nature_health/final_pagination_completion_2026_09_14'
CONTROL=ROOT/'audit/report_harmonization/final_documents_2026_09_13'
ACCEPTED=C/'project/html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html'
WORD=F/'deliverables/Nature_Health_manuscript.docx'
CORPUS=ROOT/'audit/report_harmonization/phase4_corpus_manifest.csv'
WORD_SHA='325c3a8e3a76ea225970f80e177ceed0bbdd592b72e79196d154597f3581250b'

def sha(path):
    with Path(path).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def digest(data):return hashlib.sha256(data).hexdigest()
def rows(path):
    with Path(path).open(newline='',encoding='utf-8-sig') as f:return list(csv.DictReader(f))
def label(path):
    p=Path(path)
    return str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else str(p)
def safe(path):
    p=Path(path)
    assert p.is_relative_to(OUT),p
    p.parent.mkdir(parents=True,exist_ok=True)
    return p
def write_json(path,obj):safe(path).write_text(json.dumps(obj,indent=2,ensure_ascii=False)+'\n')
def write_csv(path,data,fields=None):
    if fields is None:fields=list(dict.fromkeys(k for r in data for k in r))
    with safe(path).open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(data)
def doc(path):return html.fromstring(Path(path).read_bytes(),parser=html.HTMLParser(huge_tree=True,encoding='utf-8'))
def one(nodes):assert len(nodes)==1,len(nodes);return nodes[0]
def span(raw,tag,element_id=None):
    starts=list(re.finditer(r'<'+tag+r'\b[^>]*>',raw,re.I))
    if element_id is not None:
        starts=[m for m in starts if re.search(r'\bid=["\x27]'+re.escape(element_id)+r'["\x27]',m[0])]
    assert len(starts)==1,(tag,element_id,len(starts))
    start=starts[0];level=1
    for token in re.finditer(r'</?'+tag+r'\b[^>]*>',raw[start.end():],re.I):
        level+=-1 if token[0].startswith('</') else 1
        if level==0:return (start.start(),start.end()+token.end())
    raise AssertionError(('unclosed',tag,element_id))
def segment(raw,tag,element_id=None):
    a,b=span(raw,tag,element_id);return raw[a:b]
def inner(raw,tag,element_id=None):
    s=segment(raw,tag,element_id);return s[s.index('>')+1:s.rfind('</'+tag)]
def inventory(root):
    result=[]
    for p in sorted(Path(root).rglob('*')):
        assert not p.is_symlink(),p
        if p.is_file():result.append(dict(path=str(p.relative_to(root)),bytes=p.stat().st_size,sha256=sha(p)))
    return result
