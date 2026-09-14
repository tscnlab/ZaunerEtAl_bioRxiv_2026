"""TEMP-only OOXML fixture tests. Neither full helper entry point is loaded.

No DOCX is saved, rendered or assembled. Existing artifacts are read only.
Synthetic byte strings are test payloads, not scientific asset replacements.
"""
import ast
import copy
import csv
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile
from lxml import etree

TMP = Path(__file__).resolve().parent
ROOT = Path("/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026")
OWNER = ROOT / "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k"
PROPOSED = TMP / "embed_accepted_svg_figures.proposed.py"
tree = ast.parse(PROPOSED.read_text())
safe = [n for n in tree.body if isinstance(n, (ast.Import, ast.ImportFrom, ast.Assign))
        or isinstance(n, ast.FunctionDef) and n.name != "main"]
ctx = {"__file__": str(PROPOSED), "__name__": "isolated_fixture_only"}
exec(compile(ast.Module(body=safe, type_ignores=[]), str(PROPOSED), "exec"), ctx)
assert "main" not in ctx
NS = ctx["NS"]
SVG_URI, DPI_URI = ctx["SVG_EXTENSION"], ctx["DPI_EXTENSION"]
SVG = b'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"/>'
HASH = hashlib.sha256(SVG).hexdigest()
PNG = b"\x89PNG\r\n\x1a\nsynthetic-fixture-not-a-render"
checks = []

def passed(name, condition=True):
    assert condition, name
    checks.append({"test": name, "pass": True})

def fixture(base=False, native=False, dpi=False, raster=False):
    rels = etree.Element("{" + NS["pr"] + "}Relationships", nsmap={None:NS["pr"]})
    parts = {"word/media/base.svg": SVG, "word/media/native.svg": SVG,
             "word/media/base.png": PNG}
    for rid, target in (("rB", "media/base.png" if raster else "media/base.svg"), ("rS", "media/native.svg")):
        etree.SubElement(rels,"{"+NS["pr"]+"}Relationship",Id=rid,Type=ctx["IMAGE_RELATIONSHIP"],Target=target)
    blip = etree.Element("{"+NS["a"]+"}blip",nsmap={"a":NS["a"],"r":NS["r"],"asvg":NS["asvg"],"a14":ctx["A14"]})
    if base: blip.set("{"+NS["r"]+"}embed","rB")
    if dpi or native:
        lst = etree.SubElement(blip,"{"+NS["a"]+"}extLst")
        if dpi:
            ext = etree.SubElement(lst,"{"+NS["a"]+"}ext",uri=DPI_URI)
            etree.SubElement(ext,"{"+ctx["A14"]+"}useLocalDpi",val="0")
        if native:
            ext = etree.SubElement(lst,"{"+NS["a"]+"}ext",uri=SVG_URI)
            child = etree.SubElement(ext,"{"+NS["asvg"]+"}svgBlip")
            child.set("{"+NS["r"]+"}embed","rS")
    return blip, rels, parts

def inspect(f):
    blip, rels, parts = f
    return ctx["inspect_image_blip"](blip,ctx["relationship_lookup"](rels),parts,HASH)

def rejected(name, mutation, *, base=True, native=True, dpi=True, raster=False):
    f=fixture(base=base,native=native,dpi=dpi,raster=raster)
    mutation(*f)
    before=[etree.tostring(f[0]),etree.tostring(f[1]),dict(f[2])]
    try: inspect(f)
    except (SystemExit,etree.XMLSyntaxError): pass
    else: raise AssertionError("Unexpected acceptance: "+name)
    passed(name, before==[etree.tostring(f[0]),etree.tostring(f[1]),dict(f[2])])

for base,native,dpi,raster in [(True,False,False,False),(True,False,True,False),
                              (False,True,False,False),(False,True,True,False),
                              (True,True,False,False),(True,True,True,False),
                              (True,True,True,True)]:
    f=fixture(base,native,dpi,raster)
    before=(etree.tostring(f[0]),etree.tostring(f[1]),dict(f[2]))
    result=inspect(f)
    passed(f"accept base={base} native={native} dpi={dpi} raster={raster} without mutation",before==(etree.tostring(f[0]),etree.tostring(f[1]),dict(f[2])))
    passed(f"relationship selection {base}/{native}/{dpi}/{raster}",bool(result["base_id"])==base and bool(result["native_id"])==native)

f=fixture(True,True,True)
f[0].set("{"+NS["r"]+"}embed","rS")
passed("base and SVG may share one exact relationship",inspect(f)["base_member"]==inspect(f)["native_member"])
f=fixture(False,True,True)
f[0][0][:]=list(reversed(list(f[0][0])))
before=etree.tostring(f[0]); inspect(f)
passed("standard extension order preserved verbatim",before==etree.tostring(f[0]))

rejected("no image relationship",lambda b,r,p:None,base=False,native=False,dpi=False)
rejected("duplicate relationship ID",lambda b,r,p:r.append(copy.deepcopy(r[0])))
rejected("empty relationship ID",lambda b,r,p:r[0].set("Id",""))
rejected("whitespace relationship ID",lambda b,r,p:r[0].set("Id","r B"))
rejected("wrong relationship namespace",lambda b,r,p:setattr(r[0],"tag","Relationship"))
for index,label in ((0,"base"),(1,"native")):
    for mode in ("External","external","Unknown"):
        rejected(label+" target mode "+mode,lambda b,r,p,i=index,v=mode:r[i].set("TargetMode",v))
    rejected(label+" wrong relationship type",lambda b,r,p,i=index:r[i].set("Type",NS["r"]+"/hyperlink"))
    rejected(label+" missing relationship type",lambda b,r,p,i=index:r[i].attrib.pop("Type"))
    rejected(label+" unresolved ID",lambda b,r,p,i=index:r.remove(r[i]))
    for target in ("https://example.invalid/x.svg","../media/x.svg","/word/media/x.svg","media/../x.svg","media//x.svg","media/x.svg#fragment","media/x.svg?query","media/%2e%2e/x.svg","media\\x.svg","media/x y.svg",""):
        rejected(label+" invalid target "+repr(target),lambda b,r,p,i=index,t=target:r[i].set("Target",t))
rejected("missing native member",lambda b,r,p:p.pop("word/media/native.svg"))
rejected("missing base member",lambda b,r,p:p.pop("word/media/base.svg"))
rejected("native mismatched payload",lambda b,r,p:p.__setitem__("word/media/native.svg",SVG+b" "))
rejected("base SVG mismatched payload",lambda b,r,p:p.__setitem__("word/media/base.svg",SVG+b" "))
rejected("base-only mismatched payload",lambda b,r,p:p.__setitem__("word/media/base.svg",SVG+b" "),native=False,dpi=False)
rejected("base-only raster not silently promoted",lambda b,r,p:None,native=False,dpi=False,raster=True)
rejected("bad existing PNG fallback",lambda b,r,p:p.__setitem__("word/media/base.png",b"not PNG"),raster=True)
rejected("unrecognized existing fallback",lambda b,r,p:(r[0].set("Target","media/x.bin"),p.__setitem__("word/media/x.bin",PNG)))
rejected("linked blip",lambda b,r,p:b.set("{"+NS["r"]+"}link","rB"))
rejected("unexpected blip attribute",lambda b,r,p:b.set("unexpected","true"))
rejected("empty base ID",lambda b,r,p:b.set("{"+NS["r"]+"}embed",""))
rejected("unexpected text",lambda b,r,p:setattr(b,"text","unexpected"))
rejected("unexpected child",lambda b,r,p:etree.SubElement(b,"{"+NS["a"]+"}alphaModFix"))
rejected("duplicate extension list",lambda b,r,p:b.append(copy.deepcopy(b[0])))
rejected("empty extension list",lambda b,r,p:b[0].clear())
rejected("extension list attributes",lambda b,r,p:b[0].set("unexpected","true"))
rejected("unknown extension",lambda b,r,p:b[0][0].set("uri","{UNKNOWN}"))
rejected("duplicate SVG extension",lambda b,r,p:b[0].append(copy.deepcopy(b[0][1])))
rejected("duplicate DPI extension",lambda b,r,p:b[0].append(copy.deepcopy(b[0][0])))
rejected("malformed extension namespace",lambda b,r,p:setattr(b[0][1],"tag","ext"))
rejected("extension extra attribute",lambda b,r,p:b[0][1].set("unexpected","true"))
rejected("extension extra child",lambda b,r,p:b[0][1].append(copy.deepcopy(b[0][1][0])))
rejected("missing SVG child",lambda b,r,p:b[0][1].remove(b[0][1][0]))
rejected("wrong SVG child namespace",lambda b,r,p:setattr(b[0][1][0],"tag","svgBlip"))
rejected("empty native relationship",lambda b,r,p:b[0][1][0].set("{"+NS["r"]+"}embed",""))
rejected("native child nested content",lambda b,r,p:etree.SubElement(b[0][1][0],"x"))
rejected("native child unexpected attribute",lambda b,r,p:b[0][1][0].set("x","1"))
rejected("DPI wrong val",lambda b,r,p:b[0][0][0].set("val","1"))
rejected("DPI wrong namespace",lambda b,r,p:setattr(b[0][0][0],"tag","useLocalDpi"))
rejected("DPI extra attribute",lambda b,r,p:b[0][0][0].set("x","1"))
rejected("DPI nested content",lambda b,r,p:etree.SubElement(b[0][0][0],"x"))

# Exact insertion and reversal, including pre-existing DPI and S8-like crop siblings.
for dpi in (False,True):
    f=fixture(True,False,dpi)
    fill=etree.Element("{"+NS["a"]+"}blipFill"); fill.append(f[0])
    etree.SubElement(fill,"{"+NS["a"]+"}srcRect",t="42305",b="0")
    before=etree.tostring(fill)
    had_list=ctx["add_svg_extension"](f[0],"rB")
    passed("addition preserves crop and one native node, DPI="+str(dpi),len(f[0].xpath(".//asvg:svgBlip",namespaces=NS))==1 and fill[1].get("t")=="42305")
    ctx["reverse_added_svg_extension"](f[0],had_list)
    passed("exact whole-fill reversal, DPI="+str(dpi),before==etree.tostring(fill))
f=fixture(True,True,True)
before=etree.tostring(f[0])
try: ctx["add_svg_extension"](f[0],"rB")
except SystemExit: pass
else: raise AssertionError("Existing native extension overwritten")
passed("adding over native fails unchanged",before==etree.tostring(f[0]))

# Shared S8 source: one relationship retarget, two independent extension insertions.
f=fixture(True,False,False); original_rels=etree.tostring(f[1])
lookup=ctx["relationship_lookup"](f[1]); old=set(); changed={}
ctx["retarget_base_image"](lookup,"rB","word/media/new.svg",old,changed)
after=etree.tostring(f[1])
ctx["retarget_base_image"](lookup,"rB","word/media/new.svg",old,changed)
passed("shared-source retarget is idempotent",after==etree.tostring(f[1]) and old=={"word/media/base.svg"} and changed=={"rB":"word/media/new.svg"})
try: ctx["retarget_base_image"](lookup,"rB","word/media/conflict.svg",old,changed)
except SystemExit: pass
else: raise AssertionError("Conflicting shared source accepted")
passed("shared-source conflict rejected unchanged",after==etree.tostring(f[1]))

def ct_fixture():
    types=etree.Element("{"+NS["ct"]+"}Types",nsmap={None:NS["ct"]})
    etree.SubElement(types,"{"+NS["ct"]+"}Default",Extension="png",ContentType="image/png")
    return types
types=ct_fixture(); png_xml=etree.tostring(types[0]); ctx["ensure_svg_content_type"](types,["word/media/native.svg"])
after=etree.tostring(types); ctx["ensure_svg_content_type"](types,["word/media/native.svg"])
passed("SVG content type insertion is precise and idempotent",after==etree.tostring(types) and png_xml==etree.tostring(types[0]))
for variant in ("duplicate_default","wrong_default","duplicate_override","wrong_override"):
    types=ct_fixture()
    if "default" in variant:
        etree.SubElement(types,"{"+NS["ct"]+"}Default",Extension="svg",ContentType="image/png" if variant=="wrong_default" else "image/svg+xml")
        if variant=="duplicate_default":types.append(copy.deepcopy(types[-1]))
    else:
        etree.SubElement(types,"{"+NS["ct"]+"}Override",PartName="/word/media/native.svg",ContentType="image/png" if variant=="wrong_override" else "image/svg+xml")
        if variant=="duplicate_override":types.append(copy.deepcopy(types[-1]))
    before=etree.tostring(types)
    try:ctx["ensure_svg_content_type"](types,["word/media/native.svg"])
    except SystemExit:pass
    else:raise AssertionError(variant)
    passed("reject "+variant+" without mutation",before==etree.tostring(types))

# The orphan-removal block is extracted unchanged, not the helper entry point.
main=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=="main")
def cleanup_nodes(main):
    start=next(i for i,n in enumerate(main.body) if isinstance(n,ast.Assign) and isinstance(n.targets[0],ast.Name) and n.targets[0].id=="referenced")
    end=next(i for i,n in enumerate(main.body[start:],start) if isinstance(n,ast.Assign) and isinstance(n.targets[0],ast.Subscript))
    return main.body[start:end]
oldtree=ast.parse((TMP/"embed_accepted_svg_figures.preimage.py").read_text())
oldmain=next(n for n in oldtree.body if isinstance(n,ast.FunctionDef) and n.name=="main")
passed("orphan-removal block AST unchanged",ast.dump(ast.Module(body=cleanup_nodes(main),type_ignores=[]))==ast.dump(ast.Module(body=cleanup_nodes(oldmain),type_ignores=[])))
fn=ast.parse("def cleanup_for_fixture(parts, rels, types, former_parts):\n return []\n").body[0]
fn.body=copy.deepcopy(cleanup_nodes(main))+[ast.Return(value=ast.Name(id="removed",ctx=ast.Load()))]
exec(compile(ast.fix_missing_locations(ast.Module(body=[fn],type_ignores=[])),"isolated-cleanup","exec"),ctx)
f=fixture(True,False,False); rels=f[1]
rels[0].set("Target","media/new.svg")
types=ct_fixture()
etree.SubElement(types,"{"+NS["ct"]+"}Override",PartName="/word/media/base.svg",ContentType="image/svg+xml")
parts=dict(f[2]); parts.update({"word/media/new.svg":SVG,"word/styles.xml":b"UNRELATED", "word/_rels/document.xml.rels":etree.tostring(rels)})
removed=ctx["cleanup_for_fixture"](parts,rels,types,{"word/media/base.svg","word/media/native.svg"})
passed("orphan cleanup removes only unreferenced former member",removed==["word/media/base.svg"] and "word/media/native.svg" in parts and parts["word/styles.xml"]==b"UNRELATED" and not types.xpath("./ct:Override[@PartName='/word/media/base.svg']",namespaces=NS))

# Read three existing OOXML drawings only. There is no candidate package save.
docx=OWNER/"project/render_docx_attempt2/ZaunerEtAl2026_NatHealth_phase3_brown.docx"
docx_before=hashlib.sha256(docx.read_bytes()).hexdigest()
with ZipFile(docx) as archive:
    original={name:archive.read(name) for name in archive.namelist()}
doc=etree.fromstring(original["word/document.xml"])
rels=etree.fromstring(original["word/_rels/document.xml.rels"])
before_doc,before_rels=etree.tostring(doc),etree.tostring(rels)
lookup=ctx["relationship_lookup"](rels)
manifest=json.loads((OWNER/"expanded_svg_manifest.json").read_text())
actual=[]
for index,draw in enumerate(doc.xpath(".//wp:inline",namespaces=NS)[:3],1):
    record=next(r for r in manifest["accepted_figures"] if r["word_label"]==f"Main Figure {index}")
    item=ctx["inspect_image_blip"](draw.xpath(".//a:blip",namespaces=NS)[0],lookup,original,record["sha256"])
    passed("actual main SVG "+str(index)+" native-only validated",item["base_id"] is None and item["native_id"]==("rId21","rId28","rId35")[index-1])
    actual.append({"label":record["word_label"],**item,"sha256":record["sha256"]})
passed("actual document and relationships entirely unchanged",before_doc==etree.tostring(doc) and before_rels==etree.tostring(rels) and hashlib.sha256(docx.read_bytes()).hexdigest()==docx_before)

# Evaluate the exact final guard expressions in tiny in-memory fixtures.
guard=next(n.value for n in main.body if isinstance(n,ast.Assign) and isinstance(n.targets[0],ast.Name) and n.targets[0].id=="checks")
guards={key.value:value for key,value in zip(guard.keys,guard.values)}
def eval_guard(name,values):
    return eval(compile(ast.Expression(guards[name]),"isolated-final-guard","eval"),{**ctx,**values})
for count in (51,52,53):
    doc=etree.Element("doc",nsmap={"wp":NS["wp"]})
    for _ in range(count):etree.SubElement(doc,"{"+NS["wp"]+"}inline")
    for appearances in (22,23,24):
        result=eval_guard("drawing_contract_exact",{"document":doc,"records":[{"drawings":[{}]*appearances}]})
        passed(f"final52/23 drawing gate {count}/{appearances}",result==(count==52 and appearances==23))
for count in (21,22,23):
    members=[f"word/media/f{i}.svg" for i in range(count)]
    result=eval_guard("svg_part_count_exact",{"added":members[3:],"retained":members[:3],"parts":dict.fromkeys(members,SVG),"authority":{"accepted_figures":[{}]*22}})
    passed("physical22SVG gate "+str(count),result==(count==22))

out=TMP/"isolated_test_results.json"
assert not out.exists()
out.write_text(json.dumps({"status":"PASS","tests":checks,"test_count":len(checks),"actual_main_svg_inspections":actual,"full_entry_points_loaded":False,"full_entry_points_invoked":False,"package_saves":0,"render_or_browser_or_office_calls":0,"scientific_computation":False},indent=2)+"\n")
with (TMP/"isolated_test_results.csv").open("x",newline="") as stream:
    writer=csv.DictWriter(stream,fieldnames=["test","pass"]); writer.writeheader();writer.writerows(checks)
print(json.dumps({"status":"PASS","isolated_tests":len(checks),"package_saves":0,"full_entry_points_invoked":False}))
