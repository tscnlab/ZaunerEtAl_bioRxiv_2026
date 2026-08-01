# H01 post-bootstrap response-family major-change gate

Date: 2026-07-31  
Status: **OPEN — inferential release withheld**  
Trigger: required response-family checks failed after the completed production
bootstrap  
Scope: H01 only; no shared preparation change requested

## Disposition

The approved production bootstrap completed successfully and its cached draws
remain intact. However, the Tweedie log-link model for time below 1 lx melEDI
during sleep fails its required distributional and support checks in both the
main and manuscript-prepared near-eye analyses. H01 therefore meets the
predeclared stop condition: a common response-family replacement or an
explicit non-estimable disposition requires author approval before any result
is released.

No response family has been replaced. No model, multiplicity family, site
follow-up, manuscript claim, shared preparation artifact, central ledger, or
Quarto configuration has been changed. The current estimates and adjusted
p-values are diagnostic/provisional and must not be reported.

Two additional approved-family warnings should be resolved in the same gate:

- the Tweedie model for calendar-day cumulative time below 10 lx melEDI before
  sleep has a strong residual warning in three of eight runs, including the
  main near-eye analysis; and
- the shifted-log Gaussian model for L10 mean melEDI has a strong
  heteroscedasticity warning in six of eight runs. The two all-available
  near-eye analyses are below the predeclared strong-warning threshold but
  still have variance ratios of 7.35 and 8.51.

The complete 24-row evidence table is
`audit/hypotheses/H01/H01_postbootstrap_response_family_gate_evidence.csv`.

## Decisive failure: time below 1 lx melEDI during sleep

The fitted outcome is a non-negative duration. The approved Tweedie log-link
model converged, had a positive-definite Hessian, and was not singular, but
those numerical fit checks do not establish distributional adequacy.

| Data scenario | Exact participants | Participant-days / observations | Sites | Main-data derivation support | Observed zero fraction | Simulated zero fraction | DHARMa uniformity p | DHARMa zero-inflation p | DHARMa outlier p | Support check |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Main, near eye | 141 | 778 | 9 | 6,282.52 h | 0.00514 | 0 | 1.75 × 10^-11^ | 0 | 0.00182 | 187 fitted means exceeded that day's sleep-window support |
| Manuscript-prepared, near eye | 141 | 790 | 9 | unavailable | 0.00506 | 0 | 4.44 × 10^-13^ | 0 | 2.65 × 10^-6^ | support hours unavailable, as predeclared |

All eight scenario/placement/sample runs are classified
`WARN_STRONG_TWEEDIE_MISFIT`. The observed zeros are sparse, but the fitted
Tweedie models essentially never reproduce them; uniformity and outlier
diagnostics disagree with the fitted distribution throughout. In main data,
the available per-day support additionally shows impossible fitted means in
all four near-eye/chest, all-available/paired runs.

The model specification names an identity-scale Gaussian model as the
predefined alternative, while explicitly requiring approval before switching
the primary model. This gate does not presume that the alternative will pass
its own residual and support checks.

## Additional response-family dispositions

| Metric | Current family | Evidence across eight runs | Predeclared alternative | Required disposition |
|---|---|---|---|---|
| Time below 10 lx melEDI before sleep | Tweedie, log link | Three strong warnings; the main near-eye zero fraction is 0.0153 versus 0.00688 in simulations. All observed and predicted values pass the 24-hour bound, and no value is above the six-hour audit threshold. | None | Decide whether the small absolute zero-mass discrepancy is acceptable with an explicit limitation, or authorize a common replacement study. |
| L10 mean melEDI | Gaussian after log10(value + 0.1) | Six strong Gaussian warnings; residual variance ratios range from 7.35 to 17.41. Both all-available near-eye runs are warnings rather than strong warnings. | Tweedie, log link | Decide whether to retain the common Gaussian family with explicit limitations, approve the named common alternative, or declare the metric non-estimable. |
| Time below 1 lx melEDI during sleep | Tweedie, log link | Eight strong warnings, absent simulated zero mass, and main-data predictions beyond nightly support. | Gaussian, identity scale | Approve one common replacement for every scenario and placement, or declare this metric non-estimable. |

## Author decisions required

1. For time below 1 lx melEDI during sleep, choose one of:
   - approve the predefined identity-scale Gaussian model as the common
     candidate for main/manuscript-prepared, near-eye/chest, and
     all-available/paired runs;
   - authorize a separately specified candidate-family assessment before
     selecting a common replacement; or
   - declare the metric non-estimable for H01, retaining its missing row in
     each complete 17-metric family.
2. Decide whether the pre-sleep Tweedie warning is retained with an explicit
   limitation or requires a common candidate-family assessment.
3. Decide whether L10 mean melEDI retains its shifted-log Gaussian family or
   moves to the named Tweedie candidate for every run.

Any approved replacement must preserve the outcome construct, exact model
rows where the alternative permits, fixed/random predictor structure,
near-eye primacy, complementary chest role, and identical implementation
between the main and manuscript-prepared scenarios. A replacement is a major
method change and reopens all four BH families and any hierarchical site
follow-up whose eligibility changes.

## Computation policy and preserved work

The completed production run was the explicit pre-COMPUTE-001 exception:

```sh
H01_STAGE=bootstrap H01_BOOTSTRAP_REFITS=1000 H01_BOOTSTRAP_CORES=4 \
Rscript scripts/hypotheses/H01/run_h01_models.R
```

It produced 128 draw files. Every estimable target retained exactly 1,000
joint refits; the minimum number of successful refits among 1,500 attempts was
1,491. There were 36 failed attempts across 24 targets and 25 warning attempts
across 21 targets. All bootstrap audit rows pass, all 1,272 estimable 95%
interval rows are complete, and eight participant-associated-share rows for
participant-level IS/IV remain explicitly non-estimable.

These draws must be preserved. If an author-approved family change affects
only the three gated metrics, unaffected metric draws do not need to be
recomputed. The changed targets require new fits and diagnostics; any future
production bootstrap must follow COMPUTE-001, including a separately stored
50- or 100-successful-refit production-code pilot for every changed target,
runtime/failure/warning/resource reporting, proposed reader-facing previews,
and explicit author approval before production.

## Multiplicity and claim consequences

- All four primary families remain 17-row families. They must not be shortened
  to 16 or fewer metrics.
- A non-estimable disposition leaves a missing test in the declared family;
  it is not treated as a null result.
- Because replacement p-values can change vector-wide BH values for every
  metric, no current adjusted p-value or inferential site follow-up is
  released.
- Submitted site, latitude, photoperiod, placement, and explained-variation
  claims remain unverified. No manuscript claim was edited.
- The production bootstrap is computationally valid for its fitted models but
  does not rescue an inadequate response family.

## Inputs, hashes, and audit outputs

| Artifact | SHA-256 |
|---|---|
| Main H01 model-data manifest | `ea9d47f624a8777f8416447612bfcc2309cf2bac40fdf4fd5021c8767806dfbf` |
| Manuscript-prepared H01 model-data manifest | `cb47b3678146604aadca875a96f79909e2d73355162683ff0603f038f3b31a25` |
| Completed model-results manifest | `086e95b50b97304396302b7093711cc1490ee498a5e4aa83a09ac7264a896d3e` |
| Model diagnostics | `47ea12fb9baf40a3c32d87e7280da9e7ed7fbdc840ed15ef3ccad1529d99372e` |
| Exact fitted samples | `a986ee74c2057434b8ee8fe7d9ed5d119c597872a3f9f5f5c498edf6d112095c` |
| Bootstrap audit | `50e78b7de80e843ff3bb3670e3711001c46f363fdd503ba5732f6c16b5588cb1` |
| Gate evidence | `6aaea36d062f71a11786a8c2f44d94e2c172d3f4cc4c1cd46f4a2a2534eb17f0` |
| Gate summary | `512e3dbace4e7cce2c8b7b6c73d212b1c88fdc339f846992f8e258db3e85d6d6` |
| Gate provenance | `2b555f60022f3b92508d7ab678494799b45efc9db649dad9c434fbc3cd653f18` |

R 4.6.1 generated the evidence with
`scripts/hypotheses/H01/audit_h01_postbootstrap_response_families.R`.
No package was installed or updated.

## Proposed coordinator ledger entries

| Ledger class | Proposed entry |
|---|---|
| Finding | The approved Tweedie model for time below 1 lx melEDI during sleep fails distributional checks in both main and manuscript-prepared near-eye analyses and predicts beyond available nightly support in main data. |
| Finding | Pre-sleep time below 10 lx melEDI has a strong Tweedie warning in the main near-eye analysis despite passing the construct, six-hour audit, and physical-bound checks. |
| Finding | The shifted-log Gaussian model for L10 mean melEDI has strong heteroscedasticity warnings in six of eight runs. |
| Decision | Open a post-bootstrap H01 response-family major-change gate; require a common author-approved family or non-estimable disposition before release. |
| Deviation | Preserve the completed production bootstrap, but withhold all four BH families, hierarchical site follow-ups, sensitivity classifications, and claim updates while the family gate is open. |
| Change log | Added an R 4.6.1 post-bootstrap response-family audit, 24-row evidence table, summary, provenance, and this gate without modifying fitted models or shared preparation. |
| Result comparison | Status `invalid/gated`; submitted-versus-repaired numerical comparison is not released because at least one approved response family fails required checks. |
| Claim provenance | No rebuilt H01 inferential claim is authorized; submitted claims remain unverified. |

