# Deterministic environment reconciliation

## Outcome

The static dependency scan completed in 2.024 seconds and found 457 package references across 57 unique packages.
No mandatory library or scanner failure was found. The environment is not lock-synchronized yet because the planned R 4.6.1 snapshot remains gated on the complete clean analysis run.

This audit does not call `renv::status()` and does not contact a
package repository. It compares the authored dependency scan, the
project library, `renv.lock`, and recorded source metadata directly.

## Explicit dependency policy

- `see` and `DHARMa` are installed optional runtime dependencies. Static discovery does not find them, so the final gated snapshot must include them explicitly.
- `shiny` is found only in the 11 parameterized hypothesis notebooks. All detected files have Quarto YAML `params:` and no Shiny runtime reference. It is retained as a scanner-synchronization dependency, not described as an interactive runtime.

## Pending lock alignment

- Lockfile R version: `4.5.0`; runtime R version: `4.6.1`.
- Installed/locked version mismatches: Matrix, sf.
- Explicit packages awaiting the gated snapshot: DHARMa, see, shiny.

## Why unbounded status was retired

Before `.renvignore` was introduced, project discovery could traverse large generated artifact, render, data, submission, and project-library trees. The current ignore rules make `renv::dependencies()` fast.
`renv::status()` still performs additional work: it resolves the full transitive package closure, recreates library records, and, with `sources = TRUE`, checks source metadata. The prior nine-hour runs do not isolate which of these later phases was pathological, so this audit does not claim a single confirmed root cause.
The final mandatory status call must use `scripts/environment/run_renv_status_safe.R`; that wrapper launches a separate R process, enforces a wall-clock timeout, terminates the child on timeout, and retains stdout, stderr, exit status, and timing metadata.

## Machine-readable outputs

- `dependency-reconciliation.csv`
- `environment-summary.csv`
- `repository-reconciliation.csv`
