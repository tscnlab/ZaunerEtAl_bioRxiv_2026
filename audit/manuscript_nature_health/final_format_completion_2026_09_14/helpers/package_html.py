"""Three reversible static packaging transformations; no Quarto execution."""
from pathlib import Path
import re,json,hashlib,base64,argparse
from lxml import html
C=Path(__file__).resolve().parents[1]
ap=argparse.ArgumentParser();ap.add_argument('--round',type=int,choices=(1,2),default=1);a=ap.parse_args()
src=C/'inputs/prior_integrated.html';old=src.read_text()
assert hashlib.sha256(src.read_bytes()).hexdigest()=='0488130aba3ef7b043c743ee879d6e88f9c2ece8ae3c0c2eba89d90e116ea510'
expected=json.loads((C/'evidence/html_expected_cells.json').read_text())
def norm(s):return ' '.join(s.replace('\xa0',' ').split())
def cells(table):
    result=[]
    for n in table.xpath('./thead/tr/*|./tbody/tr/*|./tfoot/tr/*'):
        cp=html.fromstring(html.tostring(n))
        for br in cp.xpath('.//br'):br.tail=' '+(br.tail or '')
        result.append(norm(cp.text_content()))
    return result
d=html.fromstring(old);tabs=d.xpath('//table[contains(concat(" ",normalize-space(@class)," ")," gt_table ")]')
assert len(tabs)==len(expected)==19
assert all(cells(t)==e['cells'] for t,e in zip(tabs,expected,strict=True))
new=old;changes=[]
for endpoint,widths in [('nh_table2_primary',[176,254,230,180,180,200,100]),('near-eye-metric-summary',[210,86,138,146,146,154,138,146,138,146,138,130,120,252])]:
    target=d.xpath('//*[@id=$id]',id=endpoint);assert len(target)==1
    table=target[0].xpath('.//table');assert len(table)==1 and table[0].find('colgroup') is None
    marker=f'id="{endpoint}"';assert new.count(marker)==1
    at=new.index(marker);m=re.search(r'<table\b[^>]*>',new[at:]);assert m
    insertion=at+m.end()
    payload='<colgroup>'+''.join(f'<col style="width: {w}px;">' for w in widths)+'</colgroup>'
    new=new[:insertion]+payload+new[insertion:];changes.append(dict(endpoint=endpoint,widths=widths,payload=payload))
oldimg=d.xpath('//*[@id="fig-s15"]//img')[1].get('src')
assert oldimg.startswith('data:image/svg+xml;base64,')
oldbytes=base64.b64decode(oldimg.split(',',1)[1]);assert hashlib.sha256(oldbytes).hexdigest()=='c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3'
figs=json.loads((C/'maps/expanded_svg_manifest.json').read_text())['accepted_figures']
s15=next(f for f in figs if f['word_label']=='Supplementary Figure S15B');newbytes=Path(s15['path']).read_bytes()
assert hashlib.sha256(newbytes).hexdigest()==s15['sha256']=='0a3d0cabcd6cdb67db072cfa566448a885a774db519bea442a973896a7d616e8'
newimg='data:image/svg+xml;base64,'+base64.b64encode(newbytes).decode();assert new.count(oldimg)==1
new=new.replace(oldimg,newimg,1)
reverse=new.replace(newimg,oldimg,1)
for ch in changes:
    assert reverse.count(ch['payload'])==1
    reverse=reverse.replace(ch['payload'],'',1)
assert reverse==old,'Reverse proof failed'
nd=html.fromstring(new);nt=nd.xpath('//table[contains(concat(" ",normalize-space(@class)," ")," gt_table ")]')
assert all(cells(t)==e['cells'] for t,e in zip(nt,expected,strict=True))
out=C/f'project/html_round{a.round}/ZaunerEtAl2026_NatHealth_phase3_brown.html';out.parent.mkdir(exist_ok=True);assert not out.exists()
out.write_text(new)
report=dict(status='Static packaging candidate; no Quarto or Pandoc execution',input_sha256=hashlib.sha256(src.read_bytes()).hexdigest(),output_sha256=hashlib.sha256(out.read_bytes()).hexdigest(),colgroups=changes,s15b_old_sha256=hashlib.sha256(oldbytes).hexdigest(),s15b_new_sha256=s15['sha256'],all_other_bytes_reverse_exactly=True,table_count=19,targeted_cells=413)
(C/f'evidence/html_packaging_round{a.round}.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
