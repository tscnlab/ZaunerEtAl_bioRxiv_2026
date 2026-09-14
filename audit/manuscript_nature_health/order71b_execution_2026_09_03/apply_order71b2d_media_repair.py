#!/usr/bin/env python3

"""Apply the sealed Order 71b2d one-media Word repair."""

from __future__ import annotations

import hashlib
import json
import zipfile
from copy import deepcopy
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = ROOT / "audit/manuscript_nature_health/order71b_execution_2026_09_03"
PREIMAGE = EVIDENCE / "docx_candidate/ZaunerEtAl2026_NatHealth_phase3_brown_candidate_bookmarks.docx"
CANDIDATE = EVIDENCE / "docx_candidate/ZaunerEtAl2026_NatHealth_phase3_brown_candidate_bookmarks_s3fixed.docx"
OLD_PNG = EVIDENCE / "word_capture/supp_table_s3_part_01.png"
NEW_PNG = EVIDENCE / "word_capture_s3_repair/supp_table_s3_width_1059_font_12.png"
ORIGINAL_MANIFEST = EVIDENCE / "word_capture/word_table_png_manifest.json"
NEW_MANIFEST = EVIDENCE / "word_capture_s3_repair/word_table_png_manifest_s3fixed.json"
OUTPUT = EVIDENCE / "order71b2d_media_repair.json"
MEDIA_MEMBER = "word/media/image15.png"

EXPECTED = {
    PREIMAGE: "9dd88539d7fea176423ecc5b201ea1ef8c92b925c561ffd5cb6ee9b5463f0e92",
    OLD_PNG: "d0d0216799239d4a11892b99ee26f06623d93761af7a7559a2cbddc150e8c4c7",
    NEW_PNG: "e8847874e5b1d08db8e67527c7ff4742fbd9912bae58ac161fecc21df6219e4c",
    ORIGINAL_MANIFEST: "6c7093de3f83be5e95fc6ddb299c6b05b1bde4935fff871abe6a1b3008e40b39",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def zip_payloads(path: Path) -> tuple[list[str], dict[str, bytes]]:
    with zipfile.ZipFile(path) as archive:
        assert archive.testzip() is None
        names = archive.namelist()
        assert len(names) == len(set(names))
        return names, {name: archive.read(name) for name in names}


def main() -> None:
    for path, expected_hash in EXPECTED.items():
        if not path.is_file():
            raise FileNotFoundError(path)
        assert sha256(path) == expected_hash
    if CANDIDATE.exists() or NEW_MANIFEST.exists() or OUTPUT.exists():
        raise FileExistsError("Order 71b2d output already exists")

    with Image.open(NEW_PNG) as image:
        assert image.size == (2118, 1464)

    new_png_bytes = NEW_PNG.read_bytes()
    old_png_bytes = OLD_PNG.read_bytes()
    temporary = CANDIDATE.with_suffix(".docx.tmp")
    if temporary.exists():
        raise FileExistsError(temporary)

    with zipfile.ZipFile(PREIMAGE, "r") as source, zipfile.ZipFile(temporary, "w") as target:
        assert source.testzip() is None
        source_names = source.namelist()
        assert len(source_names) == len(set(source_names))
        assert MEDIA_MEMBER in source_names
        assert source.read(MEDIA_MEMBER) == old_png_bytes
        for info in source.infolist():
            payload = new_png_bytes if info.filename == MEDIA_MEMBER else source.read(info.filename)
            target.writestr(info, payload)
    temporary.replace(CANDIDATE)

    before_names, before_payloads = zip_payloads(PREIMAGE)
    after_names, after_payloads = zip_payloads(CANDIDATE)
    assert before_names == after_names
    changed = [name for name in before_names if before_payloads[name] != after_payloads[name]]
    assert changed == [MEDIA_MEMBER]
    assert after_payloads[MEDIA_MEMBER] == new_png_bytes

    original_manifest = json.loads(ORIGINAL_MANIFEST.read_text(encoding="utf-8"))
    revised_manifest = deepcopy(original_manifest)
    matches = [entry for entry in revised_manifest if entry["key"] == "supp_table_s3"]
    assert len(matches) == 1 and len(matches[0]["files"]) == 1
    s3_file = matches[0]["files"][0]
    assert Path(s3_file["path"]) == OLD_PNG
    assert s3_file["cssWidth"] == 1059 and s3_file["cssHeight"] == 732
    s3_file["path"] = str(NEW_PNG)
    NEW_MANIFEST.write_text(
        json.dumps(revised_manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    roundtrip = json.loads(NEW_MANIFEST.read_text(encoding="utf-8"))
    roundtrip_s3 = next(entry for entry in roundtrip if entry["key"] == "supp_table_s3")
    assert Path(roundtrip_s3["files"][0]["path"]) == NEW_PNG
    roundtrip_s3["files"][0]["path"] = str(OLD_PNG)
    assert roundtrip == original_manifest

    result = {
        "status": "PASS",
        "preimage": {"path": str(PREIMAGE), "sha256": sha256(PREIMAGE), "bytes": PREIMAGE.stat().st_size},
        "candidate": {"path": str(CANDIDATE), "sha256": sha256(CANDIDATE), "bytes": CANDIDATE.stat().st_size},
        "changed_uncompressed_members": changed,
        "old_media": {"path": str(OLD_PNG), "sha256": sha256(OLD_PNG), "bytes": OLD_PNG.stat().st_size},
        "new_media": {
            "path": str(NEW_PNG),
            "sha256": sha256(NEW_PNG),
            "bytes": NEW_PNG.stat().st_size,
            "pixel_width": 2118,
            "pixel_height": 1464,
        },
        "table_manifest": {
            "path": str(NEW_MANIFEST),
            "sha256": sha256(NEW_MANIFEST),
            "bytes": NEW_MANIFEST.stat().st_size,
            "only_s3_path_changed": True,
            "css_width": 1059,
            "css_height": 732,
        },
    }
    OUTPUT.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
