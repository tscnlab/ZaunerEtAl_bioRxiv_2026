"""One finite, byte-reversible, no-render Order011 candidate packaging pass."""
import copy,datetime,shutil
from html import escape
from collections import Counter
from urllib.parse import quote
from common import *

assert not BUILD.exists(),'Candidate already exists; no unrecorded packaging pass'
assert (EVIDENCE/'preflight_summary.json').is_file()
assert sha(WORD)==WORD_SHA
baseline=rows(EVIDENCE/'baseline_inventory.csv')
assert inventory(LIVE)==[dict(path=r['path'],bytes=int(r['bytes']),sha256=r['sha256']) for r in baseline]
source=ACCEPTED.read_bytes().decode('utf-8')
source_doc=doc(ACCEPTED)
source_main=inner(source,'main')
source_si=segment(source,'section','supplementary-information')
source_toc=segment(source,'nav','TOC')
source_style=one([m[0] for m in re.finditer(r'<style\b[^>]*>[\s\S]*?</style>',source) if 'div.manuscript-table,' in m[0]])
title=one(source_doc.xpath('//title')).text
matrix=rows(PROPOSAL/'proposed_integration_matrix.csv')
natives=[r for r in matrix if r['key'].startswith('editable_')]
assert len(natives)==19
revision_source=ROOT/one([r for r in matrix if r['key']=='passage_change_csv'])['source']
changes=rows(revision_source);assert len(changes)==20

utility_css='''<style id="order011-site-utilities">
.site-utilities{grid-column:body-content-start / body-content-end;min-width:0;max-width:100%;border:1px solid #c8d4dc;border-radius:.35rem;padding:1rem;margin:1rem 0 1.5rem;background:#f6f9fb;}
.site-utilities h2{margin:0 0 .65rem;font-size:1.2rem;}.site-utilities h3{font-size:1rem;margin:1rem 0 .4rem;}
.site-download-list{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:.35rem 1.4rem;padding-left:1.25rem;}
.site-utilities a{overflow-wrap:anywhere;}.site-utility-scroll{max-width:100%;overflow-x:auto;overscroll-behavior-inline:contain;}
.site-utility-scroll:focus{outline:2px solid #2b6f85;outline-offset:2px;}
.site-change-table{width:100%;min-width:740px;table-layout:fixed;border-collapse:collapse;background:white;font-size:.85rem;}
.site-change-table th,.site-change-table td{padding:.65rem;vertical-align:top;text-align:left;border:1px solid #ccd4da;white-space:pre-wrap;overflow-wrap:anywhere;}
.site-change-table thead th{background:#e8eef3;}.site-change-table caption{caption-side:top;color:inherit;font-weight:600;text-align:left;}
@media(max-width:708px){.site-download-list{grid-template-columns:repeat(2,minmax(0,1fr));}.site-utilities{padding:.75rem;}}
@media(max-width:420px){.site-download-list{grid-template-columns:1fr;}}
</style>'''

def downloads(route):
    parts=['<aside class="site-utilities" data-site-utility="true" aria-labelledby="site-downloads-title">',
        '<h2 id="site-downloads-title">Manuscript downloads</h2>',
        '<p><a href="ZaunerEtAl2026_NatHealth_phase3_brown.docx" download>Download the complete manuscript (Word)</a></p>',
        '<p>Individual editable tables are provided as Word documents.</p>',
        '<ul class="site-download-list">']
    for r in natives:
        name=Path(r['target']).stem.replace('_',' ')
        parts.append(f'<li><a href="editable_tables/{Path(r["target"]).name}" download>{escape(name)} (editable Word)</a></li>')
    parts+=['</ul>','<p><a href="manuscript_changes.csv" download>Passage changes (CSV)</a> · <a href="manuscript_changes.md" download>Passage changes (Markdown)</a> · <a href="supplementary_information.html#site-passage-changes">Read the position, old and new text table</a></p>']
    if route=='index.html':parts.append('<p><a href="supplementary_information.html">Open Supplementary Information separately</a></p>')
    else:parts.append('<p><a href="index.html">Return to the complete manuscript</a></p>')
    return '\n'.join(parts+['</aside>'])

def revision_panel():
    parts=['<section class="site-utilities" data-site-utility="true" aria-labelledby="site-passage-changes">',
        '<h2 id="site-passage-changes">Manuscript passage changes</h2>',
        '<p>This revision record is a website resource, separate from the manuscript and Supplementary Information.</p>',
        '<div class="site-utility-scroll" role="region" aria-label="Position, old and new manuscript text" tabindex="0">',
        '<table class="site-change-table"><caption>Position, old text and new text</caption><colgroup><col style="width:14%"><col style="width:43%"><col style="width:43%"></colgroup>',
        '<thead><tr><th scope="col" id="site-change-position">Position</th><th scope="col" id="site-change-old">Old text</th><th scope="col" id="site-change-new">New text</th></tr></thead><tbody>']
    for i,r in enumerate(changes,1):
        parts.append(f'<tr><th scope="row" id="site-change-row-{i}" headers="site-change-position">{escape(r["position"])}</th><td headers="site-change-old site-change-row-{i}">{escape(r["old_text"])}</td><td headers="site-change-new site-change-row-{i}">{escape(r["new_text"])}</td></tr>')
    return '\n'.join(parts+['</tbody></table></div></section>'])

def first_ul(s):
    m=re.search(r'<ul\b[^>]*>',s);assert m
    level=1
    for t in re.finditer(r'</?ul\b[^>]*>',s[m.end():]):
        level+=-1 if t[0].startswith('</') else 1
        if level==0:return s[m.start():m.end()+t.end()]
    raise AssertionError('unclosed TOC ul')

plans={};ledger=[]
for route in ['index.html','supplementary_information.html']:
    original=(LIVE/route).read_bytes().decode('utf-8');ops=[]
    def replace(old,new,slot):
        assert original.count(old)==1,(route,slot,original.count(old))
        if old!=new:ops.append((original.index(old),original.index(old)+len(old),new,slot))
    if route=='index.html':
        replace(inner(original,'main'),'\n'+downloads(route)+source_main,'main-content')
        start=original.index('<meta name="author"');end=original.index('</title>',start)+len('</title>')
        s=source.index('<meta name="author"');e=source.index('</title>',s)+len('</title>')
        replace(original[start:end],source[s:e],'manuscript-metadata')
        replace(one([m[0] for m in re.finditer(r'<style\b[^>]*>[\s\S]*?</style>',original) if 'div.manuscript-table,' in m[0]]),source_style,'accepted-display-css')
        new_ul=first_ul(source_toc)
    else:
        replace(inner(original,'main'),'\n'+downloads(route)+'\n'+source_si+'\n'+revision_panel()+'\n','supplement-and-resources')
        si_li=one(source_doc.xpath('//nav[@id="TOC"]/ul/li[a[@href="#supplementary-information"]]'))
        new_ul='<ul class="collapse">'+etree.tostring(si_li,encoding='unicode',method='html',with_tail=False)+'<li><a href="#site-passage-changes" id="toc-site-passage-changes" class="nav-link" data-scroll-target="#site-passage-changes">Passage changes</a></li></ul>'
    old_toc=segment(original,'nav','TOC')
    old_ul=first_ul(old_toc)
    replace(old_toc,old_toc.replace(old_ul,new_ul,1),'toc-content-only')
    replace('</head>',('\n'+source_style if route!='index.html' else '')+'\n'+utility_css+'\n</head>','entry-local-style-insertion')
    ops.sort();assert all(ops[i][1]<=ops[i+1][0] for i in range(len(ops)-1))
    pieces=[];previous=0;postpos=0
    for start,end,new,slot in ops:
        retained=original[previous:start];pieces.append(retained);postpos+=len(retained.encode())
        old=original[start:end];new_bytes=new.encode()
        ledger.append(dict(route=route,slot=slot,pre_start=len(original[:start].encode()),pre_end=len(original[:end].encode()),post_start=postpos,post_end=postpos+len(new_bytes),pre_sha256=digest(old.encode()),post_sha256=digest(new_bytes)))
        pieces.append(new);postpos+=len(new_bytes);previous=end
    pieces.append(original[previous:]);post=''.join(pieces).encode()
    reverse=post
    for op in reversed([o for o in ledger if o['route']==route]):
        raw_original=original.encode()
        assert digest(reverse[op['post_start']:op['post_end']])==op['post_sha256']
        reverse=reverse[:op['post_start']]+raw_original[op['pre_start']:op['pre_end']]+reverse[op['post_end']:]
    assert reverse==(LIVE/route).read_bytes(),('raw reversal',route)
    candidate_tree=html.fromstring(post,parser=html.HTMLParser(huge_tree=True,encoding='utf-8'))
    assert not [i for i,c in Counter(candidate_tree.xpath('//@id')).items() if c>1],route
    plans[route]=post

# All boundary, collision and reverse conditions were checked before staging.
shutil.copytree(LIVE,BUILD,copy_function=shutil.copy2)
assert inventory(BUILD)==inventory(LIVE)
for route,payload in plans.items():safe(BUILD/route).write_bytes(payload)
for r in matrix:
    if r['key']=='word_download':shutil.copy2(WORD,safe(BUILD/Path(r['target']).relative_to('_build/nathealth')))
    elif r['proposed_action']=='BYTE_EXACT_ADDITION':
        src=ROOT/r['source'];assert sha(src)==r['source_sha256']
        shutil.copy2(src,safe(BUILD/Path(r['target']).relative_to('_build/nathealth')))

# Search is a static reader projection, never an execution or scientific summary.
search=[];old_search=json.loads((LIVE/'search.json').read_text())
crumbs={r['href'].split('#')[0]:r.get('crumbs',[]) for r in old_search}
for r in rows(CORPUS):
    route=str(Path(r['expected_html']).relative_to('_build/nathealth'))
    tree=doc(BUILD/route);counts=Counter(tree.xpath('//@id'))
    main=copy.deepcopy(one(tree.xpath('//main')))
    for bad in main.xpath('.//script|.//style|.//nav|.//*[@data-site-utility]|.//*[@hidden]|.//*[@aria-hidden="true"]|.//button|.//*[contains(concat(" ",normalize-space(@class)," ")," anchorjs-link ")]'):
        if bad.getparent() is not None:bad.drop_tree()
    page_title=tree.xpath('string(//title)');section_nodes=main.xpath('.//section[@id]')
    # Each section contributes only its own non-nested reader content; child sections
    # get separate valid targets. Duplicate-ID sections stay in the route-level text.
    root_text=copy.deepcopy(main)
    for section in root_text.xpath('.//section[@id]'):
        if counts[section.get('id')]==1 and section.getparent() is not None:section.drop_tree()
    def text(node):return re.sub(r'\s+',' ',' '.join(node.itertext())).strip()
    search.append(dict(objectID=route,href=route,title=page_title,section='',text=text(root_text),crumbs=crumbs.get(route,[])))
    for section in section_nodes:
        id_=section.get('id')
        if counts[id_]!=1:continue
        own=copy.deepcopy(section)
        for child in own.xpath('.//section[@id]'):
            if counts[child.get('id')]==1 and child.getparent() is not None:child.drop_tree()
        heading=own.xpath('./h1|./h2|./h3|./h4|./h5|./h6')
        heading_text=text(heading[0]) if heading else id_
        href=route+'#'+quote(id_,safe='-._~')
        search.append(dict(objectID=href,href=href,title=page_title,section=heading_text,text=text(own),crumbs=crumbs.get(route,[])))
assert len({r['objectID'] for r in search})==len(search)
write_json(BUILD/'search.json',search)
write_json(EVIDENCE/'raw_operation_ledger.json',ledger)
write_json(EVIDENCE/'packaging_pass.json',dict(pass_number=1,time_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),implementation_sha256=sha(Path(__file__)),raw_reversal_exact=True,search_records=len(search),no_render=True,live_changes=0))
candidate=inventory(BUILD);assert len(candidate)==914
write_csv(EVIDENCE/'candidate_inventory.csv',candidate)
print('PASS: one static candidate packaged; 914 files; both raw reversals exact; search records',len(search))
