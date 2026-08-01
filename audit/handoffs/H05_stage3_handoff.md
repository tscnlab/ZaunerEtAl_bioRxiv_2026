# H05 Stage 3 handoff

Status: **Stage 3 complete and author-approved; four-stage H05 workflow closed**

## Controlling authorization

The coordinator's transition and closure decisions are
`audit/decisions/h05_stage2_gate_and_stage3_transition.md` (`H05-001`) and
`audit/decisions/h05_stage3_gate_and_stage4_transition.md` (`H05-002`), with
final closure in `audit/decisions/h05_stage4_closure.md` (`H05-003`).
`H05-001` records approval of the Stage 2 gate items 1--5 and 7, supersedes
the former item 6, and distinguishes the optional production-computation gate
from the mandatory standalone reader-facing result. `H05-002` records the
author's approval of that result and authorizes the scientific preparation and
provenance companion. No production bootstrap or simulation is required for
H05. `H05-003` accepts that companion and closes the four-stage workflow.

The coordinator-owned records remain read-only for this H05 task:

- `audit/decisions/h05_stage2_gate_and_stage3_transition.md` (`H05-001`);
- `audit/decisions/h05_stage3_gate_and_stage4_transition.md` (`H05-002`);
- `audit/decisions/h05_stage4_closure.md` (`H05-003`);
- `audit/ledgers/hypothesis_stage_gates.csv`; and
- `audit/ledgers/change_log.csv` (`CHG-071`, `CHG-077`, `CHG-080`).

They record Stages 1--4 as complete and verified, production computation as
not required, and the current H05 gate as closed.

The report also follows the coordinator-owned display and terminology rules:

- `audit/decisions/p_value_display_conventions.md` (`REPORT-008`);
- `audit/decisions/paired_placement_comparison_display.md` (`REPORT-009`);
- `audit/decisions/gap_timing_unaware_dataset_terminology.md`
  (`REPORT-010`); and
- `audit/decisions/figure_readability_and_layout.md` (`REPORT-011`).

## Completed reader-facing deliverable

The standalone H05 result is complete at:

- source: `notebooks/hypotheses/H05.qmd`;
- Nature Health HTML:
  `_build/nathealth/notebooks/hypotheses/H05.html`;
- reader-artifact builder:
  `scripts/hypotheses/H05/build_h05_reader_artifacts.R`;
- focused verification:
  `tests/hypotheses/H05/test_h05_stage3_reader_report.R`; and
- provenance seal:
  `artifacts/12_manifests/H05/H05_stage3_artifacts.csv`.

The shared Nature Health profile was used without an H05-owned configuration
edit. The reader report links reciprocally to the approved preparation and
provenance companion. It does not discuss submitted-versus-new comparisons,
internal workflow mechanics, or discarded construction variants.

## Scientific result presented

The report quotes the exact preregistered statement:

> H5: LEBA questionnaire factors correlate with selected personal light
> exposure metrics.

It presents all-available near-eye results as primary and all-available chest
results as complementary. Paired/common near-eye and chest results and the
gap-timing-unaware dataset are labelled sensitivities. At first use, the
report explains that the latter still passed the general 50%-per-hour and
80%-per-day coverage rules but does not use the timing of remaining missing
observations for additional metric-specific adjustment.

The strongest defensible conclusion is that, after fixed-site adjustment and
one complete 68-test Benjamini--Hochberg correction, **zero of 68 primary
associations is retained**. The two leading F2 estimates are described as
stable but not multiplicity-retained, never as significant:

| Primary near-eye metric | Ratio per participant SD (95% CI) | Raw p | BH-adjusted p |
|---|---:|---:|---:|
| Time above 1,000 lx melEDI | 1.234 (1.084 to 1.405) | 0.002 | 0.124 |
| Corrected melEDI dose | 1.278 (1.079 to 1.514) | 0.004 | 0.124 |

The complementary chest family also retains zero of 68 associations; its
smallest BH-adjusted p is 0.224. The gap-timing-unaware near-eye family retains
zero of 68; its smallest BH-adjusted p is 0.070.

## Model and sample transparency

The reader report lists all relevant departures and clarifications, including:

- fixed site in the primary specification versus registered random site;
- participant-day versus participant-level model structure;
- the complete 68-test BH family in each inferential scenario; and
- the primary, complementary, and sensitivity roles of the placements and
  samples.

A visible evaluated R cell constructs the exact six Wilkinson formula objects
supplied to the full and reduced fixed-site and random-site models and presents
them in a six-row `gt` table. The sample tables give, for every one of the 17
metrics and for each all-available placement, exact participants,
participant-days, observations where applicable, and sites.

The fixed-site choice is explained from the inherited site-structure evidence
and the registered random-site sensitivity. Of the 136 all-available
random-site cells, 121 pass and 15 are unstable (seven near-eye and eight
chest), supporting fixed site as the primary adjustment.

## Diagnostics and limitations

The report contains placement-specific adequacy heatmaps, counts, limitation
tables, and selected residual-versus-fitted and quantile--quantile displays.
The near-eye reader assessment is 19 acceptable, 45 acceptable with specified
limitations, and four unfit for inference. The complementary chest assessment
is 14, 50, and four, respectively.

The four sleep-environment models for each all-available placement are marked
**unfit for inference**, rather than being hidden inside the aggregate limited
count. They have material response-support and simulated-residual failures,
including 183--187 near-eye and 241--244 chest fitted values above the observed
support. Their estimates, confidence intervals, and p-values are suppressed
from the reader-facing matrices. The report makes clear that this disposition
is specific to the H05 response and model structure and does not determine
whether the metric can be used in another hypothesis with a different response
variable or model structure.

## Sensitivities presented

- All 612 required leave-one-site-out refits are complete: 21 associations are
  stable, 27 are direction-stable but magnitude-sensitive, and 20 are
  direction-unstable. The two leading F2 associations are stable.
- The paired/common display uses exact matched estimands: participant-day
  metrics contain 110--112 participants, 505--643 matched participant-days,
  and eight sites; IS and IV use 112 participant rows. Fifty-nine of 68 cells
  agree in direction with overlapping component intervals; nine differ in
  direction. The figure places near-eye estimates on x and chest estimates on
  y, uses equal axis geometry with identity and null lines, links the exact
  paired source data, and explicitly does not imply equivalence.
- Sixty-four of 68 cells comparing the primary and gap-timing-unaware datasets
  agree in sign with overlapping component intervals; four differ in sign
  while retaining overlapping intervals.
- The exact longest-period identifiability sensitivity contains 500
  participant-days, 132 participants, and all nine sites. All four factor
  directions agree with the all-available result. The F2 ratio attenuates from
  1.117 to 1.046 (95% CI 0.930 to 1.175).
- Participant-level Spearman coefficients are explicitly descriptive and do
  not form a second significance screen.

No noon sensitivity was added, consistent with the author decision. The
deferred expensive analyses remain deferred.

## Reuse of frozen results and provenance

No model was refitted, no leave-one-site-out analysis was rerun, and no
bootstrap was added. The reader-artifact builder checks the frozen inputs and
only pairs existing estimates with manuscript labels, prepares reader-facing
CSV files, and draws figures from stored results.

The final Stage 3 manifest contains 144 non-circular file identities and verifies
before writing that every file in the frozen Stage 2 manifest still has its
recorded SHA-256 hash. The manifest excludes itself and this handoff by design;
its own identity is reported here.

| File | SHA-256 |
|---|---|
| `notebooks/hypotheses/H05.qmd` | `b75b10bafefe3dfe7b7fdc809b0e31f0b477c6bc2c454bba1cf64b50dc5ed73b` |
| `_build/nathealth/notebooks/hypotheses/H05.html` | `ca1c9fbc3920ec72da6660ffb8d5fb585ca75ef96e65fbab791b61b7a80cb34a` |
| `scripts/hypotheses/H05/build_h05_reader_artifacts.R` | `11a9568193764e3c145ecd3ceaebffa954e347925b29be155367e41225531388` |
| `scripts/hypotheses/H05/build_h05_stage3_manifest.R` | `f538d2a2420a30be440cb5e4efc8884da5a51504f79280559ad5f0c4d6033212` |
| `tests/hypotheses/H05/test_h05_stage3_reader_report.R` | `936e8677c30926b5af20b02566c23104f8f201c91535ce48ae7950b39ef14f0a` |
| `artifacts/12_manifests/H05/H05_stage3_artifacts.csv` | `abc7480eded838a4108a27781c04d8a85dde09c4de99b2402b4a6673981a7958` |

Reader figures have non-empty alternative text. The rendered HTML contains 26
bounded `gt` tables, seven accessible figures, a six-row exact-formula table,
four 17-row paired component tables, and links to the paired figure/table
source data used in the report. Individual PNG figures were inspected at final
display size. The only defect found, a clipped Q--Q diagnostic subtitle, was
repaired by wrapping the annotation; frozen estimates and source data were not
changed. The reader-artifact builder now identity-checks the frozen Stage 2
comparison figures instead of rewriting their timestamp-bearing PDFs.

## Verification commands

Run from the project root with R 4.6.1 and the project `renv` library:

```text
R_PROFILE_USER=/dev/null \
R_LIBS=renv/library/macos/R-4.6/aarch64-apple-darwin23 \
Rscript --vanilla scripts/hypotheses/H05/build_h05_reader_artifacts.R

R_PROFILE_USER=/dev/null \
R_LIBS=renv/library/macos/R-4.6/aarch64-apple-darwin23 \
quarto render notebooks/hypotheses/H05.qmd --profile nathealth

R_PROFILE_USER=/dev/null \
R_LIBS=renv/library/macos/R-4.6/aarch64-apple-darwin23 \
Rscript --vanilla scripts/hypotheses/H05/build_h05_stage3_manifest.R

R_PROFILE_USER=/dev/null \
R_LIBS=renv/library/macos/R-4.6/aarch64-apple-darwin23 \
Rscript --vanilla tests/hypotheses/H05/test_h05_stage2.R

R_PROFILE_USER=/dev/null \
R_LIBS=renv/library/macos/R-4.6/aarch64-apple-darwin23 \
Rscript --vanilla tests/hypotheses/H05/test_h05_stage3_reader_report.R
```

## Author disposition and closure

The author approved the Stage 3 report and explicitly authorized Stage 4.
`H05-002` and `CHG-077` record that transition. `H05-003` and `CHG-080`
verify the completed companion and close H05. No commit, push, upload, or
external publication action was made by this task.
