# REPORT-018 owner order 48a: H06_daily consolidated display repair and result rerender

Date: 2026-08-21

Owner: H06_daily task `019fec6a-20d3-7710-ab9b-a035e0874182`

Disposition: `AUTHORIZED_ONCE`

Target: `notebooks/hypotheses/H06_daily.qmd`

The H06_daily companion and every later REPORT-018 target remain held.

## Controlling authority

This order implements the single consolidated disposition in:

- `audit/report_harmonization/report018_h06_daily_order48_consolidated_repair_concurrence.md`, SHA-256 `90e36dd860f6cc3226023c91ee65ba021b0a2e156c333e942bf6389ff10b2724`;
- its 25-row non-circular manifest, SHA-256 `806169c24867faebb04071b4a4b3f48e9d07e04c04a2c03c3736e970b4d7a5d2`; and
- the order-48 stopped-state independent acceptance, SHA-256 `a0864132f3d9a860f178494f080ea02b7c56e873a6c5d0704398a7ac7d7da244`, with 24-row seal `c963b3cea63e11258e5bf2bd8c76b926545896c7a8a169406d94c390519f34fc`.

Order 48 rendered once and stopped with exactly two display defects. All other scientific, semantic, link, navigation, build, and protected-identity domains passed. This order combines the table-code correction, four-figure display refresh, one durable promotion, one result rerender, and one complete acceptance package. Do not split it into separate owner returns.

## 1. Hard preflight and immutable baseline

Before any mutation:

1. Reproduce every row of `audit/report_harmonization/report018_h06_daily_order48a_dispatch_manifest.csv` by exact SHA-256 and byte count. Stop on any mismatch other than the coordination-matrix dispatch transition recorded after this order is sealed.
2. Reproduce the 25-row central concurrence manifest and the 108-row order-48 owner manifest as exact, unique, and non-circular.
3. Require R 4.6.1, Quarto 1.9.37, profile SHA-256 `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`, and no competing Quarto, Pandoc, semantic-hook, H06, or H06_daily render process.
4. Inventory the complete project-side protected set and `_build/nathealth`. Require zero build symlinks.
5. Preserve the stopped result HTML `15c537269ac0be96ce06c6b574946dc0b98d46afe36c3c696f804a216a7d0c76` as the pre-repair rendered baseline.
6. Preserve the held companion source and HTML exactly at `ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709` and `7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259`.

Do not patch a failed preflight. Return one stopped package.

## 2. Exact live-table source correction

Edit only the predicate inside the live `placement_table()` helper in `notebooks/hypotheses/H06_daily.qmd`:

```r
filter(.data$predictor_id == predictor_id)
```

becomes:

```r
filter(.data$predictor_id == .env$predictor_id)
```

The identical expression inside the unused `primary_table()` helper must remain byte-identical. No other QMD byte may change.

Required source transition:

- preimage SHA-256 `01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08`, 65,344 bytes;
- postimage SHA-256 `8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639`, 65,349 bytes.

Require an exact one-hunk diff and reverse reconstruction. Parse all existing R chunks under R 4.6.1. Before rendering, prove from the frozen 180-row placement CSV that the three predictor subsets are distinct and each has exactly 60 source rows, 15 metric slots, and four placement scenarios.

## 3. Dedicated four-figure refresh

Create exactly one dedicated H06_daily-owned R 4.6.1 refresh implementation and one focused verifier. Suggested stable paths are:

- `scripts/hypotheses/H06_daily/refresh_h06_daily_order48_figures.R`;
- `tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R`; and
- bounded evidence under `audit/hypotheses/H06_daily/report018_order48a_display_repair/`.

The refresh may read only these five data or registry inputs:

1. `H06_daily_non_l10_production_primary_ratio_effects.csv`, SHA-256 `c7a1c0018e82db71e2fb0fe74d6e3e5a6645948017b10dd938fce18f6c5c2a9d`;
2. `H06_daily_non_l10_production_primary_absolute_effects.csv`, SHA-256 `2b695be686e6fdfdef9bdad4082be1fdcd1100e0d3d763fac35b4a75b8df11a7`;
3. `H06_daily_stage3_fdr_overview_figure.csv`, SHA-256 `4a9a7c3f0877872e2efe7bfddd73afac1c50299f60474bd8d328ce945f17ddf1`;
4. `H06_daily_stage3_primary_site_deviation_figure.csv`, SHA-256 `12193a0a1795fe478bf4829a3986c2b1290510038e4c4aed59aa7e61714bcbcc`; and
5. `config/site_display_registry.csv`, SHA-256 `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`.

It must not read or deserialize a model, fitted object, inferential RDS, analytical frame, or broad scientific manifest. It must not source or execute any broad builder. The four historical builder or refresh scripts named in the dispatch manifest remain byte-identical.

### Historical-theme baseline

Use a fresh temporary directory outside the project for baseline and candidate work. Reconstruct all six current durable display files with the historical theme before candidate work:

- accept exact bytes when deterministic;
- otherwise require decoded PNG pixels to be identical and normalized SVG structure to be identical; and
- stop before candidate work on any visible, geometric, data-layer, scale, break, label, panel, colour, shape, point, line, interval, or null-reference difference.

### Candidate boundary

Candidate iterations are allowed only before the first durable write. They may change only:

- essential typography within the ranges below;
- plot margins;
- panel spacing;
- label wrap width; and
- canvas height, by no more than 15 percent.

Output width and DPI stay fixed. Preserve every source row, value, interval, status, point, line, reference, category, label meaning, colour, shape, facet, panel order, scale, and break.

Essential nominal text must stay within:

- 12.6 to 14.0 points for the primary ratio and absolute figures;
- 12.5 to 14.0 points for the FDR overview; and
- 10.8 to 12.0 points for the site-deviation figure.

Require at least 7.0 effective points at both 170 mm and the 642-pixel narrow display. Validate original size, 170-mm width, the 708-pixel page width, and the 720 by 500 200-percent-equivalent view. Every label, axis, legend, symbol, panel, and disclosure must remain present, legible, unclipped, and nonoverlapping.

## 4. One recoverable six-file promotion

After one complete candidate set passes, preserve exact recoverable preimages in the bounded owner evidence and promote the six candidates together exactly once:

1. `artifacts/10_figures/H06_daily/H06_daily_non_l10_production_primary_ratio_effects.png`, preimage `a50f6b25c1c09abca1700870594d26a15e2085ec1c2a4c8eb5f6bc0f727cfa66`;
2. `artifacts/10_figures/H06_daily/H06_daily_non_l10_production_primary_absolute_effects.png`, preimage `da67b5f8a27b49d7c4d0e6426563d79aaa540ef835e350d02fd952a3a134c686`;
3. `artifacts/10_figures/H06_daily/H06_daily_stage3_fdr_overview.png`, preimage `48283afc83e9ebcd0f7d02177dacc162287940126c335b47efab11cc54c9edd9`;
4. `artifacts/10_figures/H06_daily/H06_daily_stage3_fdr_overview.svg`, preimage `ef8a3ba3d502804c5b7a01f9d21fada9d598006b8d6fcd83f0c721bd96dbda84`;
5. `artifacts/10_figures/H06_daily/H06_daily_stage3_primary_site_deviations.png`, preimage `a1ddd2ae719d5a6ab11c1c591801d4b4aa7cb06f9eb0bcad7c983d8024fd86e1`; and
6. `artifacts/10_figures/H06_daily/H06_daily_stage3_primary_site_deviations.svg`, preimage `b23f9a6838c2ecc476bdb5e68c203e0c7a85d05479a65841f75ee02d21e20b1c`.

Figure 5, `H06_daily_temporal_h02_primary_context_functions.png`, must remain byte-identical at `e28c639f23b3f33687ca046a77069153bb66073d29cd03d96fd03408c4317d98`.

Create a new non-circular current display manifest, exact preimage-to-postimage ledger, source-input inventory, no-scientific-call audit, candidate validation, and visual-QA evidence. Preserve every historical H06_daily test and manifest byte-for-byte. Do not run a broad manifest builder and do not rewrite a historical row to claim the new displays were historical.

## 5. Complete pre-render gate

Before Quarto:

1. require the QMD at the exact authorized postimage;
2. parse all result R chunks;
3. pass the new focused display verifier;
4. prove the three predictor-specific 60-row subsets and complete four-scenario support;
5. prove all four source CSVs and the site registry unchanged;
6. prove all six durable outputs candidate-identical and Figure 5 unchanged;
7. prove every non-display scientific artifact and every held companion path unchanged;
8. pass Air formatting for the two new R files and scoped `git diff --check`; and
9. prove there has been no model, fit, refit, prediction, simulation, bootstrap, resampling, inference, p-value, FDR, diagnostic, or scientific source-data call.

Do not execute the unchanged historical live-identity test or rewrite historical manifests. Their accepted REPORT-014 classifications remain historical evidence.

If any pre-render gate fails, stop once. Do not render.

## 6. Sole result rerender

Only after all pre-render checks pass, create one fresh, empty, absolute semantic-audit directory and issue exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H06_daily.qmd --profile nathealth
```

Use normal R 4.6.1 and Quarto 1.9.37 project and `renv` startup, with only the established narrow access to the existing user-owned cache if required. Do not bypass the profile or semantic hook. No second render is authorized.

## 7. Post-render semantic and content acceptance

Against the fresh HTML, require:

1. exactly 14 native gt tables, five figures, seven dynamic links, and the accepted endpoint order;
2. semantic-hook `REPAIRED` or an already-valid equivalent with exact reverse and forward evidence, document-wide unique IDs, and every explicit `headers` token resolving exactly once inside its own table to the intended `th`;
3. Tables 5, 6, and 7 with distinct predictor-specific bodies, exactly 15 metric rows and four placement columns each, and every displayed cell reconciled to its frozen predictor-specific source row;
4. all five figures, captions, alt text, paired source links, values, marks, order, and labels, with Figure 5 unchanged;
5. the accepted complementary-daily hierarchy, hourly-main links, reciprocal companion link, DEV anchors, active navigation, and all nine country-coded study sites;
6. zero embedded error, warning, stderr, unresolved cross-reference, raw trace, forbidden local or build link, or unsupported internal target; and
7. the held companion source and HTML, profile, semantic tools, source data, scientific artifacts, and all unrelated hypotheses byte-identical.

Classify the build delta explicitly. Only the authorized QMD copy, six target-owned figure copies, result HTML, search, sitemap, normal source-identical target resources, bounded semantic audit, and modification-time-only framework touches may differ. Fail on any unclassified content change. Keep `audit/report_harmonization/phase4_corpus_manifest.csv` unchanged in this result-only order; its H06_daily HTML transition remains pending companion and shared integration.

## 8. Secure loopback QA

After all nonvisual checks pass:

1. preflight `_build/nathealth` for symlinks and stop on any unsafe resolution;
2. start one temporary read-only static server rooted exactly at `_build/nathealth`, bound only to `127.0.0.1` on an unused high port;
3. navigate only to the exact H06_daily result route in the in-app Browser;
4. inspect the complete page at 1440 by 1000, 708 by 1000, and 720 by 500, plus original and 170-mm figure sizes;
5. inspect all 14 tables and five figures, especially predictor-specific Tables 5 through 7 and the four repaired figures;
6. apply the accepted table policy: desktop usability is required, while narrow tables may use a contained, working horizontal scroller without page-level overflow;
7. check typography, legends, axes, labels, symbols, panels, captions, disclosures, callouts, links, navigation, clipping, overlap, wrapping, and overflow;
8. stop the server, prove no listener remains, reset the viewport, and close the QA tab; and
9. rehash the complete build and protected inventories and require post-QA stability.

## 9. One combined return

Return one complete non-circular acceptance package with exact commands, R, Quarto and consequential package versions, input and output identities, source diff and reverse proof, candidate history, preimage recovery, visual evidence, semantic reversal, build and protected reconciliation, server lifecycle, and final identities.

If a genuinely new defect appears, finish every safe read-only inspection and return one consolidated stopped package. Do not patch or rerender inside this order.

## Prohibitions

No source-data edit, model, fit, refit, prediction, simulation, bootstrap, resampling, Shapley or dominance computation, estimate, interval, p-value, FDR decision, diagnostic, sensitivity, inference, scientific artifact regeneration, broad builder, historical test or manifest rewrite, companion edit or render, later render, full-project render, profile, package, lockfile, ledger, commit, push, upload, or publication action is authorized.

The H06_daily companion and every later REPORT-018 target remain held pending independent result-page acceptance.
