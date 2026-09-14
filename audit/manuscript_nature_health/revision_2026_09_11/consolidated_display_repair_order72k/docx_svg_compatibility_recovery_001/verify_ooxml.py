"""Independent read-only package and exact XML reversal verification."""
import copy
import hashlib
import json
import posixpath
from pathlib import Path
from zipfile import ZipFile
from lxml import etree

REC = Path(__file__).resolve().parent
OWNER = REC.parent
NS = {
    "w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
    "wp": "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "asvg": "http://schemas.microsoft.com/office/drawing/2016/SVG/main",
    "pr": "http://schemas.openxmlformats.org/package/2006/relationships",
    "ct": "http://schemas.openxmlformats.org/package/2006/content-types",
}
SVG_URI = "{96DAC541-7B7A-43D3-8B79-37D633B846F1}"
result_path = REC / "ooxml_checks.json"
assert not result_path.exists()

def read_package(path):
    with ZipFile(path) as z:
        names = z.namelist()
        assert len(names) == len(set(names))
        return {name: z.read(name) for name in names}

def digest(blob):
    return hashlib.sha256(blob).hexdigest()

def drawings(document):
    found = document.xpath(".//wp:inline", namespaces=NS)
    return {node.find("wp:docPr", NS).get("id"): node for node in found}

before = read_package(OWNER / "manuscript_assembled_attempt1.docx")
after = read_package(OWNER / "Nature_Health_non_S5_preview_attempt1.docx")
old_doc = etree.fromstring(before["word/document.xml"])
new_doc = etree.fromstring(after["word/document.xml"])
old_draw = drawings(old_doc)
new_draw = drawings(new_doc)
checks = {}
checks["same_52_unique_drawing_IDs"] = len(old_draw) == len(new_draw) == 52 and old_draw.keys() == new_draw.keys()
assert checks["same_52_unique_drawing_IDs"]
reversed_doc = copy.deepcopy(new_doc)
reverse_draw = drawings(reversed_doc)
inserted_extensions = []
native_ids = []
old_rels = etree.fromstring(before["word/_rels/document.xml.rels"])
new_rels = etree.fromstring(after["word/_rels/document.xml.rels"])
old_rel_map = {r.get("Id"): r for r in old_rels}
new_rel_map = {r.get("Id"): r for r in new_rels}
expected_removed = set()
expected_added = set()
native_members = set()
retargets = {}
authority = json.loads((OWNER / "expanded_svg_manifest.json").read_text())["accepted_figures"]
accepted = {r["word_label"]: r for r in authority}

for ident, old_node in old_draw.items():
    new_node = new_draw[ident]
    label = old_node.find("wp:docPr", NS).get("descr")
    assert label == new_node.find("wp:docPr", NS).get("descr")
    old_svg = old_node.xpath(".//asvg:svgBlip", namespaces=NS)
    new_svg = new_node.xpath(".//asvg:svgBlip", namespaces=NS)
    if old_svg:
        assert len(old_svg) == len(new_svg) == 1
        assert etree.tostring(old_node) == etree.tostring(new_node)
        rid = old_svg[0].get("{" + NS["r"] + "}embed")
        native_ids.append(rid)
        assert etree.tostring(old_rel_map[rid]) == etree.tostring(new_rel_map[rid])
        native_members.add("word/" + old_rel_map[rid].get("Target"))
    elif new_svg:
        assert len(new_svg) == 1
        old_blip = old_node.xpath(".//a:blip", namespaces=NS)[0]
        new_blip = new_node.xpath(".//a:blip", namespaces=NS)[0]
        base_rid = old_blip.get("{" + NS["r"] + "}embed")
        assert new_blip.get("{" + NS["r"] + "}embed") == base_rid
        assert new_svg[0].get("{" + NS["r"] + "}embed") == base_rid
        choices = [r for key, r in accepted.items() if label == key or label.startswith(key + ",")]
        assert len(choices) == 1
        expected = choices[0]
        member = "word/media/nh_" + expected["word_label"].lower().replace(" ", "_") + ".svg"
        old_member = "word/" + old_rel_map[base_rid].get("Target")
        assert digest(before[old_member]) == digest(after[member]) == expected["sha256"]
        assert new_rel_map[base_rid].get("Target") == member.removeprefix("word/")
        assert base_rid not in retargets or retargets[base_rid] == member
        retargets[base_rid] = member
        expected_removed.add(old_member)
        expected_added.add(member)
        blip = reverse_draw[ident].xpath(".//a:blip", namespaces=NS)[0]
        exts = blip.find("a:extLst", NS)
        inserted = exts.xpath("./a:ext[@uri=$uri]", namespaces=NS, uri=SVG_URI)
        assert len(inserted) == 1
        exts.remove(inserted[0])
        if old_blip.find("a:extLst", NS) is None:
            assert len(exts) == 0
            blip.remove(exts)
        inserted_extensions.append(ident)
    else:
        assert etree.tostring(old_node) == etree.tostring(new_node)

checks["exact_whole_document_XML_reversal"] = etree.tostring(reversed_doc) == etree.tostring(old_doc)
checks["three_main_native_drawings_relationships_members_unchanged"] = set(native_ids) == {"rId21", "rId28", "rId35"} and native_members == {"word/media/rId21.svg", "word/media/rId28.svg", "word/media/rId35.svg"} and all(before[p] == after[p] for p in native_members)
checks["twenty_supplemental_appearances_nineteen_new_sources"] = len(inserted_extensions) == 20 and len(expected_added) == 19
checks["exactly_documented_SVG_member_additions_removals"] = set(after) - set(before) == expected_added and set(before) - set(after) == expected_removed
changes = {"word/document.xml", "word/_rels/document.xml.rels", "[Content_Types].xml"}
checks["every_unrelated_package_member_byte_identical"] = all(before[name] == after[name] for name in set(before) & set(after) - changes)
checks["no_added_raster_parts"] = all(p.endswith(".svg") for p in set(after) - set(before))
checks["relationship_ID_set_unchanged"] = old_rel_map.keys() == new_rel_map.keys()
for rid in old_rel_map:
    if rid in retargets:
        expected_node = copy.deepcopy(old_rel_map[rid])
        expected_node.set("Target", retargets[rid].removeprefix("word/"))
        assert etree.tostring(expected_node) == etree.tostring(new_rel_map[rid])
    else:
        assert etree.tostring(old_rel_map[rid]) == etree.tostring(new_rel_map[rid])
checks["only_nineteen_consistent_base_relationship_retargets"] = len(retargets) == 19

relationship_count = 0
for name, blob in after.items():
    if not name.endswith(".rels"):
        continue
    tree = etree.fromstring(blob)
    ids = [node.get("Id") for node in tree]
    assert len(ids) == len(set(ids)) and all(ids)
    base = "" if name == "_rels/.rels" else posixpath.dirname(posixpath.dirname(name))
    for relation in tree:
        relationship_count += 1
        if relation.get("TargetMode") == "External":
            continue
        target = relation.get("Target")
        member = target.lstrip("/") if target.startswith("/") else posixpath.normpath(posixpath.join(base, target))
        assert member in after and not member.startswith("../")
        if relation.get("Type", "").endswith("/image") and name == "word/_rels/document.xml.rels":
            assert target.startswith("media/") and posixpath.normpath(target) == target
            assert not any(c in target for c in "\\:%?#")
checks["all_internal_relationships_resolve_and_image_targets_canonical"] = True
for node in new_doc.iter():
    for attr in ("id", "embed", "link"):
        rid = node.get("{" + NS["r"] + "}" + attr)
        if rid is not None:
            assert rid in new_rel_map
checks["all_document_relationship_references_resolve"] = True
types = etree.fromstring(after["[Content_Types].xml"])
defaults = types.findall("ct:Default", NS)
overrides = types.findall("ct:Override", NS)
default_map = {n.get("Extension"): n.get("ContentType") for n in defaults}
override_map = {n.get("PartName"): n.get("ContentType") for n in overrides}
assert len(default_map) == len(defaults) and len(override_map) == len(overrides)
for name in after:
    if name == "[Content_Types].xml":
        continue
    typ = override_map.get("/" + name, default_map.get(name.rsplit(".", 1)[-1]))
    assert typ
    if name.endswith(".svg"):
        assert typ == "image/svg+xml"
checks["unique_resolving_content_types_all_SVG_types_valid"] = True
assert all(checks.values()), checks
result = {"status": "STRUCTURAL_PASS_VISUAL_QA_PENDING", "checks": checks,
          "input_sha256": digest((OWNER / "manuscript_assembled_attempt1.docx").read_bytes()),
          "output_sha256": digest((OWNER / "Nature_Health_non_S5_preview_attempt1.docx").read_bytes()),
          "accepted_native_members": sorted(native_members), "added_SVG_members": sorted(expected_added),
          "removed_former_SVG_members": sorted(expected_removed), "new_extension_drawing_ids": inserted_extensions,
          "package_relationships_checked": relationship_count, "office_browser_native_actions": 0}
result_path.write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({"checks": len(checks), "all_pass": all(checks.values()), "output_sha256": result["output_sha256"]}, indent=2))
