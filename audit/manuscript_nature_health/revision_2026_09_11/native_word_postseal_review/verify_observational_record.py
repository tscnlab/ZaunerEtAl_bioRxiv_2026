"""Read-only document/SVG structure checks and a task-owned evidence inventory.

This script does not calculate, reproduce or validate a scientific result.
"""

import base64
import csv
import hashlib
import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from lxml import etree

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
STOPPED = OUT.parent / "svg_complete_order72d"


def digest(path):
    with path.open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


manifest_path = STOPPED / "combined_accepted_svg_manifest.json"
figure_manifest = json.loads(manifest_path.read_text())
pins = {
    STOPPED / "ZaunerEtAl2026_NatHealth_svg_complete_order72d.docx":
        "933249b33defbb2155b0d98da60db980302817537b06671982dc5114ce29eac9",
    STOPPED / "stopped_manifest.csv":
        "76bebd6da0ab5985c67b229780d6c8143d82bd8fdb969b1b22d38b4d96d9ecf3",
    manifest_path:
        "0e0618520fedb387ef030b685e11597e7332ae46fa7ad9ad76d865c24b1c91b2",
}

checks = []
structures = []
for row in figure_manifest["accepted_figures"]:
    source = ROOT / row["path"]
    pins[source] = row["sha256"]
    payloads = Counter()
    embedded_depths = []

    def inspect(data, level=0):
        parser = etree.XMLParser(resolve_entities=False, no_network=True)
        tree = etree.fromstring(data, parser=parser)
        for item in tree.xpath('//*[local-name()="image"]'):
            href = item.get("href") or item.get(
                "{http://www.w3.org/1999/xlink}href", ""
            )
            kind = href.split(",", 1)[0] if href.startswith("data:") else "external-reference"
            payloads[kind] += 1
            if kind == "data:image/svg+xml;base64":
                if level >= 5:
                    raise RuntimeError("Unexpected SVG nesting depth")
                embedded_depths.append(level + 1)
                inspect(base64.b64decode(href.split(",", 1)[1]), level + 1)

    inspect(source.read_bytes())
    structures.append({
        "figure": row["word_label"],
        "source": row["path"],
        "sha256": digest(source),
        "image_payload_types": dict(payloads),
        "maximum_embedded_svg_depth": max(embedded_depths, default=0),
    })

for path, expected in pins.items():
    actual = digest(path)
    checks.append({
        "path": str(path.relative_to(ROOT)),
        "expected_sha256": expected,
        "actual_sha256": actual,
        "unchanged": actual == expected,
    })

result = {
    "checked_utc": datetime.now(timezone.utc).isoformat(),
    "operation": "Non-analytical document/SVG structure and checksum verification",
    "native_word_figure_appearances_inspected": 21,
    "native_word_screenshots": "Emitted in task transcript; local archive pending",
    "candidate_accepted": False,
    "all_input_pins_exact": all(row["unchanged"] for row in checks),
    "checks": checks,
}
if not result["all_input_pins_exact"]:
    raise RuntimeError(json.dumps(result, indent=2))

(OUT / "input_checks.json").write_text(json.dumps(result, indent=2) + "\n")
(OUT / "svg_structure.json").write_text(json.dumps(structures, indent=2) + "\n")

members = set(pins)
members.update(path for path in OUT.iterdir() if path.is_file()
               and path.name != "observational_record_manifest.csv")
with (OUT / "observational_record_manifest.csv").open("w", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=["path", "sha256", "bytes", "role"])
    writer.writeheader()
    for path in sorted(members):
        writer.writerow({
            "path": str(path.relative_to(ROOT)),
            "sha256": digest(path),
            "bytes": path.stat().st_size,
            "role": "protected_input" if path in pins else "postseal_observation",
        })
print(json.dumps({
    "all_input_pins_exact": result["all_input_pins_exact"],
    "protected_input_count": len(pins),
    "manifest_members": len(members),
    "manifest_sha256": digest(OUT / "observational_record_manifest.csv"),
    "screenshot_archive_complete": False,
    "candidate_accepted": False,
}, indent=2))
