#!/usr/bin/env python3
"""Build a non-circular file manifest for Nature Health production evidence."""

from __future__ import annotations

import csv
import hashlib
import sys
from pathlib import Path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def role_for(relative: str) -> str:
    if "/docx_pages_s8_repaired/" in relative:
        return "final_docx_page_render"
    if "/docx_page_contact_sheets_s8_repaired/" in relative:
        return "final_docx_contact_sheet"
    if "/docx_pages/" in relative or "/docx_page_contact_sheets/" in relative:
        return "preserved_pre_repair_docx_qa"
    if "/word_capture/" in relative:
        return "word_capture_asset_or_manifest"
    if "/html_" in relative or relative.endswith("html_browser_qa.json"):
        return "html_visual_qa"
    if "candidate_final" in relative or "preimage" in relative or "failed_render" in relative:
        return "preserved_preimage_or_candidate"
    if "semantic" in relative or "verify_final_html" in relative:
        return "html_semantic_repair_evidence"
    if "docx_" in relative or "word_" in relative:
        return "word_validation_evidence"
    if "stability" in relative or "completion" in relative or "lifecycle" in relative:
        return "completion_evidence"
    if relative.endswith(".qmd"):
        return "manuscript_source"
    if relative.endswith(".html"):
        return "canonical_html"
    if relative.endswith(".docx"):
        return "canonical_docx"
    if relative.endswith(".py") or relative.endswith(".R") or relative.endswith(".mjs"):
        return "production_or_validation_script"
    return "supporting_evidence"


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit("Usage: build_final_evidence_manifest.py ROOT EVIDENCE_DIR")
    root = Path(sys.argv[1]).resolve()
    evidence = (root / sys.argv[2]).resolve()
    output = evidence / "final_evidence_manifest.csv"

    paths = [
        path for path in evidence.rglob("*")
        if path.is_file() and path != output and path.name != ".DS_Store"
    ]
    extra_relatives = [
        "manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd",
        "manuscript/R0_NatHealth/_quarto.yml",
        "manuscript/R0_NatHealth/manuscript_displays.css",
        "manuscript/R0_NatHealth/references_merged.bib",
        "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html",
        "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx",
        "scripts/manuscript_nature_health/capture_word_tables.mjs",
        "scripts/manuscript_nature_health/prepare_word_manuscript.py",
        "tests/manuscript_nature_health/validate_current_revision.R",
        "tests/manuscript_nature_health/verify_final_production_outputs.py",
        "tests/manuscript_nature_health/build_final_evidence_manifest.py",
        "audit/report_harmonization/owner_orders/68_nature_health_manuscript_html_docx_production_render.md",
        "audit/report_harmonization/owner_orders/68a_nature_health_no_rerender_semantic_repair_and_production_completion.md",
        "audit/report_harmonization/phase4_corpus_manifest.csv",
    ]
    paths.extend(root / relative for relative in extra_relatives)
    unique = sorted(set(paths), key=lambda path: str(path.relative_to(root)))

    rows = []
    for path in unique:
        if not path.is_file():
            raise FileNotFoundError(path)
        relative = str(path.relative_to(root))
        rows.append({
            "path": relative,
            "role": role_for(relative),
            "bytes": path.stat().st_size,
            "sha256": sha256(path),
        })

    with output.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=("path", "role", "bytes", "sha256"))
        writer.writeheader()
        writer.writerows(rows)
    print(f"PASS: wrote {len(rows)} unique members to {output.relative_to(root)}")
    print(f"SHA-256: {sha256(output)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
