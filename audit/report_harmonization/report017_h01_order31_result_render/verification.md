# REPORT-017 H01 order 31 bounded render verification

Date: 2026-08-14

Status: **render completed; verification blocked before browser QA by the shared navigation contract.**

## Released target and preflight

The sole render target was
`notebooks/hypotheses/H01.qmd`. All accepted release hashes matched before
execution. Both H01 reporting manifests reconciled completely, with 49 of 49
and 95 of 95 rows matching current paths, hashes, and byte counts.

The historical order 30 inventory contained 1,215 paths. All matched before
rendering. The complete Nature Health build contained 1,123 nodes, including
817 regular files and no symlinks. Static extraction parsed 124 R expressions
and 96 unique function calls. The chunks read accepted stored outputs,
constructed formulas and display objects, and emitted native gt tables. No
fit, refit, prediction, simulation, bootstrap, package installation, artifact
writer, reporting-input builder, or scientific-regeneration call was present.
The source uniquely declared 36 `tbl-h01-*` endpoints and 10
`fig-h01-*` endpoints.

## Startup and exact render

A restricted normal-profile smoke probe was stopped before R produced output
because it was waiting to acquire the renv sandbox lock. It did not alter a
source, build, protected artifact, lockfile, or package. The same smoke then
passed with the coordinator-authorized narrow access to the existing
user-owned renv cache.

The following command ran exactly once:

```text
quarto render notebooks/hypotheses/H01.qmd --profile nathealth
```

The render used Quarto 1.9.37, R 4.6.1, renv 1.2.3, gt 1.3.0, knitr 1.51,
and rmarkdown 2.31. It ran from 2026-08-14T12:20:37Z to
2026-08-14T12:21:45Z. The observed render-process wall time was approximately
48.923 seconds, inside a 68-second timestamp envelope. All 75 knitr steps
completed. The process exited 0 without a Quarto, knitr, R-cell, Pandoc, or
table warning or error. renv emitted its existing dependency-discovery note
at startup and shutdown. No dependency or lockfile changed.

The fresh result HTML is:

- path: `_build/nathealth/notebooks/hypotheses/H01.html`;
- SHA-256:
  `ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`;
- bytes: 1,371,249.

The protected companion HTML remains
`5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`.

## Preservation and build delta

Within the historical 1,215-path set, only the authorized result HTML changed.
The other 1,214 paths remained byte-identical. The two reporting manifests,
focused test, result and companion QMDs, profile, models, diagnostics,
scientific tables, durable figures, source data, and companion HTML retained
their accepted identities.

The build retained the same 1,123 nodes and 817 files. Exactly four build
files changed content:

1. the H01 result HTML;
2. the rendered-site copy of
   `H01_stage3_reporting_artifacts.csv`, refreshed from its previously stale
   22,144-byte copy to the accepted 22,735-byte source;
3. `search.json`; and
4. `sitemap.xml`.

Fourteen copied H01 display resources and the Bootstrap stylesheet were
byte-identical but received ordinary render mtimes. Sixteen containing
directories also received ordinary metadata updates. The full delta and both
complete inventories are retained alongside this record. The focused and
structural tests did not change any build byte or retained mtime.

## Tests and mandatory stop

The complete normal-profile H01 focused test passed against the fresh HTML.
The reader-link contract passed for 35 QMD sources and all 86 deviation
anchors. The country-coded study-site contract also passed for all 35
reader-facing sources.

The current navigation contract failed because these shared, deferred sources
remain in both `project.render` and the sidebar:

- `notebooks/hypotheses/H06_daily.qmd`;
- `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`.

This is a shared configuration disposition outside H01 ownership. Order 31
requires a stop on any test failure. No configuration or test was edited, no
second render was run, and no loopback server was started. Therefore the
dedicated semantic DOM audit, 1440 by 1000 and 708 by 1000 visual QA,
36-table measurements, 10-figure inspection, screenshots, and focused
desktop, narrow, and 200 percent reviews of the principal table and figure
remain unperformed.

## Boundary

No H01 source, test, shared configuration, scientific artifact, model,
estimate, interval, p-value, diagnostic, sensitivity, durable figure,
source-data file, dependency, lockfile, manuscript file, or central ledger
was edited. No model operation, scientific builder, bootstrap, simulation,
companion render, other-target render, full render, commit, or push ran.

The fresh H01 result HTML is retained as bounded render evidence, but order 31
cannot be accepted until the coordinator resolves or explicitly disposes of
the shared navigation failure and separately releases the remaining QA.
