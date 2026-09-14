# Phase 4 reader-corpus source verification

Date: 2026-08-12  
R: 4.6.1 (2026-06-24)  
Scope: source text, configuration, paths, anchors, and file identities only;
no Quarto source code or scientific analysis was executed.

## Accepted source corpus

- 35 accepted reader-facing QMD sources are recorded in
  phase4_corpus_manifest.csv.
- All 11 result reports are immediately followed by their accepted
  preparation/provenance companion in both the Nature Health render list and
  sidebar.
- notebooks/preregistration_deviations.qmd follows Descriptives in the
  Analysis overview.
- The comparison contract, H03–H11 gated workflow, legacy _deviations.qmd,
  and assemble-artifacts workflow are outside the reader corpus.
- Main hourly H06 remains the sole H06 reader result. H06_daily remains
  excluded pending acceptance of its reader-facing source.

## Passing structural contracts

- tests/report_harmonization/test_navigation_contract.R: PASS for 35
  accepted reader sources.
- tests/report_harmonization/test_reader_links.R: PASS for 35 QMD sources
  and all 86 deviation IDs/anchors.
- tests/report_harmonization/test_country_coded_site_names.R: PASS for 35
  reader sources. Proper instrument, institution, and competing-interests
  names containing “Munich” are explicitly classified as non-site contexts.
- tests/report_harmonization/test_phase2_package.R: PASS.
- tests/report_harmonization/test_preregistration_deviations.R: PASS for the
  deterministic 86-entry page and its 60/1/19/6 visible sections.
- tests/report_harmonization/test_gt_table_contract.R (non-strict Phase 2
  inventory gate): PASS.

## Shared accepted identities

- index.qmd:
  bde8b03095bc4d4a47a8398f4cf565b1d1aa6f1d1dc4989b81d91b9453898022;
- _quarto-nathealth.yml:
  b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5;
- notebooks/preregistration_deviations.qmd:
  b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d.

## Remaining render gate

This is a source-only acceptance. The manifest currently finds 34 of 35
expected HTML files; supplementary_information.html is absent. Existing HTML
files also predate some accepted source changes. Focused renders, visual QA,
the regenerated strict gt audit, principal-output review, and final HTML-link
verification remain pending a separate Phase 4 render release.
