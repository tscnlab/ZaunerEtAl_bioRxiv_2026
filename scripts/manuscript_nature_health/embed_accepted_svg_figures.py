#!/usr/bin/env python3
"""Embed byte-exact accepted SVG sources in a separate Word integration candidate.

No scientific computation, SVG rewriting, manual rasterization, or production edits.
The explicit accepted-image manifest, not filename similarity, controls substitutions.
"""

import argparse
import hashlib
import json
import posixpath
from copy import deepcopy
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

from lxml import etree

ROOT = Path(__file__).resolve().parents[2]
NS = {
    "w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
    "wp": "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "asvg": "http://schemas.microsoft.com/office/drawing/2016/SVG/main",
    "pr": "http://schemas.openxmlformats.org/package/2006/relationships",
    "ct": "http://schemas.openxmlformats.org/package/2006/content-types",
}
SVG_EXTENSION = "{96DAC541-7B7A-43D3-8B79-37D633B846F1}"


def digest(blob):
    return hashlib.sha256(blob).hexdigest()


def xml_bytes(root):
    return etree.tostring(root, encoding="UTF-8", xml_declaration=True, standalone=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input_docx", type=Path)
    parser.add_argument("accepted_manifest", type=Path)
    parser.add_argument("output_docx", type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()
    if args.input_docx.resolve() == args.output_docx.resolve():
        raise SystemExit("Write a distinct integration candidate; do not overwrite the input.")
    authority = json.loads(args.accepted_manifest.read_text())
    with ZipFile(args.input_docx) as archive:
        parts = {name: archive.read(name) for name in archive.namelist()}
    original = dict(parts)
    document = etree.fromstring(parts["word/document.xml"])
    before_document = deepcopy(document)
    rels = etree.fromstring(parts["word/_rels/document.xml.rels"])
    types = etree.fromstring(parts["[Content_Types].xml"])
    rel_lookup = {element.get("Id"): element for element in rels}
    added, former_parts, updated_ids, records = [], set(), set(), []
    for record in authority["accepted_figures"]:
        source = ROOT / record["path"]
        svg = source.read_bytes()
        if digest(svg) != record["sha256"]:
            raise SystemExit(f"Accepted SVG hash mismatch: {source}")
        svg_root = etree.fromstring(svg)
        if svg_root.tag != "{http://www.w3.org/2000/svg}svg":
            raise SystemExit(f"Not an SVG: {source}")
        label = record["word_label"]
        drawings = [drawing for drawing in document.xpath(".//wp:inline", namespaces=NS)
                    if drawing.find("wp:docPr", NS).get("descr", "") == label or
                    drawing.find("wp:docPr", NS).get("descr", "").startswith(label + ",")]
        if len(drawings) != record["appearances"]:
            raise SystemExit(f"Unexpected drawing count for {label}: {len(drawings)}")
        member = "word/media/nh_" + label.lower().replace(" ", "_") + ".svg"
        if member in parts:
            raise SystemExit(f"Output member already exists: {member}")
        parts[member] = svg
        added.append(member)
        drawing_records = []
        for drawing in drawings:
            blips = drawing.xpath(".//a:blip", namespaces=NS)
            if len(blips) != 1:
                raise SystemExit(f"Expected one image relationship for {label}")
            blip = blips[0]
            relation_id = blip.get("{" + NS["r"] + "}embed")
            relation = rel_lookup[relation_id]
            if relation_id not in updated_ids:
                former_parts.add(posixpath.normpath("word/" + relation.get("Target")))
                relation.set("Target", member.removeprefix("word/"))
                updated_ids.add(relation_id)
            if blip.find("a:extLst", NS) is not None:
                raise SystemExit(f"Unexpected pre-existing image extension for {label}")
            extension_list = etree.SubElement(blip, "{" + NS["a"] + "}extLst")
            extension = etree.SubElement(extension_list, "{" + NS["a"] + "}ext", uri=SVG_EXTENSION)
            svg_blip = etree.SubElement(extension, "{" + NS["asvg"] + "}svgBlip", nsmap={"asvg": NS["asvg"]})
            svg_blip.set("{" + NS["r"] + "}embed", relation_id)
            drawing_records.append({"description": drawing.find("wp:docPr", NS).get("descr"),
                                    "relationship": relation_id,
                                    "extent": dict(drawing.find("wp:extent", NS).attrib),
                                    "crop": [dict(node.attrib) for node in drawing.xpath(".//a:srcRect", namespaces=NS)]})
        records.append({**record, "embedded_part": member, "drawings": drawing_records})

    if not types.xpath("./ct:Default[@Extension='svg']", namespaces=NS):
        etree.SubElement(types, "{" + NS["ct"] + "}Default", Extension="svg", ContentType="image/svg+xml")
    # Remove only the old image members that no package relationship still uses.
    referenced = set()
    for name, blob in parts.items():
        if not name.endswith(".rels"):
            continue
        root = rels if name == "word/_rels/document.xml.rels" else etree.fromstring(blob)
        base = posixpath.dirname(name).replace("/_rels", "")
        if base == "_rels":
            base = ""
        for relation in root:
            if relation.get("TargetMode") != "External":
                referenced.add(posixpath.normpath(posixpath.join(base, relation.get("Target"))))
    removed = []
    for member in sorted(former_parts - referenced):
        del parts[member]
        removed.append(member)
        for override in types.xpath("./ct:Override[@PartName=$name]", namespaces=NS, name="/" + member):
            types.remove(override)
    parts["word/document.xml"] = xml_bytes(document)
    parts["word/_rels/document.xml.rels"] = xml_bytes(rels)
    parts["[Content_Types].xml"] = xml_bytes(types)

    # Exact reversal proves that only SVG extension nodes were added to document XML.
    reversed_document = deepcopy(document)
    for blip in reversed_document.xpath(".//a:blip", namespaces=NS):
        extension_list = blip.find("a:extLst", NS)
        if extension_list is not None and extension_list.xpath("./a:ext[@uri=$uri]", namespaces=NS, uri=SVG_EXTENSION):
            blip.remove(extension_list)
    checks = {
        "document_xml_reverses_exactly": etree.tostring(reversed_document) == etree.tostring(before_document),
        "accepted_svg_bytes_preserved": all(digest(parts[record["embedded_part"]]) == record["sha256"] for record in records),
        "all_other_existing_parts_unchanged": all(parts[name] == blob for name, blob in original.items()
            if name not in removed and name not in {"word/document.xml", "word/_rels/document.xml.rels", "[Content_Types].xml"}),
        "no_new_raster_parts": all(name.endswith(".svg") for name in set(parts) - set(original)),
        "svg_part_count_exact": len(added) == len(authority["accepted_figures"]),
    }
    if not all(checks.values()):
        raise SystemExit(json.dumps(checks, indent=2))
    args.output_docx.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(args.output_docx, "w", ZIP_DEFLATED) as archive:
        for name, blob in parts.items():
            archive.writestr(name, blob)
    report = {
        "status": "Partial vector integration candidate; not released. Seven figure exports and Brown replacement remain held.",
        "input": str(args.input_docx.resolve()), "input_sha256": digest(args.input_docx.read_bytes()),
        "output": str(args.output_docx.resolve()), "output_sha256": digest(args.output_docx.read_bytes()),
        "checks": checks, "embedded_svgs": records, "removed_unreferenced_raster_parts": removed,
        "held_figures": authority["held_figures"],
        "renderer_qualification": "Direct SVG OOXML integration requires visual QA; native Microsoft Word compatibility is not inferred from XML validity.",
    }
    args.report.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"embedded_svgs": len(records), "drawing_appearances": sum(len(record["drawings"]) for record in records),
                      "checks": checks, "output_sha256": report["output_sha256"]}, indent=2))


if __name__ == "__main__":
    main()
