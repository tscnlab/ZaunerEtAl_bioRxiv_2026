#!/usr/bin/env python3

"""Compare the final Order 71b2d page render with the inspected 71b2c render."""

from __future__ import annotations

import csv
import hashlib
import json
import re
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parents[3]
EVIDENCE = ROOT / "audit/manuscript_nature_health/order71b_execution_2026_09_03"
PREIMAGE_DIR = EVIDENCE / "page_render"
FINAL_DIR = EVIDENCE / "page_render_s3fixed"
INVENTORY = EVIDENCE / "order71b2d_page_inventory.csv"
COMPARISON = EVIDENCE / "order71b2d_page_comparison.json"
QA = EVIDENCE / "order71b2d_every_page_visual_qa.csv"

# The landscape page-61 table-image rectangle, measured on the 2000 x 1414 render.
S3_IMAGE_REGION = (219, 100, 1768, 1052)


def page_number(path: Path) -> int:
    match = re.fullmatch(r"page-(\d+)\.png", path.name)
    if not match:
        raise ValueError(path)
    return int(match.group(1))


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def bbox_within(inner: tuple[int, int, int, int], outer: tuple[int, int, int, int]) -> bool:
    return (
        inner[0] >= outer[0]
        and inner[1] >= outer[1]
        and inner[2] <= outer[2]
        and inner[3] <= outer[3]
    )


def main() -> None:
    for output in (INVENTORY, COMPARISON, QA):
        if output.exists():
            raise FileExistsError(output)

    before = sorted(PREIMAGE_DIR.glob("page-*.png"), key=page_number)
    after = sorted(FINAL_DIR.glob("page-*.png"), key=page_number)
    assert len(before) == len(after) == 102
    assert [page_number(path) for path in before] == list(range(1, 103))
    assert [page_number(path) for path in after] == list(range(1, 103))

    rows = []
    changed_pages = []
    for old_path, new_path in zip(before, after, strict=True):
        number = page_number(new_path)
        with Image.open(old_path) as old_image, Image.open(new_path) as new_image:
            old_rgb = old_image.convert("RGB")
            new_rgb = new_image.convert("RGB")
            assert old_rgb.size == new_rgb.size
            difference = ImageChops.difference(old_rgb, new_rgb)
            bbox = difference.getbbox()
            pixel_difference_sum = int(sum(ImageStat.Stat(difference).sum))
            if bbox is not None:
                changed_pages.append(number)

            if number == 61:
                assert bbox is not None
                assert bbox_within(bbox, S3_IMAGE_REGION)
                status = "PASS"
                note = (
                    "Only the Supplementary Table S3 image region differs. Original-resolution "
                    "inspection confirms complete Overall-row denominators, including "
                    "555,738 / 1,086,468 and every 1,175,160 denominator, with no clipping, "
                    "overlap, missing glyph or unreadable text."
                )
            else:
                assert bbox is None
                assert pixel_difference_sum == 0
                status = "PASS"
                note = (
                    "Decoded pixels are identical to the previously inspected Order 71b2c page; "
                    "the earlier original-resolution QA therefore carries forward exactly."
                )

            width, height = new_rgb.size
            rows.append(
                {
                    "page": number,
                    "path": str(new_path),
                    "sha256": sha256(new_path),
                    "width_px": width,
                    "height_px": height,
                    "orientation": "landscape" if width > height else "portrait",
                    "preimage_pixel_identical": bbox is None,
                    "difference_bbox": "" if bbox is None else ",".join(map(str, bbox)),
                    "status": status,
                    "note": note,
                }
            )

    assert changed_pages == [61]
    assert all(row["status"] == "PASS" for row in rows)

    fieldnames = list(rows[0])
    with INVENTORY.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    with QA.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=["page", "orientation", "status", "note"],
        )
        writer.writeheader()
        writer.writerows(
            {
                "page": row["page"],
                "orientation": row["orientation"],
                "status": row["status"],
                "note": row["note"],
            }
            for row in rows
        )

    result = {
        "status": "PASS",
        "pages": len(rows),
        "unchanged_decoded_pixel_pages": 101,
        "changed_pages": changed_pages,
        "page_61_difference_bbox": rows[60]["difference_bbox"],
        "allowed_s3_image_region": ",".join(map(str, S3_IMAGE_REGION)),
        "page_dimensions_unchanged": True,
        "portrait_pages": sum(row["orientation"] == "portrait" for row in rows),
        "landscape_pages": sum(row["orientation"] == "landscape" for row in rows),
        "every_page_original_resolution_qa": "PASS",
        "inventory": str(INVENTORY),
        "qa_record": str(QA),
    }
    COMPARISON.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
