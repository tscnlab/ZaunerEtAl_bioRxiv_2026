#!/usr/bin/env python3
"""Compare document page images and assemble visual QA sheets; no scientific audit."""

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent
BASE = OUT.parent / "manuscript_qa_reference_case_final"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def number(path):
    return int(path.stem.rsplit("-", 1)[1])


def main():
    pages = sorted((OUT / "rendered_pages").glob("page-*.png"), key=number)
    rows = [{"page": number(page), "path": str(page), "sha256": sha(page),
             "baseline_sha256": sha(BASE / page.name), "byte_identical": sha(page) == sha(BASE / page.name)}
            for page in pages]
    sheets = OUT / "review_sheets"
    sheets.mkdir(exist_ok=True)
    for start in range(0, len(pages), 6):
        canvas = Image.new("RGB", (2250, 2210), "#ececec")
        draw = ImageDraw.Draw(canvas)
        for index, page in enumerate(pages[start:start + 6]):
            left, top = index % 3 * 750, index // 3 * 1105
            with Image.open(page) as img:
                img.thumbnail((730, 1060))
                canvas.paste(img, (left + (750 - img.width) // 2, top + 30))
            draw.text((left + 12, top + 10), f'Page {number(page)}', fill="black")
        canvas.save(sheets / f"sheet-{start // 6 + 1}.png")
    record = {"baseline_render": str(BASE), "complete_render_page_count": len(pages),
              "baseline_page_count": len(list(BASE.glob("page-*.png"))),
              "changed_pages": [row["page"] for row in rows if not row["byte_identical"]],
              "identical_page_count": sum(row["byte_identical"] for row in rows), "pages": rows}
    (OUT / "page_comparison.json").write_text(json.dumps(record, indent=2) + "\n")
    print(json.dumps({key: value for key, value in record.items() if key != "pages"}, indent=2))


if __name__ == "__main__":
    main()
