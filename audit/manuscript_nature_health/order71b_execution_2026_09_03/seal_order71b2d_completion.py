#!/usr/bin/env python3

"""Create the non-circular Order 71b2d completion record and manifest."""

from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = ROOT / "audit/manuscript_nature_health/order71b_execution_2026_09_03"
RECORD = EVIDENCE / "order71b2d_completion.md"
MANIFEST = EVIDENCE / "order71b2d_completion_manifest.csv"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def relative(path: Path) -> str:
    return str(path.relative_to(ROOT))


def main() -> None:
    if RECORD.exists() or MANIFEST.exists():
        raise FileExistsError("Order 71b2d completion has already been sealed")

    structural = json.loads((EVIDENCE / "docx_order71b2d_checks.json").read_text(encoding="utf-8"))
    pages = json.loads((EVIDENCE / "order71b2d_page_comparison.json").read_text(encoding="utf-8"))
    promotion = json.loads((EVIDENCE / "order71b2d_promotion.json").read_text(encoding="utf-8"))
    media = json.loads((EVIDENCE / "order71b2d_media_repair.json").read_text(encoding="utf-8"))
    assert structural["status"] == pages["status"] == promotion["status"] == media["status"] == "PASS"
    assert promotion["canonical_postimage_sha256"] == structural["candidate"]["sha256"]
    assert structural["changed_uncompressed_members"] == ["word/media/image15.png"]
    assert pages["pages"] == 102 and pages["changed_pages"] == [61]

    record_text = f"""# REPORT-018 Order 71b2d completion

Date: 2026-09-03

Status: `PASS_PROMOTED_AWAITING_INDEPENDENT_ACCEPTANCE`

## Outcome

The final Nature Health Word manuscript was promoted once to
`manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`.
Its SHA-256 is `{promotion['canonical_postimage_sha256']}` and its size is
{promotion['canonical_postimage_bytes']:,} bytes.

The sole Word display repair replaced `word/media/image15.png`, the captured
Supplementary Table S3, while preserving every other uncompressed DOCX member.
The repaired PNG is 2,118 by 1,464 pixels, SHA-256
`{structural['embedded_s3']['sha256']}`. It preserves the approved 1,059 CSS-pixel
table width and 12-pixel capture font while showing every denominator in full.

## Validation

- The sealed dispatch manifest reproduced 18 of 18 identities under R 4.6.1.
- The complete structural suite passed: 87 valid package parts, 28 authors,
  14 affiliations, 91 bibliography entries, 53 displays, 27 sections, 124
  resolved internal links, 102 unique targets and 195 bookmarks.
- The exact 22 repaired destinations remain present. `fig-s3` remains absent
  from both hyperlink and bookmark sets as required.
- The replacement render contains {pages['pages']} pages with unchanged page
  dimensions. Pages 1 to 60 and 62 to 102 are decoded-pixel identical to the
  previously inspected render. Page 61 differs only within the Supplementary
  Table S3 image region ({pages['page_61_difference_bbox']}).
- Original-resolution inspection passed for all 102 pages. On page 61, the
  complete `555,738 / 1,086,468` total and all four `1,175,160` denominators
  are readable without clipping, overlap or missing glyphs.
- The accepted manuscript QMD, Supplementary Information QMD, self-contained
  HTML, direct Supplementary Figure S6 SVG and integrated website remain exact.

## Statistical terminology decision

The author's preference for R² or variance explained is already satisfied in
the frozen manuscript wherever those terms are technically valid. H02, Brown
adherence, H01/H07 and the exploratory H03/H04 mixed-model summaries use R² or
explained variance. The two H03/H04 time-of-day decompositions remain described
as shares of variation in fitted hourly patterns because they partition fitted
linear-predictor variation without a response-variance denominator and are not
R². This decision required no source or render change.

## Evidence

The non-circular completion manifest is
`audit/manuscript_nature_health/order71b_execution_2026_09_03/order71b2d_completion_manifest.csv`.
It excludes itself. The 102-page inventory, page comparison and every-page QA
records are listed there with exact identities.
"""
    RECORD.write_text(record_text, encoding="utf-8")

    items = [
        ("sealed_order", ROOT / "audit/report_harmonization/owner_orders/71b2d_nature_health_word_supp_table_s3_media_repair.md"),
        ("dispatch_manifest", ROOT / "audit/report_harmonization/report018_writer_order71b2d_dispatch_manifest.csv"),
        ("dispatch_replay", EVIDENCE / "order71b2d_dispatch_replay.csv"),
        ("probe_record", ROOT / "audit/report_harmonization/report018_writer_order71b2d_supp_table_s3_capture_probe.md"),
        ("probe_helper", ROOT / "audit/report_harmonization/probe_supp_table_s3_capture.mjs"),
        ("probe_report", EVIDENCE / "word_capture_s3_repair/probe_report.json"),
        ("repaired_s3_media", EVIDENCE / "word_capture_s3_repair/supp_table_s3_width_1059_font_12.png"),
        ("original_table_manifest", EVIDENCE / "word_capture/word_table_png_manifest.json"),
        ("repaired_table_manifest", EVIDENCE / "word_capture_s3_repair/word_table_png_manifest_s3fixed.json"),
        ("accepted_bookmarked_candidate", EVIDENCE / "docx_candidate/ZaunerEtAl2026_NatHealth_phase3_brown_candidate_bookmarks.docx"),
        ("s3fixed_candidate", EVIDENCE / "docx_candidate/ZaunerEtAl2026_NatHealth_phase3_brown_candidate_bookmarks_s3fixed.docx"),
        ("canonical_docx_postimage", ROOT / "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx"),
        ("media_repair_script", EVIDENCE / "apply_order71b2d_media_repair.py"),
        ("media_repair_record", EVIDENCE / "order71b2d_media_repair.json"),
        ("base_validator", EVIDENCE / "verify_order71b_docx.py"),
        ("bookmark_validator", EVIDENCE / "verify_order71b2b_docx.py"),
        ("order71b2d_validator", EVIDENCE / "verify_order71b2d_docx.py"),
        ("base_structural_output", EVIDENCE / "docx_structural_checks_s3fixed.json"),
        ("order71b2d_structural_output", EVIDENCE / "docx_order71b2d_checks.json"),
        ("page_validator", EVIDENCE / "verify_order71b2d_pages.py"),
        ("page_render_pdf", EVIDENCE / "page_render_s3fixed/ZaunerEtAl2026_NatHealth_phase3_brown_candidate_bookmarks_s3fixed.pdf"),
        ("page_inventory", EVIDENCE / "order71b2d_page_inventory.csv"),
        ("page_comparison", EVIDENCE / "order71b2d_page_comparison.json"),
        ("every_page_visual_qa", EVIDENCE / "order71b2d_every_page_visual_qa.csv"),
        ("promotion_script", EVIDENCE / "promote_order71b2d_docx.py"),
        ("promotion_record", EVIDENCE / "order71b2d_promotion.json"),
        ("dispatch_replay_script", EVIDENCE / "verify_order71b2d_dispatch.R"),
        ("completion_seal_script", Path(__file__).resolve()),
        ("completion_record", RECORD),
        ("accepted_main_source", ROOT / "manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"),
        ("accepted_si_source", ROOT / "manuscript/R0_NatHealth/supplementary_information_outline.qmd"),
        ("accepted_html", ROOT / "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html"),
        ("accepted_s6_svg", ROOT / "manuscript/R0_NatHealth/display_assets/brown_participant_state_raincloud.svg"),
        ("protected_site", ROOT / "_build/nathealth/index.html"),
    ]
    roles = [role for role, _ in items]
    paths = [path for _, path in items]
    assert len(roles) == len(set(roles))
    assert len(paths) == len(set(paths))
    assert MANIFEST not in paths
    for path in paths:
        if not path.is_file():
            raise FileNotFoundError(path)

    rows = [
        {
            "role": role,
            "path": relative(path),
            "sha256": sha256(path),
            "bytes": path.stat().st_size,
        }
        for role, path in items
    ]
    with MANIFEST.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=["role", "path", "sha256", "bytes"])
        writer.writeheader()
        writer.writerows(rows)

    print(
        json.dumps(
            {
                "status": "PASS_PROMOTED_AWAITING_INDEPENDENT_ACCEPTANCE",
                "completion_record": relative(RECORD),
                "completion_record_sha256": sha256(RECORD),
                "manifest": relative(MANIFEST),
                "manifest_sha256": sha256(MANIFEST),
                "manifest_members": len(rows),
                "canonical_docx_sha256": promotion["canonical_postimage_sha256"],
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
