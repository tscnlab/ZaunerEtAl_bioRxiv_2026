"""Consolidate exact reference removals and unresolved reader-scope items, without constructing a candidate."""
from pathlib import Path
import csv,json,hashlib,re,collections,posixpath,urllib.parse
from lxml import html,etree
ROOT=Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
SITE=ROOT/'_build/nathealth';OUT=Path('/private/tmp/reader-scope-audit-20260914.nnDbyu')
def read(n):return list(csv.DictReader((OUT/n).open()))
def put(n,rows):
    assert not (OUT/n).exists()
    if n.endswith('.json'):(OUT/n).write_text(json.dumps(rows,indent=2));return
    keys=list(dict.fromkeys(k for r in rows for k in r))
    with (OUT/n).open('w') as f:w=csv.DictWriter(f,fieldnames=keys);w.writeheader();w.writerows(rows)
links=read('all_local_references.csv');inv=read('live_inventory_before.csv');by={r['path']:r for r in inv}
sens='notebooks/sensitivity_battery.html';prefix='notebooks/sensitivity_battery_files/'
retire=[sens,'manuscript_changes.csv','manuscript_changes.md']+[r['path'] for r in inv if r['path'].startswith(prefix)]
inbound=[r for r in links if r['target']==sens and r['route']!=sens]
put('sensitivity_inbound_exact.csv',inbound)
utility=[r for r in links if r['target'] in ['manuscript_changes.csv','manuscript_changes.md'] or r['fragment']=='site-passage-changes']
put('passage_inbound_exact.csv',utility)
support=[]
for target in retire:
    rs=[r for r in links if r['target']==target]
    support.append(dict(**by[target],reason='withdrawn planned-sensitivity page' if target==sens else 'editorial passage-change copy' if target.startswith('manuscript_changes') else 'dedicated support of withdrawn page',html_inbound_count=len(rs),html_inbound_owners='|'.join(sorted(set(r['route'] for r in rs))),inbound_from_retained_html='|'.join(sorted(set(r['route'] for r in rs if r['route'] not in retire)))))
put('proposed_public_retirements.csv',support)
raw_hits=[]
needles=['sensitivity_battery','manuscript_changes','site-passage-changes','H03-H11_gated_workflow','implementation_result_comparison_contract']
for r in inv:
    if Path(r['path']).suffix.lower() not in ['.html','.css','.js','.json','.xml','.qmd','.md','.csv','.txt']:continue
    b=(SITE/r['path']).read_bytes()
    for needle in needles:
        count=b.count(needle.encode())
        if count:raw_hits.append(dict(path=r['path'],needle=needle,raw_occurrences=count))
put('named_target_raw_references.csv',raw_hits)
supportrefs=[]
for r in inv:
    if not r['path'].endswith('.css'):continue
    text=(SITE/r['path']).read_text(errors='replace')
    for m in re.finditer(r'(?:url\(\s*|@import\s+)["\x27]?([^"\x27\)\s;]+)',text):
        ref=m[1];u=urllib.parse.urlsplit(ref)
        if u.scheme or ref.startswith('data:'):continue
        target=posixpath.normpath(posixpath.join(posixpath.dirname(r['path']),urllib.parse.unquote(u.path)))
        if target.startswith(prefix):supportrefs.append(dict(owner=r['path'],ref=ref,target=target,owner_retired=r['path'] in retire))
put('retired_support_css_references.csv',supportrefs)
matrix=[]
for route in sorted(set(r['route'] for r in inbound)|{'index.html','supplementary_information.html','search.json','sitemap.xml'}):
    acts=[];rs=[r for r in inbound if r['route']==route]
    for area,n in collections.Counter(r['area'] for r in rs).items():acts.append(f'remove {n} exact sensitivity reference(s) from {area}')
    if route=='index.html':acts.append('remove complete section[data-site-utility="true"][aria-labelledby="site-downloads-title"]; preserve Other Formats Word and all science/figures/tables')
    if route=='supplementary_information.html':acts+=['remove passage-change paragraph from downloads utility; preserve Word + 19 editable links and return link','remove complete section[data-site-utility="true"][aria-labelledby="site-passage-changes"] and TOC li for #site-passage-changes']
    if route=='search.json':acts.append('remove exactly four records with href route notebooks/sensitivity_battery.html; preserve remaining 938 objects byte/content-equivalent')
    if route=='sitemap.xml':acts.append('remove exact sensitivity <url>; review workflow-only URL separately; preserve other URL entries and lastmod values')
    matrix.append(dict(**by[route],action='; '.join(acts),sensitivity_reference_count=len(rs),status='proposed only; no candidate or public bytes changed'))
put('proposed_public_replacement_matrix.csv',matrix)
extra=['audit/hypotheses/H03-H11_gated_workflow.html','audit/hypotheses/H03-H11_gated_workflow.qmd','audit/hypotheses/implementation_result_comparison_contract.html','audit/hypotheses/implementation_result_comparison_contract.qmd','audit/H01/02_implementation_and_v0_comparison.html']
amb=[]
for target in extra:
    if target not in by:continue
    rs=[r for r in links if r['target']==target and r['route']!=target]
    amb.append(dict(**by[target],inbound=len(rs),inbound_owners='|'.join(sorted(set(r['route'] for r in rs))),classification='workflow-only candidate needing explicit boundary' if 'gated_workflow' in target or 'implementation_result_comparison_contract' in target else 'mixed historical analysis/result comparison; preserve pending explicit content decision'))
put('ambiguous_nonreader_file_matrix.csv',amb)
put('ambiguous_nonreader_inbound.csv',[r for r in links if any(r['target']==x for x in extra) and r['route']!=r['target']])
doc=etree.parse(str(SITE/'sitemap.xml'));sm=[]
for e in doc.xpath('//*[local-name()="url"]'):
    loc=e.xpath('./*[local-name()="loc"]/text()')[0]
    if re.search('sensitivity|workflow|implementation|changes|%20| 2| 3',loc):sm.append(dict(loc=loc,xml=etree.tostring(e).decode()))
put('sitemap_scope_items.csv',sm)
puts=[]
for route in ['index.html','supplementary_information.html']:
    d=html.fromstring((SITE/route).read_bytes())
    for e in d.xpath('//*[@data-site-utility]'):puts.append(dict(route=route,attribute=e.get('data-site-utility'),line=e.sourceline,tag=e.tag,xpath=d.getroottree().getpath(e),ids='|'.join(e.xpath('.//*[@id]/@id'))))
put('utility_exact_selectors.csv',puts)
summary=dict(public_retirements=len(retire),support_files=sum(x.startswith(prefix) for x in retire),support_inbound_from_other_html=[r for r in links if r['target'].startswith(prefix) and r['route']!=sens],support_css_refs=supportrefs,retained_html_affected=len(set(r['route'] for r in inbound)),sensitivity_inbound_references=len(inbound),sensitivity_inbound_by_area=dict(collections.Counter(r['area'] for r in inbound)),proposed_replacements=len(matrix),candidate_public_files=914-len(retire),reader_routes=36,search_records=938,public_sensitivity_source_copy_exists=(SITE/'notebooks/sensitivity_battery.qmd').exists(),proposed_output_only=True)
put('consolidated_counts.json',summary)
print(json.dumps(summary,indent=2))
