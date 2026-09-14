# REPORT-018 order 53: H07 companion render and acceptance

Date: 2026-08-21

Owner: H07 owner `019fbe52-6781-7c32-bdcf-379c88ef1e78`

Status: released for exactly one H07 preparation/provenance companion render.
Every later REPORT-018 render remains held.

## Controlling authority

Follow the complete central release at
`audit/report_harmonization/report018_h07_companion_release.md`. Before any
execution, require its identity, its non-circular release manifest, this order,
and every non-matrix row in the dispatch manifest to match exactly.

Key protected identities are:

- accepted result QMD `c779c57f...` and HTML `78148604...`;
- companion QMD `a6c05e81...`;
- stale build companion QMD `e32aff68...`;
- stale companion HTML `53c261b8...`;
- dedicated helper `9e961ec8...`;
- current 1,235-row manifest `7e3cbf59...`;
- held preparation test `89fd3eaa...`;
- result reader test `84e96a52...`;
- normal profile `80dd0557...`;
- semantic wrapper `28c11058...` and engine `7c949930...`; and
- lockfile `3bf99c63...`.

The coordination matrix is dispatch-time evidence only. Do not edit it or
rerun the completed central release checker after its expected status change.

## Pre-render gate

Reproduce every non-matrix dispatch pin. Require:

- 26 parseable R chunks;
- exactly 21 unique table endpoints and three unique figure endpoints;
- 14 resolving relative reader/source-data targets;
- no prohibited scientific-regeneration calls;
- zero build symlinks;
- exactly the four preclassified historical preparation-manifest mismatches;
- the accepted result and source-side historical companion HTML exact; and
- no competing Quarto, Pandoc, H07 semantic, or loopback process.

Inventory the complete `_build/nathealth` tree and protected H07 scope. Create
one fresh empty absolute semantic directory under `/private/tmp`.

Preserve `tests/hypotheses/H07/test_h07_preparation_report.R` byte-for-byte
and do not execute it. Its one hard-coded HTML source-link assertion is stale.
The accepted source has three dynamic `.qmd` result links. Reproduce every
other preparation contract independently after rendering. Do not patch or
replace the test.

## Sole render

Run exactly once with R 4.6.1, Quarto 1.9.37, the normal project profile, the
accepted project library, and the semantic hook:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render audit/hypotheses/H07/H07_analysis_preparation.qmd --profile nathealth
```

The established narrow elevated access to the existing user-owned `renv`
cache is authorized. Do not bypass the profile, use `--no-execute`, render the
result again, render another page, or retry a failed command.

## One helper execution

If and only if the render and hook succeed, execute once:

```sh
NATHEALTH_PROJECT_ROOT=<absolute-project-root> Rscript --vanilla scripts/hypotheses/H07/build_h07_preparation_report_manifest.R
```

Require the authoring and build QMDs to become byte-identical and the new
preparation manifest to be unique, live-exact, non-circular, and truthful.
The profile-integrated helper must not restore or change the source-side
historical HTML or asset tree.

## Complete acceptance

Before visual QA, create task-owned evidence that independently proves:

- 21 native `gt` tables, two accepted PNG figures, and one top-down Mermaid;
- semantic repair of all native tables with exact reversal, reapplication,
  unique document IDs, and all table-header references resolving within their
  own table;
- exact endpoint order, captions, notes, alt text, source-data links, dynamic
  result links, anchors, navigation, country-coded sites, and no embedded
  errors or unresolved references;
- all preparation source-data row contracts, formulas, fit settings,
  derivative settings, diagnostics, sensitivities, site influence, METRIC-011
  provenance, environment, and code/output maps preserved;
- the result reader test passes unchanged;
- the held preparation test is unchanged and unexecuted;
- the final helper manifest is wholly live-exact;
- the accepted result, profile, science, handoff, corpus manifest, local
  historical companion HTML, and unrelated project files remain exact; and
- every build delta is target-owned or source-identical and classified.

Then bind a temporary server only to `127.0.0.1` and inspect the complete page
at 1440 by 1000, 708 by 1000, 720 by 500 200-percent-equivalent, and 170 mm
figure size. Inspect all tables, both PNG figures, the Mermaid diagram,
contained table scrollers, captions, notes, links, and final provenance.
Require no page overflow, clipping, overlap, missing content, broken
interaction, or report-attributable console warning or error. Close the QA
surface, reset the viewport, stop the server, and prove no listener remains.

Return one completion record and one unique non-circular manifest, or one
consolidated fail-closed record. No source/helper/test/profile/science edit,
result rerender, later render, full-project render, retry, commit, push, or
upload is authorized.
