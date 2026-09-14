# REPORT-017 order 32d: H01 consolidated display repair and rerender

Date: 2026-08-15

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: **Released as one consolidated build-cleanup, three-figure
display-repair, focused-reseal, single-render, and complete-QA order. Do not
split this work. The companion and every later REPORT-017 target remain
held.**

## Authority

The controlling stopped-state records are:

- independent acceptance
  `audit/report_harmonization/report017_h01_order32c_stopped_state_independent_acceptance.md`,
  SHA-256
  `770e6242f0ecfabb60c6eda191e58bf807ca5be8ffeb4c29fc155ae468a7060c`;
- 19-row independent seal
  `audit/report_harmonization/report017_h01_order32c_stopped_state_independent_manifest.csv`,
  SHA-256
  `b36d003c1a41723094246dfbd6d80cf4b3ca061925ec2c30277d10924eba752a`;
  and
- 119-row owner seal
  `audit/hypotheses/H01/report017_order32c_result_render/owner_evidence_manifest.csv`,
  SHA-256
  `d058cdbceed5e7cd1912d9a0f931646d44141b8bfab755e53d1c65794ca7890b`.

The coordinator accepted the order-32c target-resource synchronization,
confirmed the defects in the three affected H01 figures, and authorized this
one-pass package.
The H04 country-code source-wrap finding is outside H01 and does not block this
order.

## Exact preflight pins

Stop before any move or write if an identity differs:

### Reader and integration inputs

- result QMD `notebooks/hypotheses/H01.qmd`:
  `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`;
- companion QMD `audit/hypotheses/H01/H01_analysis_preparation.qmd`:
  `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`;
- Nature Health profile `_quarto-nathealth.yml`:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper:
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic engine:
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- fresh stopped result HTML:
  `d1bc9159526c92b9cc9256c58a8232d4779f0014a3aa39ed3680b4e58fb25410`;
  and
- frozen companion HTML, using only this full corrected identity:
  `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`.

### Reproducible display construction

- `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R`:
  `35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7`;
- model-support source CSV
  `artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_model_support_figure_source.csv`:
  `cf869aa233aca9230a9d295f7efae69fc51c1258a80daf90258d08122f5effc0`;
- paired-placement source CSV
  `artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_paired_placement_figure_source.csv`:
  `8e1672e499e6bee05cde70647165e780dfa5cb9195ed0c3f1bd203da5d838853`;
  and
- diagnostic-assessment source CSV
  `artifacts/11_source_data/H01/stage3/H01_stage3_diagnostic_figure_source.csv`:
  `d9b424ae246fc688670a77a561717701fec3ddffaf000af72ea6b68f214b9397`.

### Six durable display targets before repair

| Target | SHA-256 | Required geometry |
|---|---|---|
| `artifacts/10_figures/H01/stage3/H01_stage3_model_support.png` | `2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b` | 3360 by 2368, 320 dpi |
| `artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg` | `602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966` | accepted vector companion |
| `artifacts/10_figures/H01/stage3/H01_stage3_paired_placement.png` | `866670f47457bf304467e787481589298d9b7cf7c2c5de560ac9500f044c4608` | 3840 by 2176, 320 dpi |
| `artifacts/10_figures/H01/stage3/H01_stage3_paired_placement.svg` | `fe101f32cb0ffd4912b81ddbad4090c9558263aa85cc4f13ecad73369ac074f0` | accepted vector companion |
| `artifacts/10_figures/H01/stage3/H01_stage3_diagnostic_assessment.png` | `95f46b0909b43c9b281a93a860d577b38a7753cb4d151ad751e2aca8a017b12d` | 3680 by 2432, 320 dpi |
| `artifacts/10_figures/H01/stage3/H01_stage3_diagnostic_assessment.svg` | `a15b3bae14b1b76d5a48ae9a21d0eb86dfd264db238179fb2a4486c002876a52` | accepted vector companion |

Before work, audit the complete 19-row independent seal and all 119 owner
evidence rows. Inventory every H01 protected file and the complete
`_build/nathealth` tree, including type, symlink status, SHA-256, bytes, mtime,
birth time where available, and change time where available.

## Part A: recoverable duplicate quarantine

Before candidate generation or rendering, require that each path below is a
regular non-symlink with the exact identity and byte count:

| Exact path | SHA-256 | Bytes |
|---|---|---:|
| `_build/nathealth/artifacts/10_figures/H01/stage3/H01_stage3_model_support 2.png` | `601c65eebff8260b9c19d6f5e3a6054799e1fb7fa7f39442745073cb36098e7a` | 238260 |
| `_build/nathealth/notebooks/hypotheses/H01 2.html` | `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa` | 1626484 |
| `_build/nathealth/site_libs/bootstrap/bootstrap-a2a938b4dd5711f7a799c87bd16ba44c.min 2.css` | `b3d78f1077461003efc2b21acc3f81ee6ba80468fe09df310b4c339e2e19133c` | 498438 |

Create one fresh recovery directory with `mktemp -d` under `/private/tmp`.
Record its resolved path, permissions, emptiness, and creation time. Move only
the three explicit files above, intact, to unambiguous relative paths under
that directory. Do not use a glob, delete a file, rename a duplicate in place,
or touch another build entry.

After the move, prove:

- exact absence at all three original paths;
- exact presence, SHA-256, bytes, and metadata at all three recovery paths;
- no accepted build member changed; and
- the recovery directory remains available through independent acceptance.

## Part B: one bounded three-figure display implementation

Create one dedicated H01 R 4.6.1 display-refresh implementation and focused
tests. It may read only:

1. the three frozen source CSVs pinned above;
2. the minimum frozen display registries or constants already required by the
   accepted construction; and
3. its own pre-repair figures and bounded audit evidence.

It must not read or deserialize a model or scientific RDS, source an analysis
or full reporting builder, calculate inference, or read another figure-source
dataset. It may write only temporary candidates, the six durable targets after
candidate acceptance, and bounded H01 audit/test/manifest evidence.

Update only the corresponding display literals in
`build_h01_stage3_reporting_inputs.R` so the reproducible builder records the
same accepted display construction. Do not run the full builder. Require an
AST and exact-diff audit proving that only the authorized display parameters
changed.

### Figure 5: paired placement

Change only deterministic direct-label layout parameters. Preserve every
source row, point, point label, estimate, predictor, axis, scale, panel,
colour, shape, null line, identity line, legend category, source-data link,
and source ordering. Preserve 3840 by 2176 pixels and 320 dpi.

Every label must remain present and independently legible, with zero label to
label overlap, zero label clipping, and no obscured point at original size,
intended final size, 1440-pixel desktop width, 708-pixel width, and 200
percent. Any label segments remain deterministic under a fixed seed.

### Figures 1 and 6: matrix typography

Change only text and status-symbol sizes needed to achieve at least 7 points
at the 708-pixel final display. Preserve every tile, status, symbol, row,
column, placement, legend category, colour, ordering, source row, source-data
link, and captioned meaning.

Preserve Figure 1 at 3360 by 2368 pixels and Figure 6 at 3680 by 2432 pixels,
both at 320 dpi. Preserve all FDR wording and zero visible compact BH wording.

### Temporary candidate and one-write rule

Write PNG and SVG candidates outside all durable targets first. The owner may
tune only the authorized display parameters inside that temporary candidate
workspace, recording every candidate attempt. No durable target or manifest
may change until one candidate set passes all of the following under R 4.6.1:

- exact frozen-source identities, row counts, keys, values, and mapped
  aesthetics;
- exact point, label, tile, status, symbol, row, column, layer, panel, and
  legend-category counts;
- exact dimensions and DPI;
- normalized-SVG structural equality outside authorized text-size,
  status-symbol-size, label-position, and label-segment properties;
- bounded raster-difference classification proving plot data and
  non-display geometry unchanged; and
- original-size, intended-final-size, 1440-pixel, 708-pixel, and 200-percent
  visual QA with zero collision, clipping, or sub-7-point required text.

Only after the complete candidate set passes may the six durable PNG/SVG
targets be replaced once. Preserve exact pre/post identities and copies of the
accepted pre-repair targets in bounded evidence.

## Part C: checker, tests, and direct manifest reseal

Preserve every order-32c evidence file byte-for-byte. Do not edit the old
order-32c semantic checker. Copy it into the new order evidence and change
only its two retired section-ID expectations to the accepted endpoints:

- `detailed-analysis-record`; and
- `analysis-record-and-source-data`.

Retain every other semantic assertion.

Add or update focused H01 tests that fail on:

- any frozen source-data change;
- any scientific field, value, row, key, mapped aesthetic, layer, panel,
  colour, shape, status, symbol, or label loss;
- any Figure 5 label collision, clipping, or missing label;
- any required Figure 1 or 6 text below 7 points at the accepted 708-pixel
  final display;
- any geometry or DPI change;
- any unexpected builder change; and
- any unclassified build or protected-file drift.

Reseal only current manifest rows directly dependent on the changed builder,
new refresh implementation, six figures, focused tests, and bounded evidence.
Update from leaves upward. Do not run a broad manifest builder, introduce a
self-hash row, or change an unrelated row, path, role, producer, order, or R
version. Preserve all historical REPORT-016, order-31, order-32, order-32c,
and other prior evidence byte-for-byte.

Run the complete focused display tests, complete H01 reporting test, complete
REPORT-016 reconciliation test, corrected semantic checker, exact manifest
audits, protected-inventory reconciliation, R parsing, Air checks, exact
source-data comparisons, and scoped diff checks. If any durable source,
artifact, test, or manifest check fails, do not render. Finish the complete
check set, seal one combined stopped state, and return without piecemeal
patching.

## Part D: exactly one H01 result render

Only after Parts A through C pass, create a fresh pre-render protected and
build inventory and run exactly once:

```sh
quarto render notebooks/hypotheses/H01.qmd --profile nathealth
```

Use normal R 4.6.1 project startup and only the established narrow access to
the existing user-owned renv cache if required. Do not bypass the profile or
semantic hook and do not use `--no-execute`.

The render may change only:

- the H01 result HTML;
- `search.json` and `sitemap.xml`;
- exact build copies of the three newly accepted PNG figures used by the H01
  page;
- the exact source-identical Stage 3 manifest build copy linked by the page;
  and
- byte-identical mtime-only resources, classified separately.

Every build copy must exactly match its current accepted source. Fail on any
other content change or any reappearance of a quarantined duplicate path.
Keep the companion HTML exact and do not run a second render.

## Part E: one complete post-render acceptance

After the sole render, require:

- 36 native gt tables and ten intended figures in exact order;
- `tbl-h01-primary-publication-summary` and `fig-h01-model-support` first;
- successful semantic-hook repair, document-wide unique IDs, and every table
  `headers` token resolving exactly once within its own table;
- 40 links to 36 exact deviation anchors;
- resolved dynamic reader links, source-data links, navigation, and H01
  country-coded site names;
- zero unresolved cross-reference, raw error node, warning node, stderr node,
  or object leak;
- complete H01 protected scientific and source-artifact preservation; and
- a fully classified build delta.

Start one temporary read-only loopback server rooted exactly at
`_build/nathealth`, bound only to `127.0.0.1` on an unused high or OS-selected
port. Record the exact command, PID, resolved root, address, port, launch time,
first request, teardown time, and no-listener result. Use only the in-app
Browser.

Inspect the complete H01 page at 1440 by 1000 and 708 by 1000. Inspect all ten
figures at final display size and inspect Figures 1, 5, and 6 at original,
intended final, desktop, narrow, and 200 percent. Inspect the principal table
at desktop, narrow, and 200 percent. Apply the accepted desktop-first and
contained narrow-scroller table policy. Require no label collision, clipping,
uncontained overflow, sub-7-point required text, browser console error, or
broken navigation/link behavior.

Stop the server immediately after QA, prove no listener remains, and rehash
the complete protected and build inventories. Preserve complete screenshots,
measurements, visual classifications, render output, hook output, exact
pre/post identities, recovery-directory evidence, and a non-circular owner
manifest.

If any remaining startup, source, artifact, test, render, semantic, link,
protection, build, or visual defect appears, do not patch or rerender. Complete
every safely executable remaining check and return one combined stopped-state
list.

## Prohibited work

Do not fit, refit, predict, simulate, bootstrap, resample, rerun Shapley,
change a source-data value, regenerate a non-display scientific artifact, run
the full reporting builder, render the companion or a later target, run a
full-project render, edit the profile or a central ledger, change a package or
lockfile, commit, push, upload, or delete a quarantined file.

The H01 companion and every later REPORT-017 target remain held until this
single consolidated return is independently accepted.
