# H06_daily H01-aligned diagnostic assessment

Decision ID: `H06-D-014`  
Change ID: `CHG-127`  
Date: 2026-08-12  
Status: author-approved no-refit diagnostic amendment

## Author decision

The author directed H06_daily to apply the H01 diagnostic rules to the daily
metrics. Autoregressive checks must remain visible in result summaries, but
they must not make an otherwise adequate result fail.

This is a diagnostic-classification and reporting amendment. It does not
authorize a fit or refit, a new estimate or interval, a raw-p or FDR update, a
deletion analysis, Stage 3 or Stage 4, a main-H06 change, shared-data work,
commit, or push.

## H01-aligned rule with visual residual judgment

The controlling classification architecture is the H01 overall diagnostic
rule in `scripts/hypotheses/H01/h01_modeling.R`, refined by the author's
explicit instruction that residual distribution must be judged visually.
H06_daily must reproduce the three classes in a new derived audit table rather
than reinterpret the existing H06_daily model outputs in place:

1. `FAIL_MAJOR_GATE` (reader label **Not acceptable**) applies only when the
   base analysis has a fit error or unavailable required result, did not
   converge, lacks a positive-definite Hessian, is singular, is rank- or
   covariance-deficient/non-estimable, lacks required timing or clock support,
   contains observed values outside the valid response support, or receives a
   visually reviewed residual verdict of `FAIL_GROSS`.
2. `WARN_REVIEW` (reader label **Acceptable with limitations**) applies when
   no hard gate fails but the visually reviewed residual verdict is
   `REVIEW_LIMITATION`, or the base fit has a predicted-value-bound warning,
   an audit-threshold warning, or a fit warning.
3. `PASS` (reader label **Acceptable**) applies when neither condition above
   is present and the visually reviewed residual verdict is `PASS`.

The derived output must retain both the exact H01 class and the plain reader
label. Claim eligibility may be blocked by `FAIL_MAJOR_GATE`; it may not be
blocked solely by any sidecar diagnostic named below. Statistical support
still requires the existing full-precision FDR decision and every scientific
qualification remains reportable.

## Sidecar evidence that cannot set the overall class

The following evidence remains mandatory, must remain linked row-for-row to
the relevant result, and must be summarized in plain language, but does not
feed the H01-aligned overall diagnostic class or claim-eligibility field:

- AR trigger status, AR convergence or numerical behavior, rho, post-AR
  residual dependence, and AR-versus-base effect shifts;
- participant- and site-deletion influence results, including incomplete or
  non-estimable deletion refits;
- exact-period/longest-period sensitivity results; and
- Student-t, Tweedie, or other response-family sensitivity results.

A sidecar result still triggers a hard failure if it demonstrates a genuine
construct or observed-support failure in the base estimand. It may also be
described as a major limitation. It must not silently change the model,
sample, estimator, covariance, multiplicity family, or claim.

## Required visual residual assessment

Residual normality, homoscedasticity, and centering must not be accepted or
rejected by a hard numerical test or threshold. Existing numeric summaries
may be retained as navigation aids and reproducible evidence, but they cannot
determine the residual verdict.

For every model cell, inspect plots derived only from the already stored fit
and residual data:

- Gaussian mixed-model and participant-cluster HC3 cells require a residual-
  versus-fitted display for zero-centering and variance structure plus a Q-Q
  display for gross departures from normality.
- Tweedie cells require a Pearson-residual-versus-fitted display for gross
  structure and variance problems plus zero-mass and prediction-support
  displays. Pearson residuals are not required to be normally distributed.

Record exactly one per-cell verdict: `PASS`, `REVIEW_LIMITATION`, or
`FAIL_GROSS`. Each record must include the reviewer, review date, concise
reason codes, a plain-language explanation, the diagnostic-plot identity,
and the source-data identity. Gross visual failures may make a cell not
acceptable; ordinary departures are limitations. Generate plots only from
frozen stored values and do not refit, resimulate, or regenerate scientific
predictions. Use consistent, readable physical-size exports and an indexed
review layout so every cell can be inspected without clipped or illegible
content.

## Exact no-refit scope

### Remaining non-L10 Stage 2 production grid

Preserve the completed H06-D-013 scientific outputs byte-for-byte. From the
stored diagnostic components only, derive the H01-aligned status for all 468
production cells and rebuild only dependent diagnostic/claim-display fields
in new H06_daily-owned amendment artifacts. The worker's static replay reports
the expected cross-check totals as 311 `PASS`, 157 `WARN_REVIEW`, and 0
`FAIL_MAJOR_GATE`; the 39 primary near-eye cells are expected to split 26,
13, and 0. These counts are not accepted by this decision until the task
independently reproduces them in R 4.6.1 and seals their row-level provenance.

No model object, frame, coefficient, standard error, confidence interval, raw
p-value, FDR-adjusted p-value, FDR rank, or FDR significance decision may
change. Existing H06-D-G2 files remain immutable historical evidence; the new
amendment supersedes only their diagnostic-status and dependent claim-
eligibility interpretation.

### Shifted-log L10 pilot

Apply the same rule to the already fitted H06-D-003 shifted-log L10 pilot.
Its AR-only failure is now a nonblocking sidecar. The pilot's residual,
zero-mass, prediction-bound, and response-family evidence remains visible,
including the reported major Student-t limitations. If the stored base-fit
evidence passes every hard gate, its revised pilot assessment is **Acceptable
with limitations**.

This reclassification does not authorize the full shifted-log L10 batch, does
not populate L10 in any 15-slot FDR family, and does not accept any pilot raw
p-value. Those steps still require a separate explicit author decision. The
historical two-part L10 route remains **Not acceptable/non-estimable** because
component separation is a hard estimability failure; its raw and adjusted
p-values remain missing.

### MDER and other frozen branches

MDER, temporal-GAMM, and pre-sleep no-nugget model outputs remain frozen. The
task may apply the same no-refit diagnostic mapping to already stored MDER
evidence if it is needed for one coherent H06_daily Stage 2 summary, but may
write only new amendment artifacts and dependent display fields. It may not
change an MDER model, estimate, interval, raw/FDR value, support decision, or
claim except for the diagnostic-eligibility consequence of this author rule.
The temporal-GAMM and pre-sleep no-nugget results remain sidecar evidence.

Main hourly H06 is outside this amendment and remains the selected primary
H06 route; H06_daily remains complementary evidence.

## Required task-owned amendment and verification

The H06_daily task may now create one separate no-refit diagnostic-alignment
amendment report, transition record, row-level classification and claim-
eligibility tables, non-circular manifests, and focused tests. It must:

- pin `H06-D-014`, the exact H01 source implementation, the completed
  H06-D-G2 identities, the shifted-log pilot identities, and every frozen
  upstream identity it reads;
- prove the source scientific outputs are byte-identical before and after;
- reproduce the provisional non-visual 468-cell and 39-cell mapping in R
  4.6.1, then replace its residual component with the sealed per-cell visual
  verdicts and report the final counts separately;
- verify that no numeric residual test or threshold automatically sets a
  residual or overall verdict;
- show separately how many FDR-supported association and site-interaction
  results become claim-eligible under the revised rule, without changing any
  FDR value or decision;
- retain every AR, influence, period, and family-sensitivity qualification in
  the row-level output and reader summary; and
- explicitly distinguish revised diagnostic eligibility from scientific
  strength, robustness, and preregistration status.

After focused verification, stop at `H06-D-G2A` for explicit author review.
Stage 3 and Stage 4 remain blocked.

## Reopening condition

Reopen if the H01 implementation or the author-defined visual residual rule
changes, an input or frozen identity changes, the provisional replay cannot be
reproduced, a per-cell plot/source identity or review record is missing, a
numeric residual threshold sets a verdict, a hard-gate mapping is ambiguous,
an AR/influence/period/family result is lost from the sidecar evidence, a
model or FDR field changes, or the author requests L10 production or a
different diagnostic rule.
