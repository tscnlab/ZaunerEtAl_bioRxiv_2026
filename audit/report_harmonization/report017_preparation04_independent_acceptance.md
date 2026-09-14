# REPORT-017 Preparation 04 independent acceptance

Date: 2026-08-13  
Harmonization task: `019ff52e-48ac-77b3-9a0e-9a87749a3bba`  
Document owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/04_metric_derivation.qmd`  
Disposition: **ACCEPTED. Preparation 04 passes the source, focused target-render, protected-input, semantic HTML, dynamic-link, navigation, desktop, narrow-layout, native-table, and figure-visual contracts. Preparation 05 may be released as the sole next REPORT-017 render owner.**

This independent review used the authorized `$quarto-authoring` workflow. It
did not rerender the page, execute a preparation or scientific builder,
modify a reader source, regenerate an artifact, or start another browser
server.

## Accepted identities

- Reader source:
  `6b7239ca32ecc6e75b993115f74fa2a42781ddded98ebf9ce94f2202777086d4`
- Nature Health profile:
  `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`
- Focused test:
  `8a3caf85f230002c43c7efd46af6f6986dc6611d5e2954fa5f0edd20334b2704`
- Target HTML:
  `9dd7797e5c3924aae5348dad0d2f1abdb3d66a281503e3500f73d0f47124479e`
- MDER figure PNG:
  `423cae8946a50bd6e611ff14708b7ff0543546f3fdc9e9fa030ca917838d75ce`
- Owner final record:
  `50950da6fabc99d4a91e53977d817b1450db349a64db39bf1820eea93e773685`
- Owner final manifest:
  `cbb942a90546ab2108241ecc519d480fcb47ea59d48962d5a0610e5374587ed2`

The non-circular 23-entry independent manifest is
`audit/report_harmonization/report017_preparation04_independent_acceptance_manifest.csv`,
SHA-256
`f4f232c36cef9700bf5d4dc3f11b9ee16820cc0719927a3c5bb61e2c916059d5`.
R 4.6.1 independently verified all 23 file paths, SHA-256 values, and byte
counts.

## Exact display-only repair

The accepted source differs from the released source only by:

```diff
-flowchart LR
+flowchart TB
```

Streaming the exact reverse substitution independently reproduced SHA-256
`86041585edfb60ba0f3137d268418e7479b369be859b41350d2347bd81e064a6`.
The current source contains the one `flowchart TB` declaration at line 1569.
All nine diagram labels and every node and edge remain unchanged. The
scientific prose, 14 table endpoints, figure code, source data, PREP-003 and
FIND-044 qualification, metric values, and configuration remain outside the
repair.

## Focused and protected verification

The focused command was independently rerun with the normal project startup
and the previously approved narrow access to the existing user-owned renv
cache:

```text
/usr/local/bin/Rscript tests/test_preparation04_report.R _build/nathealth/notebooks/preparation/04_metric_derivation.html
```

It completed under R 4.6.1 and passed:

```text
PASS: Preparation 04 satisfies the bounded-render, version-specific verification, gt-table, figure, terminology, and provenance contract.
```

The normal startup reported a 15-second dependency-discovery note. It did not
change the assertion result, install or update a package, edit `renv.lock`, or
alter a protected file.

The final scoped comparison contains 106 paths. Independent R 4.6.1 checking
confirmed 105 byte-identical paths and exactly one authorized Mermaid
direction change. No stored preparation input, metric output, data file,
manifest, scientific script, decision, environment identity, shared profile,
or focused test drifted. The evidence file is
`audit/preparation_reports/report017_preparation04_diagram_postrender_scoped_verification.csv`,
SHA-256
`c94c0947e326ae54fcac6318a5ae72e096cf4f63215f705328e7065a18d7a951`.

The two preliminary focused-test stops are preserved. The first exposed
obsolete historical 725/729 wording. The second showed that the accepted
supersession sentence is defined inside a table-producing R chunk and
therefore cannot occur in a prose-only string that strips fenced chunks. The
approved harness repairs changed only those assertion locations. The final
test still requires the exact current 687/811 and 723/897 counts, current
means and medians, 25,620-cell invariance, METRIC-010, METRIC-011, PREP-003,
FIND-044, paths, hashes, table and figure contracts, and forbidden-execution
checks.

## Semantic HTML and links

Independent R checking confirmed all 10 recorded semantic checks and all 14
native table endpoints. The controlling count is 14 because the accepted
METRIC-011 follow-up added `tbl-l10-numerical-zero`; the earlier 13-table
order text is superseded metadata.

All table identifiers are unique. Every endpoint has a nonempty
Quarto-owned caption, headers, body rows, accepted ordering and values, and
its intended source-note role. The complete METRIC-010 and METRIC-011 wording,
current MDER counts, PREP-003/FIND-044 qualification, and no-discrepancy
statement are present. The MDER figure has a 200-character substantive alt
text, caption, and paired source-data link.

The five reader-facing main links retain their intended labels and resolve.
There is no rendered internal `.qmd`, `file://`, `_build`, build-directory, or
absolute-local href, raw console or tibble output, unresolved cross-reference,
or rendered error text. Preparation 04 is active in navigation, and the
accepted H06 complementary daily pages remain in the later hypothesis
position. No individual study-site name is displayed, so the country-code
contract is not applicable to this page.

## Independent visual review

The owner used the authorized read-only secure-loopback surface. The final
server was rooted exactly at `_build/nathealth`, bound only to
`127.0.0.1:50523`, and recorded as OS PID 61685. It ran from
`2026-08-13T16:10:57.102489+02:00` through
`2026-08-13T16:15:00.185274+02:00`, exited with status 0, and left no
listener. An independent `lsof` check also returned the expected no-match
status for port 50523.

All five retained final screenshots were inspected independently at original
resolution.

At the requested 1440 by 1000 desktop viewport:

- the document client and scroll widths both equal 1,425 pixels;
- the top-to-bottom overview is visually balanced, with all labels and edges
  legible at the recorded 12-point effective size;
- all 14 native HTML tables fit their desktop containers with intact titles,
  headings, rows, and notes and a recorded 8.25-point minimum cell size; and
- the 1,382 by 806 MDER PNG is clear at its intended 691 by 403 CSS-pixel
  display, with readable labels, counts, axis, legend, caption, and
  source-data link.

At the requested 708 by 1000 narrow viewport:

- the document client and scroll widths both equal 693 pixels, so there is no
  page-level horizontal overflow;
- the overview displays at 642 by 498.07 pixels, with approximately
  9.49-point effective labels and no clipping or overlap;
- all 14 native HTML tables remain contained and readable under the approved
  narrow-view policy; and
- the MDER figure retains its aspect ratio and readable labels, legend,
  caption, and source-data link.

Table 13 is 670 pixels wide inside a 642-pixel viewport. Its wrapper provides
a working horizontal scroller across the complete 28-pixel excess. The
retained screenshot shows the dense identity table contained within the page.
This is accepted behavior under
`audit/report_harmonization/phase4_table_visual_qa_policy.md`, SHA-256
`589efda97afe0b5d23f0a490dd446b051326ec8f3f7d7cad6d3363b51b4197c2`:
native HTML tables must work at a typical desktop or laptop viewport, while a
narrow view requires page integrity and contained usable horizontal
scrolling. Preparation 04 has no exported table PNG endpoint. Its PNG is a
figure and passed the separate intended-final-size figure check.

## Final disposition

Preparation 04 is independently accepted. The narrow Mermaid defect is
resolved by the bounded top-to-bottom repair. The test harness and 14-table
metadata corrections are also reconciled without a reader-source or
scientific change. PREP-003/FIND-044 remains visible and unchanged in meaning.
No scientific discrepancy was exposed.

Preparation 05 may be released as the only active REPORT-017 render owner,
subject to the coordinator's serial authorization. The principal and
supplemental manuscript-output shortlist remains provisional and is not
affected by this preparation-page acceptance.
