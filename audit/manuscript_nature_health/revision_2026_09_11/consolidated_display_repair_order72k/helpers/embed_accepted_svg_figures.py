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

ROOT = Path(__file__).resolve().parents[1]
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
DPI_EXTENSION = "{28A0092B-C50C-407E-A947-70E740481C1C}"
A14 = "http://schemas.microsoft.com/office/drawing/2010/main"
IMAGE_RELATIONSHIP = NS["r"] + "/image"


def digest(blob):
    return hashlib.sha256(blob).hexdigest()


def xml_bytes(root):
    return etree.tostring(root, encoding="UTF-8", xml_declaration=True, standalone=True)


def relationship_lookup(rels):
    result = {}
    for relation in rels:
        rid = relation.get("Id")
        if relation.tag != "{" + NS["pr"] + "}Relationship" or not rid or any(char.isspace() for char in rid) or rid in result:
            raise SystemExit("Malformed or duplicate package relationship")
        result[rid] = relation
    return result


def image_target(rid, lookup, original, expected_sha=None):
    if not rid or rid not in lookup:
        raise SystemExit("Missing or unresolved image relationship")
    relation = lookup[rid]
    target = relation.get("Target", "")
    if (relation.get("Type") != IMAGE_RELATIONSHIP or
            relation.get("TargetMode") not in (None, "Internal") or
            not target.startswith("media/") or posixpath.normpath(target) != target or
            any(char in target for char in "\\:%?#") or any(char.isspace() for char in target)):
        raise SystemExit("Unexpected image relationship type, mode or target")
    member = "word/" + target
    if member not in original:
        raise SystemExit("Image relationship has no package member")
    if expected_sha is not None:
        if not member.endswith(".svg") or digest(original[member]) != expected_sha:
            raise SystemExit("Original SVG relationship payload differs from accepted bytes")
        if etree.fromstring(original[member]).tag != "{http://www.w3.org/2000/svg}svg":
            raise SystemExit("Image relationship payload is not SVG")
    return member


def inspect_image_blip(blip, lookup, original, expected_sha):
    if any((node.text or "").strip() or (node.tail or "").strip() for node in blip.iter()):
        raise SystemExit("Unexpected text in image relationship structure")
    if set(blip.attrib) - {"{" + NS["r"] + "}embed"}:
        raise SystemExit("Unexpected image attributes or linked image")
    lists = blip.findall("a:extLst", NS)
    if len(lists) > 1 or len(blip) != len(lists):
        raise SystemExit("Unexpected image children or duplicate extension list")
    native_id, seen = None, set()
    if lists:
        if lists[0].attrib or not len(lists[0]):
            raise SystemExit("Malformed or empty image extension list")
        for ext in lists[0]:
            uri = ext.get("uri")
            if (ext.tag != "{" + NS["a"] + "}ext" or set(ext.attrib) != {"uri"} or
                    uri not in {SVG_EXTENSION, DPI_EXTENSION} or uri in seen or len(ext) != 1):
                raise SystemExit("Unexpected, duplicate or malformed image extension")
            seen.add(uri)
            node = ext[0]
            if uri == SVG_EXTENSION:
                if node.tag != "{" + NS["asvg"] + "}svgBlip" or set(node.attrib) != {"{" + NS["r"] + "}embed"} or len(node):
                    raise SystemExit("Malformed native SVG extension")
                native_id = node.get("{" + NS["r"] + "}embed")
                if not native_id:
                    raise SystemExit("Empty native SVG relationship")
            elif node.tag != "{" + A14 + "}useLocalDpi" or dict(node.attrib) != {"val": "0"} or len(node):
                raise SystemExit("Unexpected standard DPI extension")
    base_id = blip.get("{" + NS["r"] + "}embed")
    native_member = image_target(native_id, lookup, original, expected_sha) if native_id else None
    base_member = image_target(base_id, lookup, original) if base_id is not None else None
    if base_member and (not native_id or base_member.endswith(".svg")):
        image_target(base_id, lookup, original, expected_sha)
    if base_member and native_id and not base_member.endswith(".svg"):
        blob = original[base_member]
        if not ((base_member.endswith(".png") and blob.startswith(b"\x89PNG\r\n\x1a\n")) or
                (base_member.endswith((".jpg", ".jpeg")) and blob.startswith(b"\xff\xd8"))):
            raise SystemExit("Unexpected pre-existing native SVG fallback")
    if not base_id and not native_id:
        raise SystemExit("Image has neither base nor native SVG relationship")
    return {"base_id": base_id, "base_member": base_member,
            "native_id": native_id, "native_member": native_member}


def retarget_base_image(lookup, rid, member, former_parts, updated_ids):
    if rid in updated_ids:
        if updated_ids[rid] != member:
            raise SystemExit("Shared image relationship maps to conflicting sources")
        return
    relation = lookup[rid]
    former_parts.add("word/" + relation.get("Target"))
    relation.set("Target", member.removeprefix("word/"))
    updated_ids[rid] = member


def add_svg_extension(blip, rid):
    extension_list = blip.find("a:extLst", NS)
    had_list = extension_list is not None
    if not had_list:
        extension_list = etree.SubElement(blip, "{" + NS["a"] + "}extLst")
    if extension_list.xpath("./a:ext[@uri=$uri]", namespaces=NS, uri=SVG_EXTENSION):
        raise SystemExit("Do not replace an existing native SVG extension")
    extension = etree.SubElement(extension_list, "{" + NS["a"] + "}ext", uri=SVG_EXTENSION)
    svg_blip = etree.SubElement(extension, "{" + NS["asvg"] + "}svgBlip", nsmap={"asvg": NS["asvg"]})
    svg_blip.set("{" + NS["r"] + "}embed", rid)
    return had_list


def reverse_added_svg_extension(blip, had_list):
    extension_list = blip.find("a:extLst", NS)
    matches = extension_list.xpath("./a:ext[@uri=$uri]", namespaces=NS, uri=SVG_EXTENSION) if extension_list is not None else []
    if len(matches) != 1:
        raise SystemExit("Cannot reverse the exact inserted SVG extension")
    extension_list.remove(matches[0])
    if not had_list:
        if len(extension_list):
            raise SystemExit("New extension list contains unrelated content")
        blip.remove(extension_list)


def ensure_svg_content_type(types, members):
    defaults = types.xpath("./ct:Default[@Extension='svg']", namespaces=NS)
    if len(defaults) > 1 or any(node.get("ContentType") != "image/svg+xml" for node in defaults):
        raise SystemExit("Unexpected SVG default content type")
    for member in members:
        overrides = types.xpath("./ct:Override[@PartName=$name]", namespaces=NS, name="/" + member)
        if len(overrides) > 1 or any(node.get("ContentType") != "image/svg+xml" for node in overrides):
            raise SystemExit("Unexpected SVG override content type")
    if not defaults:
        etree.SubElement(types, "{" + NS["ct"] + "}Default", Extension="svg", ContentType="image/svg+xml")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input_docx", type=Path)
    parser.add_argument("accepted_manifest", type=Path)
    parser.add_argument("output_docx", type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()
    for output in (args.output_docx, args.report):
        if not output.resolve().is_relative_to(ROOT) or output.exists():
            raise SystemExit("Output must be a new candidate-only file")
    if args.input_docx.resolve() == args.output_docx.resolve():
        raise SystemExit("Write a distinct integration candidate; do not overwrite the input.")
    authority = json.loads(args.accepted_manifest.read_text())
    with ZipFile(args.input_docx) as archive:
        if len(archive.namelist()) != len(set(archive.namelist())):
            raise SystemExit("Duplicate package member")
        parts = {name: archive.read(name) for name in archive.namelist()}
    original = dict(parts)
    document = etree.fromstring(parts["word/document.xml"])
    before_document = deepcopy(document)
    rels = etree.fromstring(parts["word/_rels/document.xml.rels"])
    types = etree.fromstring(parts["[Content_Types].xml"])
    rel_lookup = relationship_lookup(rels)
    original_lookup = relationship_lookup(etree.fromstring(original["word/_rels/document.xml.rels"]))
    added, retained, former_parts, updated_ids, records = [], [], set(), {}, []
    new_extensions = {}
    preserved_native_relationship_ids = set()
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
        inspections = []
        for drawing in drawings:
            blips = drawing.xpath(".//a:blip", namespaces=NS)
            if len(blips) != 1:
                raise SystemExit(f"Expected one image relationship for {label}")
            inspections.append(inspect_image_blip(blips[0], original_lookup, original, record["sha256"]))
        native_members = {item["native_member"] for item in inspections}
        preserve_native = None not in native_members
        if preserve_native:
            if len(native_members) != 1:
                raise SystemExit(f"Conflicting native SVG members for {label}")
            member = native_members.pop()
            retained.append(member)
            preserved_native_relationship_ids.update(rid for item in inspections
                for rid in (item["base_id"], item["native_id"]) if rid is not None)
        else:
            if native_members != {None}:
                raise SystemExit(f"Mixed native and base-only drawings for {label}")
            member = "word/media/nh_" + label.lower().replace(" ", "_") + ".svg"
            if member in parts:
                raise SystemExit(f"Output member already exists: {member}")
            parts[member] = svg
            added.append(member)
        drawing_records = []
        for drawing, inspected in zip(drawings, inspections, strict=True):
            blips = drawing.xpath(".//a:blip", namespaces=NS)
            if len(blips) != 1:
                raise SystemExit(f"Expected one image relationship for {label}")
            blip = blips[0]
            relation_id = inspected["native_id"] if preserve_native else inspected["base_id"]
            if not preserve_native:
                retarget_base_image(rel_lookup, relation_id, member, former_parts, updated_ids)
                new_extensions[drawing.find("wp:docPr", NS).get("id")] = add_svg_extension(blip, relation_id)
            drawing_records.append({"description": drawing.find("wp:docPr", NS).get("descr"),
                                    "relationship": relation_id,
                                    "extent": dict(drawing.find("wp:extent", NS).attrib),
                                    "crop": [dict(node.attrib) for node in drawing.xpath(".//a:srcRect", namespaces=NS)]})
        records.append({**record, "embedded_part": member, "drawings": drawing_records, "existing_native_preserved": preserve_native})

    ensure_svg_content_type(types, added + retained)
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
    for drawing in reversed_document.xpath(".//wp:inline", namespaces=NS):
        if drawing.find("wp:docPr", NS).get("id") not in new_extensions:
            continue
        blip = drawing.xpath(".//a:blip", namespaces=NS)[0]
        reverse_added_svg_extension(blip, new_extensions[drawing.find("wp:docPr", NS).get("id")])
    checks = {
        "document_xml_reverses_exactly": etree.tostring(reversed_document) == etree.tostring(before_document),
        "accepted_svg_bytes_preserved": all(digest(parts[record["embedded_part"]]) == record["sha256"] for record in records),
        "all_other_existing_parts_unchanged": all(parts[name] == blob for name, blob in original.items()
            if name not in removed and name not in {"word/document.xml", "word/_rels/document.xml.rels", "[Content_Types].xml"}),
        "no_new_raster_parts": all(name.endswith(".svg") for name in set(parts) - set(original)),
        "svg_part_count_exact": len(added) + len(retained) == len(authority["accepted_figures"]) == 22
            and len(set(added + retained)) == 22
            and len([name for name in parts if name.startswith("word/media/") and name.endswith(".svg")]) == 22,
        "drawing_contract_exact": len(document.xpath(".//wp:inline", namespaces=NS)) == 52
            and sum(len(record["drawings"]) for record in records) == 23,
        "existing_native_drawings_preserved": all(etree.tostring(after) == etree.tostring(before)
            for before, after in zip(before_document.xpath(".//wp:inline", namespaces=NS), document.xpath(".//wp:inline", namespaces=NS), strict=True)
            if before.xpath(".//asvg:svgBlip", namespaces=NS)),
        "existing_native_relationships_preserved": all(etree.tostring(rel_lookup[rid]) == etree.tostring(original_lookup[rid])
            for rid in preserved_native_relationship_ids),
    }
    if not all(checks.values()):
        raise SystemExit(json.dumps(checks, indent=2))
    args.output_docx.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(args.output_docx, "w", ZIP_DEFLATED) as archive:
        for name, blob in parts.items():
            archive.writestr(name, blob)
    report = {
        "status": "Order72k non-S5 display-integration candidate, not promoted. Historical Brown S5 and Brown scientific replacement remain held.",
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
