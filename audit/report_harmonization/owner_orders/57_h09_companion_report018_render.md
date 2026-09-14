# REPORT-018 order 57: H09 companion render and acceptance

Date: 2026-08-22

Owner: H09 owner `019fdc1b-b927-7fb1-ac61-88993c0a818a`

Status: sealed for exactly one H09 companion render. Every later REPORT-018
render remains held.

## Controlling authority

Follow the complete release at
`audit/report_harmonization/report018_h09_companion_release.md`. Its completed
preflight is:

```text
H09_COMPANION_REPORT018_RELEASE=PASS checks=30/30 pins=34/34 result_acceptance=37/37 chunks=22 tables=19 figures=1 mermaid=1 links=23/22 manifest=113/132+19 prospective_manifest=449->450 stale_test=3/3 forbidden_calls=0 build=851 symlinks=0 R=4.6.1 digest=0.6.39 quarto=1.9.37
```

The controlling preflight identities are:

- checker `scripts/report_harmonization/check_h09_companion_report018_release.R`,
  SHA-256
  `9fcd89bc7d2585d927fd4527e0cbd8a893e52cb87f353cabb38ef04a9f5cffdc`,
  21,154 bytes;
- verification SHA-256
  `89a533044dac43c0f179761900b7f598bf2c43d14df915847f0b73bffa8d64a6`,
  5,811 bytes; and
- 34-row pins SHA-256
  `16a181126f1978f7c18f6be621612ab1e422442f55889e302611c1db66f2e677`,
  5,319 bytes.

Before execution, reproduce this order, the complete dispatch manifest, the
release, and every non-matrix hard pin. The coordination matrix is
dispatch-time evidence only. Do not edit it and do not rerun the completed
central checker after its expected status transition.

## Frozen endpoints

Require:

- accepted result QMD `c738a436...` and HTML `901fd63b...`;
- companion QMD `7563a933...`;
- stale build companion QMD `4640129c...`;
- historical source-side and stale canonical companion HTMLs both
  `4054dfc6...`;
- helper `c7a32036...`;
- historical preparation test `9a243e39...` and result test `a0309e55...`;
- current 132-row preparation manifest `8e1d6332...`;
- Stage 3 manifest `0103aad8...` and figure manifest `74c0f444...`;
- contract `458dc3c0...`, profile `80dd0557...`, semantic wrapper
  `28c11058...`, semantic engine `7c949930...`, phase-4 manifest
  `73f1a371...`, handoff `f6a596f9...`, and lockfile `3bf99c63...`; and
- the frozen 108-row model-frame index `5a0fb42c...` and historical
  source-side sample-support PNG `3116032e...`.

Static R 4.6.1 preflight parses all 22 companion R chunks and finds exactly
19 unique `tbl-h09-prep-*` endpoints, one unique
`fig-h09-prep-sample-support` endpoint, one top-down Mermaid, 23 relative link
occurrences to 22 unique targets, and zero prohibited scientific-regeneration
calls.

The current 132-row preparation manifest has exactly 19 historical
mismatches. They are the accepted H09 source, result, profile, registry,
contract, and figure transitions enumerated by the release checker. Require
exact set equality for these 19 paths and exact live identities for the other
113 rows before rendering. This historical state is not permission to change
any scientific artifact.

## Pre-render gate

Before rendering:

1. reproduce every non-matrix dispatch member;
2. require 22 parseable R chunks, exactly 19 native-table endpoints, one
   figure endpoint, one top-down Mermaid, and all 23 relative targets in the
   accepted source order;
3. require zero prohibited scientific-regeneration calls;
4. require the 132-row preparation manifest to have exactly 113 live rows and
   only the exact 19 accepted historical transitions;
5. require 851 build files, zero build symlinks, and the accepted result,
   companion, profile, model-frame, helper, test, manifest, source-side HTML,
   and source-side asset pins;
6. inventory the complete build and protected H09 scopes; and
7. confirm no competing Quarto, Pandoc, H09 semantic, or loopback process.

Create all pre-render working evidence under one fresh temporary directory
outside the project. Create a separate fresh empty absolute semantic-audit
directory under `/private/tmp`.

Preserve both historical H09 tests byte-for-byte and do not execute them. The
preparation test contains exactly the three classified obsolete integration
assumptions recorded in the release. Use a new order-specific verifier after
rendering.

## Sole render

Run exactly once from the project root:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> \
quarto render audit/hypotheses/H09/H09_analysis_preparation.qmd --profile nathealth
```

Use R 4.6.1, Quarto 1.9.37, the accepted project library, the normal profile,
the accepted semantic hook, and the established narrow access to existing
user-owned caches. Do not alter `HOME`, redirect or reset a cache, restore or
install packages, bypass the profile, use `--no-execute`, render another
target, or retry. On any failure, stop once and seal it.

The companion may read only its accepted stored inputs and format them. No
model fit or refit, prediction, bootstrap, simulation, resampling, influence
recalculation, scientific artifact regeneration, or source-data rewrite is
authorized.

## One helper execution

If and only if the render and semantic hook succeed, run exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
Rscript --vanilla scripts/hypotheses/H09/build_h09_preparation_report_manifest.R
```

The helper must execute before any durable order-57 evidence directory is
created. Require authoring and build companion QMDs to be byte-identical and
the resulting preparation manifest to contain exactly 450 unique, live-exact,
non-circular rows. It must exclude itself and every order-57 evidence path.
The helper may change only the build QMD copy and the preparation manifest.
Do not run it again.

The historical source-side companion HTML and its 16-file support tree must
remain byte-identical. They are historical evidence and must not replace,
overwrite, or otherwise supply the canonical website output.

## Required acceptance

After the helper, create one new durable evidence directory under
`audit/hypotheses/H09/report018_order57_companion_render/` and prove:

- render exit zero, exactly one Quarto invocation, and no embedded error,
  unresolved reference, or raw trace;
- exactly 19 native `gt` tables, one figure, and one top-down Mermaid in
  source order;
- every table and figure endpoint, caption, note, alt text, cell, label,
  source relationship, reader link, navigation link, and country-coded site
  present;
- semantic repair of all 19 tables, unique document IDs, exact ledger reverse
  and reapplication, and every `headers` token resolving exactly once to an
  intended `th` inside its own table;
- all 23 relative target occurrences and required fragments resolving,
  including two dynamic result links, reciprocal navigation, DEV-037,
  DEV-038, DEV-039, and the result deviation-section anchor;
- all accepted score directions, sample counts, exact formulas, model
  settings, four complete five-outcome FDR families, diagnostic
  qualifications, sensitivity summaries, METRIC-011 provenance, code and
  output maps, and environment records consistent with the frozen inputs;
- the accepted result, profile, helper, historical tests, source data,
  scientific artifacts, durable figures, handoff, historical manifests,
  phase-4 manifest, semantic code, and lockfile exact;
- the final 450-row preparation manifest wholly live-exact;
- the historical source-side HTML and support tree byte-identical; and
- build changes only the companion target, source-identical build QMD, one
  target-owned figure, search and sitemap integration, and the truthful H09
  preparation manifest.

If the target-generated sample-support PNG changes bytes from the historical
source-side PNG, require the same frozen 108-row model-frame input, geometry,
values, labels, panels, colours, and visible content, plus at least 7-point
final-size text. Classify the exact transition in owner evidence only. Do not
edit a historical manifest or promote a durable display artifact.

The phase-4 corpus manifest remains byte-identical. Its result and companion
HTML identities are historical records and must be classified against the
current accepted pages rather than resealed.

## Secure loopback QA

After every nonvisual gate passes, serve `_build/nathealth` through one
read-only server bound only to `127.0.0.1`. Inspect the H09 companion route at
1440 by 1000, 708 by 1000, and 720 by 500 as the 200-percent-equivalent view.
Inspect all 19 tables, the figure, the Mermaid diagram, headings, callouts,
captions, notes, links, navigation, disclosures, and final provenance.
Exercise required narrow table scrollers. Inspect the figure at 170 mm and
require essential text of at least 7 points.

Require no page overflow, clipping, overlap, missing content, broken
interaction, or report-attributable console warning or error. Close the QA
surface, reset the viewport, stop the server, prove no listener remains, and
require post-QA build and protected inventories to match their post-render
states exactly.

## Return and prohibitions

Return one completion record and one unique non-circular evidence manifest,
or one consolidated fail-closed record. Retain external semantic evidence
until independent acceptance.

No source, helper, historical test, profile, science, durable figure,
handoff, ledger, package, lockfile, result rerender, later render,
full-project render, retry, language or cosmetic loop, commit, push, upload,
or publication is authorized. The mandatory next stop is independent H09
companion acceptance.
