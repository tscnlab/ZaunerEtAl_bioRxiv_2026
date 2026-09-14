"""Read-only loopback delivery checks for the exact candidate downloads."""
import datetime
from urllib.request import Request, urlopen
from common import *

life=json.loads((EVIDENCE/'server_lifecycle.json').read_text())
assert life['host']=='127.0.0.1',life
port=int(life['port'])
targets=[r for r in rows(EVIDENCE/'website_promotion_manifest.csv')
         if r['candidate'].endswith(('.docx','.csv','.md'))]
assert len(targets)==22
results=[]
for row in targets:
    source=ROOT/row['candidate']
    relative=source.relative_to(BUILD).as_posix()
    url=f'http://127.0.0.1:{port}/{relative}'
    with urlopen(Request(url,method='HEAD'),timeout=20) as response:
        head_status=response.status
        size=int(response.headers['Content-Length'])
        mime=response.headers['Content-Type']
    with urlopen(Request(url,method='GET'),timeout=20) as response:
        get_status=response.status
        data=response.read()
    exact=(head_status==get_status==200 and size==len(data)==int(row['bytes'])
           and digest(data)==row['candidate_sha256']==sha(source))
    assert exact,relative
    results.append(dict(relative_path=relative,head_status=head_status,
                        get_status=get_status,mime_type=mime,bytes=len(data),
                        sha256=digest(data),exact=exact))
write_csv(EVIDENCE/'http_download_checks.csv',results)
write_json(EVIDENCE/'http_download_summary.json',dict(
    utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    host='127.0.0.1',port=port,downloads=22,all_exact=True,
    method='GET/HEAD response bytes in memory, no browser download folder writes'))
print('PASS: all 22 download targets return HTTP 200 and exact accepted bytes.')
