# REPORT-017 Preparation 07 Mermaid repair repeat-visual stop

Date: 2026-08-14

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Target: `_build/nathealth/notebooks/preparation/07_example_days.html`

Outcome: **STOP. The authorized LR-to-TB Mermaid repair, single target
render, focused test, protected-input gate, semantic audit, desktop visual
review, and repaired diagram pass. At the required 708-pixel viewport, the
three raster figures scale their important 9 pt axis, tick, and legend text to
approximately 6.34 pt, below the 7 pt final-display floor.**

No repair was inferred or attempted for this new display defect. No second
render ran. No source other than the authorized Mermaid direction token was
edited. The focused test, profile, scientific inputs, accepted artifacts,
decisions, ledgers, lockfile, and hypothesis outputs remain unchanged. Every
hypothesis render remains held.

## Authority and accepted starting state

The controlling order was
`audit/report_harmonization/owner_orders/28_preparation07_mermaid_tb_repair.md`,
SHA-256
`e77a1ca23438ae126b10346ea8a00347a7068c72608a674f1bbc167149f9c6fa`.
All accepted starting identities matched:

| Item | SHA-256 |
|---|---|
| Preparation 07 QMD | `ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae` |
| Focused test | `958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163` |
| Nature Health profile | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| Stopped HTML | `9c05cd46796d853dad10e5f3058231946f0c1df3a4678d6272d6aa8141fe47db` |
| Owner stopped-render record | `aea0899ecfc8c5325b4015f7f2e2c6c282928f7e4b1067852a265cb3004bed13` |
| Owner 45-entry manifest | `88c1bbf4159caec07c0b60359bbd5aa241cf21dbae811c7efe6d0ec2f0066c0b` |
| Independent stop acceptance | `37d0584c98ed9f9ec28c0ff8f7a423b83222f9a3578c98e791c77a88d4647219` |
| Independent 15-entry manifest | `485f3310df55fa9a7d1d876838c94de07b5fbfee02ed071658469c69e7bb3c3c` |

Both manifests were reverified non-circularly at 45/45 and 15/15 entries.
The immediate 38-path inventory was byte-identical to the accepted order 27
post-QA inventory at SHA-256
`5b9cf24c75a593d0d7a46530904c965a92476333bd19dea619ad348538c94949`.
The build root contained 817 regular files and no symbolic links. Its
pre-repair inventory remained
`f181e470d5e7fa699c12de3b96bf96e68da63282bd5af201e8dc21bb43b4ba0b`.

## Exact bounded source repair

Only line 664 of `notebooks/preparation/07_example_days.qmd` changed:

```diff
-flowchart LR
+flowchart TB
```

The repaired source is 39,361 bytes with SHA-256
`37cfe876cf687e874d44d08761cd8f5d18a7c3ad809aa99c9ee449072eb1b9c7`.
Replacing only the new `flowchart TB` token with `flowchart LR` reconstructed
the accepted pre-edit SHA-256
`ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae`.
The comparison contained exactly one removed line and one added line.
`git diff --check` passed.

The source-only focused test then passed under R 4.6.1 without executing a
QMD chunk. It retained every forbidden builder, strict verifier, writer,
selection, model, prediction, resampling, simulation, and regeneration gate.

## Environment and single render

The normal project environment reported:

- Quarto 1.9.37 at `/usr/local/bin/quarto`;
- R 4.6.1;
- the repository root as the active project;
- the first library at
  `renv/library/macos/R-4.6/aarch64-apple-darwin23`; and
- renv 1.2.3, knitr 1.51, rmarkdown 2.31, gt 1.3.0, xml2 1.6.0,
  digest 0.6.39, dplyr 1.2.1, readr 2.2.0, scales 1.4.0, tibble 3.3.1,
  and tidyr 1.3.2.

Exactly one Quarto command ran:

```text
quarto render notebooks/preparation/07_example_days.qmd --profile nathealth
```

It used normal `.Rprofile` and `renv/activate.R` startup with the approved
narrow access to the existing user-owned R 4.6 renv cache. The command began
after the `2026-08-14T12:42:37+02:00` timestamp probe, completed all 25 knitr
stages, and exited 0. The tool-observed execution time after approval was
36.45 seconds. The output mtime is `2026-08-14T12:43:31+02:00`.
The only extra output was renv's established informational dependency-
discovery note. No package was installed or updated, and `renv.lock` remained
exact.

The new HTML is 297,095 bytes with SHA-256
`aa531fb4aef06d6ac897dfdbb9f493e83ad3d431d8e87b309cdffb31f0691401`.
The focused source/HTML test passed under R 4.6.1.

## Protected inputs and build delta

Before the render, immediately after it, and after browser QA, all 38
protected identities were exact relative to the repaired-source baseline.
The three resulting inventories are byte-identical at SHA-256
`cbc5b73492af6b0da0266baec59972fb5ffe7b98c6d6fd77a02e591852ff7b79`.
Relative to the accepted pre-repair gate, the QMD is the sole authorized
protected difference and the other 37 identities are exact.

The post-render build retained 817 regular files. The seven-row delta contains:

- content changes only to the target HTML, `search.json`, and `sitemap.xml`;
- mtime-only changes to the three generated HTML figure PNGs and the shared
  Bootstrap stylesheet; and
- no added or removed build path.

The complete delta is
`audit/preparation_reports/report017_preparation07_mermaid_postrender_build_delta.csv`,
SHA-256
`0ae4aa82d5b99b5e346736a517680edf13a5beb2ac1541fbdaf2336069299606`.
Browser QA changed neither content nor mtime in any build file. The
post-render and post-QA build inventories are byte-identical at SHA-256
`9ab3459065c543e0531d26e00d5bf5b21c0d9aea46191c4e1573a92542aff641`.

The generated figure PNG hashes remain
`ad6ee88b1df7a0b2f17d513825d74887cc009b74317ae23d43bb16a14c2d9ad8`,
`837d65b0f35f490e2c76ac4e170ebd633a349c4aff821fe82eae2be7ebb6b53d`,
and
`fd6f1cb73718674fdb6544e89bb684be0723bb33378709c399c4b161e1ec5629`.
The durable showcase PNG, SVG, and paired source-data CSV remain exact at
`a35e8189bdbdb450411bfe7f71d52964c17e45a7a26fdb44e82776d201b00ff3`,
`5ad003220cb1d5a1d2b223af206f4a1e608b4e1fa0e695d656989dde62b0ea4a`,
and
`15e12011effbdf8fdbf7835be235b7b50406838278d411df023e924e81bea1e4`.

## Semantic, native-table, figure, and link checks

The final R 4.6.1 semantic harness passed 24/24 checks. It confirmed:

- exactly seven native `gt` endpoints, each with one Quarto caption,
  nonempty headers and rows, and one intended source note;
- three figure endpoints with complete images, substantive alt text,
  nonempty captions, and existing source files;
- the paired source-data link and the approved historical/current provenance
  explanation and identities;
- all nine country-coded site names in submitted order;
- active Preparation 07 navigation and both H06_daily entries;
- released reader links and fragments, while isolating the known unreleased
  `supplementary_information.html` shared navigation target; and
- no rendered errors, warnings, unresolved references, raw console output,
  internal workflow codes, QMD links, `file://` links, `_build` links, or
  absolute local reader links.

The semantic, table, and link evidence retain SHA-256 identities
`5cd0ce50defa82768af8de6da9f58fc5b23e3b8cab24136e6caec4e7f834238c`,
`4a00379bfb704c048fd5aa512d837a4f7e576af5aa8d50b57a44305965087a50`,
and
`1701fb57752200117ae9f2a9f28287738a762cbc3342c4e0058efb3859e87adf`.
Browser warning/error logs were empty.

## Desktop visual QA

At 1,440 by 1,000 pixels, the desktop visual result is PASS:

- document client width and scroll width were both 1,425 pixels;
- the main column was 1,148.5 pixels wide;
- the repaired TB Mermaid displayed at 836.40 by 605.99 pixels from an
  836.40 by 606 view box;
- all eight important Mermaid labels retained at least 12.00 pt, with zero
  clipped labels and zero label overlaps;
- all seven native tables fitted their containers and retained a minimum
  8.25 pt cell font; and
- all three figures displayed at 1,148.5 pixels wide with readable axes,
  site and participant labels, traces, points, state bands, daylight context,
  legends, captions, and units.

The TB layout has no harmful vertical expansion at desktop. Every node, edge,
label, caption, and downstream section remained intact. All seven tables and
all three figures were visually inspected before moving to the narrow view.

## Narrow visual QA and new stop condition

At 708 by 1,000 pixels, the repaired Mermaid and page layout pass:

- document client width and scroll width were both 693 pixels, with no
  page-level horizontal overflow;
- the main column and callout remained within 642 pixels;
- the TB Mermaid displayed at 642 by 465.15 pixels;
- all eight Mermaid labels retained at least 9.21 pt, with zero clipping and
  zero overlap; and
- all seven native tables measured 642 pixels wide with a minimum 8.25 pt
  font and no page-level overflow. Tables 1 and 2 were visually inspected
  before the later figure gate stopped the review.

The raster figures expose a new typography defect. Each plot is defined at a
9.5-inch figure width and displayed at 642 CSS pixels. The source specifies
9 pt axis and legend text, 9.5 pt strip and legend-title text, and 10 pt axis
titles. At the actual narrow display width, the effective sizes are:

| Text role | Source size | Effective narrow size | Result |
|---|---:|---:|---|
| Axis ticks and legend labels | 9 pt | 6.336 pt | FAIL |
| Facet strips and legend title | 9.5 pt | 6.688 pt | FAIL |
| Axis titles | 10 pt | 7.039 pt | PASS |

The display calculation is
`source points × 642 / (9.5 × 96 CSS pixels per inch)`. The small axis,
tick, strip, and legend text is visible in
`report017_preparation07_mermaid_narrow_figures_1_2.png`. It falls below the
standing 7 pt final-display floor and carries information needed to interpret
the panels. This is a display-only defect, not evidence of a changed source
value, fixed selection, figure trace, state assignment, daylight context, or
scientific result.

Order 28 requires an immediate stop on any new defect and does not authorize
another source edit or render. The narrow review therefore ended at this
figure gate. No repair was attempted. The exact measurements are in
`audit/preparation_reports/report017_preparation07_mermaid_repeat_visual_metrics.csv`,
SHA-256
`7515390ca2d05bc9190ecdaaff7debbce9d97d7bc483befa499a522cbc33ba40`.

## Secure loopback lifecycle and teardown

The sole loopback command was:

```text
python3 -u -m http.server 0 --bind 127.0.0.1 --directory _build/nathealth
```

- document root:
  `/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/_build/nathealth`;
- address: `127.0.0.1:52814`;
- PID: `13992`;
- process start: `2026-08-14T12:45:47+02:00`;
- listener confirmation: `2026-08-14T12:45:55+02:00`;
- target URL:
  `http://127.0.0.1:52814/notebooks/preparation/07_example_days.html`;
- first page GET: `2026-08-14T12:46:53+02:00`;
- stop confirmation: `2026-08-14T12:54:25+02:00`; and
- server exit status: 0.

Every required page and asset request returned HTTP 200; only the optional
favicon returned 404. The browser viewport override was reset and the browser
session finalized before teardown. The browser-finalization instant was not
separately captured and is not reconstructed. After the server exited,
`lsof -nP -iTCP:52814 -sTCP:LISTEN` returned exit status 1 with empty output,
the expected no-match result proving that no listener remained. The lifecycle
CSV is
`audit/preparation_reports/report017_preparation07_mermaid_loopback_lifecycle.csv`,
SHA-256
`1d458aa30d002bd1685745874e55bc1f923ce2ebffff64d5a5e8459399dbfcc0`.

## Disposition

The requested Mermaid repair is successful and fully preserved. Preparation
07 nevertheless remains stopped at the newly exposed narrow raster-figure
typography boundary. The existing HTML, QMD repair, screenshots, inventories,
and audit evidence are preserved for coordinator disposition. No scientific
or hypothesis computation was run, and every hypothesis render remains held.
