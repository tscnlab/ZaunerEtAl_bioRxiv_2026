"""Read current published preimages into the temporary audit only. No candidate or project writes."""
from pathlib import Path
import csv,hashlib,json,shutil,datetime
ROOT=Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
OUT=Path('/private/tmp/reader-scope-audit-20260914.nnDbyu');SITE=ROOT/'_build/nathealth'
def rows(n):return list(csv.DictReader((OUT/n).open()))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
base={r['path']:r for r in rows('live_inventory_before.csv')}
targets=['_build/nathealth/'+r['path'] for n in ['proposed_public_replacement_matrix.csv','proposed_public_retirements.csv'] for r in rows(n)]
targets+=['_quarto-nathealth.yml','audit/report_harmonization/phase4_corpus_manifest.csv','scripts/report_harmonization/build_phase4_corpus_manifest.R','tests/report_harmonization/test_navigation_contract.R']
assert len(targets)==len(set(targets))==64
saved=[]
for logical in targets:
    src=ROOT/logical;dst=OUT/'preimages'/logical;assert not dst.exists()
    dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,dst)
    assert sha(src)==sha(dst)
    if logical.startswith('_build/nathealth/'):
        b=base[logical.removeprefix('_build/nathealth/')];assert int(b['bytes'])==src.stat().st_size and b['sha256']==sha(src)
    saved.append(dict(path=logical,bytes=src.stat().st_size,sha256=sha(src),temporary_preimage=str(dst.relative_to(OUT)),recovery='exact current bytes; no mutation authorized'))
with (OUT/'preimage_manifest.csv').open('w') as f:w=csv.DictWriter(f,fieldnames=list(saved[0]));w.writeheader();w.writerows(saved)
current={str(p.relative_to(SITE)):dict(path=str(p.relative_to(SITE)),bytes=str(p.stat().st_size),sha256=sha(p)) for p in SITE.rglob('*') if p.is_file()}
assert current==base
accepted=list(csv.DictReader((ROOT/'audit/report_harmonization/final_site_a4_promotion_2026_09_14/evidence/final_post_site_inventory.csv').open()))
assert {r['path']:(int(r['bytes']),r['sha256']) for r in accepted}=={k:(int(r['bytes']),r['sha256']) for k,r in current.items()}
(OUT/'read_only_closure.json').write_text(json.dumps(dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),public_inventory_unchanged=True,live914_exact_Order016=True,temporary_preimages=64,temporary_preimage_bytes=sum(r['bytes'] for r in saved),project_writes=0,candidate_builds=0,renders=0,browser_sessions=0,scientific_refits=0),indent=2))
print('Exact64 temporary preimages; live914 unchanged and exact accepted Order016.')
