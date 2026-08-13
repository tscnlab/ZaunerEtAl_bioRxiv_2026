# H06-D-G4 preparation and provenance companion gate

- Date: 2026-08-13
- Status: bounded companion complete; awaiting explicit author review
- Scope: H06_daily-owned preparation and provenance only

## Completed endpoint

The author accepted the revised H06_daily Stage 3 reader report and instructed
this task to continue. The authorized bounded follow-up created and narrowly
rendered:

- `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`; and
- `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html`.

The companion is scientific documentation of the analytical unit, exact
inputs, metric and predictor registries, fitted samples, site and category
support, model routes, estimands, multiplicity, diagnostic architecture,
sensitivity branches, exploratory jointly adjusted models, exploratory
30-minute GAMMs, code order, and stored output provenance. It links to, but
does not duplicate, the accepted complementary results report.

The renderer verified stored identities and schemas and calculated bounded
descriptive summaries of already fitted samples. It did not fit or refit a
model, predict, re-estimate temporal correlation, calculate or adjust a
p-value, rerun deletion analyses, bootstrap, or simulate. The accepted Stage 3
QMD, HTML, and gate identities remain unchanged.

## Exact audit outcome

- All 19 pinned scientific and reporting inputs passed SHA-256 verification.
- The registry contains 15 participant-day outcomes, three recorded contexts,
  522 exact metric-by-predictor-by-role fitted-sample records, 12 dataset-
  qualified 15-slot multiplicity families, 405 primary site-support rows, and
  six exact temporal fitted-support rows.
- The standalone HTML contains 17 compact `gt` tables, one embedded source-
  paired figure with alt text, one Mermaid analysis-path diagram, rendered
  mathematical notation, and one informational note callout.
- Original-resolution figure inspection passed labeling, overlap, panel
  balance, clipping, and final-size legibility checks. The PNG is 3,011 by
  2,657 pixels; its intended 170 by 150 mm display retains an effective
  minimum text size of approximately 8.7 pt.
- Rendered-DOM checks passed. Automated browser control of the local `file://`
  page was unavailable, so that check is recorded as one disclosed limitation.
  No workaround was used.
- The focused R 4.6.1 test passed and verified the input contract, exact
  registry sizes, selected fitted denominators, stored diagnostic summaries,
  temporal support, no analytical calls in executable report chunks, rendered
  structure, manifests, and preservation of the accepted Stage 3 identities.

## Sealed identities

| Artifact | SHA-256 | Bytes |
|---|---|---:|
| `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd` | `fdfe94cf96e16ecfff3455c3e2427bd94c6419ee62350211a724821870058c0e` | 33,731 |
| `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html` | `7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259` | 4,613,650 |
| `scripts/hypotheses/H06_daily/build_h06_daily_preparation_artifacts.R` | `3196d183e35b3c9b206bfb181cd3a53f5657017d3f8877102a05304761eca1ca` | 39,366 |
| `scripts/hypotheses/H06_daily/seal_h06_daily_preparation.R` | `14b034188a77d1090e764264382b8a27c84ac6bb9771fe77c54301f55d922115` | 17,551 |
| `tests/hypotheses/H06_daily/test_h06_daily_preparation_report.R` | `4fbf8ba28dc957295ec5c90e42247f644c0010b3097195652d1e260fb6bdc2a0` | 10,471 |
| `artifacts/12_manifests/H06_daily/H06_daily_preparation_source_data_manifest.csv` | `19f441e87912962c7d60268899511c1f3a8e4c318502a6ed1c79e7e8e125f8ba` | 4,878 |
| `artifacts/12_manifests/H06_daily/H06_daily_preparation_software_manifest.csv` | `25f547ccf47c8c3afc75d9b43dc457fe41d4bac7e2e9cf16baf710f7384d95e9` | 2,047 |
| `artifacts/12_manifests/H06_daily/H06_daily_preparation_figure_readability_qa.csv` | `ae5dbb7a2a9f7f0dc47a60297e6bc9a244d103859186748756797332942dba45` | 1,603 |
| `artifacts/12_manifests/H06_daily/H06_daily_preparation_render_qa.csv` | `840fdaef6c31a51e2aabd6727a60b66a8a9df54cb0199b4a6c018c3080ea22de` | 1,916 |
| `artifacts/12_manifests/H06_daily/H06_daily_preparation_output_manifest.csv` | `50461464c788a882635809881638856dde8b6f16a8593eb0fa76194be9feb190` | 8,334 |
| `audit/hypotheses/H06_daily/H06_daily_analysis_preparation_report_manifest.csv` | `1579815ec9d3110f4e5b37fe7f5843947f1e0543dbe1b219c834be0ba388e28d` | 3,675 |

## H06-D-G4 author decisions requested

Please decide whether to:

1. accept the bounded preparation and provenance companion as the scientific
   documentation paired with the complementary H06_daily results report;
2. accept its explicit separation of the participant-day daily-metric,
   jointly adjusted daily, 30-minute temporal, and selected hourly H06
   estimands;
3. accept the sample, model-route, multiplicity, diagnostic, sensitivity, and
   provenance descriptions, including the disclosed local-browser QA
   limitation; and
4. close H06-D-G4 or request bounded companion revisions.

No website integration is requested at this gate. Shared Quarto configuration,
central ledgers, manuscript files, main H06, scientific outputs, commit, and
push remain outside this task's authorization. H06_daily stops here for
explicit author review.
