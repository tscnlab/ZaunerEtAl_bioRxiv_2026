"""Verify22 existing candidate download targets by exact GET/HEAD bytes."""
from common import *
from urllib.request import Request,urlopen
life=json.loads((E/'server_lifecycle.json').read_text());assert life['host']=='127.0.0.1' and life['status']=='listening'
inventory={r['path']:r for r in parsed_inv(E/'candidate_inventory.csv')}
targets=['ZaunerEtAl2026_NatHealth_phase3_brown.docx',*[r for r in inventory if r.startswith('editable_tables/')],'manuscript_changes.csv','manuscript_changes.md'];assert len(targets)==len(set(targets))==22
checks=[]
for route in targets:
    r=inventory[route];url=f'http://127.0.0.1:{life["port"]}/{route}'
    with urlopen(Request(url,method='HEAD'),timeout=20) as resp:head=resp.status;size=int(resp.headers['Content-Length']);mime=resp.headers['Content-Type']
    with urlopen(Request(url,method='GET'),timeout=20) as resp:get=resp.status;data=resp.read()
    digest=hashlib.sha256(data).hexdigest();ok=head==get==200 and size==len(data)==r['bytes'] and digest==r['sha256']==sha(BUILD/route);assert ok,route
    checks.append(dict(path=route,head_status=head,get_status=get,bytes=len(data),sha256=digest,mime_type=mime,exact=ok))
csvout(E/'http_download_checks.csv',checks);dump(E/'http_download_summary.json',dict(utc=utc(),downloads=22,all_exact=True,port=life['port'],no_download_folder_writes=True));print('PASS:22 exact GET/HEAD downloads.')
