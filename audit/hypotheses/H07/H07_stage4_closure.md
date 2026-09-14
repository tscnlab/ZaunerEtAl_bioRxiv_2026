# H07 four-stage workflow closure

Decision ID: `H07-005`
Date: 2026-08-07
Status: approved

## Decision

The author accepted `H07-S4-001` through `H07-S4-004` and requested that the
H07 worker wrap up and commit the H07-owned work. The authoritative
reader-facing result is `notebooks/hypotheses/H07.qmd`; its scientific
analysis-preparation and provenance companion is
`audit/hypotheses/H07/H07_analysis_preparation.qmd`.

The H07-owned four-stage workflow is closed. Coordinator-owned integration of
the preparation page into `_quarto-nathealth.yml`, shared navigation, and
central ledgers remains pending under
`audit/handoffs/H07_shared_change_request.md`. That integration is
administrative and must not rerun or change the accepted scientific analysis.

## Accepted scientific disposition

- The descriptive derivative-defined plateau pattern is present for six of
  nine primary near-eye metrics and seven of nine complementary chest metrics.
- The pattern requires a pointwise detected increase followed immediately by
  a zero-compatible derivative whose pointwise 95% interval continues to
  contain zero through the longest recorded photoperiod.
- The result is not an equivalence test and does not establish an asymptote,
  mechanistic ceiling, causal photoperiod effect, distinct latitude effect,
  placement equivalence, or clinical or health outcome.
- Absolute latitude is fixed within site; site photoperiod ranges overlap only
  partly; collection periods differ; participant-smooth concurvity is very
  high; and sample, model-form, metric-definition, and site-omission
  sensitivities limit interpretation.
- H07 used `mgcv::gam(method = "REML")`, not `bam()`. The H11
  `discrete = FALSE` alternative is therefore not applicable.
- The accepted preparation companion reports frozen results only. It contains
  no model fit, prediction, derivative calculation, simulation, or bootstrap.

## Evidence and verification

- `audit/hypotheses/H07/H07_analysis_preparation.qmd` and its bounded render;
- `notebooks/hypotheses/H07.qmd` and its Nature Health render;
- `audit/hypotheses/H07/H07_figure_readability_qa.md`;
- `artifacts/12_manifests/H07/H07_figure_readability_qa.csv`;
- `artifacts/12_manifests/H07/H07_preparation_report_manifest.csv`;
- `tests/hypotheses/H07/test_h07_stage3_reader_report.R`;
- `tests/hypotheses/H07/test_h07_preparation_report.R`; and
- `audit/handoffs/H07_worker_handoff.md`.

The Stage 3 and preparation-focused checks pass under R 4.6.1. The preparation
render contains 20 semantic `gt` tables and two external figures with captions
and non-empty alternative text. All four reader-facing H07 figures pass
REPORT-011 inspection at 170-mm display width. The expected website source is
byte-identical to the authoring QMD.

## METRIC-011 sealed-input addendum

On 2026-08-12, the shared METRIC-011 numerical-zero normalization activated
the sealed-input reopen rule for eight primary L10 mean cells. The H07 worker
reopened only the L10 mean primary, declared sensitivity, diagnostic, and
leave-one-site-out branches and BH fields in families containing L10. The
historical V0 reconstruction and every non-L10 fit and raw test remained
frozen.

The bounded reconciliation changed no fitted sample, diagnostic category,
derivative classification, transition grid point, conditional-AIC category,
BH significance label, or REPORT-008 three-decimal value. The accepted
scientific disposition above is therefore unchanged and decision `H07-005`
remains closed without a new author gate. The durable addendum and exact
artifact hashes are recorded in
`audit/hypotheses/H07/H07_METRIC-011_reconciliation.md` and
`artifacts/12_manifests/H07/H07_METRIC-011_*.csv`.

## Reopen rule

Reopen H07 only if a sealed scientific input or output changes, a focused
verifier fails, the accepted model, derivative rule, sample, response
construction, classification, diagnostic disposition, sensitivity result, or
claim scope changes, or shared integration exposes a substantive provenance
discrepancy. Navigation, link, checksum, provenance, or display-only repairs
do not reopen the accepted inference.
