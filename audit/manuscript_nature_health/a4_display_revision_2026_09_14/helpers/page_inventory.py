from pathlib import Path
import subprocess,concurrent.futures,json,sys
from pypdf import PdfReader
j=Path('audit/manuscript_nature_health/a4_display_revision_2026_09_14')
a=j/sys.argv[1];pdf=a/'qa/main/Nature_Health_manuscript.pdf'
pages=PdfReader(pdf).pages
out=a/'evidence/page_text';out.mkdir(exist_ok=True)
def extract(n):
    try:
        t=subprocess.check_output(['/opt/homebrew/bin/pdftotext','-f',str(n),'-l',str(n),'-layout',str(pdf),'-'],text=True,timeout=8)
        (out/f'page-{n}.txt').write_text(t)
        lines=[v.strip() for v in t.splitlines() if v.strip()]
        return {'page':n,'text_status':'ok','chars':len(t),'first':' | '.join(lines[:2])[:130],'last':' | '.join(lines[-3:])[:140]}
    except subprocess.TimeoutExpired:
        return {'page':n,'text_status':'timeout_8s','chars':None,'first':'Visual inspection required','last':''}
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    result=list(pool.map(extract,range(1,len(pages)+1)))
for row,page in zip(result,pages):
    row['width_pt']=float(page.mediabox.width);row['height_pt']=float(page.mediabox.height)
    print(row,flush=True)
(a/'evidence/pdf_page_inventory.json').write_text(json.dumps(result,indent=2)+'\n')
