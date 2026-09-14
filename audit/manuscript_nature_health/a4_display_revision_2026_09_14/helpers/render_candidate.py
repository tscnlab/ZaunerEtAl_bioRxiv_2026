from pathlib import Path
from zipfile import ZipFile
from lxml import etree as E
import sys, subprocess, os, json, time, hashlib

root=Path.cwd()
j=root/'audit/manuscript_nature_health/a4_display_revision_2026_09_14'
a=j/sys.argv[1]
python='/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3'
renderer='/Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py'
env=os.environ.copy()
env['PATH']='/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/override:'+env['PATH']
baseline=root/'audit/manuscript_nature_health/final_pagination_completion_2026_09_14/deliverables/Nature_Health_manuscript.docx'
z0,z1=ZipFile(baseline),ZipFile(a/'Nature_Health_manuscript.docx')
assert set(z0.namelist())==set(z1.namelist())
checks=[{'member':n,'exact':z0.read(n)==z1.read(n)} for n in z0.namelist() if n!='word/document.xml']
assert all(v['exact'] for v in checks)
(a/'evidence/zip_member_preservation.json').write_text(json.dumps(checks,indent=2)+'\n')
for key,src in [('S4',a/'editable_tables/Table_S4.docx'),('S7',a/'editable_tables/Table_S7.docx'),('main',a/'Nature_Health_manuscript.docx')]:
    out=a/'qa'/key
    cmd=[python,renderer,str(src),'--output_dir',str(out),'--dpi','150','--emit_pdf','--verbose']
    t=time.time()
    print('Rendering',key,flush=True)
    result=subprocess.run(cmd,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (a/'evidence'/f'render_{key}.log').write_text(result.stdout)
    (a/'evidence'/f'render_{key}_execution.json').write_text(json.dumps({'command':cmd,'input_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'elapsed_seconds':time.time()-t,'returncode':result.returncode},indent=2)+'\n')
    print(key,'returncode',result.returncode,flush=True)
    if result.returncode:print(result.stdout);sys.exit(result.returncode)
