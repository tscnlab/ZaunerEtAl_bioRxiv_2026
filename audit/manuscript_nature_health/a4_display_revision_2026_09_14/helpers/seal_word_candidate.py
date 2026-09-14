"""Create a non-circular candidate-only manifest. No scientific computation."""
from pathlib import Path
import hashlib
import csv

j = Path('audit/manuscript_nature_health/a4_display_revision_2026_09_14')
files = []
for directory in ['deliverables','helpers','evidence/final_word','attempt_04/evidence','attempt_04/editable_tables',
                  'attempt_04/qa','html_candidate_round2','attempt_03/qa']:
    files += [p for p in (j/directory).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
files += [j/p for p in ['word_candidate_handoff.md','revision_plan.md',
                         'attempt_04/Nature_Health_manuscript.docx','attempt_04/placements.json',
                         'attempt_04/caption_reference_amendments.json',
                         'attempt_03/evidence/full_resolution_visual_review.json',
                         'evidence/dispatch52_rehash.csv','evidence/preflight_session.txt']]
files = sorted(set(files))
manifest = j/'word_candidate_manifest.csv'
with manifest.open('w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['path','bytes','sha256'])
    writer.writeheader()
    for p in files:
        writer.writerow({'path':str(p.relative_to(j)), 'bytes':p.stat().st_size,
                         'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
print('Members:',len(files))
print('Manifest SHA-256:',hashlib.sha256(manifest.read_bytes()).hexdigest())
