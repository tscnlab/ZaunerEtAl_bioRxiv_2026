# REPORT-018 owner order 63: H06_daily Supplementary Figure S12 FDR legend repair

Date: 2026-08-31

Owner: H06_daily task `019fec6a-20d3-7710-ab9b-a035e0874182`

Disposition: `AUTHORIZED_ONCE_CANDIDATE_ONLY`

Scientific authority: the accepted H06_daily Stage 3 analysis and its frozen 90-row FDR-overview source data.

The accepted H06_daily QMDs, HTMLs, canonical PNG/SVG, scientific artifacts, selection document, and every render remain held.

## 1. Controlling decision

This order implements only the author-approved Supplementary Figure S12 display correction retained in `audit/report_harmonization/report018_post_navigation_display_queue_2026_08_24.md`, SHA-256 `9ebb1d81ef202b420aec42d12e5de372871edec780c5f72885e18d327f0f5a36`.

The six estimable MDER cells are scientifically FDR-not-supported. In the selection candidate they must use the same ordinary `Not FDR-supported` symbol and legend entry as every other estimable unsupported cell. Remove only the redundant MDER-specific magenta-diamond class and legend entry. Preserve the separate L10 non-estimable encoding.

The earlier table-layout instruction is withdrawn and must not be revived. The accepted `tbl-h06-daily-primary-matrix` endpoint, the selection preview treatment, and all reader pages remain unchanged.

## 2. Hard preflight

Before any owner write:

1. Reproduce every row of `audit/report_harmonization/report018_h06_daily_order63_dispatch_manifest.csv` by exact SHA-256 and byte count. The coordination matrix is dispatch-time evidence only and is not an owner execution pin.
2. Require R 4.6.1 and the accepted project library. Record consequential package versions.
3. Reproduce the accepted H06_daily result and companion records and their non-circular seals.
4. Require the accepted result source and HTML at `8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639` and `7fd65a465185a341d5065a2c47b07d510b2ff331a3a99e56bc7f90044e755a02`.
5. Require the accepted companion source and HTML at `b1d2c9ec6184e9c537af04119d94040b581ae691069e38e0a713935ab1582536` and `29f03d5b13833d793653d4061ab8deea47596765ba6aec22a77a8c07bc71b6de`.
6. Require the canonical FDR overview PNG and SVG at `3dc2cf8de4597c1ce85d1acd65404778c14e75fa9f4920e7bfe1b83571bc048a` and `1ecfc0156b7ee6ddedc96f1943c597a583516732383c6ac9c799a4dba2e362bd`.
7. Require the frozen paired source CSV at `4a9a7c3f0877872e2efe7bfddd73afac1c50299f60474bd8d328ce945f17ddf1`.
8. Read the CSV under R 4.6.1 and require exactly 90 rows, 15 metric slots, three predictors, two analysis sets, six MDER rows at metric slot 15, six L10 rows at metric slot 3, 57 FDR-supported rows, 21 ordinary unsupported rows, and no missing or duplicated analytical cell.
9. Require all six MDER rows to have `fdr_supported == FALSE` and current display status `MDER result (not FDR-supported)`. Require all six L10 rows to retain `L10 non-estimable`.
10. Inventory the task-owned evidence root before work and stop if a prior order-63 implementation already exists.

Do not patch a failed preflight. Return one stopped package.

## 3. Exact owned paths

The owner may create only:

- `scripts/hypotheses/H06_daily/build_h06_daily_manuscript_supplementary_figure_s12.R`;
- `tests/hypotheses/H06_daily/test_h06_daily_manuscript_supplementary_figure_s12.R`; and
- files below `audit/hypotheses/H06_daily/manuscript_selection_supplementary_figure_s12/`.

The two durable selection candidates must be:

- `audit/hypotheses/H06_daily/manuscript_selection_supplementary_figure_s12/H06_daily_supplementary_figure_s12.png`;
- `audit/hypotheses/H06_daily/manuscript_selection_supplementary_figure_s12/H06_daily_supplementary_figure_s12.svg`.

No other path may be created, changed, moved, removed, or normalized.

## 4. Frozen-source display build

The new R 4.6.1 builder may read only:

- `artifacts/11_source_data/H06_daily/H06_daily_stage3_fdr_overview_figure.csv`;
- the accepted canonical PNG/SVG as display baselines; and
- minimum plotting constants copied explicitly from the accepted order-48 refresh implementation.

It must not source or execute the order-48 builder, a broad figure builder, a model builder, a manifest builder, or any Quarto document. It must not read or deserialize any model, model frame, fit, prediction object, inferential RDS, or scientific manifest.

The builder must transform only the in-memory display classification:

```r
display_status = dplyr::if_else(
  .data$display_status == "MDER result (not FDR-supported)",
  "Not FDR-supported",
  .data$display_status
)
```

The paired source CSV itself remains byte-identical and is not copied or rewritten.

Required candidate contract:

- exactly 90 plotted cells in the accepted row, predictor, analysis-set, and facet order;
- exactly three legend classes: `FDR-supported with limitations`, `Not FDR-supported`, and `L10 non-estimable`;
- 57 supported cells unchanged;
- 27 estimable unsupported cells using the ordinary unsupported symbol and colour, including all six MDER cells;
- six L10 non-estimable cells using the existing L10 symbol and colour;
- no magenta MDER diamond and no MDER-specific legend entry;
- every estimate, raw p-value, BH/FDR value, rank, support decision, sample, metric label, predictor label, analysis-set label, count, order, coordinate, panel, scale, break, title, subtitle, note, and non-colour cue preserved;
- accepted dimensions `3776 x 3680` pixels, 320 DPI, and corresponding SVG width `849.60pt` and height `828.00pt`;
- typography, margins, panel geometry, legend position, and canvas geometry unchanged except for removal of the redundant legend entry;
- no text that changes or reinterprets the scientific result.

## 5. Candidate-first execution

1. Create one fresh temporary candidate directory outside the project.
2. Build the PNG and SVG there.
3. Run the complete focused verifier against those temporary files.
4. Perform visual QA at original size and at 170 mm manuscript width. Check every panel, metric row, marker, label, legend entry, title, subtitle, note, clipping, overlap, and effective text size.
5. Require a structural SVG audit proving the three-class legend and all 90 plotted cells.
6. Require a decoded-raster and normalized-SVG comparison showing that changes are confined to the six MDER markers and the removed MDER legend entry. Panel geometry and every non-MDER data mark must remain identical.
7. Only after all candidate checks pass, copy the two files once to the durable selection-candidate paths.

Candidate iterations are permitted only before the first durable write and only to correct a genuine display-contract failure. The owner must record every attempt. After the first durable write, no replacement attempt is authorized.

## 6. Verification and seal

The focused R 4.6.1 verifier must fail closed unless all of the following pass:

1. source CSV hash and 90-row scientific content are unchanged;
2. canonical PNG/SVG, QMDs, HTMLs, profile, `renv.lock`, order-48 scripts/tests/manifests, accepted records, and handoff are byte-identical;
3. all six MDER cells map only to ordinary unsupported display encoding;
4. all six L10 cells retain the non-estimable encoding;
5. the candidate has exactly three legend classes and no MDER-specific class, label, magenta diamond, or legend key;
6. every source row and analytical field reconciles one-to-one to a plotted cell;
7. dimensions, DPI, SVG canvas, panels, scales, labels, and all non-MDER marks satisfy the preservation contract;
8. original-size and 170-mm visual QA pass;
9. the owner diff contains only the two new R files and the bounded evidence/candidate root;
10. no Quarto, knitr, Pandoc, semantic hook, browser server, model, analysis, fit, prediction, resampling, inference, or scientific regeneration process ran; and
11. the final owner manifest is exact, unique, non-circular, and excludes itself.

Return one completion record, one verification summary, one visual-QA record, one exact input/output inventory, one source-to-display reconciliation, one attempt ledger, and one non-circular final manifest.

If any genuinely new defect appears, complete safe read-only evidence collection and return one fail-closed stopped package. Do not patch outside the authorized candidate stage and do not rerun after durable promotion.

## 7. Explicit prohibitions

No canonical figure replacement, QMD edit, HTML edit, result or companion render, selection-page edit or render, source-data edit, model or scientific computation, new estimate, p-value or FDR calculation, scientific manifest rewrite, profile or lockfile change, broad builder, historical evidence change, coordination-matrix edit, commit, push, upload, or publication action is authorized.

This order produces only a bounded Supplementary Figure S12 selection candidate. Its later integration into a manuscript or selection page requires separate central authority.
