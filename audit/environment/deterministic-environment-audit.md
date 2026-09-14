# Deterministic environment reconciliation

## Outcome

The static dependency scan completed in 4.258 seconds and found 959 package references across 71 unique packages.
No mandatory library or scanner failure was found. The lockfile is synchronized with R 4.6.1 and the expected project dependencies.

This audit does not call `renv::status()` and does not contact a
package repository. It compares the authored dependency scan, the
project library, `renv.lock`, and recorded source metadata directly.

## Explicit dependency policy

- `see` and `DHARMa` are required diagnostic dependencies. `see` is an optional backend that static discovery may not find; `DHARMa` is now also called directly by hypothesis code. Both remain explicit lockfile requirements.
- `shiny` is found only in the 11 parameterized hypothesis notebooks. All detected files have Quarto YAML `params:` and no Shiny runtime reference. It is retained as a scanner-synchronization dependency, not described as an interactive runtime.

## Lock alignment

- Lockfile and runtime both use R `4.6.1`.
- Installed/locked version mismatches: none.
- Explicit diagnostic and Quarto-scanner packages missing from the lockfile: none.

## Safe status checks

Before `.renvignore` was introduced, project discovery could traverse large generated artifact, render, data, submission, and project-library trees. The current ignore rules make `renv::dependencies()` fast.
`renv::status()` still performs additional work: it resolves the full transitive package closure, recreates library records, and, with `sources = TRUE`, checks source metadata. The prior nine-hour runs do not isolate which of these later phases was pathological, so this audit does not claim a single confirmed root cause.
Status checks are run only through `scripts/environment/run_renv_status_safe.R`; that wrapper launches a separate R process, enforces a wall-clock timeout, terminates the child on timeout, and retains stdout, stderr, exit status, and timing metadata.

## Machine-readable outputs

- `dependency-reconciliation.csv`
- `environment-summary.csv`
- `repository-reconciliation.csv`
