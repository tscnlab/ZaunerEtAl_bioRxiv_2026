"""Recheck every released authority and create only the five future preimages."""
import datetime,shutil
from common import *

checks=[]
def verify(path,expected,expected_size=None,category=''):
    p=Path(path);actual=sha(p)
    exact=actual==expected and (expected_size is None or p.stat().st_size==int(expected_size))
    checks.append(dict(path=label(p),category=category,bytes=p.stat().st_size,sha256=actual,expected_sha256=expected,exact=exact))
    assert exact,p

verify(CONTROL/'final_site_candidate_order_011.md','9bae7b64d4a4ec0dccab89f4ef5a9454fcea8f9c5bf1403a79aa5d0b3057e72b',10277,'order')
dispatch=CONTROL/'final_site_candidate_order_011_dispatch_manifest.csv'
verify(dispatch,'ed4395ee67a03bde42f1349c97d6cad126517867863e64cc4212cc3eca458c56',7961,'dispatch_seal')
released=rows(dispatch);assert len(released)==47
for r in released:verify(ROOT/r['path'],r['sha256'],r['bytes'],'dispatch47')
for root,count,expected in [(PROPOSAL,25,'6a4e78f7952a467d4e3dfd629313500c4380b2cdc7288b5182214df26183fe91'),(C,271,'86ba7e46cdf106090d8ceaee3109d751dddc32f0f80d62da325ce6b7698583e2'),(F,145,'7fce1f1e88980219a1e8199c5440af0ed19070cbf28b3906bcce13d7bd529ad2')]:
    verify(root/'completion_manifest.csv',expected,category='package_manifest')
    members=rows(root/'completion_manifest.csv');assert len(members)==count
    for r in members:verify(root/r['path'],r['sha256'],r['bytes'],f'package{count}')
pins=rows(PROPOSAL/'input_identities.csv');assert len(pins)==1298
absent=[]
for r in pins:
    p=Path(r['path']) if r['path'].startswith('/') else ROOT/r['path']
    assert not p.is_symlink(),p
    if r['exists']=='True':verify(p,r['sha256'],r['bytes'],'input1298')
    else:
        assert not p.exists(),p
        absent.append(dict(path=r['path'],exists=False))
baseline=inventory(LIVE);assert len(baseline)==893
expected={r['relative']:(r['sha256'],int(r['bytes'])) for r in rows(PROPOSAL/'build_inventory.csv')}
assert {r['path']:(r['sha256'],r['bytes']) for r in baseline}==expected
verify(WORD,WORD_SHA,14372157,'final_word')
assert not BUILD.exists(),'No overwrite of an existing candidate'
backups=[]
matrix=rows(PROPOSAL/'proposed_integration_matrix.csv');assert len(matrix)==26
for r in matrix:
    if r['current_exists']=='True':
        source=ROOT/r['target'];target=OUT/'backup'/r['target']
        assert not target.exists(),target
        shutil.copy2(source,safe(target));assert sha(source)==sha(target)==r['preimage_sha256']
        backups.append(dict(live_target=r['target'],backup=label(target),bytes=target.stat().st_size,sha256=sha(target)))
    else:assert not (ROOT/r['target']).exists()
assert len(backups)==5 and len([r for r in matrix if r['current_exists']=='False'])==21
write_csv(EVIDENCE/'input_preflight.csv',checks)
write_csv(EVIDENCE/'input_absences.csv',absent,['path','exists'])
write_csv(EVIDENCE/'baseline_inventory.csv',baseline)
write_csv(EVIDENCE/'five_backup_manifest.csv',backups)
write_json(EVIDENCE/'preflight_summary.json',dict(time_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),dispatch=47,proposal=25,C=271,finalWordPackage=145,inputPins=1298,baselineFiles=893,backups=5,additionsAbsent=21,all_exact=True,scientific_execution=False,live_writes=0))
print('PASS: dispatch47, proposal25, C271, final145, input1298, baseline893; five exact backups; no live changes.')
