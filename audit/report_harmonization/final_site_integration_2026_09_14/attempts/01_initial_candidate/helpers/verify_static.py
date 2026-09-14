"""Full static file, navigation, resource, IDREF and prospective reseal checks."""
from common import *
from collections import Counter
from urllib.parse import unquote,urlsplit
import os

checks=[]
def check(name,condition,detail=''):
    checks.append(dict(check=name,pass_=bool(condition),detail=detail))
    assert condition,(name,detail)
baseline={r['path']:r for r in rows(EVIDENCE/'baseline_inventory.csv')}
candidate={r['path']:r for r in inventory(BUILD)}
matrix=rows(PROPOSAL/'proposed_integration_matrix.csv')
targets={str(Path(r['target']).relative_to('_build/nathealth')):r for r in matrix if r['target'].startswith('_build/nathealth/')}
check('914 candidate files',len(candidate)==914)
check('25 exact future website targets',len(targets)==25)
check('Exactly 21 additions',set(candidate)-set(baseline)=={k for k,r in targets.items() if r['current_exists']=='False'})
untouched=set(baseline)-set(targets)
check('889 exact untouched baseline files',len(untouched)==889 and all(candidate[k]['sha256']==baseline[k]['sha256'] for k in untouched))
check('Live893 unchanged',inventory(LIVE)==[dict(path=r['path'],bytes=int(r['bytes']),sha256=r['sha256']) for r in rows(EVIDENCE/'baseline_inventory.csv')])
corpus=rows(CORPUS);routes=[str(Path(r['expected_html']).relative_to('_build/nathealth')) for r in corpus]
check('35 report pages exact',all(candidate[r]['sha256']==baseline[r]['sha256'] for r in routes if r not in ['index.html','supplementary_information.html']))

documents={};ids={}
def getdoc(p):
    if p not in documents:
        documents[p]=doc(p);ids[p]=Counter(documents[p].xpath('//@id'))
    return documents[p]

idrows=[];idrefrows=[]
for route in routes:
    p=BUILD/route;d=getdoc(p)
    duplicates={k:v for k,v in ids[p].items() if v>1}
    if route in ['index.html','supplementary_information.html']:
        check(route+' clean static IDs',not duplicates,duplicates)
        for table_idx,table in enumerate(d.xpath('//table'),1):
            scope=Counter(table.xpath('.//@id'))
            for n in table.xpath('.//*[@headers]'):
                for target in n.get('headers').split():
                    ok=scope[target]==1
                    idrefrows.append(dict(route=route,table=table_idx,attribute='headers',target=target,valid=ok))
                    check(route+' table-scoped header '+target,ok)
        for n in d.xpath('//*[@aria-labelledby]|//*[@aria-describedby]|//*[@for]'):
            for attr in ['aria-labelledby','aria-describedby','for']:
                for target in n.get(attr,'').split():
                    ok=ids[p][target]==1
                    idrefrows.append(dict(route=route,table='',attribute=attr,target=target,valid=ok))
                    check(route+' IDREF '+attr+' '+target,ok)
    else:
        old=Counter(doc(LIVE/route).xpath('//@id'))
        check(route+' accepted duplicate-ID multiset',{k:v for k,v in old.items() if v>1}==duplicates)
    idrows.append(dict(route=route,id_count=sum(ids[p].values()),duplicate_ids=json.dumps(duplicates)))

refs=[];external=[];seen=set();closure=set(BUILD/r for r in routes)
def reference(owner,ref,kind):
    if not ref or ref.startswith('data:'):return
    key=(owner,ref,kind)
    if key in seen:return
    seen.add(key);u=urlsplit(ref.strip())
    if u.scheme or u.netloc:
        check('No local filesystem URI',u.scheme!='file',str(owner))
        external.append(dict(owner=str(owner.relative_to(BUILD)),reference=ref,kind=kind));return
    raw=unquote(u.path);target=BUILD/raw.lstrip('/') if raw.startswith('/') else owner.parent/raw if raw else owner
    target=Path(os.path.normpath(target))
    if target.is_dir():target=target/'index.html'
    check('No outward relative public link',target.is_relative_to(BUILD),ref)
    status='EXISTS' if target.is_file() else 'MISSING'
    frag=unquote(u.fragment)
    if status=='EXISTS':
        closure.add(target)
        if frag and target.suffix=='.html':
            getdoc(target)
            if not ids[target][frag]:status='MISSING_FRAGMENT'
    refs.append(dict(owner=str(owner.relative_to(BUILD)),reference=ref,kind=kind,target=str(target.relative_to(BUILD)),status=status))
def scan(p):
    if p.suffix=='.html':
        for n in getdoc(p).iter():
            if not isinstance(n.tag,str):continue
            for attr in ['href','src','poster','data-src']:
                if n.get(attr):reference(p,n.get(attr),n.tag+'@'+attr)
            if n.tag=='object' and n.get('data'):reference(p,n.get('data'),'object@data')
            if n.get('srcset') and not n.get('srcset').startswith('data:'):
                for chunk in n.get('srcset').split(','):reference(p,chunk.strip().split()[0],'srcset')
            style=n.get('style','')+(''.join(n.itertext()) if n.tag=='style' else '')
            for m in re.finditer(r'url\(\s*["\x27]?([^"\x27\)\s]+)',style):reference(p,m[1],'css-url')
    elif p.suffix=='.css':
        for m in re.finditer(r'(?:url\(\s*|@import\s+)["\x27]?([^"\x27\)\s;]+)',p.read_text()):reference(p,m[1],'css-resource')
scanned=set()
while closure-scanned:
    p=sorted(closure-scanned)[0];scanned.add(p);scan(p)
exceptions=[r for r in refs if r['status']!='EXISTS']
old_exceptions=[r for r in rows(PROPOSAL/'local_reference_audit.csv') if r['owner'].startswith('_build/nathealth/') and r['status']!='EXISTS']
normalize=lambda r:(r['owner'].removeprefix('_build/nathealth/'),r['reference'],r['kind'],r['status'])
check('Only four exact inherited font reference exceptions',len(exceptions)==4 and {normalize(r) for r in exceptions}=={normalize(r) for r in old_exceptions},exceptions)

search=json.loads((BUILD/'search.json').read_text());searchrows=[]
check('Unique search IDs',len(search)==len({r['objectID'] for r in search}))
check('Exactly37 search routes',set(r['href'].split('#')[0] for r in search)==set(routes))
for r in search:
    check('Search schema',set(r)=={'objectID','href','title','section','text','crumbs'})
    u=urlsplit(r['href']);p=BUILD/u.path;getdoc(p)
    ok=p.is_file() and (not u.fragment or ids[p][unquote(u.fragment)]==1)
    searchrows.append(dict(href=r['href'],valid_unique=ok))
    check('Search target resolves uniquely',ok,r['href'])
    check('Search excludes utility text',not any(t in r['text'] for t in ['Individual editable tables are provided','This revision record is a website resource']),r['href'])
for route in ['index.html','supplementary_information.html']:
    d=getdoc(BUILD/route)
    linknames=[Path(x).name for x in d.xpath('//*[@data-site-utility]//a[starts-with(@href,"editable_tables/")]/@href')]
    check(route+' nineteen distinct native links',len(linknames)==19 and len(set(linknames))==19)
    raw=(BUILD/route).read_bytes();original=(LIVE/route).read_bytes()
    for op in reversed([r for r in json.loads((EVIDENCE/'raw_operation_ledger.json').read_text()) if r['route']==route]):
        check('Raw postimage span',digest(raw[op['post_start']:op['post_end']])==op['post_sha256'],op['slot'])
        raw=raw[:op['post_start']]+original[op['pre_start']:op['pre_end']]+raw[op['post_end']:]
    check(route+' exact whole-file raw reversal',raw==original)

promotion=[]
for route,r in targets.items():
    p=BUILD/route
    if r['key']=='word_download':check('Final010c Word exact',sha(p)==WORD_SHA)
    elif r['proposed_action']=='BYTE_EXACT_ADDITION':check(route+' accepted source exact',sha(p)==r['source_sha256'])
    promotion.append(dict(target=r['target'],candidate=label(p),bytes=p.stat().st_size,preimage_sha256=r['preimage_sha256'],candidate_sha256=sha(p),action='replace' if r['current_exists']=='True' else 'add'))
post=CORPUS.read_bytes();original=post;reverse_rows=[]
for route in ['index.html','supplementary_information.html']:
    r=one([r for r in corpus if r['expected_html']=='_build/nathealth/'+route]);old=r['html_sha256'];new=sha(BUILD/route)
    check('Unique corpus hash cell '+route,post.count(old.encode())==1)
    post=post.replace(old.encode(),new.encode(),1)
    reverse_rows.append(dict(route=route,preimage_sha256=old,postimage_sha256=new))
reverse=post
for r in reverse_rows:reverse=reverse.replace(r['postimage_sha256'].encode(),r['preimage_sha256'].encode(),1)
check('Corpus raw two-cell reverse',reverse==original)
safe(EVIDENCE/'phase4_corpus_manifest.prospective.csv').write_bytes(post)
newcorpus=rows(EVIDENCE/'phase4_corpus_manifest.prospective.csv')
changed=[(i,k) for i,(a,b) in enumerate(zip(corpus,newcorpus)) for k in a if a[k]!=b[k]]
check('Exactly two html_sha256 cells changed',len(changed)==2 and all(k=='html_sha256' for i,k in changed))
authority=[]
for r in rows(PROPOSAL/'reader_routes.csv'):
    route=str(Path(r['expected_html']).relative_to('_build/nathealth'))
    authority.append(dict(**r,candidate_html_sha256=sha(BUILD/route),delivery_authority='Accepted C HTML plus reversible static website slots under Order011' if route in ['index.html','supplementary_information.html'] else 'Exact historical accepted delivered HTML',fresh_source_render=False,source_gap_preserved=r['current_source_sha256']!=r['historical_source_sha256']))
write_csv(EVIDENCE/'source_artifact_authority.csv',authority)
write_csv(EVIDENCE/'prospective_corpus_reverse.csv',reverse_rows)
write_csv(EVIDENCE/'website_promotion_manifest.csv',promotion)
write_csv(EVIDENCE/'static_checks.csv',checks)
write_csv(EVIDENCE/'id_inventory.csv',idrows)
write_csv(EVIDENCE/'table_and_aria_idrefs.csv',idrefrows)
write_csv(EVIDENCE/'local_reference_audit.csv',refs)
write_csv(EVIDENCE/'legacy_reference_exceptions.csv',exceptions)
write_csv(EVIDENCE/'external_reference_inventory.csv',external)
write_csv(EVIDENCE/'search_target_checks.csv',searchrows)
write_json(EVIDENCE/'static_summary.json',dict(pass_=True,checks=len(checks),candidate_files=914,unchanged_baseline=889,unchanged_reader_reports=35,search_records=len(search),search_routes=37,missing_reference_baseline_exceptions=4,live_writes=0,corpus_live_unchanged=sha(CORPUS)==digest(original)))
print('PASS',len(checks),'static checks;',len(search),'valid search targets; candidate only.')
