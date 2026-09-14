"""Read-only loopback download response hashes, without download-folder writes."""
from common import *
from urllib.request import Request,urlopen
life=json.loads((E/'server_lifecycle.json').read_text());assert life['host']=='127.0.0.1' and life['status']=='listening'
port=int(life['port']);targets=[r for r in plan_rows() if r['target'].startswith('_build/nathealth/') and r['target'].endswith(('.docx','.csv','.md'))]
assert len(targets)==22
results=[]
for row in targets:
    p=ROOT/row['target'];relative=p.relative_to(LIVE).as_posix();url=f'http://127.0.0.1:{port}/{relative}'
    with urlopen(Request(url,method='HEAD'),timeout=20) as response:head=response.status;size=int(response.headers['Content-Length']);mime=response.headers['Content-Type']
    with urlopen(Request(url,method='GET'),timeout=20) as response:get=response.status;data=response.read()
    digest=hashlib.sha256(data).hexdigest();ok=head==get==200 and size==len(data)==row['bytes'] and digest==row['post_sha256']==sha(p)
    assert ok,relative
    results.append(dict(path=relative,head_status=head,get_status=get,mime_type=mime,bytes=len(data),sha256=digest,exact=ok))
csvout(E/'http_download_checks.csv',results)
dump(E/'http_download_summary.json',dict(utc=utc(),host='127.0.0.1',port=port,downloads=22,all_exact=True,method='GET/HEAD response bytes in memory; no browser download folder writes'))
print('PASS: all22 downloads return200 and exact accepted bytes.')
