# REPORT-018 H06_daily order 48 stopped-state independent acceptance

Date: 2026-08-21

Disposition: `ACCEPT_FAIL_CLOSED_TWO_DISPLAY_DEFECTS`

## Independent result

The order-48 owner return is complete, internally consistent, and independently reproducible. The sole H06_daily result render completed successfully, and every scientific, semantic, link, navigation, build, and protected-identity domain passed. Two genuine reader-display defects remain. They are consolidated below and require one later bounded repair and one later result rerender.

The stopped state is accepted as the controlling pre-repair baseline. It is not an accepted reader page.

## Reproduced authority

The following owner records reproduce exactly:

- completion record `audit/hypotheses/H06_daily/report018_order48_result_render/order48_fail_closed_completion.md`, SHA-256 `43b2f7aa09e449e770cf7e4d6bf4f7ec7e5eaaf5861011d0b0c2acba2e7dcc22`, 7,609 bytes;
- non-circular 108-row owner manifest `audit/hypotheses/H06_daily/report018_order48_result_render/order48_fail_closed_manifest.csv`, SHA-256 `795e163e1b3cea96e635097c0095f92765794b71f9eabb715be23c52874cbc8b`;
- owner verifier `audit/hypotheses/H06_daily/report018_order48_result_render/verify_order48_fail_closed_package.R`, SHA-256 `eed1ffe2cc6c6a3a6fbeedb7ac6e605c77c931b7b59f72ef03999919694568fb`, 3,519 bytes; and
- independent checker `scripts/report_harmonization/check_h06_daily_order48_stopped_acceptance.R`, SHA-256 `5705f04a16abb7389b32d6d2c0aa53baa2c214c6603864711d20cf31e998e563`, 6,108 bytes.

Both R 4.6.1 checks pass. The independent checker resolves all 108 owner-manifest paths by exact SHA-256 and byte count and confirms that the manifest is unique and non-circular.

The sole render produced `_build/nathealth/notebooks/hypotheses/H06_daily.html` at SHA-256 `15c537269ac0be96ce06c6b574946dc0b98d46afe36c3c696f804a216a7d0c76`. The accepted source remains `01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08`. The held companion source and HTML remain `ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709` and `7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259`.

## Passing domains

Independent replay confirms:

1. The post-render semantic hook repaired all 14 native gt tables through 113 ID and 705 `headers` substitutions, 818 substitutions in total. Exact reversal reproduces the pre-hook HTML.
2. The page retains five intended figures, seven dynamic links, the complementary-daily hierarchy, the hourly-main link, DEV anchors, active navigation, and all nine country-coded study sites.
3. All 12 nonvisual acceptance domains pass. No embedded error, warning, stderr, unresolved cross-reference, forbidden local link, or build symlink is present.
4. All 846 post-render build members and all 3,260 protected members remain byte-identical after browser QA.
5. Secure loopback inspection covered 1440 by 1000, 708 by 1000, 720 by 500, and intended output sizes. The server stopped cleanly and no listener remains.

## Consolidated defects

### ORDER48-DEFECT-001: predictor tabs repeat the wrong table body

Tables 5, 6, and 7 have correct predictor-specific captions but identical bodies containing all three predictors. The frozen placement CSV is correct: it contains 180 unique metric, predictor, and scenario rows, with 15 rows for each of the 12 predictor-by-scenario combinations.

The source defect is confined to `placement_table()` in `notebooks/hypotheses/H06_daily.qmd`:

```r
filter(.data$predictor_id == predictor_id)
```

The right-hand name resolves inside the dplyr data mask to the same data column. The later bounded correction is:

```r
filter(.data$predictor_id == .env$predictor_id)
```

The same unsafe form is present in the currently unused `primary_table()` helper. It did not create a rendered defect. Any repair order must state explicitly whether that latent helper line is included or preserved.

### ORDER48-DEFECT-002: four figures are below the final-size text floor

At 170 mm, the minimum essential text sizes are 5.02 points for Figure 1, 5.02 points for Figure 2, 5.96 points for Figure 3, 5.36 points for Figure 4, and 7.97 points for Figure 5. Figures 1 through 4 therefore fail the required 7-point floor. Figure 5 passes and must remain unchanged.

The four frozen figure-source CSVs, plotted values, confidence intervals, marks, categories, ordering, colours, labels, and figure endpoints are intact. The required correction is display-only. It may change typography and canvas geometry, but it must not change a scientific value, status, interval, row, symbol meaning, or source-data identity.

## Recommended single repair gate

To avoid another sequence of partial reruns, the next owner order should combine both defects and complete all candidate checks before one rerender:

1. correct the exact live `placement_table()` filter and add a focused predictor-specific table-body check;
2. create one dedicated R 4.6.1 display-refresh implementation that reads only the four frozen figure-source CSVs and the minimum accepted display registry, writes candidates outside the durable targets first, and never reads a model or inferential RDS;
3. preserve every figure row and mapped scientific aesthetic, require at least 7 points at 170 mm and the 708-pixel view, and require no clipping, overlap, or missing labels at original, final, narrow, and 200-percent-equivalent sizes;
4. after all candidate checks pass, replace only the six durable outputs for Figures 1 through 4, namely four PNG files and the existing SVG files for Figures 3 and 4, then directly reseal only their current dependent display records;
5. run exactly one H06_daily result render with the semantic hook and repeat the complete nonvisual and secure-loopback QA package; and
6. keep the H06_daily companion and every later render held until independent result acceptance.

No model fit, inference, source-data change, scientific artifact regeneration, broad builder, companion render, profile change, package or lock change, ledger change, commit, push, or upload is warranted.
