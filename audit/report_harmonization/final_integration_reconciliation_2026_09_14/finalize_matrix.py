"""Finish a proposed integration matrix from read-only structural evidence.

This does not execute, stage, promote, rewrite or render a website/document.
"""
from pathlib import Path
from urllib.parse import urlsplit, unquote
import collections,csv,hashlib,json,re
from lxml import html,etree

ROOT=Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
OUT=Path(__file__).resolve().parent
BUILD=ROOT/'_build/nathealth'
C=ROOT/'audit/manuscript_nature_health/final_format_completion_2026_09_14'
P=ROOT/'audit/manuscript_nature_health/final_review_production_2026_09_14'
OLD=ROOT/'audit/report_harmonization/final_documents_2026_09_12/harmonizer_transitive_preflight_archival_001/package'
def readcsv(path):
    with Path(path).open(newline='',encoding='utf-8-sig') as f:return list(csv.DictReader(f))
def emit(name,data,fields=None):
    if fields is None:fields=list(dict.fromkeys(k for r in data for k in r))
    with (OUT/name).open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(data)
def label(p):
    try:return str(Path(p).relative_to(ROOT))
    except ValueError:return str(p)
def sha(p):
    with Path(p).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
pins={r['path']:r for r in readcsv(OUT/'input_identities.csv')}
def pin(p,category='additional_read_only_input'):
    p=Path(p);name=label(p)
    if name not in pins:
        pins[name]=dict(path=name,exists=p.is_file(),symlink=p.is_symlink(),bytes=p.stat().st_size if p.is_file() else '',sha256=sha(p) if p.is_file() else '',categories=category)
    return pins[name]

# Compare the complete live build to its accepted historical inventory.
historic=ROOT/'audit/report_harmonization/nathealth_final_landing_resync_2026_09_03/post_promotion_build_inventory.csv'
pin(historic)
expected={r['path']:r for r in readcsv(historic)}
observed={r['relative']:r for r in readcsv(OUT/'build_inventory.csv')}
build_comparison=[]
for name in sorted(set(expected)|set(observed)):
    e=expected.get(name,{});o=observed.get(name,{})
    build_comparison.append(dict(path=name,historical_sha256=e.get('sha256',''),current_sha256=o.get('sha256',''),exact=e.get('sha256')==o.get('sha256') and e.get('bytes')==o.get('bytes')))
emit('historical_build_comparison.csv',build_comparison)
code=[]
for r in readcsv(OLD/'ast_files.csv'):
    p=pin(ROOT/r['path'],'prior_static_code_frontier')
    code.append(dict(path=r['path'],sha256_12sep=r['sha256'],current_sha256=p['sha256'],exact=p['sha256']==r['sha256']))
emit('source54_checkpoint.csv',code)
source_authority=[]
for r in readcsv(OLD/'sixteen_source_authority_disposition.csv'):
    src=pin(ROOT/r['source'])
    authority=pin(ROOT/r['record']) if r['record'] else {}
    source_authority.append(dict(source=r['source'],historical_corpus_source_sha256=r['source_sha256'],
        current_source_sha256=src['sha256'],unchanged_since_prior_audit=src['sha256']==r['live_source_sha256'],
        classification=r['classification'],record=r['record'],record_sha256_prior=r['record_sha256'],
        record_sha256_now=authority.get('sha256',''),record_unchanged=authority.get('sha256','')==r['record_sha256'],
        source_to_output_gap=r['remaining_gate'],
        integration_disposition='Retain accepted historical HTML as an explicitly artifact-backed report. This source gap is not silently cleared and grants no render or owner-dispatch authority.'))
emit('source_transition_status.csv',source_authority)

# Search-index schema and fragment validity, without indexing scientific data.
search_path=BUILD/'search.json';search=json.loads(search_path.read_text())
pin(search_path)
trees={};idsets={}
def tree(path):
    path=Path(path)
    if path not in trees:
        trees[path]=html.fromstring(path.read_bytes(),parser=html.HTMLParser(huge_tree=True))
        idsets[path]=set(trees[path].xpath('//@id'))
    return trees[path]
search_checks=[]
for row in search:
    u=urlsplit(row['href']);p=BUILD/unquote(u.path)
    exists=p.is_file()
    if exists:tree(p)
    search_checks.append(dict(objectID=row['objectID'],href=row['href'],page_exists=exists,
        fragment_exists=not u.fragment or (exists and unquote(u.fragment) in idsets[p]),
        affected_entrypoint=u.path in ('index.html','supplementary_information.html')))
emit('search_entry_audit.csv',search_checks)

candidate=C/'project/html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html'
doc=tree(candidate);si=doc.xpath('//*[@id="supplementary-information"]');assert len(si)==1
si_ids=set(si[0].xpath('.//@id'))|{si[0].get('id')}
si_outbound=sorted(set(a[1:] for a in si[0].xpath('.//@href') if a.startswith('#') and a[1:] not in si_ids))
node_rows=[]
for page in [BUILD/'index.html',BUILD/'supplementary_information.html',candidate]:
    d=tree(page)
    for kind,xpath in [('main','//main'),('toc','//nav[@id="TOC"]'),('header','//*[@id="quarto-header"]'),('footer','//footer'),('page_navigation','//nav[contains(@class,"page-navigation")]'),('custom_style','//head/style[contains(text(),"div.manuscript-table")]')]:
        for number,node in enumerate(d.xpath(xpath)):
            raw=etree.tostring(node)
            node_rows.append(dict(path=label(page),component=kind,index=number,serialized_bytes=len(raw),dom_sha256=hashlib.sha256(raw).hexdigest(),note='Structural DOM digest, not a raw byte-boundary extraction or visual acceptance'))
emit('integration_component_identities.csv',node_rows)

# Read-only authority pins and exact downstream bindings, no copying.
extra=[
 'audit/report_harmonization/final_documents_2026_09_13/writer010b_independent_completion_manifest.csv',
 'audit/report_harmonization/final_documents_2026_09_13/h09_s15b_candidate_acceptance_010a.md',
 'audit/decisions/brown_main_linkage_b_report_finishing_007/author_review_closure_and_writer_release.md',
 'audit/report_harmonization/navigation_mobile_toc_collapse_repair_2026_09_02/order67a_clone_state_repair/legacy_duplicate_id_multiset.csv',
 'audit/report_harmonization/navigation_mobile_toc_collapse_repair_2026_09_02/order67a_clone_state_repair/legacy_duplicate_id_route_summary.csv',
 'audit/report_harmonization/navigation_mobile_toc_collapse_repair_2026_09_02/order67a_clone_state_repair/production_browser_route_qa.json',
 'audit/manuscript_nature_health/final_review_production_2026_09_14/evidence/source_changes.json',
 'audit/manuscript_nature_health/final_review_production_2026_09_14/evidence/preflight_result.json',
 'audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/source/ZaunerEtAl2026_NatHealth_phase3_brown.qmd',
 'audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/source/supplementary_information_outline.qmd',
]
for rel in extra:pin(ROOT/rel)
brown_root=Path('/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence')
for rel in ['13_cross_state_association_results_amendment.qmd','13_cross_state_association_results_amendment.html','14_cross_state_association_preparation_and_provenance.qmd','14_cross_state_association_preparation_and_provenance.html']:
    pin(brown_root/rel,'accepted_Brown_reference_not_a_37_route_publish_target')

matrix=[]
def action(key,target,source,operation,scope,check,owner='Coordinator-designated site integration owner'):
    current=pin(ROOT/target,'proposed_target_preimage')
    matrix.append(dict(key=key,target=target,current_exists=current['exists'],preimage_sha256=current['sha256'],
        source=source,source_sha256=pin(ROOT/source)['sha256'] if source and not source.startswith('PENDING') and (ROOT/source).is_file() else ('PENDING_ORDER010C' if source.startswith('PENDING') else 'DERIVED_AFTER_RELEASE'),
        proposed_action=operation,scope=scope,acceptance_check=check,owner=owner,
        release_status='PROPOSED_ONLY_NOT_AUTHORIZED_OR_EXECUTED'))
action('main_entry','_build/nathealth/index.html',label(candidate),'STATIC_TRANSPLANT_AND_SITE_UTILITY_PANEL',
       'Exact accepted main content, title/author metadata and custom display CSS; retain historical site shell/scripts; refresh TOC; append distinct download links',
       'Raw reversal; accepted main and all display payloads preserved; shell exact outside approved slots; all links/IDREFs resolve')
action('supplement_entry','_build/nathealth/supplementary_information.html',label(candidate),'STATIC_SUPPLEMENT_EXTRACTION_AND_RESOURCE_PANEL',
       'Exact section#supplementary-information including 16 semantic tables; retain existing supplementary site shell; add 19 table links and exact position/old/new table',
       'Exact SI content and display payloads; complete fragment closure; preserve utility/source distinction; desktop/narrow full-page QA')
action('word_download','_build/nathealth/ZaunerEtAl2026_NatHealth_phase3_brown.docx','PENDING_ORDER010C_FINAL_ACCEPTED_WORD','BYTE_EXACT_REPLACEMENT',
       'Only final independently accepted 010c Word, never current C/d6dd4180 or the historical 74193a7a download',
       'Record final source path/full SHA/size and acceptance seal before staging; source and published download byte-identical')
action('search_index','_build/nathealth/search.json','','STATIC_REINDEX_EXACT_37_READER_HTML_ROUTES',
       'Preserve objectID/href/title/section/text/crumbs schema; regenerate records from the 37 exact staged reader HTML pages only because the old index contains stale anchors across many routes and non-reader entries; do not render or alter report pages',
       'Unique objectIDs; all 37 readers represented; every href/fragment resolves; text derived only from accepted staged DOM; no non-reader/internal-workflow results or analytical execution')
native_order=['Table_1','Table_2','Table_3','Table_S1','Table_S2','Table_S3','Table_S4','Table_S5','Table_S6','Table_S7','Table_S8','Table_S9','Table_S10','Table_S11a','Table_S11b','Table_S12','Table_S13','Table_S14','Table_S15']
native=[]
for name in native_order:
    source=C/'editable_tables'/f'{name}.docx';p=pin(source)
    action('editable_'+name,f'_build/nathealth/editable_tables/{name}.docx',label(source),'BYTE_EXACT_ADDITION','Accepted native one-table file only; do not export/render or copy absolute-path provenance metadata','19/19 hashes and download anchors; one link per requested native table')
    native.append(dict(name=name,source=label(source),sha256=p['sha256'],bytes=p['bytes'],public_target=f'editable_tables/{name}.docx'))
change_root=ROOT/'audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/evidence'
change_rows=readcsv(change_root/'cumulative_passage_changes.csv')
for ext in ['csv','md']:
    action('passage_change_'+ext,f'_build/nathealth/manuscript_changes.{ext}',label(change_root/f'cumulative_passage_changes.{ext}'),'BYTE_EXACT_ADDITION','Existing accepted passage-change artifact, no prose revision','Exact file identity; visible position/old_text/new_text fields retain all 20 ordered source rows')
action('corpus_reseal','audit/report_harmonization/phase4_corpus_manifest.csv','','TWO_HTML_HASH_ONLY_RESEAL_WITH_ADDITIVE_AUTHORITY_SIDECAR',
       '37 rows/order and all historical source metadata preserved; update only index/SI html_sha256 after accepted staging; new sidecar states accepted HTML authority and current source gaps',
       'Raw reverse to current 01a2fdc1...; exactly two changed HTML cells; all 37 live output hashes match; never run the generic manifest builder against changed live sources',
       'Coordinator or explicitly designated manifest owner')
emit('proposed_integration_matrix.csv',matrix)
emit('editable_table_bindings.csv',native)

# Extend the initial input pin set, then prove read-only preservation.
post=[]
for row in sorted(pins.values(),key=lambda r:r['path']):
    p=Path(row['path']) if row['path'].startswith('/') else ROOT/row['path']
    exists=p.is_file();observed_sha=sha(p) if exists else ''
    post.append(dict(path=row['path'],initial_sha256=row['sha256'],final_sha256=observed_sha,
        initially_exists=str(row['exists']).lower()=='true',finally_exists=exists,
        exact=observed_sha==row['sha256'] and exists==(str(row['exists']).lower()=='true')))
emit('input_identities.csv',sorted(pins.values(),key=lambda r:r['path']))
emit('read_only_postflight.csv',post)
summary=dict(
    historical_build_files=len(build_comparison),historical_build_exact=sum(r['exact'] for r in build_comparison),
    code_frontier_files=len(code),code_frontier_exact=sum(r['exact'] for r in code),
    source_authority_records_changed=[r['record'] for r in source_authority if r['record'] and not r['record_unchanged']],
    search_entries=len(search),search_entrypoint_records=sum(r['affected_entrypoint'] for r in search_checks),
    search_broken_fragments=len([r for r in search_checks if not r['fragment_exists']]),
    search_broken_fragment_routes=sorted(set(r['href'].split('#')[0] for r in search_checks if not r['fragment_exists'])),
    search_nonreader_routes=sorted(set(r['href'].split('#')[0] for r in search_checks)-set(r['expected_html'].removeprefix('_build/nathealth/') for r in readcsv(OUT/'reader_routes.csv'))),
    si_boundary_id='supplementary-information',si_semantic_tables=len(si[0].xpath('.//table')),
    si_outbound_fragment_ids=si_outbound,passage_change_rows=len(change_rows),
    proposed_targets=len(matrix),proposed_build_replacements=4,proposed_build_additions=21,proposed_build_total=914,
    native_table_files=len(native),read_only_pins=len(post),read_only_pins_exact=sum(r['exact'] for r in post),
    final_word='PENDING_ORDER010C_ACCEPTANCE',no_packaging_or_render_executed=True,
    note='The 26-target matrix is a finite proposal, including one live corpus manifest, not an implementation release. New audit/stage/backup evidence has its own future bounded root.')
(OUT/'matrix_summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
