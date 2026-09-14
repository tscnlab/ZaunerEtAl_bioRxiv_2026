"""Make a complete static browser canvas. Change widths/padding only."""
from pathlib import Path
from lxml import html
import re,json
C=Path(__file__).resolve().parents[1]
src=(C/'inputs/table_s3_original.html').read_text()
src=src.replace('```{=html}\n','').replace('```','')
assert src.count('<table ')==1 and '<colgroup' not in src
cols=[150]+[120]*8
colgroup='<colgroup>'+''.join(f'<col style="width:{w}px">' for w in cols)+'</colgroup>'
src=re.sub(r'(<table [^>]+>)',r'\1'+colgroup,src,count=1)
css='''html,body {margin:0;padding:0;background:white;}
body {width:1158px;padding:24px;box-sizing:border-box;}
#recommendation-context {overflow:visible!important;padding:0!important;}
#recommendation-context .gt_table {width:1110px!important;table-layout:fixed;}
#recommendation-context .gt_row, #recommendation-context .gt_col_heading {padding-left:5px;padding-right:5px;}
'''
dest=C/'project/s3_preview/table_s3.html';dest.parent.mkdir(exist_ok=True)
assert not dest.exists()
dest.write_text('<!doctype html><html><head><meta charset="utf-8"><title>Complete Supplementary Table S3</title></head><body>'+src+'<style>'+css+'</style></body></html>')
before=html.fromstring(src)
after=html.fromstring(dest.read_bytes())
assert before.xpath('//table//th//text()|//table//td//text()')==after.xpath('//table//th//text()|//table//td//text()')
(C/'evidence/s3_presentation_contract.json').write_text(json.dumps(dict(column_widths=cols,table_width=1110,body_width=1158,body_padding=24,font_change=False,text_change=False),indent=2))
print(dest)
