# Brown recommendation adherence boundary Stage 1 acceptance and Stage 2 transition

Decision ID: `BA-002`  
Change ID: `CHG-140`  
Date: 2026-08-14  
Status: author approved; bounded Boundary Stage 2 authorized

## Author decision and current status

The author explicitly approved the complete reopened boundary-process contract
in two parts:

> **Approve Brown adherence boundary Stage 1 as written.**

> **Approve Brown adherence R² and Shapley amendment as written.**

This closes `BA-BG1` through `BA-BG15` without revision. It follows the
completed but Stage 3-ineligible beta-binomial Stage 2 assessment recorded
under `BA-001 / CHG-138`. That historical assessment remains preserved as an
acceptable-with-limitations benchmark for mean observed-valid-minute
contrasts, but it is not accepted for endpoint-probability claims and is not
authorized for Stage 3.

Brown recommendation adherence remains a standalone exploratory analysis. It
does not become an H01 through H11 hypothesis, replace an accepted hypothesis
result, or alter any existing multiplicity family outside this analysis. The
central `hypothesis_stage_gates.csv` therefore remains unchanged. This
decision, `BA-002`, and `CHG-140` are the central records for the reopened
boundary-process gate.

## Accepted Boundary Stage 1 identities

| Accepted artifact | SHA-256 |
|---|---|
| `audit/analyses/brown_adherence/05_boundary_process_audit_and_plan.qmd` | `e1474c56f55509ba707aca814812607339c3bfae3c694e3afe62717a1cf07642` |
| `audit/analyses/brown_adherence/05_boundary_process_audit_and_plan.html` | `d9fd179582d074c629e490df803da41ac89596f562d755f70f84d31586e08b8a` |
| `audit/analyses/brown_adherence/05a_r2_shapley_amendment.qmd` | `72ba06bd60b296b0b0b88874013c0a2f468d3858ce724cabf6db06b44c66c213` |
| `audit/analyses/brown_adherence/05a_r2_shapley_amendment.html` | `a617d68a25c9ccaccd42fe9f0cd46d2c03856e49e2ea306b680a6f61682216b3` |
| `audit/analyses/brown_adherence/05b_complete_stage1_author_approval.md` | `5359fddee72078511d88d7526dbaa624270590f25cdbba46f84940052877cc70` |
| `audit/analyses/brown_adherence/stage1_boundary/boundary_stage1_complete_author_gate.csv` | `6bf6dbe97eee2c8a4eb253d82a3d790f65d24b73fa644aff46109789b3df447a` |
| `audit/handoffs/brown_adherence_strategy_handoff.md` | `c541ddbeccdb52d09c6609a8fc305a917cb63f50728ebea406ad67574bdb8320` |

Independent R 4.6.1 verification passed all 22 boundary-report checks and all
22 R²/Shapley-amendment checks. It also matched all seven accepted artifacts,
all nine boundary-support manifest entries, all eight preserved input records,
and all ten shared scientific input pins retained from `BA-001`. The checks
used `data.table` 1.18.4, `digest` 0.6.39, and `xml2` 1.6.0, wrote only to a
temporary audit directory, and confirmed that no Boundary Stage 2 source,
output directory member, or fitted model exists.

## Preserved analytical input pins

Boundary Stage 2 must stop before fitting if any of these task-owned inputs do
not match:

| Preserved input | SHA-256 |
|---|---|
| `audit/analyses/brown_adherence/stage2/model_frames.rds` | `13ef1ed1e07d055e369b1e7d479285aee38a0587b61c5b87747067c3bc3a6821` |
| `audit/analyses/brown_adherence/stage2/frame_manifest.csv` | `47b94e517c3d5b0781dfebdd225a4a4f4dde178c9eb0ed66dc24fbad39ed837f` |
| `audit/analyses/brown_adherence/stage2/boundary_prediction.csv` | `18f751f5cf39ee1d64ffd20309cda9d8cb8e37b7c9c4a32928b5b42ed88b5666` |
| `audit/analyses/brown_adherence/stage2/stage2_author_gate.csv` | `c2c6885f98f065beea9f0a9c9378340a3ac513add582771c89a2bd655dc7cfc1` |
| `audit/analyses/brown_adherence/02_implementation_and_baseline_reconciliation.qmd` | `70b27411c4c3ad1591da839209c6eb2c0361e5ded66bc1e370088904a649e567` |
| `audit/analyses/brown_adherence/02_implementation_and_baseline_reconciliation.html` | `a3f2de7d792224bca55e094cbbaf0e8202285f39ff66b3f54df9c7e4d1613f7f` |
| `audit/analyses/brown_adherence/01_audit_and_plan.qmd` | `43926e02846c15ff521e65b0c7d43b23084231c13805ae57c8ff616e42de5c3f` |
| `audit/analyses/brown_adherence/01_audit_and_plan.html` | `24f6d8d55055af1bdb510de0bb7be446b3e382c5529096c048e0e8b26f8965a3` |
| `audit/analyses/brown_adherence/stage1_boundary/boundary_support_cell.csv` | `72ed423feb9c4244e6d7d0d831af5331beb45e98432db7f9c3eceb80a59a63c5` |
| `audit/analyses/brown_adherence/stage1_boundary/boundary_stage1_manifest.csv` | `954c74d5ac79cc5151fb18324f839360e7495b8b2e45430347166268b13ad320` |

The ten shared scientific inputs already pinned by `BA-001` also remain an
execution preflight requirement. Their current identities were independently
reverified without change. Boundary Stage 2 must consume the sealed task-owned
model frames rather than silently rebuilding or changing the accepted sample.

## Authorized Boundary Stage 2 scope

The Brown-adherence owner may now create:

- `audit/analyses/brown_adherence/06_boundary_process_implementation_and_reconciliation.qmd`; and
- task-owned code, models, diagnostics, tables, source data, manifests, and
  verification records under
  `audit/analyses/brown_adherence/stage2_boundary/`.

No accepted Stage 1 or historical Stage 2 file may be rewritten. No shared
file, package, `renv.lock`, preparation report, hypothesis report, manuscript,
or central ledger may be edited by the Brown task.

The bounded implementation contract is:

1. Validate the custom endpoint-inflated beta-binomial likelihood before its
   first Brown-data fit. The deterministic checks must cover probabilities,
   reduction to the beta-binomial, moments, CDF, random generation,
   derivatives, design matrices, random-effect indexing, and compilation from
   recorded task-owned C++ source under R 4.6.1 and TMB 1.9.21.
2. Fit the endpoint-inflated beta-binomial starting at the approved
   `F3/R0/Q0/D0` structures. Change only one structural dimension at a time
   through the approved `F`, `R`, `Q`, and `D` ladders, and record the exact
   structural failure that justifies every transition. Results, directions,
   p-values, or narrative convenience may not select a rung.
3. Fix the extra all-yes mass to zero for Wake while retaining ordinary
   beta-binomial all-yes probability. Keep the all-no and supported-state
   all-yes component ladders separate.
4. Use ordered beta only after every endpoint-inflated rung is unacceptable.
   Label it as an equal-period fallback, retain the sealed beta-binomial as the
   historical benchmark, and do not transfer the count-denominator estimand to
   the fallback.
5. Preserve the any-valid primary sample and repeat the identical at-least-80%
   sample as the mandatory claim gate. Preserve linkage C, the three accepted
   state intervals and thresholds, equal weighting of the nine sites, near-eye
   primacy, and the separate complementary chest placement check without
   pooling or an ocular interpretation of sleep-environment exposure.
6. Report overall marginal adherence and the all-no, mixed, and all-yes
   probabilities on the approved response scale. Assemble complete `BA-M1`
   through `BA-M5` families before FDR adjustment. Absolute adherence has a
   95% CI but no test against zero.
7. Retain the approved compact-table semantics, including the equal-site
   average row, same-day site deviations, separate `BA-M4` localization, and
   the restricted bolding rule.
8. Run the approved fit, rank, separation, endpoint-calibration, randomized
   quantile-residual, temporal, denominator, support, placement, and
   influence checks. The 250 conditional predictive draws with seed 20260814,
   nine leave-one-site-out fits, and bounded five-participant influence screen
   are authorized as required Stage 2 diagnostics.
9. Apply the 80% claim gate exactly: preserve each primary contrast direction
   and interval-exclusion status, with no absolute shift above 2 percentage
   points. Persistent material endpoint miscalibration blocks endpoint claims
   and Stage 3.
10. Only after a primary model is accepted, calculate the approved point-only
    response-scale marginal and conditional R², random-effect increment, and
    full-model Shapley allocation across State, Site, and Day type. Use the
    balanced 54-cell reference grid, empirical denominator distributions,
    integrated retained random effects, all eight Shapley subsets, within-state
    Site and Day-type allocations, the identical 80% sensitivity, and the
    15-node versus 30-node 0.05-percentage-point quadrature gate. Do not attach
    confidence intervals or p-values, refit reduced models for the
    decomposition, or use it for model selection.

Ordinary bounded candidate fits and the listed diagnostics are authorized.
A broad simulation-recovery study, bootstrap, exhaustive participant-deletion
battery, or other heavy production computation is not authorized. If such
work becomes necessary, first propose a separate 50- or 100-replicate pilot
and obtain a new coordinator and author decision before running it.

## Mandatory stop gate

After the authorized implementation, fits, diagnostics, sensitivities,
multiplicity calculations, compact tables, and R²/Shapley outputs are complete
and verified, stop at `BA-BS2-REVIEW` for explicit author review. The report
must distinguish acceptability of overall adherence from acceptability of
endpoint probabilities and must disclose every entered structural rung and
limitation.

No Boundary Stage 2 estimate, p-value, FDR result, diagnostic disposition, or
claim is author accepted by this transition. Stage 3, Stage 4, shared Quarto
integration, shared preparation changes, manuscript integration, commit,
push, upload, and heavy production computation remain unauthorized.

## Reopening condition

Reopen `BA-002` before further fitting if a pinned identity changes, the
accepted frame or support does not reconcile, the custom likelihood cannot be
validated, the approved ladder or estimand cannot be implemented, a new
package or response family is required, or the author changes any item in
`BA-BG1` through `BA-BG15`.
