# REPORT-017 order 32h: H01 historical recovery, direct reseal, and result-page completion

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Mode: one consolidated continuation. Do not split this order into separate
test, manifest, render, semantic, or visual-QA returns.

## Purpose and controlling disposition

Order 32g completed and accepted the display-only Figure 1, Figure 5, and
Figure 6 replacements, then stopped before manifest resealing and before
Quarto because one immutable historical core-manifest row still referred to
the earlier display test. The exact historical test has now been reconstructed
byte-for-byte. A complete downstream audit also found that the REPORT-016
live-transition classifier must cover the same six accepted figure files.

This order resolves both classifications, reseals only their direct current
dependencies, runs the full H01 source and artifact gates, and, if they all
pass, performs exactly one H01 result render and one complete semantic and
visual acceptance pass.

Read completely before acting:

- `audit/report_harmonization/report017_h01_order32g_stopped_state_independent_acceptance.md`,
  SHA-256
  `16921627f4b35d518c61214750e41af9a07be6dc3da76423c9b2b08a48232c69`,
  6,079 bytes;
- `audit/report_harmonization/report017_h01_order32g_stopped_state_independent_manifest.csv`,
  SHA-256
  `67f3fb0e1a4b3c50b00fd3e540aa2d3ccea17ce4b7c7fbfadfd3427722709bca`,
  4,764 bytes, 27/27 exact and non-circular;
- `audit/hypotheses/H01/report017_order32g_continuation/order32g_stopped_state.md`,
  SHA-256
  `6012e1c2d6c5b664bc17968172e196ff80f9567553d099690afcb4402414bb90`,
  4,310 bytes;
- `audit/hypotheses/H01/report017_order32g_continuation/order32g_stopped_state_manifest.csv`,
  SHA-256
  `05b44c9e852334e191a766ef784767f3197c603a5713e30f55e852a0580b9443`,
  12,740 bytes, 63/63 exact and non-circular;
- `audit/report_harmonization/report017_h01_order32g_recovery_checks.csv`,
  SHA-256
  `7105a18b8eb306b65bcd90103707674a61bf4f93a766463cc959ab48ac947dba`;
- this order's non-circular dispatch manifest.

The coordination-matrix identity at dispatch is coordination evidence only.
It is not an owner execution pin.

## Exact preflight identities

Stop before editing if any of these differ:

| Path | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/hypotheses/H01.qmd` | `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb` | 93,260 |
| `audit/hypotheses/H01/H01_analysis_preparation.qmd` | `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f` | 55,827 |
| `_build/nathealth/notebooks/hypotheses/H01.html` | `d1bc9159526c92b9cc9256c58a8232d4779f0014a3aa39ed3680b4e58fb25410` | 1,643,915 |
| `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html` | `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38` | 667,418 |
| `_quarto-nathealth.yml` | `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3` | 7,480 |
| `scripts/report_harmonization/post_render_gt_html_semantics.R` | `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205` | 21,453 |
| `scripts/report_harmonization/repair_gt_html_semantics.R` | `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1` | 17,747 |
| `tests/report_harmonization/test_post_render_gt_html_semantics.R` | `696e3308275d366dcc4aefb8e60c36d7c4c42d02a88402e3d06717b6383d0fae` | 16,662 |
| `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R` | `39511a898f5d55be1abeb571e48a7812a0143f1db3aa641614e5464eb9c75bbc` | 68,626 |
| `scripts/hypotheses/H01/refresh_h01_order32d_figures.R` | `367e1544e5533cdb2670c0e413a5f15c23c3d4a95f431bbf7784615e9bb00ff7` | 29,036 |
| `tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R` | `dcd3e62574a493d18733a9cb50eb6eb9d7493f8ac7bbb27918dc6535dcd1a603` | 8,224 |
| `tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R` | `09e8daa4a62a2fe18f29527bc6c5fca610175d651eedc1da10f51fadc9d3af5e` | 14,922 |
| `tests/hypotheses/H01/test_h01_order32g_display_repair.R` | `73a4d68708cf59855a00f7bf36fe2918e861dd0f0e8d94b8295ab9903a79ca07` | 7,106 |
| `tests/hypotheses/H01/test_h01_reporting_inputs.R` | `48f374cc70b69a6d96a95dc425ffd9676b2e83133a5554ae1c19eda939c0c8af` | 23,014 |
| `tests/hypotheses/H01/test_h01_preparation_report.R` | `379414830e5bcd656ac460c2ad93616ecbcab104259c56a8fcf9296da8c0f2c4` | 10,993 |
| `artifacts/12_manifests/H01_reporting_artifacts.csv` | `dfa9e15f44f0919277264765e84b49b7be78e4822df014abed678b29a9a951b4` | 11,054 |
| `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv` | `e9fe8740785e9f4d29e17c4333fdc0615347299c1dabea1d62ffad1cdafd11f9` | 26,497 |
| `artifacts/12_manifests/H01/H01_preparation_report_manifest.csv` | `cb89845e92b39f5bab7a0524508a3f7e2ce1d19ebbc99afe12f1ebf8eb9aefb5` | 13,841 |
| `artifacts/12_manifests/H01_worker_artifacts.csv` | `0d98bcc4ffe312e27ec89e352fdd84eea4ce1b8b8f9b9169307d314ba466b031` | 394,888 |
| `audit/handoffs/H01_worker_handoff.md` | `0de574566315d44934d3c6dd5fd91be9045e2f6b43887c9e3ad98d97caf1f19b` | 97,406 |

Exact frozen display inputs:

| Path | SHA-256 | Bytes |
|---|---|---:|
| `artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_model_support_figure_source.csv` | `cf869aa233aca9230a9d295f7efae69fc51c1258a80daf90258d08122f5effc0` | 96,013 |
| `artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_paired_placement_figure_source.csv` | `8e1672e499e6bee05cde70647165e780dfa5cb9195ed0c3f1bd203da5d838853` | 21,978 |
| `artifacts/11_source_data/H01/stage3/H01_stage3_diagnostic_figure_source.csv` | `d9b424ae246fc688670a77a561717701fec3ddffaf000af72ea6b68f214b9397` | 21,261 |

Exact accepted live display files, which must not be regenerated again:

| Path | SHA-256 | Bytes |
|---|---|---:|
| `artifacts/10_figures/H01/stage3/H01_stage3_model_support.png` | `a06d33e4d9708e7a60c0296a645b7c136ffea9f6be5bcf0c7a5e38615a3069de` | 332,771 |
| `artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg` | `897e7b11a27136fd2f3ffca978af72c108ba1f443bb8941ce7d9a5515847e8ba` | 54,914 |
| `artifacts/10_figures/H01/stage3/H01_stage3_paired_placement.png` | `5ca5a91ed367bdf0158bae99a671819eccf14de0d06938c91a2268275998fee5` | 237,215 |
| `artifacts/10_figures/H01/stage3/H01_stage3_paired_placement.svg` | `87d0df52d9e5134b4a760cea63acd3bdd6f9bc82b675551a3325e30e3afa8a2b` | 22,469 |
| `artifacts/10_figures/H01/stage3/H01_stage3_diagnostic_assessment.png` | `103556d8d6ca681cb8fba1ba65f4b1d7d5839ee477215becdfbc7480af0613c4` | 495,057 |
| `artifacts/10_figures/H01/stage3/H01_stage3_diagnostic_assessment.svg` | `be25f8b9c83996a2e70cd7333283ae8111a659392f577f02a585508f37116f44` | 76,304 |

## Immutable historical recovery

These harmonizer-owned files are read-only inputs to this order:

- `scripts/report_harmonization/reconstruct_h01_order32g_historical_display_test.R`,
  SHA-256
  `f53ef754f3ccdf700ed6987d9947a669d45df08a841dc1107bc69a20dd1f0680`,
  4,581 bytes;
- `audit/report_harmonization/report017_h01_order32g_historical_test_recovery/H01_stage3_model_support_display_refresh_pre32g.R`,
  SHA-256
  `121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb`,
  6,747 bytes;
- `audit/report_harmonization/report017_h01_order32g_recovery_checks.csv`,
  SHA-256
  `7105a18b8eb306b65bcd90103707674a61bf4f93a766463cc959ab48ac947dba`.

Run the recovery implementation once to a fresh file under `/private/tmp` and
require exact equality with the durable recovered file. Do not overwrite the
durable copy or the current test.

## A. Exact test classifications

Edit only these two existing tests.

### Display-refresh test

In
`tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R`,
change only the resolver for the immutable core-manifest row whose path is the
display-refresh test itself. Route that one row to the exact durable recovered
file above. Keep every other core-manifest row, builder transition, source-data
check, PNG/SVG comparison, 136-cell check, and current live-display check
unchanged. Require the historical hash and bytes explicitly.

### REPORT-016 test

In
`tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`,
preserve every file under `audit/hypotheses/H01/report016/` byte-for-byte.
Change only the live display-transition classifier so it recognizes exactly
these six paths:

1. `artifacts/10_figures/H01/stage3/H01_stage3_diagnostic_assessment.png`
2. `artifacts/10_figures/H01/stage3/H01_stage3_diagnostic_assessment.svg`
3. `artifacts/10_figures/H01/stage3/H01_stage3_model_support.png`
4. `artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg`
5. `artifacts/10_figures/H01/stage3/H01_stage3_paired_placement.png`
6. `artifacts/10_figures/H01/stage3/H01_stage3_paired_placement.svg`

The historical identities and byte counts must come from the frozen REPORT-016
protected CSV. The live identities and byte counts must be selected by exact
path from the accepted order 32g stopped-state manifest at SHA-256
`05b44c9e852334e191a766ef784767f3197c603a5713e30f55e852a0580b9443`.
Require exact six-path set equality, exact historical and live identities, all
other protected rows unchanged, and failure on any seventh mismatch. Retain
all deviation, link, central-ID, historical-manifest, and scientific gates.

## B. Leaf-only evidence and direct resealing

Create `audit/hypotheses/H01/report017_order32h_completion/` for this order.
Before manifest resealing, create these leaf evidence files. None may contain
or pin a current Stage 3, preparation, or worker manifest identity:

1. `order32h_historical_display_test_recovery_audit.csv`
2. `order32h_six_figure_transition_audit.csv`
3. `order32h_source_and_geometry_verification.csv`
4. `order32h_package_versions.csv`
5. `order32h_test_classification_diff.patch`

The first four must be deterministic, source-only records. The patch must
contain exactly the two authorized test changes and no manifest diff.

Do not run any broad manifest builder. Reseal from leaves upward.

### Stage 3 manifest

In `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv`, update only the
eight existing rows for the six figure files, builder, and current display-
refresh test. Preserve every other existing row and every non-hash field.

Append exactly these ten new, unique paths in this order, using role
`H01 REPORT-017 order 32h display completion evidence`, the current order file
as producer, and R version `4.6.1`:

1. `scripts/hypotheses/H01/refresh_h01_order32d_figures.R`
2. `tests/hypotheses/H01/test_h01_order32g_display_repair.R`
3. `scripts/report_harmonization/reconstruct_h01_order32g_historical_display_test.R`
4. `audit/report_harmonization/report017_h01_order32g_historical_test_recovery/H01_stage3_model_support_display_refresh_pre32g.R`
5. `audit/report_harmonization/report017_h01_order32g_recovery_checks.csv`
6. `audit/hypotheses/H01/report017_order32h_completion/order32h_historical_display_test_recovery_audit.csv`
7. `audit/hypotheses/H01/report017_order32h_completion/order32h_six_figure_transition_audit.csv`
8. `audit/hypotheses/H01/report017_order32h_completion/order32h_source_and_geometry_verification.csv`
9. `audit/hypotheses/H01/report017_order32h_completion/order32h_package_versions.csv`
10. `audit/hypotheses/H01/report017_order32h_completion/order32h_test_classification_diff.patch`

The Stage 3 manifest must have 118 unique data rows after this step.

### Preparation manifest

In `artifacts/12_manifests/H01/H01_preparation_report_manifest.csv`, update
only the existing row for
`artifacts/12_manifests/H01_stage3_reporting_artifacts.csv` to the new exact
Stage 3 hash and bytes. Preserve every other row and field.

### Worker manifest

In `artifacts/12_manifests/H01_worker_artifacts.csv`, update only the existing
rows for:

- the six figure files;
- `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R`;
- the two edited tests;
- `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv`;
- `artifacts/12_manifests/H01/H01_preparation_report_manifest.csv`.

Append the same ten new paths in the same order, using this order file as
producer and R version `4.6.1`. The worker manifest must have 1,659 unique data
rows after this step. Preserve all other existing rows exactly, including the
established historical H01 HTML and profile rows. Do not refresh those two
historical rows.

Keep `artifacts/12_manifests/H01_reporting_artifacts.csv` byte-identical at
SHA-256
`dfa9e15f44f0919277264765e84b49b7be78e4822df014abed678b29a9a951b4`.

Create exact row-level before/after and reverse evidence for all three edited
manifests. Require no duplicate path, no self-row, and no path whose contents
pin a manifest that lists it.

## C. Complete pre-render verification

Under R 4.6.1, run all of these after resealing:

1. reconstruct the historical display test to a fresh temporary output and
   compare it byte-for-byte with the durable recovered copy;
2. `tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R`;
3. `tests/hypotheses/H01/test_h01_order32g_display_repair.R`;
4. `tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`;
5. `tests/hypotheses/H01/test_h01_reporting_inputs.R`;
6. `tests/hypotheses/H01/test_h01_preparation_report.R` with
   `H01_PREPARATION_SOURCE_ONLY=true`;
7. exact row and file audits of the reporting, Stage 3, preparation, and worker
   manifests;
8. exact six-transition and all-other-REPORT-016-row equality;
9. exact preservation of the three frozen source CSVs, all accepted scientific
   files, both QMDs, both held HTMLs, profile, semantic hook, packages, and
   lockfile;
10. R parse, Air 0.4.1, exact test diff/reverse proof, manifest reverse proof,
    and scoped `git diff --check`.

The pre-render worker manifest is allowed to retain exactly the two established
historical mismatches for the result HTML and profile. No third mismatch is
allowed. If any other check fails, finish a single combined diagnostic and
stop without patching or rendering.

## D. Exactly one H01 result render

Only after every pre-render check passes:

1. Create one fresh audit directory with `mktemp -d` under `/private/tmp`.
   Record its normalized absolute path, permissions, and initial emptiness.
2. Run exactly one command under the normal project profile and the established
   narrow access to the existing user-owned renv cache:

   ```bash
   GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H01.qmd --profile nathealth
   ```

3. Require R 4.6.1, Quarto 1.9.37, normal profile startup, and semantic-hook
   disposition `REPAIRED` for the declared H01 HTML output.
4. Do not rerender after any failure.

Allowed content-changing build outputs are limited to:

- `_build/nathealth/notebooks/hypotheses/H01.html`;
- normal `search.json` and `sitemap.xml` refreshes;
- source-identical website copies of the six accepted figure files if Quarto
  declares them for this target;
- the source-identical website copy of
  `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv` if Quarto declares
  it for this target.

Classify byte-identical CSS or asset mtime touches separately and restore their
accepted mtime only when the established REPORT-017 procedure requires it.
Fail on any other unclassified build-content change.

## E. Semantic, link, and visual acceptance

Retain the external semantic audit directory until the harmonizer consumes it.
Require the accepted H01 semantic outcome: 36 native `gt` tables, 783
namespaced IDs, 4,798 resolved `headers` values, and 5,581 reversible raw
attribute substitutions. Require document-wide unique IDs, every explicit
headers token resolving once to the intended `th` in its own table, no
dangling or unsupported ID references, and preservation of visible content,
row/cell/header counts, captions, notes, links, styles, and endpoints.

Run the fresh-render H01 reporting, navigation, reader-link, deviation-link,
country-code, no-error, and no-warning contracts. Require:

- exactly 36 native tables and ten intended figures;
- 40 links to 36 unique preregistration-deviation anchors;
- `fig-h01-model-support` and
  `tbl-h01-primary-publication-summary` as the first principal figure and
  table;
- accepted FDR language and zero visible BH shorthand in the principal output;
- all dynamic internal targets and anchors resolved;
- external HTTPS GitHub edit links classified as external;
- the unbuilt Supplementary information link classified only as the existing
  shared DOC-001 hold;
- no raw error, warning, unresolved cross-reference, or stderr node.

Use the approved `$quarto-authoring` secure-loopback procedure. Preflight the
build root for escaping symlinks, serve exactly `_build/nathealth` read-only on
`127.0.0.1` at one unused high port, and navigate only to the H01 result route
in the in-app Browser. Inspect at 1440 x 1000 and 708 x 1000, at 200 percent,
and at intended final sizes. Review all ten figures, with particular attention
to the three repaired outputs, and the principal table and figure. Check
typography, legends, labels, clipping, overlap, overflow, callouts, navigation,
and link usability.

For HTML tables, require reasonable desktop and laptop usability. A narrow
table may use a contained, usable horizontal scroller. For exported tables,
the PNG output is the controlling visual check. Do not reject an exported
table solely because the HTML representation differs at a narrow viewport.

Stop the loopback server immediately after QA, prove that no listener remains,
and rehash the complete protected and build inventories. Record screenshots,
server lifecycle, final hashes, semantic ledger and summary, link checks,
visual measurements, and exact build deltas in the order 32h evidence
directory. Create a final non-circular owner manifest that excludes itself and
does not enter any current H01 manifest.

## One-combined-stop rule

Do not pause for the already authorized two test classifications, direct
reseals, append-only rows, render synchronization, or expected historical
worker rows. If a genuinely new defect appears, finish all safe read-only
diagnostics, seal one combined stopped state, stop the browser server if
started, and return once. Do not patch or rerender after that failure.

## Prohibitions

Do not edit either QMD, any source CSV, model, estimate, interval, p-value,
diagnostic, sample definition, central record, profile, semantic hook, package,
or lockfile. Do not regenerate the six figures, run the full builder, fit,
refit, predict, simulate, bootstrap, resample, or recalculate inference. Do not
render the companion or another target, run a full project render, delete any
retained evidence or quarantine file, commit, push, upload, or edit the
manuscript. The H01 companion and every later REPORT-017 render remain held.
