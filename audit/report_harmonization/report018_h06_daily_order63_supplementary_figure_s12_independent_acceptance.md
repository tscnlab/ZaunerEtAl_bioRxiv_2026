# REPORT-018 H06_daily order 63 Supplementary Figure S12 independent acceptance

Date: 2026-08-31

Status: `ACCEPTED_CANDIDATE_ONLY`

Owner: H06_daily task `019fec6a-20d3-7710-ab9b-a035e0874182`

## Accepted outputs

- PNG: `audit/hypotheses/H06_daily/manuscript_selection_supplementary_figure_s12/H06_daily_supplementary_figure_s12.png`, SHA-256 `8b66509d8fee47521f6179c793a612d1ec707a330a7a45a2715c449d0136e75f`, 622,084 bytes.
- SVG: `audit/hypotheses/H06_daily/manuscript_selection_supplementary_figure_s12/H06_daily_supplementary_figure_s12.svg`, SHA-256 `4d95b3f1160a310baa6152f2ec7acecdd03da16c835ddcfbada6676cafd56d0d`, 24,374 bytes.
- Builder: `scripts/hypotheses/H06_daily/build_h06_daily_manuscript_supplementary_figure_s12.R`, SHA-256 `73db8e6830f49f6405bdb91ee942b498797c1383aab9259cbf4afa42c39f6c42`.
- Verifier: `tests/hypotheses/H06_daily/test_h06_daily_manuscript_supplementary_figure_s12.R`, SHA-256 `9582d5f8105e36f1acf101f6f500462af1daae07d8c740d62eed9638f7c32141`.
- Owner completion: SHA-256 `f0748a79d4c24403a4bf857269f9130d3521ef88a73ee2c9baeeeef338fe3893`.
- Owner 14-row non-circular manifest: SHA-256 `d41dbc38b033cbe73f9580e95d1a4fa9a3243c1a661e41f5fe4b794c835878b7`.

## Independent verification

Fresh R 4.6.1 verification reproduced:

- 14/14 owner-manifest members exact, unique, and non-circular;
- 22/22 focused checks PASS;
- 90/90 frozen source rows reconciled one-to-one to the SVG display;
- 57 FDR-supported cells, 27 ordinary not-supported cells, and six L10 non-estimable cells;
- all six MDER cells encoded as ordinary `Not FDR-supported` open grey circles;
- exactly three legend classes, with no MDER-specific label, magenta class, polygon, or legend key;
- all 84 non-MDER SVG marks and both 3 by 15 panel grids structurally identical to the accepted canonical display;
- zero decoded-raster changes outside the six MDER marker boxes and legend region;
- original-size and 170-mm visual QA PASS, with 7.26-point minimum effective text at manuscript width; and
- no Quarto, knitr, Pandoc, semantic hook, browser server, model, prediction, inference, resampling, canonical-figure, source-data, QMD, HTML, profile, or lockfile operation.

The focused candidate verifier was independently executed against the retained temporary pair and returned PASS under R 4.6.1. Direct visual inspection of both the 3776 by 3680 candidate and the 2142 by 2088 170-mm preview found complete panels, legible labels, correct three-class legend, and no clipping or overlap.

The attempt ledger truthfully retains three candidate-verifier-only stops and one final-sealer storage-type stop. All occurred without candidate regeneration or replacement. The candidate pair was built once and promoted once after the candidate gate passed.

## Preservation and next boundary

The accepted H06_daily reader QMDs, HTMLs, canonical FDR PNG/SVG, frozen 90-row source CSV, scientific artifacts, historical manifests, selection page, profile, and `renv.lock` remain unchanged.

This acceptance authorizes the two selection candidates as inputs to a later, separately bounded manuscript-selection integration. It does not authorize a QMD edit, HTML edit, canonical figure replacement, manuscript or selection render, or scientific action.

Coordination matrix SHA-256 after acceptance: `c56a40142cabc1234c974768df384c23667de9b9ffe7c6714ddfcbbf6db62a52`.
