# REPORT-017 order 31f: H01 model-support FDR display-artifact refresh

Date: 2026-08-14

Owner task: `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: **Released for one bounded artifact-only display refresh and its
source/test/manifest evidence. No Quarto render is authorized. The H01
companion, H02, the queued H03 synchronization, and every later REPORT-017
target remain held.**

## Authority and accepted stop

The coordinator accepted finding `H01-REPORT017-31E-VIS-001` as a genuine
display-only defect. The fresh H01 result render and post-render native-gt
semantic repair passed. Visual QA then stopped because the principal
`fig-h01-model-support` raster says `BH-adjusted result`, while the accepted
reader term in its caption and alt text is `FDR-adjusted result`.

Controlling harmonizer evidence:

- independent stop acceptance:
  `audit/report_harmonization/report017_h01_order31e_visual_stop_independent_acceptance.md`,
  SHA-256
  `f5844f1d034171243e7702f05392e061dbc8aafe055ce6d4b77ef76818f45b75`;
- its 20-entry non-circular manifest:
  `audit/report_harmonization/report017_h01_order31e_visual_stop_independent_acceptance_manifest.csv`,
  SHA-256
  `54044eddc8899b7c2823aca86bffc52b273bdc646693d002f5153eb771ebec51`;
- stopped H01 HTML:
  `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa`;
- R 4.6.1 frozen-source comparison script:
  `/private/tmp/H01_VIS001_AUDIT.Ynn9ZM/compare_support_sources.R`,
  SHA-256
  `b13593dbc692da4b330de4d63fbf8e755109ad2439d2782f5054feae40dc5d9e`;
  and
- its comparison result:
  `/private/tmp/H01_VIS001_AUDIT.Ynn9ZM/support_source_comparison.csv`,
  SHA-256
  `b6d4caa0be10581d6b9580e3eaf893c90e15147366ecf94ab737cef547a23592`.

The R comparison established 136 unique
metric-by-placement-by-question cells and exact equality of all plotted
fields between the historical and current sources. Differences occur only in
unmapped stored numerical fields. The accepted current METRIC-011 source is
therefore the sole plot-data input for this refresh.

## Exact preflight pins

Stop before changing or executing anything if any identity differs:

- builder:
  `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R`,
  SHA-256
  `eca3e1e855314838c51172d3dd24922ac8e5db096b6c5e3b505d74853885b28c`,
  68,213 bytes;
- accepted current plot source:
  `artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_model_support_figure_source.csv`,
  SHA-256
  `cf869aa233aca9230a9d295f7efae69fc51c1258a80daf90258d08122f5effc0`,
  96,013 bytes;
- historical plot source, which must remain unchanged:
  `artifacts/11_source_data/H01/stage3/H01_stage3_model_support_figure_source.csv`,
  SHA-256
  `2054c097bb6b901ebc12491c78082fe5a56ebca2ccc5e2c61afe7e21244c3772`,
  96,014 bytes;
- target PNG:
  `artifacts/10_figures/H01/stage3/H01_stage3_model_support.png`,
  SHA-256
  `601c65eebff8260b9c19d6f5e3a6054799e1fb7fa7f39442745073cb36098e7a`,
  238,260 bytes;
- target SVG:
  `artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg`,
  SHA-256
  `c054674bacdd41ca2d02fff0a784955dfd77caf7604dacc166ccd0c8e1cfc098`,
  54,756 bytes;
- H01 result QMD:
  `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`;
- H01 companion QMD:
  `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8`;
- complete H01 reporting test:
  `ab648ac80bc1c8a149a11bb958fd683b38722487c53179b42b215a2b000e6fd5`;
- REPORT-016 focused test:
  `tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`,
  SHA-256
  `55c89eb03f9510ea3bce937a26da04d552d9eb4d6c2f87aec34884af69715765`;
- reporting manifest, which is protected and is not edited in this order:
  `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`;
- current Stage 3 reporting manifest:
  `08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f`;
- current worker manifest:
  `51288b656723bc7d29027b3bd5877fa7f18837135d6f7fe1d6c0b96bbe312006`;
- Nature Health profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
  and
- current H01 handoff:
  `00ae3a8e9aa6a9203f598d57f21ef462cbc676407f50c162fa0ab14c3457d9b0`.

Record a fresh pre-execution inventory that includes every historical
REPORT-016 protected path, all H01 scientific/input artifacts, both QMDs, the
profile and semantic hook, all current manifests, the stopped HTML, and all
figures other than the two exact targets.

## Exact builder repair

In `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R`, replace only
the legend-title literal:

```text
BH-adjusted result
```

with:

```text
FDR-adjusted result
```

Require an exact one-literal diff and an in-memory reverse substitution that
reproduces the pre-edit builder identity. Do not change another byte, plotting
argument, numeric token, geometry, theme, label, source path, or output path in
the builder. Do not execute or source the full builder.

## Dedicated display-refresh implementation

Create one H01-owned R script dedicated to this refresh, preferably
`scripts/hypotheses/H01/refresh_h01_stage3_model_support_fdr_label.R`.

The dedicated script may:

- read only the accepted current METRIC-011 source above and the minimum
  frozen display registry or constants already needed to reproduce the
  accepted plot construction;
- reproduce the accepted 136 plotted cells, key order, support states,
  symbols, colours, facets, labels, scales, theme, layout, dimensions, and
  resolution; and
- write only the target PNG and SVG plus its own bounded H01-owned audit and
  non-circular manifest evidence.

It must not:

- source or run the full Stage 3 builder;
- deserialize or load a fitted model;
- fit, refit, predict, simulate, bootstrap, resample, calculate inference, or
  recompute an estimate, interval, p-value, FDR decision, diagnostic,
  sensitivity, or sample;
- change or write a source CSV, table, diagnostic, QMD, HTML, other figure,
  profile, semantic hook, central ledger, package, or lockfile; or
- read the historical source as a data input to the refreshed plot. The
  historical source may be pinned only as unchanged provenance evidence.

The PNG must remain exactly 3,360 by 2,368 pixels at 320 dpi. Only the visible
legend-title text may change. The SVG must retain the same normalized display
structure apart from that title.

## Focused display test and evidence

Add one H01-owned focused R 4.6.1 display test, preferably
`tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R`.
It must require:

1. the exact frozen current-source identity and 136 unique plotting keys;
2. exact equality of all accepted plotting fields and support states against
   the sealed comparison evidence;
3. the exact one-literal builder change and no other builder delta;
4. unchanged numeric tokens and plot-construction fields outside the one
   authorized label;
5. exact PNG pixel dimensions and 320 dpi;
6. visible `FDR-adjusted result` and no visible `BH-adjusted result` in both
   output formats;
7. a PNG difference confined to the legend-title region, with all plotted
   cells and other visible regions unchanged; and
8. normalized SVG structure identical except for the legend-title text.

Create bounded H01-owned provenance and visual-QA records. Record pre/post
hashes and byte counts for the builder, PNG, SVG, refresh script, focused test,
frozen current source, historical source, display registries, and all evidence
files. Record exact R and consequential package versions, command, runtime,
exit status, dimensions, resolution, comparison method, and original-size plus
intended-final-size visual QA. The non-circular manifest must not include
itself.

## Current-manifest and REPORT-016 handling

Truthfully update only:

- `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv`; and
- `artifacts/12_manifests/H01_worker_artifacts.csv`.

Refresh only the rows for the changed builder, PNG, and SVG, then add only the
new dedicated refresh script, focused test, and bounded evidence rows required
by the existing manifest conventions. Preserve every other row, field, role,
producer, order, and identity exactly. Do not edit
`artifacts/12_manifests/H01_reporting_artifacts.csv`.

Preserve these historical REPORT-016 records byte-for-byte:

- `audit/hypotheses/H01/report016/H01_REPORT016_protected_scientific_artifacts.csv`;
- `audit/hypotheses/H01/report016/H01_REPORT016_reconciliation_manifest.csv`;
- every other file under `audit/hypotheses/H01/report016/`; and
- every historical REPORT-016 inventory or reconciliation manifest elsewhere.

Edit only the classification logic in
`tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R` that is
strictly needed to recognize the exact pre/post builder, PNG, SVG, current
Stage 3 manifest, worker manifest, refresh-script, test, and evidence
identities as an approved display-only transition. Continue to require every
other historical protected path byte-identical. Do not weaken the corrected
deviation rows, central-ID mapping, scientific-file protection, or manifest
checks.

## Required execution and verification

Use R 4.6.1 and the synchronized project library. Run only the dedicated
display refresh and read-only verification needed for this order. Then run:

- the new focused display test;
- the complete `tests/hypotheses/H01/test_h01_reporting_inputs.R`;
- the complete
  `tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`;
- static parsing of every changed R file;
- exact manifest row and reverse-diff checks;
- a protected-inventory comparison; and
- scoped `git diff --check`.

The complete H01 reporting test must continue to pass without a Quarto render.
The stopped HTML remains sealed at its current identity and may still contain
the pre-refresh raster until a separate target-render order is released.

Return:

- all exact pre/post identities and byte counts;
- the exact builder diff and reverse proof;
- the dedicated script and its no-scientific-call audit;
- plotting-key, support-state, image-region, SVG-normalization, dimensions,
  resolution, and visual-QA evidence;
- the two current manifest row-level diffs and exact preservation of every
  other row;
- proof that all historical REPORT-016 records are byte-identical;
- complete R 4.6.1 test output, package versions, commands, runtimes, exit
  status, protected reconciliation, and scoped diff result; and
- one non-circular owner verification manifest.

Stop for independent harmonizer acceptance. Do not render Quarto, mutate the
durable H01 HTML, edit a QMD, update the profile or semantic hook, commit,
push, or release another target. A separate coordinator gate is required for
the later one-target H01 result rerender and desktop, 708-pixel, and 200%
visual QA.
