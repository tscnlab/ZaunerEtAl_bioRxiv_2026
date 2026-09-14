"""Archive exact existing outputs from this task's bounded CUA session only."""
from common import *
import base64,re,sys
mode=sys.argv[1];assert mode in ('candidate','live');qa=E/(mode+'_qa')
life=json.loads((qa/'server_lifecycle.json').read_text());assert life['status']=='stopped'
source=Path('/Users/zauner/.codex/sessions/2026/08/12/rollout-2026-08-12T10-54-39-019ff52e-48ac-77b3-9a0e-9a87749a3bba.jsonl')
dest=qa/'browser_captures';assert not dest.exists();dest.mkdir()
start=life['started_utc'];end=life['stopped_utc'];calls={};records=[];images=[]
def dt(s):return datetime.datetime.fromisoformat(s.replace('Z','+00:00'))
with source.open() as f:
    for line in f:
        if start[:10] not in line[:60]:continue
        row=json.loads(line);ts=row.get('timestamp','')
        if not ts or not dt(start)<=dt(ts)<=dt(end) or row.get('type')!='response_item':continue
        payload=row.get('payload',{});cid=payload.get('call_id','')
        if payload.get('type')=='function_call' and payload.get('name')=='js':calls[cid]=payload;continue
        if payload.get('type')!='function_call_output' or cid not in calls:continue
        body=payload.get('output');body=body if isinstance(body,list) else [{'type':'input_text','text':str(body)}]
        texts=[b.get('text','') for b in body if b.get('type')=='input_text'];ims=[b for b in body if b.get('type')=='input_image']
        stem=re.sub(r'[^A-Za-z0-9_-]','',ts)+'_'+cid;metadata=dest/(stem+'.json')
        data=dict(timestamp=ts,call_id=cid,tool_arguments=json.loads(calls[cid]['arguments']),text_blocks=texts,images=[])
        for i,b in enumerate(ims,1):
            url=b['image_url'];assert url.startswith('data:image/jpeg;base64,')
            raw=base64.b64decode(url.split(',',1)[1],validate=True);assert raw[:2]==b'\xff\xd8'
            p=dest/(stem+'_'+str(i)+'.jpg');p.write_bytes(raw)
            rec=dict(timestamp=ts,call_id=cid,within_call_index=i,image_path=str(p.relative_to(OUT)),metadata_path=str(metadata.relative_to(OUT)),bytes=len(raw),sha256=sha(p))
            images.append(rec);data['images'].append(rec)
        dump(metadata,data);records.append(dict(timestamp=ts,metadata=str(metadata.relative_to(OUT)),images=len(ims)))
assert images
csvout(qa/'browser_capture_manifest.csv',images);dump(qa/'browser_tool_output_index.json',records)
dump(qa/'browser_archival_provenance.json',dict(source=str(source),start=start,end=end,images=len(images),records=len(records),scope='Only this task CUA outputs within this exact server lifecycle',binary_handling='Exact decoded JPEG bytes; no edit, resize, crop, generation or separate browser capture'))
print('Archived',len(images),'original CUA screenshots')
