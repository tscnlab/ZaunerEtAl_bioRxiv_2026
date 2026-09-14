# H01 order-32 source-only verification stop

Date: 2026-08-14  
Attempt status: **STOPPED, exit status 1**  
R version: 4.6.1

## Exact command

```sh
env R_PROFILE_USER=/dev/null \
  R_LIBS_USER=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  NATHEALTH_PROJECT_ROOT=<project> \
  Rscript --vanilla \
  audit/hypotheses/H01/report017_order32_source_rewrite/run_h01_order32_source_audit.R \
  /private/tmp/H01-order32-baseline.v2ZLRx \
  audit/hypotheses/H01/report017_order32_source_rewrite
```

The process elapsed 0.561 seconds and stopped before invoking any of the four
focused tests.

## Console result

```text
Error in walk(element) : argument "element" is missing, with no default
Calls: intersect ... collect_calls -> walk -> walk -> walk -> walk -> walk
Execution halted
```

## Fail-closed disposition

The verifier defect is recorded as `ORDER32-VERIFY-001`. The unexecuted
verification gates are recorded as `ORDER32-VERIFY-002`. No attempt was made
to edit the verifier, patch a source contract, or rerun any check. The
assembled reader-source and direct-manifest changes therefore remain pending
independent correction and a new complete source-only verification release.

No Quarto command, QMD chunk, model, prediction, bootstrap, simulation,
reporting builder, or artifact-regeneration path ran. No output was written by
the failed verifier beyond creating its already authorized evidence directory;
that directory contained only the verifier source before this stopped-state
record was added.
