# REPORT-017 order 32j: H01 preparation no-render finalization

Date: 2026-08-20

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: authorized procedural continuation; no Quarto command is authorized

## Purpose

Finish the already rendered H01 preparation/provenance page without rendering
again. Order 32i completed the target render and semantic repair, then stopped
because Quarto removed two linked source-data copies, left a stale build-side
QMD copy, and therefore left the current preparation and worker manifests
unreconciled.

Treat this as one consolidated finalization. Restore the exact protected
downloads, synchronize the build-side QMD, reseal only direct current
dependencies, run the complete non-render verification package, and complete
the deferred secure-loopback visual QA. Return one combined result.

Controlling harmonizer records:

- stopped-state independent acceptance:
  `audit/report_harmonization/report017_h01_order32i_stopped_independent_acceptance.md`,
  SHA-256
  `be210834f9a7cda0f7400924a1ec0d34639b5839fd040674ebecd26f658e525d`;
- 14-row non-circular stopped-state manifest:
  `audit/report_harmonization/report017_h01_order32i_stopped_acceptance_manifest.csv`,
  SHA-256
  `99200c48ce705d8cebaf8a689e48ad452dbb64e02ec6ee3bb51229391822c5bb`;
- order-32i owner stop:
  `audit/hypotheses/H01/report017_order32i_preparation_render/order32i_stopped_state.md`,
  SHA-256
  `b36ae6f42509d2dfd2c611473190b101b70d339a3c79c9029487b4075b16366d`;
- order-32i owner evidence manifest:
  `audit/hypotheses/H01/report017_order32i_preparation_render/order32i_owner_evidence_manifest.csv`,
  SHA-256
  `bdf00b7a3035308f743961d272b755c1df6901de4c75f493d487937f0fe20440`.

The coordination-matrix identity at dispatch is evidence only. It is not a
mutable owner execution pin while disjoint source-only work may proceed.

## Exact preflight pins

Stop before mutation if any of these live identities differs:

- helper:
  `scripts/hypotheses/H01/build_h01_preparation_report_manifest.R`,
  `0ff174f2127ac981d13b619038c16f286f0643a10372610def43f687048aa4ee`,
  7,163 bytes;
- authoring companion QMD:
  `audit/hypotheses/H01/H01_analysis_preparation.qmd`,
  `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`,
  55,827 bytes;
- stale build-side companion QMD:
  `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.qmd`,
  `85d51304a3a5808efa6ec4cf7bded79a07a31ff639a6643ec49be67fb8ed6dcc`,
  52,259 bytes;
- accepted companion HTML:
  `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html`,
  `5ab6587465f01f946fcf133f9f81a69168e08fa866f69830c2378e6c3cf250fe`,
  727,310 bytes;
- accepted result QMD:
  `notebooks/hypotheses/H01.qmd`,
  `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`,
  93,260 bytes;
- accepted result HTML:
  `_build/nathealth/notebooks/hypotheses/H01.html`,
  `df78ac3c2ed91515058b6af38e01b85b4baae74118699c008a29ba4dacf4d007`,
  1,643,915 bytes;
- Nature Health profile:
  `_quarto-nathealth.yml`,
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`,
  7,480 bytes;
- current 62-row preparation manifest:
  `artifacts/12_manifests/H01/H01_preparation_report_manifest.csv`,
  `69c2215a3c789e31b4b9e820ae1a1c90485a74ec106d4c09269a71d859cdffd5`,
  13,841 bytes;
- current 1,659-row worker manifest:
  `artifacts/12_manifests/H01_worker_artifacts.csv`,
  `882c1e63290384723b47d1bf67eb524c6a18e21d710eb60c989067bfe08c387c`,
  397,567 bytes;
- preparation test:
  `tests/hypotheses/H01/test_h01_preparation_report.R`,
  `379414830e5bcd656ac460c2ad93616ecbcab104259c56a8fcf9296da8c0f2c4`;
- reporting test:
  `tests/hypotheses/H01/test_h01_reporting_inputs.R`,
  `48f374cc70b69a6d96a95dc425ffd9676b2e83133a5554ae1c19eda939c0c8af`;
- REPORT-016 test:
  `tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`,
  `140cc2d0305026885f8703e2aa349d324d1cef9a8d7d92c9b72314d845d0f8ab`;
- H01 handoff:
  `audit/handoffs/H01_worker_handoff.md`,
  `0de574566315d44934d3c6dd5fd91be9045e2f6b43887c9e3ad98d97caf1f19b`;
- semantic wrapper and engine:
  `scripts/report_harmonization/post_render_gt_html_semantics.R`,
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`,
  and `scripts/report_harmonization/repair_gt_html_semantics.R`,
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- central deviation page:
  `notebooks/preregistration_deviations.qmd`,
  `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d`.

The protected download sources must be exact:

- `artifacts/11_source_data/H01/preparation/H01_preparation_fitted_sample_support.csv`,
  `760e634fd6139b8c6561d185c95fb5c06ef5b41637c7b20f8c61b0e627ff37c7`,
  4,818 bytes;
- `artifacts/11_source_data/H01/preparation/H01_preparation_model_frame_retention.csv`,
  `28cc582f2778c849025f2ea77fee2036ce693378630d6f7e172adc0db6bb6d5b`,
  2,860 bytes.

Their corresponding target paths under
`_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation_files/source-data/`
must both be absent before the helper runs.

## Authorized mutable paths

Only these existing project paths may change:

1. `scripts/hypotheses/H01/build_h01_preparation_report_manifest.R`;
2. `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.qmd`;
3. the two exact target download CSVs under the target `source-data` directory;
4. `artifacts/12_manifests/H01/H01_preparation_report_manifest.csv`;
5. `artifacts/12_manifests/H01_worker_artifacts.csv`.

New bounded order-32j audit, snapshots, diff, reverse proof, test output,
loopback lifecycle, screenshot, visual-QA, inventory, and non-circular manifest
evidence may be written only under
`audit/hypotheses/H01/report017_order32j_no_render_finalization/`.

Do not modify any authoring QMD, HTML, other build member, profile, semantic
tool, scientific artifact, historical record, package, lockfile, central
record, manuscript, or another hypothesis.

## Helper correction

Change only the existing preparation-manifest helper. Add deterministic
synchronization from the accepted authoring companion QMD to the existing
build-side companion QMD. Before copying, record the authoring QMD SHA-256 and
byte count. Copy with overwrite and mode preservation. Then require:

- the authoring QMD retains its exact pre-copy SHA-256 and byte count;
- the build-side QMD has the same SHA-256 and byte count as the authoring QMD;
- the build-side path is regular and not a symlink; and
- failure of any copy or identity check stops before manifest writing.

Retain the helper's existing source-data discovery, exact two-copy operation,
SHA-256 comparison, manifest roles, fail-closed path checks, row ordering, and
writer. Do not broaden the helper to another page or output.

Create exact helper pre/post diff and reverse evidence. Parse the changed
helper under R 4.6.1 before execution. Do not run a preliminary helper or
partial copy command.

## One helper execution

Run the helper exactly once through normal R 4.6.1 project startup:

```sh
NATHEALTH_PROJECT_ROOT=<exact-project-root> Rscript scripts/hypotheses/H01/build_h01_preparation_report_manifest.R
```

No Quarto command is permitted. After the one helper run, require:

- both target download CSVs exist, are regular non-symlinks, and are
  byte-identical to their respective protected sources;
- the build-side companion QMD is SHA-256
  `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`
  and 55,827 bytes;
- the accepted companion HTML is still SHA-256
  `5ab6587465f01f946fcf133f9f81a69168e08fa866f69830c2378e6c3cf250fe`;
- the preparation manifest contains exactly 62 unique paths, has no self-row,
  and all 62 SHA-256 and byte identities equal the live files; and
- the only mutations so far are the helper, build QMD, two download copies,
  and preparation manifest.

## Direct worker-manifest reseal

Do not run `build_h01_worker_manifest.R` or any broad manifest builder. Update
only these four existing worker-manifest rows to their live SHA-256 and byte
identities, preserving every other field and the complete row order:

1. `scripts/hypotheses/H01/build_h01_preparation_report_manifest.R`;
2. `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.qmd`;
3. `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html`;
4. `artifacts/12_manifests/H01/H01_preparation_report_manifest.csv`.

The two target-download rows already carry the correct source-identical
hashes and byte counts. Verify them but do not rewrite their values. Preserve
the worker-manifest historical result-HTML and profile rows unchanged and
classified as historical by the existing tests. Fail unless all four target
rows occur exactly once, no other row or field changes, all paths remain
unique, and no self-row or circular dependency is introduced.

Use leaf-up order: helper and copied build outputs, preparation manifest, then
worker-manifest direct rows. Record exact row-level before/after and reverse
evidence.

## Complete no-render verification

Under R 4.6.1, run the complete preparation test, H01 reporting test,
REPORT-016 test, navigation contract, reader-link contract, country-coded-site
contract, and preregistration-deviation contract. Run a read-only semantic
HTML audit using the accepted engine logic. Require:

- exactly 20 native gt tables and two figure endpoints;
- zero duplicate document IDs;
- every explicit `headers` token and supported ID reference resolves exactly
  once to its intended element within its own table;
- reciprocal result and companion links, all deviation links and anchors,
  active navigation, and all country-coded study sites pass;
- both restored download links resolve to exact protected CSVs;
- no unresolved cross-reference, local/build path, raw error, warning, or
  stderr node;
- preparation manifest 62 of 62 live-exact;
- worker manifest differs from live files only at the two established
  historical result-HTML and profile rows, as required by the accepted
  transition classifications; and
- the complete protected scientific and build inventories are unchanged
  outside this order's explicit mutable set.

Do not rerun the pre-integration transition test that intentionally pins the
old defective result HTML. Do not misclassify that historical pin as a new
defect.

## Secure loopback visual QA

Use the active `$quarto-authoring` secure-loopback procedure without
rendering. Recheck `_build/nathealth` for symlinks and stop if any symlink
resolves outside that root. Start one temporary read-only static server rooted
exactly at `_build/nathealth`, bind only to `127.0.0.1` on one unused high or
ephemeral port, and navigate only to the exact H01 companion route in the
in-app Browser.

Inspect at 1,440 by 1,000 pixels, 708 by 1,000 pixels, and 200 percent zoom.
Verify headings, callouts, reciprocal and download links, navigation,
typography, wrapping, clipping, overlap, page overflow, both figures, and the
top-to-bottom Mermaid. Inspect all 20 HTML tables for reasonable desktop and
laptop use. At narrow width, a wide HTML table may use a contained, working
horizontal scroller. For any exported table representation, its PNG is the
controlling final-size visual check.

Stop the server immediately after QA, prove no listener remains on the port,
reset the viewport, and rehash the source, profile, accepted HTML, build, and
protected inventories. The browser must not modify any build file.

## Completion and stop rule

Return one combined seal with exact commands, R and package versions,
pre/post identities, the four-row worker change proof, 62-row preparation
manifest audit, test results, semantic counts, resolved-link counts, visual
measurements, screenshots, server lifecycle, protected reconciliation, and a
non-circular evidence manifest that excludes itself.

If any genuinely new failure remains, finish all safe read-only inspection,
do not patch or retry, and return one combined stopped-state defect list.

No Quarto command, render, QMD execution, source QMD edit, scientific
calculation, artifact regeneration, result-page change, profile or central
ledger edit, package or lockfile change, full-project action, commit, push, or
upload is authorized. H01 remains the sole integration path. H02 and every
later render remain held.
