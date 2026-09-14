# H02 order-33 source-only execution record

Date: 2026-08-15

R version: 4.6.1
Checks passed: 41/42
Focused tests passed: 2/3

No Quarto render, QMD execution, model fit, prediction, bootstrap,
simulation, Shapley allocation, p-value calculation, or figure regeneration
was performed.

## Focused commands

- `NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 H02_REPORT_SOURCE_ONLY=true '/Library/Frameworks/R.framework/Resources/bin/Rscript' --vanilla tests/hypotheses/H02/test_h02_reader_report.R` (1.405 s; exit 0)
- `NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 H02_REPORT_SOURCE_ONLY=true '/Library/Frameworks/R.framework/Resources/bin/Rscript' --vanilla tests/hypotheses/H02/test_h02_preparation_report.R` (1.523 s; exit 1)
- `NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 '/Library/Frameworks/R.framework/Resources/bin/Rscript' --vanilla tests/hypotheses/H02/test_h02_paired_placement_display.R` (0.37 s; exit 0)

## Historical render classification

The Aug-1 preparation and worker manifests and both existing HTML pages
remain byte-identical historical render evidence. They do not describe the
revised source-only report state.

## Known historical-to-live mismatch sets

- `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv`: `_quarto-nathealth.yml`
- `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv`: `audit/hypotheses/H02/H02_analysis_preparation.qmd`
- `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv`: `notebooks/hypotheses/H02.qmd`
- `artifacts/12_manifests/H02/H02_worker_output_hashes.csv`: `audit/handoffs/H02_shared_change_request.md`
- `artifacts/12_manifests/H02/H02_worker_output_hashes.csv`: `audit/hypotheses/H02/H02_analysis_preparation.qmd`
- `artifacts/12_manifests/H02/H02_worker_output_hashes.csv`: `notebooks/hypotheses/H02.qmd`
- `artifacts/12_manifests/H02/H02_worker_output_hashes.csv`: `tests/hypotheses/H02/test_h02_paired_placement_display.R`
- `artifacts/12_manifests/H02/H02_worker_output_hashes.csv`: `tests/hypotheses/H02/test_h02_preparation_report.R`
- `artifacts/12_manifests/H02/H02_worker_output_hashes.csv`: `tests/hypotheses/H02/test_h02_reader_report.R`

Stopped with 1 failed checks; see H02_order33_source_audit.csv.
