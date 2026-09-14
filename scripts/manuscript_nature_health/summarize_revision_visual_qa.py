#!/usr/bin/env python3
"""Assemble rendered document pages for layout review, without scientific computation."""

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
AUDIT = ROOT / "audit/manuscript_nature_health/revision_2026_09_11"


def page_number(path):
    return int(path.stem.rsplit("-", 1)[1])


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    records = []
    for stem in ["Table_1", "Table_2", "Table_3"] + [
        f"Table_S{label}" for label in
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11a", "11b", "12", "13", "14", "15"]
    ]:
        source_dir = AUDIT / ("table_qa_main_caption_final" if "_S" not in stem else "table_qa_final") / stem
        for page in sorted(source_dir.glob("page-*.png"), key=page_number):
            records.append({"table": stem, "page": page_number(page), "path": str(page), "sha256": digest(page)})
    sheets = AUDIT / "table_page_sheets_release_candidate"
    sheets.mkdir(exist_ok=True)
    for offset in range(0, len(records), 4):
        batch = records[offset:offset + 4]
        canvas = Image.new("RGB", (2200, 1640), "#ececec")
        draw = ImageDraw.Draw(canvas)
        for position, record in enumerate(batch):
            left, top = (position % 2) * 1100, (position // 2) * 820
            with Image.open(record["path"]) as page:
                page.thumbnail((1080, 780))
                canvas.paste(page, (left + (1100 - page.width) // 2, top + 30))
            draw.text((left + 12, top + 8), f'{record["table"]}, page {record["page"]}', fill="black")
        canvas.save(sheets / f"sheet-{offset // 4 + 1}.png")

    earlier = AUDIT / "manuscript_qa_final"
    final = AUDIT / "manuscript_qa_reference_case_final"
    before = {path.name: digest(path) for path in earlier.glob("page-*.png")}
    after = {path.name: digest(path) for path in final.glob("page-*.png")}
    changed = sorted((name for name in after if before.get(name) != after[name]), key=lambda name: page_number(Path(name)))
    report = {
        "scope": "Document page layout and file identities only. No scientific computation.",
        "editable_table_documents": len(set(record["table"] for record in records)),
        "editable_table_pages": len(records),
        "table_pages": records,
        "manuscript_earlier_page_count": len(before),
        "manuscript_final_page_count": len(after),
        "manuscript_changed_pages_after_reference_case_repair": changed,
        "removed_pages": sorted(set(before) - set(after)),
    }
    (AUDIT / "visual_qa_page_inventory.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({key: value for key, value in report.items() if key != "table_pages"}, indent=2))


if __name__ == "__main__":
    main()
