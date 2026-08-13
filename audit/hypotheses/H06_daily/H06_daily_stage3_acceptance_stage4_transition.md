# H06_daily Stage 3 acceptance and Stage 4 transition

- Date: 2026-08-13
- Status: author accepted; bounded Stage 4 authorized
- Author instruction: `accepted. continue`

## Accepted scientific endpoint

The author accepted the revised standalone H06_daily reader report after its
equal-site and site-adjustment revision. The accepted report remains the
complementary, preregistration-oriented participant-day analysis. It does not
replace the selected main hourly H06 analysis.

The accepted Stage 3 identities are:

| Artifact | SHA-256 |
|---|---|
| `audit/hypotheses/H06_daily/H06_daily_stage3_revision_gate.md` | `733dd1dd4c57bfdb6df7bf10e69e635455c451373c8dd0f6e3060c12b6e3884e` |
| `notebooks/hypotheses/H06_daily.qmd` | `0318fd6cf874380631296d35095486b9de7f987a9779e4dc5d59c5a635a8c3dc` |
| `notebooks/hypotheses/H06_daily.html` | `5a20c0680011be17111f72bb6b15aed6a4f4700c8866a13ea6dcf49a589fcce3` |
| `artifacts/12_manifests/H06_daily/H06_daily_stage3_source_data_manifest.csv` | `77cd39b759a0bb46505c71db34f9b38818848531491f69afc7d67bf4dd8dc3ed` |
| `artifacts/12_manifests/H06_daily/H06_daily_stage3_output_manifest.csv` | `7c7658fca61687b0124f0f49a1b773fd1a101af7a5e6be641cd1adc2eb09c01e` |
| `artifacts/12_manifests/H06_daily/H06_daily_stage3_render_qa.csv` | `d61a2550545370532ea1e000b23b198be24380d27980ae72b2a17686f4433f2f` |
| `artifacts/12_manifests/H06_daily/H06_daily_stage3_revision_figure_readability_qa.csv` | `75f3e82a7fcfa6b846fbb13b5441d892767b322073222bd7b6d433ecfa318064` |
| `tests/hypotheses/H06_daily/test_h06_daily_stage3_reader_report.R` | `16e3d02bbfe443928708a8a6e2c793a04c47281afaa8993116e1c27d0bdaa8d2` |

The earlier central Stage 2-to-Stage 3 transition remains
`audit/decisions/h06_daily_stage2_acceptance_stage3_transition.md`, SHA-256
`26e3cf5302db74156a2ad929a80a1352eac6967ccf0e0e1adb5cdcfa71b9954e`.

## Authorized Stage 4 scope

The next bounded action is to create and render only
`audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd` as a lean
scientific preparation and provenance companion. It may read the accepted
H06_daily model frames, stored models, diagnostic tables, reader source data,
and manifests. Its render may calculate bounded descriptive summaries and
file-identity checks only.

It must not fit or refit a model, regenerate predictions, re-estimate temporal
correlation, rerun deletion analyses, recompute raw or adjusted p-values,
alter L10 or MDER, or modify the accepted Stage 3 report. It must not modify
main H06, shared Quarto configuration, central ledgers, manuscript files, or
website integration. The work stops at `H06-D-G4` for explicit author review.
