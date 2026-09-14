"""Reversible, exact-span, removal-only reader delivery patch. Never renders."""
from common import *
from html.parser import HTMLParser
from lxml import html, etree
from urllib.parse import urlsplit
from collections import Counter
import base64, shutil, re

def doc(b): return html.fromstring(b, parser=html.HTMLParser(encoding='utf-8', huge_tree=True))
class Spans(HTMLParser):
    def __init__(self, raw):
        super().__init__(convert_charrefs=False)
        self.text=raw.decode('utf-8'); self.lines=self.text.splitlines(keepends=True)
        self.offsets=[0]
        for line in self.lines: self.offsets.append(self.offsets[-1]+len(line.encode('utf-8')))
        self.nodes=[]; self.stack=[]; self.feed(self.text); self.close()
    def pos(self):
        line,col=self.getpos(); return self.offsets[line-1]+len(self.lines[line-1][:col].encode('utf-8'))
    def handle_starttag(self, tag, attrs):
        p=self.pos(); n=dict(tag=tag, attrs=dict(attrs), line=self.getpos()[0], start=p, end=None)
        self.nodes.append(n)
        if tag in VOID: n['end']=p+len(self.get_starttag_text().encode('utf-8'))
        else: self.stack.append(n)
    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag,attrs)
        if tag not in VOID: self.stack.pop()['end']=self.pos()+len(self.get_starttag_text().encode('utf-8'))
    def handle_endtag(self, tag):
        for i in range(len(self.stack)-1,-1,-1):
            if self.stack[i]['tag']==tag:
                end=self.pos()+len(('</'+tag+'>').encode('utf-8'))
                self.stack[i]['end']=end; del self.stack[i:]; break
    def match(self,n):
        attrs={k:('' if v is None else v) for k,v in n.attrib.items()}
        hits=[x for x in self.nodes if x['tag']==n.tag and x['line']==n.sourceline and {k:('' if v is None else v) for k,v in x['attrs'].items()}==attrs]
        assert len(hits)==1 and hits[0]['end'] is not None,(n.tag,n.sourceline,attrs,len(hits))
        return hits[0]['start'],hits[0]['end']

def selected_nodes(d,route):
    selected=[]
    for row in readcsv(AUDIT/'sensitivity_inbound_exact.csv'):
        if row['route']!=route: continue
        hits=d.xpath(row['xpath']); assert len(hits)==1
        n=hits[0]; assert n.get(row['attribute'])==row['ref']
        if row['area'] in ('navbar','sidebar'): n=n.xpath('ancestor::li[1]')[0]
        elif row['area']=='head': assert n.tag=='link' and n.get('rel')=='next'
        else:
            assert row['area']=='previous_next',row['area']
            n=n.xpath('ancestor::div[contains(concat(" ",normalize-space(@class)," ")," nav-page-next ")][1]')[0]
        selected.append((n,'sensitivity:'+row['area']))
    utility='//section[@data-site-utility="true" and @aria-labelledby="site-downloads-title"]'
    if route=='index.html':
        hits=d.xpath(utility); assert len(hits)==1; selected.append((hits[0],'main_download_utility'))
    if route=='supplementary_information.html':
        xp=utility+'/p[a[@href="manuscript_changes.csv"]]'
        for selector,kind in [(xp,'passage_download_paragraph'),('//section[@data-site-utility="true" and @aria-labelledby="site-passage-changes"]','passage_section'),('//a[@href="#site-passage-changes"]/ancestor::li[1]','passage_toc')]:
            hits=d.xpath(selector); assert len(hits)==1,(route,selector); selected.append((hits[0],kind))
    return selected

def apply_edits(raw, edits):
    result=raw; end=len(raw)
    for e in sorted(edits,key=lambda x:x['start'],reverse=True):
        a,b=e['start'],e['end']; assert 0<=a<b<=end
        old=base64.b64decode(e['removed']); new=base64.b64decode(e['replacement'])
        assert raw[a:b]==old; result=result[:a]+new+result[b:]; end=a
    return result
def reverse(raw,edits):
    result=raw
    for e in sorted(edits,key=lambda x:x['start']):
        a=e['start']; old=base64.b64decode(e['removed']); new=base64.b64decode(e['replacement'])
        assert result[a:a+len(new)]==new; result=result[:a]+old+result[a+len(new):]
    return result
def record(raw,start,end,kind,replacement=b'',xpath=''):
    return dict(start=start,end=end,kind=kind,xpath=xpath,removed=base64.b64encode(raw[start:end]).decode(),replacement=base64.b64encode(replacement).decode(),removed_sha256=hashbytes(raw[start:end]),left_context=base64.b64encode(raw[max(0,start-40):start]).decode(),right_context=base64.b64encode(raw[end:end+40]).decode())

def html_post(raw,route):
    d=doc(raw); selected=selected_nodes(d,route); parser=Spans(raw); edits=[]
    for n,kind in selected:
        a,b=parser.match(n); edits.append(record(raw,a,b,kind,xpath=d.getroottree().getpath(n)))
    post=apply_edits(raw,edits)
    # Independent DOM deletion (tails retained) must equal parsing the raw patch.
    for n,kind in selected: n.drop_tree()
    canonical=lambda x: etree.tostring(x,method='c14n')
    assert canonical(d)==canonical(doc(post)),('DOM mismatch',route)
    assert reverse(post,edits)==raw
    return post,edits

def profile_post(raw):
    chunks=[b'    - notebooks/sensitivity_battery.qmd\n',b'          - text: "Sensitivity checks"\n            href: notebooks/sensitivity_battery.qmd\n',b'    - id: robustness\n      title: "Robustness"\n      style: "floating"\n      search: false\n      collapse-level: 1\n      contents:\n        - section: "Sensitivity analyses"\n          contents:\n            - href: notebooks/sensitivity_battery.qmd\n              text: "Sensitivity checks"\n']
    edits=[]
    for i,c in enumerate(chunks):
        assert raw.count(c)==1; a=raw.index(c); edits.append(record(raw,a,a+len(c),'profile_remove_'+str(i+1)))
    return apply_edits(raw,edits),edits

def search_post(raw):
    s=raw.decode('utf-8'); dec=json.JSONDecoder(); pos=s.index('[')+1; spans=[]; objs=[]
    while True:
        while s[pos].isspace(): pos+=1
        if s[pos]==']': break
        a=pos; obj,pos=dec.raw_decode(s,pos); spans.append((a,pos)); objs.append(obj)
        while s[pos].isspace(): pos+=1
        if s[pos]==',': pos+=1
        else: assert s[pos]==']'
    assert len(objs)==942
    assert [i for i,o in enumerate(objs) if o['href'].split('#')[0]=='notebooks/sensitivity_battery.html']==list(range(938,942))
    a=len(s[:spans[937][1]].encode()); b=len(s[:spans[941][1]].encode())
    e=record(raw,a,b,'remove_final_four_search_objects'); post=apply_edits(raw,[e])
    assert json.loads(post)==objs[:938]
    return post,[e]

def sitemap_post(raw):
    hits=[m for m in re.finditer(rb'<url>.*?</url>',raw,re.S) if b'/notebooks/sensitivity_battery.html</loc>' in m[0]]
    assert len(hits)==1; m=hits[0]; e=record(raw,m.start(),m.end(),'remove_sensitivity_sitemap_url')
    return apply_edits(raw,[e]),[e]

def csv_spans(line):
    fields=[]; start=0; quote=False; i=0
    while i<len(line):
        if line[i]==34:
            if quote and i+1<len(line) and line[i+1]==34: i+=1
            else: quote=not quote
        elif line[i]==44 and not quote: fields.append((start,i)); start=i+1
        i+=1
    fields.append((start,len(line.rstrip(b'\r\n')))); return fields
def corpus_post(raw,posts):
    lines=raw.splitlines(keepends=True); rows=readcsv(ROOT/CORPUS); assert len(rows)==37 and len(lines)==38
    header=next(csv.reader([lines[0].decode()])); edits=[]; offset=len(lines[0])
    for row,line in zip(rows,lines[1:]):
        if row['source']=='notebooks/sensitivity_battery.qmd':
            edits.append(record(raw,offset,offset+len(line),'retire_corpus_sensitivity_row'))
        else:
            spans=csv_spans(line); assert len(spans)==len(header)
            for key,value in [('html_sha256',hashbytes(posts[row['expected_html']]))]+([('render_position',str(int(row['render_position'])-1))] if int(row['render_position'])>35 else []):
                a,b=spans[header.index(key)]; old=line[a:b]; quote=old.startswith(b'"'); new=(b'"'+value.encode()+b'"') if quote else value.encode()
                edits.append(record(raw,offset+a,offset+b,'corpus_'+key,new))
        offset+=len(line)
    return apply_edits(raw,edits),edits

def prepare():
    assert not CAND.exists() and not (OUT/'preimages').exists(),'Preparation is single initial creation; preserve failed evidence.'
    baseline=csvmap(AUDIT/'live_inventory_before.csv'); assert len(baseline)==914 and invmap(LIVE)==baseline
    auditmanifest=readcsv(AUDIT/'audit_manifest.csv'); assert len(auditmanifest)==100
    assert all(exact(AUDIT/r['path'],r['sha256'],r['bytes']) for r in auditmanifest)
    shutil.copytree(AUDIT,OUT/'inputs/owner_readonly')
    for name in ['site_reader_scope_cleanup_order_017.md','site_reader_scope_cleanup_order_017_dispatch_manifest.csv','site017_readonly_independent_acceptance.md']:
        shutil.copy2(CONTROL/name,owned(OUT/'inputs'/name))
    replacements=readcsv(AUDIT/'proposed_public_replacement_matrix.csv'); retirements=readcsv(AUDIT/'proposed_public_retirements.csv')
    assert len(replacements)==45 and len(retirements)==15
    logical=['_build/nathealth/'+r['path'] for r in replacements+retirements]+[PROFILE,CORPUS]
    assert len(logical)==len(set(logical))==62
    backups=[]
    for key in logical:
        p=checked(ROOT/key); dest=owned(OUT/'preimages'/key); shutil.copy2(p,dest)
        assert sha(p)==sha(dest); backups.append(dict(target=key,backup=str(dest.relative_to(OUT)),bytes=p.stat().st_size,sha256=sha(p)))
    csvout(E/'preimage_manifest.csv',backups)
    shutil.copytree(LIVE,CAND); assert invmap(CAND)==baseline
    csvout(E/'baseline_inventory.csv',list(baseline.values()))
    posts={}; ledgers=[]
    for r in replacements:
        key='_build/nathealth/'+r['path']; raw=(ROOT/key).read_bytes(); assert hashbytes(raw)==r['sha256']
        if r['path'].endswith('.html'): post,edits=html_post(raw,r['path'])
        elif r['path']=='search.json': post,edits=search_post(raw)
        else: assert r['path']=='sitemap.xml'; post,edits=sitemap_post(raw)
        assert reverse(post,edits)==raw and post!=raw
        posts[key]=post; ledgers.append(dict(target=key,pre_sha256=hashbytes(raw),post_sha256=hashbytes(post),edits=edits,exact_reverse=True))
    for key in [PROFILE,CORPUS]:
        raw=(ROOT/key).read_bytes(); post,edits=profile_post(raw) if key==PROFILE else corpus_post(raw,posts)
        assert reverse(post,edits)==raw; posts[key]=post; ledgers.append(dict(target=key,pre_sha256=hashbytes(raw),post_sha256=hashbytes(post),edits=edits,exact_reverse=True))
    for key,payload in posts.items(): owned(target(key,'candidate')).write_bytes(payload)
    for r in retirements:
        p=CAND/r['path']; assert exact(p,r['sha256'],r['bytes']); p.unlink()
    # Empty candidate-only directories are harmless; no broad deletion is used.
    bmap={r['target']:r for r in backups}; operations=[]
    for key in ['_build/nathealth/'+r['path'] for r in replacements+retirements]+[PROFILE,CORPUS]:
        b=bmap[key]; post=posts.get(key)
        operations.append(dict(sequence=len(operations)+1,target=key,action='replace' if post is not None else 'retire',pre_bytes=b['bytes'],pre_sha256=b['sha256'],post_bytes=len(post) if post is not None else 0,post_sha256=hashbytes(post) if post is not None else '',backup=b['backup'],candidate=str(target(key,'candidate').relative_to(OUT)) if post is not None else ''))
    dump(E/'transaction_plan.json',operations); dump(E/'raw_span_ledger.json',ledgers)
    csvout(E/'candidate_inventory.csv',inventory(CAND))
    csvout(E/'planned_operations.csv',operations)
    dump(E/'preparation_summary.json',dict(utc=utc(),status='PASS',preimages=62,replacements=47,public_replacements=45,retirements=15,raw_reversible_files=47,html_dom_equivalent=43,candidate_files=len(inventory(CAND))))
    print('PASS candidate creation, 62 preimages, 47 reversible postimages, 15 recoverable candidate retirements')
if __name__=='__main__': prepare()
