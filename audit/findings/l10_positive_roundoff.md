# Positive L10 numerical residuals from all-zero source windows

Finding ID: `FIND-050`  
Date: 2026-08-12  
Status: **repaired and independently verified; bounded downstream L10 updates required**  
Severity: low numerical error; high importance for response-family and zero-mass handling

## Finding

Eight primary L10 mean melEDI cells were stored as
`4.163336342344337e-17` lx although every finite one-minute melEDI value in
their selected 10-hour window was exactly zero. The residual arose from the
zero-aware geometric-mean calculation: floating-point evaluation of the
shifted mean produced a value infinitesimally above the 0.1-lx offset before
the offset was subtracted.

The affected records are three near-eye participant-days and five chest
participant-days. Seven selected windows contain 600 observed zero minutes.
The KNUST_S002 chest window on 2024-10-19 contains 547 observed zero minutes
and 53 missing minutes; the missing minutes remain missing and the window
still satisfies the existing 80% support requirement.

These residuals are not genuine positive exposure. Treating them as positive
would incorrectly move the records from the zero part to the positive part of
a two-part model.

## Resolution

`METRIC-011` introduces a shared, pre-model numerical-zero rule based on R
machine precision, the transformed scale, the non-negative measurement
domain, and exact source provenance. It preserves every raw value and source
count in a row-level audit. The full metric package and inherited preparation
layers were rebuilt and independently verified in R 4.6.1.

The primary scientific change is exactly eight L10 mean cells from the tiny
positive residual to zero. The full audit also retains the four historical
negative-domain roundoff normalizations documented in `FIND-033`, for twelve
audited L10 cells in total.

## Evidence

- `audit/decisions/l10_numerical_zero_normalization.md`
- `audit/reconciliation/l10_METRIC-011/positive_roundoff_reclassifications.csv`
- `audit/reconciliation/l10_METRIC-011/primary_scientific_cell_changes.csv`
- `audit/reconciliation/l10_METRIC-011/invariance_summary.csv`
- `audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv`
- `artifacts/05_metrics/metrics_glasses_numerical_zero_audit.csv`
- `artifacts/05_metrics/metrics_chest_numerical_zero_audit.csv`

## Result effect

No shared sample count changes. L10 mean response values and their zero mass
change in affected downstream analyses. Those analyses must update only their
L10-dependent model branches, diagnostics, sensitivity outputs, and complete
multiplicity-family derivatives; every non-L10 fit and raw test remains
frozen. The gap-timing-unaware scientific data and all L10 midpoint values are
unchanged.

## Reopening condition

Reopen under any condition listed in `METRIC-011`, if a downstream analysis
does not retain these records as zeros where its response permits zero, or if
an L10-dependent result cannot be reconciled while non-L10 outputs remain
frozen.
