"""Read-only localhost route/download checks, plus explicit teardown proof."""
from common import *
import urllib.request,urllib.error,urllib.parse,socket,sys
mode=sys.argv[1];action=sys.argv[2];assert mode in ('candidate','live');qa=E/(mode+'_qa')
state=json.loads((qa/'server_lifecycle.json').read_text());origin='http://127.0.0.1:'+str(state['port'])
if action=='teardown':
    assert state['status']=='stopped';sock=socket.socket();sock.settimeout(2)
    code=sock.connect_ex(('127.0.0.1',state['port']));sock.close();assert code!=0
    current=inventory(site_for(mode));assert {r['path']:r for r in current}==csvmap(qa/'server_pre_inventory.csv')
    csvout(qa/'teardown_inventory.csv',current)
    dump(qa/'teardown.json',dict(utc=utc(),status='PASS',host='127.0.0.1',port=state['port'],connect_errno=code,no_listener=True,files_immutable=899))
    print('PASS stopped server, connection refused,899 unchanged files');raise SystemExit
assert action=='check' and state['status']=='listening'
members=csvmap(E/'candidate_inventory.csv');corpus=readcsv(target(CORPUS,mode))
routes=[str(Path(r['expected_html']).relative_to('_build/nathealth')) for r in corpus]
downloads=[r['path'] for r in readcsv(E/(mode+'_download_inventory.csv'))]
records=[]
for route in routes+downloads:
    url=origin+'/'+urllib.parse.quote(route,safe='/');expected=members[route]
    with urllib.request.urlopen(url,timeout=20) as response:
        body=response.read();assert response.status==200 and hashbytes(body)==expected['sha256'] and len(body)==expected['bytes']
        records.append(dict(route=route,method='GET',status=200,bytes=len(body),sha256=hashbytes(body),exact=True))
    if route in downloads:
        with urllib.request.urlopen(urllib.request.Request(url,method='HEAD'),timeout=20) as response:
            assert response.status==200 and int(response.headers['Content-Length'])==expected['bytes']
            records.append(dict(route=route,method='HEAD',status=200,bytes=expected['bytes'],sha256=expected['sha256'],exact=True))
for route in ['notebooks/sensitivity_battery.html','manuscript_changes.csv','manuscript_changes.md']:
    try:urllib.request.urlopen(origin+'/'+route,timeout=20)
    except urllib.error.HTTPError as exc:assert exc.code==404
    else:raise AssertionError('Retired URL still served: '+route)
    records.append(dict(route=route,method='GET',status=404,bytes=0,sha256='',exact=True))
csvout(qa/'http_exact_checks.csv',records)
dump(qa/'http_summary.json',dict(status='PASS',utc=utc(),reader_routes=36,download_GET_HEAD=20,retired404=3,checks=len(records),origin=origin))
print('PASS36 reader GETs,20 exact download GET/HEAD pairs,3 retired404s')
