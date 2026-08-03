# H08 worker handoff

Date: 2026-08-03
Branch: `rewrite/NH`
Current gate: **author accepted H08 package; coordinator integration and push requested**
Preparation companion created: yes
Preparation companion accepted: yes
Profile-integrated preparation render: no
Resampling performed: none

## Gate history

- The analytical audit fixed the accepted score, metric, sample, model,
  estimand, diagnostic, and sensitivity decisions without fitting a new
  inferential model.
- The author explicitly approved all recommended audit decisions on
  2026-08-01.
- The implementation package was accepted in full, including the no-retained-
  association conclusion, exact samples, 95% confidence intervals,
  multiplicity families, diagnostics, and sensitivities.
- The author approved the standalone H08 scientific reader report on
  2026-08-01 and authorised creation of its preparation and provenance
  companion.
- The H08-owned preparation source, standalone render, descriptive source
  data, display-only figure repair, A4 physical-size QA, manifest builder, and
  focused test now exist.
- The author accepted the preparation package on 2026-08-03 and requested a
  scoped H08 commit followed by a coordinator-owned GitHub push.
- Work is stopped because `_quarto-nathealth.yml` does not yet place the H08
  preparation page immediately after H08 in the render list and navigation.
  The exact upstream request is recorded in
  `audit/handoffs/H08_shared_change_request.md`.

## Accepted scientific conclusion remains unchanged

Across nine primary near-eye metrics, no average association or site-specific
heterogeneity test met the BH-adjusted criterion. The strongest directional
near-eye pattern was lower corrected melEDI dose per VLSQ-8 SD: ratio 0.846
(95% CI 0.716–0.999), likelihood-ratio raw p = 0.051, and BH-adjusted
p = 0.160. It is not a multiplicity-retained finding.

Complementary chest analyses and the central sensitivity analyses do not
materially strengthen the evidence. Uncertainty, complete-family adjustment,
and site influence make the directional pattern inconclusive. The preparation
work did not refit a model or change any scientific value.

## H08 preparation companion

- Source: `audit/hypotheses/H08/H08_analysis_preparation.qmd`
  - SHA-256:
    `b5feb96cf30faaa7cb0533c2d833171f304c0051f1b3115ec16f4fdbb7dcdc45`
  - bytes: 49,107
- Standalone verified render:
  `audit/hypotheses/H08/H08_analysis_preparation.html`
  - SHA-256:
    `8274204210e6c9babc0f2171ea9bb2864ae2c66c078f38644956887cc420137c`
  - bytes: 677,624

The render completed all 49 document steps under R 4.6.1. It contains 18
compact `gt` tables and three accessible descriptive figures, each linked to
an exact source-data CSV. It recalculates only bounded hashes, schema and key
checks, and lightweight descriptive support. It reads all scientific results,
diagnostics, and sensitivities from frozen H08 outputs.

Reader-facing content includes:

- an informational execution-boundary callout and reciprocal link to the H08
  results report;
- the first-use REPORT-010 explanation with 50%-per-hour, 80%-per-day,
  remaining-gap-timing, and one-time time-sensitive-primary wording;
- the VLSQ-8 rule (eight ordered 1–5 item codes plus 5), 184 complete scores,
  observed range 13–39, mean 21.598, and participant SD 5.540;
- all nine admissible participant-day metrics, missing-value rules, near-eye-
  primary/chest-complementary placement, and exact metric-specific samples;
- nine exact current Wilkinson formulae, model engines, practical estimands,
  95% confidence intervals, and eight complete nine-test BH families;
- response-family, residual-spread, zero-mass, remaining-gap-timing, and
  leave-one-site-out qualifications;
- paired placement, preparation, photoperiod, participant-summary, exactly
  identified longest-period, observed-dose, and site-omission sensitivities;
  and
- code, output, claim, environment, and reproduction maps.

The reader text contains no temperature or unsupported predictor, no internal
workflow history, and no `bout` terminology. Near eye remains primary and
chest remains complementary.

## REPORT-011 physical-size correction

Every H08 reader-facing figure was assessed at exactly 170 mm on an A4
portrait page with 20-mm side margins. The record contains native width,
intended width, scale factor, smallest essential nominal text, effective final
text, pixel dimensions, figure/source/proof identities, and the required
physical visual checks.

- QA record:
  `artifacts/12_manifests/H08/H08_figure_physical_size_qa.csv`
  - SHA-256:
    `27520754a8089d62aa13a66be3c72547e45fd60c5bd8d4d6bcc653bcb6f9f8a1`
  - bytes: 7,531
- Durable A4 proofs:
  `artifacts/12_manifests/H08/physical_size_qa/`
- Figures assessed: five H08 result figures and three preparation figures.
- Native and intended width: 170 mm for every figure.
- Scale factor: 1.0 for every figure.
- Smallest effective essential text: 7.5 pt for result figures and 8.0 pt for
  preparation figures.
- Final status: eight of eight PASS.

The first physical-size inspection exposed clipped caption text in all five
result figures. `rebuild_h08_reader_figures.R` rewrapped those captions and
re-exported the figures from the already stored H08 figure-source CSV files.
No model or scientific result was recomputed. The second original-size A4
inspection passed clipping/cropping, overlap, wrapping, distortion, important-
text readability, mark distinguishability, caption/alt presence, and data-
region balance for all eight figures.

The accepted result report was rerendered after this display-only correction:

- `notebooks/hypotheses/H08.qmd`
  - SHA-256:
    `6933b6ae770cd55794556c065e4c312079df1df5123e5c217ef6c06b12abd4a8`
  - bytes: 37,660
- `_build/nathealth/notebooks/hypotheses/H08.html`
  - SHA-256:
    `c216a59dfe335d990dc4f0c06867368c3bdbbabe2493dffb76e8d1d4701c17f4`
  - bytes: 297,552

Its five figures now use 100% intended width and its Reproducibility section
links back to the preparation companion.

## New H08-owned implementation and verification files

- `scripts/hypotheses/H08/build_h08_preparation_artifacts.R`
- `scripts/hypotheses/H08/rebuild_h08_reader_figures.R`
- `scripts/hypotheses/H08/build_h08_figure_physical_size_qa.R`
- `scripts/hypotheses/H08/build_h08_preparation_report_manifest.R`
- `tests/hypotheses/H08/test_h08_preparation_report.R`
- six preparation source-data CSV files under
  `artifacts/11_source_data/H08/`
- the physical-size QA record and eight A4 proof PNG files under
  `artifacts/12_manifests/H08/`

The final-manifest builder deliberately verifies shared profile adjacency
before writing anything. It has not created
`H08_preparation_report_manifest.csv` because the central profile is not yet
integrated. The earlier `H08_stage3_artifacts.csv` remains a historical
pre-correction record; the final preparation-report manifest will seal the
current result report, corrected figures, preparation page, and QA together.

## Verification completed

- Isolated H08 results render: 45 document steps completed under R 4.6.1.
- Standalone preparation render: 49 document steps completed under R 4.6.1.
- `tests/hypotheses/H08/test_h08_stage2.R`: `H08 Stage 2 tests passed`.
- `H08_PREINTEGRATION_ONLY=true` with
  `tests/hypotheses/H08/test_h08_preparation_report.R`: passed all frozen
  scientific assertions, 18 `gt` tables, three descriptive figures,
  reciprocal source links, exact source-data sizes, and eight REPORT-011 A4
  inspections.
- Current preparation-figure hashes remain identical to the hashes sealed in
  the QA record after the final standalone render.
- H08 R scripts and focused tests were formatted with Air.
- No heavy resampling, bootstrap, model fit, prediction, simulation, or
  full-project render was run.

## Required upstream action and final sealing

The coordinator must implement the two exact additions in
`audit/handoffs/H08_shared_change_request.md`, then run targeted profile
renders of H08 results and H08 preparation only. After hand-back, the H08 task
will:

1. inspect the final profile-integrated navigation and website figure assets;
2. refresh and re-inspect the physical-size proof record against those assets;
3. run `build_h08_preparation_report_manifest.R` to create the byte-identical
   website source copy and final identity inventory; and
4. run `test_h08_preparation_report.R` in strict mode.

After those checks pass, the coordinator can treat the accepted H08 workflow
as closed and push the scoped H08 commit. Further scientific approval is
needed only if an accepted output changes.
