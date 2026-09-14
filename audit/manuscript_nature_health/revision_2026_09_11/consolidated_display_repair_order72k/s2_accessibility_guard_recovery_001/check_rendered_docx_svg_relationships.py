"""Structural diagnosis only: no package or rendering edits."""
from pathlib import Path
from zipfile import ZipFile
import hashlib
import json
import posixpath
import sys
from lxml import etree

source = Path(sys.argv[1])
ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
      "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
      "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
      "asvg": "http://schemas.microsoft.com/office/drawing/2016/SVG/main"}
with ZipFile(source) as z:
    doc = etree.fromstring(z.read("word/document.xml"))
    rels = {r.get("Id"): r.get("Target") for r in etree.fromstring(z.read("word/_rels/document.xml.rels"))}
    rows = []
    for table in doc.xpath("./w:body/w:tbl", namespaces=ns):
        text = " ".join("".join(table.xpath(".//w:t/text()", namespaces=ns)).split())
        if not any(text.startswith(f"Figure {n}:") for n in (1, 2, 3)):
            continue
        for blip in table.xpath(".//a:blip", namespaces=ns):
            rid = blip.get("{" + ns["r"] + "}embed")
            ext = blip.xpath(".//asvg:svgBlip", namespaces=ns)
            native = []
            for node in ext:
                svg_id = node.get("{" + ns["r"] + "}embed")
                member = posixpath.normpath("word/" + rels[svg_id])
                native.append({"relationship": svg_id, "member": member,
                               "sha256": hashlib.sha256(z.read(member)).hexdigest()})
            rows.append({"figure": text.split(":", 1)[0], "base_blip_embed": rid,
                         "base_relationship_resolves": rid in rels,
                         "native_svg": native, "blip_xml": etree.tostring(blip, encoding="unicode")})
print(json.dumps({"input": str(source), "input_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                  "main_figure_relationships": rows,
                  "frozen_embedding_precondition_pass": all(r["base_relationship_resolves"] for r in rows)
                  and len(rows) == 3}, indent=2))
