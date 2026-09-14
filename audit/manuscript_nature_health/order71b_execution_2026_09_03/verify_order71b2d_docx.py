#!/usr/bin/env python3

"""Run the complete Order 71b gate and Order 71b2d media-only checks."""

from __future__ import annotations

import hashlib
import importlib.util
import io
import json
import zipfile
from pathlib import Path

from lxml import etree
from PIL import Image
from docx.oxml.ns import qn


ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = ROOT / "audit/manuscript_nature_health/order71b_execution_2026_09_03"
BASE_VALIDATOR = EVIDENCE / "verify_order71b_docx.py"
BOOKMARKED = EVIDENCE / "docx_candidate/ZaunerEtAl2026_NatHealth_phase3_brown_candidate_bookmarks.docx"
CANDIDATE = EVIDENCE / "docx_candidate/ZaunerEtAl2026_NatHealth_phase3_brown_candidate_bookmarks_s3fixed.docx"
ORIGINAL_TABLE_MANIFEST = EVIDENCE / "word_capture/word_table_png_manifest.json"
TABLE_MANIFEST = EVIDENCE / "word_capture_s3_repair/word_table_png_manifest_s3fixed.json"
NEW_MEDIA = EVIDENCE / "word_capture_s3_repair/supp_table_s3_width_1059_font_12.png"
BASE_OUTPUT = EVIDENCE / "docx_structural_checks_s3fixed.json"
OUTPUT = EVIDENCE / "docx_order71b2d_checks.json"
MEDIA_MEMBER = "word/media/image15.png"
NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}

EXPECTED_REPAIRED = {
    "fig-study-overview",
    "fig-daily-architecture",
    "fig-activity-context",
    "tbl-participant-site",
    "tbl-brown-adherence",
    "tbl-metric-context",
    "fig-s1",
    "fig-s2",
    *(f"fig-s{number}" for number in range(4, 18)),
}

PROTECTED = {
    ROOT / "manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd": "a527b6cb9ba689ab15370a05776280c632073ef27b79320a271feca96b27c69f",
    ROOT / "manuscript/R0_NatHealth/supplementary_information_outline.qmd": "fbfdde52cd24a60a5ff19eefb7901d3b7dcb268d97c2c922e0e87e7c944c652e",
    ROOT / "manuscript/R0_NatHealth/display_assets/brown_participant_state_raincloud.svg": "200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653",
    ROOT / "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html": "438f80545e09eb1844d15c3d4495d7d2d4dbc07bcf039f4c8e4430b18e79ee0c",
    ROOT / "_build/nathealth/index.html": "c8abe2f9fbfcbe2fc8b4e39e149797a6dc2d74a5735337ed2399fb6e5814eb21",
}


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_parts(path: Path) -> tuple[list[str], dict[str, bytes]]:
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
        names = archive.namelist()
        assert len(names) == len(set(names))
        return names, {name: archive.read(name) for name in names}


def bookmark_inventory(document_xml: bytes) -> dict[str, object]:
    root = etree.fromstring(document_xml)
    anchors = [
        node.get(qn("w:anchor"))
        for node in root.xpath(".//w:hyperlink[@w:anchor]", namespaces=NS)
    ]
    starts = root.xpath(".//w:bookmarkStart", namespaces=NS)
    ends = root.xpath(".//w:bookmarkEnd", namespaces=NS)
    names = [node.get(qn("w:name")) for node in starts]
    start_ids = [node.get(qn("w:id")) for node in starts]
    end_ids = [node.get(qn("w:id")) for node in ends]
    return {
        "anchors": anchors,
        "names": names,
        "start_ids": start_ids,
        "end_ids": end_ids,
        "unresolved": sorted(set(anchors) - set(names)),
    }


def main() -> None:
    for path in (BASE_VALIDATOR, BOOKMARKED, CANDIDATE, ORIGINAL_TABLE_MANIFEST, TABLE_MANIFEST, NEW_MEDIA):
        if not path.is_file():
            raise FileNotFoundError(path)
    for path, expected_hash in PROTECTED.items():
        assert sha256(path) == expected_hash
    assert sha256(BOOKMARKED) == "9dd88539d7fea176423ecc5b201ea1ef8c92b925c561ffd5cb6ee9b5463f0e92"
    assert sha256(NEW_MEDIA) == "e8847874e5b1d08db8e67527c7ff4742fbd9912bae58ac161fecc21df6219e4c"

    spec = importlib.util.spec_from_file_location("order71b_validator_s3fixed", BASE_VALIDATOR)
    assert spec is not None and spec.loader is not None
    validator = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(validator)
    validator.CANDIDATE = CANDIDATE
    validator.TABLE_MANIFEST = TABLE_MANIFEST
    validator.OUTPUT = BASE_OUTPUT
    validator.main()

    before_names, before_parts = read_parts(BOOKMARKED)
    after_names, after_parts = read_parts(CANDIDATE)
    assert before_names == after_names
    changed = [name for name in before_names if before_parts[name] != after_parts[name]]
    assert changed == [MEDIA_MEMBER]
    assert before_parts["word/document.xml"] == after_parts["word/document.xml"]
    assert before_parts["word/_rels/document.xml.rels"] == after_parts["word/_rels/document.xml.rels"]
    assert after_parts[MEDIA_MEMBER] == NEW_MEDIA.read_bytes()

    with Image.open(io.BytesIO(after_parts[MEDIA_MEMBER])) as image:
        embedded_dimensions = image.size
    assert embedded_dimensions == (2118, 1464)

    bookmarks = bookmark_inventory(after_parts["word/document.xml"])
    assert len(bookmarks["anchors"]) == 124
    assert len(set(bookmarks["anchors"])) == 102
    assert len(bookmarks["names"]) == len(bookmarks["start_ids"]) == len(bookmarks["end_ids"]) == 195
    assert len(set(bookmarks["names"])) == len(set(bookmarks["start_ids"])) == 195
    assert set(bookmarks["start_ids"]) == set(bookmarks["end_ids"])
    assert bookmarks["unresolved"] == []
    assert EXPECTED_REPAIRED <= set(bookmarks["names"])
    assert len(EXPECTED_REPAIRED) == 22
    assert "fig-s3" not in bookmarks["anchors"] and "fig-s3" not in bookmarks["names"]

    original_manifest = json.loads(ORIGINAL_TABLE_MANIFEST.read_text(encoding="utf-8"))
    revised_manifest = json.loads(TABLE_MANIFEST.read_text(encoding="utf-8"))
    revised_s3 = next(entry for entry in revised_manifest if entry["key"] == "supp_table_s3")
    assert revised_s3["files"][0]["cssWidth"] == 1059
    assert revised_s3["files"][0]["cssHeight"] == 732
    assert Path(revised_s3["files"][0]["path"]) == NEW_MEDIA
    revised_s3["files"][0]["path"] = str(EVIDENCE / "word_capture/supp_table_s3_part_01.png")
    assert revised_manifest == original_manifest

    reversed_parts = dict(after_parts)
    reversed_parts[MEDIA_MEMBER] = before_parts[MEDIA_MEMBER]
    assert all(reversed_parts[name] == before_parts[name] for name in before_names)

    result = {
        "status": "PASS",
        "candidate": {"path": str(CANDIDATE), "sha256": sha256(CANDIDATE), "bytes": CANDIDATE.stat().st_size},
        "bookmarked_preimage": {"path": str(BOOKMARKED), "sha256": sha256(BOOKMARKED), "bytes": BOOKMARKED.stat().st_size},
        "identical_member_names_and_order": True,
        "changed_uncompressed_members": changed,
        "document_xml_byte_identical": True,
        "document_relationships_byte_identical": True,
        "embedded_s3": {
            "member": MEDIA_MEMBER,
            "sha256": sha256_bytes(after_parts[MEDIA_MEMBER]),
            "pixel_width": embedded_dimensions[0],
            "pixel_height": embedded_dimensions[1],
        },
        "references": {
            "internal_hyperlinks": len(bookmarks["anchors"]),
            "unique_targets": len(set(bookmarks["anchors"])),
            "bookmarks": len(bookmarks["names"]),
            "repaired_destinations": len(EXPECTED_REPAIRED),
            "unresolved": bookmarks["unresolved"],
            "fig_s3_hyperlinks": bookmarks["anchors"].count("fig-s3"),
            "fig_s3_bookmarks": bookmarks["names"].count("fig-s3"),
        },
        "table_manifest_only_s3_path_changed": True,
        "exact_uncompressed_reversal": True,
        "protected_qmd_html_svg_site_exact": len(PROTECTED),
        "base_order71b_gate": str(BASE_OUTPUT),
    }
    OUTPUT.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
