"""Generate only TEMP evidence, diffs and a zero-fuzz reverse check. No document build."""
import difflib
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

TMP = Path(__file__).resolve().parent
ROOT = Path("/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026")
OWNER = ROOT / "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k"
PYTHON = "/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
pre=TMP/"embed_accepted_svg_figures.preimage.py"
post=TMP/"embed_accepted_svg_figures.proposed.py"
live=OWNER/"helpers/embed_accepted_svg_figures.py"
assert digest(pre)==digest(live)
diff=TMP/"forward.diff"
assert not diff.exists()
diff.write_text("".join(difflib.unified_diff(pre.read_text().splitlines(True),post.read_text().splitlines(True),fromfile="a/embed_accepted_svg_figures.py",tofile="b/embed_accepted_svg_figures.py")))
(TMP/"reverse.diff").write_text("".join(difflib.unified_diff(post.read_text().splitlines(True),pre.read_text().splitlines(True),fromfile="a/embed_accepted_svg_figures.py",tofile="b/embed_accepted_svg_figures.py")))
reverse=TMP/"zero_fuzz_reverse"
reverse.mkdir()
copy=reverse/"embed_accepted_svg_figures.py"
shutil.copyfile(post,copy)
command=["/usr/bin/patch","--batch","--fuzz=0","--reverse","-p1","--directory",str(reverse),"--input",str(diff)]
result=subprocess.run(command,capture_output=True,text=True)
assert result.returncode==0 and digest(copy)==digest(pre)
assert "offset" not in (result.stdout+result.stderr).lower() and "fuzz" not in (result.stdout+result.stderr).lower()
receipt={"command":command,"exit_code":result.returncode,"stdout":result.stdout,"stderr":result.stderr,"exact_reversal":True,"pre_sha256":digest(pre),"post_sha256":digest(post),"live_source_unchanged":digest(live)==digest(pre),"reverse_sha256":digest(copy)}
(TMP/"zero_fuzz_reverse_receipt.json").write_text(json.dumps(receipt,indent=2)+"\n")
outputs=[OWNER/"manuscript_assembled_attempt1.docx",OWNER/"Nature_Health_non_S5_preview_attempt1.docx",OWNER/"svg_embedding_attempt1.json"]
assert not any(p.exists() for p in outputs)
inputs=[live,OWNER/"helpers/prepare_word_manuscript.py",OWNER/"project/render_docx_attempt2/ZaunerEtAl2026_NatHealth_phase3_brown.docx",OWNER/"s2_accessibility_guard_recovery_001/word_table_manifest_attempt5.json",OWNER/"word_figure_svg_manifest.json",OWNER/"expanded_svg_manifest.json"]
commands={"status":"PROPOSED ONLY. Requires separate central release and exact helper promotion. Not executed.","cwd":str(ROOT),
 "assembly":[PYTHON,str(inputs[1]),str(inputs[2]),str(inputs[3]),str(inputs[4]),str(outputs[0])],
 "embedding":[PYTHON,str(live),str(outputs[0]),str(inputs[5]),str(outputs[1]),"--report",str(outputs[2])],
 "preconditions":["Source helper equals approved postimage before embedding; all other pins exact.","Use attempt2 raw DOCX and attempt5 table map directly, never run_stage.py or prepare_correction_manifest.py.","Both commands are one future released assembly/embedding trial, not part of this proposal.","No further Quarto render/capture or raster installation is authorized.","Native Word acceptance still needs author unlock; browser policy rejection remains final for the rejected route."],
 "input_pins":[{"path":str(p),"sha256":digest(p),"bytes":p.stat().st_size} for p in inputs]}
(TMP/"future_commands_NOT_EXECUTED.json").write_text(json.dumps(commands,indent=2)+"\n")
print(json.dumps({"pre_sha256":digest(pre),"post_sha256":digest(post),"exact_zero_fuzz_reversal":True,"future_commands_executed":False}))
