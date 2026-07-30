# Preparation 04 clean-session dependency declaration

Finding ID: `FIND-015`  
Status: repaired and canonically verified  
Finding date: 2026-07-30  
Severity: medium reproducibility defect; no scientific output written

## Expected

The canonical Preparation 04 notebook and the standalone metric builder must
run in a clean R session using only their declared dependencies.

## Observed

After the timing support map was changed to a fixed exceedance-distribution
artifact, `validate_fixed_metric_profiles()` called
`validate_exceedance_distribution_profiles()`, which is defined in
`scripts/pipeline/reference_profiles.R`.

The focused metric-builder test sourced that file before the builder and
therefore passed. The clean canonical invocation failed before metric
derivation with:

```text
could not find function "validate_exceedance_distribution_profiles"
```

Neither the Preparation 04 notebook dependency vector nor the standalone
builder entrypoint declared `reference_profiles.R`.

## Repair

`reference_profiles.R` is now sourced after `time_support.R` and before
`metric_derivation.R` in both entrypoints. A structural regression test
requires every dependency exactly once and in the necessary order.

The failed canonical attempt stopped during input validation, before deriving
or writing any metric artifact. It therefore has no scientific-value or
sample-flow effect.

## Verification

- `tests/test_metric_entrypoint_dependencies.R`: PASS
- `scripts/pipeline/build_metric_derivation.R`: parses under R 4.6.1
- clean canonical rerun: PASS for 897 chest and 811 glasses
  participant-days

Reopen this finding if a new cross-file validator is added without being
declared by both the notebook and standalone entrypoint, or if the clean
canonical run fails on another implicit dependency.
