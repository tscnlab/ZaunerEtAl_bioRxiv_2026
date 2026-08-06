# H11 Stage 3 author gate

Date: 2026-08-06  
Branch: `rewrite/NH`  
Stage: 3 — revised reader-facing report  
Status: **ready for author review; stop before later-stage integration**

## Authorization implemented

The report implements the approved H11 robust complete-curve method,
participant-cluster robust pointwise 95% intervals, conditional biological-sex
effect-size reporting, and the author-requested activity-context sensitivity.
The accepted all-available global models remain the primary near-eye and
complementary chest tests. The activity analysis is explicitly exploratory and
does not replace them.

The report now states that the two-test BH level/shape decomposition is a
secondary attribution analysis. Its inability to resolve either component
independently does not invalidate the separately supported global curve test.

## Accepted results retained

The complete near-eye Female-minus-Male curve is supported (raw and one-test
BH-adjusted *p* = **0.028**) and the complementary chest curve is supported
(*p* = **0.029**). The secondary level/shape analysis does not independently
resolve either supported curve after its two-test BH adjustment.

Pointwise near-eye estimates show a minimum Female-to-Male shifted ratio of
0.471 at 08:45 (95% CI 0.284–0.779). The complementary chest ratio is nearly
time-constant at 0.793 (0.645–0.976). These are pointwise intervals and do not
define a familywise significant time period.

The gap-timing-unaware dataset preserves the global decisions for near eye
(*p* = **0.026**) and chest (*p* = **0.037**). Its approved first-use coverage
and missing-observation-timing explanation is retained.

## Exploratory activity-context sensitivity

The exact near-eye activity-complete sample contains 126 participants, 724
participant-days, and 30,499 observations. Its same-sample global result is
unsupported both before activity adjustment (*p* = 0.160) and after adjustment
(*p* = 0.364). Sample restriction therefore prevents attribution of the change
from the accepted result to activity.

The exact chest sample contains 150 participants, 875 participant-days, and
36,711 observations. Its same-sample result changes from **0.025** before
activity adjustment to 0.050 after adjustment (full precision 0.05021431625).
This is reported as attenuation around a decision threshold, not as evidence
of mediation, explanation, or mechanism.

No activity-adjusted global result had raw *p* < 0.050, so the author-approved
activity effect-size gate remained closed and no additional effect-size
bootstrap was run. All four activity-complete fits are acceptable with
specified limitations.

## Reader deliverables

- source: `notebooks/hypotheses/H11.qmd`;
- render: `_build/nathealth/notebooks/hypotheses/H11.html`;
- reader artifacts: `artifacts/06_model_data/H11/stage3/`,
  `artifacts/08_diagnostics/H11/stage3/`,
  `artifacts/09_tables/H11/stage3/`, and
  `artifacts/11_source_data/H11/stage3/`;
- seven tightly bounded reader figures: `artifacts/10_figures/H11/stage3/`;
- physical-size QA record: `audit/hypotheses/H11/03_figure_readability_qa.md`;
- QA-only proof:
  `artifacts/12_manifests/H11/H11_stage3_figure_A4_proofs.pdf`;
- focused test: `tests/hypotheses/H11/test_h11_stage3_reader_report.R`;
- Stage 3 inventory:
  `artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv`.

## Reporting-policy disposition

- **REPORT-008:** displayed raw and adjusted *p*-values use a leading zero and
  three decimal places; significance is decided at full precision and bolding
  is applied independently.
- **REPORT-009:** no unmatched or unsupported scalar placement identity plot is
  shown.
- **REPORT-010:** the exact “gap-timing-unaware dataset” terminology is used.
- **REPORT-011:** seven actual exported assets were assessed at 170 mm on A4
  QA pages using the approved 14/12/11-pt source convention. All seven pass.
  Final assets remain tightly bounded and exclude A4 canvas.
- **REPORT-012:** the compact callout is titled exactly “Answer in brief.”
- **REPORT-013:** melEDI figures use
  `LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)` with original-unit
  breaks and untransformed source data.

## Proposed coordinator-owned ledger entries

1. `H11-STAGE3-BH-INTERPRETATION` — component decomposition cannot cleanly
   assign the supported global curve to level or shape; it does not invalidate
   the global test.
2. `H11-STAGE3-ACTIVITY-SENSITIVITY` — near-eye activity-complete sample is
   unsupported before and after adjustment; chest changes from raw *p* = 0.025
   to 0.050, without causal or mediational interpretation.
3. `H11-STAGE3-ACTIVITY-EFFECT-GATE` — closed at both placements; no additional
   effect-size bootstrap executed.
4. `H11-REPORT-011-013-PASS` — seven figures pass physical-size QA and all
   reader melEDI axes use the approved true symlog transform.
5. `H11-STAGE3-REVISED-AUTHOR-GATE` — revised reader report rendered and
   verified; awaiting author approval.

## Decision requested

Please approve the revised H11 Stage 3 reader report or identify further
scientific or display changes. No later-stage integration or closure is
authorized by this record.
