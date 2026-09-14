"""Prepare minimal, reversible HTML fragments. No browser or site mutation."""
from pathlib import Path
from lxml import html, etree as E
from copy import deepcopy
import json,re,hashlib,sys

root=Path.cwd(); j=root/'audit/manuscript_nature_health/a4_display_revision_2026_09_14'
c=root/'audit/manuscript_nature_health/final_format_completion_2026_09_14'
out=j/(sys.argv[1] if len(sys.argv)>1 else 'html_candidate');out.mkdir(exist_ok=False)
src=c/'project/html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html'
s=src.read_text();original=s;changes=[]
def change(old,new,key):
    global s
    assert s.count(old)==1,(key,s.count(old))
    s=s.replace(old,new,1)
    changes.append({'key':key,'old':old,'new':new})
def element(id):
    start=re.search(r'<(\w+)\b[^>]*\bid="'+re.escape(id)+r'"[^>]*>',s)
    assert start,id
    tag=start.group(1);depth=0
    for m in re.finditer(r'</?'+tag+r'\b[^>]*>',s[start.start():]):
        depth+=-1 if m.group().startswith('</') else 1
        if depth==0:return s[start.start():start.start()+m.end()]
    raise ValueError(id)
def serialize(e):return E.tostring(e,encoding='unicode',method='html',with_tail=False)
def norm(e):return ' '.join(e.text_content().split())
for key in ['supp-table-s4','supp-table-s7']:
    old=element(key);e=html.fromstring(old);t=e.xpath('.//table')[0]
    if key=='supp-table-s4':
        removedid=None
        for row in t.xpath('./thead/tr|./tbody/tr'):
            cells=row.xpath('./th|./td')
            if len(cells)==5:
                if 'FDR-correction set/family' in norm(cells[3]):removedid=cells[3].get('id')
                row.remove(cells[3])
        for cel in t.xpath('.//*[@colspan="5"]'):cel.set('colspan','4')
        assert removedid
        for cel in t.xpath('.//*[@headers]'):
            cel.set('headers',' '.join(v for v in cel.get('headers').split() if v!=removedid))
        ww=[1.1,2.4,.9,6.15]
    else:
        ww=[2.1,1.0,1.05,1.05,1.05,.9,1.15,2.25]
        count=0
        for row in t.xpath('./tbody/tr'):
            cells=row.xpath('./th|./td')
            if len(cells)!=8:continue
            last=cells[-1]
            ems=last.xpath('.//em')
            assert len(ems)==2
            second=ems[1];parent=second.getparent();i=list(parent).index(second)
            if not last.xpath('.//br'):parent.insert(i,E.Element('br'))
            count+=1
        assert count==17
    for cg in t.xpath('./colgroup'):t.remove(cg)
    cg=E.Element('colgroup')
    for v in ww:E.SubElement(cg,'col',style=f'width: {100*v/sum(ww):.7f}%;')
    t.insert(0,cg)
    t.set('style',(t.get('style','')+';table-layout:fixed;width:100%;').lstrip(';'))
    style=E.Element('style');style.text=f'#{key} table {{ table-layout: fixed; width: 100%; }}\n'
    # Match the Word proportions without changing the accepted base font sizes.
    style.text+=f'#{key} .gt_row, #{key} .gt_col_heading {{ overflow-wrap: normal; word-break: normal; }}\n'
    e.insert(0,style)
    change(old,serialize(e),key)
# Rename existing age/sex figures first, using one simultaneous mapping.
for pattern,mapping,key in [
    (r'fig-s(?:16|17)\b',{'fig-s16':'fig-s17','fig-s17':'fig-s18'},'existing_figure_anchors'),
    (r'Figure S(?:16|17)\b',{'Figure S16':'Figure S17','Figure S17':'Figure S18'},'existing_figure_labels'),
    (r'figure-s(?:16-and-table-s14|17-and-table-s15)',{'figure-s16-and-table-s14':'figure-s17-and-table-s14','figure-s17-and-table-s15':'figure-s18-and-table-s15'},'existing_section_ids')]:
    before=s;s=re.sub(pattern,lambda m:mapping[m.group()],s)
    changes.append({'key':key,'regex':pattern,'map':mapping,'matches':len(re.findall(pattern,before))})
# The next person-level paragraph has short hyperlink labels, not "Figure S...".
for newanchor,oldlabel,newlabel in [('fig-s17','S16','S17'),('fig-s18','S17','S18')]:
    old=f'<a href="#{newanchor}">{oldlabel}</a>';new=f'<a href="#{newanchor}">{newlabel}</a>'
    assert old in s;change(old,new,'Results short reference '+newlabel)
old=element('fig-s15');e=html.fromstring(old);ims=e.xpath('.//img');assert len(ims)==2
am=json.loads((j/'attempt_01/caption_reference_amendments.json').read_text())
caps=next(v['new'] for v in am if v['position']=='S15 split captions').split('\n\n')
figures=[]
for k,(im,cap) in enumerate(zip(ims,caps),15):
    f=E.Element('figure',id=f'fig-s{k}',attrib={'class':'display-figure figure'})
    f.append(deepcopy(im));fc=E.SubElement(f,'figcaption');strong=E.SubElement(fc,'strong');strong.text=f'Supplementary Figure S{k}.';strong.tail=cap.split('. ',1)[1]
    strong.tail=' '+strong.tail;figures.append(serialize(f))
new=figures[0]+'\n<h3 id="supplementary-figure-s16-observed-timing">Supplementary Figure S16. Observed timing across chronotype and study sites</h3>\n'+figures[1]
change(old,new,'split_S15_into_S15_S16')
oldheading='Supplementary Figure S15 and Table S13. Chronotype and timing'
assert s.count(oldheading)==1
change(oldheading,'Supplementary Figure S15. Adjusted chronotype associations','S15 heading')
old='show adjusted estimates and observed timing distributions.'
new='show adjusted estimates; <a href="#fig-s16">Supplementary Figure S16</a> shows observed timing distributions.'
change(old,new,'Results chronotype references')
candidate=out/'ZaunerEtAl2026_NatHealth_phase3_brown.html';candidate.write_text(s)
# Store targeted fragments and a reversible patch recipe; coordinator controls integration.
for i,v in enumerate(changes,1):
    if 'old' in v:
        for side in ['old','new']:
            path=out/f'{i:02d}_{side}.html';path.write_text(v.pop(side));v[side+'_file']=path.name
(out/'delta_manifest.json').write_text(json.dumps({'baseline_path':str(src.relative_to(root)),'baseline_sha256':hashlib.sha256(original.encode()).hexdigest(),'candidate_sha256':hashlib.sha256(s.encode()).hexdigest(),'changes':changes,'browser_qa':'HELD pending coordinator release of the serial slot'},indent=2)+'\n')
print(candidate)
