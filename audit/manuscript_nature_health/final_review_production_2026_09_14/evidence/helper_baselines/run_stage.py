"""Bounded serial candidate operations with explicit, non-overwriting logs."""
import argparse
import ast
import csv
import difflib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

OUT = Path(__file__).resolve().parents[1]
ROOT = OUT.parents[3]
SEL = ROOT / "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k"
PYTHON = "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
NODE = "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node"
QMD = "ZaunerEtAl2026_NatHealth_phase3_brown.qmd"
DOCDIR = "/Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents"
H = OUT / "helpers"

def stages(attempt):
    return {
      "selection_html": {"cwd":str(SEL/"project"),"args":["quarto","render","selection.qmd","--to","html","--no-execute","--output-dir",f"render_attempt{attempt}"]},
      "main_html": {"cwd":str(OUT/"project"),"args":["quarto","render",QMD,"--to","html","--no-execute","--output-dir",f"render_html_attempt{attempt}"]},
      "main_docx": {"cwd":str(OUT/"project"),"args":["quarto","render",QMD,"--to","docx","--no-execute","--output-dir",f"render_docx_attempt{attempt}"]},
      "capture": {"cwd":str(ROOT),"args":[NODE,str(H/"capture_word_tables.mjs"),"REPLACE_WITH_APPROVED_CANDIDATE_URL",str(OUT/f"capture_attempt{attempt}")]},
      "assembly": {"cwd":str(ROOT),"args":[PYTHON,str(H/"prepare_word_manuscript.py"),str(OUT/f"project/render_docx_attempt{attempt}"/QMD.replace(".qmd",".docx")),str(OUT/"word_table_manifest_sealed.json"),str(OUT/"word_figure_svg_manifest.json"),str(OUT/f"manuscript_assembled_attempt{attempt}.docx")]},
      "embedding": {"cwd":str(ROOT),"args":[PYTHON,str(H/"embed_accepted_svg_figures.py"),str(OUT/f"manuscript_assembled_attempt{attempt}.docx"),str(OUT/"expanded_svg_manifest.json"),str(OUT/f"Nature_Health_non_S5_preview_attempt{attempt}.docx"),"--report",str(OUT/f"svg_embedding_attempt{attempt}.json")]},
      "office_qa": {"cwd":str(OUT),"args":[PYTHON,f"{DOCDIR}/render_docx.py",str(OUT/f"Nature_Health_non_S5_preview_attempt{attempt}.docx"),"--output_dir",str(OUT/f"office_qa_attempt{attempt}"),"--emit_pdf"]}
    }

def preflight():
    for p in H.glob("*.py"): ast.parse(p.read_text())
    subprocess.run([NODE,"--check",str(H/"capture_word_tables.mjs")],check=True)
    results = list(csv.DictReader((OUT/"source_preservation_checks.csv").open()))
    if any(x["pass"] != "TRUE" for x in results): raise RuntimeError("Source preflight failed")
    for name in ("capture_word_tables.mjs","prepare_word_manuscript.py","embed_accepted_svg_figures.py"):
        original = ROOT / "scripts/manuscript_nature_health" / name
        new = H/name
        (OUT/f"helper_{name}.diff").write_text(''.join(difflib.unified_diff(original.read_text().splitlines(True),new.read_text().splitlines(True),fromfile=str(original),tofile=str(new))))
    originals = [(ROOT/"manuscript/R0_NatHealth"/QMD,OUT/"project"/QMD,"main"),
                 (ROOT/"manuscript/R0_NatHealth/supplementary_information_outline.qmd",OUT/"project/supplementary_information_outline.qmd","supplement"),
                 (ROOT/"audit/manuscript_nature_health/manuscript_figure_table_selection.qmd",SEL/"project/selection.qmd","selection")]
    for old,new,key in originals:
        (OUT/f"{key}_source.diff").write_text(''.join(difflib.unified_diff(old.read_text().splitlines(True),new.read_text().splitlines(True),fromfile=str(old),tofile=str(new))))
    tmp = Path(tempfile.mkdtemp(prefix="order72k_",dir="/private/tmp"))
    configuration = {"scratch":str(tmp),"cache":str(tmp/"quarto_cache"),"output_roots":[str(SEL),str(OUT)]}
    (OUT/"runtime_paths.json").write_text(json.dumps(configuration,indent=2)+"\n")
    tables = json.loads((OUT/"frozen_table_manifest_rebased.json").read_text())
    drawing_map=[]
    for row in json.loads((OUT/"expanded_svg_manifest.json").read_text())["accepted_figures"]:
        for part in range(1,row["appearances"]+1): drawing_map.append({"kind":"SVG","label":row["word_label"],"appearance":part,"path":row["path"],"sha256":row["sha256"]})
    for table in tables:
        parts = 3 if table["key"] == "supp_table_s2" else len(table["files"])
        for part in range(1,parts+1): drawing_map.append({"kind":"table_capture","label":table["key"],"part":part,"candidate_capture":table["key"] in {"supp_table_s2","supp_table_s5","supp_table_s6","supp_table_s10"}})
    assert len(drawing_map)==52
    payload={"status":"pre-generation dry run; no analytical execution", "commands":stages(1),"second_pass_limit":stages(2),"drawing_map":drawing_map,
      "table_capture_plan":{"S2":{"rows":[[0,9],[9,17],[17,23]],"columns":list(range(14)),"width_css":1400,"max_trials":3},"S5":{"rows":[[0,9]],"width_css":902},"S6":{"rows":[[0,9]],"width_css":902},"S10":{"rows":[[0,4],[4,7]],"width_css":904}},
      "preservation_checks":str(OUT/"source_preservation_checks.csv"),"resource_map":str(OUT/"source_copy_map.json"),"runtime":configuration,
      "known_holds":["Brown scientific update and historical Figure S5", "Canonical promotion", "Native Word and integrated visual acceptance pending"]}
    (OUT/"dry_run_manifest.json").write_text(json.dumps(payload,indent=2)+"\n")
    print("Preflight recorded. 52 planned drawings, no render/capture yet.")

def execute(stage,attempt,url):
    if not (OUT/"dry_run_manifest.json").exists(): raise RuntimeError("Missing dry-run manifest")
    if not 1<=attempt<=2: raise RuntimeError("Trial allowance exceeded")
    plan=stages(attempt)[stage]
    if stage=="capture":
        if not url or not url.startswith("http://127.0.0.1:"): raise RuntimeError("Use approved candidate server URL")
        plan["args"][2]=url
    log=OUT/f"{stage}_attempt{attempt}.log"
    record=OUT/f"{stage}_attempt{attempt}_command.json"
    if log.exists() or record.exists(): raise RuntimeError("This attempt was already used")
    runtime=json.loads((OUT/"runtime_paths.json").read_text())
    env=dict(os.environ)
    env["RENV_CONFIG_AUTOLOADER_ENABLED"]="FALSE"
    env["QUARTO_CACHE_DIR"]=runtime["cache"]
    env["TMPDIR"]=runtime["scratch"]
    env["PATH"]="/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/override:"+str(Path(PYTHON).parent)+":"+env["PATH"]
    event={**plan,"stage":stage,"attempt":attempt,"started":time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime()),"environment":{"RENV_CONFIG_AUTOLOADER_ENABLED":"FALSE","QUARTO_CACHE_DIR":runtime["cache"],"TMPDIR":runtime["scratch"]},"status":"running"}
    record.write_text(json.dumps(event,indent=2)+"\n")
    with log.open("xb") as stream:
        result=subprocess.run(plan["args"],cwd=plan["cwd"],env=env,stdout=stream,stderr=subprocess.STDOUT)
    event.update({"exit_code":result.returncode,"status":"completed" if result.returncode==0 else "failed","ended":time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime())})
    record.write_text(json.dumps(event,indent=2)+"\n")
    print(json.dumps(event))
    sys.exit(result.returncode)

if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("stage",choices=["preflight",*stages(1)]);parser.add_argument("--attempt",type=int,default=1);parser.add_argument("--url")
    args=parser.parse_args()
    if args.stage=="preflight": preflight()
    else: execute(args.stage,args.attempt,args.url)
