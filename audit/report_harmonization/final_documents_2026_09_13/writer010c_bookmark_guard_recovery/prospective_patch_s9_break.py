"""Order010c: delete exactly one authorized direct page break, once."""
from pathlib import Path
from hashlib import sha256
from zipfile import ZipFile
from lxml import etree
import csv
import json
import re
import time

OUT = Path(__file__).resolve().parents[1]
ROOT = OUT.parents[2]
PRIOR = ROOT / "audit/manuscript_nature_health/final_format_completion_2026_09_14"
SOURCE = PRIOR / "deliverables/Nature_Health_manuscript_round2.docx"
DEST = OUT / "deliverables/Nature_Health_manuscript.docx"
W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
NS = {"w": W}
TARGET = "Supplementary Figure S9. Paired sensor-position hourly associations"
sha = lambda data: sha256(data).hexdigest()

assert not DEST.exists(), "Single patch output already exists; no retry authorized"
assert sha(SOURCE.read_bytes()) == "d6dd418054fb8287efe2a4d49fc2d4adaf5a4a56b8a6ded503645ca34c599701"
assert json.loads((OUT / "evidence/preflight.json").read_text())["prior_exact"] == 271
start = time.time()
with ZipFile(SOURCE) as original:
    infos = original.infolist()
    assert len({i.filename for i in infos}) == len(infos)
    before = original.read("word/document.xml")
    assert len(before) == 358303
    assert sha(before) == "cb767c3e378f5b08cb7251fbe5f3a306bfe73ac0d10ec3e3b67bafc0fdd6e393"
    doc = etree.fromstring(before)
    paragraphs = doc.xpath("./w:body/w:p", namespaces=NS)
    text = lambda p: "".join(p.xpath(".//w:t/text()", namespaces=NS))
    indices = [i for i, p in enumerate(paragraphs) if text(p) == TARGET]
    assert len(indices) == 1
    target = paragraphs[indices[0]]
    preceding = paragraphs[indices[0] - 1]
    intervening = []
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
    assert text(preceding) == "Hourly routine analyses"
    assert len(preceding.xpath("./w:pPr/w:pageBreakBefore", namespaces=NS)) == 1
    breaks = target.xpath("./w:pPr/w:pageBreakBefore", namespaces=NS)
    assert len(breaks) == 1 and not breaks[0].attrib and len(breaks[0]) == 0

    # Select by the independently fixed raw paragraph identity. Do not serialize
    # the XML tree, which would risk changing unrelated whitespace/namespaces.
    matches = [m for m in re.finditer(rb"<w:p(?:\s[^>]*)?>.*?</w:p>", before, re.S)
               if sha(m.group()) == "836b1402a77c1d81fbd0fbdd06992a3f05398a12fc6ab9d110f67035bb295ec8"]
    assert len(matches) == 1
    match = matches[0]
    old_paragraph = match.group()
    assert len(old_paragraph) == 272 and old_paragraph.count(b"<w:pageBreakBefore/>") == 1
    new_paragraph = old_paragraph.replace(b"<w:pageBreakBefore/>", b"", 1)
    assert len(new_paragraph) == 252
    assert sha(new_paragraph) == "046cac3f3089d05dd76487e1e415e5f088d9ea88aa6df856ca3392ea8492c311"
    after = before[:match.start()] + new_paragraph + before[match.end():]
    assert len(after) == 358283
    assert sha(after) == "98e2924ccc67952165ada5b01d1904b40eacea517908480b47faf0a0e58ffb7f"
    assert after.count(new_paragraph) == 1
    assert after.replace(new_paragraph, old_paragraph, 1) == before
    etree.fromstring(after)

    with ZipFile(DEST, "x") as result:
        result.comment = original.comment
        for info in infos:
            payload = after if info.filename == "word/document.xml" else original.read(info.filename)
            result.writestr(info, payload)

with ZipFile(SOURCE) as original, ZipFile(DEST) as result:
    assert original.namelist() == result.namelist()
    assert original.comment == result.comment
    rows = []
    for name in original.namelist():
        old = original.read(name)
        new = result.read(name)
        rows.append({"member": name, "before_bytes": len(old), "after_bytes": len(new),
                     "before_sha256": sha(old), "after_sha256": sha(new), "unchanged": old == new})
    assert [r["member"] for r in rows if not r["unchanged"]] == ["word/document.xml"]
    assert result.read("word/document.xml").replace(new_paragraph, old_paragraph, 1) == original.read("word/document.xml")

with (OUT / "evidence/member_delta.csv").open("x", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
    writer.writeheader()
    writer.writerows(rows)
for name, data in (("selected_paragraph_before.xml", old_paragraph), ("selected_paragraph_after.xml", new_paragraph)):
    with (OUT / "evidence" / name).open("xb") as handle:
        handle.write(data)
proof = {"order": "010c", "patch_count": 1, "source": str(SOURCE), "output": str(DEST),
         "source_sha256": sha(SOURCE.read_bytes()), "output_sha256": sha(DEST.read_bytes()),
         "document_xml_before": sha(before), "document_xml_after": sha(after),
         "selected_paragraph_before": sha(old_paragraph), "selected_paragraph_after": sha(new_paragraph),
         "exact_reverse": True, "all_other_member_bytes_exact": True, "member_count": len(rows),
         "zip_member_names_and_order_exact": True, "zip_comment_exact": True,
         "removed_bytes": 20, "prose_changes": 0, "started": start, "ended": time.time()}
with (OUT / "evidence/patch_proof.json").open("x") as handle:
    json.dump(proof, handle, indent=2)
print(json.dumps(proof, indent=2))
