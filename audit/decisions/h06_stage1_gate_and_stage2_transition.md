# H06 Stage 1 gate and Stage 2 transition

Decision ID: `H06-001`  
Date: 2026-08-01  
Status: approved

## Evidence reviewed

The coordinator independently verified the revised Stage 1 source and render:

- `audit/hypotheses/H06/01_audit_and_plan.qmd`, SHA-256
  `411fbfe289b3ec6014a6e319516b5773d94a03276a8b98e2581773e3d23c45fc`;
- `audit/hypotheses/H06/01_audit_and_plan.html`, SHA-256
  `529036b06356ac64ca94eb6e5b7b228303bf5c00d5a0c1a9032bead9b649a099`;
- `audit/handoffs/H06_worker_handoff.md`; and
- `audit/handoffs/H06_shared_change_request.md`.

R 4.6.1 checks independently confirmed that the source parses, the rendered
page contains the approved contract, and the pinned TUM exercise diary has
seven corrected `TUM_S001` records and zero `TUM_S101` records.

## Approved Stage 2 contract

H06-G1 is closed in favor of the deliberate hourly adaptation. The registered
daily-metric question remains visible as a scientifically distinct unselected
reference, not as an active second primary analysis.

Stage 2 is authorized under the following fixed contract:

1. The primary outcome is supported one-hour zero-aware geometric mean melEDI.
2. The three primary predictors are work/free day, binary activity
   (`Sedentary` versus `Active`), and previous-night sleep duration.
   Weekday/weekend is an estimate-and-95%-CI sensitivity. Other named day,
   exercise, and sleep predictors are exploratory only.
3. The primary site formulation uses fixed site, sum-to-zero contrasts,
   separate hierarchy-preserving heterogeneity tests, and equal-site
   reader-facing marginalization. The registered random-site model is a
   comparison.
4. Participant and participant-day intercepts and a true-time,
   participant-day- and gap-bounded AR(1) represent repeated observations.
   The confirmatory model has no local-clock term and estimates an
   observed-supported-hour-weighted average.
5. Time of day is confined to a separately labelled exploratory GAM/GAMM.
   Its fit and every downstream calculation must remain compatible with
   `mgcv::bam(discrete = TRUE)`.
6. The active Benjamini--Hochberg families are `H06-F1-main` (3),
   `H06-F2-heterogeneity` (3), `H06-F3-practical-contrasts` (3),
   `H06-F1-gap` (3), and `H06-F2-gap` (3). There is no site-specific or
   paired-placement significance screen.
7. Near-eye is primary. Paired/common-sample near-eye and chest models are
   complementary, and all-available chest results are contextual.
8. The `KNUST_S005` 2024-11-04 source numeral 3,600 is interpreted only in
   the H06-owned exploratory adapter as 3,600 seconds (1 h), with row-level
   provenance. The shared source remains unchanged.
9. DEV-056 remains pinned to `melidosData` 1.0.6. Stage 2 performs only the
   read-only seven-`S001`/zero-`S101` assertion and does not fetch, update, or
   rebuild shared preparation.
10. Stage 2 reports exact fitted samples, 95% confidence intervals,
    REPORT-008 p-values, and interpreted convergence, distributional,
    residual, temporal, and influence diagnostics. Heavy resampling follows
    the 50- or 100-replicate pilot gate.

Stage 2 must recreate and compare the V0 outputs, then stop for author review.
No H06 model had been fitted when this gate was opened.

## Shared documentation disposition

The stale Preparation 06 narrative is a coordinator-owned documentation
repair. It does not change the current approved 816-day near-eye and 902-day
chest input bundle, and it does not block H06 Stage 2.

## Reopening condition

Reopen H06-G1 if the outcome, core predictor set, site formulation, temporal
dependence, marginalization, multiplicity families, placement role, source
pin, or exploratory/confirmatory boundary changes, or if Stage 2 cannot fit
the approved contract without a scientific amendment.
