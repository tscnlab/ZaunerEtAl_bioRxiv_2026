# REPORT-017 order 31a: H01 existing-HTML semantic and visual QA

Date: 2026-08-14  
Owner task: `019fb4ce-d84c-73d1-be48-dc244be5b5f0`  
Coordinator decisions: REPORT-017 / CHG-134 and the approved H06_daily corpus-contract repair  
Scope: resume order 31 after the shared structural gate, using the existing fresh H01 result HTML without rerendering

## Release and strict boundary

The shared navigation failure from order 31 is resolved and independently
accepted in
`audit/report_harmonization/report017_h06_daily_corpus_contract_repair_independent_acceptance.md`
at SHA-256
`bf93932680e890243566d8229d6c897b4953cbea14eb830df4392cb65ec77975`.
Its non-circular manifest is
`audit/report_harmonization/report017_h06_daily_corpus_contract_repair_independent_acceptance_manifest.csv`
at SHA-256
`a1e0b5cf2b93777dc51c8e306a02be7229cab98ea9a35086efe02b25323cb168`.

Resume only the semantic and secure-loopback visual QA that remained
unperformed in order 31. **Do not run Quarto, knitr, or any render command.**
Do not execute a scientific builder, fit or refit a model, edit a source,
test, profile, artifact, HTML file, manifest, ledger, or evidence file outside
the existing order-31 evidence directory. The H01 companion and every later
hypothesis target remain held.

Stop before QA if any current pin differs:

| Item | SHA-256 |
|---|---|
| H01 result QMD | `5a3f1a03c5c83fba24f59d85d5fb949dd73162d9df9f33fde1a14a17aadda7a9` |
| H01 companion QMD | `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8` |
| H01 reporting manifest | `54b9b062a949c7aa0c4949a068670cd8b65ef65c8d785aeb71ba4167057aa676` |
| H01 Stage 3 manifest | `684046903baae35c8cf624bd3d0b317f0bdd5a31daf548d520a5ca759d7b43d8` |
| H01 focused test | `6e7b4de5a6580d95c81656f953e24a65743c6af5bf940eb1ce3ef628fc041f83` |
| Nature Health profile | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| Fresh H01 result HTML | `ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72` |
| Protected companion HTML | `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38` |
| Corpus builder | `c01f0dc86e25bcf4a37685515cd692e2007774a004a4e902eac5936521749e2e` |
| Navigation test | `1ba59346328e8e4fb2aa898c5806313763711867514097969f5e4df1c22d3407` |
| 37-source corpus manifest | `52baecfc4d40288cf26cbe259115abddb72f749eae7e538eebafae97ced6aafb` |

## Nonvisual checks

1. Reconcile the retained order-31 1,215-path protected inventory and the
   complete post-render build inventory before and after QA. No source,
   profile, scientific, durable-display, companion-HTML, or target-HTML byte
   may change.
2. Run the existing H01 focused test, navigation contract, reader-link
   contract, and country-coded site-name contract under R 4.6.1. Do not edit a
   failing test. The navigation, reader-link, and site-name contracts must each
   report 37 reader sources.
3. Complete the semantic audit of the retained HTML. Require exactly 36 native
   gt tables with one Quarto caption and nonempty head/body, and exactly 10
   labelled figures with nonempty captions and alt text. Retain every section,
   link, identifier, terminology, no-error, no-warning, and no-leaked-object
   requirement from order 31.
4. Resolve the companion, Preparation 04, Preparation 06, exact deviation
   anchors, source-data, and active-navigation links. Rendered reader links
   must expose no `.qmd`, `file://`, `_build`, absolute local, or unresolved
   target.

## Secure-loopback QA

Use the same bounded loopback procedure and the full visual contract from
order 31:

1. Preflight `_build/nathealth` for symlinks and stop if any resolves outside
   that directory.
2. Start one temporary read-only static HTTP server rooted exactly at
   `_build/nathealth`, bound only to `127.0.0.1` on one unused high or
   OS-selected port, with no upload or write endpoint.
3. Navigate only to `/notebooks/hypotheses/H01.html` in the supported in-app
   Browser. Inspect at 1440 by 1000 and 708 by 1000, plus the focused 200%
   reviews required below.
4. Inspect the full page hierarchy, typography, wrapping, clipping, overlap,
   callouts, navigation, labels, tabsets, captions, footnotes, source notes,
   units, and page-level overflow.
5. Audit all 36 HTML tables. They must work reasonably at desktop size. At 708
   pixels, a contained and clearly usable horizontal scroller is acceptable
   for a genuinely wide table. Page-level overflow, clipped headers,
   unreadable type, or a hidden scroll affordance is not acceptable.
6. Give `tbl-h01-primary-publication-summary` desktop, narrow, and 200%
   review. Verify readable metric labels, exact sample notation, FDR and 95% CI
   headings, p-value display, caption, footnote/source-note hierarchy, and any
   contained scrolling.
7. Inspect all 10 figures at final page size and retain representative
   screenshots. Give `fig-h01-model-support` desktop, narrow, and 200% review.
   Verify legible metric and family labels, check/dash redundancy, panel
   distinction, colour contrast, caption and alt-text agreement, and no
   clipping. Inspect original stored PNGs where page scaling could conceal a
   defect. Do not regenerate a figure.
8. Check the site-contrast, R-squared, matched-placement, model-check, and four
   diagnostic figures for readable labels, country codes where relevant, null
   lines, units, legends, and caption agreement. Use 7 pt as the narrow
   final-size minimum unless an established page-specific contract is
   stricter.

The principal figure/table appearance and their output roles remain
provisional pending author review. A visual PASS integrates this page but does
not finalize either role.

## Teardown and return

Stop the loopback server immediately after QA and prove that no listener
remains. Browser QA must leave the source, profile, target HTML, companion
HTML, complete scoped build inventory, and protected identities byte- and
retained-mtime-identical.

Update the existing order-31 evidence directory with the completed semantic,
link, table, figure, screenshot, viewport, server-lifecycle, protected, and
build records. Return the revised durable verification record and a new
non-circular manifest. Run scoped diff and whitespace checks.

Stop without editing or rerendering if any display defect, scientific drift,
test failure, missing output, unresolved link, or preservation mismatch
appears. Return the bounded finding for separate disposition.
