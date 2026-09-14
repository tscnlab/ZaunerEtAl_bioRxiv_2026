# REPORT-017 Preparation 04 final diagram verification

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `_build/nathealth/notebooks/preparation/04_metric_derivation.html`  
Outcome: **PASS**

Preparation 04 passed its bounded render, focused contract test, 106-path
preservation gate, semantic HTML audit, and final-size desktop and narrow
visual QA. Preparation 05 was not started.

## Sealed failure checkpoint and authorized repair

The preceding visual stop was sealed before editing:

- failed-visual record SHA-256:
  `ea98e02fb9296eb13d517964da013ec952edca99ddcb1dbe5fd336c228ba56bd`;
- non-circular failed-visual manifest SHA-256:
  `bb56e58653d22ba243169c584df838f65f71d0a36f33d134f37a6cb251ab2acf`;
- stopped server PID `56901`, start
  `2026-08-13T15:55:53.085147+02:00`, stop
  `2026-08-13T16:05:29.365903+02:00`; and
- listener closure: `lsof` exit 1 with empty output on port 49809.

The authorized repair changed one source line at line 1569:

```diff
-flowchart LR
+flowchart TB
```

No Mermaid node, edge, label, figure identifier, caption, alt text,
scientific prose, R expression, table, stored value, artifact path, test gate,
configuration entry, or handoff content changed. The source moved from
SHA-256 `86041585edfb60ba0f3137d268418e7479b369be859b41350d2347bd81e064a6`
to `6b7239ca32ecc6e75b993115f74fa2a42781ddded98ebf9ce94f2202777086d4`.
Applying the exact reverse substitution as a read-only stream reproduced the
accepted pre-edit SHA-256 `86041585edfb60ba0f3137d268418e7479b369be859b41350d2347bd81e064a6`.
`git diff --check` passed.

## Targeted render and focused test

Exactly one post-repair render command ran:

```text
quarto render notebooks/preparation/04_metric_derivation.qmd --profile nathealth
```

It used Quarto 1.9.37 and the normal project `.Rprofile` and `renv` activation
with R 4.6.1. The already approved narrow permission allowed transient access
only to the existing user-owned R 4.6 cache. No package was installed or
updated, and `renv.lock` was not edited. The render completed all 35 bounded
documentation stages with exit status 0 in approximately 43 seconds. It did
not call a preparation builder, production scientific verifier, model,
prediction, resampling procedure, simulation, or artifact writer.

The focused command `Rscript tests/test_preparation04_report.R` used the same
normal project startup and passed with exit status 0:

```text
PASS: Preparation 04 satisfies the bounded-render, version-specific verification, gt-table, figure, terminology, and provenance contract.
```

The accepted test-harness repair remained byte-identical at SHA-256
`8a3caf85f230002c43c7efd46af6f6986dc6611d5e2954fa5f0edd20334b2704`.

## Protected-input and semantic verification

The final scoped comparison contains 106 paths. Relative to the accepted
post-test baseline, 105 were byte-identical and the sole difference was the
authorized QMD direction change. There was no unexpected difference in a
stored preparation input, metric output, manifest, production script or
module, decision, environment identity, shared Quarto configuration, or
focused test. The comparison is stored at
`audit/preparation_reports/report017_preparation04_diagram_postrender_scoped_verification.csv`
(SHA-256 `c94c0947e326ae54fcac6318a5ae72e096cf4f63215f705328e7065a18d7a951`).

The final DOM contained 14 unique native `gt` table endpoints. This count
includes the accepted METRIC-011 table `tbl-l10-numerical-zero` and supersedes
owner order 22's earlier 13-table metadata. Every table retained its intended
caption, nonempty headers, body rows, values, order, and source-note role.
METRIC-010, METRIC-011, PREP-003, FIND-044, the current MDER counts, the
no-discrepancy qualification, the MDER caption, substantive 200-character alt
text, and paired source-data link were present. Five labeled reader-facing
main links retained their targets. No forbidden internal `.qmd`, `file://`,
`_build`, build-directory, or absolute-local rendered href appeared. The
active Preparation 04 navigation item and the H06 complementary daily-results
sidebar entry remained present. There was no raw console/tibble output,
unresolved cross-reference, or rendered error text. No individual site name
is displayed, so the country-coded site rule is not applicable on this page.

## Final-size visual QA

At 1440 by 1000 pixels:

- document client width and scroll width both equalled 1,425 CSS pixels;
- the 1,148.5-pixel main column contained every page element without clipping;
- the repaired Mermaid used an 812.0469 by 630 view box and displayed at its
  full size, leaving nominal 16 CSS pixel labels at 12 points;
- all 14 native tables fitted their containers and used minimum 11 CSS pixel,
  or 8.25-point, cell text; and
- the 1,382 by 806 MDER PNG displayed at 691 by 403 CSS pixels with readable
  axis, tick, direct-label, legend, caption, and link text.

At 708 by 1000 pixels:

- document client width and scroll width both equalled 693 CSS pixels, while
  the main column remained within its 642-pixel container;
- the Mermaid displayed at 642 by 498.07 CSS pixels with scale 0.79059,
  leaving its central node labels at approximately 9.49 points;
- all 14 native tables remained contained and readable under the author-approved
  native-table policy; Table 13's inner scroller had a 642-pixel viewport and
  a 670-pixel table, and moved through its full 28-pixel horizontal range;
- the MDER PNG displayed without distortion at 642 by 374.42 CSS pixels, with
  readable labels, legend, caption, and source-data link; and
- prose, callouts, navigation, links, long identities, and the visible
  PREP-003/FIND-044 qualification wrapped without clipping or overlap.

Two browser-harness JavaScript attempts encountered transient method-binding
errors before completing a mutation. The bounded read-only retry succeeded;
the page and output identities remained exact. Final visual metrics are stored
in `audit/preparation_reports/report017_preparation04_diagram_visual_metrics.csv`.

## Secure loopback method and teardown

One final read-only GET/HEAD server was rooted exactly at the existing
`_build/nathealth` directory and bound only to the loopback interface:

```text
python3 -u /private/tmp/report017_preparation04_loopback.py
```

- Address: `127.0.0.1:50523`
- PID: `61685`
- Start: `2026-08-13T16:10:57.102489+02:00`
- Stop: `2026-08-13T16:15:00.185274+02:00`
- Process exit status: `0`

The requested page and required assets returned HTTP 200. The optional
`/favicon.ico` request returned 404 with no page effect. The browser viewport
override was reset and the QA tab was finalized before server teardown. After
the keyboard interrupt, `lsof -nP -iTCP:50523 -sTCP:LISTEN` returned exit
status 1 with empty output, the expected no-match PASS proving that no listener
remained.

## Final build identities and bounded deltas

| Path | Bytes | SHA-256 |
|---|---:|---|
| `notebooks/preparation/04_metric_derivation.qmd` | 80,557 | `6b7239ca32ecc6e75b993115f74fa2a42781ddded98ebf9ce94f2202777086d4` |
| `_quarto-nathealth.yml` | 7,404 | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| `tests/test_preparation04_report.R` | 13,456 | `8a3caf85f230002c43c7efd46af6f6986dc6611d5e2954fa5f0edd20334b2704` |
| `_build/nathealth/notebooks/preparation/04_metric_derivation.html` | 558,230 | `9dd7797e5c3924aae5348dad0d2f1abdb3d66a281503e3500f73d0f47124479e` |
| `_build/nathealth/notebooks/preparation/04_metric_derivation_files/figure-html/fig-mder-availability-1.png` | 47,303 | `423cae8946a50bd6e611ff14708b7ff0543546f3fdc9e9fa030ca917838d75ce` |
| `_build/nathealth/search.json` | 1,563,220 | `b77998ae38456050062427344d8d56370543f103868ec792a30be828e9b32506` |
| `_build/nathealth/sitemap.xml` | 5,219 | `96094f56658d955c61a4bcb0ed24213473e914f9b89b14ff46928ff5575c1e0f` |
| `_build/nathealth/site_libs/bootstrap/bootstrap-a2a938b4dd5711f7a799c87bd16ba44c.min.css` | 498,438 | `b3d78f1077461003efc2b21acc3f81ee6ba80468fe09df310b4c339e2e19133c` |

The targeted render changed the Preparation 04 HTML, `search.json`, and
`sitemap.xml` as expected for the QMD modification. The MDER PNG and shared
Bootstrap CSS were byte-identical. Every stored scientific and preparation
artifact in the scoped gate was byte-identical. No transient mtime restoration
was required.
