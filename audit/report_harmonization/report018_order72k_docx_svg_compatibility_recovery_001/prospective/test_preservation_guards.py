"""Additional in-memory guard tests; neither main entry point is loaded."""
import ast
import copy
import hashlib
import json
from pathlib import Path
from lxml import etree

TMP=Path(__file__).resolve().parent
path=TMP/"embed_accepted_svg_figures.proposed.py"
tree=ast.parse(path.read_text())
ctx={"__file__":str(path),"__name__":"isolated_guards"}
safe=[n for n in tree.body if isinstance(n,(ast.Import,ast.ImportFrom,ast.Assign)) or isinstance(n,ast.FunctionDef) and n.name!="main"]
exec(compile(ast.Module(body=safe,type_ignores=[]),str(path),"exec"),ctx)
assert "main" not in ctx
main=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=="main")
guard=next(n.value for n in main.body if isinstance(n,ast.Assign) and isinstance(n.targets[0],ast.Name) and n.targets[0].id=="checks")
guards={k.value:v for k,v in zip(guard.keys,guard.values)}
NS=ctx["NS"]; rows=[]
def check(name,ok):
    assert ok,name
    rows.append({"test":name,"pass":True})
def evaluate(name,**values):
    return eval(compile(ast.Expression(guards[name]),"guard-only","eval"),{**ctx,**values})

svg=b'<svg xmlns="http://www.w3.org/2000/svg"/>'
part="word/media/accepted.svg"
records=[{"embedded_part":part,"sha256":hashlib.sha256(svg).hexdigest()}]
check("accepted SVG payload exact",evaluate("accepted_svg_bytes_preserved",parts={part:svg},records=records))
check("accepted SVG byte edit rejected",not evaluate("accepted_svg_bytes_preserved",parts={part:svg+b" "},records=records))
original={"word/styles.xml":b"STYLE","word/other.xml":b"OTHER"}
check("no new raster parts positive",evaluate("no_new_raster_parts",original=original,parts={**original,part:svg}))
check("new raster member rejected",not evaluate("no_new_raster_parts",original=original,parts={**original,"word/media/new.png":b"PNG"}))
check("unrelated existing parts preserved",evaluate("all_other_existing_parts_unchanged",original=original,parts=dict(original),removed=[]))
check("unrelated existing part edit rejected",not evaluate("all_other_existing_parts_unchanged",original=original,parts={**original,"word/styles.xml":b"EDIT"},removed=[]))
check("authorized former-part deletion tolerated",evaluate("all_other_existing_parts_unchanged",original=original,parts={"word/styles.xml":b"STYLE"},removed=["word/other.xml"]))
before=etree.fromstring(b"<root><x/></root>")
check("document XML reversal exact",evaluate("document_xml_reverses_exactly",before_document=before,reversed_document=copy.deepcopy(before)))
after=copy.deepcopy(before);after[0].set("x","1")
check("document XML unrelated mutation rejected",not evaluate("document_xml_reverses_exactly",before_document=before,reversed_document=after))

before=etree.Element("doc",nsmap={"wp":NS["wp"],"a":NS["a"],"asvg":NS["asvg"],"r":NS["r"]})
draw=etree.SubElement(before,"{"+NS["wp"]+"}inline")
etree.SubElement(draw,"{"+NS["wp"]+"}extent",cx="100",cy="200")
blip=etree.SubElement(draw,"{"+NS["a"]+"}blip")
exts=etree.SubElement(blip,"{"+NS["a"]+"}extLst")
dpi=etree.SubElement(exts,"{"+NS["a"]+"}ext",uri=ctx["DPI_EXTENSION"])
etree.SubElement(dpi,"{"+ctx["A14"]+"}useLocalDpi",val="0")
ext=etree.SubElement(exts,"{"+NS["a"]+"}ext",uri=ctx["SVG_EXTENSION"])
node=etree.SubElement(ext,"{"+NS["asvg"]+"}svgBlip");node.set("{"+NS["r"]+"}embed","rS")
check("existing native drawing untouched",evaluate("existing_native_drawings_preserved",before_document=before,document=copy.deepcopy(before)))
for name,mutate in (
    ("native geometry change",lambda d:d[0][0].set("cx","99")),
    ("invented native base embed",lambda d:d[0][1].set("{"+NS["r"]+"}embed","rS")),
    ("native DPI sibling removal",lambda d:d[0][1][0].remove(d[0][1][0][0])),
    ("native relationship change",lambda d:d[0][1][0][1][0].set("{"+NS["r"]+"}embed","rOther"))):
    after=copy.deepcopy(before);mutate(after)
    check(name+" rejected",not evaluate("existing_native_drawings_preserved",before_document=before,document=after))

rels=etree.Element("{"+NS["pr"]+"}Relationships")
for rid in ("rB","rS"):
    etree.SubElement(rels,"{"+NS["pr"]+"}Relationship",Id=rid,Type=ctx["IMAGE_RELATIONSHIP"],Target="media/"+rid+".svg")
old=ctx["relationship_lookup"](rels)
check("both base and native relationships untouched",evaluate("existing_native_relationships_preserved",rel_lookup=ctx["relationship_lookup"](copy.deepcopy(rels)),original_lookup=old,preserved_native_relationship_ids={"rB","rS"}))
for rid in ("rB","rS"):
    for attr,val in (("Target","media/changed.svg"),("Type","changed"),("TargetMode","External")):
        current=ctx["relationship_lookup"](copy.deepcopy(rels));current[rid].set(attr,val)
        check(f"native group {rid} {attr} change rejected",not evaluate("existing_native_relationships_preserved",rel_lookup=current,original_lookup=old,preserved_native_relationship_ids={"rB","rS"}))

for payload in (b"<svg",b"<not_svg/>"):
    rels=etree.Element("{"+NS["pr"]+"}Relationships")
    etree.SubElement(rels,"{"+NS["pr"]+"}Relationship",Id="rS",Type=ctx["IMAGE_RELATIONSHIP"],Target="media/x.svg")
    try:ctx["image_target"]("rS",ctx["relationship_lookup"](rels),{"word/media/x.svg":payload},hashlib.sha256(payload).hexdigest())
    except (SystemExit,etree.XMLSyntaxError):pass
    else:raise AssertionError("Malformed or wrong-root SVG accepted")
    check("reject malformed/wrong-root payload "+repr(payload),True)

out=TMP/"preservation_guard_results.json"
assert not out.exists()
out.write_text(json.dumps({"status":"PASS","test_count":len(rows),"tests":rows,"full_entry_points_loaded":False,"package_saves":0},indent=2)+"\n")
print(json.dumps({"status":"PASS","isolated_guard_tests":len(rows),"package_saves":0}))
