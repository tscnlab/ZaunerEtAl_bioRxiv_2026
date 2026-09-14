#!/usr/bin/env python3
"""Structural integrity checks for the final Nature Health production outputs.

This checker performs file identity and document-QA reconciliation only. It does
not inspect research data or calculate scientific results.
"""

from __future__ import annotations

import csv
import hashlib
import json
import os
import sys
from pathlib import Path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def add_file_check(rows, root: Path, category: str, relative: str,
                   expected_sha: str, expected_bytes: int | None = None,
                   note: str = "") -> None:
    path = root / relative
    exists = path.is_file()
    actual_sha = sha256(path) if exists else ""
    actual_bytes = path.stat().st_size if exists else ""
    ok = exists and actual_sha == expected_sha
    if expected_bytes is not None:
        ok = ok and actual_bytes == expected_bytes
    rows.append({
        "category": category,
        "path": relative,
        "expected_sha256": expected_sha,
        "actual_sha256": actual_sha,
        "expected_bytes": "" if expected_bytes is None else expected_bytes,
        "actual_bytes": actual_bytes,
        "status": "PASS" if ok else "FAIL",
        "note": note,
    })


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit("Usage: verify_final_production_outputs.py ROOT EVIDENCE_DIR")

    root = Path(sys.argv[1]).resolve()
    evidence = (root / sys.argv[2]).resolve()
    rows = []

    stable = {
        ".Rprofile": ("3f9d62fc3f1bf5888a09816101b705f9844ef4cd44ee5ad157f4168dac4af4d4", 26),
        "_build/nathealth/index.html": ("600b7a3d5eb244e99e841b5c4e3b6c1c7440004303fe0e9da1bc0c874add1184", 405444),
        "_includes/nathealth-mobile-toc.html": ("153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980", 1542),
        "_quarto-nathealth.yml": ("e54c71794f4f763a8b50417ab83ff3db37bc9af3fef3f4d1910576ab12c61bc7", 10042),
        "audit/manuscript_nature_health/figure_table_selection_assets/selection_asset_manifest.csv": ("30ff83aac8a932d9702e7b7ec9c8c561729703da1a390c022099508067960640", 7553),
        "audit/report_harmonization/owner_orders/64_writer_finalized_figure_integration.md": ("f48abd6967964fc381b0ce602989ca7b265014ebf7ae5591311b42630d78b024", 5030),
        "audit/report_harmonization/owner_orders/68_nature_health_manuscript_html_docx_production_render.md": ("c6878872e2bb533d203f3a352134f5bc91e9bef3c647c406b4204118a1f8d118", 11475),
        "audit/report_harmonization/owner_orders/68a_nature_health_no_rerender_semantic_repair_and_production_completion.md": ("6529348eb0b843d9388a2bc3b569320a0d6b7b81fda40d010c454a13c4ea4702", None),
        "audit/report_harmonization/phase4_corpus_manifest.csv": ("5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b", 11479),
        "audit/report_harmonization/report018_order68_manuscript_render_dispatch.md": ("10c9e714090768ce0eafb114f4323afd7f8370cc20d32e69f1b87b92f2a7eee2", 1229),
        "audit/report_harmonization/report018_navigation_order67a_independent_acceptance.md": ("d0398d9872340a5245beccc8462daee155f7a709503834cd6a7d882dba018cc8", 2444),
        "audit/report_harmonization/report018_navigation_order67a_independent_acceptance_manifest.csv": ("39119c296606e43faa6b771cc9dacdbe6a598593224727df734bd4480b8ed856", 3771),
        "index.qmd": ("86766c377e7ee1dcfea6b1ada8704b04320bbc231630c4044cd9c9d93aa0bf80", 91250),
        "manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd": ("9853f0bd462c8c6ed0e74dae8a7bae9a570fdc8ba6f13644dfbc0d88109657d0", 80774),
        "manuscript/R0_NatHealth/_quarto.yml": ("2aa2911f13d4532aa8ce98e38363a5c92b1d2bdc025b3c8bba49950077e76b33", 435),
        "manuscript/R0_NatHealth/manuscript_displays.css": ("5974136901a8325e831e932a3999382532acfcf94508f428b23bc8f5de3ffc98", 4397),
        "manuscript/R0_NatHealth/references_merged.bib": ("4972d8011fd9ccd2067e5e583a9bbc8846a825218ca7b4b574bcc6bd4bea1c06", 51953),
        "renv.lock": ("3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350", 603493),
        "scripts/manuscript_nature_health/capture_word_tables.mjs": ("9a38f12b93bd03f3332de2f3c862bedbd035659bd762b386b98166800a04af07", 14753),
        "scripts/manuscript_nature_health/prepare_word_manuscript.py": ("0e6310467104be48993ca00f63d18e8e0b6d9ac7b59605ac18f749ee250a8d9c", 25939),
        "scripts/report_harmonization/check_report018_navigation_order67a_final_acceptance.R": ("a874d7c4b40333f5ca47249410c79ac3b456fbf9f1d64d17030b702c71705afb", 9075),
        "styles-nathealth.css": ("051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87", 4548),
        "tests/manuscript_nature_health/validate_current_revision.R": ("adf639878cca1bd1dff5886a50f839c39529732e3a75f4183011d3aadf65f354", 23841),
    }
    for relative, (expected_sha, expected_bytes) in stable.items():
        add_file_check(rows, root, "frozen_or_protected_input", relative,
                       expected_sha, expected_bytes)

    finals = {
        "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html": ("8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac", 30881505),
        "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx": ("07ff074d4bd4124656063f69a2437b4c646a8240ad771ce94d30339f41d0604c", 28749374),
        "audit/manuscript_nature_health/final_production_render_2026_09_02/raw_quarto_ZaunerEtAl2026_NatHealth_phase3_brown.docx": ("b8eeca31794e06c7c2ec2d6a474ae812b77b2b8c2dcadf7d341e3b6178430cdd", 9872181),
        "audit/manuscript_nature_health/final_production_render_2026_09_02/semantic_repair_ledger.csv": ("225b5d37818850dca9b6cb5dcf39d78e5fd76c1e79745bbf09f981a70a980287", 70290),
        "audit/manuscript_nature_health/final_production_render_2026_09_02/verify_final_html.R": ("7054f6da946edf858813378017dd606283dbdf0816e2bc41a8f7237fd681c55c", 6657),
    }
    for relative, (expected_sha, expected_bytes) in finals.items():
        add_file_check(rows, root, "final_artifact", relative,
                       expected_sha, expected_bytes)

    corpus_path = root / "audit/report_harmonization/phase4_corpus_manifest.csv"
    corpus_rows = list(csv.DictReader(corpus_path.open(encoding="utf-8", newline="")))
    for item in corpus_rows:
        source = root / item["source"]
        source_exists = source.is_file()
        source_sha = sha256(source) if source_exists else ""
        source_matches = source_exists and source_sha == item["source_sha256"]
        rows.append({
            "category": "accepted_corpus_source_information",
            "path": item["source"],
            "expected_sha256": item["source_sha256"],
            "actual_sha256": source_sha,
            "expected_bytes": "",
            "actual_bytes": source.stat().st_size if source_exists else "",
            "status": "PASS" if source_matches else "INFO",
            "note": (
                f"logical_order={item['logical_order']}; accepted render source unchanged"
                if source_matches else
                f"logical_order={item['logical_order']}; later shared-checkout source edit; "
                "accepted rendered HTML remains the integration authority"
            ),
        })
        add_file_check(
            rows, root, "accepted_corpus_html", item["expected_html"], item["html_sha256"],
            note=f"logical_order={item['logical_order']}",
        )

    qa_files = {
        "html_browser_qa": evidence / "html_browser_qa.json",
        "word_capture_validation": evidence / "word_capture_validation.json",
        "docx_structural_checks": evidence / "docx_structural_checks_s8_repaired.json",
        "docx_page_qa": evidence / "docx_page_qa.json",
    }
    qa_statuses = {}
    for label, path in qa_files.items():
        data = json.loads(path.read_text(encoding="utf-8"))
        if label == "html_browser_qa":
            ok = (
                data["desktop"]["tables"]["count"] == 19
                and data["desktop"]["figures"]["count"] == 20
                and data["desktop"]["links"]["unresolved"] == 0
                and data["desktop"]["links"]["badCitations"] == 0
                and data["desktop"]["markers"]["errors"] == 0
                and all(not data[name]["horizontalOverflow"]
                        for name in ("intermediate", "phone", "zoom200_equivalent"))
            )
        else:
            ok = data.get("status") == "PASS"
        qa_statuses[label] = "PASS" if ok else "FAIL"
        rows.append({
            "category": "qa_ledger",
            "path": str(path.relative_to(root)),
            "expected_sha256": "",
            "actual_sha256": sha256(path),
            "expected_bytes": "",
            "actual_bytes": path.stat().st_size,
            "status": "PASS" if ok else "FAIL",
            "note": label,
        })

    symlinks = [
        str(path.relative_to(root))
        for base in (root / "manuscript/R0_NatHealth", evidence)
        for path in base.rglob("*") if path.is_symlink()
    ]
    rows.append({
        "category": "filesystem",
        "path": "manuscript/R0_NatHealth and final evidence directory",
        "expected_sha256": "",
        "actual_sha256": "",
        "expected_bytes": "",
        "actual_bytes": "",
        "status": "PASS" if not symlinks else "FAIL",
        "note": "zero symlinks" if not symlinks else "; ".join(symlinks),
    })

    overall = "PASS" if all(row["status"] != "FAIL" for row in rows) else "FAIL"
    csv_path = evidence / "final_stability_checks.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    summary = {
        "status": overall,
        "checks": len(rows),
        "failures": [row for row in rows if row["status"] == "FAIL"],
        "informational_source_drifts": [
            row for row in rows if row["status"] == "INFO"
        ],
        "corpus_routes": len(corpus_rows),
        "corpus_source_checks": len(corpus_rows),
        "corpus_html_checks": len(corpus_rows),
        "qa_statuses": qa_statuses,
        "symlinks": symlinks,
        "final_html": {
            "path": "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html",
            "sha256": "8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac",
            "bytes": 30881505,
        },
        "final_docx": {
            "path": "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx",
            "sha256": "07ff074d4bd4124656063f69a2437b4c646a8240ad771ce94d30339f41d0604c",
            "bytes": 28749374,
        },
    }
    json_path = evidence / "final_stability_checks.json"
    json_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2))
    return 0 if overall == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
