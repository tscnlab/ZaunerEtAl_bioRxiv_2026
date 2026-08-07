# H07 Stage 3 gate and Stage 4 transition

Decision ID: `H07-004`
Date: 2026-08-07
Status: approved

## Decision

The author accepted `H07-S3-001` through `H07-S3-006` and explicitly
authorized the continuing H07 task to begin Stage 4.

The accepted Stage 3 result is the standalone reader-facing report at
`notebooks/hypotheses/H07.qmd`. It reports the descriptive
derivative-defined plateau pattern for six of nine primary near-eye metrics
and seven of nine complementary chest metrics, with all stated
identifiability, distributional, temporal, model-form, sample, support, and
site-influence limitations. No production simulation or bootstrap is
required.

Stage 4 creates
`audit/hypotheses/H07/H07_analysis_preparation.qmd` as the scientific
analysis-preparation and provenance companion. It must follow the accepted
H02/H05 structure and bounded-render rules. It may read stored H07 inputs,
model registries, exact samples, diagnostics, result tables, figures, and
source rows; perform identity, completeness, and lightweight descriptive
checks in R; and explain the scientific and computational lineage. It must
not refit a model, rerun a sensitivity, bootstrap, simulate, change an
accepted result, or introduce a new estimand.

The H07 task owns only the H07-specific source, test, displays, manifests,
and handoff. Shared preparation code, central ledgers, shared Quarto
configuration, bibliography, manuscript and submission files, `renv.lock`,
and `manuscript/R0_NatMed/` remain coordinator-owned and read-only.

## Reopening condition

Reopen Stage 3 only if the preparation/provenance companion exposes a
scientific discrepancy, changes an accepted estimate, classification,
diagnostic disposition, sensitivity result, or claim, or requires scientific
recomputation. Wording, layout, provenance, identity, or bounded descriptive
repairs do not reopen the accepted result.
