#!/usr/bin/env python3
"""Bounded Order72d integration/QA orchestration; no scientific computation."""

import argparse
import contextlib
import csv
import hashlib
import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
AUTH = ROOT / "audit/report_harmonization/report018_order72d_writer_svg_integration"
HELPER = ROOT / "scripts/manuscript_nature_health/embed_accepted_svg_figures.py"
BASE = ROOT / "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_revision_2026_09_11.docx"
DOCX = OUT / "ZaunerEtAl2026_NatHealth_svg_complete_order72d.docx"
RENDERER = Path("/Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pins(phase):
    reports = []
    for name in ["release_manifest.csv", "input_and_preservation_pins.csv"]:
        source = AUTH / name
        rows = list(csv.DictReader(source.open()))
        checks = [{"path": row["path"], "expected_sha256": row["sha256"],
                   "actual_sha256": sha(ROOT / row["path"]),
                   "bytes_exact": (ROOT / row["path"]).stat().st_size == int(row["bytes"])} for row in rows]
        exact = all(row["expected_sha256"] == row["actual_sha256"] and row["bytes_exact"] for row in checks)
        reports.append({"manifest": str(source.relative_to(ROOT)), "manifest_sha256": sha(source),
                        "rows": len(rows), "unique": len({row["path"] for row in rows}) == len(rows),
                        "all_exact": exact, "checks": checks})
    (OUT / f"preservation_{phase}.json").write_text(json.dumps(reports, indent=2) + "\n")
    if not all(record["all_exact"] and record["unique"] for record in reports):
        raise SystemExit("Input/preservation mismatch; stop Order72d.")
    return reports


def build():
    if DOCX.exists():
        raise SystemExit("One candidate already exists; no blind retry.")
    pins("before")
    combined = AUTH / "combined_accepted_svg_manifest.json"
    if sha(HELPER) != "2b5533b192013b7efabbbc6eb963d40f8a8ec1cfb9bd1286a4be30eb1f2197d6":
        raise SystemExit("Embedding helper pin changed.")
    if sha(combined) != "0e0618520fedb387ef030b685e11597e7332ae46fa7ad9ad76d865c24b1c91b2":
        raise SystemExit("Combined20 authority changed.")
    shutil.copyfile(combined, OUT / "combined_accepted_svg_manifest.json")
    command = [sys.executable, str(HELPER), str(BASE), str(OUT / "combined_accepted_svg_manifest.json"),
               str(DOCX), "--report", str(OUT / "embedding_raw_report.json")]
    result = subprocess.run(command, capture_output=True, text=True)
    (OUT / "embedding_execution.json").write_text(json.dumps({"command": command,
        "returncode": result.returncode, "stdout": result.stdout, "stderr": result.stderr,
        "helper_sha256": sha(HELPER), "algorithm_changed": False}, indent=2) + "\n")
    print(result.stdout)
    if result.returncode:
        raise SystemExit("Embedding failed; retain evidence and stop Order72d.")
    report = json.loads((OUT / "embedding_raw_report.json").read_text())
    current = {"status": "Complete20 native-SVG candidate awaiting document/figure QA and independent review. Brown remains held.",
               "legacy_metadata_disposition": "The raw helper's seven-held status sentence is superseded by Order72d, not an integration finding.",
               "svg_count": len(report["embedded_svgs"]),
               "drawing_appearances": sum(len(record["drawings"]) for record in report["embedded_svgs"]),
               "held_figure_exports": report["held_figures"], "checks": report["checks"],
               "docx_sha256": report["output_sha256"]}
    assert current["svg_count"] == 20 and current["drawing_appearances"] == 21 and not current["held_figure_exports"]
    (OUT / "embedding_current_order_checks.json").write_text(json.dumps(current, indent=2) + "\n")
    pins("after_embedding")


def render():
    if (OUT / "rendered_pages").exists():
        raise SystemExit("Rendered output already exists; no blind retry.")
    spec = importlib.util.spec_from_file_location("bounded_document_renderer", RENDERER)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    # Retain the packaged rendering functions and bundled LibreOffice, with all
    # scratch children contained inside one fresh, private task directory.
    module._default_macos_tmpdir_for_soffice()
    before_tmp = tempfile.tempdir
    with tempfile.TemporaryDirectory(prefix="nature_health_order72d_", dir="/private/tmp") as scratch:
        tempfile.tempdir = scratch
        try:
            with (OUT / "document_render.log").open("w") as log, contextlib.redirect_stdout(log), contextlib.redirect_stderr(log):
                print("Renderer:", str(RENDERER))
                print("Bundled LibreOffice:", module._resolve_soffice())
                print("Private scratch root:", scratch)
                render_input, repair = module.make_renderable_docx_copy(str(DOCX), verbose=True)
                try:
                    dpi = module.calc_dpi_via_ooxml_docx(render_input, 1600, 2000)
                    module.rasterize(render_input, str(OUT / "rendered_pages"), dpi, verbose=True, emit_pdf=True)
                finally:
                    if repair is not None:
                        repair.cleanup()
        finally:
            tempfile.tempdir = before_tmp
    pins("after_render")
    pages = list((OUT / "rendered_pages").glob("page-*.png"))
    print(json.dumps({"page_count": len(pages), "docx_sha256": sha(DOCX)}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["build", "render", "postcheck"])
    args = parser.parse_args()
    if args.mode == "build":
        build()
    elif args.mode == "render":
        render()
    else:
        pins("after_visual_qa")
