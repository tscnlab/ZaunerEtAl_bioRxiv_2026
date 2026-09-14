# H05 Stage 2 handoff

Status: **Stage 2 remains approved; bounded METRIC-011 primary L10 reseal implemented and awaiting coordinator reconciliation**

## Scope completed

This worker implemented the author-approved H05 analysis in R, ran it in
clean sessions, reproduced the submitted V0 near-eye and chest outputs,
created corrected V0 matrices, compared the approved implementation with V0,
and assessed all fitted primary models and registered sensitivities. The work
is confined to H05 scripts, tests, artifacts, audit reports, and handoffs.

The reader-facing H05 notebook was not created during Stage 2. No manuscript
file, shared configuration, central decision record, or deviation ledger was
modified by the H05 task.

## METRIC-010 bounded amendment (2026-08-11)

The controlling amendment is
`audit/decisions/mder_mean_of_viable_ratios.md` (`METRIC-010`; SHA-256
`1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de`).
MDER is now the arithmetic mean of viable one-minute MEDI/LIGHT ratios. Both
channels must be finite and strictly positive; fall-back duplicate local
minutes are averaged channel-wise before the ratio is formed, spring-forward
absent minutes remain missing on the complete 1,440-minute local wall-clock
grid, and at least 720 viable minute ratios are required. This is neither a
time-profile-weighted measure nor a ratio of daily integrals.

The initial bounded amendment rebuilt 32 MDER fixed-site cells across the
eight accepted H05 scenarios, 36 primary MDER leave-one-site-out refits, and
eight MDER random-site fits. After the shared gap input was repaired, a second
bounded reseal replaced only the four gap-timing-unaware MDER frames and four
H05-F3 MDER model bundles (16 factor-model cells), then ran 44 gap-only
day/participant deletion refits and reconstructed the exact matched-placement
record. No primary model and no non-MDER model was refitted during this
reseal. The H05-F3 BH vector was reconstructed from 64 unchanged non-MDER raw
p-values and four repaired MDER p-values; this necessarily changed 27
non-MDER adjusted p-values and 26 non-MDER ranks while leaving every
non-MDER raw test and fitted object unchanged. The 20-check initial
reconciliation and 16-check gap reseal both pass. No full 17-metric run,
bootstrap, simulation, or heavy resampling was performed.

The current primary near-eye MDER sample is 702 participant-days from 137
participants at nine sites; the complementary chest sample is 732 days from
152 participants at eight sites. No MDER association is BH-retained. The
near-eye F5 estimate is -0.0197 MDER units per LEBA SD (95% CI -0.0351 to
-0.0043; raw p = 0.010; BH-adjusted p = 0.169), so its unadjusted interval is
below zero but it is not multiplicity-retained. The exact primary paired MDER
sample is 489 days from 107 participants at eight sites; all four paired
directions agree and their component intervals overlap. Repaired
gap-timing-unaware MDER uses 687 near-eye days from 137 participants and 723
chest days from 152 participants. Its exact paired sample is 478 days from 107
participants at eight sites. These changes do not alter the zero-of-68 family
conclusion.

One near-eye and three chest days exceeded the current-estimand Tukey outer
fence. All 44 bounded day- and participant-deletion refits passed. Forty of 44
sensitivity intervals contain zero; the four exceptions are the near-eye F5
deletion intervals, which remain below zero. All chest sensitivity intervals
contain zero, although the small chest coefficients are more upper-tail-
sensitive. The family-wide conclusion remains zero of 68.

The repaired gap branch has its own 44 successful bounded deletion refits;
40 intervals contain zero. The four exceptions are again the near-eye F5
intervals. Near-eye directions do not reverse. All chest intervals contain
zero, although F2 reverses direction in two deletions. This does not alter the
H05-F3 multiplicity conclusion.

## METRIC-011 bounded L10 amendment (2026-08-12)

The controlling decision is
`audit/decisions/l10_numerical_zero_normalization.md` (`METRIC-011`; SHA-256
`23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797`).
Offset geometric-mean residuals within the unit-aware numerical tolerance are
set to exact zero only when every finite source value in the selected window
is exactly zero. Missing source minutes remain missing. The upstream evidence
manifest is
`audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv`
(SHA-256
`a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb`).

Eight primary L10-mean cells changed from
`4.163336342344337e-17` lx to exact zero: three near-eye and five chest
participant-days. All eight occur in both the all-available and paired/common
frames. The bounded H05 reseal therefore replaced four primary L10 frames,
refit 16 core factor-model cells, replaced eight primary inferential bundles,
refit eight registered random-site sensitivities, and repeated 36 near-eye
leave-one-site-out refits. No sample changed. No gap-timing-unaware L10 model,
non-L10 model, MDER model, bootstrap, simulation, or other resampling was run.

The largest absolute coefficient change across the 16 cells was
`3.61e-12` on the model scale per LEBA point. Seven inferential raw p-values
changed at full precision. Two BH-adjusted p-values changed below the required
three-decimal display precision, and no family rank changed. Diagnostic and
adequacy classifications are unchanged. All three complete 68-test families
still retain zero associations.

The 22-row preservation reconciliation verifies every table and both object
archives. It freezes all content outside primary L10 except mathematically
dependent BH fields, and separately proves identity for all four
gap-timing-unaware L10 frames and all four gap L10 inferential bundles. The
29-row amendment manifest records the installed artifacts and R 4.6.1
environment.

## Primary deliverables

- `scripts/hypotheses/H05/h05_contract.R`
- `scripts/hypotheses/H05/h05_modeling.R`
- `scripts/hypotheses/H05/run_h05_stage2.R`
- `scripts/hypotheses/H05/refresh_h05_mder_metric010.R`
- `scripts/hypotheses/H05/finalize_h05_metric010_reconciliation.R`
- `scripts/hypotheses/H05/reseal_h05_gap_mder_metric010.R`
- `scripts/hypotheses/H05/reseal_h05_l10_metric011.R`
- `scripts/hypotheses/H05/build_h05_metric011_displays.R`
- `tests/hypotheses/H05/test_h05_stage2.R`
- `audit/hypotheses/H05/02_implementation_and_v0_comparison.qmd`
- `audit/hypotheses/H05/02_implementation_and_v0_comparison.html`
- this handoff
- H05-only artifacts under `artifacts/06_model_data/H05/` through
  `artifacts/12_manifests/H05/`

The authoritative artifact inventory, including SHA-256 hashes, is
`artifacts/12_manifests/H05/H05_stage2_artifacts.csv`.

The inventory is refreshed only after the final bounded source, render,
display, test, and handoff state. It deliberately excludes downstream Stage 3
and Stage 4 reader/provenance products, preventing a circular checksum chain.
The L10 amendment changed no accepted MDER output, gap L10 fit, or non-L10
fit. Reporting sources, renders, L10-aware figures and source data, handoff,
and focused-test identities are included in the refreshed inventory.

## Approved implementation

- Near-eye, all-available data are primary.
- Site is represented by fixed effects in the primary models. The inherited
  H01 evidence shows that all 17 fixed-site fits converged with positive-
  definite Hessians and without singularity, whereas the corresponding random
  site models included non-estimable and singular fits. Random site remains a
  registered sensitivity.
- Participant-day metrics use
  `response_value ~ site + leba_centered + (1 | participant_key)`.
- Participant-level IS/IV metrics use
  `response_value ~ site + leba_centered`.
- Each reduced model removes LEBA only and uses exactly the same model frame.
- LEBA is centered and scaled over the unique participants in each exact
  analysis frame, avoiding day-weighted questionnaire scaling.
- The H01 response-family and transformation package is inherited without
  outcome-driven selection in H05.
- The 17 metrics are crossed with four LEBA factors. Each inferential scenario
  uses one complete 68-test Benjamini--Hochberg family.
- Chest all-available results are complementary. Paired/common near-eye and
  chest analyses separate placement from sample composition. Other placement
  runs and the gap-timing-unaware dataset are sensitivities.
- L10 uses the approved strict post-16:00 definition. No noon sensitivity was
  run, as explicitly directed by the author.

## Primary result

All 68 fixed-site primary models are estimable. **Zero of 68 associations has
BH-adjusted p at or below 0.050.** The submitted claim that exactly two H05
comparisons were significant is therefore not supported by the approved
analysis.

The two numerically strongest results are both for LEBA F2:

| Metric | Ratio per participant SD (95% CI) | Raw p | BH-adjusted p | Adequacy |
|---|---:|---:|---:|---|
| Time above 1,000 lx melEDI | 1.234 (1.084 to 1.405) | 0.002 | 0.124 | Acceptable |
| Corrected melEDI dose | 1.278 (1.079 to 1.514) | 0.004 | 0.124 | Acceptable with an ordinary Gaussian residual warning |

These positive estimates are observational and exploratory after the complete
multiplicity correction. They must not be described as significant or as
confirmatory H05 findings.

The strongest defensible conclusion is: **after fixed-site adjustment and one
complete 68-test BH correction, this dataset provides no multiplicity-retained
evidence that any of the four LEBA factors is associated with the 17 selected
personal light-exposure metrics.**

## Model adequacy

The frozen Stage 2 diagnostic classification is 19 acceptable and 49
acceptable with specified limitations. The subsequent author disposition
separates the four sleep-environment cells from that latter group, giving the
reader-facing assessment:

- 19 acceptable;
- 45 acceptable with specified limitations; and
- 4 unfit for inference.

Forty-four retained models have ordinary Gaussian residual warnings. One
retained Tweedie model has an ordinary warning. The four sleep-environment
Tweedie models show material simulated-residual and response-support failures,
including predictions above the outcome support. Their estimates, intervals,
and p-values are suppressed from reader-facing inference. This disposition is
specific to the H05 response and model structure and does not determine
whether the underlying metric is usable in another hypothesis with a different
response variable or model structure.

## Sensitivity results

- The complementary chest all-available family contains 68 complete tests;
  its smallest BH-adjusted p is 0.224 and none is retained.
- The gap-timing-unaware near-eye family contains 68 complete tests; its
  smallest BH-adjusted p is 0.070 and none is retained.
- All 612 primary leave-one-site-out refits succeed: 20 associations are
  stable, 27 retain direction but are magnitude-sensitive, and 21 are
  direction-unstable.
- The random-site sensitivity contains 136 main all-available cells. Of these,
  121 pass and 15 are unstable; this supports keeping fixed site as primary.
- The exact paired/common sample contains 107--112 participants, 489--643
  matched participant-days, and eight sites; IS and IV use 112 participant
  rows. Fifty-nine of 68 near-eye/chest cells agree in direction and have
  overlapping component intervals; nine differ in direction.
- Sixty-four of 68 cells comparing the primary and gap-timing-unaware datasets
  agree in sign and have overlapping component intervals; four do not.
- The exact longest-period identifiability sensitivity retains 500
  participant-days, 132 participants, and all nine sites. All four LEBA factor
  directions agree with the all-available analysis. The F2 ratio attenuates
  from 1.117 to 1.046 (95% CI 0.930 to 1.175), reinforcing the null
  interpretation.
- The two leading F2 primary estimates retain their direction in the random-
  site, leave-one-site-out, paired-placement, and gap-timing-unaware
  analyses.

Participant-level Spearman coefficients are descriptive only and create no
second significance screen. For the two leading F2 metrics they are 0.291
(95% CI 0.132 to 0.436) for time above 1,000 lx melEDI and 0.263 (95% CI
0.102 to 0.410) for corrected melEDI dose.

## V0 reproduction and correction

The exact V0 reconstruction contains 136 cells. The faithful submitted method
flags two near-eye cells and one chest cell. Replacing the mismatched Pearson
test and scalar `p.adjust(..., n = 68)` behavior with internally consistent
Spearman tests and a single 68-value BH vector leaves two near-eye flags and
zero chest flags.

On the frozen V0 near-eye summaries, the corrected results are:

- F2 with time above 1,000 lx melEDI: rho = 0.290, BH-adjusted p = 0.033; and
- F2 with corrected melEDI dose: rho = 0.272, BH-adjusted p = 0.038.

These reproduce the submitted descriptive pattern but do not override the
approved fixed-site result. The submitted prose must also correct “duration
above 250 lx” to the actual highlighted metric, time above 1,000 lx melEDI,
and must remove the interpretation of squared rank correlation as explained
variance.

## Claim disposition

| V0 claim or artifact | Stage 2 disposition |
|---|---|
| Exactly two of 68 comparisons were significant | Withdraw; the approved primary family retains zero of 68 |
| Positive F2--dose result | If shown, label as a stable but non-multiplicity-retained estimate with a residual warning |
| Positive F2--time-above-1,000-lx result | If shown, label as a stable but non-multiplicity-retained estimate |
| Highlighted metric described as duration above 250 lx | Correct to time above 1,000 lx melEDI |
| rho-squared described as explained variance | Remove |
| Site can be omitted | Remove; retain fixed site in the primary model |
| Chest duplicates near-eye interpretation | Replace with placement-specific evidence |
| Habitual behavior is broadly less informative than immediate context | Do not infer from H05 |

## Deferred analyses and production-computation gate

The following remain deferred because they are not needed to adjudicate the
primary 68-test result:

- participant-cluster intervals for the paired placement difference;
- coverage Rules B/C and relaxed native-epoch scenarios;
- broader all-zero-inclusive and state-support threshold batteries; and
- broader upstream scenario production.

Alternative response-family fits were not repeated because H01 already
completed its prespecified candidate assessment. The author explicitly ruled
out an L10 noon sensitivity. No production bootstrap is required for the
approved H05 inference.

Production computation is an unnumbered conditional gate between Stages 2 and
3; it is not Stage 3. If the author later requires an interval for the paired
placement difference, a separate 50- or 100-successful-refit
participant-cluster pilot, runtime estimate, and approval gate are required
before production. That possibility does not alter the current transition to
mandatory Stage 3.

## Verification performed

- R 4.6.1 with the project `renv` library; consequential package versions and
  frozen input hashes are recorded in the report and H05 manifests.
- Eight analysis runs produced 544 fixed-site cells.
- The bounded METRIC-010 updater replaced only the 32 MDER cells, repeated
  only the required MDER diagnostics and sensitivities, and proved that all
  other metric-specific scientific content remained invariant.
- The repaired-gap reseal replaced only 16 gap MDER cells, ran 44 bounded
  gap-only deletion refits, preserved all primary and non-MDER model objects,
  and reconciled the mathematically necessary H05-F3 BH-derived changes.
- The METRIC-011 reseal replaced only 16 primary L10 cells, eight primary
  inferential bundles, eight registered random-site sensitivities, and 36
  primary near-eye leave-one-site-out refits. Its 22 checks preserve every
  non-L10 fit and every gap L10 fit; two adjusted p-values changed below
  display precision and no family rank changed.
- Three inferential families each contain exactly 68 observed tests and each
  reproduces vector BH adjustment exactly.
- The inferential archive contains 204 full/reduced model bundles.
- All 612 required primary leave-one-site-out refits are present.
- Independent tests reproduce the exact V0 flag counts and coefficients,
  exact longest-period sensitivity values, paired IS/IV support, model-frame
  identity, and all required figure files.
- Quarto rendered the report as a self-contained HTML with embedded figures.

Analytical verification command:

```text
R_LIBS=renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=<project-root> \
Rscript --vanilla tests/hypotheses/H05/test_h05_stage2.R
```

## Author disposition and Stage 3 authorization

The author approved the following Stage 2 items on 2026-08-01:

1. the zero-of-68 primary result and withdrawal of the two V0 significance
   claims;
2. the fixed-site effect and the faithful/corrected V0 displays;
3. the adequacy classifications, including the four sleep-environment models
   designated unfit for H05 inference;
4. the interpretation of the two leading F2 estimates as stable but not
   multiplicity-retained;
5. the complementary chest and registered sensitivity interpretations,
   including the gap-timing-unaware dataset;
7. the claim-disposition table and strongest defensible conclusion.

The former item 6 is superseded because it incorrectly described production
computation as Stage 3. The expensive analyses listed above remain deferred,
no production-computation gate is required, and H05 proceeds directly to the
mandatory standalone Stage 3 reader-facing report.

The coordinator recorded this disposition in:

- `audit/decisions/h05_stage2_gate_and_stage3_transition.md` (`H05-001`);
- `audit/ledgers/hypothesis_stage_gates.csv`; and
- `audit/ledgers/change_log.csv` (`CHG-071`).

The reporting revision also follows the coordinator-owned rules:

- `audit/decisions/p_value_display_conventions.md` (`REPORT-008`);
- `audit/decisions/paired_placement_comparison_display.md` (`REPORT-009`);
  and
- `audit/decisions/gap_timing_unaware_dataset_terminology.md`
  (`REPORT-010`).

Those coordinator-owned records are read-only for the H05 task. The numbering
correction changes no model, estimate, interval, diagnostic, sensitivity
result, or claim.

## Current scope guard

The four-stage H05 workflow was closed under H05-004 before METRIC-011. This
amendment reopens only the primary L10-dependent slice for bounded scientific
and reporting reconciliation. All accepted METRIC-010 MDER outputs and every
other metric fit remain frozen. Shared preparation, central decisions and
ledgers, Quarto configuration, other hypotheses, and manuscript files remain
read-only. H05 should be considered scientifically unchanged in conclusion but
administratively awaiting coordinator verification and resealing of the
METRIC-011 amendment.
