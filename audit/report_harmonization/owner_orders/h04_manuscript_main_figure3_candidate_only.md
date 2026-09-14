# H04 manuscript main Figure 3 candidate-only order

## Disposition

Prepare one candidate-only four-panel H04 manuscript figure for author review. This order authorizes no artifact promotion, H04 report edit, Quarto command, manuscript integration, or render.

## Scientific and display objective

Combine the accepted near-eye temporal display as panels **a-c** with the accepted near-eye activity-by-site factorization as panel **d**. Preserve the complete temporal block at its native aspect ratio. The composite must use the current activity and site colour handling, consistent typography, consistent printed values, and balanced panel dimensions at intended manuscript size.

Use reader-facing terms `site-average estimate` and `activity-by-site interaction model`. Do not introduce an internal H04 label or describe the interaction model as a heterogeneity model.

## Frozen inputs

- `notebooks/hypotheses/H04.qmd`: `f8adb6d78be041ce296dd7e89eb92769b128631c1b4227ce5d8ab3d526daf1d5`
- `_build/nathealth/notebooks/hypotheses/H04.html`: `edb592760ee086c4b58abf7ab8946dbdf2be2c4b35bb7e6f11d84f66f71160e0`
- `artifacts/10_figures/H04/H04_temporal_near_eye.png`: `8f048e0716e036413f541054a03c521941b4728f661871223b3e4c238991b3d4`
- `artifacts/10_figures/H04/H04_temporal_near_eye.svg`: `2a804065daa8550523f90391350ed9ec654f3ad66dbc3d5e410ef408739a7678`
- `artifacts/10_figures/H04/H04_temporal_near_eye.pdf`: `627376f457ec710793834755d7bde8f37389c213e10763334dfaab7b77f2d379`
- `artifacts/11_source_data/H04/H04_reader_temporal_near_eye_curves.csv`: `97025e3f0166b8d4c896cd7504ac75c32aa49a7b315b8b17aef9929c1669d7e1`
- `artifacts/11_source_data/H04/H04_reader_temporal_near_eye_ratios.csv`: `26a5c2de41e46894171b1442cb41da8053c633bda97d8a68b1ba514262bfc613`
- `artifacts/11_source_data/H04/H04_reader_temporal_near_eye_global.csv`: `4f4445bb359bf3023d97b4e2445e3905950c22d570f9d47fc3ed554d12d34749`
- `artifacts/11_source_data/H04/H04_reader_temporal_near_eye_support.csv`: `6d0a3a3b82d7c4dbbbb8863bf09307ec1ffa719f09e71593c5e9eae69516e508`
- `artifacts/09_tables/H04/H04_reader_heterogeneity_category_estimands.csv`: `733086079d21a6bb13ea36a43020c6a0d0204f648797337dff1d6ea4dcd32084`
- `artifacts/06_model_data/H04/H04_category_support.csv`: `bd8b8837e2357ca18466c080c6121eee6b857e4440554e662d3632cb308cd463`
- `scripts/hypotheses/H04/build_h04_stage3_reader_figures.R`: `2ae1ae770d4b0cf3725b04cd337d883659d429ff9a8f7c482d38f0af516c158a`
- `scripts/hypotheses/H04/build_h04_stage3_reader_assets.R`: `9fef4f87941e28c0db784d5e9ef2971cd96e1d5f8ffd55847b51ccbcc2a24c60`
- `artifacts/12_manifests/H04/H04_stage3_reader_asset_manifest.csv`: `b7963a6bf11617ea4831ce8e53baaf1e9d6746a0bd147ca866cd1fbbb8901be3`
- `artifacts/12_manifests/H04/H04_stage3_artifacts.csv`: `6215a9496f5f542ff92c19536b5601aa49c1ca804523eb7f9ff8bfdff852e115`

Do not substitute the similarly named non-reader temporal support file.

## Exact data contract

R 4.6.1 must reproduce, without changing a scientific artifact:

- 126 participants;
- 724 participant-days;
- 16,135 unique participant-hours;
- 16,875 generated long rows;
- 16,135 effective weighted hours;
- nine sites;
- 4,746 exact-zero participant-hours;
- five retained activity categories in their accepted order;
- 45 site-category cells in panel d;
- exactly 44 estimable multiplicity-family members;
- exactly one support-non-estimable cell, San José (CR), Outdoors; and
- exactly 17 FDR-labelled site deviations.

The focused test must verify these counts and every displayed estimate, confidence interval, FDR label, category, site label, and support token against the frozen inputs.

## Authorized candidate work

Create only:

- `scripts/hypotheses/H04/build_h04_manuscript_figure3_candidate.R`;
- `tests/hypotheses/H04/test_h04_manuscript_figure3_candidate.R`;
- candidate outputs inside one fresh temporary directory; and
- evidence inside `audit/hypotheses/H04/manuscript_figure3_candidate/`.

The builder may read only the frozen display and source endpoints listed above. It must not fit or refit a model, predict from a stored model, bootstrap, resample, alter a multiplicity family, or write a scientific artifact.

## Panel-tag and preservation boundary

The accepted temporal artwork contains uppercase `A`, `B`, and `C`. Change only those tags to bold lowercase `a`, `b`, and `c` inside their existing tag boxes. Add a matching bold lowercase `d` tag to the new factorization panel.

Require:

- cropped panel a-c decoded-pixel identity outside the three existing tag boxes;
- normalized SVG identity outside the three tag nodes and the composition wrapper;
- no change to data geometry, axes, scales, colours, legends, values, confidence bands, support marks, or source notes in panels a-c; and
- the complete a-c block preserved at its native aspect ratio.

## Candidate caption and support note

Retain the supplied scientific caption language. The composite caption or panel-d support note must state the exact frame contract: 126 participants, 724 participant-days, 16,135 unique participant-hours, 16,875 generated long rows, 16,135 effective weighted hours, nine sites, and 4,746 exact-zero participant-hours.

## Candidate QA

Before returning:

1. Run Air and R parse checks on the new builder and test.
2. Run the focused test once under R 4.6.1.
3. Inspect the PNG and vector candidate at original size and intended 170 mm width.
4. Require legible lowercase tags, complete panel-d values, no clipping, overlap, truncation, missing cells, colour change, or unintended whitespace.
5. Seal one non-circular candidate manifest and one completion or stopped-state record.

## Prohibitions

No canonical artifact overwrite, artifact promotion, H04 QMD or HTML edit, Quarto or Pandoc command, shared manifest or configuration edit, ledger edit, manuscript or selection-document edit, model fit, prediction, bootstrap, scientific recomputation, commit, push, upload, or render is authorized.

Stop after the candidate package and return it for author and independent central approval.
