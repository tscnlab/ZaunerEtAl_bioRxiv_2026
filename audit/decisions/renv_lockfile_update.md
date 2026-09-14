# R 4.6.1 lockfile update

Decision ID: `ENV-001`
Date: 2026-07-31
Status: verified

## Decision

Update `renv.lock` now from the verified R 4.6.1 project library instead of
waiting for the end of the complete analysis. The lockfile is the shared
environment baseline for all active and future hypothesis tasks. A final
snapshot is still required if a later approved analysis introduces or changes
a dependency.

The snapshot uses the project dependency scan plus three explicit runtime
requirements:

- `see`, used by the model-diagnostic display workflow;
- `DHARMa`, used for simulated residual diagnostics; and
- `shiny`, retained because renv interprets the Quarto `params:` headers in
  the eleven hypothesis notebooks as a dependency.

The snapshot updates existing records rather than performing a blanket
package update. It uses the installed project library and the explicit CRAN
repository `https://cloud.r-project.org`.

## Result

- R recorded in the lockfile: 4.6.1, replacing 4.5.0.
- Package records: 246, replacing 226.
- Compatibility updates: `Matrix` 1.7-6 and `sf` 1.1-2.
- Added records include the required diagnostic and parameter-rendering
  packages and their installed dependency closure.
- SHA-256 of `renv.lock`:
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

The deterministic dependency-to-library-to-lock test passes. The full
source-aware `renv::status()` check, run in a timeout-controlled child
process, reports `RENV_STATUS_SYNCHRONIZED=TRUE` and finishes in about five
seconds. The model and diagnostic smoke test also passes.

## Rule for parallel tasks

Hypothesis and descriptive tasks must use R 4.6.1 and the activated project
library. They must not install packages inside a notebook, update
`renv.lock`, or run an unbounded `renv::status()` call. A task that needs a
new or changed dependency submits a shared-change request to the coordinator.

Status checks use:

```sh
Rscript --vanilla scripts/environment/run_renv_status_safe.R \
  /absolute/path/to/project 60 true
```

The wrapper records stdout, stderr, runtime, timeout state, and exit status in
`audit/environment/renv-status/`.

## Reopening condition

Reopen if a required package or version changes, a new dependency is approved,
the lockfile hash changes, the project is run under another R minor version,
or the bounded source-aware status check no longer reports synchronization.
