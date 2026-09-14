# REPORT-017 Preparation 02 diagram repair verification

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Order: Preparation 02 diagram repair and final targeted render  
Branch: `rewrite/NH`

## Disposition

PASS. The coordinator-authorized reader-only Mermaid repair resolved the sole
remaining Preparation 02 display defect. The repaired page passed its bounded
render, focused R test, scoped protected-input gate, semantic HTML and link
audits, and complete desktop and 708-pixel secure-loopback inspection.

Preparation 03 remained held and was not rendered or otherwise started. No
scientific builder, production verifier, model, prediction, resampling,
simulation, bootstrap, Shapley calculation, or downstream hypothesis
computation ran.

The preceding repeat-visual failure was sealed before this repair in:

- `audit/preparation_reports/report017_preparation02_repeat_visual_verification.md`,
  SHA-256 `5b610ffb983227086f296654ed2c680591b2603faa2bbee870933c873856afd6`;
- `audit/preparation_reports/report017_preparation02_repeat_visual_manifest.csv`,
  SHA-256 `e0aacb13563da72e9e8025aedf9d303b43c339fb3d6da7b32eba528d1c23e338`.

## Exact source repair

The immediate pre-edit source identity was
`b65673d2ecfd8913a6e9c8ba06d7c1b98bca3665769864bb7f7e68be78a8f3ef`.
Exactly one source line changed at line 496:

```diff
-flowchart LR
+flowchart TB
```

The post-edit and final source identity is
`572173e119c9e8faac93fd61687d3a209d470742dbd82efe44a12ac87e6275fd`.
Replacing only `flowchart TB` with `flowchart LR` in the final source reproduced
the immediate pre-edit SHA-256 exactly. The three previously approved Table 1,
Table 3, and Table 6 reference repairs remained intact.

Every Mermaid node, edge, label, figure identifier, caption, alt text,
surrounding paragraph, R chunk, chunk label, prepared object, table endpoint,
stored number, scientific claim, artifact path, and configuration identity was
otherwise preserved. `git diff --check` passed.

## Bounded execution and runtime

Static inspection found the accepted 12 R chunks. A search confined to their
executable code found no preparation builder, production verifier, source or
system execution, data write, model, prediction, resampling, simulation,
bootstrap, or Shapley call. The search returned exit status 1 with empty
output, the expected no-match pass.

The only Quarto command after the diagram repair was:

```text
quarto render notebooks/preparation/02_coverage_sample_flow.qmd --profile nathealth
```

It ran once, processed all 27 knitr steps, exited with status 0, and took
43.12 seconds. Quarto was 1.9.37 and R was 4.6.1. The repository `.Rprofile`
activated renv 1.2.3 and the existing project library at
`renv/library/macos/R-4.6/aarch64-apple-darwin23`. No package was installed or
updated, and `renv.lock` was not edited.

| Input | Final SHA-256 |
|---|---|
| `notebooks/preparation/02_coverage_sample_flow.qmd` | `572173e119c9e8faac93fd61687d3a209d470742dbd82efe44a12ac87e6275fd` |
| `_quarto-nathealth.yml` | `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5` |
| `tests/test_preparation02_report.R` | `1a6fd5fb83fdefa7e7862c055fee71b6d6b9508a59b0a434b20936b51cea52c3` |
| accepted handoff | `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640` |

## Rendered outputs and exact build delta

| Output | SHA-256 | Bytes |
|---|---|---:|
| `_build/nathealth/notebooks/preparation/02_coverage_sample_flow.html` | `0eeb0114db9161d5bc69b9a0186bd629b302d5fec2e08dcf35e78d049f20886d` | 313,890 |
| `_build/nathealth/search.json` | `fedf8b394efb2fe499b8f05168b36e202e51ca023b8016577c53b93633b36e46` | 1,535,458 |
| `_build/nathealth/sitemap.xml` | `fb7d35e07c77e21ea3b231276fb89711e326ed49837f5d24654fe50d4936c5f8` | 5,219 |

The build contained 827 files before and after the target render. No file was
added or deleted. Exactly three files changed in content:

| Path | Before SHA-256 | After SHA-256 |
|---|---|---|
| Preparation 02 HTML | `badeb5f5c1c02436cbb33200841921d2e2010bf413b3074b93b666f996dd07a6` | `0eeb0114db9161d5bc69b9a0186bd629b302d5fec2e08dcf35e78d049f20886d` |
| `search.json` | `c044834c4d756ce163f09fb867326c1f3958f8a4c5a29cfd3cc2567873021e32` | `fedf8b394efb2fe499b8f05168b36e202e51ca023b8016577c53b93633b36e46` |
| `sitemap.xml` | `067a1de50590667ffa6efa462817c90b71d33a30608bc9bfdb0ecc51eb1459ab` | `fb7d35e07c77e21ea3b231276fb89711e326ed49837f5d24654fe50d4936c5f8` |

Quarto transiently touched the byte-identical shared Bootstrap CSS file. Its
content remained unchanged and its mtime was restored from 1786620217 to the
pre-render value 1786619001. After restoration, only the three expected output
files differed in content or metadata from the immediate pre-render build.

## Focused test and protected-input gate

Command:

```text
/usr/local/bin/Rscript tests/test_preparation02_report.R _build/nathealth/notebooks/preparation/02_coverage_sample_flow.html
```

The focused test used normal project startup under R 4.6.1, exited with status
0 in 16.51 seconds, and reported:

```text
PASS: Preparation 02 source satisfies the bounded-render, terminology, gt-table, and provenance contract.
```

The diagram-repair scoped read set contained 32 paths. Immediate pre-render,
post-render, and post-loopback comparisons each found 32 unchanged paths and
zero mismatches.

| Record | SHA-256 | Rows |
|---|---|---:|
| `audit/preparation_reports/report017_preparation02_diagram_prerender_scoped_readset.csv` | `4551e62feff0f744278016895d5a980caf3c316b9386c293f471a2ae073462c2` | 32 |
| `audit/preparation_reports/report017_preparation02_diagram_postrender_scoped_verification.csv` | `6abd7f479f283f95c94c8dd571dce1c25cdd5bd90ce7580c52ed8b7f6bbd3722` | 32 |
| `audit/preparation_reports/report017_preparation02_diagram_final_scoped_verification.csv` | `6abd7f479f283f95c94c8dd571dce1c25cdd5bd90ce7580c52ed8b7f6bbd3722` | 32 |

Every stored scientific or preparation input in the page read set remained
unchanged. This is a scoped assertion, not a claim that the shared checkout
was globally static.

## Semantic HTML and link audit

The final HTML passed these assertions:

- exact page title and the accepted 10 second-level headings in order;
- one complete render-boundary callout;
- one Mermaid overview with its accepted figure identifier, caption, and alt
  text;
- exactly 11 native `table.gt_table` displays and 11 nonempty captions;
- the accepted table structure of 3/6, 3/13, 8/17, 3/5, 7/10, 6/20, 3/6,
  5/1, 2/4, 3/7, and 2/5 header/body-row counts, with the two expected source
  notes;
- every accepted threshold, count, unit, sample-flow value, and all nine
  country-coded site labels;
- one active sidebar item, `02 Coverage and sample flow`;
- no `Table Table` duplication, raw tibble or console output, rendered error,
  or internal production shorthand.

The main-content and page-navigation region contained eight unique internal
links. All eight files and anchors resolved. The DEV-055 link occurred once,
rendered exactly as
`../../notebooks/preregistration_deviations.html#dev-055`, and resolved to the
`dev-055` anchor in the unchanged target with SHA-256
`c033c1b8110e58375757e8ef8ac5c5d0dbf5f402a651454b247c1a622ded6880`.
The loopback log also recorded a successful HTTP 200 request for that target.
No internal `.qmd`, `file://`, `_build`, build-directory, or absolute-local
href occurred.

The global sidebar still contains the previously recorded
`supplementary_information.html` target that is absent from this partial build.
This order prohibited rendering supplementary information or the full project,
so the known global-build limitation was not changed or treated as a
Preparation 02 content failure.

## Secure loopback visual QA and teardown

The temporary server command was:

```text
python3 -u -m http.server 0 --bind 127.0.0.1 --directory /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/_build/nathealth
```

It was rooted exactly at `_build/nathealth`, bound only to `127.0.0.1`, used
port 62163 and PID 37673, and ran from `2026-08-13T11:26:09Z` to
`2026-08-13T11:33:36Z`. The exact review URL was
`http://127.0.0.1:62163/notebooks/preparation/02_coverage_sample_flow.html`.
After browser cleanup, the server was interrupted. `lsof` returned no listener
on port 62163, and `kill -0 37673` returned `no such process`. The complete
827-file inventory was byte-for-byte and mtime-for-mtime unchanged across the
loopback review. No symlink was present in the build.

At 1440 by 1000, the repaired Mermaid SVG occupied 538.93 by 733.99 CSS pixels
with the same-size view box. Its node-label font was 16 px, equivalent to 12
points at final size. Every node and arrow was visible, labels stayed inside
their nodes, and the layout had no clipping, overlap, distortion, or excessive
width. All 11 tables retained 13 px type and 1,148.5-pixel table and wrapper
widths with no overflow. Prose, captions, the callout, links, and page
navigation also passed.

At 708 by 1000, the document client width and scroll width were both 693
pixels, so there was no page-level horizontal overflow. The Mermaid retained
its 538.93 by 733.99 CSS-pixel size and 16 px labels, remaining centered and
fully legible. Each table and wrapper was 642 pixels wide, with 13 px cell
type and no horizontal overflow. All tables, captions, source notes, links,
callout text, country-coded site labels, opened mobile navigation, and bottom
page navigation passed for wrapping, clipping, overlap, typography, and
usability.

## Ownership and scientific-change evidence

The only source edit in this repair was the one authorized Mermaid direction
token. No data, scientific artifact, manifest, production script, test,
configuration, decision, ledger, bibliography, lockfile, manuscript file, or
hypothesis output was changed. The render read the already accepted stored
coverage outputs and did not recreate them. Preparation 03 remained held for
independent release.
