# REPORT-018 H08 order 54 result acceptance

Status: **PASS**

Date: 2026-08-21

The sealed H08 result order was executed once within its result-only boundary. The sole authorized render exited 0 under R 4.6.1 and Quarto 1.9.37. No source, test, scientific artifact, historical or current manifest, profile, central ledger, package, lockfile, companion page, or unrelated page was rendered or modified. No model was fitted or refitted, and no prediction, resampling, simulation, bootstrap, p-value calculation, or scientific-result regeneration was performed.

## Controlling identities

| Item | SHA-256 |
|---|---|
| Order 54 | `e41c03bc8cf003cb49ee4e6d000d9153e909012a0a6f04a3183a9a5b5383be06` |
| Dispatch manifest | `87acae3e4d8e9951a0ee8e329b9bdbededbe0c23a5112757a924b5d11bcad715` |
| Central release | `c729a0917cbaa7cd51f41b259b7016a6936abdad4fbb99ad5617589c5ced4ccd` |
| Central 30-row release manifest | `71e1fb067205453e462255b6bd3bb5e687c50f3be26e120ce544f5afc333e279` |
| H08 result QMD | `1b6b50b21e22d60909a65b125ce74be54829e5efc10de33f888fcd294c7374b1` |
| Nature Health profile | `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3` |
| Fresh H08 result HTML | `472848d0da3e3996fa1727151048e3cab4a7e363dba3dc8eda8b024eb5a4ca9a` |

The fresh result HTML is 340,040 bytes. The exact render command and its single-attempt record are in `render_execution.csv`.

## Render and semantic acceptance

- Exactly 15 native `gt` tables and five figures occur in the accepted order.
- The formula endpoint contains exactly the nine accepted evaluated Wilkinson formulas in one semantic table, with no separate formula-object output.
- The semantic hook reported `REPAIRED`: 86 ID substitutions plus 855 header substitutions, for 941 reversible substitutions in total.
- Exact semantic reversal to the pre-hook HTML and exact reapplication both passed. Visible text, values, order, captions, notes, and links were invariant.
- The final document contains 281 unique IDs. All 864 `headers` token uses resolve exactly once to an intended `th` in their own table.
- All 26 expected reader and source-data targets pass, including reciprocal companion navigation and exact DEV-035 and DEV-036 anchors.
- The Answer in brief, exact samples, separate effect scales, eight complete FDR families, near-eye primary and chest complementary hierarchy, model qualifications, sensitivities, and limitations all pass the sealed scientific contract.
- Zero embedded errors, warnings, stderr, unresolved references, or raw execution traces were found.

The external semantic evidence remains retained at `/private/tmp/H08-order54-semantic.XXQVYp`. Its ledger SHA-256 is `95dc07bcb3cc8f85b6d89a9c452fa78e67ebf079cd213f6888940d76ced7dd31`; its summary SHA-256 is `a51f8f846e0b8ba9a75bcdfeb8cbec17ae93649a72e1646c5742906b692842c8`. Byte-identical copies are present in this evidence directory.

## Preservation and build acceptance

The complete build inventory contains 851 files. Exactly three build transitions occurred and all passed classification:

1. `_build/nathealth/notebooks/hypotheses/H08.html`, the authorized H08 result target.
2. `_build/nathealth/search.json`, expected website integration.
3. `_build/nathealth/sitemap.xml`, expected website integration.

No build member was removed and no build symlink exists. The complete protected scope contains 153 paths, with only the authorized result HTML transition. The post-QA rehash matched all 851 build files and all 153 protected paths exactly.

Held and historical identities remained exact:

| Item | SHA-256 |
|---|---|
| Companion QMD | `3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d` |
| Companion HTML | `95f5ba0aede0ee6cf0d1b65fcdc53623d52810f8316c846cb214b4fb34a5f135` |
| Historical reader test | `3049ecd80bc7f6c83dce7370b2877a92c6693dd9585f1f45ed7ac19fdf64be8f` |
| Historical preparation test | `2e83542b120021e0c337a3769127e6eba2fe61ebc4d56014693b34066a3fc2a4` |
| Historical Stage 3 manifest | `e8dcec4bfdaf129002c875681f22b0f9d226ebbc95f706309c98ae4e21244af2` |
| Phase 4 corpus manifest | `73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334` |

Both historical tests were preserved byte-for-byte and were not executed. The Stage 3 manifest is unchanged and reconciles at 99 of 102 live-exact identities, with exactly the accepted result QMD, profile, and fresh result HTML transitions. The phase 4 corpus manifest is unchanged, with the H08 HTML row classified as the expected historical-to-fresh transition.

## Visual acceptance

Read-only visual QA inspected only the H08 result route through one temporary server bound to `127.0.0.1`. All 15 tables, all five figures, the callout, headings, captions, links, navigation, wrapping, disclosures, axes, legends, symbols, country-coded sites, clipping, overlap, and page overflow were inspected at:

- 1440 by 1000: client width 1440 px, page scroll width 1440 px, PASS.
- 708 by 1000: client width 708 px, page scroll width 708 px, PASS.
- 720 by 500, the 200-percent-equivalent view: client width 720 px, page scroll width 720 px, PASS.

All tables reflowed within the page at narrow widths, so no contained horizontal scroller was needed. The narrow sidebar opened, exposed both H08 navigation entries, and closed cleanly. Deep internal navigation worked. All five result images loaded at their expected intrinsic dimensions. The browser console recorded zero warning or error entries. Seventy-four screenshots retain the three viewport flows and endpoint inspections.

All five A4 portrait proofs were inspected at an intended width of 170 mm between 20-mm side margins. Each retains 7.5-pt nominal and effective essential text. All five passed clipping, overlap, wrapping, distortion, and data-region-balance review.

The QA tab was closed, the viewport override was reset, and the temporary server exited 0. No listener remained on TCP port 8774 and no Quarto, Pandoc, semantic-hook, HTTP QA, or order-specific verifier process remained.

## Evidence and hold

The order-specific verifier SHA-256 is `9c122e3218fa8e7b7478a85c970d7e014f295676f706c0fb167e2aba4f1bb0d6`. Verifier-only corrections are recorded in `verifier_correction.csv`; none changed a source, result, render, or scientific artifact, and no rerender occurred.

Two finalizer-only stops caused by R data-frame attributes and vector names are recorded in `finalizer_correction.csv`. Both checks were narrowed only to ignore non-value attributes while retaining exact path, SHA-256, and byte-count comparisons. The completed finalizer passed every value and identity check without changing a source, render, or scientific artifact.

The non-circular `order54_evidence_manifest.csv` seals this acceptance record, every order-specific evidence file other than the manifest itself, and the consequential controlling, source, held, rendered, test, manifest, semantic, and physical-size identities.

The H08 companion render and every later REPORT-018 render remain held. No commit, push, upload, or publication action was performed.
