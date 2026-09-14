# H08 worker handoff

Date: 2026-08-12
Branch: `rewrite/NH`
Current gate: **bounded METRIC-011 maintenance complete; no new author-review gate triggered**
R version: 4.6.1
Resampling performed: none

## Outcome

The accepted H08 Stage 2, Stage 3, and Stage 4 scientific conclusion is
unchanged after shared decision METRIC-011 normalised eight primary L10 mean
cells from `4.163336342344337e-17` lx to exact zero. Three cells were near eye
and five were chest. No displayed effect, confidence interval, p-value,
multiplicity decision, diagnostic disposition, sensitivity classification,
or reader-facing claim changed. The instruction to stop for author review was
therefore not activated.

Across nine primary near-eye metrics, no average association or site-specific
heterogeneity test met the BH-adjusted criterion. The strongest directional
near-eye pattern remains lower corrected melEDI dose per VLSQ-8 SD: ratio
0.846 (95% CI 0.716–0.999), likelihood-ratio raw p = 0.051, and BH-adjusted
p = 0.160. This is not a multiplicity-retained finding. Complementary chest
results and the central sensitivity analyses do not materially strengthen
the evidence.

## Controlling shared evidence

- Decision: `audit/decisions/l10_numerical_zero_normalization.md`; SHA-256
  `23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797`.
- Evidence manifest:
  `audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv`;
  SHA-256
  `a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb`.
- Current metric manifest:
  `028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e`.
- Current site/context manifest:
  `c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518`.
- Current base manifest:
  `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce`.
- Current base bundle:
  `e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916`.
- Near-eye participant-day context RDS:
  `013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a`.
- Chest participant-day context RDS:
  `497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057`.

## Bounded H08 refresh

`scripts/hypotheses/H08/reseal_h08_l10_metric011.R` verified all 20 sealed
inputs and rebuilt only the branches that inherit the changed L10
participant-days:

- six primary-dataset L10 model bundles;
- four L10 sensitivity bundles;
- 17 leave-one-site-out fits; and
- four complete nine-member BH families, 36 rows in total.

Four raw p-values changed below reader-display precision. Three BH-adjusted
values changed below display precision: two L10 values and one M10 derivative
within an affected complete family. All 36 displayed adjusted values and all
36 retained/not-retained decisions remained identical.

The reseal preserved every gap-timing-unaware field, every non-L10 fit and raw
test, all V0 artifacts, all accepted MDER outputs, all non-target model frames
and bundles, and the photoperiod, participant-summary, exactly identified
longest-period, and observed-dose outputs. No temperature or unsupported
predictor was introduced.

Key bounded records are:

- `artifacts/09_tables/H08/H08_metric011_result_comparison.csv`;
- `artifacts/09_tables/H08/H08_metric011_display_invariance.csv`;
- `artifacts/09_tables/H08/H08_metric011_bh_recalculation.csv`; and
- `artifacts/12_manifests/H08/H08_metric011_reconciliation.csv`.

The result comparison contains no author-review-required row, all six display
checks pass, and all 33 protected-scope reconciliation checks pass.

## Reports and display provenance

The bounded maintenance is recorded in:

- `audit/hypotheses/H08/02_implementation_and_v0_comparison.qmd`;
- `notebooks/hypotheses/H08.qmd`; and
- `audit/hypotheses/H08/H08_analysis_preparation.qmd`.

The Stage 3 **Results in brief** callout remains directly after the hypothesis
and analytical question and retains the multiplicity, 95% CI, complementary
chest, and sensitivity qualifications required by REPORT-012.

Five result figures were re-exported at their existing 170-mm size from the
stored H08 source CSVs only. Three preparation figures were rebuilt from
their stored descriptive frames. No scientific result was refitted for this
display work. Original-size A4 inspection with 20-mm side margins passed all
eight figures for clipping, overlap, wrapping, distortion, essential-text
readability, mark distinction, caption/alt presence, and data-region balance.
The effective final essential text is 7.5 pt for result figures and 8.0 pt for
preparation figures.

Current Stage 3 reader identities are:

- `notebooks/hypotheses/H08.qmd`: SHA-256
  `13b3547cad0eb7eba37d090cc8f611de99407e71a7b7a0a6a5a29670c06834c0`;
  bytes: 39,363.
- `_build/nathealth/notebooks/hypotheses/H08.html`: SHA-256
  `a08a888a40ec58669c61a47b7500159388577eaad49ece5440b9bee9da6a93e1`;
  bytes: 299,712.

## Verification

The following bounded checks complete successfully under R 4.6.1:

- isolated Stage 2 render: 63 evaluated steps;
- targeted NatHealth Stage 3 render: 45 evaluated steps;
- targeted NatHealth Stage 4 render: 51 evaluated steps;
- `tests/hypotheses/H08/test_h08_stage2.R`;
- `tests/hypotheses/H08/test_h08_metric011_reseal.R`;
- `tests/hypotheses/H08/test_h08_stage3_reader_report.R`; and
- `tests/hypotheses/H08/test_h08_preparation_report.R` in strict mode.

The final Stage 2 manifest seals the accepted implementation plus the bounded
maintenance. The Stage 3 manifest seals the reader report without sweeping
in downstream Stage 4 outputs. The Stage 4 preparation manifest then seals
the integrated results/preparation pair, all source data, all eight physical-
size proofs, and the upstream Stage 3 identity. This one-way dependency avoids
a circular manifest hash.

No full analysis rerun, bootstrap, simulation, heavy resampling, package
installation, full-project render, commit, push, or upload was performed for
this maintenance. The shared checkout contains unrelated work; any later
commit must remain restricted to H08-owned paths.
