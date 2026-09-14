# REPORT-018 H06 order 47d no-rerender acceptance

Date: 2026-08-21

Owner: H06 hourly

Outcome: **PASS**

## Scope and authority

This record completes the authorized read-only continuation of H06 order 47d.
The already-rendered companion page was inspected and reconciled without a
second render. The accepted hourly result stayed fixed. H06 daily and every
later render stayed held.

The controlling no-rerender concurrence is
`audit/report_harmonization/report018_h06_order47d_test_stop_no_rerender_concurrence.md`,
SHA-256
`b4eef3626e5a6a83209fd4c04e278bc1f390a54a2a6ccd01021eb9ab12882dd1`.
Its 20-row manifest is SHA-256
`2bf82dd065ecb7af79aa1717836478b3caf701359a00d0ed25d3dedc3f9369ce`.
The accepted PNG classification is
`audit/report_harmonization/report018_h06_order47d_response_png_delta_classification.md`,
SHA-256
`df2ec2b57d36a64c2c11cbc766a25d0841aa913559baec950c9fa046724090ec`.
Its 20-row manifest is SHA-256
`464020499116e93a5463b0a46b8dfc61aaf073c6c4b5fb142ee1d6a9097868fc`.

## Two accepted classifications

1. The retired literal result-link assertion in
   `tests/hypotheses/H06/test_h06_preparation_report.R` is deferred under
   REPORT-018. The test stayed byte-identical at SHA-256
   `2b9f02f7caa448a3c7fdb88b0febc5ce306239002ebe220b6f5f7a7c4285a4fc`.
   The companion source contains three approved dynamic `.qmd` result targets,
   zero retired `.html` result targets, and the existing final HTML resolves
   the result links correctly.
2. The response-distribution PNG transition from SHA-256
   `5cf25ad6cef9840e78a217ab083ca816105eacb37568ac788d3cd82c4bc31f46`
   to
   `ab51417026d3b3edd9c0af7a455961b9e018cd0d4396bc6ba2f615ac98e7f7a1`
   is the centrally accepted deterministic target-owned build delta. The
   current PNG has 105,561 bytes and the same 1920 by 1113 pixel canvas. The
   historical readability CSV and A4 proof stayed unchanged at SHA-256
   `49045b8064870acb8c51c797a7b75bf8962524da2239397f70a3e457ede801dd`
   and
   `a7f6d8e8e30e4ce7be812049766e15631c579d1216dc0d0c88c24b6cb029c6d5`.

The exact classifications are also recorded in
`continuation_classification.csv`.

## Static and semantic acceptance

The R 4.6.1 preflight passed before browser inspection:

- 7 of 7 controlling pins were exact;
- the 20-row no-rerender manifest, 20-row PNG-classification manifest,
  64-row stopped owner manifest, and 411-row preparation manifest were all
  exact, unique, and non-circular;
- the authoring and website companion QMDs were byte-identical;
- the existing HTML contained 30 native gt tables, three figures, and one
  top-down Mermaid flowchart;
- all document IDs were unique and all 1,142 gt header-reference tokens
  resolved exactly once;
- 2,505 internal links had existing targets and valid fragments, including
  the hourly result, the reciprocal companion link, and exact DEV-015,
  DEV-030, DEV-031, and DEV-032 anchors;
- the active H06 companion navigation and all nine country-coded study-site
  labels were present; and
- the final HTML had no embedded execution error, stderr, unresolved
  cross-reference, or raw local/build path.

The 985-row reversible semantic ledger remained exact at SHA-256
`c2bc57a6606c0dfb118b8405cb153e044a8c96e4008609e0c8b40b12892b6100`.
Its repair summary remained exact at SHA-256
`d520b2660419f896eb3733846e9347e0d254849bc31c2b9bdc5d9bd4032d8ecd`.

## Secure-loopback visual acceptance

One server was started with this exact command:

```text
python3 -m http.server 54317 --bind 127.0.0.1 --directory _build/nathealth
```

The exact route was
`http://127.0.0.1:54317/audit/hypotheses/H06/H06_analysis_preparation.html`.
The listener was restricted to `127.0.0.1:54317`.

The page was inspected at 1440 by 1000, 708 by 1000, and the 720 by 500
200-percent-equivalent viewport. The inspection covered:

- the title, subtitle, 28 headings, one scope callout, captions, links, active
  navigation, and previous/next navigation;
- all 30 gt tables, including the four technical-provenance tables inside the
  reader-controlled disclosure;
- all three figures and their source links;
- the complete top-down analysis-path diagram;
- the nine displayed site/country labels;
- the result links, the held daily link, and all four DEV links; and
- browser warnings, errors, broken images, overlap, clipping, wrapping,
  distortion, and content balance.

There was no page-wide horizontal overflow at any viewport. At 708 pixels,
four wide tables used contained horizontal scrolling. Each scroller was
exercised from its left edge to its right edge and reset. At the
200-percent-equivalent viewport, longer tables, figures, and the diagram
remained fully accessible through ordinary vertical scrolling. The browser
reported no warning or error entries and no broken images.

All 30 desktop table screenshots and all 30 200-percent-equivalent table
screenshots are retained under `screenshots/`, together with desktop, narrow,
and 200-percent-equivalent figure and diagram views.

## Final-size figure acceptance

The current response-distribution PNG was inspected at a 642 CSS-pixel page
width, equivalent to 169.86 mm and within 0.08 percent of the intended 170 mm.
The unchanged physical-size contract gives a native width of 254 mm, scale
factor 0.669, smallest essential nominal text of 12 pt, and effective final
text of 8.03 pt. It therefore exceeds the 7 pt threshold. Panel titles,
subtitles, placement labels, symlog ticks, endpoints, exact-zero percentages,
and marks were legible and unclipped.

The other two companion figures were also inspected at the intended width.
Their effective smallest essential text is 7.30 pt for the site-support figure
and 8.03 pt for the clock-support figure. All three passed clipping, overlap,
wrapping, distortion, mark separation, and content-balance checks. The exact
record is `figure_170mm_qa.csv`.

## Shutdown and postflight reconciliation

The server was stopped with Ctrl-C and exited 0. The command
`lsof -nP -iTCP:54317 -sTCP:LISTEN` then exited 1 with empty output, proving
that no listener remained.

The definitive R 4.6.1 postflight passed:

- 821 of 821 build files were byte-identical to the pre-browser inventory;
- there were no added, removed, changed, or symlinked build files;
- 469 of 469 protected paths were byte-identical to the pre-browser
  inventory; and
- 15 fixed result, companion, contract, profile, manifest, ledger, test, and
  held-daily identities were exact.

One preliminary temporary postflight checker stopped before reconciliation
because it joined two absolute semantic-evidence paths to the project root.
Only that temporary path resolver was corrected. The definitive checker then
passed. No project, build, browser, protected, scientific, or H06-daily file
changed during that checker-only stop.

## Fixed identities at return

- Hourly result QMD:
  `d65c197cb37db32101d8a43fcdc80198ab599a95cb73259abd187c9b2b58d350`.
- Hourly result HTML:
  `8b5f1b0ada997290ec5324de35e0c874fd25e2e9ef052281acaab07d0a3dccaa`.
- Companion QMD, both authoring and website copies:
  `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`.
- Companion HTML:
  `f9a4f51db555454a2e7cd0ea70895978b71016e6bd2c7310ae5033ad3c7ed378`.
- H06 contract:
  `b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f`.
- Nature Health profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- 411-row preparation manifest:
  `a3bd413daf9e154d78f32e49caea0697303c8d86ce387892ab081b06ae8b6bbc`.

The held H06-daily result source, companion source, result HTML, and companion
HTML also remained exact at the four identities recorded in
`key_identity_post_qa.csv`.

## Boundary confirmation

No Quarto render, helper rerun, preparation-test rerun, QMD execution, model,
prediction, inference, sensitivity calculation, bootstrap, simulation,
resampling, figure regeneration, source edit, HTML edit, manifest edit,
profile edit, package or lockfile change, ledger edit, H06-daily action,
commit, push, or upload occurred in this continuation. The accepted hourly
result and scientific artifacts are unchanged.
