# Manuscript metric-inventory completeness

Status: open manuscript repair  
Date: 2026-07-30  
Severity: medium

## Finding

The signed preregistration and the manuscript's analysis code identify the
midpoints of the brightest and darkest 10 hours as timing-based outcomes.
The Results report both midpoints, including their site and chronotype
associations. The current Methods inventory in `index.qmd`, however, lists
first, last, and mean timing above 250 lx without also naming the M10 and L10
midpoints.

Conversely, M10/L10 onset and offset are returned by the rolling-window
calculation only as boundary diagnostics. They are absent from the
preregistered outcome set, have missing response specifications in the
superseded model registries, and are not reported in the manuscript.

## Approved repair

- Add the midpoint of the brightest 10 hours and midpoint of the darkest
  10 hours to the Methods inventory of timing-based metrics.
- Retain only the two window levels and two midpoints in analytical and
  manuscript-facing registries.
- Keep onset and offset, if preserved at all, only as internal fields used to
  verify window duration, midnight wrapping, and tie handling.
- Use the established manuscript names and categories from
  `config/metric_display_registry.csv`; put implementation qualifiers in
  separate method or sensitivity fields.

This is a reporting-completeness repair and outcome-registry clarification,
not a new outcome or preregistration deviation.

## Evidence

- `preregistration/AsPredicted #273407.pdf`, page 1
- `preregistration/MeLiDos_ZaunerEtAl_analysis_plan.docx`
- `audit/evidence/preregistration_contract.md`
- `data_preparation.qmd:25-45`
- `index.qmd:269-289`
- `index.qmd:367`
- `index.qmd:516-518`
- `audit/hypotheses/H01-H04_migration_map.md`

## Reopening condition

Reopen if the approved analytical metric set or manuscript taxonomy changes.
