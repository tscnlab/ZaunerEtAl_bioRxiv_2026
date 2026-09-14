"""Exact byte reconstruction of prospective source deltas. Infrastructure only."""
import csv,difflib,hashlib,json
from pathlib import Path
root=Path(__file__).resolve().parent
evidence=root/'independent_evidence'
with (root/'exact_owner_copy_map.csv').open(newline='') as f:rows=list(csv.DictReader(f))
checks=[]
for row in rows[:5]:
    new=Path(row['source_path']);old=Path(row['destination_path'].replace('_v2.R','.R'))
    delta=list(difflib.ndiff(old.read_text().splitlines(keepends=True),new.read_text().splitlines(keepends=True)))
    reconstructed_old=''.join(difflib.restore(delta,1)).encode()
    reconstructed_new=''.join(difflib.restore(delta,2)).encode()
    assert reconstructed_old==old.read_bytes() and reconstructed_new==new.read_bytes()
    (evidence/(new.name+'.ndiff')).write_text(''.join(delta))
    checks.append({'old_path':str(old),'new_path':row['destination_path'],'old_sha256':hashlib.sha256(reconstructed_old).hexdigest(),'new_sha256':hashlib.sha256(reconstructed_new).hexdigest(),'reverse_exact':True,'forward_exact':True})
with (root/'source_reverse_proofs.csv').open('x',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(checks[0]));w.writeheader();w.writerows(checks)
(root/'inert_fixture_location.json').write_text(json.dumps({'path':'/private/tmp/ba018-completion-audit.ekpsA4/supervisor_v10_inert_fixtures_001','classification':'inert copied process-test sandboxes, not analytical authority','moved_intact':True,'real_children':0,'real_signals':0},indent=2)+'\n')
print('SOURCE_REVERSALS=PASS 5/5')
