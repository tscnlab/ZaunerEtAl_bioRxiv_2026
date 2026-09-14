"""Seal this new read-only planning return; never write outside its directory."""
from pathlib import Path
import ast,csv,datetime,hashlib,json

OUT=Path(__file__).resolve().parent
ROOT=Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
assert OUT==ROOT/'audit/report_harmonization/final_integration_reconciliation_2026_09_14'
def sha(path):
    with Path(path).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def rows(path):
    with Path(path).open(newline='',encoding='utf-8') as f:return list(csv.DictReader(f))
for script in OUT.glob('*.py'):ast.parse(script.read_text(),filename=str(script))
matrix=rows(OUT/'proposed_integration_matrix.csv')
assert len(matrix)==26 and len({r['target'] for r in matrix})==26
assert sum(r['proposed_action']=='BYTE_EXACT_ADDITION' for r in matrix)==21
assert all(r['release_status']=='PROPOSED_ONLY_NOT_AUTHORIZED_OR_EXECUTED' for r in matrix)
word=next(r for r in matrix if r['key']=='word_download')
assert word['source']=='PENDING_ORDER010C_FINAL_ACCEPTED_WORD' and word['source_sha256']=='PENDING_ORDER010C'
assert len(rows(OUT/'editable_table_bindings.csv'))==19
inputs=rows(OUT/'input_identities.csv')
assert len(inputs)==1298 and len({r['path'] for r in inputs})==1298
for row in inputs:
    p=Path(row['path']) if row['path'].startswith('/') else ROOT/row['path']
    expected_exists=row['exists'].lower()=='true'
    assert p.is_file()==expected_exists,row['path']
    if expected_exists:
        assert sha(p)==row['sha256'],row['path']
        assert p.stat().st_size==int(row['bytes']),row['path']
assert all(r['exact']=='True' for r in rows(OUT/'candidate271_identity_replay.csv'))
assert all(r['exact']=='True' for r in rows(OUT/'historical_build_comparison.csv'))
assert all(r['exact']=='True' for r in rows(OUT/'source54_checkpoint.csv'))
excluded={'completion_manifest.csv','completion_seal.json'}
members=[]
for p in sorted(OUT.iterdir()):
    assert p.is_file() and not p.is_symlink(),str(p)
    if p.name not in excluded:
        members.append(dict(path=p.name,bytes=p.stat().st_size,sha256=sha(p)))
manifest=OUT/'completion_manifest.csv'
with manifest.open('w',newline='',encoding='utf-8') as f:
    w=csv.DictWriter(f,fieldnames=['path','bytes','sha256']);w.writeheader();w.writerows(members)
for r in rows(manifest):assert sha(OUT/r['path'])==r['sha256']
seal=dict(status='READ_ONLY_RECONCILIATION_AND_FINITE_PROPOSAL_NOT_EXECUTED',
    sealed_at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    manifest='completion_manifest.csv',manifest_sha256=sha(manifest),members=len(members),
    return_path='reconciliation.md',return_sha256=sha(OUT/'reconciliation.md'),
    matrix_path='proposed_integration_matrix.csv',matrix_sha256=sha(OUT/'proposed_integration_matrix.csv'),
    input_pins_rechecked=1298,input_pins_exact=1298,proposed_live_targets=26,
    final_word_identity='PENDING_ORDER010C_ACCEPTANCE',
    exclusions=sorted(excluded),non_circular=True,scientific_execution=False,
    renders=0,browser_server_capture_office_actions=0,owner_dispatches=0,live_file_writes=0)
(OUT/'completion_seal.json').write_text(json.dumps(seal,indent=2)+'\n')
print(json.dumps({**seal,'seal_sha256':sha(OUT/'completion_seal.json')},indent=2))
