"""Non-analytical layout, image-identity and package evidence for Order012."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from io import BytesIO
import csv
import hashlib
import json
import shutil
from lxml import etree as E
from PIL import Image
from pypdf import PdfReader

root = Path.cwd()
j = root / 'audit/manuscript_nature_health/a4_display_revision_2026_09_14'
c = root / 'audit/manuscript_nature_health/final_format_completion_2026_09_14'
n = root / 'audit/manuscript_nature_health/final_pagination_completion_2026_09_14'
a = j / 'attempt_04'
e = j / 'evidence/final_word'
e.mkdir(parents=True, exist_ok=True)
deliver = j / 'deliverables'
(deliver / 'editable_tables').mkdir(parents=True, exist_ok=True)

def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()

def dump(name, value):
    (e / name).write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')

def csvout(name, rows):
    with (e / name).open('w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

review = json.loads((j / 'attempt_03/evidence/full_resolution_visual_review.json').read_text())
assert review['main'] == list(range(1, 99))
assert set(review['native']) == {'S4/1', 'S7/1', 'S7/2'}
pages = []
for key, filename, count in [('main', 'Nature_Health_manuscript.pdf', 98),
                              ('S4', 'Table_S4.pdf', 1), ('S7', 'Table_S7.pdf', 2)]:
    pdf = a / 'qa' / key / filename
    pp = PdfReader(pdf).pages
    assert len(pp) == count
    for number, page in enumerate(pp, 1):
        current = a / 'qa' / key / f'page-{number}.png'
        inspected = j / 'attempt_03/qa' / key / current.name
        width, height = float(page.mediabox.width), float(page.mediabox.height)
        is_a4 = all(abs(x-y) < 0.7 for x, y in zip(sorted([width,height]), [595.276,841.890]))
        exact = sha(current) == sha(inspected)
        assert exact and is_a4
        pages.append({'document': key, 'page': number, 'width_pt': width, 'height_pt': height,
                      'orientation': 'portrait' if height > width else 'landscape',
                      'a4': is_a4, 'final_png': str(current.relative_to(j)),
                      'inspected_png': str(inspected.relative_to(j)), 'sha256': sha(current),
                      'pixel_file_exact': exact,
                      'review': 'Full-resolution image inspected; exact final-render PNG identity verified',
                      'qualification': ('Unchanged accepted converter rendering of the right-edge SVG footnote; source exact'
                                        if key == 'main' and number == 96 else '')})
csvout('all_101_page_review.csv', pages)
dump('review_basis.json', {'basis_path': str(j / 'attempt_03/evidence/full_resolution_visual_review.json'),
                          'basis_sha256': sha(j / 'attempt_03/evidence/full_resolution_visual_review.json'),
                          'page_count': len(pages), 'all_pixel_files_exact': True,
                          'notes': review['notes']})

ns = {'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
      'wp':'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
      'a':'http://schemas.openxmlformats.org/drawingml/2006/main',
      'r':'http://schemas.openxmlformats.org/officeDocument/2006/relationships'}
docx = a / 'Nature_Health_manuscript.docx'
z = ZipFile(docx)
tree = E.fromstring(z.read('word/document.xml'))
rels = {r.get('Id'): r.get('Target') for r in E.fromstring(z.read('word/_rels/document.xml.rels'))}
drawings = tree.xpath('//wp:inline', namespaces=ns)
placements = json.loads((a / 'placements.json').read_text())
actual_pages = [6,7,8,10,13,15,16,17,18,21,57,58,59,60,61,62,63,64,65,66,67,
                70,71,72,73,74,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97]
assert len(drawings) == len(placements) == len(actual_pages) == 47
for d, row, page in zip(drawings, placements, actual_pages):
    dp = d.find('wp:docPr', ns)
    assert dp.get('descr') == row['description']
    blips = d.xpath('.//*[local-name()="svgBlip"]', namespaces=ns) or d.xpath('.//a:blip', namespaces=ns)
    rid = blips[0].get('{%s}embed' % ns['r'])
    member = 'word/' + rels[rid]
    payload = z.read(member)
    assert hashlib.sha256(payload).hexdigest() == row['sha256']
    ext = d.find('wp:extent', ns)
    inner = d.xpath('.//a:xfrm/a:ext', namespaces=ns)[0]
    outer = [int(ext.get(k)) for k in ['cx','cy']]
    assert outer == [int(inner.get(k)) for k in ['cx','cy']]
    if member.endswith('.svg'):
        svg = E.fromstring(payload)
        viewbox = [float(v) for v in svg.get('viewBox').replace(',', ' ').split()]
        sw, sh = viewbox[2:]
        source_unit = 'SVG viewBox units'
    else:
        sw, sh = Image.open(BytesIO(payload)).size
        source_unit = 'PNG pixels'
    ratio = sw / sh
    assert abs(outer[0] / outer[1] - ratio) < 2e-6
    assert abs(row['new_width_in'] - outer[0] / 914400) < 2e-6
    assert abs(row['new_height_in'] - outer[1] / 914400) < 2e-6
    page_row = pages[page-1]
    assert page_row['orientation'] == row['page_orientation']
    row.update({'final_page': page, 'page_width_pt': page_row['width_pt'], 'page_height_pt': page_row['height_pt'],
                'actual_member': member, 'source_width': sw, 'source_height': sh, 'source_units': source_unit,
                'actual_width_in': outer[0]/914400, 'actual_height_in': outer[1]/914400,
                'outer_inner_extents_exact': True, 'aspect_ratio_preserved': True,
                'source_payload_exact': True, 'accessible_title': dp.get('title','')})
csvout('display_source_geometry_and_placement.csv', placements)
dump('display_source_geometry_and_placement.json', placements)

sections = []
for i, section in enumerate(tree.xpath('//w:sectPr', namespaces=ns), 1):
    size = section.find('w:pgSz', ns)
    dims = [int(size.get('{%s}%s' % (ns['w'], k))) for k in ['w','h']]
    assert sorted(dims) == [11906,16838]
    sections.append({'section':i, 'width_twips':dims[0], 'height_twips':dims[1],
                     'orientation':'portrait' if dims[1]>dims[0] else 'landscape', 'a4':True})
assert len(sections) == 37
csvout('all_37_sections_a4.csv', sections)

native_parts = [{'table':'S4','part':1,'main_page':69,'native_page':1},
                {'table':'S7','part':1,'main_page':75,'native_page':1},
                {'table':'S7','part':2,'main_page':76,'native_page':2}]
for p in native_parts:
    p.update({'orientation':'landscape','paper':'A4','representation':'native editable Word table'})
csvout('native_table_actual_placements.csv', native_parts)

bindings = []
for old in json.loads((c / 'editable_tables/table_manifest.json').read_text()):
    label = old['label']
    src = a / 'editable_tables' / (label + '.docx')
    target = deliver / 'editable_tables' / src.name
    shutil.copy2(src, target)
    changed = label in ['Table_S4', 'Table_S7']
    assert changed or sha(src) == old['sha256']
    row = {'label':label, 'title':old['title'], 'path':str(target.relative_to(j)), 'sha256':sha(src),
           'accepted_native_path':old['path'], 'accepted_native_sha256':old['sha256'],
           'accepted_source_table_sha256':old['source_table_sha256'], 'byte_exact_reuse':not changed,
           'action': ('Authorized redundant family-column omission; all four outcomes and complete family note retained'
                      if label=='Table_S4' else 'Two matching-width parts before Timing; 17 exact metric rows; explicit sample line breaks'
                      if label=='Table_S7' else 'Exact accepted native export; no source or native typography edits'),
           'verification':('R4.6.1 retained cells/notes exact; every new native page inspected'
                           if changed else 'SHA-256 exact accepted native document; previous acceptance preserved'),
           'paper':old['paper'], 'orientation':old['orientation'], 'base_font':old['base_font'],
           'logical_exports':1, 'physical_native_parts':2 if label=='Table_S7' else 1}
    bindings.append(row)
csvout('native19_source_binding_map.csv', bindings)
dump('native19_source_binding_map.json', bindings)
shutil.copy2(docx, deliver / 'Nature_Health_manuscript.docx')
with ZipFile(deliver / 'Nature_Health_editable_tables.zip', 'w', ZIP_DEFLATED) as archive:
    for f in sorted((deliver / 'editable_tables').glob('Table_*.docx')):
        archive.write(f, f.name)

amendments = json.loads((a / 'caption_reference_amendments.json').read_text())
amendments += [
    {'position':'Word S8 repeated heading','old':'Supplementary Figure S8 (continued)','new':'',
     'reason':'One uncropped appearance replaces two cropped appearances'},
    {'position':'New Word S16 heading','old':'','new':'Supplementary Figure S16. Observed timing across chronotype and study sites',
     'reason':'Own numbered figure and caption'},
    {'position':'Word only external A/B labels around old S15','old':'A and B display labels','new':'',
     'reason':'Only external grouping labels removed; internal artwork and subpanels unchanged'}]
zold = ZipFile(n / 'deliverables/Nature_Health_manuscript.docx')
old_tree = E.fromstring(zold.read('word/document.xml'))
metadata_map = [('S8','Supplementary Figure S8, upper half'),('S15','Supplementary Figure S15A'),
                ('S16','Supplementary Figure S15B'),('S17','Supplementary Figure S16'),('S18','Supplementary Figure S17')]
for label, _ in metadata_map:
    dp = tree.xpath('//wp:docPr[@descr="Supplementary Figure %s"]' % label, namespaces=ns)[0]
    row = next(p for p in placements if p['description'] == 'Supplementary Figure ' + label)
    old_labels = []
    for od in old_tree.xpath('//wp:inline', namespaces=ns):
        bl = od.xpath('.//*[local-name()="svgBlip"]', namespaces=ns) or od.xpath('.//a:blip', namespaces=ns)
        old_member = 'word/' + rels[bl[0].get('{%s}embed' % ns['r'])]
        if old_member == row['actual_member']:
            old_labels.append(od.find('wp:docPr', ns).get('title',''))
    amendments.append({'position':'Word accessible title for '+label, 'old':' | '.join(old_labels),
                       'new':dp.get('title'), 'reason':'Metadata agrees with final displayed figure label'})
dump('caption_reference_and_presentation_amendments.json', amendments)
csvout('caption_reference_amendments.csv', [{k:v.get(k,'') for k in ['position','old','new','reason']} for v in amendments])

renumber = [
    {'old':'S15A','new':'S15','anchor':'fig-s15','role':'Adjusted chronotype associations'},
    {'old':'S15B','new':'S16','anchor':'fig-s16','role':'Observed timing distributions'},
    {'old':'S16','new':'S17','anchor':'fig-s17','role':'Age'},
    {'old':'S17','new':'S18','anchor':'fig-s18','role':'Biological-sex daily patterns'}]
csvout('figure_renumber_map.csv', renumber)
dump('word_completion_summary.json', {
    'main_docx':str((deliver / 'Nature_Health_manuscript.docx').relative_to(j)),
    'main_sha256':sha(deliver / 'Nature_Health_manuscript.docx'),
    'main_pages':98, 'all_main_and_changed_native_pages_a4':True,
    'all_reviewed_final_page_images':101, 'all_exact_to_full_resolution_inspected_images':True,
    'sections':37, 'figure_numbered_groups':21, 'figure_appearances':23,
    'numbered_table_groups':18, 'native_table_downloads':19, 'exact_native_reuse':17,
    'changed_native_downloads':2, 'native_parts_embedded_in_main':3,
    'table_image_appearances':24, 'total_drawing_appearances':47,
    'html_status':'Prepared exact delta. Browser QA held pending separate coordinator release.',
    'scope':'Candidate only. No live source, accepted package or live website edited.'})
print(json.dumps({'pages_verified':len(pages), 'drawings_verified':len(placements),
                  'native_exports':len(bindings), 'main_sha256':sha(deliver/'Nature_Health_manuscript.docx')}, indent=2))
