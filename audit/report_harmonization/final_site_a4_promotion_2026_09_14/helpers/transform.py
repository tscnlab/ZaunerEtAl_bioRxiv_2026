"""Exact accepted fragment delta and static two-route search projection."""
from common import *
# Verification replay uses immutable accepted preimages, never promoted live bytes.
LIVE=BASELINE
CORPUS=PRECORPUS
from collections import Counter
from urllib.parse import quote
from lxml import html
import re,copy

def make_postimages():
    delta=json.loads((DELTA/'delta_manifest.json').read_text());assert len(delta['changes'])==10
    accepted=json.loads((CONTROL/'writer014_independent_evidence/site_delta_preflight.json').read_text())
    expected={(r['route'],r['key']):r for r in accepted['operations']}
    plans={};ledger=[];reversals=[]
    for route in ['index.html','supplementary_information.html']:
        original=(LIVE/route).read_bytes();raw=original;steps=[]
        for i,op in enumerate(delta['changes'],1):
            contract=expected[(route,op['key'])];matches=[]
            if 'regex' in op:
                for m in re.finditer(op['regex'].encode(),raw):matches.append((m.start(),m.end(),op['map'][m[0].decode()].encode()))
                assert dict(Counter(raw[a:b].decode() for a,b,new in matches))==contract['values']
            else:
                before=(DELTA/op['old_file']).read_bytes();after=(DELTA/op['new_file']).read_bytes()
                for m in re.finditer(re.escape(before),raw):matches.append((m.start(),m.end(),after))
            assert len(matches)==contract['count'],(route,op['key'],len(matches))
            pieces=[];last=0;postpos=0;spans=[]
            for start,end,new in matches:
                retained=raw[last:start];pieces.append(retained);postpos+=len(retained)
                spans.append(dict(pre_start=start,pre_end=end,post_start=postpos,post_end=postpos+len(new),pre_sha256=hashlib.sha256(raw[start:end]).hexdigest(),post_sha256=hashlib.sha256(new).hexdigest()))
                pieces.append(new);postpos+=len(new);last=end
            pieces.append(raw[last:]);post=b''.join(pieces)
            record=dict(route=route,step=i,key=op['key'],matches=len(matches),mode=contract['mode'],whole_pre_sha256=hashlib.sha256(raw).hexdigest(),whole_post_sha256=hashlib.sha256(post).hexdigest(),spans=spans)
            ledger.append(record);steps.append((record,raw));raw=post
        reverse=raw
        for record,pre in reversed(steps):
            assert hashlib.sha256(reverse).hexdigest()==record['whole_post_sha256']
            for span in reversed(record['spans']):
                assert hashlib.sha256(reverse[span['post_start']:span['post_end']]).hexdigest()==span['post_sha256']
                reverse=reverse[:span['post_start']]+pre[span['pre_start']:span['pre_end']]+reverse[span['post_end']:]
            assert reverse==pre
        assert reverse==original
        plans[route]=raw;reversals.append(dict(route=route,steps=10,exact_whole_file_reversal=True,pre_sha256=hashlib.sha256(original).hexdigest(),post_sha256=hashlib.sha256(raw).hexdigest()))
    oldsearch=json.loads((LIVE/'search.json').read_text());crumbs={r['href'].split('#')[0]:r.get('crumbs',[]) for r in oldsearch};search=[]
    def text(n):return re.sub(r'\s+',' ',' '.join(n.itertext())).strip()
    for route,raw in plans.items():
        tree=html.fromstring(raw,parser=html.HTMLParser(huge_tree=True,encoding='utf-8'));counts=Counter(tree.xpath('//@id'));assert not any(n>1 for n in counts.values())
        main=copy.deepcopy(tree.xpath('//main')[0])
        for bad in main.xpath('.//script|.//style|.//nav|.//*[@data-site-utility]|.//*[@hidden]|.//*[@aria-hidden="true"]|.//button|.//*[contains(concat(" ",normalize-space(@class)," ")," anchorjs-link ")]'):
            if bad.getparent() is not None:bad.drop_tree()
        title=tree.xpath('string(//title)');sections=main.xpath('.//section[@id]');root_text=copy.deepcopy(main)
        for section in root_text.xpath('.//section[@id]'):
            if counts[section.get('id')]==1 and section.getparent() is not None:section.drop_tree()
        search.append(dict(objectID=route,href=route,title=title,section='',text=text(root_text),crumbs=crumbs.get(route,[])))
        for section in sections:
            id_=section.get('id')
            if counts[id_]!=1:continue
            own=copy.deepcopy(section)
            for child in own.xpath('.//section[@id]'):
                if counts[child.get('id')]==1 and child.getparent() is not None:child.drop_tree()
            headings=own.xpath('./h1|./h2|./h3|./h4|./h5|./h6');href=route+'#'+quote(id_,safe='-._~')
            search.append(dict(objectID=href,href=href,title=title,section=text(headings[0]) if headings else id_,text=text(own),crumbs=crumbs.get(route,[])))
    remainder=[r for r in oldsearch if r['href'].split('#')[0] not in plans];assert len(remainder)==836 and len(search)==106
    combined=search+remainder;assert len(combined)==len({r['objectID'] for r in combined})==942
    oldby={r['objectID']:r for r in oldsearch};newby={r['objectID']:r for r in combined}
    search_delta=dict(removed=sorted(set(oldby)-set(newby)),added=sorted(set(newby)-set(oldby)),changed=sorted(k for k in set(oldby)&set(newby) if oldby[k]!=newby[k]))
    assert search_delta==accepted['search']['delta']
    plans['search.json']=(json.dumps(combined,indent=2,ensure_ascii=False)+'\n').encode()
    for r in plan_rows():
        route=str(Path(r['target']).relative_to('_build/nathealth'))
        if route not in plans:plans[route]=(ROOT/r['source']).read_bytes()
        assert len(plans[route])==r['bytes'] and hashlib.sha256(plans[route]).hexdigest()==r['post_sha256'],route
    corpus=CORPUS.read_bytes();prospective=corpus;corpus_reverse=[]
    for route in ['index.html','supplementary_information.html']:
        r=next(r for r in plan_rows() if r['target']=='_build/nathealth/'+route)
        old=r['pre_sha256'].encode();new=r['post_sha256'].encode();assert prospective.count(old)==1
        prospective=prospective.replace(old,new,1);corpus_reverse.append(dict(route=route,pre_sha256=old.decode(),post_sha256=new.decode()))
    reverse=prospective
    for r in corpus_reverse:reverse=reverse.replace(r['post_sha256'].encode(),r['pre_sha256'].encode(),1)
    assert reverse==corpus
    assert prospective==(CONTROL/'writer014_independent_evidence/phase4_corpus_manifest.prospective.csv').read_bytes()
    return plans,ledger,reversals,search_delta,prospective,corpus_reverse
