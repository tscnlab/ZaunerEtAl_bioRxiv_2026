"""Copy frozen resources and mechanically rebase candidate-only authoring sources.

No analytical content is calculated or rewritten. The only wrapper changes are
the released S7/S15 split blocks, four scoped table-layout rules and status notice.
"""
import csv
import difflib
import hashlib
import json
import re
import shutil
from pathlib import Path

OUT = Path(__file__).resolve().parents[1]
ROOT = OUT.parents[3]
SELECTION = ROOT / "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k"
MAIN_SOURCE = ROOT / "manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"
SI_SOURCE = MAIN_SOURCE.with_name("supplementary_information_outline.qmd")
SELECTION_SOURCE = ROOT / "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd"
PINS = ROOT / "audit/report_harmonization/report018_order72k_non_s5_integration_release/integration_input_pins.csv"
ADDED = ROOT / "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/dependency_closure_pins.csv"
NOTICE = "Non-S5 display-integration preview. The historical Brown Figure S5 and existing Brown results are retained for context and are not updated or newly scientifically accepted here. The Brown linkage-B replacement remains held pending explicit fit authorization and scientific review. During sleep, the unworn device describes the bedside sleep environment, not verified ocular exposure; contrary historical caption wording is not endorsed."
pin_rows = list(csv.DictReader(PINS.open())) + list(csv.DictReader(ADDED.open()))
pinned = {(str((ROOT / row["path"]).resolve()), row["sha256"]) for row in pin_rows}
copies, changes = [], []

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def write_new(p, text):
    if p.exists():
        raise RuntimeError(f"Refusing to overwrite {p}")
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding="utf-8")

def copy_resource(source, project, role="resource"):
    source = source.resolve()
    digest = sha(source)
    if (str(source), digest) not in pinned or source.is_symlink():
        raise RuntimeError(f"Unpinned or symlink resource: {source}")
    folder = "linked_metadata" if role == "metadata" else "resources"
    target = project / folder / f"{digest[:12]}_{source.name}"
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        if sha(target) != digest:
            raise RuntimeError("Candidate copy collision")
    else:
        shutil.copyfile(source, target)
    copies.append({"source": str(source), "copy": str(target), "sha256": digest,
                   "bytes": source.stat().st_size, "role": role})
    return target.relative_to(project).as_posix()

figure_map = json.loads((ROOT / "audit/report_harmonization/report018_order72d_writer_svg_integration/combined_accepted_svg_manifest.json").read_text())
splits = {
  7: [("artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg", "4ddf972fc4c8082594d13a3b446537ae8a525ca35077e0605967f9c4c0ce519e", "FDR support matrix for site, civil photoperiod, latitude and site-versus-latitude adequacy across near-eye exposure metrics."),
      ("audit/hypotheses/H07/report018_order72j_split_svg_export/candidate/H07_revised_smooth_derivative_pairs_near_eye.svg", "f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57", "Near-eye metric response smooths and their fitted slopes across observed civil photoperiod, arranged as paired panels.")],
  15: [("audit/hypotheses/H09/report018_order72j_split_svg_export/candidate/H09_primary_effects.svg", "a3f9bdb969c075d33adf9a0e6e751a1f967d5111856fcd0db07cbc36575a745a", "Study-site-adjusted chronotype associations with the analysed timing metrics, with estimates and confidence intervals."),
       ("audit/hypotheses/H09/report018_order72j_split_svg_export/candidate/H09_observed_timing_patterns.svg", "c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3", "Observed participant-day timing values across chronotype and country-coded study sites in the corresponding model samples, arranged by timing metric.")]
}
expanded = []
for item in figure_map["accepted_figures"]:
    number = next((n for n in splits if item["word_label"] == f"Supplementary Figure S{n}"), None)
    if number is None:
        expanded.append(item)
    else:
        for tag, (source, digest, alt) in zip("AB", splits[number], strict=True):
            expanded.append({"word_label": f"Supplementary Figure S{number}{tag}", "path": source,
                             "sha256": digest, "appearances": 1, "alt": alt})
assert len(expanded) == 22 and sum(x["appearances"] for x in expanded) == 23
by_label = {x["word_label"]: x for x in expanded}

table_css = """
/* Order72k candidate-only layout. No rule targets protected Main Table 3. */
#tbl-near-eye-metrics table {width:1400px !important;min-width:1400px !important;table-layout:fixed !important;}
#tbl-near-eye-metrics {min-width:0 !important;max-width:100%;}
#tbl-near-eye-metrics tr > :first-child {width:200px !important;min-width:0 !important;}
#tbl-near-eye-metrics tr > :nth-child(2) {width:40px !important;min-width:0 !important;}
#tbl-near-eye-metrics tr > :nth-child(3) {width:105px !important;min-width:0 !important;}
#tbl-near-eye-metrics tr > :nth-child(n+4):nth-child(-n+12) {width:86px !important;min-width:0 !important;}
#tbl-near-eye-metrics tr > :nth-child(13) {width:50px !important;min-width:0 !important;}
#tbl-near-eye-metrics tr > :nth-child(14) {width:231px !important;min-width:0 !important;}
#tbl-near-eye-metrics tbody img {width:100% !important;height:auto !important;max-width:100% !important;min-width:0 !important;object-fit:contain;}
"""
for table_id in ["tbl-plan-h02-glasses-variation-shapley-gt-candidate", "tbl-plan-h02-chest-variation-shapley-gt-candidate", "tbl-plan-person-level-synthesis-gt-candidate"]:
    table_css += f"#{table_id}, #{table_id} table, #{table_id} th, #{table_id} td, #{table_id} * {{font-family:Arial, Helvetica, sans-serif !important;}}\n"
table_css += """
#fig-s7 .order72k-split-panel, #fig-s15 .order72k-split-panel {display:block;width:100%;margin:0 0 1.25rem;}
#fig-s7 .order72k-panel-tag, #fig-s15 .order72k-panel-tag {display:block;text-align:left;font-weight:700;margin:0 0 .3rem;}
#fig-s7 img, #fig-s15 img {display:block;width:100%;height:auto;max-width:100%;object-fit:contain;}
"""

def rebase_includes(text, source, project):
    def replacement(match):
        old = match.group(1)
        resource = (source.parent / old).resolve()
        new = "supplementary_information_outline.qmd" if resource == SI_SOURCE else copy_resource(resource, project, "table")
        changes.append({"source": str(source), "old_reference": old, "new_reference": new, "kind": "include"})
        return "{{< include " + new + " >}}"
    return re.sub(r"\{\{< include ([^ >]+) >\}\}", replacement, text)

def replace_figures(text, source, project, selection=False):
    if selection:
        imgs = list(re.finditer(r'<img\b[^>]*src="([^"]+)"[^>]*>', text))
        original_labels = [x["word_label"] for x in figure_map["accepted_figures"]]
        assert len(imgs) == len(original_labels) == 20
        for match, label in reversed(list(zip(imgs, original_labels, strict=True))):
            if label in {"Supplementary Figure S7", "Supplementary Figure S15"}:
                continue
            resource = copy_resource(ROOT / by_label[label]["path"], project, "svg")
            replacement = match.group().replace(match.group(1), resource)
            changes.append({"source":str(source),"old_reference":match.group(1),"new_reference":resource,"kind":"accepted_svg"})
            text = text[:match.start()] + replacement + text[match.end():]
    else:
        for n in range(1,18):
            if n in splits: continue
            pattern = rf'(<figure id="fig-s{n}"[^>]*>\s*<img[^>]*src=")([^"]+)(")'
            m = re.search(pattern, text)
            if not m: raise RuntimeError(f"Missing SI figure {n}")
            new = copy_resource(ROOT / by_label[f"Supplementary Figure S{n}"]["path"], project, "svg")
            changes.append({"source":str(source),"old_reference":m.group(2),"new_reference":new,"kind":"accepted_svg"})
            text = text[:m.start(2)] + new + text[m.end(2):]
    for n, components in splits.items():
        original_block = re.search(rf'<figure id="fig-s{n}".*?</figure>', SI_SOURCE.read_text(), re.S).group()
        caption = re.search(r'<figcaption>.*?</figcaption>', original_block, re.S).group()
        blocks = []
        for tag, (p, digest, alt) in zip("AB", components, strict=True):
            new = copy_resource(ROOT / p, project, "svg")
            blocks.append(f'<div class="order72k-split-panel"><span class="order72k-panel-tag">{tag}</span><img src="{new}" alt="{alt}"></div>')
        new_block = f'<figure id="fig-s{n}" class="display-figure">\n' + "\n".join(blocks) + "\n" + caption + "\n</figure>"
        if selection:
            pattern = rf'(<h-not-real>)'  # selected below by the frozen heading range
            start = re.search(rf'^#### Supplementary Figure S{n}(?:\.| and Table\b).*$', text, re.M)
            if start is None:
                start = re.search(rf'^#### .*S{n}\..*$', text,re.M)
            if start is None: raise RuntimeError(f"Missing selection S{n} heading")
            image_start = text.index('<img', start.end())
            caption_start = text.index('<div class="caption-proposal">', image_start)
            end = text.index('</div>', caption_start)+len('</div>')
            text = text[:image_start] + new_block + text[end:]
        else:
            text, count = re.subn(rf'<figure id="fig-s{n}".*?</figure>', lambda _:new_block, text, count=1, flags=re.S)
            assert count == 1
        changes.append({"source":str(source),"kind":"split_wrapper","display":f"S{n}","caption":"exact current manuscript caption"})
    return text

def main():
    selection_project, main_project = SELECTION / "project", OUT / "project"
    if selection_project.exists() or main_project.exists():
        raise RuntimeError("Candidate project already exists")
    for project in (selection_project, main_project):
        project.mkdir(parents=True)
        write_new(project / "order72k_layout.css", table_css)
    selection = SELECTION_SOURCE.read_text()
    selection = rebase_includes(selection, SELECTION_SOURCE, selection_project)
    selection = replace_figures(selection, SELECTION_SOURCE, selection_project, selection=True)
    selection = selection.replace('</style>', '</style>\n\n' + NOTICE, 1)
    # Direct metadata links only, not the linked evidence trees.
    def metadata_link(match):
        label, old = match.groups()
        if old.startswith(("http:","https:","#","mailto:")): return match.group()
        new = copy_resource((SELECTION_SOURCE.parent / old).resolve(), selection_project, "metadata")
        changes.append({"source":str(SELECTION_SOURCE),"kind":"metadata_link","old_reference":old,"new_reference":new})
        return f'[{label}]({new})'
    selection = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', metadata_link, selection)
    selection = selection.replace('execute:\n', 'css: order72k_layout.css\nexecute:\n', 1)
    si = replace_figures(rebase_includes(SI_SOURCE.read_text(), SI_SOURCE, main_project), SI_SOURCE, main_project)
    main_text = rebase_includes(MAIN_SOURCE.read_text(), MAIN_SOURCE, main_project)
    main_figs = list(re.finditer(r'!\[\]\(([^)]+)\)', main_text))
    assert len(main_figs) == 3
    for n, m in reversed(list(enumerate(main_figs,1))):
        new = copy_resource(ROOT / by_label[f"Main Figure {n}"]["path"], main_project, "svg")
        main_text = main_text[:m.start(1)] + new + main_text[m.end(1):]
        changes.append({"source":str(MAIN_SOURCE),"kind":"accepted_svg","old_reference":m.group(1),"new_reference":new})
    for key in ("bibliography","csl","css"):
        m = re.search(rf'^{key}: (.+)$',main_text,re.M)
        new = copy_resource((MAIN_SOURCE.parent / m.group(1)).resolve(), main_project, key)
        value = f'[{new}, order72k_layout.css]' if key == "css" else new
        main_text = main_text[:m.start(1)] + value + main_text[m.end(1):]
        changes.append({"source":str(MAIN_SOURCE),"kind":key,"old_reference":m.group(1),"new_reference":value})
    main_text = main_text.replace('# Supplementary Information {.unnumbered}\n', '# Supplementary Information {.unnumbered}\n\n' + NOTICE + '\n', 1)
    write_new(selection_project / "selection.qmd", selection)
    write_new(main_project / MAIN_SOURCE.name, main_text)
    write_new(main_project / SI_SOURCE.name, si)
    ref = copy_resource(ROOT / "assets/reference.docx", main_project, "reference-doc")
    lua = copy_resource(ROOT / "_extensions/kapsner/authors-block/authors-block.lua", main_project, "authors-filter")
    write_new(selection_project / "_quarto.yml", 'project:\n  type: default\n  render: [selection.qmd]\n  resources: ["linked_metadata/*"]\nexecute:\n  enabled: false\n')
    write_new(main_project / "_quarto.yml", f'''project:
  type: default
  render: [{MAIN_SOURCE.name}]
execute:
  enabled: false
format:
  html:
    theme: cosmo
    toc: true
    toc-depth: 2
    number-sections: false
    embed-resources: true
    link-external-newwindow: true
  docx:
    toc: false
    number-sections: false
    reference-doc: {ref}
    filters: [{lua}]
crossref:
  fig-title: "Figure"
  tbl-title: "Table"
''')
    word_figures = []
    for item in expanded:
        copied = copy_resource(ROOT / item["path"], main_project, "svg")
        item["source_path"] = item["path"]
        item["path"] = str(main_project / copied)
        if item["word_label"].startswith("Supplementary"):
            key = "supp_figure_" + item["word_label"].split()[-1].lower()
            word_figures.append({"key":key,"path":item["path"]})
    write_new(OUT / "expanded_svg_manifest.json", json.dumps({"authority":"Order72k non-S5 candidate-only integration", "accepted_figures":expanded,"held_figures":["Historical Brown Figure S5; replacement and scientific update held"]},indent=2)+"\n")
    write_new(OUT / "word_figure_svg_manifest.json", json.dumps(word_figures,indent=2)+"\n")
    frozen = json.loads((ROOT / "manuscript/R0_NatHealth/_word_test/table_pngs_v2/word_table_png_manifest.json").read_text())
    for entry in frozen:
        if entry["key"] in {"supp_table_s2","supp_table_s5","supp_table_s6","supp_table_s10"}: continue
        for part in entry["files"]:
            old = Path(part["path"])
            new = copy_resource(old, OUT, "frozen_table_capture")
            part["path"] = str(OUT / new)
    write_new(OUT / "frozen_table_manifest_rebased.json", json.dumps(frozen,indent=2)+"\n")
    write_new(OUT / "source_copy_map.json",json.dumps(copies,indent=2)+"\n")
    write_new(OUT / "candidate_change_map.json",json.dumps(changes,indent=2)+"\n")
    for original, candidate, label in [(MAIN_SOURCE, main_project / MAIN_SOURCE.name,"main"),(SI_SOURCE, main_project / SI_SOURCE.name,"supplement"),(SELECTION_SOURCE,selection_project / "selection.qmd","selection")]:
        write_new(OUT / f"{label}_source.diff",''.join(difflib.unified_diff(original.read_text().splitlines(True),candidate.read_text().splitlines(True),fromfile=str(original),tofile=str(candidate))))
    print(json.dumps({"copied_resources":len(copies),"svg_sources":len(expanded),"svg_appearances":sum(x["appearances"] for x in expanded),"projects":[str(selection_project),str(main_project)]}))

if __name__ == "__main__": main()
