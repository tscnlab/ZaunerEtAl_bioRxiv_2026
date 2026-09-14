"""Order011's sole consolidated correction: grid root and non-margin utility."""
import datetime,shutil
from common import *

assert (EVIDENCE/'packaging_pass.json').is_file()
assert not (EVIDENCE/'correction_pass.json').exists(),'No third candidate pass'
assert json.loads((EVIDENCE/'server_lifecycle.json').read_text())['status']=='stopped'
expected=rows(EVIDENCE/'candidate_inventory.csv')
assert inventory(BUILD)==[dict(path=r['path'],bytes=int(r['bytes']),sha256=r['sha256']) for r in expected]
attempt=OUT/'attempts/01_initial_candidate';assert not attempt.exists()
matrix=rows(PROPOSAL/'proposed_integration_matrix.csv')
for r in matrix:
    if r['target'].startswith('_build/nathealth/'):
        route=Path(r['target']).relative_to('_build/nathealth')
        shutil.copy2(BUILD/route,safe(attempt/'changed_files'/route))
for p in sorted(EVIDENCE.iterdir()):
    if p.is_file():shutil.copy2(p,safe(attempt/'evidence'/p.name))
for p in sorted((OUT/'helpers').glob('*')):
    if p.is_file():shutil.copy2(p,safe(attempt/'helpers'/p.name))
write_csv(attempt/'preserved_manifest.csv',inventory(attempt))

old_ledger=json.loads((EVIDENCE/'raw_operation_ledger.json').read_text())
new_ledger=[];postimages={}
for route in ['index.html','supplementary_information.html']:
    original=(LIVE/route).read_bytes();old=(BUILD/route).read_bytes()
    operations=[]
    for op in [o for o in old_ledger if o['route']==route]:
        replacement=old[op['post_start']:op['post_end']]
        assert digest(replacement)==op['post_sha256']
        if op['slot'] in ['main-content','supplement-and-resources']:
            needle=b'<aside class="site-utilities"';assert replacement.count(needle)==1
            replacement=replacement.replace(needle,b'<section class="site-utilities"',1)
            assert replacement.count(b'</aside>')==1
            replacement=replacement.replace(b'</aside>',b'</section>',1)
        operations.append((op['pre_start'],op['pre_end'],replacement,op['slot']))
    match=one(list(re.finditer(rb'<main\b[^>]*>',original)))
    opening=b'<main class="content page-columns page-full" id="quarto-document-content">'
    operations.append((match.start(),match.end(),opening,'main-grid-root'))
    operations.sort();assert all(operations[i][1]<=operations[i+1][0] for i in range(len(operations)-1))
    pieces=[];previous=0;postpos=0
    for start,end,replacement,slot in operations:
        retained=original[previous:start];pieces.append(retained);postpos+=len(retained)
        new_ledger.append(dict(route=route,slot=slot,pre_start=start,pre_end=end,post_start=postpos,post_end=postpos+len(replacement),pre_sha256=digest(original[start:end]),post_sha256=digest(replacement)))
        pieces.append(replacement);postpos+=len(replacement);previous=end
    pieces.append(original[previous:]);post=b''.join(pieces)
    reverse=post
    for op in reversed([o for o in new_ledger if o['route']==route]):reverse=reverse[:op['post_start']]+original[op['pre_start']:op['pre_end']]+reverse[op['post_end']:]
    assert reverse==original
    postimages[route]=post
for route,post in postimages.items():safe(BUILD/route).write_bytes(post)
write_json(EVIDENCE/'raw_operation_ledger.json',new_ledger)
write_csv(EVIDENCE/'candidate_inventory.csv',inventory(BUILD))
write_json(EVIDENCE/'correction_pass.json',dict(pass_number=2,time_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),implementation_sha256=sha(Path(__file__)),preserved_first_pass_manifest_sha256=sha(attempt/'preserved_manifest.csv'),changed_files=list(postimages),corrections=['Use the accepted page-columns/page-full main grid root so the imported nested section grids inherit the website width correctly.','Use a section instead of aside for the independent utility panel; Quarto treats every aside as a right-margin conflict.'],scientific_content_changed=False,shared_shell_changed=False,live_changes=0,raw_reversal_exact=True))
print('PASS: sole second candidate pass, two entry-local corrections; first postimages and evidence preserved.')
