# H07 Stage 1 gate and Stage 2 transition

Decision ID: `H07-001`
Date: 2026-08-06
Status: approved

## Evidence approved

The owner approved the complete revised H07 Stage 1 gate package in the H07
task after review of:

- `audit/hypotheses/H07/01_audit_and_plan.qmd`, SHA-256
  `a9ef7f7a08a1193ef175c9c888fa0bc650eec8c978a705371b14d5f107c2f7b8`;
- `audit/hypotheses/H07/01_audit_and_plan.html`, SHA-256
  `d5a64287fe35912fc34c153230f3a42a408105de58848c43563db0cdfb8934d0`;
- the revised ceiling estimand and no-ceiling recommendation;
- the V0 conditional-AIC and derivative reconstruction;
- the H11 computational-method comparison; and
- H07-G1 through H07-G16 as displayed in the rendered Stage 1 report.

## Approved Stage 2 contract

1. All nine planned H07 metrics are analysed independently of H01 fitted
   results, significance, or p-values. Non-estimable family members remain in
   their nine-member multiplicity families with reasons.
2. Near-eye all-available data are primary. Chest all-available data are
   complementary. Direct placement comparisons use exact paired/common
   participant-days and do not test placement equivalence.
3. The registered estimand is the supported absolute-latitude--photoperiod
   tensor. A separately labelled site-adjusted photoperiod adaptation may be
   used only when the tensor fails the fixed identifiability gate.
4. No metric-specific scientific equivalence margin is available. The
   plateau/equivalence family is disabled and ceiling/plateau claims are
   prohibited. Nonlinearity, attenuation, a non-significant slope, conditional
   AIC, and visual flattening are not ceiling evidence.
5. The primary engine is exact `mgcv::gam(method = "REML")` with the displayed
   formulas. `mgcv::bam(method = "fREML", discrete = TRUE)` is only a
   provisional computational fallback after a timed attempt and exact-fit
   stability check. No primary branch uses ML or `bam(discrete = FALSE)`.
6. Maintained conditional GAM inference comprises the approximate
   `summary.gam()` whole-term test, the prespecified approximate nested
   `anova.gam()` shape comparison, and audited conditional AIC as secondary
   relative-support evidence. Failed identifiability, nesting, effective-df
   ordering, or residual-dependence gates withhold the affected support label.
7. The three Tweedie metrics use estimated-power
   `mgcv::tw(link = "log", a = 1.01, b = 1.99)` with explicit power,
   dispersion, boundary, zero-frequency, and positive-tail diagnostics.
8. H11's Gaussian/AR-whitened participant CR1 method is not assumed to
   transfer to H07. Any participant-cluster refit bootstrap or custom
   sandwich requires a displayed 50- or 100-replicate validation pilot and
   separate production approval.
9. Practical derivatives use central maintained `gratia` methods or central
   finite differences of full response predictions, supported grids,
   recorded uncertainty settings, and simultaneous bands. The V0 forward,
   pointwise last-positive rule is historical only.
10. Stage 2 reports exact samples, 95% intervals, REPORT-008 p-values, and
    interpreted convergence, distributional, residual, temporal,
    identifiability, support-surface, and influence diagnostics. Near-eye,
    chest, paired/common, gap-timing-unaware, exact-common preparation,
    exact-period, observed-dose, basis, site-representation, and
    leave-one-site-out branches follow the approved roles.
11. Collection period, photoperiod, latitude, and site limitations remain
    explicit. Temperature, weather, holidays, unsupported behavioural
    predictors, and other result-selected covariates are prohibited.
12. Stage 2 recreates and compares the recognizable V0 figures and tables,
    then stops for owner approval before production resampling or Stage 3.

## Reopening condition

Reopen the H07 Stage 1 gate if the outcome family, predictor surface, basis,
site/participant structure, placement role, fitting engine, family/link,
inferential procedure, multiplicity family, support rule, ceiling disposition,
or sensitivity roles change, or if the approved contract cannot be fitted and
interpreted without a scientific amendment.

## Post-Stage 2 amendment

The owner invoked the reopening condition on 2026-08-07 after reviewing the
pooled-support display. Decision `H07-002` supersedes the eligibility roles of
H07-G1, H07-G9, and H07-G13 for the revised descriptive derivative
classification. The pooled-support and leave-one-site-out results remain
diagnostics rather than exclusion gates. The durable amendment and its
interpretation boundary are recorded in
`audit/hypotheses/H07/H07_stage2_derivative_gate_revision.md`.
