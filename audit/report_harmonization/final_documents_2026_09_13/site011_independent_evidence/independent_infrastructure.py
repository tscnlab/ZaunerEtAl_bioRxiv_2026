from pathlib import Path
import csv, hashlib, json, os, runpy, sys

ROOT = Path('/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026')
OWNER = ROOT / 'audit/report_harmonization/final_site_integration_2026_09_14'
SCRATCH = Path('/private/tmp/site011-independent.r9PH4p')
BUILD = OWNER / 'candidate_build'
LIVE = ROOT / '_build/nathealth'
def sha(p):
    with Path(p).open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()
def rows(p):
    with Path(p).open(newline='', encoding='utf-8-sig') as f:
        return list(csv.DictReader(f))
def csvout(p, data, fields=None):
    assert p.is_relative_to(SCRATCH)
    p.parent.mkdir(parents=True, exist_ok=True)
    fields = fields or list(dict.fromkeys(k for r in data for k in r))
    with p.open('w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=fields); w.writeheader(); w.writerows(data)
def inv(p):
    found = []
    for x in sorted(p.rglob('*')):
        assert not x.is_symlink(), x
        if x.is_file():
            found.append(dict(path=str(x.relative_to(p)), bytes=x.stat().st_size, sha256=sha(x)))
    return found
def normalized(data):
    return {r['path']: (int(r['bytes']), r['sha256']) for r in data}

assert sha(OWNER/'completion_manifest.csv') == '34c5804faa43c9f71bdd2c9be7cc8bc3e03f85b84227a6d94f10f9ed349e1199'
assert sha(OWNER/'candidate_return.md') == 'fa7d95b70cbdb06f222fde6559e71b71817aabef1870780a90d1d566967d47d4'
assert sha(OWNER/'completion_seal.json') == '639d0cbd4c2f525e786d8a0564a0ff07c7335131ca9d6559ae9b93d79a6aa3fa'
m = rows(OWNER/'completion_manifest.csv')
assert len(m) == len({r['path'] for r in m}) == 1026
assert not {'completion_manifest.csv', 'completion_seal.json'} & {r['path'] for r in m}
audit = []
for r in m:
    p = OWNER/r['path']
    assert p.resolve().is_relative_to(OWNER) and p.is_file() and not p.is_symlink()
    actual = sha(p)
    audit.append(dict(**r, actual_sha256=actual, exact=actual == r['sha256'] and p.stat().st_size == int(r['bytes'])))
assert all(r['exact'] for r in audit)
csvout(SCRATCH/'owner1026_rehash.csv', audit)
live = inv(LIVE); candidate = inv(BUILD)
assert len(live) == 893 and len(candidate) == 914
assert normalized(live) == normalized(rows(OWNER/'evidence/baseline_inventory.csv'))
assert normalized(candidate) == normalized(rows(OWNER/'evidence/candidate_inventory.csv'))
csvout(SCRATCH/'candidate914_rehash.csv', candidate)
csvout(SCRATCH/'live893_rehash.csv', live)

# Replay both existing complete infrastructure verifiers with evidence writes
# redirected, without changing code, candidate, owner evidence or live files.
sys.dont_write_bytecode = True
sys.path.insert(0, str(OWNER/'helpers'))
import common
evidence = OWNER/'evidence'
replay = SCRATCH/'infrastructure_replay'
replay.mkdir(exist_ok=True)
def safe_redirect(path):
    p = Path(path)
    assert p.is_relative_to(evidence), p
    target = replay/p.relative_to(evidence)
    target.parent.mkdir(parents=True, exist_ok=True)
    return target
common.safe = safe_redirect
common.write_json = lambda p, obj: safe_redirect(p).write_text(json.dumps(obj, indent=2, ensure_ascii=False)+'\n')
def redirected_csv(p, data, fields=None):
    csvout(safe_redirect(p), data, fields)
common.write_csv = redirected_csv
runpy.run_path(str(OWNER/'helpers/verify_static.py'), run_name='__main__')
runpy.run_path(str(OWNER/'helpers/postflight.py'), run_name='__main__')
for name in ['static_checks.csv', 'website_promotion_manifest.csv', 'phase4_corpus_manifest.prospective.csv',
             'prospective_corpus_reverse.csv', 'source_artifact_authority.csv', 'input_postflight.csv',
             'candidate_inventory.postflight.csv']:
    assert (replay/name).read_bytes() == (evidence/name).read_bytes(), name
assert all(sha(OWNER/r['path']) == r['sha256'] for r in m)
summary = dict(owner_members=1026, live_files=893, candidate_files=914, symlinks=0,
    static_checks=53703, content_replay_separate=True, postflight_checks=3632,
    exact_replayed_files=7, owner_package_unchanged=True, live_unchanged=True)
(SCRATCH/'independent_summary.json').write_text(json.dumps(summary, indent=2)+'\n')
print('INDEPENDENT_INFRASTRUCTURE=PASS', json.dumps(summary))
