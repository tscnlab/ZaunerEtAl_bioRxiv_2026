# REPORT-018 H06 order 47c completion record

Date: 2026-08-21  
Owner: H06 hourly  
Outcome: PASS  
Scope: two exact Quarto table endpoints, one H06 result render, and the required nonvisual and visual acceptance package

## Controlling order and preflight

- Order: `audit/report_harmonization/owner_orders/47c_h06_hourly_formula_endpoints_and_result_render.md`
- Order SHA-256: `510d6ed1d380c71a1d20cb55c3db3197e63954b579e84d305c871b7a06b47861`
- Dispatch manifest: `audit/report_harmonization/report018_h06_order47c_dispatch_manifest.csv`
- Dispatch SHA-256: `e05b0afecabb9f4f384f2e98844411455b81425e11d6be6481f358d53e55a4d1`
- Dispatch audit: 93 data rows, 92 hard rows after excluding the coordination matrix, 0 mismatches.
- No competing render process and no symlink in `_build/nathealth` were present.
- A fresh semantic-audit directory was created at `/private/tmp/h06_order47c_semantic.Tv5J9P`.

The coordination matrix was treated as dispatch-time evidence only and was not edited or repinned.

## Authorized source transition

Only `notebooks/hypotheses/H06.qmd` changed before rendering.

- Preimage: `2e88ad6b3a4aaffd2dfbf429a77c5d0865256554bb9b7799648fe63b976f1526`, 60,680 bytes.
- Postimage: `d65c197cb37db32101d8a43fcdc80198ab599a95cb73259abd187c9b2b58d350`, 60,791 bytes.
- Exact transition and reverse proof: `source_transition_and_reverse_proof.md`.
- Reverse reconstruction reproduced the preimage exactly.
- All 20 result R chunks parsed under R 4.6.1. There were no inline R expressions.
- Exactly 13 unique `tbl-*` labels and six unique `fig-*` labels occurred in source order.
- Every native gt-producing chunk had one table endpoint and one Quarto-owned caption.
- Both formula-table R bodies, values, roles, formula strings, source notes, and positions were byte-identical after excluding the approved metadata lines.
- No source cross-reference targeted either retired ordinary chunk label.
- The accepted figure-QA transformation and contract remained exact.

## Commands and versions

Versions:

- R 4.6.1, aarch64-apple-darwin23;
- Quarto 1.9.37;
- Python 3.9.6 for the read-only loopback server.

Sole render command:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/h06_order47c_semantic.Tv5J9P quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

The render executed all 41 cells once and exited 0. No companion, H06 daily, later target, or full-project render ran.

## Render and semantic acceptance

The semantic hook reported `REPAIRED`.

- Pre-hook HTML: `c5a0dfe1d5076cc4c0a7cdaf926eff3811dab0f9bece5f5a2b34af9730e73371`, 4,863,796 bytes.
- Final HTML: `8b5f1b0ada997290ec5324de35e0c874fd25e2e9ef052281acaab07d0a3dccaa`, 4,874,263 bytes.
- Native tables: 13.
- Repaired IDs: 64.
- Repaired `headers` tokens: 340.
- Total reversible substitutions: 404.
- Semantic summary: `gt_html_semantic_post_render_summary.csv`, SHA-256 `51445398f0649f1d827fd8034354e5b96b1bd220b77b10e895a9bd793941395a`, 456 bytes.
- Reversible ledger: `001__build__nathealth__notebooks__hypotheses__H06.html_gt_semantic_ledger.csv`, SHA-256 `bfc9a72231ad6b4a777fae57614f838f46a55eaa3373d10cee54ac51f1256c13`, 83,758 bytes and 404 data rows.
- Reversing the ledger reconstructed the pre-hook HTML exactly. Reapplying it reconstructed the final HTML exactly.

The final page had 1,810 unique document IDs, 1,712 unique links, and 1,710 internal links. All explicit table-header references resolved once within their table. There were no unsupported ID references, missing non-held internal targets, invalid fragments, unresolved cross-references, embedded error or warning nodes, forbidden local links, or build-path links.

Both companion links resolve in the retained site. The H06 daily link was classified as the sole held internal link and was not opened, inspected, or rendered. All four DEV links resolve to their exact anchors. Active navigation is `H06 results`, all nine country-coded study sites are present, and all 19 source links are present.

The only Pandoc warnings were the same three previously accepted resource warnings:

1. `Could not fetch resource ../../audit/hypotheses/H06/H06_analysis_preparation.html`
2. `Could not fetch resource ../../audit/hypotheses/H05/H05_analysis_preparation.html`
3. `Could not fetch resource ../../Datatype.woff2`

No additional warning appeared. The final page contains none of these warnings.

## Ordered endpoints

Table endpoints:

1. `tbl-h06-primary-effects`
2. `tbl-h06-primary-site-interactions`
3. `tbl-h06-site-specific-associations`
4. `tbl-h06-gap-sensitivity-comparisons`
5. `tbl-h06-key-sensitivities`
6. `tbl-h06-influence-checks`
7. `tbl-h06-model-checks`
8. `tbl-h06-exploratory-diary-associations`
9. `tbl-h06-exploratory-two-part-formulas`
10. `tbl-h06-exact-samples`
11. `tbl-h06-exact-confirmatory-formulas`
12. `tbl-h06-fdr-adjustment`
13. `tbl-h06-figure-readability-checks`

Figure endpoints:

1. `fig-h06-core-effects`
2. `fig-h06-primary-site-associations`
3. `fig-h06-paired-placement`
4. `fig-h06-residual-clock`
5. `fig-h06-exploratory-day-type-time`
6. `fig-h06-exploratory-activity-time`

The two repaired table captions are exactly `Exploratory two-part formulas.` and `Exact evaluated Wilkinson formulas.` Their formulas wrap within their cells and their source notes are present.

## Classified build changes

The complete 836-member build inventory had no added or removed file and exactly four classified target-render changes:

1. `_build/nathealth/notebooks/hypotheses/H06.html`: `dc62f37001c2d7e9f5a2daa9167023e006aafecc72c2d0137925093e573027c1` at 4,862,444 bytes to `8b5f1b0ada997290ec5324de35e0c874fd25e2e9ef052281acaab07d0a3dccaa` at 4,874,263 bytes.
2. `_build/nathealth/search.json`: `865db8b7a8130846fca38367f62af2a2526ad0a6129713b25f3324c012b9c53e` at 2,172,525 bytes to `d8696050af3525259a0dd6f4bb0054ed8f7b6060d757c1f7eb2c1d4002476803` at 2,172,640 bytes.
3. `_build/nathealth/sitemap.xml`: `e021df3eec96763cab02cd83962a2fbfa0c739186f7ad5c5ee6a3fbe55317b9a` at 5,742 bytes to `71cdaf108a39b857ba83564bc522f85d39f430630248176f7c1162920c708758` at 5,742 bytes.
4. `_build/nathealth/site_libs/bootstrap/bootstrap-a2a938b4dd5711f7a799c87bd16ba44c.min.css`: content remained `b3d78f1077461003efc2b21acc3f81ee6ba80468fe09df310b4c339e2e19133c` at 498,438 bytes; only the render-time modification timestamp changed.

Three expected H06 Quarto support files changed:

- `.quarto/_freeze/notebooks/hypotheses/H06/execute-results/html.json`: `f602ac6385dfea2d0480153f26a9062675f7f731f799fde3b904c337c11f5ccb`, 236,574 bytes;
- `.quarto/idx/notebooks/hypotheses/H06.qmd.json`: `2546184e05c86db604a3c4677a5f0cd8a48a8b31c35b19ba0153e28b2c3bea62`, 132,231 bytes;
- `.quarto/xref/ba60df9d`: `2cfd01d1b48d7554e863fbddd0cc2969c950ecea0864bdcf225d1d31fe211720`, 5,288 bytes.

No build symlink, missing member, or unclassified build content delta was found.

## Secure loopback visual QA

The exact root `_build/nathealth` was served only on `127.0.0.1:54873`. The exact route inspected was `/notebooks/hypotheses/H06.html`. The server log contains only successful H06 page requests plus a browser favicon 404. The server was stopped after QA, and `lsof -nP -iTCP:54873 -sTCP:LISTEN` returned exit 1 with no output. Browser runtime logs were empty. The viewport override was reset.

Viewports:

- desktop: 1440 by 1000;
- narrow: 708 by 1000;
- 200-percent-equivalent: 720 by 500;
- intended final output: each stored PNG inspected directly and at approximately 170 mm in the rendered page.

All 13 native tables and all six figures were visually inspected. The checks covered typography, formula wrapping, axes, legends, labels, symbols, panels, captions, disclosures, callouts, navigation, links, clipping, overlap, and page overflow.

Results:

- no horizontal page overflow at any viewport;
- no clipped table or figure;
- no missing table caption or figure alt text;
- no formula-cell overflow;
- the dense site table retained a 9.5-pixel, approximately 7.1-point minimum table font and remained readable;
- at 708 pixels, the model-check table uses a visible contained horizontal scroller, while the page itself does not overflow;
- all six stored PNGs had readable titles, axes, legends, site labels, symbols, panels, and disclosures at the declared 170-mm width;
- no clipping, overlap, harmful wrapping, distortion, or materially imbalanced data region was found.

Measurements are in `browser_qa_measurements.json`, SHA-256 `667f63393612d4ff0782ce48527e7ec6cac7dfd7d067ccc488c94a8d6dfef9b6`, 25,881 bytes. Twelve browser screenshots are retained under `screenshots/`.

## Protected stability and final identities

After the source edit, render, semantic repair, browser QA, server shutdown, and viewport reset, all 90 protected paths matched their preflight SHA-256 and byte counts. The following controlling identities remained exact:

- contract: `scripts/hypotheses/H06/h06_contract.R`, `b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f`, 13,468 bytes;
- companion source: `audit/hypotheses/H06/H06_analysis_preparation.qmd`, `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`, 59,613 bytes;
- companion HTML: `_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html`, `222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`, 771,694 bytes;
- profile: `_quarto-nathealth.yml`, `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`, 7,480 bytes;
- semantic wrapper: `scripts/report_harmonization/post_render_gt_html_semantics.R`, `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`, 21,453 bytes;
- semantic engine: `scripts/report_harmonization/repair_gt_html_semantics.R`, `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`, 17,747 bytes;
- lockfile: `renv.lock`, `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`, 603,493 bytes.

No QMD other than the exact authorized result source changed. No contract, companion, H06 daily, source CSV, stored figure, scientific artifact, profile, package, lockfile, ledger, shared source, test, existing manifest, catalog, or navigation file changed. No model, inference, scientific calculation, artifact regeneration, commit, push, upload, or publication action occurred.

## Execution notes

- A preliminary temporary post-render checker incorrectly assumed every accepted table had a source-note block. Read-only inspection showed four accepted tables intentionally had none. The checker was corrected to compare pre-hook and post-hook source-note counts and contents and to require the two formula-table notes. The definitive post-render gate then passed. No source, artifact, or rendered page was changed and no rerender occurred.
- The first loopback bind attempt was blocked by the sandbox before a listener was created. The approved narrow loopback escalation then started the server successfully. This was an environment-only event.
- One browser wait helper did not support `networkidle`; the page was instead confirmed at `load` with `document.readyState = complete`. This was a browser-client capability detail, not a page defect.

Genuine new defects: none.
