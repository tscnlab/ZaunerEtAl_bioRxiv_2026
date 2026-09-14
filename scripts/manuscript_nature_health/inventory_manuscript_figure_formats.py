#!/usr/bin/env python3
"""Pin manuscript image files and possible same-name SVGs, without modifying displays."""

import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANUSCRIPT = ROOT / "manuscript/R0_NatHealth"
AUDIT = ROOT / "audit/manuscript_nature_health/revision_2026_09_11"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    records = []
    for name in ["ZaunerEtAl2026_NatHealth_phase3_brown.qmd", "supplementary_information_outline.qmd"]:
        source = MANUSCRIPT / name
        for line_number, line in enumerate(source.read_text().splitlines(), 1):
            targets = re.findall(r'!\[[^\]]*\]\(([^)]+)\)|<img\s+src="([^"]+)"', line)
            for markdown, html in targets:
                path = (source.parent / (markdown or html)).resolve()
                candidate = path.with_suffix(".svg")
                records.append({
                    "qmd": str(source.relative_to(ROOT)),
                    "line": line_number,
                    "current_path": str(path.relative_to(ROOT)),
                    "current_sha256": sha(path),
                    "current_format": path.suffix,
                    "same_name_svg": str(candidate.relative_to(ROOT)) if candidate.exists() else None,
                    "same_name_svg_sha256": sha(candidate) if candidate.exists() else None,
                    "status": "current SVG input" if path.suffix == ".svg" else
                              "SVG candidate exists; owner acceptance not inferred" if candidate.exists() else
                              "accepted SVG equivalent requested from owner",
                })
    output = {
        "scope": "Read-only structural inventory. A same-name file is not evidence of scientific or visual acceptance.",
        "figure_count": len(records),
        "svg_current_count": sum(record["current_format"] == ".svg" for record in records),
        "figures": records,
    }
    (AUDIT / "figure_format_inventory.json").write_text(json.dumps(output, indent=2) + "\n")
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
