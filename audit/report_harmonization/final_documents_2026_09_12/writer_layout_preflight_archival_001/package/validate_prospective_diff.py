"""Static text/AST check only. Never import or execute prospective helpers."""
import ast
import difflib
import hashlib
import json
import subprocess
from pathlib import Path

root=Path("/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026")
out=Path("/private/tmp/nature-health-layout-preflight.yMAKmA")
base=root/"audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k"
sources={"prepare_word_manuscript.py":base/"helpers/prepare_word_manuscript.py",
         "capture_word_tables.mjs":base/"helpers/capture_word_tables.mjs",
         "export_editable_tables.py":root/"scripts/manuscript_nature_health/export_editable_tables.py",
         "order72k_layout.css":base/"project/order72k_layout.css"}
allowed={"prepare_word_manuscript.py":{"parse_args","add_picture_paragraph","add_cropped_picture_paragraph",
  "add_label_paragraph","section_break_paragraph","replace_main_table_float","replace_main_figure_float",
  "replace_native_table","insert_supplementary_figure","main"},
  "export_editable_tables.py":{"add_run","render_inline","export_one","main"}}
diffdir=out/"diffs"; diffdir.mkdir(exist_ok=True)
records=[]; combined=[]
for name,source in sources.items():
    old=source.read_text(); new=(out/"prospective"/name).read_text()
    assert "PROSPECTIVE ONLY" in new
    delta=list(difflib.ndiff(old.splitlines(keepends=True),new.splitlines(keepends=True)))
    assert "".join(difflib.restore(delta,1))==old
    assert "".join(difflib.restore(delta,2))==new
    diff="".join(difflib.unified_diff(old.splitlines(keepends=True),new.splitlines(keepends=True),
        fromfile=str(source.relative_to(root)),tofile="PROSPECTIVE_ONLY/"+name))
    (diffdir/(name+".diff")).write_text(diff); combined.append(diff)
    record={"file":name,"live_source":str(source),"live_sha256":hashlib.sha256(source.read_bytes()).hexdigest(),
        "prospective_sha256":hashlib.sha256((out/"prospective"/name).read_bytes()).hexdigest(),"round_trip_text_exact":True}
    if name.endswith(".py"):
        before,after=ast.parse(old),ast.parse(new)
        funcs=lambda tree:{n.name:ast.dump(n,include_attributes=False) for n in tree.body if isinstance(n,(ast.FunctionDef,ast.AsyncFunctionDef))}
        b,a=funcs(before),funcs(after)
        changed={key for key in b if a.get(key)!=b[key]}
        assert changed <= allowed[name],changed-allowed[name]
        record.update(changed_existing_functions=sorted(changed),new_functions=sorted(set(a)-set(b)),python_ast_parse=True)
        if name=="prepare_word_manuscript.py":
            for key in ("add_image_run","image_dimensions","resize_drawing_paragraph","add_author_block","add_missing_display_bookmarks"):
                if key in b: assert a[key]==b[key],key
        else:
            assigns=lambda tree:{n.targets[0].id:ast.dump(n.value,include_attributes=False) for n in tree.body
                                if isinstance(n,ast.Assign) and len(n.targets)==1 and isinstance(n.targets[0],ast.Name)}
            ob,oa=assigns(before),assigns(after)
            assert ob["LABELS"]==oa["LABELS"]
            bw=next(n.value for n in before.body if isinstance(n,ast.Assign) and isinstance(n.targets[0],ast.Name) and n.targets[0].id=="WIDTHS")
            aw=next(n.value for n in after.body if isinstance(n,ast.Assign) and isinstance(n.targets[0],ast.Name) and n.targets[0].id=="WIDTHS")
            width_nodes=lambda node:{ast.literal_eval(k):ast.dump(v,include_attributes=False) for k,v in zip(node.keys,node.values)}
            wb,wa=width_nodes(bw),width_nodes(aw)
            assert {k for k in wb if wb[k]!=wa[k]}=={"Table_S2"}
    if name.endswith(".mjs"):
        marker=lambda txt:txt.split("// BEGIN S2_SCREEN_READER_CONTRACT",1)[1].split("// END S2_SCREEN_READER_CONTRACT",1)[0]
        assert marker(old)==marker(new)
        command=["/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node","--check",str(out/"prospective"/name)]
        result=subprocess.run(command,capture_output=True,text=True,check=False)
        record.update(node_command=command,node_exit=result.returncode,node_stdout=result.stdout,node_stderr=result.stderr,
                      screen_reader_contract_exact=True)
        assert result.returncode==0,result.stderr
    if name.endswith(".css"):
        assert new.count("{")==new.count("}")
        record["balanced_css_rule_braces"]=True
    records.append(record)
(out/"prospective_changes.diff").write_text("".join(combined))
(out/"static_diff_checks.json").write_text(json.dumps(records,indent=2)+"\n")
print(json.dumps(records,indent=2))
