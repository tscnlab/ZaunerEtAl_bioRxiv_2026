"""Read-only file/markup reconciliation. No project code or science is executed.

Only this new audit directory receives generated evidence. Hashes, route and
resource resolution, and HTML structure are infrastructure checks, not a
recalculation or scientific validation of the report contents.
"""
from pathlib import Path
import base64
import collections
import csv
import datetime
import hashlib
import json
import os
import re
import sys
from urllib.parse import unquote, urlsplit
from lxml import etree, html

ROOT = Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
OUT = Path(__file__).resolve().parent
assert OUT == ROOT / 'audit/report_harmonization/final_integration_reconciliation_2026_09_14'
BUILD = ROOT / '_build/nathealth'
C = ROOT / 'audit/manuscript_nature_health/final_format_completion_2026_09_14'
P = ROOT / 'audit/manuscript_nature_health/final_review_production_2026_09_14'
OLD = ROOT / 'audit/report_harmonization/final_documents_2026_09_12/harmonizer_transitive_preflight_archival_001/package'
CORPUS = ROOT / 'audit/report_harmonization/phase4_corpus_manifest.csv'
pins = {}

def label(path):
    path = Path(path)
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)

def sha(path):
    with Path(path).open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def pin(path, category):
    path = Path(path)
    key = label(path)
    if key not in pins:
        pins[key] = dict(path=key, exists=path.is_file(), symlink=path.is_symlink(),
                         bytes=path.stat().st_size if path.is_file() else '',
                         sha256=sha(path) if path.is_file() else '', categories=set())
    pins[key]['categories'].add(category)
    return pins[key]

def rows(path):
    pin(path, 'input_manifest')
    with Path(path).open(newline='', encoding='utf-8-sig') as stream:
        return list(csv.DictReader(stream))

def emit(name, data, fields=None):
    path = OUT / name
    assert path.parent == OUT
    if fields is None:
        fields = list(dict.fromkeys(k for row in data for k in row))
    with path.open('w', newline='', encoding='utf-8') as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(data)

def inventory(root, category):
    result = []
    symlinks = []
    for base, dirs, files in os.walk(root, followlinks=False):
        for name in dirs + files:
            path = Path(base) / name
            if path.is_symlink():
                symlinks.append(dict(root=label(root), path=label(path), target=str(path.resolve())))
        dirs[:] = [d for d in dirs if not (Path(base) / d).is_symlink()]
        for name in sorted(files):
            path = Path(base) / name
            if path.is_file() and not path.is_symlink():
                p = pin(path, category)
                result.append(dict(root=label(root), relative=str(path.relative_to(root)),
                                   path=p['path'], bytes=p['bytes'], sha256=p['sha256']))
    return sorted(result, key=lambda x:x['path']), symlinks

build_inventory, symlinks = inventory(BUILD, 'current_build')
corpus = rows(CORPUS)
assert len(corpus) == 37
route_rows = []
old_sources = {r['path']:r for r in rows(OLD / 'ast_files.csv')}
old_authorities = {r['source']:r for r in rows(OLD / 'sixteen_source_authority_disposition.csv')}
for row in corpus:
    src = pin(ROOT / row['source'], 'reader_source')
    page = pin(ROOT / row['expected_html'], 'reader_html')
    older = old_sources.get(row['source'], {})
    authority = old_authorities.get(row['source'], {})
    route_rows.append(dict(logical_order=row['logical_order'], role=row['role'],
        source=row['source'], historical_source_sha256=row['source_sha256'],
        current_source_sha256=src['sha256'], source_matches_historical=src['sha256']==row['source_sha256'],
        source_matches_12sep_audit=src['sha256']==older.get('sha256'),
        expected_html=row['expected_html'], historical_html_sha256=row['html_sha256'],
        current_html_sha256=page['sha256'], html_matches_historical=page['sha256']==row['html_sha256'],
        prior_authority_class=authority.get('classification',''),
        prior_authority_record=authority.get('record',''),
        prior_authority_gap=authority.get('remaining_gate','')))

# Exact current package membership only; no verifier/helper is sourced.
package_checks = []
for r in rows(C / 'completion_manifest.csv'):
    p = pin(C / r['path'], 'accepted_format_package')
    package_checks.append(dict(path=p['path'], expected_sha256=r['sha256'], current_sha256=p['sha256'],
        expected_bytes=r['bytes'], current_bytes=p['bytes'], exact=p['sha256']==r['sha256'] and str(p['bytes'])==r['bytes']))

extra_paths = [
    '_quarto.yml','_quarto-nathealth.yml','styles.css','styles-nathealth.css',
    '_includes/nathealth-mobile-toc.html',
    'scripts/report_harmonization/post_render_gt_html_semantics.R',
    'scripts/report_harmonization/repair_gt_html_semantics.R',
    'scripts/report_harmonization/build_phase4_corpus_manifest.R',
    'scripts/report_harmonization/navigation_integration_support.R',
    'scripts/report_harmonization/build_navigation_shell_candidate.R',
    'scripts/report_harmonization/promote_navigation_candidate_once.R',
    'scripts/report_harmonization/reseal_navigation_manifest_once.R',
    'audit/report_harmonization/nathealth_final_landing_resync_2026_09_03/order71c_resync_verify_promote.R',
    'audit/report_harmonization/report018_navigation_order71c_independent_acceptance.md',
    'audit/report_harmonization/final_documents_2026_09_13/writer010b_independent_completion_disposition.md',
    'audit/report_harmonization/final_documents_2026_09_13/writer_s9_pagination_completion_order_010c.md',
    'manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html',
    'manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx',
    'audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/evidence/cumulative_passage_changes.csv',
    'audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/evidence/cumulative_passage_changes.md',
]
for rel in extra_paths:
    pin(ROOT / rel, 'authority_or_integration_input')

source_inventory=[]
for top in [P/'project', C/'project', ROOT/'manuscript/R0_NatHealth']:
    for path in sorted(top.rglob('*')):
        if path.is_file() and path.suffix in {'.qmd','.yml','.lua','.css'} and not path.is_symlink():
            p=pin(path,'manuscript_source_or_layout')
            text=path.read_text(errors='replace')
            source_inventory.append(dict(path=p['path'],sha256=p['sha256'],bytes=p['bytes'],
                executable_cell_openings=len(re.findall(r'^\s*`{3,}\{(?:r|python|julia)(?:[ ,}])',text,re.M)),
                inline_r_tokens=len(re.findall(r'`r\s',text)),
                include_directives=' | '.join(re.findall(r'\{\{<\s*include\s+([^>]+)>\}\}',text))))

documents={}
doc_rows=[]
payloads=[]
parser=html.HTMLParser(huge_tree=True)
def document(path):
    path=Path(path)
    if path in documents:return documents[path]
    tree=html.fromstring(path.read_bytes(),parser=parser)
    documents[path]=tree
    ids=tree.xpath('//@id')
    counts=collections.Counter(ids)
    title=tree.xpath('string(//title)')
    headers=tree.xpath('//*[@id="quarto-header"]')
    footers=tree.xpath('//footer')
    mains=tree.xpath('//main')
    def hashes(nodes):return '|'.join(hashlib.sha256(etree.tostring(n)).hexdigest() for n in nodes)
    doc_rows.append(dict(path=label(path),title=title,ids=len(ids),duplicate_ids=' | '.join(k for k,v in counts.items() if v>1),
        table_count=len(tree.xpath('//table')),gt_tables=len(tree.xpath('//table[contains(concat(" ",normalize-space(@class)," ")," gt_table ")]')),
        image_count=len(tree.xpath('//img')),script_count=len(tree.xpath('//script')),header_sha256=hashes(headers),footer_sha256=hashes(footers),main_dom_sha256=hashes(mains),
        main_sections=' | '.join(n.get('id','') for n in tree.xpath('//main/section')),
        colgroups=len(tree.xpath('//colgroup')),main_h1_ids=' | '.join(n.get('id','') for n in tree.xpath('//main//h1'))))
    for i,node in enumerate(tree.xpath('//img[starts-with(@src,"data:")]')):
        src=node.get('src')
        meta,data=src.split(',',1)
        if ';base64' in meta:
            raw=base64.b64decode(data)
            payloads.append(dict(path=label(path),image_index=i,mime=meta.split(';')[0][5:],
                                 bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest()))
    return tree

refs=[]
seen_refs=set()
external=[]
closure=set()
def addref(owner,ref,kind,root):
    if not ref or ref.startswith('data:'):return
    ref=ref.strip()
    key=(label(owner),ref,kind)
    if key in seen_refs:return
    seen_refs.add(key)
    try:u=urlsplit(ref)
    except ValueError:
        refs.append(dict(owner=label(owner),reference=ref,kind=kind,status='INVALID_URL'));return
    if u.scheme or u.netloc:
        external.append(dict(owner=label(owner),reference=ref,kind=kind,scheme=u.scheme or 'protocol-relative'));return
    raw=unquote(u.path)
    target=(root/raw.lstrip('/') if raw.startswith('/') else owner.parent/raw) if raw else owner
    target=Path(os.path.normpath(target))
    if target.is_dir():target=target/'index.html'
    within=target.is_relative_to(root)
    status='EXISTS' if target.is_file() else 'MISSING'
    if not within:status='OUTSIDE_PUBLIC_ROOT'
    fragment=unquote(u.fragment)
    fragment_ok=''
    if status=='EXISTS' and fragment and target.suffix.lower()=='.html':
        fragment_ok=fragment in document(target).xpath('//@id')
        if not fragment_ok:status='MISSING_FRAGMENT'
    refs.append(dict(owner=label(owner),reference=ref,kind=kind,target=label(target),fragment=fragment,
                     status=status,fragment_exists=fragment_ok))
    if target.is_file() and within and target!=owner:closure.add(target)

def scan_page(path,root):
    tree=document(path)
    for node in tree.iter():
        if not isinstance(node.tag,str):continue
        for attr in ('href','src','poster','data-src'):
            if node.get(attr):addref(path,node.get(attr),node.tag+'@'+attr,root)
        if node.tag=='object' and node.get('data'):addref(path,node.get('data'),'object@data',root)
        if node.get('srcset') and not node.get('srcset').startswith('data:'):
            for part in node.get('srcset').split(','):addref(path,part.strip().split()[0],'srcset',root)
        style=node.get('style','')
        if node.tag=='style':style+=''.join(node.itertext())
        for match in re.finditer(r'url\(\s*[\"\x27]?([^\"\x27\)\s]+)',style):addref(path,match[1],'css-url',root)

for row in corpus:
    path=ROOT/row['expected_html']
    closure.add(path)
    scan_page(path,BUILD)
if (BUILD/'search.json').is_file():closure.add(BUILD/'search.json')
scanned=set(ROOT/r['expected_html'] for r in corpus)
while closure-scanned:
    path=sorted(closure-scanned)[0];scanned.add(path)
    if path.suffix.lower()=='.css':
        for match in re.finditer(r'(?:url\(\s*|@import\s+)[\"\x27]?([^\"\x27\)\s;]+)',path.read_text(errors='replace')):
            addref(path,match[1],'css-resource',BUILD)
    elif path.suffix.lower()=='.html':scan_page(path,BUILD)

candidate_html=C/'project/html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html'
candidate_refs_start=len(refs)
scan_page(candidate_html,candidate_html.parent)
for path in [ROOT/'manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html']:
    if path.is_file():document(path)

emit('reader_routes.csv',route_rows)
emit('build_inventory.csv',build_inventory)
emit('candidate271_identity_replay.csv',package_checks)
emit('manuscript_source_inventory.csv',source_inventory)
emit('html_structure.csv',doc_rows)
emit('local_reference_audit.csv',refs)
emit('external_references.csv',external)
emit('embedded_image_identities.csv',payloads)
emit('public_dependency_closure.csv',[dict(path=label(p),origin='existing_site' if p.is_relative_to(BUILD) else 'candidate_document',sha256=pin(p,'public_dependency')['sha256'],bytes=p.stat().st_size) for p in sorted(closure)])
emit('symlink_audit.csv',symlinks,['root','path','target'])
emit('input_identities.csv',[{**r,'categories':' | '.join(sorted(r['categories']))} for r in sorted(pins.values(),key=lambda x:x['path'])])
summary=dict(
    checked_at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    command=[sys.executable,str(Path(__file__).resolve())],python=sys.version,lxml=etree.LXML_VERSION,
    scientific_execution=False,project_helper_execution=False,render_or_browser=False,
    build_files=len(build_inventory),build_bytes=sum(r['bytes'] for r in build_inventory),build_symlinks=len(symlinks),
    corpus_sha256=sha(CORPUS),routes=len(route_rows),
    source_hash_mismatches=[r['source'] for r in route_rows if not r['source_matches_historical']],
    source_changes_since_12sep=[r['source'] for r in route_rows if not r['source_matches_12sep_audit']],
    html_hash_mismatches=[r['expected_html'] for r in route_rows if not r['html_matches_historical']],
    candidate271_exact=sum(r['exact'] for r in package_checks),candidate271_rows=len(package_checks),
    candidate_html_sha256=sha(candidate_html),
    local_reference_statuses=dict(collections.Counter(r['status'] for r in refs)),
    candidate_nonfragment_local_references=[r for r in refs[candidate_refs_start:] if r.get('target')!=label(candidate_html)],
    public_closure_files=len(closure),existing_build_closure_files=sum(p.is_relative_to(BUILD) for p in closure),unreferenced_existing_build_files=len(set(BUILD/r['relative'] for r in build_inventory)-closure),
    source_inventory_rows=len(source_inventory),input_pins=len(pins),
    final_word_identity='PENDING_ORDER010C_ACCEPTANCE_NOT_INVENTED',
    limits='Structural and identity checks only. No new visual or scientific acceptance. Dynamic JS dependency behavior is not inferred from static URL scanning.')
(OUT/'inspection_summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
