# H05 Stage 2 handoff

Status: **Stage 2 approved; mandatory Stage 3 authorized; Stage 4 blocked**

## Scope completed

This worker implemented the author-approved H05 analysis in R, ran it in
clean sessions, reproduced the submitted V0 near-eye and chest outputs,
created corrected V0 matrices, compared the approved implementation with V0,
and assessed all fitted primary models and registered sensitivities. The work
is confined to H05 scripts, tests, artifacts, audit reports, and handoffs.

The reader-facing H05 notebook was not created during Stage 2. No manuscript
file, shared configuration, central decision record, or deviation ledger was
modified by the H05 task.

## Primary deliverables

- `scripts/hypotheses/H05/h05_contract.R`
- `scripts/hypotheses/H05/h05_modeling.R`
- `scripts/hypotheses/H05/run_h05_stage2.R`
- `tests/hypotheses/H05/test_h05_stage2.R`
- `audit/hypotheses/H05/02_implementation_and_v0_comparison.qmd`
- `audit/hypotheses/H05/02_implementation_and_v0_comparison.html`
- this handoff
- H05-only artifacts under `artifacts/06_model_data/H05/` through
  `artifacts/12_manifests/H05/`

The authoritative artifact inventory, including SHA-256 hashes, is
`artifacts/12_manifests/H05/H05_stage2_artifacts.csv`.

The approved reporting/display revision produced these updated report
identities without scientific recomputation:

| File | SHA-256 |
|---|---|
| `audit/hypotheses/H05/02_implementation_and_v0_comparison.qmd` | `b8fae36f5209d45ac0dad6c17350ecdf7b48358a8380d4d3bfb85a9c10dbad0e` |
| `audit/hypotheses/H05/02_implementation_and_v0_comparison.html` | `a6d849c816675b44b9a3db4e6771cc70f695d193238efc84a16b9efa0182b2f2` |

The H05 manifest was refreshed after this repair. All scientific-result
artifacts through the stored tables retain their prior identities because no
model, diagnostic, or sensitivity calculation was rerun. Only the approved
reporting source, render, display figures, paired display-source CSV, handoff,
and focused test have updated identities.

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
- All 612 primary leave-one-site-out refits succeed.
- The random-site sensitivity contains 136 main all-available cells. Of these,
  121 pass and 15 are unstable; this supports keeping fixed site as primary.
- The exact paired/common sample contains 110--112 participants, 505--643
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
- all-zero-inclusive and MDER/state-support threshold batteries; and
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

## Stop rule and scope guard

Stage 3 is now authorized at `notebooks/hypotheses/H05.qmd`. It must stop for
author approval after its source, Nature Health HTML, tests, manifest, and
handoff are complete. Do not begin the Stage 4 preparation/provenance
companion before that approval. No commit, push, upload, or external message
was made.
