#!/usr/bin/env python3
"""Bounded document-layout QA; no scientific data or calculations."""

import argparse
import json
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path


def render_one(source, output, runtime, renderer):
    destination = output / source.stem
    command = [str(runtime), str(renderer), str(source), "--output_dir", str(destination), "--emit_pdf"]
    result = subprocess.run(command, capture_output=True, text=True)
    return {"source": str(source.resolve()), "command": command,
            "returncode": result.returncode, "output": result.stdout + result.stderr,
            "pages": [str(p.resolve()) for p in sorted(destination.glob("page-*.png"),
                       key=lambda p: int(p.stem.split("-")[-1]))]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("table_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--python", required=True, type=Path)
    parser.add_argument("--renderer", required=True, type=Path)
    parser.add_argument("--only", nargs="+")
    args = parser.parse_args()
    sources = sorted(args.table_dir.glob("Table_*.docx"))
    if args.only:
        sources = [source for source in sources if source.stem in args.only]
    args.output_dir.mkdir(parents=True, exist_ok=True)
    records = []
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures = [pool.submit(render_one, source, args.output_dir, args.python, args.renderer)
                   for source in sources]
        for future in as_completed(futures):
            record = future.result()
            records.append(record)
            print(json.dumps({"file": Path(record["source"]).name,
                              "returncode": record["returncode"],
                              "pages": len(record["pages"])}), flush=True)
    (args.output_dir / "render_manifest.json").write_text(
        json.dumps(sorted(records, key=lambda record: record["source"]), indent=2) + "\n")
    if any(record["returncode"] or not record["pages"] for record in records):
        raise SystemExit("One or more document renders failed; inspect render_manifest.json")


if __name__ == "__main__":
    main()
