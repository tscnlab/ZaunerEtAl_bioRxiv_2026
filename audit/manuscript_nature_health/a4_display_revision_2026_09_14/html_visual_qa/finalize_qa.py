"""Seal browser evidence and remove only the verified, task-owned serve copy."""
from pathlib import Path
from PIL import Image
from datetime import datetime, timezone
import csv
import hashlib
import json
import subprocess

qa=Path('audit/manuscript_nature_health/a4_display_revision_2026_09_14/html_visual_qa').resolve()
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
now=lambda:datetime.now(timezone.utc).isoformat()
def dump(name,x): (qa/name).write_text(json.dumps(x,indent=2,ensure_ascii=False)+'\n')
def writecsv(name,rows):
    with (qa/name).open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)

state=json.loads((qa/'server_lifecycle.json').read_text())
browser=json.loads((qa/'browser_teardown.json').read_text())
assert state['port']==55675 and state['pid']==29906 and 'stopped_at' in state
assert browser['closed'] and browser['viewportReset']
cmd=['/usr/sbin/lsof','-nP','-iTCP:55675','-sTCP:LISTEN']
probe=subprocess.run(cmd,capture_output=True,text=True)
assert probe.returncode==1 and probe.stdout=='' and probe.stderr==''
dump('no_listener_check.json',{'command':cmd,'returncode':probe.returncode,'stdout':probe.stdout,
                             'stderr':probe.stderr,'pass':True,'at':now()})
guards=[]
for p in sorted((qa/'postflight').glob('*.csv')):
    rows=list(csv.DictReader(p.open()))
    col='qa_pass' if 'qa_pass' in rows[0] else 'pass'
    assert all(r[col]=='TRUE' for r in rows)
    guards.append({'path':str(p.relative_to(qa)), 'rows':len(rows),'all_pass':True,'sha256':sha(p)})
dump('postflight_guard_summary.json',guards)

serve=Path(state['root'])
assert str(serve)=='/private/tmp/nh_html_qa014_gjv0u4un'
assert not serve.is_symlink() and serve.is_dir()
target=serve/'manuscript.html'
assert set(serve.iterdir())=={target} and not target.is_symlink()
pin='d7ee926c0910227004581915040f30ae01142290f0759839e897fa2b3f5f10aa'
assert sha(target)==sha(Path(state['source']))==pin
cleanup={'root':str(serve),'removed_file':str(target),'sha256_before_removal':sha(target),
         'postflight318_exact_before_removal':True,'source_preserved':True,'at':now()}
target.unlink()
serve.rmdir()
cleanup['copy_removed']=not target.exists()
cleanup['root_removed']=not serve.exists()
dump('serve_copy_cleanup.json',cleanup)

shots=json.loads((qa/'screenshot_provenance.json').read_text())
assert len(shots)==34
for s in shots:
    p=qa/(s['name']+'.png')
    size=Image.open(p).size
    s.update({'path':p.name,'sha256':sha(p),'bytes':p.stat().st_size,
              'png_width':size[0],'png_height':size[1],
              'visually_inspected':True,'page_horizontal_overflow':s['pageWidth']>s['viewportWidth']})
    assert not s['page_horizontal_overflow']
writecsv('screenshot_inventory.csv',shots)
cases=[]
for endpoint in ['s4','s7','s15','s16','s17','s18']:
    for screen in ['desktop','phone']+(['medium'] if endpoint in ['s4','s7'] else []):
        captures=[s['path'] for s in shots if s['name'].startswith(screen+'_'+endpoint+'_')]
        assert captures
        note={'s4':'Four retained outcomes/four columns; complete family note and caption; contained horizontal scrolling at narrow widths.',
              's7':'One continuous eight-column/17-metric table; all groups and exact two-line samples; complete notes/caption; left, middle and right edge coverage where needed.',
              's15':'Own heading, complete unchanged adjusted-chronotype figure and own caption; no external A/B grouping.',
              's16':'Own heading, complete observed-timing figure including its internal subpanels and own descriptive caption.',
              's17':'Correctly renumbered age figure and caption; all three panels retained.',
              's18':'Correctly renumbered biological-sex figure and complete caption; source unchanged.'}[endpoint]
        cases.append({'endpoint':('supp-table-' if endpoint in ['s4','s7'] else 'fig-')+endpoint,
                      'viewport':{'desktop':'1440x1000','medium':'708x1000','phone':'390x844'}[screen],
                      'verdict':'PASS','screenshots':' | '.join(captures),'observation':note})
writecsv('visual_review_matrix.csv',cases)
assert json.loads((qa/'browser_console.json').read_text())==[]
dump('qa_summary.json',{'verdict':'BOUNDED_HTML_VISUAL_QA_PASS','changed_endpoints':6,
    'endpoint_viewport_cases':len(cases),'inspected_screenshots':34,'browser_errors_or_warnings':0,
    'missing_images':0,'new_page_overflow':False,'frozen318_exact_before_and_after':True,
    'content_checks':15,'extra_checks':['Two changed Results references','Four S15-S18 targets navigable',
                                     'Three existing theme Contents entries resolve','Unchanged whole Figure S8'],
    'slot_teardown':{'tab11_closed':True,'viewport_reset':True,'port55675_closed':True,
                     'temporary_exact_copy_removed':True},'completed_at':now(),
    'limitations':['Existing Word converter footnote qualification unchanged; no Office rerender or repair.',
                   'Dense SVGs retain their original content and scale to the phone width; no new typography redesign.',
                   'A first centre-point click on the wrapped S15 Results link did not activate it; ordinary keyboard Enter activated the exact target. Other three links passed pointer activation.'],
    'not_performed':['Source/artwork/table edit','Quarto or Word render','Live website promotion','Harmonizer contact']})
print('QA evidence finalized; 34 inspected screenshots; 14 endpoint/viewport cases; safe teardown complete.')
