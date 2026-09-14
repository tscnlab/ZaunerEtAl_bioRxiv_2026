# REPORT-017 Preparation 06 diagram-repair verification

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `_build/nathealth/notebooks/preparation/06_model_ready_datasets.html`  
Outcome: **PASS**

Preparation 06 passed its authorized display-only repair, one fresh bounded
target render, focused R test, semantic HTML audit, 168-path preservation
gate, and desktop and narrow visual QA. Preparation 07 was not started.

## Authorized repair

The prior narrow-viewport failure record was sealed before this repair:

- `audit/preparation_reports/report017_preparation06_failed_visual_verification.md`,
  SHA-256
  `3bde98d63d6652c14e7aca0b73c4b1515d429df8c44dfb7e1c292d916eff59ec`;
- `audit/preparation_reports/report017_preparation06_failed_visual_manifest.csv`,
  SHA-256
  `38b7e165fd1714ee63d5dce19da0de2be022d01e92878fcea466a0743ecbd144`;
  and
- the earlier loopback server on port 55326 had no listener.

Exactly one source line changed at
`notebooks/preparation/06_model_ready_datasets.qmd:1576`:

```diff
-flowchart LR
+flowchart TB
```

No diagram node, edge, label, identifier, caption, alt text, prose, R chunk,
table, figure, path, stored value, or scientific claim changed. In-memory
reverse substitution reproduced the released pre-repair source SHA-256
`2067db45d46b49bec34985f68eb9e10d5e35377548c5103218321261d50f4c5b`
exactly. The repaired source is 87,267 bytes with SHA-256
`23b201c404f3b30918d49459ce54a3155a26b758ff10872bc0be4264bd386f87`.
`git diff --check` passed.

## Bounded execution and render

Static inspection confirmed that the page contains no executable call to a
preparation builder, production scientific verifier, model, prediction,
resampling procedure, network function, or data writer. The refreshed
pre-render gate checked 168 paths: 166 were byte-identical, one was the
authorized diagram-only source change, and one was the previously authorized
focused-test-only change. There was no unexpected mismatch.

Exactly one fresh Quarto command ran after the display repair:

```text
quarto render notebooks/preparation/06_model_ready_datasets.qmd --profile nathealth
```

It used Quarto 1.9.37, R 4.6.1, the normal project `.Rprofile` and
`renv/activate.R`, and the project library
`renv/library/macos/R-4.6/aarch64-apple-darwin23`. The existing narrow
permission allowed transient lock access to the user-owned R 4.6 renv cache.
No package was installed or updated, `renv.lock` was unchanged, and no second
target or full-project render ran. The command started at
`2026-08-13T17:55:00+0200`, ended at `2026-08-13T17:55:54+0200`, took 53.94
seconds, completed all 45 knitr stages, and exited 0.

The focused command `Rscript tests/test_preparation06_report.R` used the same
normal R 4.6.1 startup. It ran from `2026-08-13T17:57:02+0200` through
`2026-08-13T17:57:18+0200`, took 16.52 seconds, exited 0, and reported:

```text
PASS: Preparation 06 source satisfies the bounded-render, terminology, gt-table, figure, and provenance contract.
```

The current focused test is 17,136 bytes with SHA-256
`03017c71915194335422f538f72750b914855310f5045d893b71a346961112ec`.
Its four bounded recoveries replaced stale reader-facing literals only. No
scientific, source, HTML, configuration, or artifact requirement was relaxed.

Two initial read-only manifest-validation one-liners exited before validation
because their Ruby audit harness omitted a closing array bracket. Each
reported `syntax error, unexpected ';', expecting ']'`. They did not execute
R, render a page, inspect scientific values, or modify any project file. The
corrected validator subsequently checked all 60 non-circular manifest rows
and returned zero missing paths, size mismatches, or SHA-256 mismatches. This
was an audit-harness construction error, not source, build, or scientific
drift.

## Semantic HTML and links

The R 4.6.1 semantic audit passed. The rendered DOM contains 19 unique native
`gt` table endpoints. Each has one native table, a nonempty Quarto caption,
nonempty column labels, body rows, and its intended source note. The page
retains its title, purpose, information hierarchy, render-boundary callout,
active MDER and numerical-zero rules, exact samples and counts, country-coded
sites, Preparation 03 and 04 qualifications, and absence of raw console or
tibble output.

`fig-site-composition` retains a substantive caption and alt text. Its PNG is
2,160 by 1,958 pixels, 224,765 bytes, and SHA-256
`058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da`.
The paired source-data CSV remains 21,916 bytes with SHA-256
`809d109d3647ef4ac1798ef9eb59c06e2c7db41f5b9ce1dade4d0a8b583f0a22`.

The dynamic `DEV-056` link resolves to
`notebooks/preregistration_deviations.html#dev-056`; the target page exists,
contains one visible `dev-056` anchor, and loaded successfully through the
loopback server. All other reader links and current-page fragments resolve.
Preparation 06 is the active navigation item, and H06_daily appears in its
accepted position. No internal `.qmd`, `file://`, `_build`, build-directory,
or absolute-local rendered href appears. The browser console contained no
warnings or errors.

## Final-size visual QA

The author-approved native-table policy was applied. Native HTML tables must
be readable at a typical desktop or laptop viewport. At 708 pixels the page
must remain intact and any needed contained horizontal scrolling must work.
The figure PNG was also inspected at its intended final size.

At 1,440 by 1,000 pixels:

- document client width and scroll width both equalled 1,425 CSS pixels;
- the repaired top-to-bottom Mermaid displayed at 716.055 by 781.992 pixels
  from its 716.055 by 782 view box;
- its nominal 16-pixel labels therefore remained approximately 12.0 points,
  all labels remained inside the SVG, and there was no clipping, overlap,
  distortion, or harmful whitespace expansion;
- all 19 native tables fit their 1,149-pixel containers and used at least 11
  CSS pixels, or 8.25 points, for cell text; and
- the figure displayed at 1,148.5 by 1,041.094 pixels with readable site,
  facet, count, and axis text, distinguishable bars, and no clipping.

At 708 by 1,000 pixels:

- document client width and scroll width both equalled 693 CSS pixels, so
  there was no page-level horizontal overflow;
- the Mermaid displayed at 642 by 701.125 pixels, scale 0.896579, leaving
  effective labels at approximately 10.759 points;
- all 15 nonempty rendered labels remained inside the SVG, and the diagram
  showed no clipping, overlap, distorted text, awkward wrapping, or harmful
  expansion;
- all 19 native tables retained at least 8.25-point cell text. Sixteen fit
  their 642-pixel containers. Three used contained `overflow-x: auto` with
  working scroll ranges of 119, 21, and 25 pixels; each scroller reached its
  right endpoint and reset to zero; and
- the figure displayed at 642 by 581.961 pixels, with readable text, balanced
  panels, intact caption and source-data link, and no clipping.

The exact measurements are stored in
`audit/preparation_reports/report017_preparation06_repaired_visual_metrics.csv`.
Representative desktop and narrow screenshots are stored under
`audit/preparation_reports/report017_preparation06_repaired_*.png` and pinned
in the non-circular manifest.

## Secure loopback lifecycle

The build root contained no symbolic links. One temporary read-only server
was rooted exactly at `_build/nathealth` and bound only to loopback:

```text
python3 -u -m http.server 0 --bind 127.0.0.1 --directory _build/nathealth
```

- address: `127.0.0.1:55856`;
- operating-system PID: `84144`;
- start: `2026-08-13T17:58:14+0200`;
- target URL:
  `http://127.0.0.1:55856/notebooks/preparation/06_model_ready_datasets.html`;
- stop: `2026-08-13T18:05:57+0200`;
- process exit status: 0.

Only GET requests occurred. Required page assets and the DEV-056 target
returned HTTP 200 or cache 304. The optional favicon returned 404 without page
effect. The viewport override was reset and the QA tab was finalized before
teardown. After keyboard interrupt, PID 84144 was absent and
`lsof -nP -iTCP:55856 -sTCP:LISTEN` returned the expected no-match result,
proving no listener remained.

Browser finalization exposed exactly two newly observed Finder-style paths
with a ` 2` suffix: one byte-identical copy of the pre-repair HTML and one
byte-identical Bootstrap CSS copy. The sealed 829-file pre-QA inventory at
SHA-256
`0132c31e5423fc8c43e87d1eb6daea884711e9ed0676a5b793f017f679199590`
contained zero rows for each path. The immediate pre-cleanup post-QA
inventory contained 831 files at SHA-256
`06b7dbe07a39bb3eec8f644349a59ca51026cb59035d23db9b2db5992f00e9e7`;
comparison against the sealed pre-QA inventory identified only these two new
paths.

Only those two paths were moved intact to the recoverable temporary directory
`/private/tmp/report017_p06_browser_extras.m6VHKJ/`. Exact original paths,
byte counts, SHA-256 values, mtimes, recovery paths, and zero-row pre-QA
evidence are recorded in
`audit/preparation_reports/report017_preparation06_browser_duplicate_recovery.csv`.
The two recovery copies retain their original bytes, hashes, and mtimes and
will remain recoverable until independent acceptance. No other `* 2*` path
was moved or modified. The historical `descriptives 2.html`, H03/H04/H06/H08/
H09/H10/H11 duplicate directories, and the existing Preparation 06
`figure-html 2` directory remain in place. After this exact two-path cleanup,
the 829-file post-QA build inventory is byte-identical to the post-render
inventory at SHA-256
`0132c31e5423fc8c43e87d1eb6daea884711e9ed0676a5b793f017f679199590`.

## Protected inputs and final identities

All 168 scoped paths were checked immediately before rendering, immediately
after rendering, and after visual QA. Each comparison contains 166 unchanged
paths, the one authorized diagram-only QMD change, and the one authorized
focused-test-only change. There is no unexpected mismatch. The final
comparison is
`audit/preparation_reports/report017_preparation06_diagram_postqa_scoped_verification.csv`,
SHA-256
`8df744af1a75c078ee9d89714c627fede4e29559397a2939e12c0581e45d87c7`.

Final identities are:

| Path | Bytes | SHA-256 |
|---|---:|---|
| `notebooks/preparation/06_model_ready_datasets.qmd` | 87,267 | `23b201c404f3b30918d49459ce54a3155a26b758ff10872bc0be4264bd386f87` |
| `_quarto-nathealth.yml` | 7,404 | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| `tests/test_preparation06_report.R` | 17,136 | `03017c71915194335422f538f72750b914855310f5045d893b71a346961112ec` |
| `_build/nathealth/notebooks/preparation/06_model_ready_datasets.html` | 665,739 | `7306d9d51e9a20da1e09ffd8a3147f7bdf1f8b6b3b1c80e0e23455ad43d96565` |
| site-composition PNG | 224,765 | `058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da` |
| paired `categorical_levels.csv` | 21,916 | `809d109d3647ef4ac1798ef9eb59c06e2c7db41f5b9ce1dade4d0a8b583f0a22` |
| `_build/nathealth/search.json` | 1,590,077 | `a822a6a45c1e9759eed5bf2b414d541d47a2bb3edc63b3de433d0ee2c7480d97` |
| `_build/nathealth/sitemap.xml` | 5,219 | `484ac30b72f1f3860c0ac86395d28c83999a7ec861d31a5c6b58920ef4658355` |

The target render changed only the Preparation 06 HTML, `search.json`, and
`sitemap.xml` content. The site-composition PNG and Bootstrap CSS received
mtime touches only and remained byte-identical. No preparation input,
scientific artifact, model result, script, decision, shared configuration, or
other report source changed. No scientific computation or H01-H11 execution
ran. Preparation 07 remains held.
