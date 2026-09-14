# REPORT-017 Preparation 02 repeat visual verification

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Order: Preparation 02 reader-only reference repair and repeat render  
Branch: `rewrite/NH`

## Disposition

The three authorized reader-only cross-reference repairs succeeded. The fresh
targeted render, focused R test, scoped protected-input gate, semantic HTML
audit, link audit, desktop visual inspection, and all narrow table and
navigation checks passed. Overall visual acceptance remains held because the
opening horizontal Mermaid overview is unreadable at the required 708 by 1000
review viewport.

At 708 CSS pixels, the SVG is scaled from a `0 0 1691.2734375 222` view box to
642 by 84.27 CSS pixels. A one-line node label measures 9.1098 CSS pixels in
displayed height, equivalent to approximately 6.83 points at the standard
96-CSS-pixel-per-inch conversion. This is below the normal 7-point minimum in
REPORT-011 and was visibly too small at final display size. No node, edge,
label, figure metadata, configuration, or scientific content was changed
during this repeat-render order.

The stop-on-display-defect rule was applied. Preparation 03 was not rendered or
otherwise started. The coordinator subsequently authorized a separate exact
source repair, `flowchart LR` to `flowchart TB`, but that repair was not made
until this failed repeat-visual record and its manifest were sealed.

## Authorized source repair completed before this render

The source began at accepted SHA-256
`1bc72ab367443ef48727c7069ad9f58d950b00264e7ea78b5a72d05b4a979c50`.
Only the redundant manual `Table` prefixes immediately before these three
Quarto references were removed:

```diff
-illuminance value. Table @tbl-preparation02-rules separates
+illuminance value. @tbl-preparation02-rules separates

-Table @tbl-preparation02-site-days shows
+@tbl-preparation02-site-days shows

-The full sample-flow file reports each step both overall and by site. Table
+The full sample-flow file reports each step both overall and by site.
 @tbl-preparation02-sample-flow shows
```

The repaired source SHA-256 was
`b65673d2ecfd8913a6e9c8ba06d7c1b98bca3665769864bb7f7e68be78a8f3ef`.
Reverse substitution of only those three changes reproduced the accepted
pre-repair SHA-256 exactly. `git diff --check` passed. All three reference
targets, all R chunks and chunk labels, all prepared objects, and all
scientific prose, numbers, paths, and claims were otherwise preserved.

## Bounded render and runtime

Static inspection of the complete QMD and its 12 R chunks again found no
preparation builder, production verifier, model, prediction, resampling,
simulation, bootstrap, Shapley, download, or artifact-writing call. The empty
`rg` result with exit status 1 was the expected no-match pass.

The sole Quarto command was:

```text
quarto render notebooks/preparation/02_coverage_sample_flow.qmd --profile nathealth
```

It ran once after the reader-only repair, exited with status 0, and took
38.241 seconds. Quarto was 1.9.37 and R was 4.6.1. Normal project startup was
retained: the repository `.Rprofile` activated renv 1.2.3, and the project
library was `renv/library/macos/R-4.6/aarch64-apple-darwin23`. No package was
installed or updated and `renv.lock` was not edited.

| Input | Final SHA-256 |
|---|---|
| `notebooks/preparation/02_coverage_sample_flow.qmd` | `b65673d2ecfd8913a6e9c8ba06d7c1b98bca3665769864bb7f7e68be78a8f3ef` |
| `_quarto-nathealth.yml` | `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5` |
| `tests/test_preparation02_report.R` | `1a6fd5fb83fdefa7e7862c055fee71b6d6b9508a59b0a434b20936b51cea52c3` |
| accepted handoff | `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640` |

## Rendered outputs

| Output | SHA-256 | Bytes |
|---|---|---:|
| `_build/nathealth/notebooks/preparation/02_coverage_sample_flow.html` | `badeb5f5c1c02436cbb33200841921d2e2010bf413b3074b93b666f996dd07a6` | 313,890 |
| `_build/nathealth/search.json` | `c044834c4d756ce163f09fb867326c1f3958f8a4c5a29cfd3cc2567873021e32` | 1,535,458 |
| `_build/nathealth/sitemap.xml` | `067a1de50590667ffa6efa462817c90b71d33a30608bc9bfdb0ecc51eb1459ab` | 5,219 |

Compared with the preceding failed-visual render, exactly those three rendered
files changed. No rendered file was added or deleted and no metadata-only
difference remained. The build contained 827 files and no symlink.

## Focused test and protected-input gate

Command:

```text
/usr/local/bin/Rscript tests/test_preparation02_report.R _build/nathealth/notebooks/preparation/02_coverage_sample_flow.html
```

The test ran with normal project startup under R 4.6.1, exited with status 0 in
16.222 seconds, and reported:

```text
PASS: Preparation 02 source satisfies the bounded-render, terminology, gt-table, and provenance contract.
```

The repaired scoped read set contained 32 paths. The immediate pre-render,
post-render, and post-loopback comparisons each found 32 unchanged paths and
zero mismatches.

| Record | SHA-256 | Rows |
|---|---|---:|
| `audit/preparation_reports/report017_preparation02_repair_prerender_scoped_readset.csv` | `1d57c848257242e22c27b1461d0a39855ae2df344c62bed0717fa0795277b3bd` | 32 |
| `audit/preparation_reports/report017_preparation02_repair_postrender_scoped_verification.csv` | `43cf3a5b185475410640ff53fe23f669928b36344497839701f87b34939c88b2` | 32 |
| `audit/preparation_reports/report017_preparation02_repair_final_scoped_verification.csv` | `43cf3a5b185475410640ff53fe23f669928b36344497839701f87b34939c88b2` | 32 |

Every stored scientific or preparation input in the page read set remained
unchanged. This is a scoped assertion, not a claim that the shared checkout
was globally static.

## Semantic HTML, table, and link audit

The repaired HTML contained the exact title, the accepted 10 second-level
headings, one render-boundary callout, the Mermaid overview and caption, and
exactly 11 native `table.gt_table` elements. The tables retained the accepted
header, row, caption, and source-note structure:

| Table | Headers | Body rows | Source notes |
|---|---:|---:|---:|
| Coverage rules | 3 | 6 | 0 |
| Overall coverage | 3 | 13 | 0 |
| Site coverage | 8 | 17 | 0 |
| Daily distribution | 3 | 5 | 0 |
| Missing or unusable periods | 7 | 10 | 1 |
| Sample flow | 6 | 20 | 0 |
| Validation | 3 | 6 | 0 |
| Manifest identity | 5 | 1 | 1 |
| Producing scripts | 2 | 4 | 0 |
| Artifacts passed forward | 3 | 7 | 0 |
| Render environment | 2 | 5 | 0 |

All nine country-coded sites and every accepted threshold, count, unit, and
sample-flow value were present. Raw tibble, console, error, and internal
production output was absent. No `Table Table` label remained.

The eight unique main-content and page-navigation links all resolved. DEV-055
occurred once as visible text `DEV-055`, resolved to
`notebooks/preregistration_deviations.html#dev-055`, and had a 58.5 by 21 CSS
pixel displayed box at the narrow viewport. No internal `.qmd`, `file://`,
`_build`, build-directory, or absolute-local href appeared. The active sidebar
entry was `02 Coverage and sample flow`. As in the preceding sealed record, the
global sidebar's supplementary-information target is absent from the current
partial build because this order prohibited rendering that target.

## Secure loopback visual QA and teardown

The temporary server command was:

```text
python3 -m http.server 0 --bind 127.0.0.1 --directory /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/_build/nathealth
```

It was rooted exactly at `_build/nathealth`, bound only to `127.0.0.1`, used
port 61450 and PID 35525, and ran from `2026-08-13T11:07:24Z` to
`2026-08-13T11:13:16Z`. The exact review URL was
`http://127.0.0.1:61450/notebooks/preparation/02_coverage_sample_flow.html`.
After browser cleanup the server was interrupted. `lsof` returned exit status
1 with empty output for port 61450, and `kill -0 35525` returned exit status 1
with `no such process`. These are the expected no-listener and no-process
results. The 827-file build inventory was byte-for-byte and mtime-for-mtime
unchanged across loopback QA.

At 1440 by 1000, the full page passed visual inspection. All 11 tables used
13 px type, had no horizontal overflow, and were readable without clipping,
overlap, distorted text, awkward wrapping, or poor legend-to-content balance.
The prose, captions, render-boundary callout, navigation, links, and repaired
single `Table 1`, `Table 3`, and `Table 6` references passed. The Mermaid
overview occupied 1,148.5 by 150.8 CSS pixels and was readable.

At 708 by 1000, the page had a 693-pixel document client width and exactly the
same scroll width, so there was no page-level horizontal overflow. All 11 table
wrappers were 642 pixels wide, each table remained 642 pixels wide, and cell
type remained 13 px. Every table, the callout, captions, country-coded sites,
DEV-055 link, page-navigation links, and the opened mobile navigation passed
visual inspection. The sole failure was the horizontally compressed Mermaid
overview described in the disposition.

## Ownership and scientific-change evidence

The only source changes preceding this repeat render were the three explicitly
authorized manual-prefix removals. No R chunk, prepared table object, row,
header, source note, stored value, denominator, unit, key, site order, artifact
path, scientific qualification, script, test, configuration, decision, ledger,
bibliography, lockfile, manuscript file, or hypothesis output changed. The
render did not run a preparation builder or any downstream scientific
computation. Preparation 03 remained held.
