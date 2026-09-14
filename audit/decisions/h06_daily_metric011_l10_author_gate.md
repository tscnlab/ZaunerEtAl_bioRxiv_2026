# H06 daily METRIC-011 L10 author gate

Decision ID: `H06-D-001`  
Date: 2026-08-12  
Status: verified; awaiting explicit author approval

## Decision

Accept the bounded H06-daily METRIC-011 L10 amendment as independently
verified evidence for an author decision. Do not accept a joint L10
association, release the remaining daily-metric production grid, alter the
approved pre-sleep no-nugget sensitivity, or designate the H06-daily variant
as the final H06 analysis.

The recommended author disposition is to:

1. classify every primary and gap-timing-unaware near-eye joint L10
   association and site-heterogeneity test as
   `NON_ESTIMABLE_COMPONENT_FAILURE`, retaining L10 as the named third slot in
   each 15-metric family with raw and adjusted p-values missing;
2. retain the positive-magnitude estimates only as conditional descriptive
   diagnostics among participant-days with L10 greater than zero;
3. retain the normal-prior fixed-site occurrence fits only as diagnostic MAP
   sensitivities without ordinary confidence intervals, p-values,
   multiplicity entries, or significance decisions; and
4. leave the joint L10 slots missing unless a later explicit scientific
   amendment changes the primary occurrence hierarchy.

## Why the joint tests are non-estimable

The prespecified fixed-site binomial occurrence component is completely or
quasi-completely separated for all three primary near-eye predictors. UCR has
no exact-zero L10 participant-day in the relevant work/free or activity cells
or across observed previous-night sleep support, so the fixed-site model can
nearly perfectly predict occurrence. Its ordinary coefficients and standard
errors are consequently not usable for confirmatory inference. The triggered
work/free actual-date AR(1) occurrence counterpart additionally reaches the
correlation boundary at `rho = -0.999964` and is not acceptable.

The joint two-part test requires both the occurrence and positive-magnitude
components to pass their component-specific gates. Because the occurrence
component fails, neither its raw p-value nor the combined joint p-value is a
valid missing-data substitute. A positive-only test, MAP fit, registered
random-site benchmark, deletion of UCR, pooled-site model, or changed
fixed-site hierarchy cannot replace it without a new author-approved
scientific amendment.

## Conditional positive-magnitude diagnostics

For the primary near-eye Gaussian component, conditional on L10 being greater
than zero, the estimated geometric-mean ratios and pointwise 95% confidence
intervals are:

| Contrast | Conditional ratio (95% CI) | Required limitation |
|---|---:|---|
| Free day versus work day | 0.925 (0.759 to 1.128) | Student-t ratio reverses direction and differs by 1.35 primary standard errors |
| Active versus sedentary | 0.864 (0.674 to 1.107) | Maximum site-deletion shift is 1.04 primary standard errors |
| Per additional hour of previous-night sleep | 0.775 (0.722 to 0.832) | Student-t sensitivity fails its numerical gate; its interval is withheld |

These estimates describe only the magnitude of L10 on positive-L10 days.
They do not estimate the overall two-part L10 association and support no
standalone confirmatory or directional claim.

## Preservation and verification

Fresh R 4.6.1 execution of
`tests/hypotheses/H06_daily/test_h06_daily_l10_metric011.R` passed. It verifies
13 pinned inputs, 36 component frames, eight numerical-zero repairs, 12
non-estimable joint slots, retention of the 15-slot family structure, 440
positive-only deletion refits, object identity for 194 fitted-model
subobjects, byte identity for 294 protected pre-existing files, and the sealed
report and manifests.

The amendment ran only the L10 branch. Every non-L10 result and the approved
pre-sleep no-nugget frame, reference, model, report, and manifest remain
frozen. The remaining H06-daily production grid remains unauthorized.

| Artifact | SHA-256 |
|---|---|
| Amendment source | `2a13894ed53f0cbe660f2855e3f994ce2041d6408ac36b650a0a4bbff2d6cade` |
| Amendment HTML | `db255bc7d5aba1f71fa8c42ab4de0ebef3807210d45c99f805cfad6074b8a109` |
| Transition | `616d9729a66856d0d6176ce2bfc7606e4fea5cf561b964ffc52a2ea98d0097f3` |
| Report manifest (112 identities) | `06876cba0c9ad5691421fcc75d5e6fc4a15fc3c742e9f05b4235b12749d35c6f` |
| Production-input manifest (55 identities) | `2e053bef2450717b7a5fd5e968d3dacbb940127c8934e2c352fd3b926951d482` |
| Production-code manifest (11 identities) | `caf796cf5dce213f2169357e7573b71fcca7587d26ccaaa6e361c0428db5ed25` |
| Production-output manifest (91 identities) | `1384166a88f66d93d40da0522fe9a725aeab987b684f5f2baf0fe9a4b669c207` |
| Focused test | `7d88c58921bf3ff5391a4d6422b4ea43c2ec7143ae34196c9e8af46cd798dedf` |
| Worker handoff | `937bba5b38c58038aee943040281d3f6e8e0d875961f254022e5394121569184` |

## Gate effect

This decision records verification only. H06-D-G2P-L10-METRIC011 remains at
author review. The main H06 record remains frozen under H06-006, and final H06
version selection remains open. Approval of this gate would settle only the
H06-daily L10 disposition; it would not by itself authorize the remaining
daily grid, Stage 3/4 reporting, or final version selection.

## Reopening condition

Reopen if a pinned identity, component frame, zero-handling rule, model
formula, separation classification, AR boundary result, conditional estimate,
family or influence sensitivity, 15-slot multiplicity structure, protected
artifact, report, manifest, or focused verifier changes. Any proposed primary
replacement for the non-estimable fixed-site occurrence component requires a
new explicit scientific amendment.
