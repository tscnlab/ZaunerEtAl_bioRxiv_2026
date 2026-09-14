# H02 final analysis and H11 inheritance

Decision ID: `H02-MODEL-001`  
Date: 2026-08-01  
Status: approved and verified

## Decision

Accept `h02_nh_v2_sz` as the final H02 implementation. Near-eye measurements
are primary and chest measurements are complementary. H11 may inherit the
frozen temporal specification and sequence-provenance rules, but not H02
fitted values.

The fitted response is the 30-minute arithmetic mean melEDI on the
`log10(melEDI + 0.1 lx)` scale. The model contains a cyclic common daily
smooth, sum-to-zero site-specific time deviations, participant-specific time
curves, a participant-day random intercept, and the boundary-aware AR(1)
working correlation. The selected formula and all comparison formulas are
stored in `artifacts/07_models/H02/selected_temporal_model_specification.csv`
and the H02 contract.

The exact primary samples are:

- near eye: 141 participants, 816 participant-days, 37,756 30-minute
  observations, and 9 sites;
- chest: 154 participants, 902 participant-days, 41,842 observations, and
  8 sites.

The placement-matched sensitivity, previously called the common-bin sample,
contains identical site, participant, local-date, and 30-minute clock keys
with admissible finite values at both placements. Each placement is fitted
separately. It contains 112 participants, 643 participant-days, 29,786
observations, and 8 sites at each placement.

## Interpretation retained

The fitted-curve participant/site ratio is 1.797 (95% CI 1.157 to 4.332) near
eye and 1.465 (0.973 to 3.179) at chest. After adding participant-day
intercept variation, the corresponding ratios are 1.991 (1.291 to 4.767) and
1.809 (1.219 to 3.736). These quantities describe model-implied fitted
variation on an equal-site clock grid; they are not observed variance
explained, unique variance explained, or causal variance decomposition.

Conditional Shapley allocation of in-sample model fit supports the same
ordering more strongly, but remains a descriptive fitted-model relevance
analysis rather than predictive validation. The participant/site ratios are
6.410 (3.846 to 15.136) near eye and 5.687 (3.723 to 10.678) at chest; the
participant-plus-day/site ratios are 9.494 (5.767 to 21.810) and 9.023 (6.006
to 17.027).

The combined participant-plus-day ordering is stable across preparation,
model-form, placement, and placement-matched checks. Participant-only
ordering is less stable because the chest and placement-matched confidence
intervals include one.

## Global time-basis diagnostic

A diagnostic-only comparison changed only the common time basis from cyclic
cubic (`bs = "cc"`) to the default thin-plate basis (`bs = "tp"`). It used
the exact accepted samples and the same transform, site, participant,
participant-day, sequence boundaries, and rho-estimation algorithm. No
bootstrap, fitted-variation analysis, Shapley allocation, or Quarto render was
run.

The non-cyclic alternative increased AIC by 5.988 near eye and 4.732 at chest,
left residual summaries essentially unchanged, and weakened midnight
continuity. Retain the cyclic common time smooth. The H02 primary fits and the
H11 inheritance specification are unchanged.

## Figure follow-up

The standalone Figure 1 assets were updated without refitting:

- site curves are Panel B and participant curves are Panel C;
- per-site participant-day counts appear at approximately 15:00 and 0.28 lx
  in Panel B, centred and formatted as `n = xxx d`;
- fitted values and intervals are unchanged.

The display-only follow-up was initially kept out of the rendered report. The
later website-integration pass rerendered the result and preparation pages
without refitting, so the current H02 HTML now uses these updated assets. The
current standalone PNG hashes are
`2d31f38a169659b37a16c44b9845605186709e4dc7734a8f97342408711f9ac2`
for near eye and
`a82659874f9246b27e8cc25733b7a8236bbf8327d67f6378f868cc8f9c2f2cb1`
for chest.

## Reader-facing preparation-page revision

The preparation and provenance page now addresses an ordinary scientific
reader. Internal step numbers, task roles, approvals, and coordination
mechanics were removed, and the opening explanation is presented as a note.
The scientific result report and shared Quarto configuration were unchanged.

The response-distribution figure separates exact-zero observations from the
histogram of positive observations. The near-eye frame contains 12,107 exact
zeros among 37,756 observations (32.1%); the chest frame contains 13,799 among
41,842 observations (33.0%). Thus, the histogram y-axis describes positive
observations only, while an accompanying summary reports the zero mass. The
paired source-data CSVs are recorded in the provenance section below. This is
a descriptive-display clarification: the accepted models continue to include
the exact-zero observations through the stated transformed response.

## Candidate response-family sensitivities

No alternative response family was fitted in the display follow-up. A
Tweedie model with a log link is the strongest candidate for a single-model
sensitivity to the approximately 32--33% exact-zero continuous response. A
two-part hurdle model would be more directly interpretable only if the
occurrence of zero exposure is treated as a scientifically distinct process.
A scaled-t model could assess tail robustness. A Gaussian location-scale
model is less practical here and does not address the point mass at zero.

These are candidates for a separately approved sensitivity stage. They do
not change the accepted H02 model, its diagnostics, its results, or the H11
inheritance specification.

## Completed reader-facing reporting touchpoint

The final reporting pass applied `REPORT-008` through `REPORT-011` without
refitting a model or rerunning a bootstrap, simulation, prediction, or Shapley
analysis.

- Raw and adjusted p-values use the shared formatter, with the stated
  significance rule applied before display formatting.
- Both reader-facing pages define and use **gap-timing-unaware dataset**. The
  first definition states that the general 50%-per-hour and 80%-per-day rules
  still apply and that only the timing of remaining gaps is omitted from
  additional metric-specific adjustment. Internal run IDs and artifact paths
  remain unchanged.
- The direct placement display overlays separately fitted near-eye and chest
  site curves for the exact matched sample of 112 participants, 643
  participant-days, 29,786 observations, and 8 sites. Its component pointwise
  intervals are not intervals for the between-placement difference, and
  visual concordance is not evidence of equivalence.
- All nine reader-facing figures passed final-size typography and layout QA.
  The only required repair widened the preparation heatmap colour bar and
  moved its title above the bar to prevent overlapping percentage labels.

The 768-row placement-display source data, six-row display manifest, and
figure-QA manifest are included in the final non-circular H02 inventory.

## Provenance and verification

- Nature Health profile:
  `_quarto-nathealth.yml`, SHA-256
  `516ac36aee8bce6d29fc2c7df91a1e41d0d2bb078256be49b695c7622408c8e7`
  at the final H02-only render;
- result source:
  `notebooks/hypotheses/H02.qmd`, SHA-256
  `d2cc99a30ee9e6c8ece97e55bee05f4ff6d930fd10557a2407ff58f5335aaac1`;
- result HTML:
  `_build/nathealth/notebooks/hypotheses/H02.html`, SHA-256
  `df73f2f87d6d3bdc9acd44493a113e18b510884f0ecb8e2214b39dc3d71cb164`;
- preparation and provenance source:
  `audit/hypotheses/H02/H02_analysis_preparation.qmd`, SHA-256
  `52a1b3b85c4a375c44c0a2a83f542ea2663c7d233a6de18ed689cb2b7a0be557`;
- preparation and provenance HTML:
  `_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html`,
  SHA-256
  `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa`;
- positive-response display source data:
  `artifacts/11_source_data/H02/preparation_response_distribution_positive_observations.csv`,
  SHA-256
  `22dff3af0f213b3ceaed0d5ca827da4184b662ff7d0366d592b6598b56e96842`;
- exact-zero display summary:
  `artifacts/11_source_data/H02/preparation_response_distribution_exact_zero_summary.csv`,
  SHA-256
  `f2cc126a168bf8d6db3c5b13b3c6fea83030b23e7fdebff882bea1eb390f31db`;
- matched-placement curve source:
  `artifacts/11_source_data/H02/paired_placement_site_curves.csv`, SHA-256
  `3bc65cdd98bb8e71c5bc6f586e0aab966a929cc6b47df25b8e6eaf1376f5c5c8`;
- matched-placement display manifest:
  `artifacts/12_manifests/H02/H02_paired_placement_display_manifest.csv`,
  SHA-256
  `fffcffcecc79196a11515ff74c56b8293fbea9ee2368b4b71b6c39cddeb65753`;
- figure-readability QA manifest:
  `artifacts/12_manifests/H02/H02_figure_readability_qa.csv`, SHA-256
  `f0898eeab659591109954f453f78ef5f5b783415cce015c79c1ce17c72a43814`;
- 57-item preparation-report manifest:
  `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv`, SHA-256
  `c2e8c5a3b4fcebe53f3f813aa75fac6d3d960384333f59dd1b1501d90b08aaf7`;
- authoritative handoff:
  `audit/handoffs/H02_worker_handoff.md`, SHA-256
  `0cf26a7038e7c49dc8e9790798b5ed3e1d01a5431cf0e1d8845b02892b96bc94`;
- 192-file non-circular inventory:
  `artifacts/12_manifests/H02/H02_worker_output_hashes.csv`, SHA-256
  `0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331`;
- all 57 preparation identities and all 192 worker identities were
  independently reverified;
- all ten H02 tests and the shared p-value helper test passed in fresh R 4.6.1
  project-library sessions;
- the bounded project-environment check reported synchronized.

The H02-owned source changes are committed as `61bc807` (`Complete H02
daily-pattern analysis`). Generated artifacts and website outputs remain local
and ignored but are covered by the manifests above. The reporting pass changed
wording and displays only; accepted fitted values, intervals, diagnostics, and
scientific claims were not recomputed.

## Reopening condition

Reopen H02 or H11 inheritance if the accepted shared input identities,
response construction, temporal sequence boundaries, model formula, common
time basis, placement role, or fitted sample changes. A display-only rebuild
does not reopen inference when its source-data identity and fitted values are
unchanged.
