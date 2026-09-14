# Preparation reports worker handoff

Date: 2026-08-11

Branch: `rewrite/NH`

Status: **Preparations 01–07 rewritten; repaired gap-timing-unaware METRIC-010 provenance verified in Preparations 04 and 06**

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

## METRIC-010 amendment

The reader-facing reports now describe the author-approved daily MDER as the
arithmetic mean of viable one-minute melEDI/illuminance ratios. A minute is
viable only when both channels are finite and strictly positive. Production
uses a complete 1,440-position local wall-clock grid, averages fall-back
duplicates channel-wise before forming the ratio, leaves absent spring-forward
minutes missing, and retains MDER at the inclusive threshold of at least 720
viable ratios. Failure removes MDER only, not the participant-day or another
metric. No profile weight, profile gate, scale, or ratio of daily integrals is
part of the active method.

Preparations 04 and 06 report the stored current availability:

- primary near-eye: 702/816 participant-days, 137 participants, mean
  0.7238529, median 0.7239000;
- primary chest: 732/902 participant-days, 152 participants, mean 0.7565438,
  median 0.7494261;
- gap-timing-unaware near-eye: 687/811 participant-days available and
  124/811 unavailable, 137 participants, mean 0.7242573, median 0.7238676;
- gap-timing-unaware chest: 723/897 participant-days available and 174/897
  unavailable, 152 participants, mean 0.7567377, median 0.7495175.

The earlier 725 near-eye and 729 chest availability wording described the
incomplete first repin and is superseded by the independently verified counts
above. The repair changed only MDER: all 25,620 non-MDER participant-day cells
were exact, and all 618 × 47 site/daylight context values remained exact.
Historical ratio-of-integrals and profile-gate records remain identified as
historical METRIC-003 provenance and are not presented as the active method.

The active identities are:

- controlling decision:
  `1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de`;
- metric manifest:
  `7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43`;
- independent MDER audit manifest:
  `5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb`;
- repaired gap-timing-unaware manifest:
  `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935`;
- repaired participant-day RDS:
  `7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1`;
- repaired MDER-support RDS:
  `a0bc5d7ea2142709412da2253158086416ddb730b0f60ff616bba9d6ccb1edc5`;
- independent gap-repair evidence manifest:
  `81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018`;
- shared-model-input manifest:
  `b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09`;
- shared-model input bundle:
  `168f25e18b6e494aa7a0272923041ad8249e25adb9ff3742d22e2f4cacf1bdf8`;
- site-context manifest:
  `959e7a1ff1e659ad3eb673c4d4b827da0b02b8a0a779e2647459638c4dac1045`;
- pre-analysis comparison manifest:
  `f90ea36334b59821101ef36de50d5d84dcfc6e8bee23f1f918be10fb2247724e`;
- downstream rebuild evidence manifest:
  `408087d420999322628066caae31efc288a5a5213b8b57d4b9a4ad77c9ec9a77`.

No preparation builder, scientific verifier, H01–H11 computation, model,
prediction, bootstrap, simulation, or downstream scientific computation was
run for this documentation amendment. The reports read only the stored
refreshed artifacts and verification summaries.

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
- Clarified under METRIC-010 that the paired-channel map is historical and
  current MDER does not use reference-profile weights, scales, or gates.
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
  local-clock planes, bin rules, thresholds, dose correction, current MDER,
  M10/L10 searches, metric-specific availability, state support, gaps, and
  daylight-saving handling.
- Added 13 `gt` tables, separated gap and daylight-saving summaries, and
  added a final-size current-MDER availability figure paired with
  `artifacts/08_diagnostics/mder_METRIC-010/verification_summary.csv`.
- Added the exact production, independent-verification, audit-finalization,
  repaired gap-timing-unaware reconstruction/evidence, stored-output, and
  manifest sequence for METRIC-010.
- Replaced the incomplete first-repin 725/729 availability with the verified
  687/723 flow and recorded 124/174 unavailable days, current summary
  statistics, and exact preservation of 25,620 non-MDER cells.
- Applied PREP-003 after METRIC-010: current metric values and MDER pass
  independent verification; FIND-044 remains open only for the current
  diary-period support manifest.

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
  with bounded reads of accepted manifest and evidence bundles.
- Explained normalized questionnaire/diary structures, incomplete intervals,
  the separate gap-timing-unaware dataset, site/daylight joins, elapsed-time
  provenance, shared near-eye/chest samples, H01 prepared frames, manifest
  identities, and exact hypothesis handoffs in 17 `gt` tables.
- Added the current MDER rule, availability, invariant checks, current metric
  and base-manifest identities, input-bundle identity, and independent audit
  evidence without reading a downstream hypothesis result.
- Added the repaired gap-timing-unaware MDER reconstruction and downstream
  repin evidence, including 687/723 available days, 124/174 unavailable days,
  exact preservation of 25,620 non-MDER cells, and exact preservation of all
  618 × 47 site-context values.
- Clarified that prepared-frame counts are not fitted-model samples and that
  metric-support hours are derivation support rather than observations.
- Repaired the owner-identified Table 13 problem by replacing the narrow
  four-column script map with a broad two-column execution map; the narrative
  column now has 62% of the table width.
- Extended that execution map to 13 labeled provenance steps. A rendered-HTML
  regression check rejects missing stage labels.
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
  `423cae8946a50bd6e611ff14708b7ff0543546f3fdc9e9fa030ca917838d75ce`;
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

That table records the accepted pre-METRIC-010 rewrite closure. The initial
METRIC-010 amendment used a new exact scoped specification at
`audit/preparation_reports/preparation_reports_metric010_scope_spec.csv`
(preceding SHA-256
`1c96c606df058f5a2a4dde526ce2f06367427cfe3676e15bd5e5c33d07aae1ee`).
Its pre-edit reconciliation preserved the original evidence and found exactly
six expected mismatches—the three task-owned QMD sources and their three
focused tests—while the other 211 paths were unchanged. No scientific or
shared preparation input differed.

| Amended page | Scoped paths | Final baseline SHA-256 | Post-render result |
|---|---:|---|---|
| Preparation 03 | 29 | `a83ec4412aa89efac712b5ad8e9a31de14f609bde56d83a847de5a3bde4edfeb` | 29 unchanged |
| Preparation 04 | 66 | `8103e9b29d9523f4d0e09134b3c7831e67dff75f4cffe61f3d934846ebc063d8` | 66 unchanged |
| Preparation 06 | 141 | `5c1da24014311d43a1d39bbb3f1dbb9c6795ea75fe893126822e9791efefdccc` | 141 unchanged |

The three final comparisons are stored in:

- `audit/preparation_reports/preparation03_metric010_postrender_scoped_verification.csv`;
- `audit/preparation_reports/preparation04_metric010_final_postrender_scoped_verification.csv`;
- `audit/preparation_reports/preparation06_metric010_final_postrender_scoped_verification.csv`.

The handoff-time repetitions are stored in the corresponding
`preparation03_metric010_handoff_scoped_verification.csv`,
`preparation04_metric010_handoff_scoped_verification.csv`, and
`preparation06_metric010_handoff_scoped_verification.csv` files; all again
reported zero mismatches.

The repaired gap-timing-unaware continuation expanded that specification with
the exact repair and downstream-repin evidence read by Preparations 04 and 06.
The current specification SHA-256 is
`96d7e7bd627bb63515ba9388893518fc38f1cf5af04d7193685b288a4acdafc8`.

| Repaired page | Scoped paths | Final baseline SHA-256 | Post-render result |
|---|---:|---|---|
| Preparation 04 | 93 | `0111323dd0df3329ea5637b91f937e538fc2a49a20dbfb358664b90212e53b78` | 93 unchanged |
| Preparation 06 | 157 | `89d328b95417e71ca989b21de2a90b2dcd4afe2c7d2f28ae3b856b50a13de8e8` | 157 unchanged |

The final comparisons are stored in
`preparation04_gap_repair_postrender_scoped_verification.csv` and
`preparation06_gap_repair_layoutfix_postrender_scoped_verification.csv` under
`audit/preparation_reports/`. Handoff-time repetitions use the corresponding
`preparation04_gap_repair_handoff_scoped_verification.csv` and
`preparation06_gap_repair_handoff_scoped_verification.csv` paths. These gates
cover page sources, exact scientific/preparation inputs, described producing
code, relevant decisions/contracts, the project environment, and render
configuration; unrelated downstream work remains excluded.

The settled shared identities at the pre-amendment rewrite closure were:

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
| 03 | `d63499f95a39e3fbc335aef3a5f98439f14c24a27406e15a49c99ef79fb4119d` | `28f8f68e87d391faa6c45269dfc267165fa0cd3299e95603c11f220fba120841` | `aab4d78311fc1037975b70c65515d133182367c7da373ed5aae2c1440711d7e0` |
| 04 | `117aad216c96131b41dc450f74e77ef8a3b7b5e3b9112e435100f19b0539c1de` | `b8b40d1e60b065256d12c7f070d5751c9ff603048f743b094ec45e73b78a8033` | `71517017ed87dc6e3215058002f7effac7d870b8f1d01ed3d26a48be62c5598a` |
| 05 | `ee1910eacbd23329d651a160450d02041cbd175869a56963ac14caef24e7d95e` | `c7a38c0b8c66b52776f307640198586a7ed22b95fd87c7c3f123a38e8594b7c2` | `1e3cddd7e66168159e5fb97564aa3fa274fb760571265bd0c6eb84597b72291d` |
| 06 | `8b32ad4b3fcc9feb14993a33832819828426382bffd4ea0c34d1e2b8de85d4c1` | `ee0b3fd709afbcd2c66e15dd1faa3bc0ce7a10857596ac8a96d8ac4cae848396` | `0430d346db5acf488b49b80324af090272cae4fefced444f385100bc092bb9e7` |
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
- **FIND-044 / PREP-003:** METRIC-010 resolved the item for the current metric
  manifest and MDER. Exact independent reconstruction remains open only for
  the current diary-period support manifest
  `755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619`.
  The ratio-of-integrals support manifest
  `9ca9b97dac5efd9ec4e7b43a1fb2227b7a13cf98ac4b92318606c4874f9e460b`
  is historical and is not an active current-MDER gate.

Neither open provenance item is evidence that the current data or downstream
results are wrong. This task did not run the relevant scientific verifiers or
builders.

## Out-of-scope files

This task did not edit `notebooks/placement_decision.qmd`,
`notebooks/descriptives.qmd`, any H01–H11 file, shared Quarto
configuration, central ledger, manuscript file, or `renv.lock`. No change
to either excluded notebook is recommended from this preparation-report
rewrite.

## METRIC-011 preparation-report follow-up — 2026-08-12

### Outcome and bounded scope

Preparations 04 and 06 were the only reader-facing preparation pages that
describe offset geometric means, L10 numerical-zero handling, or preparation
identities changed by METRIC-011. They were updated and rendered from sealed
outputs. No preparation builder, scientific verifier, H01–H11 computation,
model, prediction, autocorrelation estimate, bootstrap, simulation, or
Shapley calculation was run. Preparations 01–03, 05, and 07 were not changed
or rerendered for this follow-up.

Rendered review files:

- `_build/nathealth/notebooks/preparation/04_metric_derivation.html`;
- `_build/nathealth/notebooks/preparation/06_model_ready_datasets.html`.

### Preparation 04 changes

- Explained the active offset-geometric-mean calculation, the
  source-verified tolerance, the exact-source-zero requirement, and why
  missing minutes remain missing rather than becoming zeros.
- Added a compact L10 evidence table with three near-eye, five chest, and
  eight total positive-roundoff reclassifications. The visible text records
  seven 600/600 zero windows and one chest window with 547 observed zeros and
  53 missing minutes.
- Stated that all 816 near-eye and 902 chest participant-days retain L10,
  every non-L10 scientific value and every sample is unchanged, and rendering
  does not run a hypothesis model.
- Added `audit/scripts/finalize_l10_METRIC_011.R` and
  `scripts/pipeline/verify_metric_derivation_core.R` to the execution-order
  map, named all stored evidence files, and separated current METRIC-011
  evidence from the MDER audit tied to preceding metric manifest
  `7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43`.

### Preparation 06 changes

- Added a reader-facing L10 handoff section explaining the same source-zero
  rule and the exact effect on prepared inputs. It states that the eight
  primary L10 values propagate into shared primary inputs and H01 primary
  prepared rows without changing a sample or contract; the
  gap-timing-unaware scientific values are unchanged.
- Added a three-column evidence/sample table with 15%/18%/67% widths and a
  two-column provenance table with 32%/68% widths. Paths and hashes have
  explicit wrap opportunities. The execution map remains a broad 38%/62%
  two-column display and now contains 14 fully labelled rows, avoiding the
  narrow narrative cell previously rejected by the owner.
- Added the METRIC-011 finalizer as the last provenance step, listed the core
  and MDER verifiers it called during the already-completed shared rebuild,
  and identified the seven-file evidence manifest. The earlier METRIC-010
  downstream-repin bundle is visibly version-bound rather than presented as
  current identity evidence.
- Updated the site/context, base, H01 primary, H01 gap-timing-unaware, and
  preanalysis manifest identities. No fitted H01 result is read or displayed.

### Current sealed identities

| Record | SHA-256 |
|---|---|
| METRIC-011 decision | `23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797` |
| METRIC-011 evidence manifest | `a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb` |
| Metric manifest | `028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e` |
| Site/context manifest | `c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518` |
| Base-model-input manifest | `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce` |
| Base input bundle | `e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916` |
| Near-eye participant-day context RDS | `013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a` |
| Chest participant-day context RDS | `497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057` |
| H01 primary preparation manifest | `25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72` |
| H01 gap-timing-unaware preparation manifest | `e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b` |
| Preanalysis comparison manifest | `f3c4bfbf120d2023c045b44e3c7c04c58bce1f8d11621956bca1e5ede90c5623` |

The gap-timing-unaware preparation manifest remains
`4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935`;
METRIC-011 changed none of its scientific values.

### Structural, render, and display verification

- `tests/test_preparation04_report.R`: source and rendered HTML **PASS**;
- `tests/test_preparation06_report.R`: source and rendered HTML **PASS**;
- both tests reject producing calls, writes, model fitting, prediction,
  resampling, simulation, missing METRIC-011 rules, missing provenance paths,
  missing stage labels, raw tibble output, and prohibited visible dataset
  labels;
- Preparation 04 HTML SHA-256:
  `461e4605ff967690b6fc779a2f4381a8f19936bcd6aa48c4c091774b6437664c`;
- Preparation 06 HTML SHA-256:
  `8211aff02f0f886211347e1d363d721036bb08017bc06b773dacfd36320cd401`;
- Preparation 04 source/test SHA-256:
  `0de19fc8bdd68ff24c35dfb621d819f3cc6c6bacc532be8fc1b8b3b3242ac668`
  and
  `bab6b85bcd7c445c41681231ce84e1420816a7cc5887883b90e27534ae92080d`;
- Preparation 06 source/test SHA-256:
  `434b5e7ae4839b248b457253bb581ba867cbaa933dda0ba568a47645c092358b`
  and
  `e4b02061832be158372b54e1c473e0f221ab84cdd0aa7fb38e7d41cfb82f6f51`.

The scientifically unchanged figures were directly inspected at their
generated sizes. Preparation 04's 1,382 × 806 pixel MDER figure and
Preparation 06's 2,160 × 1,958 pixel site-composition figure have no clipping,
overlap, distortion, awkward wrapping, compressed labels, or
indistinguishable marks. Their unchanged SHA-256 values are
`423cae8946a50bd6e611ff14708b7ff0543546f3fdc9e9fa030ca917838d75ce`
and
`058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da`.
Automated inspection of the local HTML page itself was blocked by the
browser's `file://` safety policy; final HTML structure confirms the declared
column groups, explicit path wrapping, and resolved table labels.

### Scoped checksum proof

The original whole-checkout failure evidence and all earlier amendment
baselines remain preserved. The METRIC-011 scope specification is
`audit/preparation_reports/preparation_reports_metric011_scope_spec.csv`,
SHA-256
`c7b0759b90b6453f34b3b7791856735ffb4bcc782ba04c0a24b44dda18069ad8`.
The complete per-file sizes and SHA-256 values are recorded in the two scoped
inventories:

| Page | Scoped paths | Baseline SHA-256 | Immediate/post-render/handoff result |
|---|---:|---|---|
| Preparation 04 | 106 | `3fed8439a84138b77300081f6bbce5f34df381b122f5c6a919587baac24ec0e4` | 106 unchanged; 0 mismatches |
| Preparation 06 | 168 | `f03f6a9e7eccba3b4cbdbd8dc494b44b48adb583c73f5d9fa93556412260fe30` | 168 unchanged; 0 mismatches |

Post-render and handoff comparisons are stored as:

- `audit/preparation_reports/preparation04_metric011_postrender_scoped_verification.csv`;
- `audit/preparation_reports/preparation04_metric011_handoff_scoped_verification.csv`;
- `audit/preparation_reports/preparation06_metric011_immediate_prerender_verification.csv`;
- `audit/preparation_reports/preparation06_metric011_postrender_scoped_verification.csv`;
- `audit/preparation_reports/preparation06_metric011_handoff_scoped_verification.csv`.

These gates cover the exact page sources, focused tests, scientific and
preparation artifacts read, manifest members, described production and
verification scripts, decisions, environment identity, and Quarto
configuration. They prove that the documentation renders did not change any
protected input or accepted scientific artifact. Unrelated concurrent work
outside these exact read sets is recorded in
`audit/preparation_reports/excluded_concurrent_work.md` and was not treated as
a preparation failure.

### Remaining scientific questions

METRIC-011 introduced no new unresolved scientific discrepancy. The existing
state-support reconstruction qualification remains version-specific and is
not evidence that the current data or downstream results are wrong. FIND-043
for the current reference-profile manifest is unchanged and unrelated to this
follow-up. No new shared-change request is required.
