# REPORT-018 order 48 consolidated fail-closed result

Date: 2026-08-21

Target: `notebooks/hypotheses/H06_daily.qmd`

Disposition: `FAIL_CLOSED`

No source patch, second render, companion render, scientific recomputation, shared-file edit, commit, push, or later-target execution was performed.

## Outcome

The sole authorized result-page render completed under R 4.6.1 and Quarto 1.9.37 with exit code 0. Static, semantic, identity, and build-delta checks passed. Secure loopback QA then identified two genuine display defects that prevent acceptance of the current page:

1. Tables 5, 6, and 7 have predictor-specific captions but repeat the same three-predictor content.
2. Figures 1 through 4 do not meet the explicit 7-point essential-text floor at the intended 170-mm width. Figure 5 meets the floor.

The result page is therefore returned as one consolidated fail-closed defect package. These defects do not authorize an in-order patch or rerender.

## Sole render and semantic audit

The sole render command was:

```text
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H06_daily-order48-semantics.0DTIvF quarto render notebooks/hypotheses/H06_daily.qmd --profile nathealth
```

The accepted source remained byte-identical at SHA-256 `01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08`. The fresh result HTML is SHA-256 `15c537269ac0be96ce06c6b574946dc0b98d46afe36c3c696f804a216a7d0c76`, 11,691,631 bytes.

The semantic hook reported `REPAIRED` for 14 native `gt` tables and made 818 substitutions. Reversing the ledger reproduced the pre-hook SHA-256 `73ee70c0f080d16ac9d6c8cd9f3b1427e1ff7791f0bb74542006359925aad968`; applying it forward reproduced the final HTML. Visible text, table values, element order, captions, notes, links, and geometry were unchanged across this repair.

The render console disclosed failed fetch attempts for the held companion HTML and `Datatype.woff2`. Neither warning was embedded in the result HTML. Direct link checks passed, and the browser console contained zero warnings or errors. These messages are disclosed as nonblocking render-console observations, not page defects.

## Defect 1: predictor-tab bodies do not match their captions

Tables 5, 6, and 7 are captioned for Free versus Work day, Active versus Sedentary status, and previous-night sleep duration, respectively. Their rendered table-body texts are nevertheless exactly identical. Each mean-melEDI row contains all three primary estimates, `0.69`, `1.16`, and `0.89`, rather than only the estimate named by that tab.

The frozen placement source CSV is structurally correct: 180 rows cover three predictors, four scenarios, and 15 metrics, with exactly one row per metric, predictor, and scenario. The defect is in display code, not the frozen estimates.

The live `placement_table()` expression is:

```r
filter(.data$predictor_id == predictor_id)
```

Inside the dplyr data mask, the unqualified right-hand `predictor_id` resolves to the data column. The predicate therefore compares the column with itself and retains every predictor. The same unsafe expression exists in the currently unused `primary_table()` helper, but that helper is not called by this page and did not create an additional rendered defect.

Required later repair: under a new authorization, qualify the function argument as `.env$predictor_id`, rebuild only the affected tables from the frozen placement CSV, and repeat the render and semantic and visual audits. No scientific model or stored result needs to be recomputed for this display-code repair.

## Defect 2: four figures fail the final-size text floor

At the controlling 170-mm width, the effective minimum essential text sizes are:

| Figure | Essential text | Effective size | Gate |
|---|---|---:|---|
| 1, primary ratio effects | metric axis labels | 5.02 pt | Fail |
| 2, primary absolute effects | metric axis labels | 5.02 pt | Fail |
| 3, FDR overview | metric and legend labels | 5.96 pt | Fail |
| 4, site deviations | site and tick labels | 5.36 pt | Fail |
| 5, temporal GAMM | axes, subtitles, and legend | 7.97 pt | Pass |

The 708-pixel viewport displayed each figure at 642 pixels and gave materially equivalent minima. Visual inspection confirmed that Figures 1 through 4 are readable at the desktop viewport but too small at the required final size. The values, marks, geometry, site codes, and frozen source data were not changed.

Required later repair: under a new display-only authorization, rebuild Figures 1 through 4 from their frozen source data with typography and canvas geometry that keep essential text at or above 7 points at 170 mm. Re-audit their original and final-size exports before rerendering the page. No model, estimate, interval, p-value, FDR decision, or diagnostic may change.

## Checks that passed

- All 46 non-matrix dispatch identities reproduced before rendering.
- The result source retained 15 parseable R chunks, 14 unique native `gt` table endpoints, five figure endpoints, and seven dynamic QMD links, with no prohibited scientific-regeneration call.
- All 12 nonvisual acceptance domains passed, including exact semantic reversal, 231 unique document IDs, and all 1,293 explicit table-header reference tokens resolving exactly once.
- The Answer in brief callout, hourly-main and complementary-daily hierarchy, reciprocal companion link, DEV anchors, active navigation, all nine country-coded sites, and all seven dynamic links were retained.
- The complete reader flow was inspected at 1440 by 1000, 708 by 1000, and 720 by 500. There was no page-level horizontal overflow. Tab switching, tables, figures, captions, notes, links, axes, legends, symbols, and disclosures were inspected.
- The classified build transition consisted only of the result HTML, two expected search or sitemap changes, 25 source-identical target resource copies, and one modification-time-only CSS entry.
- After browser QA, all 846 build members and all 3,260 protected members were byte-identical to their post-render inventories. The build contained zero symlinks.
- The held companion QMD and HTML remained byte-identical at SHA-256 `ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709` and `7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259`.
- The loopback viewport was reset, the QA tab was closed, the server exited with code 0, and no listener remained on `127.0.0.1:56199`.

## Evidence index

The primary evidence files are:

- `visual_fail_closed_defect_summary.csv`: the two consolidated defects and later bounded repair requirements;
- `placement_tab_content_audit.csv`: rendered-tab hashes, captions, and repeated-value evidence;
- `placement_source_cardinality_audit.csv`: proof that the frozen source rows are predictor-specific;
- `figure_final_size_typography_audit.csv`: figure-by-figure effective text sizes and gate results;
- `nonvisual_status.csv`: the 12 passing static and semantic domains;
- `semantic_reverse_audit.csv` and the 818-row semantic ledger: exact reversal evidence;
- `order48_final_gate_summary.csv`: final domain-level gate disposition;
- `build_reconciliation_postqa.csv` and `protected_reconciliation_postqa.csv`: post-QA byte-identity proof;
- `loopback_lifecycle.csv`: secure server and browser teardown evidence;
- stable screenshots and browser measurement JSON files for all required viewports, all 14 tables, and all five figures; and
- `order48_fail_closed_manifest.csv`: the non-circular package manifest.

The H06_daily companion and all later REPORT-018 targets remain held pending independent disposition of this result-page defect package.
