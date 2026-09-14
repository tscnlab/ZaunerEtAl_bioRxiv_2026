"""Seal this temporary proposal without modifying or invoking any owner artifact."""
import csv
import hashlib
import json
from pathlib import Path

root=Path(__file__).resolve().parent
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
results=[json.loads((root/name).read_text()) for name in ("isolated_test_results.json","preservation_guard_results.json")]
assert sum(r["test_count"] for r in results)==139
assert all(row["pass"] for result in results for row in result["tests"])
receipt=json.loads((root/"zero_fuzz_reverse_receipt.json").read_text())
assert receipt["exact_reversal"] and receipt["live_source_unchanged"]
assert digest(root/"embed_accepted_svg_figures.proposed.py")==receipt["post_sha256"]
commands=json.loads((root/"future_commands_NOT_EXECUTED.json").read_text())
assert all(digest(Path(p["path"]))==p["sha256"] and Path(p["path"]).stat().st_size==p["bytes"] for p in commands["input_pins"])
manifest=root/"proposal_manifest.csv"
seal=root/"proposal_seal.json"
assert not manifest.exists() and not seal.exists()
files=sorted(p for p in root.rglob("*") if p.is_file())
assert all(not p.is_symlink() for p in root.rglob("*"))
rows=[{"path":str(p),"sha256":digest(p),"bytes":p.stat().st_size} for p in files]
with manifest.open("x",newline="") as stream:
    writer=csv.DictWriter(stream,fieldnames=["path","sha256","bytes"])
    writer.writeheader();writer.writerows(rows)
payload={"status":"TEMP_ONLY_PROPOSAL_NOT_RELEASED", "manifest":str(manifest),"members":len(rows),"sha256":digest(manifest),"pre_sha256":receipt["pre_sha256"],"post_sha256":receipt["post_sha256"],"isolated_tests":139,"preservation_rows":1290,"full_entry_points_invoked":False,"candidate_package_saves":0,"owner_helper_edits":0,"browser_server_native_office_calls":0,"owner_dispatches":0}
with seal.open("x") as stream:stream.write(json.dumps(payload,indent=2)+"\n")
assert all(digest(Path(p["path"]))==p["sha256"] for p in rows)
print(json.dumps({**payload,"companion_sha256":digest(seal)}))
