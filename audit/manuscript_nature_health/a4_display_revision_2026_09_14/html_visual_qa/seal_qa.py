from pathlib import Path
from datetime import datetime, timezone
import csv
import hashlib
import json
qa=Path('audit/manuscript_nature_health/a4_display_revision_2026_09_14/html_visual_qa')
manifest=qa/'qa_completion_manifest.csv'
seal=qa/'qa_completion_seal.json'
files=sorted(p for p in qa.rglob('*') if p.is_file() and p not in [manifest,seal] and '__pycache__' not in p.parts)
with manifest.open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=['path','bytes','sha256']);w.writeheader()
    for p in files: w.writerow({'path':str(p.relative_to(qa)),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
record={'members':len(files),'manifest_sha256':hashlib.sha256(manifest.read_bytes()).hexdigest(),
        'handoff_sha256':hashlib.sha256((qa/'qa_handoff.md').read_bytes()).hexdigest(),
        'frozen_candidate_manifest_sha256':'996e138233eff74da4754aae6c2fbc1a6b5785c9d196fa2c64df2fe8eeccb464',
        'frozen_html_sha256':'d7ee926c0910227004581915040f30ae01142290f0759839e897fa2b3f5f10aa',
        'verdict':'BOUNDED_HTML_VISUAL_QA_PASS','created_at':datetime.now(timezone.utc).isoformat()}
seal.write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps(record,indent=2))
