# Numerical-zero normalization for offset geometric means

Decision ID: `METRIC-011`  
Author decision: 2026-08-11  
Implemented and independently verified: 2026-08-12  
Status: **approved and implemented; affected downstream L10 branches open for bounded resealing**

## Decision

Light exposure is non-negative. A value produced by subtracting the fixed
0.1-lx offset after a geometric-mean back-transformation is therefore set to
exact zero only under the following pre-model rule:

1. Calculate the shifted mean and unrounded back-transform as
   `shifted_mean = 10^mean(log10(melEDI + 0.1))` and
   `raw_value = shifted_mean - 0.1`.
2. Define the unit-aware numerical tolerance as
   `100 * .Machine$double.eps * max(1, abs(shifted_mean), abs(0.1))` lx.
   For the affected L10 windows this is
   `2.220446049250313e-14` lx.
3. Stop if `raw_value` is materially below zero, meaning below the negative
   tolerance.
4. A negative value within tolerance is normalized to zero because negative
   light exposure is outside the measurement domain.
5. A positive value within tolerance is normalized to zero only when every
   finite source value entering that geometric mean is exactly zero. Missing
   minutes remain missing, are counted in the row-level audit, and are never
   imputed as zeros.
6. A positive value is otherwise retained, even when it is small. The rule is
   tied to floating-point precision and source provenance, not to a fitted
   model, statistical result, or arbitrary scientific cutoff.

The raw back-transformed value, shifted mean, tolerance, selected window,
finite/zero/positive/missing source-minute counts, placement, participant-day,
reason, and normalized value are preserved in placement-specific audit CSVs.

## Model handling

- Zero-capable outcomes retain the participant-day as an exact zero.
- In a two-part model, the participant-day remains in the zero/occurrence
  component and is excluded only from the strictly positive magnitude
  component by definition.
- No participant-day may be discarded merely to satisfy a positive-only
  response family.
- The rule is applied in shared metric preparation before any hypothesis
  model frame is constructed.

## Verified scope

The full primary rebuild contains twelve audited numerical-zero
normalizations, all for L10 mean melEDI: the four previously documented
negative-domain residuals under `FIND-033` and eight positive residuals of
`4.163336342344337e-17` lx. The eight newly affected cells comprise three
near-eye and five chest participant-days. Seven selected windows contain
600 observed zero minutes; one chest window contains 547 observed zero
minutes and 53 missing minutes. All satisfy the existing 80% L10 support rule.

No positive numerical-zero residual was found in daily geometric mean melEDI,
M10 mean, one-hour zero-aware geometric means, or the gap-timing-unaware
prepared data. Exact before/after comparison established that:

- only those eight primary L10 mean cells changed scientifically;
- every non-L10 participant-day value is unchanged;
- all 30-minute, hourly, and participant-level scientific values are
  unchanged;
- site/daylight-context values are unchanged;
- primary H01 preparation changes only inherited L10 model-row values and not
  its sample contract; and
- gap-timing-unaware H01 scientific values are unchanged and only their
  provenance identity is repinned.

No hypothesis model, prediction, diagnostic, resampling result, figure, table,
or claim was recomputed during the shared rebuild.

## Sealed identities

| Artifact | SHA-256 |
|---|---|
| Metric-artifact manifest | `028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e` |
| Site/daylight-context manifest | `c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518` |
| Base-model-data manifest | `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce` |
| Base-model input bundle | `e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916` |
| H01 primary manifest | `25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72` |
| H01 gap-timing-unaware manifest | `e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b` |
| Gap-timing-unaware preparation manifest | `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935` |
| Pre-analysis comparison manifest | `f3c4bfbf120d2023c045b44e3c7c04c58bce1f8d11621956bca1e5ede90c5623` |
| METRIC-011 evidence manifest | `a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb` |

The complete row-level evidence and manifest transition are under
`audit/reconciliation/l10_METRIC-011/`.

## Downstream scope

Only analyses or descriptive outputs that use **L10 mean melEDI** require a
scientific update. They must rebuild their L10 frame/model/diagnostics and any
multiplicity-derived fields that contain the L10 test slot, while preserving
every non-L10 fit and raw inferential result exactly. L10-midpoint-only work is
scientifically unchanged. Documentation that cites upstream identities may
require a provenance-only repin.

## Reopening condition

Reopen if the offset, logarithm base, floating-point tolerance multiplier,
source-all-zero requirement, missing-minute accounting, L10 support rule,
model handling of exact zeros, or any sealed identity changes; if a materially
negative value appears; or if independent verification finds another positive
residual that lacks exact-zero source provenance.
