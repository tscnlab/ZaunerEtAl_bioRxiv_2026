# H05 Stage 4 handoff

Status: **Stage 4 complete_verified; four-stage H05 workflow closed**

## Authorization and scope

The controlling transition is
`audit/decisions/h05_stage3_gate_and_stage4_transition.md` (`H05-002`), and
final closure is recorded in `audit/decisions/h05_stage4_closure.md`
(`H05-003`, `CHG-080`). The companion implements
`audit/decisions/hypothesis_preparation_provenance_companions.md`
(`REPORT-007`) and also follows `REPORT-008` through `REPORT-011` for p-value
display, paired-placement display, dataset terminology, and final-size figure
readability.

The coordinator-owned ledgers record H05 Stage 4 as `complete_verified`, the
current gate as closed, the comparison workflow as
`closed/independent_pass`, and claim records `H05-CLAIM-001` through
`H05-CLAIM-004`. Those decision and ledger files remained read-only in this
task.

This work used stored H05 data frames, fitted outputs, estimates, diagnostics,
and sensitivity records. It performed identity checks, schema/key checks, and
lightweight descriptive summaries only. No model was fitted or refitted, no
prediction or residual diagnostic was recalculated, no leave-one-site-out
analysis was repeated, and no bootstrap or simulation was run.

## Completed deliverables

- Authoring source:
  `audit/hypotheses/H05/H05_analysis_preparation.qmd`
- Nature Health HTML:
  `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.html`
- Byte-identical website source copy:
  `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.qmd`
- Descriptive source-data builder:
  `scripts/hypotheses/H05/build_h05_preparation_artifacts.R`
- REPORT-011 QA builder:
  `scripts/hypotheses/H05/build_h05_figure_readability_qa.R`
- Non-circular provenance builder:
  `scripts/hypotheses/H05/build_h05_preparation_report_manifest.R`
- H05-scoped verification:
  `tests/hypotheses/H05/test_h05_preparation_report.R`
- Figure QA record:
  `artifacts/12_manifests/H05/H05_figure_readability_qa.csv`
- Preparation-report manifest:
  `artifacts/12_manifests/H05/H05_preparation_report_manifest.csv`

The coordinator-owned `_quarto-nathealth.yml` places the companion immediately
after H05 results in both the render list and navigation. The preparation page
links to the H05 results HTML, and the rerendered H05 results page links back to
the preparation HTML. The H05 task did not edit the shared profile.

## Reader-facing content

The companion explains the complete result-producing pipeline from verified
metric datasets and LEBA scores through the 136 run-by-metric frames, 544
factor-specific model-index rows, exact formula registry, fixed-site models,
complete 68-test BH families, diagnostics, sensitivities, and report assets.
It contains a Mermaid dependency map, 19 readable `gt` tables, and three
descriptive figures with captions, alternative text, and linked source data.

The author's additions are incorporated:

- The six exact evaluated Wilkinson formulas are presented as a compact table
  instead of a raw printed list.
- The sleep-environment outcome is prominently classified as **unfit for H05
  inference**. The text explicitly limits that disposition to the H05 response,
  estimand, and model structure and does not preclude use in another hypothesis
  with a different response variable or model.
- The sensitivity dataset is called the **gap-timing-unaware dataset**. Its
  first explanation states the general 50%-per-hour and 80%-per-day coverage
  rules, explains that remaining-gap timing is not used for metric-specific
  adjustment, and uses “time-sensitive primary metric dataset” only for that
  initial contrast.
- The longest-period identifiability sensitivity consistently uses “period”
  in reader-facing text.
- A concise callout explains why BH cannot retain fewer associations than
  Bonferroni for the same raw p-value vector, while a changed model/test can
  produce a different raw vector before adjustment.
- The fixed-site primary/random-site sensitivity decision, 15 unstable
  random-site fits, zero-of-68 primary conclusion, paired/common placement
  comparison, and exact sensitivity sample of 132 participants, 500
  participant-days, and nine sites are all visible and traceable.

## Source data and figure QA

The preparation-specific source data contain:

| Source file | Rows |
|---|---:|
| `H05_preparation_sample_support.csv` | 34 |
| `H05_preparation_leba_score_distribution.csv` | 72 |
| `H05_preparation_site_support.csv` | 1,122 |
| `H05_preparation_site_support_summary.csv` | 17 |

REPORT-011 QA covers all ten H05 reader-facing figures at this reporting
touchpoint: seven in the results report and three in the preparation companion.
Every checklist field passes for clipping/cropping, overlap, text distortion,
wrapping, readability, data-region balance, mark distinguishability, and
caption/alt-text presence. The intrinsic rasters are at least 1,900 × 1,200
pixels and were inspected at their actual rendered widths.

One display defect was found and repaired: the near-eye residual Q--Q figure's
diagnostic subtitle was clipped at the right edge. It now uses a deliberate
two-line annotation and is fully visible. This repair redrew the reader assets
from frozen plot data and did not change an estimate, interval, p-value,
diagnostic classification, sensitivity result, or scientific claim.

## Provenance guard and unchanged scientific artifacts

The Stage 3 manifest guard initially detected that a display rebuild had
rewritten only the creation/modification timestamps in four frozen comparison
PDFs. Their plot content and raster counterparts were unchanged. The exact
recorded PDF byte identities were restored, and the reader-artifact builder was
hardened to identity-check those frozen files instead of rewriting them.

The final Stage 3 manifest contains 144 identities and verifies every frozen
Stage 2 hash before writing. Its intentional coordinator snapshots now absorb
the settled `hypothesis_stage_gates.csv` closure state and `change_log.csv`
through `CHG-082`, including the unrelated central comparison-ledger repairs
that followed `CHG-080`. Stage 2 and Stage 3 H05 tests pass. The Stage 4
manifest contains 111 identities, excludes itself and this handoff from its
inventory, and verifies the current hashes and byte sizes of all recorded
files. The authoring QMD and website QMD copy are byte-identical.

## Rendering and verification

Bounded renders used Quarto 1.9.37, R 4.6.1, and the synchronized project
library:

- `notebooks/hypotheses/H05.qmd`: 71 of 71 chunks, successful;
- `audit/hypotheses/H05/H05_analysis_preparation.qmd`: 51 of 51 chunks,
  successful.

The final checksum-only closure required no rerender because the focused
structural tests accepted both existing HTML files and their reciprocal links.

Final H05-scoped checks:

- `tests/hypotheses/H05/test_h05_stage2.R`: passed; 544 fixed-site cells,
  three complete 68-test BH families, 612 leave-one-site-out refits, and exact
  historical reconstruction verified;
- `tests/hypotheses/H05/test_h05_stage3_reader_report.R`: passed; 68 near-eye
  and 68 chest cells, zero retained associations, 26 bounded tables, seven
  accessible result figures, and all material diagnostic qualifications;
- `tests/hypotheses/H05/test_h05_preparation_report.R`: passed; 19 `gt`
  tables, required figure/caption/alt-text structure, 111 manifest identities,
  adjacent navigation, reciprocal links, source-data contracts, REPORT-011 QA,
  prohibited-call audit, and byte-identical source copy.

## Final identities

| File | SHA-256 |
|---|---|
| `audit/hypotheses/H05/H05_analysis_preparation.qmd` | `5ec4b2208e544edc30b2424cbee40f55a7eaafa6e54f415e4bcd4592b605d156` |
| `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.qmd` | `5ec4b2208e544edc30b2424cbee40f55a7eaafa6e54f415e4bcd4592b605d156` |
| `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.html` | `4216cb40b062c0db23882c0a3c6fbe739384f08646569a1b8e44b463112a7add` |
| `notebooks/hypotheses/H05.qmd` | `b75b10bafefe3dfe7b7fdc809b0e31f0b477c6bc2c454bba1cf64b50dc5ed73b` |
| `_build/nathealth/notebooks/hypotheses/H05.html` | `ca1c9fbc3920ec72da6660ffb8d5fb585ca75ef96e65fbab791b61b7a80cb34a` |
| `scripts/hypotheses/H05/build_h05_figure_readability_qa.R` | `0aa31b69e5c8fe767f2a910115ecfc03c504e4a8167d8534c986f624ac361cdd` |
| `scripts/hypotheses/H05/build_h05_preparation_report_manifest.R` | `ae0e1d59df2023a23728a7f19c49806d77942928417fd9b943eabe0b0a2d9287` |
| `tests/hypotheses/H05/test_h05_preparation_report.R` | `623a40bf57ec74ab28d0f77985a6039148176b2340caca21ae2b5ebdd8eafe1b` |
| `artifacts/12_manifests/H05/H05_figure_readability_qa.csv` | `850839bb0d23435af370ae5324a39f6759686a83c2b5de9bf4b7984f77da1bd4` |
| `artifacts/12_manifests/H05/H05_stage3_artifacts.csv` | `abc7480eded838a4108a27781c04d8a85dde09c4de99b2402b4a6673981a7958` |
| `audit/handoffs/H05_stage3_handoff.md` | `c60c2742767359246e3b3ec578bcf71383f1c1c910dbfad07972aa93e355cb3c` |
| `artifacts/12_manifests/H05/H05_preparation_report_manifest.csv` | `3bafa87ba8bbc44f0ec8da3e1039d4198deb5c5b37c928ae87e44ebb5d089b11` |
| `audit/decisions/h05_stage4_closure.md` | `c3502a02bcb05a19461b76fbfed5c3167af265ad81137d3f912f6918a4f0d435` |
| `audit/ledgers/hypothesis_stage_gates.csv` | `222bfb8e08f686b0c37c98e2cdd272005ef0c0a4a3592c1045b23135e0ab2d5b` |
| `audit/ledgers/change_log.csv` | `f9f05a6a9b9594548e5dce0d02033b246dd3df17209a0d97bd46ec130b7bc4de` |

## Final disposition

`H05-003` closes H05 with no further scientific gate. The final manifest chain
is non-circular: the Stage 3 handoff is outside its own inventory, the Stage 4
handoff is outside the preparation manifest, and neither manifest inventories
itself. No commit, push, upload, or external publication action was performed
by this task.
