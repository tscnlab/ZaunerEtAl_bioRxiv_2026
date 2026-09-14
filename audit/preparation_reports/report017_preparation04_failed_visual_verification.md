# REPORT-017 Preparation 04 failed narrow-visual verification

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `_build/nathealth/notebooks/preparation/04_metric_derivation.html`  
Outcome: **Desktop passed. The 708-pixel view stopped on unreadably scaled text in the horizontal Mermaid overview.**

No Preparation 04 QMD, configuration, rendered output, scientific artifact,
decision, manifest, production script, or handoff was edited during visual
verification. The only source-code change in the full order was the separately
authorized focused-test harness repair recorded in the two stopped-test
checkpoints. Preparation 05 was not started.

## State entering visual QA

The targeted render had completed successfully under the normal R 4.6.1
project profile and Quarto 1.9.37. The recovered focused test passed:

```text
PASS: Preparation 04 satisfies the bounded-render, version-specific verification, gt-table, figure, terminology, and provenance contract.
```

The current test SHA-256 is
`8a3caf85f230002c43c7efd46af6f6986dc6611d5e2954fa5f0edd20334b2704`.
The final 106-path comparison recorded 105 byte-identical protected paths and
the one authorized test-harness change, with no unexpected difference. The
comparison is stored in
`audit/preparation_reports/report017_preparation04_testrecovery_final_scoped_verification.csv`
(SHA-256 `bf567104a990cb43e91d9bcb905e5bf6b785add22ee44a55e433d34ff8398c3a`).

The rendered DOM contained 14 unique native `tbl-*` endpoints. This is the
controlling count after the accepted METRIC-011 addition
`tbl-l10-numerical-zero`; owner order 22's count of 13 is superseded metadata.
All 14 tables had nonempty captions, headers, body rows, and their intended
source-note structure. Reader-facing links and active navigation passed, and
the page contained no raw console/tibble output, unresolved cross-reference,
or rendered error text.

## Secure loopback method and teardown

One read-only GET/HEAD server was rooted exactly at the existing build:

```text
python3 -u /private/tmp/report017_preparation04_loopback.py
```

- Root: `/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/_build/nathealth`
- Address: `127.0.0.1:49809`
- PID: `56901`
- Start: `2026-08-13T15:55:53.085147+02:00`
- Stop: `2026-08-13T16:05:29.365903+02:00`
- Process exit status: `0`

The browser viewport override was reset and its QA tab was finalized before
server teardown. After the keyboard interrupt, `lsof -nP -iTCP:49809
-sTCP:LISTEN` returned exit status 1 with empty output, the expected no-match
PASS proving that no listener remained.

## Desktop result at 1440 by 1000 pixels

Desktop inspection passed:

- document and main-content widths were contained, with no page-level
  horizontal overflow or clipping;
- all 14 native `gt` tables fitted their 1,148.5-pixel containers and retained
  minimum 11 CSS pixel text, equivalent to 8.25 points;
- captions, headers, rows, source notes, links, callouts, long identities, and
  the active `04 Metric derivation` navigation item were readable and intact;
- the MDER figure displayed at 691 by 403 CSS pixels from its 1,382 by 806
  pixel PNG, with readable axis, tick, direct-label, legend, and caption text;
- the visible MDER counts were 702/816 near-eye and 732/902 chest for the
  primary dataset, and 687/811 near-eye and 723/897 chest for the
  gap-timing-unaware dataset; and
- the PREP-003/FIND-044 version-specific qualification remained visible and
  unchanged in meaning.

The horizontal Mermaid overview displayed at 1,148.5 CSS pixels from a
1,314.414-unit view box. Its scale of 0.874 reduced nominal 16 CSS pixel labels
to approximately 13.98 CSS pixels, or 10.49 points, so it passed REPORT-011 at
desktop size.

## Narrow result at 708 by 1000 pixels

The page itself remained intact: document client width and scroll width both
equalled 693 CSS pixels, the main content remained within its 642-pixel
container, callouts wrapped without clipping, and the active navigation item
remained available. All 14 native tables used contained `overflow-x: auto`.
Thirteen fitted the 642-pixel container directly; Table 13 had a 670-pixel
table inside its 642-pixel scroller. This is usable contained overflow and
passes the controlling native-table policy. The MDER PNG displayed without
distortion at 642 by 374.42 CSS pixels.

The Mermaid overview failed final-size typography. It displayed at 642 CSS
pixels while retaining the 1,314.414-unit horizontal view box. The scale of
`0.48843` reduced nominal 16 CSS pixel node labels to approximately 7.81 CSS
pixels, equivalent to `5.86 pt`. These labels carry the central preparation
sequence and fall below REPORT-011's normal 7-point minimum. Direct visual
inspection confirmed that the node labels were too small to read comfortably.

The defect is confined to the Mermaid direction declaration `flowchart LR` at
source line 1569. No repair was made in this order. The narrow screenshot is
`audit/preparation_reports/report017_preparation04_narrow_top.png` (SHA-256
`2b5ed43e852ab49a9bafe17dc638f23943c791820397b826c3ce8a2cc7f5977c`).

## Protected identities at the stop

| File | Bytes | SHA-256 |
|---|---:|---|
| `notebooks/preparation/04_metric_derivation.qmd` | 80,557 | `86041585edfb60ba0f3137d268418e7479b369be859b41350d2347bd81e064a6` |
| `_quarto-nathealth.yml` | 7,404 | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| `tests/test_preparation04_report.R` | 13,456 | `8a3caf85f230002c43c7efd46af6f6986dc6611d5e2954fa5f0edd20334b2704` |
| `_build/nathealth/notebooks/preparation/04_metric_derivation.html` | 558,230 | `fba5e6f81251123b16deb6728321a558c3722c6bc26c4a946edf8712c570dd06` |
| `_build/nathealth/notebooks/preparation/04_metric_derivation_files/figure-html/fig-mder-availability-1.png` | 47,303 | `423cae8946a50bd6e611ff14708b7ff0543546f3fdc9e9fa030ca917838d75ce` |

`git diff --check` passed for the owned source, focused test, and Preparation
04 audit records. No builder, production scientific verifier, model,
prediction, bootstrap, simulation, or artifact regeneration was run.
