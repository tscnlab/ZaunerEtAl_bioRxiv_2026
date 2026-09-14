"""Order015 complete candidate structural checks. No rendering or scientific calculation."""
from common import *
from collections import Counter
from urllib.parse import unquote,urlsplit
from lxml import html
import re,sys
from transform import make_postimages

def verify(mode):
    assert mode=='candidate'
    build=BUILD
    checks=[]
    def check(name,condition,detail=''):
        checks.append(dict(check=name,pass_=bool(condition),detail=str(detail)))
        assert condition,(name,detail)
    baseline={r['path']:r for r in parsed_inv(PROM/'evidence/post_live_inventory.csv')}
    actual={r['path']:r for r in inv(build)}
    expected={k:dict(r) for k,r in baseline.items()}
    for r in plan_rows():
        route=str(Path(r['target']).relative_to('_build/nathealth'));expected[route]=dict(path=route,bytes=r['bytes'],sha256=r['post_sha256'])
    targets={str(Path(r['target']).relative_to('_build/nathealth')):r for r in plan_rows() if r['target'].startswith('_build/nathealth/')}
    check('Full914 accepted public closure',actual==expected and len(actual)==914)
    check('Exact6 candidate replacement destinations',len(targets)==6)
    check('Zero additions or removals',set(actual)==set(baseline))
    retained=set(baseline)-set(targets)
    check('908 preserved baseline files',len(retained)==908 and all(actual[k]==baseline[k] for k in retained))
    corpus=rows(E/'phase4_corpus_manifest.prospective.csv')
    routes=[str(Path(r['expected_html']).relative_to('_build/nathealth')) for r in corpus]
    check('37 reader routes',len(routes)==len(set(routes))==37)
    check('35 exact non-entry reports',sum(r not in ['index.html','supplementary_information.html'] for r in routes)==35 and all(actual[r]==baseline[r] for r in routes if r not in ['index.html','supplementary_information.html']))
    def doc(p):return html.fromstring(p.read_bytes(),parser=html.HTMLParser(encoding='utf-8',huge_tree=True))
    documents={};ids={}
    def getdoc(p):
        if p not in documents:documents[p]=doc(p);ids[p]=Counter(documents[p].xpath('//@id'))
        return documents[p]
    idrows=[];idrefrows=[]
    for route in routes:
        p=build/route;d=getdoc(p);duplicates={k:v for k,v in ids[p].items() if v>1}
        if route in ['index.html','supplementary_information.html']:
            check(route+' clean static IDs',not duplicates,duplicates)
            for ti,t in enumerate(d.xpath('//table'),1):
                scope=Counter(t.xpath('.//@id'))
                for n in t.xpath('.//*[@headers]'):
                    for target in n.get('headers').split():
                        ok=scope[target]==1;idrefrows.append(dict(route=route,table=ti,attribute='headers',target=target,valid=ok));check('Table-scoped header',ok,target)
            for n in d.xpath('//*[@aria-labelledby]|//*[@aria-describedby]|//*[@for]'):
                for attr in ['aria-labelledby','aria-describedby','for']:
                    for target in n.get(attr,'').split():
                        ok=ids[p][target]==1;idrefrows.append(dict(route=route,table='',attribute=attr,target=target,valid=ok));check('Entry IDREF',ok,target)
        else:
            old=Counter(doc(LIVE/route).xpath('//@id'))
            check(route+' accepted duplicate-ID multiset',{k:v for k,v in old.items() if v>1}==duplicates)
        idrows.append(dict(route=route,id_count=sum(ids[p].values()),duplicate_ids=json.dumps(duplicates)))
    refs=[];external=[];seen=set();closure=set(build/r for r in routes)
    def reference(owner,ref,kind):
        if not ref or ref.startswith('data:'):return
        key=(owner,ref,kind)
        if key in seen:return
        seen.add(key);u=urlsplit(ref.strip())
        if u.scheme or u.netloc:
            check('No filesystem URI',u.scheme!='file',str(owner));external.append(dict(owner=str(owner.relative_to(build)),reference=ref,kind=kind));return
        raw=unquote(u.path);target=build/raw.lstrip('/') if raw.startswith('/') else owner.parent/raw if raw else owner
        target=Path(os.path.normpath(target))
        if target.is_dir():target=target/'index.html'
        check('No outward relative public link',target.is_relative_to(build),ref)
        status='EXISTS' if target.is_file() else 'MISSING';frag=unquote(u.fragment)
        if status=='EXISTS':
            closure.add(target)
            if frag and target.suffix=='.html':
                getdoc(target)
                if not ids[target][frag]:status='MISSING_FRAGMENT'
        refs.append(dict(owner=str(owner.relative_to(build)),reference=ref,kind=kind,target=str(target.relative_to(build)),status=status))
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
    expected_exceptions=rows(OLD/'evidence/legacy_reference_exceptions.csv')
    signature=lambda r:(r['owner'],r['reference'],r['kind'],r['target'],r['status'])
    check('Four exact inherited font exceptions',len(exceptions)==4 and {signature(r) for r in exceptions}=={signature(r) for r in expected_exceptions},exceptions)
    search=json.loads((build/'search.json').read_text());searchrows=[]
    check('942 unique search records',len(search)==len({r['objectID'] for r in search})==942)
    check('37 exact search routes',{r['href'].split('#')[0] for r in search}==set(routes))
    for r in search:
        check('Search schema',set(r)=={'objectID','href','title','section','text','crumbs'})
        u=urlsplit(r['href']);p=build/u.path;getdoc(p)
        ok=p.is_file() and (not u.fragment or ids[p][unquote(u.fragment)]==1)
        searchrows.append(dict(href=r['href'],valid_unique=ok));check('Unique search target',ok,r['href'])
        check('Search excludes utility text',not any(t in r['text'] for t in ['Individual editable tables are provided','This revision record is a website resource']),r['href'])
    downloads=[]
    for route in ['index.html','supplementary_information.html']:
        d=getdoc(build/route)
        anchors=d.xpath('//*[@data-site-utility]//a[starts-with(@href,"editable_tables/")]')
        check(route+' nineteen distinct native links',len(anchors)==len({n.get('href') for n in anchors})==19)
        for n in anchors:
            name=' '.join(n.itertext()).strip();href=n.get('href');check('Native label and exact file',bool(name) and href in actual and actual[href]==expected[href],href)
            downloads.append(dict(route=route,href=href,label=name,sha256=actual[href]['sha256']))
        check(route+' full Word label',bool(d.xpath('//a[contains(@href,"ZaunerEtAl2026_NatHealth_phase3_brown.docx") and normalize-space(.)]')))
        if route=='supplementary_information.html':check(route+'20 revision rows',len(d.xpath('//table[contains(@class,"site-change-table")]/tbody/tr'))==20)
        else:check('Main entry links to revision utility',bool(d.xpath('//a[contains(@href,"supplementary_information.html#site-passage-changes")]')))
        olddoc=doc(LIVE/route)
        for selector in ['//head','//*[@data-site-utility]','//*[@id="quarto-header"]','//*[@id="quarto-sidebar"]','//nav[contains(@class,"page-navigation")]']:
            check(route+' unchanged shell/utility '+selector,[html.tostring(n) for n in d.xpath(selector)]==[html.tostring(n) for n in olddoc.xpath(selector)])
        check(route+' all image payloads and order retained',d.xpath('//img/@src')==olddoc.xpath('//img/@src'))
    replay,ledger,reversals,search_delta,prospective,corpus_reverse=make_postimages()
    for route,payload in replay.items():check(route+' exact deterministic accepted replay',(build/route).read_bytes()==payload)
    check('Exact saved operation ledger',ledger==json.loads((E/'raw_operation_ledger.json').read_text()))
    check('Both whole-file reversals',all(r['exact_whole_file_reversal'] for r in reversals))
    check('Exact accepted search delta',search_delta==json.loads((E/'search_delta.json').read_text()))
    for route,r in targets.items():check('Exact promoted download/source '+route,exact(build/route,r['post_sha256'],r['bytes']))
    prospective=(E/'phase4_corpus_manifest.prospective.csv').read_bytes()
    backups={r['live_target']:ROOT/r['backup'] for r in rows(E/'seven_backup_manifest.csv')}
    original=backups[label(CORPUS)].read_bytes();reverse=prospective
    for r in rows(E/'prospective_corpus_reverse.csv'):reverse=reverse.replace(r['post_sha256'].encode(),r['pre_sha256'].encode(),1)
    check('Exact two-cell corpus reverse',reverse==original)
    oldcorpus=rows(backups[label(CORPUS)])
    changed=[(i,k) for i,(a,b) in enumerate(zip(oldcorpus,corpus)) for k in a if a[k]!=b[k]]
    check('Only two HTML hash cells; all37 historical source cells retained',len(corpus)==len(oldcorpus)==37 and len(changed)==2 and all(k=='html_sha256' for i,k in changed))
    check('Live corpus unchanged',CORPUS.read_bytes()==original)
    check('All19 native files equal accepted Writer donors',all(sha(build/'editable_tables'/p.name)==sha(p) for p in (WRITER/'deliverables/editable_tables').glob('*.docx')))
    check('22 public downloads unchanged in membership',len([k for k in actual if k.startswith('editable_tables/')])+3==22)
    for name,data in [('static_checks',checks),('id_inventory',idrows),('table_and_aria_idrefs',idrefrows),('local_reference_audit',refs),('legacy_reference_exceptions',exceptions),('external_reference_inventory',external),('search_target_checks',searchrows),('native_download_links',downloads)]:csvout(E/f'{mode}_{name}.csv',data)
    result=dict(utc=utc(),mode=mode,all_pass=True,checks=len(checks),files=914,preserved=908,reports=35,search_records=942,search_routes=37,inherited_font_exceptions=4,native_files=19,supplement_revision_rows=20,main_revision_link=True)
    dump(E/f'{mode}_static_summary.json',result);print(json.dumps(result,indent=2))
if __name__=='__main__':verify(sys.argv[1])
