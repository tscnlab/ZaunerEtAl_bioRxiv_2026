# H11 shared change request

Date: 2026-08-06  
Status: **Stage 4 H11-owned work complete; shared integration pending**  
Shared files modified by H11 worker: **none**

## Required shared-site integration

Please add the following source immediately after
`notebooks/hypotheses/H11.qmd` in the `project.render` list of
`_quarto-nathealth.yml`:

```yaml
- audit/hypotheses/H11/H11_analysis_preparation.qmd
```

Please add the following item immediately beside the H11 result in the
“Hypothesis analyses” navigation:

```yaml
- href: audit/hypotheses/H11/H11_analysis_preparation.qmd
  text: "H11 preparation and provenance"
```

Then run the bounded H11 result and preparation render, rebuild
`artifacts/12_manifests/H11/H11_preparation_report_manifest.csv`, and run
`tests/hypotheses/H11/test_h11_preparation_report.R`. Once the profile entries
exist, that test automatically runs the full shared REPORT-007 verifier,
including render-list and navigation adjacency. No scientific fit, prediction,
bootstrap, simulation, or robust test needs to be repeated for this
integration.

## Requested coordinator-owned changes after the Stage 2 gate

Once the author resolves `H11-STAGE2-001` through `H11-STAGE2-004`,
`H11-COMPUTE-001`, and `H11-STAGE3-001`, please update the coordinator-owned
stage gate and central ledgers as follows.

### Decision and deviation

- Record author approval of H11-METHOD-001 through H11-METHOD-007.
- Register the outcome-aware replacement of the unfinished ML,
  `discrete = FALSE`, delta-AIC branch with the post-fit complete-curve test
  based on AR-whitened participant-summed scores, participant-cluster CR1
  covariance, `Vp - Ve`, and finite-cluster fractional-rank F reference.
- Record one global p-based decision per placement, BH adjustment across the
  two within-placement level/shape tests, and participant-cluster-robust
  pointwise 95% intervals with no familywise period claim.
- Record the main-placement effect-size gate as global robust raw p below
  0.050; remove the superseded AIC criterion.

### Implementation and sample flow

- Main near eye: 141 participants, 816 participant-days, 37,756 observations,
  9 sites.
- Main chest: 154 participants, 902 participant-days, 41,842 observations, 8
  sites.
- Gap-timing-unaware near eye: 141 participants, 809 participant-days, 37,603
  observations, 9 sites.
- Gap-timing-unaware chest: 154 participants, 894 participant-days, 41,664
  observations, 8 sites.
- Record four preliminary and four final fREML/discrete full fits, two gated
  main-placement fREML baseline fits, four global robust tests, eight robust
  decomposition tests, and two 50-resample effect-size pilots.

### Result comparison and claims

- Primary near-eye global test: raw p = 0.028 and BH-adjusted p = 0.028,
  supported.
- Complementary chest global test: raw p = 0.029 and BH-adjusted p = 0.029,
  supported.
- Gap-timing-unaware near-eye global test: raw p = 0.026 and BH-adjusted p =
  0.026, supported.
- Gap-timing-unaware chest global test: raw p = 0.037 and BH-adjusted p =
  0.037, supported.
- All planned BH-adjusted level/shape components are unsupported.
- V0-to-accepted model/inference change reverses chest on the same gap-timing-
  unaware frame; the later preparation change preserves both accepted robust
  decisions.
- Effect-size pilot estimates are negligible and remain audit-only pending
  `H11-COMPUTE-001`.
- Diagnostic assessment: acceptable with specified limitations.

### Reporting rules

- REPORT-008 through REPORT-011 are incorporated in the Stage 2 report.
- REPORT-009 yields no paired identity plot or paired source CSV because no
  accepted common-sample H11 fitted estimands exist.
- REPORT-012 is incorporated in the accepted reader report using the exact
  title “Answer in brief”.

## Evidence

See:

- `audit/hypotheses/H11/02_inferential_method_decision.md`;
- `audit/hypotheses/H11/02_implementation_and_v0_comparison.html`;
- `audit/hypotheses/H11/02_figure_readability_qa.md`;
- `audit/handoffs/H11_worker_handoff.md`;
- `artifacts/12_manifests/H11/H11_stage2_output_hashes.csv`.

The H11 worker stopped before changing shared preparation code, shared Quarto
configuration, index, supplementary information, bibliography, central
ledgers, manuscript files, or `renv.lock`.
