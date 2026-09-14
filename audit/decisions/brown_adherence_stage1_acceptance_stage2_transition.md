# Brown recommendation adherence Stage 1 acceptance and Stage 2 transition

Decision ID: `BA-001`  
Change ID: `CHG-138`  
Date: 2026-08-14  
Status: author approved; bounded Stage 2 authorized

## Author decision and analysis status

The author explicitly replied:

> **Approve Brown adherence Stage 1 as written.**

This closes the complete `BA-G1` through `BA-G16` Stage 1 gate without
revision. Brown recommendation adherence remains a standalone exploratory
analysis. It is not a registered confirmatory hypothesis, does not replace
H01 through H11, and does not alter an accepted hypothesis result.

The approved Stage 1 report is fixed at these identities:

| Accepted artifact | SHA-256 |
|---|---|
| `audit/analyses/brown_adherence/01_audit_and_plan.qmd` | `43926e02846c15ff521e65b0c7d43b23084231c13805ae57c8ff616e42de5c3f` |
| `audit/analyses/brown_adherence/01_audit_and_plan.html` | `24f6d8d55055af1bdb510de0bb7be446b3e382c5529096c048e0e8b26f8965a3` |
| `audit/analyses/brown_adherence/03_author_decision_record.md` | `61afa5c70490982c4c9e662920cad7030c17c40c9daa301d3559eb84842196b7` |
| `audit/handoffs/brown_adherence_strategy_handoff.md` | `94516e2718b3280d51f6401fdd2ed686ecb5912268ecf8cd8c8abf5bd537b4a3` |
| `audit/analyses/brown_adherence/stage1_render_manifest.csv` | `4632870b0e2e4e2d28b30b33181c4f268f24f76ba9509cd32f647ed2c660ebc3` |
| `audit/analyses/brown_adherence/stage1_report_verification.csv` | `3406596778ea4a515556acdbce6561c369f0b235a317c36ca33a62b12f7eef7a` |
| `audit/analyses/brown_adherence/strategy_verification.csv` | `cdad76169a7f4c4914960916744a89d55b559d917756433643e61eeb99caa11f` |

The coordinator independently matched these identities and reviewed the
approved outcome, formula, multiplicity, diagnostic, sensitivity, and staged
workflow contracts. The Stage 1 verification records report R 4.6.1, exact
candidate counts, all 54 state by site by day-type cells, all 16 gate items,
no inferential model call, and a successful bounded report render and visual
check.

The central `hypothesis_stage_gates.csv` is deliberately unchanged because
this is a standalone exploratory analysis rather than an H01 through H11
hypothesis. This decision and `CHG-138` are its central gate records.

## Current scientific input pins

Every Stage 2 run must verify these current shared inputs before constructing
or fitting a model. A mismatch stops execution and returns to the coordinator.

| Input | SHA-256 |
|---|---|
| `artifacts/03_coverage/light_glasses_coverage.rds` | `00085dc32ae370f059da9bfb6dfbf560eda4c4376fdb0727d2ef3c0b4fec34ee` |
| `artifacts/05_metrics/state_support_gate_daily.csv` | `fa4e649a3aee03e5fb44a8899d6afdc1c9c348897e1cb450af4b05cae45c60e4` |
| `artifacts/06_model_data/normalized_inputs/sleepdiaries.rds` | `110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15` |
| `artifacts/09_tables/descriptives/recommendation_context_near_eye.csv` | `7c53c4dd8b315c7a61aa7d0f488ee9ccbfc28bc238d6c5cf6eed0dcd7409eb38` |
| `artifacts/12_manifests/coverage_artifacts.csv` | `0281118bfd0975181f6cf5fe39237f49271fa309c6de2d42d261b48450a5ba8d` |
| `artifacts/12_manifests/state_support_gate_artifacts.csv` | `755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619` |
| `artifacts/12_manifests/model_input_normalization.csv` | `e3d484711abb54f69d63ff302e5a0329efda3fd0a8c85feaf9cc4f850005c9ab` |
| `artifacts/12_manifests/descriptives/descriptive_artifacts.csv` | `b09f7bb5184e44e62272188eb7c9624669832ecdc31ecd809254bf3992544c75` |
| `config/site_display_registry.csv` | `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

## Authorized Stage 2 contract

The Brown-adherence owner may create only the approved Stage 2 source,
task-owned scripts, and task-owned outputs under
`audit/analyses/brown_adherence/stage2/`. The author-facing source is
`audit/analyses/brown_adherence/02_implementation_and_baseline_reconciliation.qmd`.

Stage 2 must implement the accepted `BA-G1` through `BA-G16` contract:

1. Reconstruct the inclusive minute-level Brown checks from sealed eligible
   near-eye measurements. Use `>=250 lx` during wake outside the three hours
   before sleep, `<=10 lx` during pre-sleep, and `<=1 lx` during the sleep
   environment.
2. Use linkage C. For wake-date diary row `r`, assign `pre-sleep_r`,
   `sleep_r`, and `wake_r` to `daytype2_r`. Linkage B remains a prespecified
   sensitivity only.
3. Use state-period counts `cbind(brown_yes, brown_no)`. Retain exact all-no
   and all-yes periods. The primary sample includes every state period with at
   least one valid comparison and estimates only the probability for an
   observed valid minute.
4. Repeat the identical analysis with at least 80% of the exact state interval
   covered by valid comparisons. This is a mandatory claim gate, not a formula
   variant.
5. Reconcile, before fitting, the frozen Stage 1 totals: any-valid has 2,216
   state rows, 782 cycles, 140 participants, 1,028,958 valid checks, and
   524,218 in-range checks; the 80% sample has 2,004 rows, 770 cycles,
   140 participants, 985,550 valid checks, and 502,877 in-range checks.
6. Attempt the beta-binomial logit `F3/R0` candidate first:

   ```r
   cbind(brown_yes, brown_no) ~
     analysis_state * site * day_type +
     diag(1 + analysis_state + day_type | participant_id) +
     (1 | behavioral_day_id)
   ```

   Use state-specific dispersion, explicit sum contrasts, maximum likelihood,
   Laplace approximation, and the approved equal-site standardization.
7. Enter the fixed `F3`, `F2`, `F1`, `F0` ladder, random `R0`, `R1`, `R1B`,
   `R2`, `R3` ladder, common-dispersion fallback, or fractional-logit family
   fallback only when the exact prespecified support, rank, convergence,
   Hessian, boundary, singularity, identifiability, or estimability gate
   requires it. Record every transition. Never simplify because of an
   estimate, direction, or p-value.
8. Report the approved response-scale probabilities, percentage-point Free
   minus Work contrasts, state-specific site interaction tests, global
   three-way test, and any authorized localization. Assemble the complete
   `BA-M1` through `BA-M4` multiplicity families exactly as approved before
   FDR adjustment.
9. Run and interpret the approved convergence, Hessian, rank, dispersion,
   residual, boundary, calibration, support, elapsed-date, sparse-cell, and
   influence checks. Each fitted target receives an explicit acceptable,
   acceptable-with-limitations, or not-acceptable assessment.
10. Keep near-eye primary. Chest remains separate and complementary, with no
    placement pooling and no direct ocular interpretation of sleep values.
11. Reconcile the accepted Brown descriptive table and sample-flow totals.
    Because this is a new analysis, do not invent an inferential V0.
12. Preserve formula objects, model frames, fitted objects, full-precision
    results, diagnostics, sensitivities, source data, manifests, and software
    provenance in the approved task-owned paths.

Ordinary candidate fits, their prespecified diagnostic comparisons, the nine
leave-one-site-out checks, and bounded participant-influence summaries are
authorized within Stage 2. An exhaustive participant-deletion battery,
bootstrap, simulation, or other heavy computation is not authorized. If such
work becomes necessary, first run only a representative 50- or 100-replicate
pilot, report runtime and failure behavior, and stop for a separate production
decision. No pilot result may substitute for production inference.

## Mandatory Stage 2 stop

After the bounded implementation, baseline reconciliation, approved fits,
diagnostics, and non-heavy sensitivities are complete and verified under
R 4.6.1, stop at `BA-S2-REVIEW` for explicit author review. Stage 3, Stage 4,
shared Quarto integration, shared preparation changes, manuscript edits,
commit, push, upload, and heavy production computation remain unauthorized.

A material change to the question, outcome, threshold, linkage, coverage
target, sample, estimand, response family, formula ladder, multiplicity,
placement role, or claim returns to Stage 1 before further fitting.

## Reopening condition

Reopen `BA-001` if a pinned input or accepted Stage 1 identity changes, the
frozen totals do not reconcile, a required fit cannot be implemented within
the approved ladders, a diagnostic or sensitivity exposes a construct change,
or the author changes any accepted `BA-G1` through `BA-G16` decision.
