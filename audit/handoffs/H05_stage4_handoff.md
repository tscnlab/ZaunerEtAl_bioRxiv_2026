# H05 Stage 4 handoff

Status: **Stage 4 complete_verified; four-stage H05 workflow closed**

## Authorization and scope

The controlling transition is
`audit/decisions/h05_stage3_gate_and_stage4_transition.md` (`H05-002`), and
final closure is recorded in `audit/decisions/h05_stage4_closure.md`
(`H05-003`, `CHG-080`; committed checksum reconciliation `CHG-084`). The companion implements
`audit/decisions/hypothesis_preparation_provenance_companions.md`
(`REPORT-007`) and the H05 reporting chain also follows `REPORT-008` through
`REPORT-013` for p-value display, paired-placement display, dataset
terminology, physical-size figure readability, the compact result summary,
and applicability of the reader-facing symlog rule.

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
- Physical-size inspection record:
  `audit/hypotheses/H05/H05_figure_readability_qa.md`
- Ten-page QA-only A4 proof:
  `artifacts/12_manifests/H05/H05_figure_A4_proofs.pdf`
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
- At the later authorized display-only touchpoint, the H05 results page gained
  the exact REPORT-012 **Answer in brief** note. It presents the accepted
  zero-of-68 result, the two leading estimates and 95% confidence intervals,
  complementary chest and gap-timing-unaware conclusions, and the main
  uncertainty qualifications without changing any scientific artifact.

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
caption/alt-text presence. Each figure was inspected on a separate A4 proof
page at its actual QMD width within a 170-mm reference frame. Display widths
were 149.6--170.0 mm, effective essential text was 5.76--6.43 pt, central
effect-matrix text was 7.11 pt, and all A4 side margins were at least 20 mm.

The initial proof found four display defects: clipped subtitles in both effect
matrices, a left-cropped quantile--quantile title, and a right-clipped subtitle
in the paired-placement figure. The subtitles were wrapped, the diagnostic
title shortened, and the result canvas/text settings repaired. The repeated
ten-page inspection passed all ten figures. These repairs redrew result
figures from frozen tables or diagnostic points and did not change an estimate,
interval, p-value, diagnostic classification, sensitivity result, or
scientific claim.

REPORT-013 was assessed as `NOT_APPLICABLE` for every H05 figure because they
show effects, adequacy categories, residual diagnostics, matched estimands,
LEBA-score distributions, sample counts, or site ranges rather than
non-negative, strongly right-skewed raw metric values with meaningful exact
zeros. No figure was redrawn merely to add a symlog scale.

## Provenance guard and unchanged scientific artifacts

The Stage 3 manifest guard initially detected that a display rebuild had
rewritten only the creation/modification timestamps in four frozen comparison
PDFs. Their plot content and raster counterparts were unchanged. The exact
recorded PDF byte identities were restored, and the reader-artifact builder was
hardened to identity-check those frozen files instead of rewriting them.

The refreshed Stage 3 manifest contains 152 identities and verifies every frozen
Stage 2 hash before writing. Its intentional coordinator snapshots now absorb
the settled `hypothesis_stage_gates.csv` closure state and `change_log.csv`
through `CHG-096`, including central reporting-rule updates after the original
closure. The Stage 4 manifest contains 117 identities, excludes itself and this handoff from its
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
The later REPORT-011 through REPORT-013 touchpoint rerendered only the 71-chunk
H05 results page from stored outputs; the preparation source, HTML, source
copy, tables, and figure assets remained unchanged. Its three figures were
nevertheless included in the new physical-size proof and passed inspection.

Final H05-scoped checks:

- `tests/hypotheses/H05/test_h05_stage2.R`: not rerun at this display-only
  touchpoint; the Stage 3 manifest guard verified every frozen Stage 2 identity
  unchanged;
- `tests/hypotheses/H05/test_h05_stage3_reader_report.R`: passed; 68 near-eye
  and 68 chest cells, zero retained associations, 26 bounded tables, seven
  accessible result figures, and all material diagnostic qualifications;
- `tests/hypotheses/H05/test_h05_preparation_report.R`: passed; 19 `gt`
  tables, required figure/caption/alt-text structure, 117 manifest identities,
  adjacent navigation, reciprocal links, source-data contracts, REPORT-011 QA,
  REPORT-013 applicability assessment, prohibited-call audit, and
  byte-identical source copy.

## Final identities

| File | SHA-256 |
|---|---|
| `audit/hypotheses/H05/H05_analysis_preparation.qmd` | `5ec4b2208e544edc30b2424cbee40f55a7eaafa6e54f415e4bcd4592b605d156` |
| `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.qmd` | `5ec4b2208e544edc30b2424cbee40f55a7eaafa6e54f415e4bcd4592b605d156` |
| `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.html` | `4216cb40b062c0db23882c0a3c6fbe739384f08646569a1b8e44b463112a7add` |
| `notebooks/hypotheses/H05.qmd` | `7923ec7a57b6c891dffb8d63eaeda3db86346c88c278c69a2b70ca97b7bf0cd7` |
| `_build/nathealth/notebooks/hypotheses/H05.html` | `d47b0e1fd61fcf42bb624c94b761e9af7d3243023bf2f84df4ac4dac5f210615` |
| `scripts/hypotheses/H05/build_h05_reader_artifacts.R` | `8ceacea40010749e4f09933f376e45c6fbcd5730176af8eea696e581ed79e926` |
| `scripts/hypotheses/H05/build_h05_figure_readability_qa.R` | `35eae45b3ee715891eb1d9b503146dc1dd19651f4f11e2a8d5ebba2092421b87` |
| `scripts/hypotheses/H05/build_h05_preparation_report_manifest.R` | `b0922c85a805716f0d689475409f42ca015c0679d7dc576bacaa85b4b98a1105` |
| `tests/hypotheses/H05/test_h05_stage3_reader_report.R` | `cf2f8e0e5ebc1cff40f94f4192c6922dcd52d559a72f85c705f99adba162a5c7` |
| `tests/hypotheses/H05/test_h05_preparation_report.R` | `8cc08d0cb235bcf3d609690953549fb9de58ee95d93b7c4d087e8102fd708b7c` |
| `audit/hypotheses/H05/H05_figure_readability_qa.md` | `a3d59c052a604f6d689c31b1d894af6b073fcae264ca75c45012961696dcf835` |
| `artifacts/12_manifests/H05/H05_figure_readability_qa.csv` | `70d8fc9600dc96342adfb8cb003bf30c30720b8c3d15ba7822735d5ba0c63095` |
| `artifacts/12_manifests/H05/H05_figure_A4_proofs.pdf` | `c155c5fcefb744dc51ffb1728c00fbaa61ff88dcfaf1ac3fcbbba438b4bbce71` |
| `artifacts/12_manifests/H05/H05_stage3_artifacts.csv` | `f3ed8526b77c65b6738f413ecec7b3ab435bfb88117ddd963d6c040bbb6b0f9e` |
| `audit/handoffs/H05_stage3_handoff.md` | `2bff53ebdc7141a70352ff34d189d35f290c35c74598a7e2c9a0002953818e25` |
| `artifacts/12_manifests/H05/H05_preparation_report_manifest.csv` | `a7d3a70609abae04af1d00114fd913265319f5291ccbe3841b95328c002d1603` |
| `audit/decisions/h05_stage4_closure.md` | `8d4cfca6412a0496c0ad523ecb650770c2c408113524551a2b82719a03c3ed30` |
| `audit/ledgers/hypothesis_stage_gates.csv` | `53dff3fde2948aa25d72184bece32cd73665eec1b5567a83f13d68ea23d9d8d8` |
| `audit/ledgers/change_log.csv` | `ead6081f40e997f315fbf50375ee32da97a895a63ab4c48b8a9d8f8e65fe8cc0` |

## Final disposition

`H05-003` closes H05 with no further scientific gate. REPORT-011 through
REPORT-013 change only reader-facing display and reporting QA and do not reopen
that scientific closure. The
final manifest chain is non-circular: the Stage 3 handoff is outside its own
inventory, the Stage 4 handoff is outside the preparation manifest, and neither
manifest inventories itself. The original closure is committed as `b2f0415`;
the display-only follow-up is contained in the H05-only commit that includes
this handoff, and its non-circular Git identity is reported to the coordinator
outside the commit. The coordinator-owned `H05-003`/`CHG-084` checksum snapshot
predates these authorized new-rule changes and requires checksum-only
reconciliation; the accepted scientific closure remains unchanged.
