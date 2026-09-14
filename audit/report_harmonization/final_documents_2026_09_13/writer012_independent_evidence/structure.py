from pathlib import Path
from zipfile import ZipFile
from io import BytesIO
from lxml import etree as ET
from PIL import Image
from pypdf import PdfReader
import csv, hashlib, json, re

root = Path.cwd()
j = root / 'audit/manuscript_nature_health/a4_display_revision_2026_09_14'
n = root / 'audit/manuscript_nature_health/final_pagination_completion_2026_09_14'
t = Path('/private/tmp/writer012-independent.cieJLM')
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
checks = []
def check(name, condition, detail=''):
    checks.append(dict(check=name, passed=bool(condition), detail=detail))
    assert condition, (name, detail)

manifest = list(csv.DictReader((j/'word_candidate_manifest.csv').open()))
check('318 exact unique non-circular members', len(manifest)==318 and
      len({r['path'] for r in manifest})==318 and
      all(r['path']!='word_candidate_manifest.csv' and not (j/r['path']).is_symlink()
          and (j/r['path']).stat().st_size==int(r['bytes']) and sha(j/r['path'])==r['sha256']
          for r in manifest))
current = j/'deliverables/Nature_Health_manuscript.docx'
check('Final Word delivery identity', sha(current)=='6f0ce7a50b608f91d24c31ae0b9b0edefe15828ed4f966732ea616c6e395a570'
      and sha(current)==sha(j/'attempt_04/Nature_Health_manuscript.docx'))
with ZipFile(current) as z, ZipFile(n/'deliverables/Nature_Health_manuscript.docx') as old:
    check('ZIP member set unchanged', set(z.namelist())==set(old.namelist()))
    changes = [p for p in z.namelist() if z.read(p)!=old.read(p)]
    check('Only document.xml differs and 87 other ZIP members exact',
          changes==['word/document.xml'] and len(z.namelist())==88)
    ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
        'wp':'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
        'a':'http://schemas.openxmlformats.org/drawingml/2006/main',
        'r':'http://schemas.openxmlformats.org/officeDocument/2006/relationships'}
    doc=ET.fromstring(z.read('word/document.xml'))
    rels={v.get('Id'):v.get('Target') for v in ET.fromstring(z.read('word/_rels/document.xml.rels'))}
    draws=doc.xpath('//wp:inline',namespaces=ns)
    placement=list(csv.DictReader((j/'evidence/final_word/display_source_geometry_and_placement.csv').open()))
    check('47 exact drawing identities with preserved aspect ratio',len(draws)==len(placement)==47)
    for i,(d,row) in enumerate(zip(draws,placement),1):
        b=d.xpath('.//*[local-name()="svgBlip"]',namespaces=ns) or d.xpath('.//a:blip',namespaces=ns)
        member='word/'+rels[b[0].get('{%s}embed'%ns['r'])]
        payload=z.read(member)
        if member.endswith('.svg'):
            sw,sh=[float(v) for v in ET.fromstring(payload).get('viewBox').replace(',',' ').split()][2:]
        else:
            sw,sh=Image.open(BytesIO(payload)).size
        ex=d.find('wp:extent',ns);inner=d.xpath('.//a:xfrm/a:ext',namespaces=ns)[0]
        dims=[int(ex.get(k)) for k in ('cx','cy')]
        check(f'Drawing {i} source and proportional geometry',
              member==row['actual_member'] and hashlib.sha256(payload).hexdigest()==row['sha256']
              and dims==[int(inner.get(k)) for k in ('cx','cy')]
              and abs(dims[0]/dims[1]-sw/sh)<2e-6
              and abs(dims[0]/914400-float(row['new_width_in']))<2e-6
              and abs(dims[1]/914400-float(row['new_height_in']))<2e-6)
    check('37 A4 sections',len(doc.xpath('//w:sectPr',namespaces=ns))==37 and
          all(sorted([int(v.get('{%s}%s'%(ns['w'],k))) for k in ('w','h')])==[11906,16838]
              for v in doc.xpath('//w:sectPr/w:pgSz',namespaces=ns)))
    check('No image crop rectangles',not doc.xpath('//a:srcRect',namespaces=ns))

for kind,file,count in [('main','Nature_Health_manuscript.pdf',98),('S4','Table_S4.pdf',1),('S7','Table_S7.pdf',2)]:
    pages=PdfReader(j/'attempt_04/qa'/kind/file).pages
    check(f'{kind} actual PDF count',len(pages)==count)
    for i,page in enumerate(pages,1):
        dims=sorted([float(page.mediabox.width),float(page.mediabox.height)])
        check(f'{kind} page {i} A4 and reviewed pixel identity',
              all(abs(a-b)<.7 for a,b in zip(dims,[595.276,841.890])) and
              sha(j/'attempt_04/qa'/kind/f'page-{i}.png')==sha(j/'attempt_03/qa'/kind/f'page-{i}.png'))
native=list(csv.DictReader((j/'evidence/final_word/native19_source_binding_map.csv').open()))
with ZipFile(j/'deliverables/Nature_Health_editable_tables.zip') as z:
    check('19 exact native download ZIP members',len(z.namelist())==19 and
          set(z.namelist())=={Path(v['path']).name for v in native} and
          all(hashlib.sha256(z.read(Path(v['path']).name)).hexdigest()==v['sha256']==sha(j/v['path']) for v in native))

hr=j/'html_candidate_round2'
delta=json.loads((hr/'delta_manifest.json').read_text())
baseline=(root/delta['baseline_path']).read_text()
forward=baseline
history=[]
for v in delta['changes']:
    before=forward
    if 'old_file' in v:
        old=(hr/v['old_file']).read_text();new=(hr/v['new_file']).read_text()
        check('Unique HTML replacement '+v['key'],forward.count(old)==1)
        forward=forward.replace(old,new,1)
        history.append(('literal',old,new))
    else:
        check('Exact regex match count '+v['key'],len(re.findall(v['regex'],forward))==v['matches'])
        forward=re.sub(v['regex'],lambda m:v['map'][m.group()],forward)
        history.append(('map',v['map'],None))
    check('HTML operation changed text '+v['key'],forward!=before)
actual=(hr/'ZaunerEtAl2026_NatHealth_phase3_brown.html').read_text()
check('Complete exact HTML forward proof',forward==actual and hashlib.sha256(forward.encode()).hexdigest()==delta['candidate_sha256'])
reverse=actual
for typ,old,new in reversed(history):
    if typ=='literal':
        check('Unique literal reverse',reverse.count(new)==1)
        reverse=reverse.replace(new,old,1)
    else:
        inv={v:k for k,v in old.items()}
        pattern='|'.join(re.escape(k) for k in sorted(inv,key=len,reverse=True))
        reverse=re.sub(pattern,lambda m:inv[m.group()],reverse)
check('Complete exact HTML reverse proof',reverse==baseline and hashlib.sha256(reverse.encode()).hexdigest()==delta['baseline_sha256'])
check('Owner package unchanged after read-only audit',all(sha(j/r['path'])==r['sha256'] for r in manifest))
with (t/'structural_checks.csv').open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=['check','passed','detail']);w.writeheader();w.writerows(checks)
(t/'structural_summary.json').write_text(json.dumps({'passed':len(checks),'owner_members':318,
    'pdf_pages':101,'drawings':47,'native_zip_members':19,'html_exact_forward_reverse':True,
    'owner_unchanged':True},indent=2)+'\n')
print('WRITER012_NONANALYTICAL_STRUCTURE=PASS',len(checks),'checks; owner318; PDF101; drawings47; ZIP19; HTML forward/reverse exact')
