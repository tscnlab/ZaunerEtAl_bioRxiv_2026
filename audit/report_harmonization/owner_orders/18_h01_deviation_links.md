# Harmonization follow-up 18 — exact H01 deviation links

Date: 2026-08-12  
Owner task: `019fb4ce-d84c-73d1-be48-dc244be5b5f0`  
Controlling decisions: REPORT-014 / CHG-124, REPORT-016 / CHG-126,
CHG-128, and CHG-130  
Dispatch mode: **source-only exact-link integration; no Quarto render or scientific execution**

## Exact owned documents and accepted evidence

| Path | SHA-256 at order preparation |
|---|---|
| `notebooks/hypotheses/H01.qmd` | `8c7ca4e7382b1f9cc5fe07bb9cdf8a1318fd6e311f7df4e86556ae3e390abe96` |
| `audit/hypotheses/H01/H01_analysis_preparation.qmd` | `685641fcb163e55b96b34778f25b276d8ce289bacd0ad73ece4351d859ebb4cb` |
| `artifacts/09_tables/H01/stage3/H01_stage3_deviations.csv` | `2671fc9af9d6764a8b64c1417c8c84b3eb63a2f0a0c2c4ff4adb4eddeb03a347` |

Recheck all three identities immediately before editing and stop on drift.
The CSV is accepted scientific-owner evidence and must remain byte-identical.
Keep all accepted data, formulas, samples, estimates, intervals, p-values,
FDR families, diagnostics, sensitivities, tables, figures, captions, and
stored outputs frozen.

## Result-report integration

1. Change `### Deviations from the preregistered specification` to
   `### Deviations from the preregistered specification {#h01-preregistration-deviations}`.
2. In `tbl-h01-deviations`, retain the accepted `deviations` object and every
   row, topic, preregistered/expected statement, and analysis-used statement.
   Hide the display-only `Deviation ID` column with `gt::cols_hide()` so the
   table contains no unlinked stable-ID text. Adjust only column widths as
   needed for the remaining three columns. Do not mutate, rewrite, or replace
   an ID in the underlying object or CSV.
3. Immediately after the table, add the following literal Markdown list.
   These links must remain literal source links so Quarto resolves each
   relative `.qmd` target and anchor:

**Linked preregistration entries by topic**

- Placement: [DEV-001](../preregistration_deviations.qmd#dev-001),
  [REP-001](../preregistration_deviations.qmd#rep-001), and
  [REP-002](../preregistration_deviations.qmd#rep-002).
- Inclusion and support:
  [DEV-003](../preregistration_deviations.qmd#dev-003),
  [DEV-004](../preregistration_deviations.qmd#dev-004),
  [IMP-003](../preregistration_deviations.qmd#imp-003), and
  [DEV-055](../preregistration_deviations.qmd#dev-055).
- Sleep and non-wear:
  [DEV-005](../preregistration_deviations.qmd#dev-005),
  [DEV-006](../preregistration_deviations.qmd#dev-006),
  [IMP-018](../preregistration_deviations.qmd#imp-018),
  [IMP-019](../preregistration_deviations.qmd#imp-019), and
  [REP-003](../preregistration_deviations.qmd#rep-003).
- Upper light boundary:
  [IMP-002](../preregistration_deviations.qmd#imp-002).
- Darkest-window level:
  [DEV-007](../preregistration_deviations.qmd#dev-007).
- Threshold timing:
  [DEV-008](../preregistration_deviations.qmd#dev-008) and
  [DEV-054](../preregistration_deviations.qmd#dev-054).
- Site and latitude:
  [DEV-009](../preregistration_deviations.qmd#dev-009).
- Photoperiod scope:
  [DEV-017](../preregistration_deviations.qmd#dev-017).
- Response models:
  [DEV-018](../preregistration_deviations.qmd#dev-018).
- Multiplicity:
  [IMP-001](../preregistration_deviations.qmd#imp-001) and
  [DEV-009](../preregistration_deviations.qmd#dev-009).
- Site follow-ups:
  [DEV-009](../preregistration_deviations.qmd#dev-009).
- Variation, uncertainty, and exact samples:
  [IMP-003](../preregistration_deviations.qmd#imp-003) and
  [IMP-004](../preregistration_deviations.qmd#imp-004).
- Model comparison:
  [IMP-010](../preregistration_deviations.qmd#imp-010).
- Full-day construct:
  [IMP-012](../preregistration_deviations.qmd#imp-012).
- Melanopic daylight efficacy ratio:
  [DEV-058](../preregistration_deviations.qmd#dev-058).
- Interdaily stability and intradaily variability:
  [IMP-014](../preregistration_deviations.qmd#imp-014) and
  [DEV-053](../preregistration_deviations.qmd#dev-053).
- Windows, periods, and timing:
  [IMP-015](../preregistration_deviations.qmd#imp-015) and
  [DEV-054](../preregistration_deviations.qmd#dev-054).
- melEDI dose:
  [IMP-016](../preregistration_deviations.qmd#imp-016) and
  [DEV-052](../preregistration_deviations.qmd#dev-052).
- Time axes and source epochs:
  [IMP-017](../preregistration_deviations.qmd#imp-017) and
  [IMP-020](../preregistration_deviations.qmd#imp-020).
- Software environment:
  [DEV-049](../preregistration_deviations.qmd#dev-049) and
  [DEV-050](../preregistration_deviations.qmd#dev-050).
- Participant-day plausibility:
  [DEV-057](../preregistration_deviations.qmd#dev-057).
- Pre-sleep duration:
  [IMP-024](../preregistration_deviations.qmd#imp-024).
- Darkest-10-hour midpoint:
  [IMP-023](../preregistration_deviations.qmd#imp-023).

Follow the list with one short sentence explaining that the central page
labels each entry as a current scientific deviation, the current
qualification, resolved implementation history, or technical provenance.
Do not present every `IMP` entry as current methodology.

The list contains all 36 unique IDs and exactly mirrors all 23 accepted table
rows. Do not add an H01-local alias, a new central ID, or another mapping.
CHG-130 confirms that H01-001 through H01-008 were editorial aliases/details
and must remain absent.

## Companion link

In the opening `## Purpose` section, extend the existing results-report link
to state: `The [H01 results report](../../../notebooks/hypotheses/H01.qmd)
presents the scientific findings and its [preregistration deviations](../../../notebooks/hypotheses/H01.qmd#h01-preregistration-deviations).`
Do not duplicate the 23-row mapping in the companion.

## Boundary

Do not edit the corrected CSV, fit or refit a model, predict, bootstrap,
simulate, rebuild reporting inputs or figures, recalculate p-values/FDR or
R-squared, run Quarto, or alter a manifest. Do not edit configuration,
ledgers, decisions, tests, scripts, bibliography, lockfile, manuscript, or
another QMD. Preserve current MDER (DEV-058), exact-zero-day (DEV-057), and
registered-longest-period/adapted-mean-timing (DEV-008/DEV-054) wording
exactly.

## Focused evidence to return

- pre/post SHA-256 values for both QMDs and unchanged CSV SHA-256;
- exact changed source lines and confirmation that reversing only the heading,
  hidden-column/width change, literal list, and companion sentence reproduces
  both dispatch hashes;
- confirmation that all 36 unique central IDs match the accepted 23-row CSV,
  all relative QMD targets and anchors resolve, and the result anchor is
  unique;
- confirmation that H01-001 through H01-008 are absent and no visible stable
  ID remains unlinked in the result or companion;
- no hard-coded internal `.html`, `file://`, `_build`, build-directory, or
  absolute local page link;
- identical chunk-label, assignment, inline-R, artifact-reference,
  figure/table identifier, formula, caption, alt-text, and executable-R sets;
- scoped status/diff showing exactly these two owned QMDs changed, plus
  `git diff --check` for them; and
- explicit confirmation that no render or scientific execution ran.

Focused Phase 4 renders remain separately released.
