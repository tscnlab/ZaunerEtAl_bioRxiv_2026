"""Non-analytical path, diff and command inventory before the bounded correction."""
import ast
import difflib
import hashlib
import json
from pathlib import Path

out = Path(__file__).resolve().parents[1]
root = out.parents[3]
sel = root / "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k"
record = out / "correction_preflight"
target = record / "correction_manifest.json"
assert not target.exists()
pairs = [(record / "main_layout_before.css", out / "project/order72k_layout.css"), (record / "selection_layout_before.css", sel / "project/order72k_layout.css"), (record / "capture_word_tables_before.mjs", out / "helpers/capture_word_tables.mjs")]
changes = []
for before, after in pairs:
    delta = ''.join(difflib.unified_diff(before.read_text().splitlines(True), after.read_text().splitlines(True), fromfile=str(before), tofile=str(after)))
    diff_path = record / (before.stem + ".diff")
    assert not diff_path.exists()
    diff_path.write_text(delta)
    changes.append({"before":str(before), "after":str(after), "before_sha256":hashlib.sha256(before.read_bytes()).hexdigest(), "after_sha256":hashlib.sha256(after.read_bytes()).hexdigest(), "diff":str(diff_path)})
for helper in (out / "helpers").glob("*.py"):
    ast.parse(helper.read_text())
for destination in [out / "capture_s2_attempt2", sel / "project/render_attempt2", out / "project/render_html_attempt2", out / "project/render_docx_attempt2"]:
    assert not destination.exists(), destination
qmd = "ZaunerEtAl2026_NatHealth_phase3_brown.qmd"
payload = {"scope":"Existing consolidated layout-only correction pass; no scientific changes", "changes":changes, "lua_copies":str(record / "lua_dependency_copies.csv"), "s2_capture":{"subset":"only-s2", "output":str(out / "capture_s2_attempt2"), "rows":[[0,9],[9,17],[17,23]], "columns":list(range(14)), "width":1400, "change":"Normal wrapping of numerical spans, with all text and images preserved; text-rectangle clipping check added"}, "reuse":"S5/S6/S10 first captures and all unaffected frozen captures unchanged", "render_commands":[{"cwd":str(sel / "project"),"argv":["/Applications/quarto/bin/quarto","render","selection.qmd","--to","html","--no-execute","--output-dir","render_attempt2"]},{"cwd":str(out / "project"),"argv":["/Applications/quarto/bin/quarto","render",qmd,"--to","html","--no-execute","--output-dir","render_html_attempt2"]},{"cwd":str(out / "project"),"argv":["/Applications/quarto/bin/quarto","render",qmd,"--to","docx","--no-execute","--output-dir","render_docx_attempt2"]}], "remaining_after_correction":{"selection_html":0,"main_html":0,"main_docx":0,"s2_vertical_adjustments":1}, "word_preflight":"Installed python-docx Document has __dict__ and accepts the candidate counter attribute; no mechanical patch needed", "visual_initial":"S7 and S15 two-component HTML images observed in the permitted in-app browser; final width-specific QA remains", "native_word":"Mac locked at initial CUA inventory; user asked to unlock; no native app action attempted"}
target.write_text(json.dumps(payload, indent=2)+"\n")
print("Correction manifest and exact three-file diffs recorded; fresh output paths checked.")
