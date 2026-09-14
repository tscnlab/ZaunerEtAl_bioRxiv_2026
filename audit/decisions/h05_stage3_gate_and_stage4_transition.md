# H05 Stage 3 gate and Stage 4 transition

Decision ID: `H05-002`  
Date: 2026-08-01  
Status: approved

## Decision

The author explicitly approved the standalone H05 Stage 3 reader-facing
report and authorized the continuing H05 task to begin Stage 4.

Stage 4 creates
`audit/hypotheses/H05/H05_analysis_preparation.qmd` under `REPORT-007`. It is a
scientific analysis-preparation and provenance companion, not a new analysis.
Its render is bounded to stored H05 artifacts, identity checks, and lightweight
descriptive summaries. It must not refit a model, rerun a sensitivity,
bootstrap, predict, or change an accepted H05 result.

The H05 task owns the Stage 4 source, H05-specific tests, displays, source
data, manifests, and handoff. The coordinator will add the source immediately
after the H05 results report in `_quarto-nathealth.yml` only after the source
exists, render it through the shared website configuration, and return the
final website identities for checksum closure.

## Reopening condition

Reopen H05 Stage 3 only if Stage 4 exposes a scientific discrepancy, changes
an accepted result or claim, or requires scientific recomputation. Wording,
layout, navigation, provenance, or bounded descriptive repairs do not reopen
the accepted inference.
