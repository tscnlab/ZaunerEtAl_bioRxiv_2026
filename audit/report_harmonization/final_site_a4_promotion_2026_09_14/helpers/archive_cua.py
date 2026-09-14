"""Archive this task's existing CUA output bytes, never inspect another surface."""
from common import *
import base64,re
assert not IS_FIXTURE
life=json.loads((E/'server_lifecycle.json').read_text());assert life['status']=='stopped'
source=Path('/Users/zauner/.codex/sessions/2026/08/12/rollout-2026-08-12T10-54-39-019ff52e-48ac-77b3-9a0e-9a87749a3bba.jsonl')
out=E/'browser_captures';assert not out.exists();out.mkdir()
start=life['started_utc'];end=life['stopped_utc'];calls={};records=[];images=[]
def dt(s):return datetime.datetime.fromisoformat(s.replace('Z','+00:00'))
with source.open() as f:
    for line in f:
        if start[:10] not in line[:60]:continue
        row=json.loads(line);ts=row.get('timestamp','')
        if not ts or not dt(start)<=dt(ts)<=dt(end) or row.get('type')!='response_item':continue
        p=row.get('payload',{});cid=p.get('call_id','')
        if p.get('type')=='function_call' and p.get('name')=='js':calls[cid]=p;continue
        if p.get('type')!='function_call_output' or cid not in calls:continue
        body=p.get('output');body=body if isinstance(body,list) else [{'type':'input_text','text':str(body)}]
        texts=[b.get('text','') for b in body if b.get('type')=='input_text'];ims=[b for b in body if b.get('type')=='input_image']
        labels=list(dict.fromkeys(re.findall(r"\bid:\s*['\"]([A-Z]\d{3,4}-[^'\"]+)['\"]",'\n'.join(texts))))
        stem=re.sub(r'[^A-Za-z0-9_-]','',ts)+'_'+cid;metadata=out/(stem+'.json')
        data=dict(timestamp=ts,call_id=cid,tool_arguments=json.loads(calls[cid]['arguments']),text_blocks=texts,images=[])
        for i,b in enumerate(ims,1):
            url=b['image_url'];assert url.startswith('data:image/jpeg;base64,')
            raw=base64.b64decode(url.split(',',1)[1],validate=True);assert raw[:2]==b'\xff\xd8'
            path=out/(stem+'_'+str(i)+'.jpg');path.write_bytes(raw)
            rec=dict(timestamp=ts,call_id=cid,within_call_index=i,observation_id=labels[i-1] if len(labels)==len(ims) else '',image_path=str(path.relative_to(E)),metadata_path=str(metadata.relative_to(E)),bytes=len(raw),sha256=sha(path))
            images.append(rec);data['images'].append(rec)
        dump(metadata,data);records.append(dict(timestamp=ts,metadata=str(metadata.relative_to(E)),images=len(ims)))
assert images
csvout(E/'browser_capture_manifest.csv',images);dump(E/'browser_tool_output_index.json',records)
dump(E/'browser_archival_provenance.json',dict(source=str(source),start=start,end=end,images=len(images),records=len(records),scope='Only this task existing CUA tool outputs during the single live smoke session',binary_handling='Exact decoded CUA JPEG bytes; no resizing, editing, cropping or re-rendering'))
print('Archived',len(images),'original CUA screenshots.')
