# H11 worker handoff

Date: 2026-08-06  
Branch: `rewrite/NH`  
Current gate: **Stage 4 H11-owned work complete; shared-site integration pending**

## Scope completed

H11 has been audited, implemented with the author-approved robust inferential
method, compared with the prior implementation, and translated into a
reader-facing Stage 3 report. The author accepted that report on 2026-08-06.
The analysis-preparation and provenance companion is now also complete within
H11 ownership. The result report includes the author-requested same-sample
activity-context sensitivity and revised level/shape language.
The final Diagnostics section now also contains an author-requested visual
summary of residual location, tails, and fitted-value-dependent spread in
addition to the two boundary-aware residual-dependence figures.

Near eye remains primary and chest complementary. The measured predictor is
biological sex; gender is treated as a distinct, unmeasured construct. The H11
models retain the finalized H02 temporal basis, participant/day hierarchy,
site constraint, clock-time provenance, AR boundaries, and diagnostic rules.

## REPORT-016 / RH-SCI-002 disposition

**Disposition: (c), outside/superseded by the accepted H11 analysis.** The
registered hourly geometric-mean outcome remains part of the preregistration
provenance, but it is not an outstanding H11 sensitivity requirement.

This disposition reconciles the full accepted record:

- the signed preregistration specified the hourly geometric mean;
- the historical Stage 1 proposal named an hourly sensitivity, and the frozen
  Stage 2 deferred-analysis registry records that it was not fitted;
- the author-approved H11 analysis deliberately inherits the accepted H02
  zero-aware transformed arithmetic mean in supported 30-minute bins;
- the accepted Stage 3 report and Stage 4 transition closed H11 scientific
  computation, and this handoff already records that no further H11 scientific
  computation is required; and
- the authoritative REPORT-016 reader-disposition overlay classifies
  `DEV-042` as `approved_implemented_verified`, while `DEV-003` is the current
  open qualification.

The stale “unresolved sensitivity” wording has therefore been corrected only
in the current H11 result source and preparation/provenance companion. The
historical Stage 1 plan, author decision, Stage 2 report, and frozen deferred-
analysis registry remain unchanged. No model, frame, prediction, estimate,
interval, p-value, multiplicity decision, diagnostic, sensitivity output, or
scientific result was recomputed or changed. The row-level reconciliation and
identity evidence are recorded in
`audit/hypotheses/H11/06_report016_hourly_outcome_disposition.md` and its paired
CSV.

The worker did not edit central ledgers, shared Quarto configuration,
manuscript files, the bibliography, or `renv.lock`, and did not push.

## Author decisions incorporated

1. Pointwise rather than simultaneous 95% confidence intervals.
2. H02-like biological-sex effect-size summaries only after a supported global
   sex curve.
3. H11-METHOD-001 through H11-METHOD-007: AR-whitened participant-cluster CR1
   complete-curve inference with smoothing-bias covariance and a finite-cluster
   fractional-rank F reference.
4. The global curve is the primary decision; level and shape form a secondary
   two-test BH attribution family.
5. The secondary decomposition must be described as an inability to resolve
   the joint curve cleanly, not as invalidating the global result.
6. Add the recorded hourly activity context in an exploratory same-sample
   sensitivity.
7. Run an activity-adjusted sex effect-size estimator only if the adjusted raw
   global *p* is below 0.050. The gate remained closed at both placements.
8. Use the approved true melEDI symlog transform, linear to 1 lx.
9. Show figures for the main continuous diagnostic outcomes in the reader
   report while retaining discrete pass/fail checks in the diagnostic table.

## Accepted global results

| Analysis | Participants | Participant-days | Observations | F | Fractional numerator df | Denominator df | Raw/BH p |
|---|---:|---:|---:|---:|---:|---:|---:|
| Near eye, primary | 141 | 816 | 37,756 | 20.946 | 9.692 | 131 | **0.028** |
| Chest, primary | 154 | 902 | 41,842 | 4.876 | 1.003 | 152 | **0.029** |
| Near eye, gap-timing-unaware | 141 | 809 | 37,603 | 20.501 | 9.612 | 131 | **0.026** |
| Chest, gap-timing-unaware | 154 | 894 | 41,664 | 4.418 | 1.005 | 152 | **0.037** |

Near-eye descriptive pointwise exclusions occur at displayed bins from
07:00–10:00 and 16:00–18:30. The minimum shifted Female-to-Male ratio is 0.471
at 08:45 (pointwise 95% CI 0.284–0.779). The chest ratio is nearly constant at
0.793 (0.645–0.976). These do not establish simultaneous significant periods.

The secondary decomposition does not independently resolve either accepted
curve after its two-test BH adjustment:

- near-eye level: raw/BH *p* = 0.075/0.075;
- near-eye shape: 0.043/0.075;
- chest level: 0.029/0.057; and
- chest shape: 0.986/0.986.

This qualification concerns attribution to level or shape; it does not alter
the global complete-curve decisions.

## Activity-context sensitivity

Only exactly-one-selected diary hours were used. Multi-label, zero-label,
all-missing, and exactly-one unspecified-other hours were excluded. Retained
contexts are home (reference), sleep, road or vehicle, indoor work, and outdoor
activity. Thirty-minute exposure rows were mapped only when wholly contained
within a unique diary hour, without duplication. `AR.start` was rebuilt after
filtering.

The activity-complete unadjusted and adjusted models use identical observations
within placement. The adjusted model adds the activity main effect and cyclic
activity-specific temporal deviations. One rho from the preliminary adjusted
model is held fixed in both final same-sample models.

| Placement | Sample | Participants | Participant-days | Observations | Raw/BH p | Decision |
|---|---|---:|---:|---:|---:|---|
| Near eye | Activity-complete, unadjusted | 126 | 724 | 30,499 | 0.160 | not supported |
| Near eye | Same sample, activity-adjusted | 126 | 724 | 30,499 | 0.364 | not supported |
| Chest | Activity-complete, unadjusted | 150 | 875 | 36,711 | **0.025** | supported in exploratory model |
| Chest | Same sample, activity-adjusted | 150 | 875 | 36,711 | 0.050 | not supported; full precision 0.05021431625 |

For near eye, restriction to activity-complete rows already removes threshold
support before activity enters; activity cannot be credited with making the
effect disappear. At chest, adjustment modestly attenuates the curve and moves
the *p*-value just above 0.050, but this does not demonstrate mediation or a
behavioural mechanism.

The adjusted near-eye minimum ratio is 0.729 (pointwise 95% CI 0.488–1.090) at
08:15. The adjusted chest ratio is approximately 0.826 (0.682–1.000; exact
upper endpoint 1.000034). No adjusted pointwise interval excludes one. The
activity-adjusted effect-size gate remained closed, so no activity effect-size
bootstrap was run.

All four activity-complete fits are **acceptable with specified limitations**.
Final boundary-aware lag-1 correlations are 0.144/0.084 near eye and
0.131/0.075 chest for unadjusted/adjusted fits. Maximum participant robust-
covariance shares remain below 8%.

The authoritative 48-file activity output inventory is
`artifacts/12_manifests/H11/H11_activity_context_output_hashes.csv`, SHA-256
`6960448adc102d29ff48c06d07eb53cdb97a1bba89ea7dce73f779d5c5a4eecc`.

## Reader and display implementation

- Reader source: `notebooks/hypotheses/H11.qmd`
- Rendered report: `_build/nathealth/notebooks/hypotheses/H11.html`
- Reader tables: `artifacts/09_tables/H11/stage3/`
- Reader source data: `artifacts/11_source_data/H11/stage3/`
- Reader diagnostics: `artifacts/08_diagnostics/H11/stage3/`
- Eight tightly bounded figures: `artifacts/10_figures/H11/stage3/`
- Figure manifest and QA: `artifacts/12_manifests/H11/`
- Scientific/activity amendment:
  `audit/hypotheses/H11/04_activity_context_results_and_stage3_revision.md`
- Current author gate: `audit/hypotheses/H11/03_stage3_author_gate.md`
- Diagnostic-figure revision:
  `audit/hypotheses/H11/05_reader_diagnostic_figure_addition.md`

The four melEDI panels use
`LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)`, with an original-unit
axis linear from 0 to 1 lx and base-10 logarithmic above 1 lx. Ratio panels use
a log-ratio scale. All eight exported assets passed physical-size A4 QA at an
intended 170-mm display width using the approved 14/12/11-pt source convention.
The tightly bounded 10.5-inch exports are reduced from 266.7 mm to 170 mm;
12-pt essential text therefore resolves to 7.65 pt and 11-pt minor text to
7.01 pt. The QA-only eight-page A4 proof is stored under manifests, not in the
final figure folder.

## Reporting policies

- REPORT-008: p-value display and independent bolding implemented.
- REPORT-009: no invalid unmatched placement identity plot.
- REPORT-010: exact gap-timing-unaware terminology implemented.
- REPORT-011: actual-export physical-size QA recorded for eight figures, with
  all essential and minor text at least 7 pt at the intended final width.
- REPORT-012: callout titled exactly “Answer in brief.”
- REPORT-013: exact LightLogR symlog transform implemented.

## Analysis preparation and provenance companion

The accepted reader report now links reciprocally to
`audit/hypotheses/H11/H11_analysis_preparation.qmd`. The companion documents:

- the ten verified consequential inputs and their SHA-256 identities;
- schema, key, response, biological-sex, support, and AR-boundary checks for
  all six frozen analysis frames;
- the exact primary, effect-size-baseline, activity-adjusted, and
  activity-adjusted no-sex Wilkinson formulas;
- exact candidate and fitted samples, temporal order, coverage, gap handling,
  transformation, estimands, multiplicity, and pointwise uncertainty;
- the complete-curve interpretation and the fact that the two-test BH result
  limits level/shape attribution without invalidating the global test;
- activity matching, attrition, same-sample adjustment, and the closed
  activity-adjusted effect-size branch;
- diagnostics, robust influence, sensitivity scope, placement-display
  inapplicability, code order, output provenance, and environment identity.

The companion render performs no model fit, rho estimation, prediction,
bootstrap, simulation, or robust-test recomputation. It contains 26 readable
`gt` tables and three preparation figures. Those figures passed 170-mm A4
physical-size QA: 10-pt essential source text resolves to 7.87 pt, 9-pt minor
text to 7.09 pt, and all clipping, overlap, wrapping, distortion, balance, and
mark-distinguishability checks passed. The melEDI distribution uses the exact
REPORT-013 symlog transform and untransformed paired source data. Following
author review, the activity-attrition display uses paired horizontal bars from
a shared 0% baseline with direct percentage labels; the ambiguous zero-to-dot
segments were removed without changing any source value.

Principal files:

- source: `audit/hypotheses/H11/H11_analysis_preparation.qmd`;
- pre-integration render:
  `_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html`;
- preparation figures: `artifacts/10_figures/H11/preparation/`;
- paired preparation source data:
  `artifacts/11_source_data/H11/preparation/`;
- physical-size QA:
  `audit/hypotheses/H11/H11_preparation_figure_readability_qa.md`;
- 282-file preparation inventory:
  `artifacts/12_manifests/H11/H11_preparation_report_manifest.csv`, SHA-256
  `00ce783a5958f6f958db1d2d6d78076760953ad1c51cc18c30abb697557c8e5c`.

The source and website QMD copy are byte-identical at SHA-256
`a2d25df408b7282691342a19b030427c2fea6111a04719ffb8c6e382bab92def`.
The current accepted result inventory contains 69 files, including the new
diagnostic source data, figure, audit record, and updated physical-size QA;
manifest SHA-256
`2f55cef62117af71beab6e320fac842489b24be149209ea60a1d54cbd172f645`.

## Verification

Scientific computation and report execution use:

```text
R_PROFILE_USER=/dev/null
R_LIBS_USER=renv/library/macos/R-4.6/aarch64-apple-darwin23
R 4.6.1
```

Only the H11 notebook and H11-scoped tests/renders are run. Full-precision
scientific artifacts are checked against their authoritative manifests before
reader selection. The reader render does not refit models or rerun resampling.

Commands completed successfully:

```text
Rscript scripts/hypotheses/H11/build_h11_stage3_reader_artifacts.R
Rscript scripts/hypotheses/H11/build_h11_stage3_figures.R
Rscript scripts/hypotheses/H11/finalize_h11_stage3_figure_qa.R
Rscript scripts/hypotheses/H11/build_h11_preparation_artifacts.R
Rscript scripts/hypotheses/H11/finalize_h11_preparation_figure_qa.R
quarto render notebooks/hypotheses/H11.qmd --profile nathealth
quarto render audit/hypotheses/H11/H11_analysis_preparation.qmd --profile nathealth
Rscript scripts/hypotheses/H11/build_h11_stage3_manifest.R
Rscript tests/hypotheses/H11/test_h11_stage3_reader_report.R
Rscript scripts/hypotheses/H11/build_h11_preparation_report_manifest.R
Rscript tests/hypotheses/H11/test_h11_preparation_report.R
```

The reader test reports eight image figures with non-empty alt text, including
three figures in the Diagnostics section. The preparation test reports 30
rendered figure containers, including three preparation image figures, 26
`gt` tables, 282 manifest identities, and a
byte-identical source copy. The full shared REPORT-007 adjacency verifier is
intentionally deferred until the coordinator-owned profile insertion exists.

## Proposed coordinator-owned ledger entries

| Ledger | Proposed entry |
|---|---|
| Decision register | Record the author-approved interpretation that the BH component family limits attribution without invalidating the global test. |
| Deviation register | Add the exploratory same-sample activity-context adjustment and its non-causal role. |
| Sample flow | Add 126 participants/724 days/30,499 rows near eye and 150/875/36,711 chest for activity-complete models. |
| Result comparison | Near eye 0.160 to 0.364 after adjustment; chest 0.025 to 0.050, with selection and adjustment separated. |
| Claim provenance | Accepted all-available global results remain primary; activity sensitivity does not identify mediation. |
| Reporting QA | Eight figures pass REPORT-011 at >=7-pt final text; melEDI panels use REPORT-013 true symlog. |
| Hypothesis stage gate | Stage 3 accepted; H11-owned Stage 4 companion complete; shared-site integration pending. |
| Preparation provenance | Add the reciprocal H11 preparation companion, its 282-file identity inventory, and three-figure REPORT-011 QA record. |

## Current gate

No further H11 scientific computation is required. The coordinator should
apply the exact render-list and navigation insertion requested in
`audit/handoffs/H11_shared_change_request.md`, perform the bounded site render,
rebuild the preparation manifest, and rerun the H11 preparation test. Until
that shared change is made, the H11-owned companion is complete and the shared
REPORT-007 adjacency check remains pending. Do not modify central ledgers,
manuscript files, or other shared surfaces from the H11 worker scope.
