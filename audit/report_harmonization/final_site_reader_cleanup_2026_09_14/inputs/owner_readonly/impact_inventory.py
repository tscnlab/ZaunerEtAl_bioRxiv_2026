"""Read-only file and DOM-reference infrastructure audit. Outputs only in this temp directory."""
from pathlib import Path
import csv,hashlib,json,posixpath,re,urllib.parse,datetime
from lxml import html,etree
ROOT=Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
SITE=ROOT/'_build/nathealth'
OUT=Path('/private/tmp/reader-scope-audit-20260914.nnDbyu')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def put(name,rs):
    p=OUT/name;assert not p.exists()
    if name.endswith('.json'):p.write_text(json.dumps(rs,indent=2));return
    keys=list(dict.fromkeys(k for r in rs for k in r))
    with p.open('w') as f:
        w=csv.DictWriter(f,fieldnames=keys);w.writeheader();w.writerows(rs)
def label(p):return str(p.relative_to(ROOT))
files=sorted(p for p in SITE.rglob('*') if p.is_file())
put('live_inventory_before.csv',[dict(path=str(p.relative_to(SITE)),bytes=p.stat().st_size,sha256=sha(p)) for p in files])
raws={};docs={};alllinks=[];units=[];page_nav=[];heads=[]
for p in files:
    if p.suffix.lower()!='.html':continue
    route=str(p.relative_to(SITE));raws[route]=p.read_text(errors='replace');d=html.fromstring(raws[route]);docs[route]=d
    for a in d.xpath('//*[@href or @src or @data-target]'):
        attr='href' if 'href' in a.attrib else 'src' if 'src' in a.attrib else 'data-target'
        ref=a.get(attr);u=urllib.parse.urlsplit(ref)
        if u.scheme=='data':continue
        if u.scheme or u.netloc:
            if 'tscnlab.github.io' not in u.netloc:continue
            target=u.path.removeprefix('/ZaunerEtAl_bioRxiv_2026/')
        else:target=posixpath.normpath(posixpath.join(posixpath.dirname(route),urllib.parse.unquote(u.path))) if u.path else route
        ancestors=list(a.iterancestors());area='body'
        if any(e.get('data-site-utility') is not None for e in ancestors):area='utility'
        elif any(e.get('id')=='quarto-header' for e in ancestors):area='navbar'
        elif any(e.get('id')=='quarto-sidebar' for e in ancestors):area='sidebar'
        elif any('page-navigation' in e.get('class','').split() for e in ancestors):area='previous_next'
        elif any(e.get('id')=='TOC' for e in ancestors):area='toc'
        elif any(e.tag=='head' for e in ancestors):area='head'
        elif any(e.get('id')=='quarto-appendix' for e in ancestors):area='appendix'
        alllinks.append(dict(route=route,area=area,tag=a.tag,attribute=attr,text=' '.join(a.text_content().split())[:220],ref=ref,target=target,fragment=u.fragment,xpath=d.getroottree().getpath(a),line=a.sourceline,target_exists=(SITE/target).is_file()))
    for e in d.xpath('//*[@data-site-utility]'):
        units.append(dict(route=route,xpath=d.getroottree().getpath(e),id=e.get('id',''),tag=e.tag,line=e.sourceline,descendant_ids='|'.join(e.xpath('.//*[@id]/@id')),links=len(e.xpath('.//a')),bytes=len(etree.tostring(e)),sha256=hashlib.sha256(etree.tostring(e)).hexdigest(),text=' '.join(e.text_content().split())))
    for e in d.xpath('//nav[contains(@class,"page-navigation")]'):
        page_nav.append(dict(route=route,text=' '.join(e.text_content().split()),hrefs='|'.join(e.xpath('.//a/@href')),xpath=d.getroottree().getpath(e)))
    for e in d.xpath('//main//*[self::h1 or self::h2 or self::h3 or self::h4]'):
        text=' '.join(e.text_content().split())
        if re.search(r'passage|revision|approval|workflow|sensitivity|provenance|download',text,re.I):heads.append(dict(route=route,heading=text,level=e.tag,id=e.get('id',''),parent_id=e.getparent().get('id',''),line=e.sourceline))
put('all_local_references.csv',alllinks);put('utility_blocks.csv',units);put('all_previous_next.csv',page_nav);put('candidate_heading_inventory.csv',heads)
specific=[r for r in alllinks if re.search(r'sensitivity_battery|passage|revision|approval|gated_workflow',r['target']+'#'+r['fragment'],re.I)]
put('withdrawal_and_ambiguous_references.csv',specific)
keywordfiles=[]
for p in files:
    route=str(p.relative_to(SITE))
    if re.search(r'sensitivity_battery|passage|revision|approval|gated_workflow|sitemap',route,re.I):keywordfiles.append(dict(path=route,bytes=p.stat().st_size,sha256=sha(p)))
put('named_public_file_candidates.csv',keywordfiles)
search=json.loads((SITE/'search.json').read_text());assert isinstance(search,list)
sf=[]
for n,r in enumerate(search):
    href=r.get('href','');match=re.search(r'sensitivity_battery|passage|revision|approval|gated_workflow',href,re.I)
    if match:sf.append(dict(index=n,id=r.get('objectID',''),href=href,title=r.get('title',''),section=r.get('section',''),bytes=len(json.dumps(r))))
put('search_withdrawal_candidates.csv',sf)
put('search_route_inventory.csv',[dict(route=r,records=sum(x.get('href','').split('#')[0]==r for x in search)) for r in sorted(set(x.get('href','').split('#')[0] for x in search))])
corpus=list(csv.DictReader((ROOT/'audit/report_harmonization/phase4_corpus_manifest.csv').open()))
put('corpus_current.json',corpus)
put('impact_summary.json',dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),root=str(ROOT),output=str(OUT),live_files=len(files),html_files=len(docs),all_references=len(alllinks),utility_blocks=len(units),route_count=len(set(x.get('href','').split('#')[0] for x in search)),search_records=len(search),withdrawal_reference_count=len(specific),withdrawal_search_records=len(sf),sitemap_paths=[str(p.relative_to(SITE)) for p in files if 'sitemap' in p.name],named_file_candidates=len(keywordfiles)))
print(json.dumps(json.loads((OUT/'impact_summary.json').read_text()),indent=2))
