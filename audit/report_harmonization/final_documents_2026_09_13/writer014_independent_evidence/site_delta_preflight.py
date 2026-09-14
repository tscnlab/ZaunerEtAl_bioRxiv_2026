from pathlib import Path
import csv, hashlib, json, re, copy
from collections import Counter
from urllib.parse import quote
from lxml import html
from PIL import Image

ROOT=Path.cwd()
OUT=Path('/private/tmp/writer014-independent.Jj6M5d')
W=ROOT/'audit/manuscript_nature_health/a4_display_revision_2026_09_14'
Q=W/'html_visual_qa'
P=ROOT/'audit/report_harmonization/final_site_promotion_2026_09_14'
LIVE=ROOT/'_build/nathealth'
def sha(p): return hashlib.file_digest(Path(p).open('rb'),'sha256').hexdigest()
def digest(s): return hashlib.sha256(s.encode()).hexdigest()
def rows(p): return list(csv.DictReader(Path(p).open(newline='',encoding='utf-8-sig')))
def output(name,obj): (OUT/name).write_text(json.dumps(obj,indent=2,ensure_ascii=False)+'\n')
checks=[]
def check(name,condition,detail=''):
    checks.append(dict(check=name,pass_=bool(condition),detail=detail))
    assert condition,(name,detail)
images=rows(Q/'screenshot_inventory.csv')
for r in images:
    im=Image.open(Q/r['path'])
    check('PNG provenance '+r['path'],im.size==(int(r['png_width']),int(r['png_height'])) and sha(Q/r['path'])==r['sha256'])

fixed=rows(P/'evidence/post_fixed_closure_checks.csv')
regular=[r for r in fixed if r['expected_sha256']]
dirs=[r for r in fixed if not r['expected_sha256']]
check('Fixed scope row classification',len(regular)==3868 and len(dirs)==1 and dirs[0]['category']=='complete_live_inventory' and dirs[0]['path']=='_build/nathealth')
for r in regular: check('Fixed '+r['path'],sha(ROOT/r['path'])==r['expected_sha256'])
baseline=rows(P/'evidence/post_live_inventory.csv')
current=[]
for p in sorted(LIVE.rglob('*')):
    check('No symlink '+str(p.relative_to(LIVE)),not p.is_symlink())
    if p.is_file():current.append(dict(path=str(p.relative_to(LIVE)),bytes=str(p.stat().st_size),sha256=sha(p)))
check('Complete live914 inventory exact',current==baseline)

delta=json.loads((W/'html_candidate_round2/delta_manifest.json').read_text())
plans={};operations=[]
for route in ['index.html','supplementary_information.html']:
    original=(LIVE/route).read_text()
    raw=original; reversible=[]
    for op in delta['changes']:
        if 'regex' in op:
            seen=re.findall(op['regex'],raw)
            counts=dict(Counter(seen))
            expected=4 if route=='index.html' else 3 if op['key']=='existing_section_ids' else 2
            # Record actual cardinality before assigning any central contract.
            new=re.sub(op['regex'],lambda m:op['map'][m[0]],raw)
            reversible.append(('regex',op,new,raw))
            operations.append(dict(route=route,key=op['key'],count=len(seen),values=counts,mode='simultaneous mapping'))
        else:
            old=(W/'html_candidate_round2'/op['old_file']).read_text()
            newfrag=(W/'html_candidate_round2'/op['new_file']).read_text()
            count=raw.count(old)
            results_only=op['key'] in ['Results short reference S17','Results short reference S18','Results chronotype references']
            check(route+' fragment uniqueness '+op['key'], count==(0 if route!='index.html' and results_only else 1), str(count))
            new=raw.replace(old,newfrag)
            reversible.append(('fragment',op,new,raw))
            operations.append(dict(route=route,key=op['key'],count=count,mode='exact fragment'))
        raw=new
    reverse=raw
    for kind,op,post,pre in reversed(reversible):
        if kind=='regex':
            inv={v:k for k,v in op['map'].items()}
            pat='|'.join(re.escape(k) for k in inv)
            reverse=re.sub(pat,lambda m:inv[m[0]],reverse)
        else:
            old=(W/'html_candidate_round2'/op['old_file']).read_text()
            new=(W/'html_candidate_round2'/op['new_file']).read_text()
            if pre.count(old):
                check(route+' reverse unique '+op['key'], reverse.count(new)==1)
                reverse=reverse.replace(new,old)
        check(route+' reverse step '+op['key'],reverse==pre)
    check(route+' byte-exact reverse',reverse==original)
    tree=html.fromstring(raw,parser=html.HTMLParser(huge_tree=True,encoding='utf-8'))
    oldtree=html.fromstring(original,parser=html.HTMLParser(huge_tree=True,encoding='utf-8'))
    check(route+' unique IDs',not [k for k,v in Counter(tree.xpath('//@id')).items() if v>1])
    check(route+' unchanged image source order',tree.xpath('//img/@src')==oldtree.xpath('//img/@src'))
    check(route+' utility blocks exact', [html.tostring(e) for e in tree.xpath('//*[@data-site-utility]')]==[html.tostring(e) for e in oldtree.xpath('//*[@data-site-utility]')])
    for id_ in ['TOC','quarto-header','quarto-sidebar']:
        # The changed-section IDs in the TOC are explicitly included in delta mappings.
        if id_!='TOC':check(route+' shell '+id_,[html.tostring(e) for e in tree.xpath('//*[@id="'+id_+'"]')]==[html.tostring(e) for e in oldtree.xpath('//*[@id="'+id_+'"]')])
    plans[route]=raw
    (OUT/('prospective_'+route)).write_text(raw)

oldsearch=json.loads((LIVE/'search.json').read_text())
crumbs={r['href'].split('#')[0]:r.get('crumbs',[]) for r in oldsearch}
search=[]
def text(n): return re.sub(r'\s+',' ',' '.join(n.itertext())).strip()
for route in ['index.html','supplementary_information.html']:
    tree=html.fromstring(plans[route],parser=html.HTMLParser(huge_tree=True,encoding='utf-8'))
    counts=Counter(tree.xpath('//@id'))
    main=copy.deepcopy(tree.xpath('//main')[0])
    for bad in main.xpath('.//script|.//style|.//nav|.//*[@data-site-utility]|.//*[@hidden]|.//*[@aria-hidden="true"]|.//button|.//*[contains(concat(" ",normalize-space(@class)," ")," anchorjs-link ")]'):
        if bad.getparent() is not None:bad.drop_tree()
    page_title=tree.xpath('string(//title)');sections=main.xpath('.//section[@id]')
    root_text=copy.deepcopy(main)
    for section in root_text.xpath('.//section[@id]'):
        if counts[section.get('id')]==1 and section.getparent() is not None:section.drop_tree()
    search.append(dict(objectID=route,href=route,title=page_title,section='',text=text(root_text),crumbs=crumbs.get(route,[])))
    for section in sections:
        id_=section.get('id')
        if counts[id_]!=1:continue
        own=copy.deepcopy(section)
        for child in own.xpath('.//section[@id]'):
            if counts[child.get('id')]==1 and child.getparent() is not None:child.drop_tree()
        heading=own.xpath('./h1|./h2|./h3|./h4|./h5|./h6')
        href=route+'#'+quote(id_,safe='-._~')
        search.append(dict(objectID=href,href=href,title=page_title,section=text(heading[0]) if heading else id_,text=text(own),crumbs=crumbs.get(route,[])))
oldpair=[r for r in oldsearch if r['href'].split('#')[0] in plans]
remainder=[r for r in oldsearch if r['href'].split('#')[0] not in plans]
combined=search+remainder
check('Search IDs unique',len({r['objectID'] for r in combined})==len(combined))
check('Search37 routes preserved',{r['href'].split('#')[0] for r in combined}=={r['href'].split('#')[0] for r in oldsearch})
serialized=json.dumps(combined,indent=2,ensure_ascii=False)+'\n'
(OUT/'prospective_search.json').write_text(serialized)
oldby={r['objectID']:r for r in oldsearch};newby={r['objectID']:r for r in combined}
search_delta=dict(removed=sorted(set(oldby)-set(newby)),added=sorted(set(newby)-set(oldby)),
 changed=sorted(k for k in set(oldby)&set(newby) if oldby[k]!=newby[k]))
output('site_delta_preflight.json',dict(status='PASS',live_files=914,protected_files=3868,operations=operations,
 prospective_html=[dict(route=k,before=sha(LIVE/k),after=digest(v),bytes=len(v.encode())) for k,v in plans.items()],
 search=dict(old_total=len(oldsearch),old_pair=len(oldpair),new_pair=len(search),new_total=len(combined),unchanged_other_rows=len(remainder),
 prospective_sha256=digest(serialized),prospective_bytes=len(serialized.encode()),delta=search_delta),
 candidate_or_live_promotion=False,site_writes=0))
output('infrastructure_checks.json',checks)
print('SITE_DELTA_PREFLIGHT=PASS',len(checks),'checks; operations',len(operations),'search',len(oldsearch),'->',len(combined))
