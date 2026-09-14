#!/usr/bin/env python3
"""Seal document-only Order72d evidence without calculating research results."""

import csv
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
AUTH = ROOT / "audit/report_harmonization/report018_order72d_writer_svg_integration"
MANIFEST = OUT / "stopped_manifest.csv"
CHECKS = OUT / "final_stop_checks.json"
DOCX = OUT / "ZaunerEtAl2026_NatHealth_svg_complete_order72d.docx"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert not MANIFEST.exists() and not CHECKS.exists(), "Evidence seal already exists."
    manifests = [AUTH / "release_manifest.csv", AUTH / "input_and_preservation_pins.csv"]
    authorities = set(manifests)
    checks = []
    for manifest in manifests:
        with manifest.open() as stream:
            rows = list(csv.DictReader(stream))
        assert len({row["path"] for row in rows}) == len(rows)
        exact = []
        for row in rows:
            path = ROOT / row["path"]
            authorities.add(path)
            exact.append(sha(path) == row["sha256"] and path.stat().st_size == int(row["bytes"]))
        assert all(exact), f"Preservation failure: {manifest}"
        checks.append({"path": str(manifest.relative_to(ROOT)), "rows": len(rows),
                       "all_exact": all(exact), "sha256": sha(manifest)})
    assert sha(DOCX) == "933249b33defbb2155b0d98da60db980302817537b06671982dc5114ce29eac9"
    assert DOCX.stat().st_size == 16623183
    baseline_page = OUT.parent / "manuscript_qa_reference_case_final/page-107.png"
    authorities.add(baseline_page)
    CHECKS.write_text(json.dumps({
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "status": "Stopped at ORDER72D-VIS-01; no retry or source change.",
        "candidate_sha256": sha(DOCX), "candidate_bytes": DOCX.stat().st_size,
        "preservation": checks,
        "manifest_exclusions": ["stopped_manifest.csv itself", "ephemeral Word lock files", "__pycache__"],
        "application_saved_candidate": False,
    }, indent=2) + "\n")
    paths = {p for p in OUT.rglob("*") if p.is_file() and p != MANIFEST
             and not p.name.startswith("~$") and "__pycache__" not in p.parts}
    paths.update(authorities)
    assert MANIFEST not in paths
    with MANIFEST.open("x", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=["path", "sha256", "bytes", "role"])
        writer.writeheader()
        for path in sorted(paths):
            writer.writerow({"path": str(path.relative_to(ROOT)), "sha256": sha(path),
                             "bytes": path.stat().st_size,
                             "role": "order72d_output_or_evidence" if path.is_relative_to(OUT) else "authority_or_preserved_input"})
    with MANIFEST.open() as stream:
        sealed = list(csv.DictReader(stream))
    assert len(sealed) == len({row["path"] for row in sealed})
    assert all(sha(ROOT / row["path"]) == row["sha256"]
               and (ROOT / row["path"]).stat().st_size == int(row["bytes"]) for row in sealed)
    print(json.dumps({"manifest": str(MANIFEST.relative_to(ROOT)), "rows": len(sealed),
                      "sha256": sha(MANIFEST), "bytes": MANIFEST.stat().st_size,
                      "unique_noncircular_and_exact": True,
                      "handoff_sha256": sha(OUT / "stopped_handoff.md")}))


if __name__ == "__main__":
    main()
