# Preparation reports worker handoff

Date: 2026-08-01

Branch: `rewrite/NH`

Status: **Preparations 01–07 rewritten and verified**

## Outcome

The seven data-preparation reports now function as scientific
analysis-preparation and provenance companions. Each starts with its purpose,
exact inputs, and position in the data-to-analysis chain; explains the
producing scripts in execution order; shows meaningful stored intermediate
outcomes and validation evidence; and identifies the exact artifacts passed
forward.

Rendering is documentation-only. Executable chunks read stored outputs,
perform bounded identity/schema checks, and calculate lightweight descriptive
summaries for display. They do not call a builder or production scientific
verifier and do not recreate or overwrite an accepted preparation or
hypothesis artifact.

Preparations 01–06 were rendered sequentially under the final settled
`nathealth` profile. Preparation 07 retained its already verified render, as
directed by the coordinator.

## Rendered review files

| Report | Source | Rendered HTML |
|---|---|---|
| Preparation 01 | `notebooks/preparation/01_import_state_alignment.qmd` | `_build/nathealth/notebooks/preparation/01_import_state_alignment.html` |
| Preparation 02 | `notebooks/preparation/02_coverage_sample_flow.qmd` | `_build/nathealth/notebooks/preparation/02_coverage_sample_flow.html` |
| Preparation 03 | `notebooks/preparation/03_reference_profiles.qmd` | `_build/nathealth/notebooks/preparation/03_reference_profiles.html` |
| Preparation 04 | `notebooks/preparation/04_metric_derivation.qmd` | `_build/nathealth/notebooks/preparation/04_metric_derivation.html` |
| Preparation 05 | `notebooks/preparation/05_model_input_acquisition.qmd` | `_build/nathealth/notebooks/preparation/05_model_input_acquisition.html` |
| Preparation 06 | `notebooks/preparation/06_model_ready_datasets.qmd` | `_build/nathealth/notebooks/preparation/06_model_ready_datasets.html` |
| Preparation 07 | `notebooks/preparation/07_example_days.qmd` | `_build/nathealth/notebooks/preparation/07_example_days.html` |

## Cross-report presentation changes

- Replaced implementation-led openings with direct statements of purpose,
  exact stored inputs, position in the Preparation 01–07 sequence, and exact
  handoff artifacts.
- Added an informational note to every page stating what is calculated during
  render and what is read from externally produced stored outputs.
- Added accessible Mermaid diagrams only where they clarify the preparation
  chain.
- Explained production drivers and function modules in execution order:
  what each reads, does, why it is separate, and what it writes.
- Replaced raw console, tibble, and `kable` output with 78 semantic `gt`
  tables across the seven pages.
- Split narrative-heavy or excessively wide tables into compact scientific
  comparisons. Production maps use broad two-column layouts so explanatory
  prose does not occupy a narrow residual cell.
- Added stored intermediate outcomes, sample-flow counts, coverage and
  missingness summaries, units, state/time handling, validation evidence,
  file identities, and exact forward artifacts as appropriate to each page.
- Applied submitted-manuscript site names, order, and colours; `melEDI`;
  “period” rather than “bout”; and the approved dataset terminology.
- Used “gap-timing-unaware dataset” for the predefined sensitivity and gave
  the required first-use explanation. Historical scenario identifiers remain
  only in exact internal provenance paths.

The page-specific records
`audit/preparation_reports/preparation01_clarity_changes.md` through
`preparation07_clarity_changes.md` contain the full traceable wording,
structure, meaning-invariant, and display ledgers.

## Page-specific changes

### Preparation 01 — import and state alignment

- Replaced live import/alignment production calls with reads of accepted
  manifests and stored audits.
- Explained fixed releases, actual versus local time, one-minute aggregation,
  diary-defined sleep, true non-wear, the strict 100,000 lx melEDI operating
  limit, placement separation, participant/day/minute accounting, and the
  exact aligned artifacts.
- Reorganized the page into 14 compact `gt` tables; the one remaining
  multi-column site table preserves a scientifically useful near-eye/chest
  comparison.

### Preparation 02 — coverage and sample flow

- Replaced the coverage builder with direct reads of stored settings, hourly
  and daily decisions, reason-coded unavailable periods, and sample flow.
- Distinguished the 50%-per-hour rule from the 80%-per-day rule, retained
  diary sleep in the daily denominator, explained the all-zero-day screen and
  repeated-clock handling, and showed site/sample-flow outcomes.
- Reorganized the evidence into 11 `gt` tables.

### Preparation 03 — reference profiles

- Replaced reference-profile learning with direct reads of the accepted
  profiles, timing distributions, support files, and relevance maps.
- Explained participant balancing, actual-time versus local-clock handling,
  strict-threshold timing, support minima, unsupported periods, no
  interpolation, and which maps may alter values versus only assess support.
- Added 11 `gt` tables and one final-size figure of stored pooled melEDI and
  illuminance profiles, paired with
  `artifacts/04_reference_profiles/reference_profiles.csv`.
- Applied PREP-002: the 394-of-394 independent reconstruction is attributed
  only to preceding manifest
  `c8e02302521360d3a5cb18f49e0a97aed4a1f0ea64343ead68bde274cddce10d`;
  FIND-043 remains open for the current manifest.

### Preparation 04 — metric derivation

- Replaced the state-support, MDER-support, and metric builders and verifier
  with reads of current stored outputs.
- Explained the hybrid wake/bedside-sleep measurement, UTC elapsed-time and
  local-clock planes, bin rules, thresholds, dose correction, MDER,
  M10/L10 searches, metric-specific availability, state support, gaps, and
  daylight-saving handling.
- Added 13 `gt` tables, separated gap and daylight-saving summaries, and
  added a final-size MDER-retention figure paired with
  `artifacts/08_diagnostics/mder_support_gate/mder_support_candidate_summary.csv`.
- Applied PREP-003: earlier complete metric and MDER verifications remain
  tied only to their earlier manifests and samples; FIND-044 remains open for
  the three current manifest families.

### Preparation 05 — model-input acquisition

- Replaced disabled production snippets with direct reads of the acquisition
  manifest, fixed registries, and stored object/column audits.
- Explained the complete 9-site by 7-modality grid, fixed release/commit/DOI
  identities, exact sleep-diary reuse, the scoped TUM exercise-diary
  correction, cache outcomes, and the fact that acquisition does not clean,
  score, recode, combine, normalize, or filter source values.
- Added nine `gt` tables, including the 63/63 acquisition outcome and
  provenance-preserving object/column checks.

### Preparation 06 — model-ready datasets

- Replaced every normalization, assembly, context, temporal-provenance,
  model-data, H01-frame, and descriptive-comparison producer/verifier call
  with bounded reads of eight accepted manifest bundles.
- Explained normalized questionnaire/diary structures, incomplete intervals,
  the separate gap-timing-unaware dataset, site/daylight joins, elapsed-time
  provenance, shared near-eye/chest samples, H01 prepared frames, manifest
  identities, and exact hypothesis handoffs in 13 `gt` tables.
- Clarified that prepared-frame counts are not fitted-model samples and that
  metric-support hours are derivation support rather than observations.
- Repaired the owner-identified Table 13 problem by replacing the narrow
  four-column script map with a broad two-column execution map; the narrative
  column now has 62% of the table width.
- Added one stored-data site-composition figure with all nine sites, direct
  counts, registered colours, alt text, caption, and paired
  `artifacts/08_diagnostics/preanalysis_comparison/categorical_levels.csv`.

### Preparation 07 — example days

- Replaced the fixed-seed scientific verifier with bounded reads of its stored
  selection, settings, source data, and manifest.
- Explained explicitly that the showcase is a display-only inspection and
  that none of its selections, source data, or figures enters H01–H11.
- Added seven `gt` tables and split the accepted 3-by-3 visual into three
  readable three-panel HTML figures drawn from the unchanged
  `artifacts/11_source_data/prepared_day_showcase.csv`.

## Figure and layout QA

REPORT-011 was applied at final display size.

- Preparations 01, 02, and 05 contain no empirical reader-facing figure.
- Preparations 03 and 04 use 9 pt axis/legend text and 10 pt titles/facet
  text; their stored-data figures passed clipping, overlap, wrapping, unit,
  balance, and distinguishability checks.
- Preparation 06 uses 9–10 pt axis, count, and facet text. Horizontal facets
  prevent the long dataset label from compressing the data region.
- Preparation 07 uses 9–10 pt typography across three balanced panels per
  row. A 900-pixel final-width inspection found no clipping, overlap,
  distortion, awkward wrapping, broken units, or indistinguishable marks.
- Every durable figure has an informative caption, specific alt text, and a
  paired source-data CSV link.

Rendered figure SHA-256 values:

- Preparation 03:
  `b011c1ac17cc1cb05bfda58170371fa8c49813b277e0455f65373a60447a9923`;
- Preparation 04:
  `43f026b8b27e4ca687b843df7d594b2925c1df706c152c365b0bb778d26d55fa`;
- Preparation 06:
  `058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da`;
- Preparation 07:
  `ad6ee88b1df7a0b2f17d513825d74887cc009b74317ae23d43bb16a14c2d9ad8`,
  `837d65b0f35f490e2c76ac4e170ebd633a349c4aff821fe82eae2be7ebb6b53d`,
  and
  `fd6f1cb73718674fdb6544e89bb684be0723bb33378709c399c4b161e1ec5629`.

## Scoped provenance and protected-file proof

The original 2,094-path whole-checkout baseline and its mismatch evidence are
preserved. It was intentionally overbroad for a shared checkout and detected
legitimate concurrent H01/H05/coordinator changes unrelated to the
preparation pages. History was not rewritten.

The coordinator therefore authorized exact page read sets. The final union is
`audit/preparation_reports/preparation_reports_final_scoped_baseline.csv`:
538 paths, SHA-256
`4b1ece912e6385ae3aa0a76efea296f54cf965df4f7599c384c28c45db4980f9`.
It covers every page source, file read by the page, manifest-listed accepted
preparation artifact, described production driver/module, relevant
decision/contract, environment identity, and shared render configuration.
The final handoff check found 538 unchanged paths and zero mismatches.

| Page | Scoped paths | Baseline SHA-256 | Final result |
|---|---:|---|---|
| Preparation 01 | 149 | `e905f08f77b2a362965db94795b0b8965ba0130b57f4f68942759c524980dbc6` | 149 unchanged |
| Preparation 02 | 32 | `e9c0893af93ee8b9794ef726b66895abea1f35d02d7306ca345d3c6771cbce5f` | 32 unchanged |
| Preparation 03 | 39 | `4a2246964c999d175474c09f63d63a3129bb7ad29f71ca18d10ed34df4335550` | 39 unchanged |
| Preparation 04 | 109 | `2ce1db192a0c7c32042e8e4477d6ee637519f09a5bb51c6300804f262ba237ac` | 109 unchanged |
| Preparation 05 | 128 | `c9aee2be47e89ccaf36759ce448c3b003421a185ceb19c5c86a4c06704c909ad` | 128 unchanged |
| Preparation 06 | 131 | `1f579c88474e710dbe862c3b69328642f38b875dece94a7d66f43f1da4d21d98` | 131 unchanged |
| Preparation 07 | 28 | `d969d3b04d817ab6de822bef34e38c09eb2f606df172e7796a1996858a9b2da7` | 28 unchanged |

The settled shared identities were:

- `_quarto-nathealth.yml`:
  `4b7ce91614a6d8f76f2526ced5aed3e2064fd2a70113018057b7a11b3916c803`;
- `audit/decisions/model_reporting.md`:
  `41fb454e42d9def6b905601ed9544d5cb447f8b38c3862723c07fd1834037134`;
- `audit/ledgers/finding_register.csv`:
  `7ad1fcfc6975226039fa7c4357e07e32615c5f91e821d884f05bf16f03ebe86b`.

Unrelated downstream hypothesis and descriptive changes outside the exact
read sets are recorded in
`audit/preparation_reports/excluded_concurrent_work.md`. They are not
inputs to these pages and are not described as evidence that the entire
shared checkout was static.

## Final source, test, and HTML identities

| Page | Source QMD SHA-256 | Focused test SHA-256 | Rendered HTML SHA-256 |
|---|---|---|---|
| 01 | `4708b90ba3dd56c21fad10d02be6a884890b668662f62631d762de1375b4f6c2` | `0237de70ff1659326b99e068d134b01d1927536fc6a805548ff3749a1160a337` | `6c45e5d23a25808c74f60677f5e3873bfdb2926cc0bfc8a6a9f4411e8d0ddeec` |
| 02 | `50c069f8e987087e89c09f4397d197a5754a9de067c955ae9e338a6beeafbfad` | `1a6fd5fb83fdefa7e7862c055fee71b6d6b9508a59b0a434b20936b51cea52c3` | `54f0c716963d5ce5736eb2b10817cee78c7a733762cacc9eb65005d7dcb452d9` |
| 03 | `963d81dc6365f0c03d69222563e5488afeebbab39dd58a1932067bd7cfd48ba2` | `8e60a2fab4410f6a5238e0d25c417ae3d91a31a2bf6e69e312f17d9339eed68d` | `ea612c208c7f1113dc2f95bebac47eb28f4505831888c74d1e4a716d917c0188` |
| 04 | `d2f4953eb26c5898aebd733ffe7f94edc0800050a9fb254976569a9409253133` | `d3772d1078a37f53ea7284a928b8f4fe86b3dbbcf1a0f521a9fb13a9ec673c12` | `2dda2e1db895668d37a5e17a5a1ca5e97156c2f2b1ebdb7fb19b674023394fe0` |
| 05 | `ee1910eacbd23329d651a160450d02041cbd175869a56963ac14caef24e7d95e` | `c7a38c0b8c66b52776f307640198586a7ed22b95fd87c7c3f123a38e8594b7c2` | `1e3cddd7e66168159e5fb97564aa3fa274fb760571265bd0c6eb84597b72291d` |
| 06 | `9ef9cfa3c72b4a52cae7339cc56173e92d63a8343d12a490090b06e37b8a35a7` | `96312cc12fc4d962dc705ab4ff16548aff7c95c6ec9d7a64e1108718a31745ce` | `295eec709d2720a3d504c0755d036265dfd618447775ee15bcf9a95a5856bb4f` |
| 07 | `fbb37a1e0d209c58a33d53e121a00921cedf4ccfa03be104d76302ff2023302e` | `be2505e1960ffb6ebbe1bdbc675fdd2da37e036a1eeb797e5c709f32f191fd2f` | `e37609f5adab0a5b57ce96d0229e4bac07dae3c713fe28aca3da68066ba12bdc` |

## Tests and execution boundary

All seven focused source/HTML tests passed:

```text
tests/test_preparation01_report.R
tests/test_preparation02_report.R
tests/test_preparation03_report.R
tests/test_preparation04_report.R
tests/test_preparation05_report.R
tests/test_preparation06_report.R
tests/test_preparation07_report.R
```

These tests reject builders, production scientific verifiers, writes,
downloads, model fitting, prediction, autocorrelation estimation, resampling,
simulation, Shapley computation, raw table output, missing terminology,
inaccessible figures, and absent source-data links as relevant to each page.

Render environment: R 4.6.1, Quarto 1.9.37, project library, and the
`nathealth` profile. No package was installed or updated. No full-project,
Word, hypothesis, descriptives, placement, manuscript, or supplementary
render was run.

## Open audit items

- **FIND-043 / PREP-002:** current reference-profile manifest
  `5e08099602682a4b951b0304764f341932ef2f03ccd4c62f32793ea82084e062`
  has current identity and stored-support checks, but no stored independent
  reconstruction tied to that exact identity. The 394-of-394 result belongs
  only to the preceding manifest named above.
- **FIND-044 / PREP-003:** current metric
  (`6ec3185620d921e1f81b8464e850249613deb823988187d58794b3471303f4e8`),
  MDER-support
  (`9ca9b97dac5efd9ec4e7b43a1fb2227b7a13cf98ac4b92318606c4874f9e460b`),
  and state-support
  (`755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619`)
  manifests do not have one stored independent reconstruction tied to all
  three current identities.

Neither open provenance item is evidence that the current data or downstream
results are wrong. This task did not run the relevant scientific verifiers or
builders.

## Out-of-scope files

This task did not edit `notebooks/placement_decision.qmd`,
`notebooks/descriptives.qmd`, any H01–H11 file, shared Quarto
configuration, central ledger, manuscript file, or `renv.lock`. No change
to either excluded notebook is recommended from this preparation-report
rewrite.
