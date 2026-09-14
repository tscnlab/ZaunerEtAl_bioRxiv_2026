#!/usr/bin/env python3

"""Run the full Order 71b gate plus explicit Order 71b2b bookmark checks."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import zipfile
from pathlib import Path

from lxml import etree
from docx.oxml.ns import qn


ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = ROOT / "audit/manuscript_nature_health/order71b_execution_2026_09_03"
BASE_VALIDATOR = EVIDENCE / "verify_order71b_docx.py"
STOPPED = EVIDENCE / "docx_candidate/ZaunerEtAl2026_NatHealth_phase3_brown_candidate.docx"
CANDIDATE = EVIDENCE / "docx_candidate/ZaunerEtAl2026_NatHealth_phase3_brown_candidate_bookmarks.docx"
BASE_OUTPUT = EVIDENCE / "docx_structural_checks_bookmarks.json"
BOOKMARK_OUTPUT = EVIDENCE / "docx_bookmark_checks.json"

EXPECTED_MISSING = {
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
EXPECTED_DESTINATIONS = {
    "fig-study-overview": "Figure 1:",
    "tbl-participant-site": "Table 1:",
    "tbl-brown-adherence": "Table 2:",
    "fig-daily-architecture": "Figure 2:",
    "tbl-metric-context": "Table 3:",
    "fig-activity-context": "Figure 3:",
    "fig-s1": "Supplementary Figure S1.",
    "fig-s2": "Supplementary Figure S2.",
    **{
        f"fig-s{number}": f"Supplementary Figure S{number}"
        for number in range(4, 18)
    },
}
NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def read_parts(path: Path) -> dict[str, bytes]:
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
        names = archive.namelist()
        assert len(names) == len(set(names))
        return {name: archive.read(name) for name in names}


def clean_text(value: str) -> str:
    return " ".join(value.replace("\xa0", " ").split())


def inventory(document_xml: bytes) -> dict[str, object]:
    root = etree.fromstring(document_xml)
    hyperlinks = root.xpath(".//w:hyperlink[@w:anchor]", namespaces=NS)
    anchors = [node.get(qn("w:anchor")) for node in hyperlinks]
    starts = root.xpath(".//w:bookmarkStart", namespaces=NS)
    ends = root.xpath(".//w:bookmarkEnd", namespaces=NS)
    names = [node.get(qn("w:name")) for node in starts]
    start_ids = [node.get(qn("w:id")) for node in starts]
    end_ids = [node.get(qn("w:id")) for node in ends]
    return {
        "root": root,
        "anchors": anchors,
        "starts": starts,
        "ends": ends,
        "names": names,
        "start_ids": start_ids,
        "end_ids": end_ids,
        "unresolved": sorted(set(anchors) - set(names)),
    }


def element_serialization(node) -> str:
    return etree.tostring(node, encoding="unicode", with_tail=True)


def main() -> None:
    assert STOPPED.exists() and CANDIDATE.exists()

    spec = importlib.util.spec_from_file_location("order71b_validator", BASE_VALIDATOR)
    assert spec is not None and spec.loader is not None
    validator = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(validator)
    validator.CANDIDATE = CANDIDATE
    validator.OUTPUT = BASE_OUTPUT
    validator.main()

    before_parts = read_parts(STOPPED)
    after_parts = read_parts(CANDIDATE)
    assert set(before_parts) == set(after_parts)
    changed_parts = sorted(
        name
        for name in before_parts
        if before_parts[name] != after_parts[name]
    )
    assert changed_parts == ["word/document.xml"]

    before = inventory(before_parts["word/document.xml"])
    after = inventory(after_parts["word/document.xml"])

    assert len(before["anchors"]) == len(after["anchors"]) == 124
    assert before["anchors"] == after["anchors"]
    assert len(set(before["anchors"])) == len(set(after["anchors"])) == 102
    assert len(before["starts"]) == len(before["ends"]) == 173
    assert len(set(before["names"])) == len(set(before["start_ids"])) == 173
    assert set(before["start_ids"]) == set(before["end_ids"])
    assert set(before["unresolved"]) == EXPECTED_MISSING
    assert "fig-s3" not in before["anchors"] and "fig-s3" not in before["names"]

    assert len(after["starts"]) == len(after["ends"]) == 195
    assert len(set(after["names"])) == len(set(after["start_ids"])) == 195
    assert set(after["start_ids"]) == set(after["end_ids"])
    assert after["unresolved"] == []
    assert "fig-s3" not in after["anchors"] and "fig-s3" not in after["names"]

    before_start_map = {
        (node.get(qn("w:id")), node.get(qn("w:name"))): element_serialization(node)
        for node in before["starts"]
    }
    before_end_map = {
        node.get(qn("w:id")): element_serialization(node) for node in before["ends"]
    }
    after_start_map = {
        (node.get(qn("w:id")), node.get(qn("w:name"))): element_serialization(node)
        for node in after["starts"]
    }
    after_end_map = {
        node.get(qn("w:id")): element_serialization(node) for node in after["ends"]
    }
    assert all(after_start_map.get(key) == value for key, value in before_start_map.items())
    assert all(after_end_map.get(key) == value for key, value in before_end_map.items())

    added_names = set(after["names"]) - set(before["names"])
    added_ids = set(after["start_ids"]) - set(before["start_ids"])
    assert added_names == EXPECTED_MISSING
    assert len(added_ids) == 22
    assert sorted(map(int, added_ids)) == list(range(354, 376))

    destination_rows = []
    added_id_by_name = {
        node.get(qn("w:name")): node.get(qn("w:id"))
        for node in after["starts"]
        if node.get(qn("w:name")) in EXPECTED_MISSING
    }
    for name in sorted(EXPECTED_MISSING):
        matches = [
            node
            for node in after["starts"]
            if node.get(qn("w:name")) == name
        ]
        assert len(matches) == 1
        start = matches[0]
        paragraph = start.getparent()
        assert paragraph.tag == qn("w:p")
        following = start.getnext()
        assert following is not None and following.tag == qn("w:bookmarkEnd")
        assert following.get(qn("w:id")) == start.get(qn("w:id"))
        preceding = start.getprevious()
        assert preceding is None or preceding.tag == qn("w:pPr")
        text = clean_text("".join(paragraph.xpath(".//w:t/text()", namespaces=NS)))
        assert text.startswith(EXPECTED_DESTINATIONS[name])
        destination_rows.append(
            {"name": name, "id": added_id_by_name[name], "destination": text},
        )

    reversed_root = etree.fromstring(after_parts["word/document.xml"])
    for node in list(reversed_root.xpath(".//w:bookmarkStart", namespaces=NS)):
        if node.get(qn("w:name")) in EXPECTED_MISSING:
            node.getparent().remove(node)
    for node in list(reversed_root.xpath(".//w:bookmarkEnd", namespaces=NS)):
        if node.get(qn("w:id")) in added_ids:
            node.getparent().remove(node)
    before_root = etree.fromstring(before_parts["word/document.xml"])
    assert etree.tostring(reversed_root) == etree.tostring(before_root)

    results = {
        "status": "PASS",
        "stopped_candidate": {
            "path": str(STOPPED),
            "sha256": sha256_bytes(STOPPED.read_bytes()),
            "bytes": STOPPED.stat().st_size,
            "internal_hyperlinks": len(before["anchors"]),
            "unique_targets": len(set(before["anchors"])),
            "bookmark_names": len(set(before["names"])),
            "unresolved": before["unresolved"],
        },
        "repaired_candidate": {
            "path": str(CANDIDATE),
            "sha256": sha256_bytes(CANDIDATE.read_bytes()),
            "bytes": CANDIDATE.stat().st_size,
            "internal_hyperlinks": len(after["anchors"]),
            "unique_targets": len(set(after["anchors"])),
            "bookmark_names": len(set(after["names"])),
            "unresolved": after["unresolved"],
        },
        "fig_s3_hyperlinks_before_after": [
            before["anchors"].count("fig-s3"),
            after["anchors"].count("fig-s3"),
        ],
        "fig_s3_bookmarks_before_after": [
            before["names"].count("fig-s3"),
            after["names"].count("fig-s3"),
        ],
        "changed_package_parts": changed_parts,
        "pre_existing_bookmark_starts_preserved": len(before_start_map),
        "pre_existing_bookmark_ends_preserved": len(before_end_map),
        "added_bookmarks": destination_rows,
        "exact_document_xml_reversal": True,
        "base_order71b_gate": str(BASE_OUTPUT),
    }
    BOOKMARK_OUTPUT.write_text(
        json.dumps(results, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(results, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
