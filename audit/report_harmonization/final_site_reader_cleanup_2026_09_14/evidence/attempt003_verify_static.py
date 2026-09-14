"""Order017 complete survivor, DOM, dependency and transition checks; no science."""
from common import *
from prepare import doc,selected_nodes,apply_edits,reverse
from lxml import etree
from urllib.parse import urlsplit,unquote
from collections import Counter
import re,sys

def verify(mode,tag):
    site=site_for(mode); corpus=target(CORPUS,mode); profile=target(PROFILE,mode)
    checks=[]
    def check(k,v,detail=''):
        checks.append(dict(check=k,pass_=bool(v),detail=str(detail)))
        if not v:
            csvout(E/(tag+'_static_failed_checks.csv'),checks); raise AssertionError((k,detail))
    baseline=csvmap(E/'baseline_inventory.csv'); actual=invmap(site); expected=csvmap(E/'candidate_inventory.csv')
    operations=plan(); changed=[r for r in operations if r['action']=='replace']; retired=[r for r in operations if r['action']=='retire']
    check('62 unique exact operations',len(operations)==len({r['target'] for r in operations})==62)
    check('47 replacements,15 retirements; corpus last',len(changed)==47 and len(retired)==15 and operations[-1]['target']==CORPUS)
    check('Exactly899 candidate files and no symlinks',actual==expected and len(actual)==899)
    expected_changed={str(Path(r['target']).relative_to('_build/nathealth')) for r in changed if r['target'].startswith('_build/nathealth/')}
    expected_retired={str(Path(r['target']).relative_to('_build/nathealth')) for r in retired}
    check('No additions and exact15 retirements',not set(actual)-set(baseline) and set(baseline)-set(actual)==expected_retired and len(expected_retired)==15)
    check('45 changed survivors',len(expected_changed)==45 and {k for k in actual if actual[k]!=baseline[k]}==expected_changed)
    check('854 byte-identical survivors',sum(actual[k]==baseline[k] for k in actual)==854)
    for r in operations:
        check('Recoverable exact preimage',exact(OUT/r['backup'],r['pre_sha256'],r['pre_bytes']),r['target'])
        p=target(r['target'],mode)
        check('Exact transition postimage or absence',not p.exists() if r['action']=='retire' else exact(p,r['post_sha256'],r['post_bytes']),r['target'])
    ledgers=json.loads((E/'raw_span_ledger.json').read_text()); check('47 reversible file ledgers',len(ledgers)==47)
    for ledger in ledgers:
        key=ledger['target']; before=(OUT/'preimages'/key).read_bytes(); after=target(key,mode).read_bytes()
        check('Exact forward raw-span replay',apply_edits(before,ledger['edits'])==after,key)
        check('Exact whole-file raw-span reversal',reverse(after,ledger['edits'])==before,key)
        if key.endswith('.html'):
            route=str(Path(key).relative_to('_build/nathealth')); d=doc(before)
            for n,kind in selected_nodes(d,route): n.drop_tree()
            check('Independent stripped DOM equals candidate',etree.tostring(d,method='c14n')==etree.tostring(doc(after),method='c14n'),route)
    oldcorpus=readcsv(OUT/'preimages'/CORPUS); newcorpus=readcsv(corpus)
    check('36 corpus routes; exact sensitivity withdrawal',len(newcorpus)==36 and len(oldcorpus)==37 and oldcorpus[-1]['source']=='notebooks/sensitivity_battery.qmd')
    routes=[str(Path(r['expected_html']).relative_to('_build/nathealth')) for r in newcorpus]
    check('36 unique routes',len(set(routes))==36)
    deltas=[]
    for old,new in zip(oldcorpus[:36],newcorpus):
        allowed={'html_sha256'}|({'render_position'} if int(old['render_position'])>35 else set())
        changedkeys={k for k in old if old[k]!=new[k]}
        check('Exact allowed corpus cells',changedkeys==allowed,new['source'])
        check('Historical source/hash/title/order retained',all(old[k]==new[k] for k in old if k not in allowed),new['source'])
        check('Current corpus HTML identity',new['html_sha256']==actual[str(Path(new['expected_html']).relative_to('_build/nathealth'))]['sha256'])
        if 'render_position' in allowed: check('Only affected render position reduced',int(new['render_position'])==int(old['render_position'])-1)
        deltas.append(dict(source=new['source'],changed_fields='|'.join(sorted(changedkeys)),historical_source_hash_retained=True))
    source_entries=re.findall(r'^    - ([^!"\n].*\.qmd)$',profile.read_text(),re.M)
    check('36 profile render entries',len(source_entries)==36 and source_entries==[r['source'] for r in sorted(newcorpus,key=lambda r:int(r['render_position']))])
    check('No retired profile route','sensitivity_battery' not in profile.read_text())
    oldsearch=json.loads((OUT/'preimages/_build/nathealth/search.json').read_bytes()); search=json.loads((site/'search.json').read_bytes())
    check('Exact retained938 search objects',len(search)==938 and search==oldsearch[:938])
    check('Exact36 search routes',{r['href'].split('#')[0] for r in search}==set(routes))
    sm=etree.fromstring((site/'sitemap.xml').read_bytes()); smold=etree.fromstring((OUT/'preimages/_build/nathealth/sitemap.xml').read_bytes())
    ns={'s':'http://www.sitemaps.org/schemas/sitemap/0.9'}
    urls=sm.xpath('//s:url',namespaces=ns); previous=smold.xpath('//s:url',namespaces=ns)
    prior=[n for n in previous if not n.xpath('s:loc',namespaces=ns)[0].text.endswith('/notebooks/sensitivity_battery.html')]
    check('38 sitemap entries; other values/timestamps exact',len(previous)==39 and len(urls)==38 and [etree.tostring(x,with_tail=False) for x in urls]==[etree.tostring(x,with_tail=False) for x in prior])
    documents={}; olddocs={}; ids={}; oldids={}; idrows=[]; idrefs=[]
    def get(route,old=False):
        bank=olddocs if old else documents
        if route not in bank:
            p=OUT/'inputs/owner_readonly/preimages/_build/nathealth'/route if old else site/route
            if old and not p.is_file(): p=LIVE/route
            bank[route]=doc(p.read_bytes())
            if old: oldids[route]=Counter(bank[route].xpath('//@id'))
            else: ids[route]=Counter(bank[route].xpath('//@id'))
        return bank[route]
    htmlroutes=[r for r in actual if r.endswith('.html')]; check('All44 surviving HTML audited',len(htmlroutes)==44)
    oldbaseline_html={r for r in baseline if r.endswith('.html')}
    def semantic_failures(d):
        result=[]; allids=Counter(d.xpath('//@id'))
        for identity,count in allids.items():
            if count!=1:result.append(('document','id',identity,count))
        for n in d.xpath('//*[@aria-labelledby]|//*[@aria-describedby]|//*[@for]'):
            for attr in ['aria-labelledby','aria-describedby','for']:
                for identity in n.get(attr,'').split():
                    if allids[identity]!=1:result.append((d.getroottree().getpath(n),attr,identity,allids[identity]))
        for ti,t in enumerate(d.xpath('//table'),1):
            scoped=Counter(t.xpath('.//@id'))
            for n in t.xpath('.//*[@headers]'):
                for identity in n.get('headers').split():
                    if scoped[identity]!=1:result.append(('table'+str(ti)+':'+d.getroottree().getpath(n),'headers',identity,scoped[identity]))
        return Counter(result)
    semantic_rows=[]
    for route in htmlroutes:
        d=get(route); old=get(route,True); dup={k:v for k,v in ids[route].items() if v>1}; olddup={k:v for k,v in Counter(old.xpath('//@id')).items() if v>1}
        check('Exact inherited duplicate-ID multiset',dup==olddup,route)
        oldfailure=semantic_failures(old);newfailure=semantic_failures(d)
        check('Complete exact inherited semantic failure multiset',oldfailure==newfailure,(route,len(oldfailure)))
        for key,count in oldfailure.items():semantic_rows.append(dict(route=route,baseline_page_sha256=baseline[route]['sha256'],location=key[0],attribute=key[1],token=key[2],target_count=key[3],occurrences=count,exact_candidate_state=True))
        if route in ['index.html','supplementary_information.html']: check('No entry semantic failures',not newfailure,route)
        for n in d.xpath('//*[@aria-labelledby]|//*[@aria-describedby]|//*[@for]'):
            for attr in ['aria-labelledby','aria-describedby','for']:
                for identity in n.get(attr,'').split():
                    ok=ids[route][identity]>=1
                    idrefs.append(dict(route=route,attribute=attr,target=identity,valid=ok))
                    if route in ['index.html','supplementary_information.html']:check('Unique entry semantic IDREF',ids[route][identity]==1,(route,attr,identity))
        tables=d.xpath('//table'); oldtables=old.xpath('//table')
        if route not in ['index.html','supplementary_information.html']: check('All non-entry tables retained exactly',len(tables)==len(oldtables) and [etree.tostring(t) for t in tables]==[etree.tostring(t) for t in oldtables],route)
        for ti,t in enumerate(tables):
            scoped=Counter(t.xpath('.//@id'))
            for n in t.xpath('.//*[@headers]'):
                for identity in n.get('headers').split():
                    if route in ['index.html','supplementary_information.html']: check('Unique entry table-scoped header',scoped[identity]==1,(route,identity))
                    else:
                        oldscoped=Counter(oldtables[ti].xpath('.//@id'))
                        check('Non-entry header has exact pinned inherited state',scoped[identity]==oldscoped[identity],(route,identity,scoped[identity]))
        idrows.append(dict(route=route,duplicate_multiset=json.dumps(dup),ids=sum(ids[route].values())))
        check('No retained raw withdrawn URL token',not any(x in (site/route).read_bytes() for x in [b'sensitivity_battery.html',b'sensitivity_battery_files/',b'manuscript_changes.csv',b'manuscript_changes.md',b'#site-passage-changes']),route)
        if route not in ['index.html','supplementary_information.html']:
            check('Every other main subtree byte-serialized exact',[etree.tostring(x) for x in d.xpath('//main')]==[etree.tostring(x) for x in old.xpath('//main')],route)
    for r in search:
        check('Search exact schema',set(r)=={'objectID','href','title','section','text','crumbs'})
        u=urlsplit(r['href']); get(u.path)
        check('Unique existing search destination',u.path in actual and (not u.fragment or ids[u.path][unquote(u.fragment)]==1),r['href'])
    check('Unique938 objectIDs',len({r['objectID'] for r in search})==938)
    m=get('index.html');s=get('supplementary_information.html')
    check('No main utility box',not m.xpath('//*[@data-site-utility]'))
    check('Retained independent Other Formats Word',len(m.xpath('//a[@href="ZaunerEtAl2026_NatHealth_phase3_brown.docx" and normalize-space(.)="MS Word"]'))==1)
    dl=s.xpath('//section[@data-site-utility="true" and @aria-labelledby="site-downloads-title"]'); check('One retained SI utility',len(dl)==1 and len(s.xpath('//*[@data-site-utility]'))==1)
    check('21 SI utility links',len(dl[0].xpath('.//a'))==21)
    native=dl[0].xpath('.//a[starts-with(@href,"editable_tables/")]')
    check('19 distinct native downloads',len(native)==len({n.get('href') for n in native})==19)
    downloads=['ZaunerEtAl2026_NatHealth_phase3_brown.docx']+[n.get('href') for n in native]
    for route in downloads: check('Accepted Word/native payload byte-identical',actual[route]==baseline[route],route)
    check('No passage utility or TOC',not s.xpath('//*[@id="site-passage-changes" or @id="toc-site-passage-changes"]'))
    # Audit every HTML and every CSS dependency, comparing inherited unresolved sets.
    def references(tree,old=False):
        refs=[]; external=[]; seen=set(); root=LIVE if old else site
        filekeys=set(baseline if old else actual)
        def ref(owner,value,kind):
            if not value or value.startswith('data:'): return
            signature=(owner,value,kind)
            if signature in seen:return
            seen.add(signature);u=urlsplit(value.strip())
            if u.scheme or u.netloc:
                check('No file URI',u.scheme!='file',(owner,value));external.append(dict(owner=owner,reference=value,kind=kind));return
            raw=unquote(u.path); p=Path(os.path.normpath((root/raw.lstrip('/')) if raw.startswith('/') else (root/owner).parent/raw if raw else root/owner))
            check('Reference stays within rendered root',p.is_relative_to(root),(owner,value))
            relative=str(p.relative_to(root))
            if relative not in filekeys and relative.rstrip('/')+'/index.html' in filekeys: relative=relative.rstrip('/')+'/index.html'
            status='EXISTS' if relative in filekeys else 'MISSING'
            if status=='EXISTS' and u.fragment and relative.endswith('.html'):
                if relative in htmlroutes:
                    get(relative,old); identityset=oldids[relative] if old else ids[relative]
                else:
                    if relative not in oldids: oldids[relative]=Counter(doc((OUT/'preimages/_build/nathealth'/relative).read_bytes()).xpath('//@id'))
                    identityset=oldids[relative]
                if unquote(u.fragment) not in identityset:status='MISSING_FRAGMENT'
            refs.append(dict(owner=owner,reference=value,kind=kind,target=relative,status=status))
        owners=sorted(oldbaseline_html if old else htmlroutes)
        for route in owners:
            d=get(route,old) if route in htmlroutes else doc((OUT/'preimages/_build/nathealth'/route).read_bytes())
            for n in d.iter():
                if not isinstance(n.tag,str):continue
                for attr in ['href','src','poster','data-src']:
                    if n.get(attr):ref(route,n.get(attr),n.tag+'@'+attr)
                if n.tag=='object' and n.get('data'):ref(route,n.get('data'),'object@data')
                if n.get('srcset') and not n.get('srcset').startswith('data:'):
                    for part in n.get('srcset').split(','):ref(route,part.strip().split()[0],'srcset')
                style=n.get('style','')+(''.join(n.itertext()) if n.tag=='style' else '')
                for match in re.finditer(r'url\(\s*["\x27]?([^"\x27\)\s]+)',style):ref(route,match[1],'css-url')
        for route in sorted(k for k in filekeys if k.endswith('.css')):
            path=(OUT/'preimages/_build/nathealth'/route) if old and route in expected_retired else root/route
            for match in re.finditer(r'(?:url\(\s*|@import\s+)["\x27]?([^"\x27\)\s;]+)',path.read_text()):ref(route,match[1],'css-resource')
        return refs,external
    refs,external=references(site); oldrefs,_=references(LIVE,True)
    sig=lambda r:(r['owner'],r['reference'],r['kind'],r['target'],r['status'])
    inherited={sig(r) for r in oldrefs if r['status']!='EXISTS' and r['owner'] not in expected_retired}
    errors=[r for r in refs if r['status']!='EXISTS']
    check('Exact inherited unresolved-reference multiset, no new',Counter(sig(r) for r in errors)==Counter({x:1 for x in inherited}),errors)
    accepted=readcsv(ROOT/'audit/report_harmonization/final_site_integration_2026_09_14/evidence/legacy_reference_exceptions.csv')
    check('Only four documented inherited font exceptions',len(errors)==4 and {sig(r) for r in errors}=={sig(r) for r in accepted},errors)
    check('No surviving reference targets a retirement',not any(r['target'] in expected_retired for r in refs))
    support=[r for r in oldrefs if r['target'].startswith('notebooks/sensitivity_battery_files/')]
    check('Twelve support files exclusively owned by retired page/family',all(r['owner']=='notebooks/sensitivity_battery.html' or r['owner'].startswith('notebooks/sensitivity_battery_files/') for r in support))
    for filename,data,fields in [('static_checks',checks,None),('ids',idrows,None),('semantic_idrefs',idrefs,None),('inherited_semantic_failures',semantic_rows,None),('references',refs,None),('reference_exceptions',errors,None),('external_references',external,None),('corpus_delta',deltas,None)]:csvout(E/(tag+'_'+filename+'.csv'),data,fields)
    csvout(E/(tag+'_download_inventory.csv'),[actual[x] for x in downloads]);csvout(E/(tag+'_site_inventory.csv'),list(actual.values()))
    result=dict(utc=utc(),status='PASS',mode=mode,checks=len(checks),public_files=899,html_files=44,public_replacements=45,retirements=15,unchanged=854,routes=36,search_records=938,sitemap_entries=38,downloads=20,reference_rows=len(refs),inherited_font_exceptions=len(errors))
    dump(E/(tag+'_static_summary.json'),result);print(json.dumps(result))
if __name__=='__main__': verify(sys.argv[1],sys.argv[2])
