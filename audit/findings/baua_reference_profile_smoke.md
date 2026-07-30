# BAUA reference-profile smoke audit

## Scope

Preparation 03 was run against the isolated BAUA Preparation 02 artifacts
under `artifacts/03_coverage/runs/subset_baua/`. The run did not read or write
the canonical full-analysis profile paths.

## Verified properties

- The profile is learned once, before participant-day metric calculation.
- The estimator first takes a within-participant bin median and then the
  median across participants.
- Placement, signal, and state domain are separate strata.
- Every represented profile and metric map retains all 48 fixed 30-minute
  pseudo-local clock bins.
- Unsupported bins remain explicit and are not interpolated.
- Estimable relevance maps sum to one to numerical precision.
- Only the dose map permits a value correction. M10, L10, threshold timing,
  and paired-channel maps are support diagnostics only.
- L10 is present and L5 is absent and explicitly prohibited.
- The checksummed Preparation 02 inputs were unchanged and every recorded
  Preparation 03 artifact checksum matches its manifest.
- The true-UTC input remains immutable. BAUA contains no repeated fall-back
  wall minute, so the declared fold-averaging rule was not exercised by this
  site-specific smoke run; it remains covered by the synthetic tests.

## Expected subset limitations

BAUA contributes 20 participants with complete chest-bin support and 18
participants with complete near-eye-bin support after the eligible-day
restriction. Consequently, the pooled full-day chest profile meets the
predeclared 20-participant threshold, whereas the pooled full-day near-eye
profile is deliberately non-estimable in this one-site smoke run. The
BAUA-specific near-eye profile meets the five-participant threshold and is
estimable.

The BAUA participant-balanced median MEDI profile is below 250 lx in most
strata. Therefore, several `timing_above_250` relevance maps have zero
relevance mass and are explicitly non-estimable. This is not imputed or
silently replaced. The corresponding full-cohort maps must be checked before
threshold-timing support rules are frozen; if a full-cohort map remains
non-estimable, the affected metric needs an explicit alternative support rule
or an `undetermined`/excluded validity decision.

## Reproduction

Run:

```sh
R_PROFILE_USER=/dev/null \
R_LIBS_USER=renv/library/macos/R-4.6/aarch64-apple-darwin23 \
Rscript --vanilla audit/scripts/verify_baua_reference_profiles.R
```
