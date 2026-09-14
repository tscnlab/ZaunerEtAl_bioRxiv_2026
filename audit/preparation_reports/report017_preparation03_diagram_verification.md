# REPORT-017 Preparation 03 diagram-repair verification

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/03_reference_profiles.qmd`  
Outcome: **PASS. The authorized top-to-bottom Mermaid layout resolves the narrow-label failure, and the rerendered page passes desktop and 708-pixel QA.**

Preparation 04 was not started. No scientific input, stored artifact,
decision file, configuration file, production code, metric value, table
value, or empirical figure value changed.

## Preserved failed-visual evidence

Before the source repair, the failed narrow-visual result was sealed in:

- `report017_preparation03_failed_visual_verification.md`, SHA-256
  `dfc23beb4919ebdde02a2e83feb18857a775cdb9b0b457605f5f8c907251285e`;
- `report017_preparation03_failed_visual_manifest.csv`, SHA-256
  `753fd94892287c36a6163c553a531c20e81f8c67b90ccd16da62ab38f8b70e15`.

Every manifest entry matched by byte size and SHA-256. The prior browser
viewport had been reset, zero QA tabs remained, and no listener remained on
the prior loopback port 63198 before the repair began.

## Exact source repair

The only source change was:

```diff
-flowchart LR
+flowchart TB
```

The source SHA-256 changed from
`a0d9bc85a906b6c83edd8019421b012220c11e2d72988724fd9d1439fbc57a3a`
to
`4ec7a6880591157eefe969e85d7b2adf7c22690fafaf434f715af944a7906504`.
Reverse substitution of `LR` for `TB` reproduced the pre-repair hash exactly.
The figure identifier, all node and edge definitions, captions, alt text,
prose, links, table code, R chunks, values, and scientific qualifications
were unchanged. `git diff --check` passed.

The refreshed 39-path baseline is
`report017_preparation03_diagram_prerender_scoped_readset.csv`, SHA-256
`476225482c6ea69ccace91f163a52ea67467a03a8ef4ac6548c368f11ce789d4`.
Relative to the preceding baseline, the authorized QMD was the only changed
path; all other 38 paths matched exactly.

## Single targeted render

The environment was Quarto 1.9.37 and R 4.6.1. The normal project startup
loaded the existing project `renv` library and user-owned sandbox cache. No
package was installed or updated, and `renv.lock` was not edited.

Exactly one Quarto command was run:

```text
quarto render notebooks/preparation/03_reference_profiles.qmd --profile nathealth
```

It completed with exit status 0 in approximately 38.96 seconds. The log shows
all 29 document stages, including the one Mermaid overview, 11 native `gt`
tables, and the stored pooled-profile figure.

The focused command

```text
/usr/local/bin/Rscript tests/test_preparation03_report.R _build/nathealth/notebooks/preparation/03_reference_profiles.html
```

passed under R 4.6.1 with the bounded-render, version-specific verification,
`gt` table, figure, and provenance contract intact. The focused test retained
the accepted scientific MDER checks, decision-file existence and exact hash,
PREP-002, FIND-043, and the preceding/current manifest qualifications.

## Protected-input and build checks

The postrender and final loopback comparisons each passed all 39 scoped paths
by byte size and SHA-256. Final evidence is stored in
`report017_preparation03_diagram_final_scoped_verification.csv`, SHA-256
`473c4440e43a3897d2e24d8c5f37ade38146073ce56ca81ba5325a5a31d2efa0`.

The bounded build delta contained only:

- the target HTML;
- the target page's pooled-profile SVG mtime, with byte content and SHA-256
  unchanged;
- `search.json`; and
- `sitemap.xml`.

Quarto also touched the mtime of the shared Bootstrap CSS without changing
its 498,438 bytes or SHA-256
`b3d78f1077461003efc2b21acc3f81ee6ba80468fe09df310b4c339e2e19133c`.
Its pre-render mtime `1786619001` was restored exactly.

## Semantic HTML result

The rerendered HTML contains:

- the accepted page title and information hierarchy;
- one complete render-boundary callout;
- the repaired Mermaid overview with its accepted identifier, caption, and
  alt text;
- exactly 11 native `table.gt_table` objects, 11 nonempty captions, and 11
  source-note sections;
- the stored pooled melEDI/illuminance figure with substantive alt text,
  caption, and paired `reference_profiles.csv` link;
- the complete version-specific verification callout, including 394 of 394
  only for the preceding manifest and FIND-043 open for the current manifest;
  and
- the active `03 Reference profiles` sidebar entry.

No raw tibble/console block, rendered R error, empty accessible main-content
link, internal `.qmd`, `file://`, `_build`, build-directory, or absolute-local
href was present. All current-page fragments resolved. Linked Preparation 03
inputs, source data, manifest, PREP-002 decision, and the Preparation 02 and
Preparation 04 pager files existed in the partial build.

The global sidebar retains the previously recorded
`supplementary_information.html` target that is absent from this partial build
because this order prohibited rendering that page or the full project. It is
not a Preparation 03 content defect. Preparation 03 displays site counts but
not individual site names, so country-coded site-label QA was not applicable.

## Durable table-QA policy

The clarification in
`audit/report_harmonization/phase4_table_visual_qa_policy.md`, SHA-256
`589efda97afe0b5d23f0a490dd446b051326ec8f3f7d7cad6d3363b51b4197c2`,
was read completely and applied.

The 11 tables are native HTML. Their controlling visual inspection was at a
typical 1440 by 1000 desktop/laptop viewport. At 708 pixels, the check covered
page integrity and contained horizontal-overflow behavior rather than
requiring dense tables to remain fully readable without scrolling.

## Desktop visual QA at 1440 by 1000 pixels

Desktop passed:

- the document client width and scroll width both equalled 1,425 CSS pixels;
- no main-content object crossed the viewport boundary;
- every table fitted its 1,148.5-pixel container, retained readable minimum
  11 CSS pixel text, equivalent to 8.25 points, and showed intact captions,
  headers, rows, and notes;
- the pooled empirical SVG displayed at its natural 729 by 517 CSS pixels
  with readable axes, ticks, facets, legend, caption, and source-data link;
- both callouts and the final provenance qualification were intact; and
- the repaired Mermaid used a 541.1094 by 782-unit view box and displayed at
  its natural size. Its nominal and effective label size was 16 CSS pixels,
  equivalent to 12 points, with no clipping or overlap.

## Narrow visual QA at 708 by 1000 pixels

Narrow inspection passed:

- document client width and scroll width both equalled 693 CSS pixels, with
  no page-level horizontal overflow or clipped main-content object;
- all 11 native HTML tables remained within 642-pixel wrappers whose computed
  `overflow-x` value was `auto`; none currently required scrolling, but the
  contained overflow affordance was present;
- table captions, headers, rows, notes, and adjacent page content remained
  intact;
- the repaired Mermaid remained at its natural 541.1094-pixel width, with
  effective 16 CSS pixel or 12-point labels and no clipping, overlap, or
  compressed text;
- the empirical figure displayed at 642 by 455.4 CSS pixels, leaving its
  9-point axis and legend text at about 7.93 points and its 10-point facet text
  at about 8.81 points;
- prose, long hashes, both callouts, captions, and links wrapped cleanly; and
- the navigation drawer opened, displayed the active Preparation 03 entry,
  and closed normally.

## Loopback teardown and final outputs

One read-only server was rooted exactly at `_build/nathealth` and bound only
to `127.0.0.1:63548`. Requested page assets returned HTTP 200 or 304; only the
browser's optional favicon request returned 404 without visible effect. The
viewport override was reset, the QA tab was finalized, the server exited with
status 0, and a listener check confirmed that port 63548 was closed.

The execution interface assigned unified terminal session ID `47334`. This is
not an operating-system process identifier. The exact server PID was not
recorded in the available execution evidence and is therefore reported as
unavailable rather than reconstructed.

The exact server start and stop timestamps were also not recorded by the
execution interface. The first captured HTTP request was timestamped
`2026-08-13 14:49:44` local time, which establishes only that the server was
running by then. The last captured HTTP request was timestamped
`2026-08-13 14:53:12` local time, after which the recorded keyboard interrupt
returned exit status 0. These request times are bounds from the log, not
substitutes for the missing start and stop timestamps.

Source, configuration, focused test, HTML, empirical SVG, scientific
manifest, search index, and sitemap hashes and mtimes were identical before
and after loopback QA.

| Output | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/preparation/03_reference_profiles.qmd` | `4ec7a6880591157eefe969e85d7b2adf7c22690fafaf434f715af944a7906504` | 43,231 |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` | 7,404 |
| `tests/test_preparation03_report.R` | `1a506a9c486ce9891799148b4c361ee6d6c3633abe77c5c33fccff325f60a5d2` | 9,245 |
| `_build/nathealth/notebooks/preparation/03_reference_profiles.html` | `43d8260933342e9cc511fed115672e5fd1065b76a6a5c6fcf136964f2735f77d` | 358,781 |
| `_build/nathealth/notebooks/preparation/03_reference_profiles_files/figure-html/fig-pooled-reference-profiles-1.svg` | `b011c1ac17cc1cb05bfda58170371fa8c49813b277e0455f65373a60447a9923` | 147,638 |
| `_build/nathealth/search.json` | `f6b67129bf35d085d521464da96ee8e3dd607ee758b4f587065fb37b6efa5277` | 1,547,072 |
| `_build/nathealth/sitemap.xml` | `33e9b9a456227759d7ca700458c6c57f56a4a4c6c85e3ff86a44bd90dae5fd04` | 5,219 |

Preparation 03 is ready for independent acceptance. Preparation 04 remains
held until that acceptance is issued.
