"""Order012: display-only OOXML changes to exact accepted packages.

No scientific calculation. Source content checks are performed separately in R.
All accepted ZIP members except word/document.xml are preserved byte-for-byte.
"""
from pathlib import Path
from zipfile import ZipFile
from copy import deepcopy
from lxml import etree as E
import argparse, hashlib, json, re, shutil

ROOT = Path.cwd()
J = ROOT / 'audit/manuscript_nature_health/a4_display_revision_2026_09_14'
C = ROOT / 'audit/manuscript_nature_health/final_format_completion_2026_09_14'
N = ROOT / 'audit/manuscript_nature_health/final_pagination_completion_2026_09_14'
NS = {'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
      'wp':'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
      'a':'http://schemas.openxmlformats.org/drawingml/2006/main',
      'r':'http://schemas.openxmlformats.org/officeDocument/2006/relationships'}
W = '{'+NS['w']+'}'
EMU = 914400
AMENDMENTS = []

def text(e): return ''.join(e.xpath('.//w:t/text()', namespaces=NS))
def child(parent, tag, **attrs):
    e = parent.find('w:'+tag, NS)
    if e is None: e = E.SubElement(parent, W+tag)
    for k,v in attrs.items(): e.set(W+k,str(v))
    return e
def pr(p):
    e=p.find('w:pPr',NS)
    if e is None: e=E.Element(W+'pPr');p.insert(0,e)
    return e
def run(s):
    r=E.Element(W+'r');t=E.SubElement(r,W+'t');t.set('{http://www.w3.org/XML/1998/namespace}space','preserve');t.text=s
    return r
def para_like(p,s):
    out=deepcopy(p)
    for e in list(out):
        if e.tag!=W+'pPr': out.remove(e)
    out.append(run(s))
    return out
def replace_text(p, old, new, key):
    before=text(p)
    found=False
    for t in p.xpath('.//w:t',namespaces=NS):
        if old in (t.text or ''):t.text=t.text.replace(old,new);found=True
    assert found,(key,old)
    AMENDMENTS.append({'position':key,'old':before,'new':text(p)})
def read_doc(p):
    z=ZipFile(p);r=E.fromstring(z.read('word/document.xml'))
    return z,r,r.find('w:body',NS)
def save_doc(z,r,out):
    out.parent.mkdir(parents=True,exist_ok=True)
    assert not out.exists(),f'Preserve previous attempt: {out}'
    with ZipFile(out,'w') as dst:
        for info in z.infolist():
            value=E.tostring(r,xml_declaration=True,encoding='UTF-8',standalone=True) if info.filename=='word/document.xml' else z.read(info.filename)
            dst.writestr(info,value)
def a4(s,landscape=False):
    child(s,'pgSz',w=16838 if landscape else 11906,h=11906 if landscape else 16838,orient='landscape' if landscape else 'portrait')
def widths(t,ww):
    ww=[round(v*1440) for v in ww]
    tp=t.find('w:tblPr',NS);child(tp,'tblW',type='dxa',w=sum(ww))
    grid=t.find('w:tblGrid',NS)
    for e in list(grid):grid.remove(e)
    for v in ww:E.SubElement(grid,W+'gridCol',{W+'w':str(v)})
    for row in t.findall('w:tr',NS):
        pos=0
        for c in row.findall('w:tc',NS):
            cp=c.find('w:tcPr',NS);sp=cp.find('w:gridSpan',NS)
            n=int(sp.get(W+'val')) if sp is not None else 1
            child(cp,'tcW',type='dxa',w=sum(ww[pos:pos+n]));pos+=n
        assert pos==len(ww),(pos,len(ww),text(row))
def set_table_pagination(t):
    rows=t.findall('w:tr',NS)
    for i,row in enumerate(rows):
        rp=child(row,'trPr');child(rp,'cantSplit')
        if i<2:child(rp,'tblHeader')
        for p in row.xpath('.//w:p',namespaces=NS):
            pp=pr(p)
            child(pp,'keepNext',val='1' if len(row.findall('w:tc',NS))==1 else '0')
            child(pp,'spacing',before=0,after=0,line=240,lineRule='auto')
def native(which,out):
    z,r,b=read_doc(C/'editable_tables'/f'Table_{which}.docx')
    t=b.find('w:tbl',NS)
    if which=='S4':
        for row in t.findall('w:tr',NS):
            cells=row.findall('w:tc',NS)
            if len(cells)==5:row.remove(cells[3])
            else:
                assert len(cells)==1
                cells[0].find('w:tcPr/w:gridSpan',NS).set(W+'val','4')
        widths(t,[1.1,2.4,.9,6.15]);set_table_pagination(t)
        parts=[t]
    else:
        rows=t.findall('w:tr',NS)
        assert len(rows)==25 and text(rows[15])=='Timing'
        for row in rows[2:]:
            cells=row.findall('w:tc',NS)
            if len(cells)!=8:continue
            for tx in cells[-1].xpath('.//w:t',namespaces=NS):
                if ';' in (tx.text or ''):
                    rr=tx.getparent();rr.append(E.Element(W+'br'))
        widths(t,[2.1,1.0,1.05,1.05,1.05,.9,1.15,2.25]);set_table_pagination(t)
        t2=deepcopy(t)
        for row in list(t.findall('w:tr',NS))[15:]:t.remove(row)
        for row in list(t2.findall('w:tr',NS))[2:15]:t2.remove(row)
        spacer=E.Element(W+'p');child(pr(spacer),'spacing',before=0,after=0,line=20,lineRule='exact')
        child(pr(spacer),'pageBreakBefore')
        i=list(b).index(t);b.insert(i+1,spacer);b.insert(i+2,t2)
        parts=[t,t2]
    for s in r.xpath('//w:sectPr',namespaces=NS):
        a4(s,True);child(s,'pgMar',top=792,bottom=792,left=648,right=648,header=400,footer=400,gutter=0)
    save_doc(z,r,out)
    note=[e for e in b if e.tag==W+'p'][1 if which=='S4' else 2]
    assert text(note).startswith('All four' if which=='S4' else 'This summary')
    return [deepcopy(t) for t in parts],deepcopy(note)

def main(out, natives, attempt):
    z,r,b=read_doc(N/'deliverables/Nature_Health_manuscript.docx')
    original=list(b)
    at=lambda i:original[i-1]
    # Establish intended A4 orientation from each original section's display class.
    landscape={2,6,11,14,16,19,23,24,26,28,30,32,34}
    sections=r.xpath('//w:sectPr',namespaces=NS)
    assert len(sections)==35
    for i,s in enumerate(sections,1):
        a4(s,i in landscape)
        if i==4:child(s,'pgMar',top=792,bottom=792,left=1440,right=1440,header=400,footer=400,gutter=0)
    # Full-width Figure2 plus its complete caption requires the A4 display-page
    # vertical margins, not a reduction of the author-approved text width.
    for target,display in [(at(48),False),(at(50),True)]:
        endp=E.Element(W+'p');pp=pr(endp)
        child(pp,'suppressLineNumbers');child(pp,'spacing',before=0,after=0,line=20,lineRule='exact')
        ss=deepcopy(sections[4]);child(ss,'type',val='nextPage')
        if display:child(ss,'pgMar',top=648,bottom=648,left=1440,right=1440,header=400,footer=400,gutter=0)
        pp.append(ss);b.insert(list(b).index(target),endp)
    child(pr(at(48)),'pageBreakBefore',val=0)
    child(pr(at(48)),'keepNext',val=1)
    # Replace only S4/S7 PNG placements with accepted editable structures.
    for indices,key in [([574,575],'S4'),([621,622,623,624],'S7')]:
        pos=list(b).index(at(indices[0])); parts,note=natives[key]
        inserts=[]
        for k,table in enumerate(parts):
            if k:
                p=E.Element(W+'p');child(pr(p),'pageBreakBefore');child(pr(p),'spacing',before=0,after=0,line=20,lineRule='exact');inserts.append(p)
            inserts.append(deepcopy(table))
        inserts.append(deepcopy(note))
        for i in indices:b.remove(at(i))
        for n,e in enumerate(inserts):b.insert(pos+n,e)
    # S8: one full, unchanged SVG. No panel crop or continuation label.
    for i in [644,645]:b.remove(at(i))
    for e in at(643).xpath('.//a:srcRect',namespaces=NS):e.getparent().remove(e)
    at(643).find('.//wp:docPr',NS).set('descr','Supplementary Figure S8')
    for i in [639,641]:child(pr(at(i)),'spacing',before=0,after=40,line=240,lineRule='auto')
    # Collision-safe renumber of existing age/sex anchors and their hyperlinks.
    person_refs=[(p,text(p)) for p in b.findall('w:p',NS) if 'give the complete results' in text(p)]
    renumber={'fig-s16':'fig-s17','fig-s17':'fig-s18'}
    for e in r.xpath('//w:bookmarkStart|//w:hyperlink',namespaces=NS):
        attr=W+('name' if e.tag==W+'bookmarkStart' else 'anchor')
        old=e.get(attr)
        if old in renumber:
            e.set(attr,renumber[old])
            if e.tag==W+'hyperlink':
                for t in e.xpath('.//w:t',namespaces=NS):t.text=(t.text or '').replace(old[4:].upper(),renumber[old][4:].upper())
    for p,before in person_refs:
        if before!=text(p):AMENDMENTS.append({'position':'Results person-level paragraph reference','old':before,'new':text(p)})
    for i,old,new in [(739,'Figure S16','Figure S17'),(742,'Figure S16','Figure S17'),(751,'Figure S17','Figure S18'),(754,'Figure S17','Figure S18')]:
        replace_text(at(i),old,new,f'Word block {i}')
    at(741).find('.//wp:docPr',NS).set('descr','Supplementary Figure S17')
    at(753).find('.//wp:docPr',NS).set('descr','Supplementary Figure S18')
    # Split the exact existing chronotype caption into its two scientific roles.
    oldcap=text(at(730))
    cap15='Supplementary Figure S15. Chronotype and timing of personal light exposure. Study-site-adjusted associations of sleep-timing-based corrected midsleep on Free days and questionnaire-based morningness-eveningness with the analysed timing metrics. Points are estimates and bars are 95% confidence intervals; the two chronotype instruments remain separate. Near-eye estimates provide ocular-exposure evidence; chest estimates, where shown, are complementary non-ocular evidence.'
    cap16='Supplementary Figure S16. Observed timing across chronotype and study sites. Observed participant-day timing values across chronotype and country-coded study sites for the samples used in the corresponding models. Each point represents one participant-day in a fitted sample. This figure is descriptive and does not replace the adjusted models or estimate independent site effects. Near-eye estimates provide ocular-exposure evidence; chest estimates, where shown, are complementary non-ocular evidence.'
    AMENDMENTS.append({'position':'S15 split captions','old':oldcap,'new':cap15+'\n\n'+cap16})
    replace_text(at(725),'Supplementary Figure S15 and Table S13. Chronotype and timing','Supplementary Figure S15. Adjusted chronotype associations','S15 heading')
    for i in [726,728,730]:b.remove(at(i))
    new15=para_like(at(730),cap15);pidx=list(b).index(at(727));b.insert(pidx+1,new15)
    h16=para_like(at(725),'Supplementary Figure S16. Observed timing across chronotype and study sites')
    child(pr(h16),'pageBreakBefore')
    new_id=str(max(int(e.get(W+'id')) for e in r.xpath('//w:bookmarkStart',namespaces=NS))+1)
    bs=E.Element(W+'bookmarkStart',{W+'id':new_id,W+'name':'fig-s16'});be=E.Element(W+'bookmarkEnd',{W+'id':new_id})
    h16.insert(1,bs);h16.insert(2,be)
    b.insert(list(b).index(at(729)),h16)
    b.insert(list(b).index(at(729))+1,para_like(at(730),cap16))
    at(727).find('.//wp:docPr',NS).set('descr','Supplementary Figure S15')
    at(729).find('.//wp:docPr',NS).set('descr','Supplementary Figure S16')
    child(pr(at(729)),'pageBreakBefore',val=0)
    for p in b.findall('w:p',NS):
        if 'show adjusted estimates and observed timing distributions.' in text(p):
            before=text(p)
            tx=p.xpath('.//w:t[contains(text(),"show adjusted estimates and observed timing distributions.")]',namespaces=NS)[0]
            tx.text=tx.text.replace('show adjusted estimates and observed timing distributions.','show adjusted estimates; ')
            link=deepcopy(p.find("w:hyperlink[@w:anchor='fig-s15']",NS));link.set(W+'anchor','fig-s16')
            for t in link.xpath('.//w:t',namespaces=NS):t.text=t.text.replace('S15','S16')
            p.append(link);p.append(run(' shows observed timing distributions.'))
            AMENDMENTS.append({'position':'Results chronotype paragraph reference','old':before,'new':text(p)})
    # Proportional placement. Geometry is source XML geometry, not a numerical result.
    rels=E.fromstring(z.read('word/_rels/document.xml.rels'))
    relmap={e.get('Id'):'word/'+e.get('Target') for e in rels}
    placements=[]
    bodylist=list(b);start=0
    for last,e in enumerate(bodylist):
        s=e if e.tag==W+'sectPr' else e.find('w:pPr/w:sectPr',NS)
        if s is None:continue
        sz=s.find('w:pgSz',NS);mar=s.find('w:pgMar',NS)
        availw=(int(sz.get(W+'w'))-int(mar.get(W+'left'))-int(mar.get(W+'right')))/1440
        landscape_page=int(sz.get(W+'w'))>int(sz.get(W+'h'))
        for p in bodylist[start:last+1]:
            for d in p.xpath('.//wp:inline',namespaces=NS):
                docpr=d.find('wp:docPr',NS);desc=docpr.get('descr','');ext=d.find('wp:extent',NS)
                # Keep Word's accessible title synchronized with the revised
                # description. Asset filenames remain protected source identities.
                if desc in ('Supplementary Figure S8','Supplementary Figure S15','Supplementary Figure S16','Supplementary Figure S17','Supplementary Figure S18'):
                    docpr.set('title',desc)
                oldw,oldh=int(ext.get('cx'))/EMU,int(ext.get('cy'))/EMU
                embeds=d.xpath('.//@r:embed',namespaces=NS)
                paths=[relmap[v] for v in embeds if v in relmap]
                svg=[v for v in paths if v.endswith('.svg')]
                asset=svg[0] if svg else paths[0]
                if svg:
                    raw=z.read(asset);sr=E.fromstring(raw)
                    vb=[float(v) for v in re.split(r'[ ,]+',sr.get('viewBox').strip())]
                    ratio=vb[2]/vb[3];heightcap=8.5
                    if desc=='Main Figure 1':w=availw;heightcap=9.0
                    elif desc=='Main Figure 2':w=availw;heightcap=9.0
                    elif desc=='Main Figure 3':w=availw;heightcap=7.0
                    elif desc=='Supplementary Figure S3':w=oldw;heightcap=oldh
                    elif desc=='Supplementary Figure S8':w=availw;heightcap=6.5
                    elif desc=='Supplementary Figure S7B':w=availw;heightcap=8.4
                    elif desc=='Supplementary Figure S17':w=availw;heightcap=7.7
                    elif desc in ('Supplementary Figure S10','Supplementary Figure S11'):w=availw;heightcap=7.5
                    else:w=min(availw,max(oldw,6.25));heightcap=8.1 if 'S5' in desc else 8.5
                    h=w/ratio
                    if h>heightcap:h=heightcap;w=h*ratio
                else:
                    ratio=oldw/oldh;w=min(availw,oldw);h=w/ratio
                    cap=5.8 if landscape_page else 8.0
                    if desc=='Main Table 3, part 1 of 4':cap=4.7
                    if desc=='Supplementary Table S10, part 2 of 2':cap=5.0
                    if desc.startswith('Main Table 2'):w=availw;h=w/ratio
                    if h>cap:h=cap;w=h*ratio
                cx,cy=round(w*EMU),round(h*EMU)
                ext.set('cx',str(cx));ext.set('cy',str(cy))
                for inn in d.xpath('.//a:xfrm/a:ext',namespaces=NS):inn.set('cx',str(cx));inn.set('cy',str(cy))
                placements.append({'description':desc,'asset':asset,'sha256':hashlib.sha256(z.read(asset)).hexdigest(),'source_ratio':ratio,'old_width_in':oldw,'old_height_in':oldh,'new_width_in':w,'new_height_in':h,'page_orientation':'landscape' if landscape_page else 'portrait','text_width_in':availw})
        start=last+1
    # Remove only blank first-paragraph spacers directly before the two reduced full figures.
    for i in [642,740]:
        if at(i) in list(b) and not text(at(i)) and not at(i).xpath('.//w:bookmarkStart|.//w:bookmarkEnd|.//w:sectPr',namespaces=NS):b.remove(at(i))
    save_doc(z,r,out)
    (attempt/'placements.json').write_text(json.dumps(placements,indent=2)+'\n')
    (attempt/'caption_reference_amendments.json').write_text(json.dumps(AMENDMENTS,indent=2,ensure_ascii=False)+'\n')

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--attempt',required=True);args=ap.parse_args()
    dest=J/args.attempt;dest.mkdir(parents=True,exist_ok=False)
    native_dir=dest/'editable_tables';native_dir.mkdir()
    pairs={}
    for f in (C/'editable_tables').glob('Table_*.docx'):
        if f.stem not in ['Table_S4','Table_S7']:shutil.copy2(f,native_dir/f.name)
    for name in ['S4','S7']:pairs[name]=native(name,native_dir/f'Table_{name}.docx')
    main(dest/'Nature_Health_manuscript.docx',pairs,dest)
    print(dest)
