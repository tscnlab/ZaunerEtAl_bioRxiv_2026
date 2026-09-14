"""Read-only OOXML infrastructure preflight for the unchanged 20-byte repair."""
from pathlib import Path
from hashlib import sha256
from zipfile import ZipFile
from lxml import etree
import json

root = Path.cwd()
owner = root / "audit/manuscript_nature_health/final_pagination_completion_2026_09_14"
helper = owner / "code/patch_s9_break.py"
out = Path("/private/tmp/writer010c-bookmark.IjDfbw")
source = helper.read_bytes()
old = b"    assert target.getprevious() is preceding\n"
new = b'''    intervening = []
    sibling = target.getprevious()
    while sibling is not None and sibling is not preceding:
        intervening.append(sibling)
        sibling = sibling.getprevious()
    assert sibling is preceding
    assert len(intervening) == 1
    assert intervening[0].tag == "{" + W + "}bookmarkStart"
    assert dict(intervening[0].attrib) == {
        "{" + W + "}id": "338",
        "{" + W + "}name": "X7652973548e0e92457fc1c236fcb0c86891495d",
    }
    assert len(intervening[0]) == 0
'''
assert source.count(old) == 1
prospective = source.replace(old, new, 1)
assert prospective.count(new) == 1
assert prospective.replace(new, old, 1) == source
compile(prospective, str(helper), "exec")
assert not (owner / "deliverables/Nature_Health_manuscript.docx").exists()
assert not (owner / "evidence/patch_proof.json").exists()
assert not (owner / "evidence/render_execution.json").exists()
text = prospective.decode("utf-8")
boundary = '    with ZipFile(DEST, "x") as result:'
assert text.count(boundary) == 1
# Execute every corrected prewrite guard and exact XML reverse assertion. The
# complete ZIP-creation/evidence-write section is not executed.
prefix = text[:text.index(boundary)]
namespace = {"__file__": str(helper), "__name__": "independent_prewrite_check"}
exec(compile(prefix, str(helper), "exec"), namespace)
assert namespace["indices"] == [339]
assert namespace["text"](namespace["preceding"]) == "Hourly routine analyses"
assert len(namespace["intervening"]) == 1
original_bookmark = etree.tostring(namespace["intervening"][0])
post_doc = etree.fromstring(namespace["after"])
bookmarks = post_doc.xpath("./w:body/w:bookmarkStart[@w:id='338']", namespaces=namespace["NS"])
assert len(bookmarks) == 1 and etree.tostring(bookmarks[0]) == original_bookmark
assert source == helper.read_bytes()
assert not (owner / "deliverables/Nature_Health_manuscript.docx").exists()
report = {
    "status": "PASS", "domain": "non-analytical OOXML infrastructure",
    "helper_before_sha256": sha256(source).hexdigest(), "helper_before_bytes": len(source),
    "helper_after_sha256": sha256(prospective).hexdigest(), "helper_after_bytes": len(prospective),
    "helper_reverse_exact": True, "full_python_parse": True,
    "all_prewrite_guards_and_XML_reverse_executed": True,
    "preceding_paragraph_one_based": 339, "target_paragraph_one_based": 340,
    "intervening_nodes": [{"tag": "w:bookmarkStart", "id": "338", "name": "X7652973548e0e92457fc1c236fcb0c86891495d"}],
    "bookmark_unchanged_after_exact_XML_repair": True,
    "document_xml_before": sha256(namespace["before"]).hexdigest(),
    "document_xml_after": sha256(namespace["after"]).hexdigest(),
    "output_DOCX_absent": True, "patch_proof_absent": True, "renderer_unconsumed": True,
    "author_mutations": 0,
}
# Only fresh coordinator scratch evidence is written.
(out / "prewrite_check.json").write_text(json.dumps(report, indent=2) + "\n")
(out / "old_guard.txt").write_bytes(old)
(out / "new_guard.txt").write_bytes(new)
(out / "prospective_patch_s9_break.py").write_bytes(prospective)
print(json.dumps(report, indent=2))
