# REPORT-018 H06 order 47b stopped record

Date: 2026-08-21  
Owner scope: H06 hourly result page  
Disposition: **STOPPED at the semantic post-render gate**

## Outcome

The exact one-token source repair passed every pre-render gate. The sole
authorized result render then completed all 41 executable cells and created a
fresh HTML target, but exited with status 1 in the configured semantic
post-render hook. No patch or second render was attempted. Browser and final-size
visual QA were not started because the nonvisual semantic gate is controlling.

## Exact source transition

Only `notebooks/hypotheses/H06.qmd` changed:

```diff
 reader_figure_qa |>
-  dplyr::select(
+  dplyr::transmute(
```

- Preimage: `468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2`,
  60,677 bytes.
- Postimage: `2e88ad6b3a4aaffd2dfbf429a77c5d0865256554bb9b7799648fe63b976f1526`,
  60,680 bytes.
- Reverse substitution reproduced the preimage exactly.
- The accepted H06 contract remained
  `b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f`,
  13,468 bytes.

The R 4.6.1 source gate passed: all 20 result R chunks parsed, all 17 accepted
table and figure endpoints were unique and ordered, no invalid nested
`dplyr::select()` expression remained, and the repaired figure-QA display
reconstructed six rows by seven columns with all six statuses mapped to
`Verified` and all accepted values unchanged.

## Sole render

Command:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/h06_order47b_semantic.Iq7j7q quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

- Quarto: 1.9.37.
- R: 4.6.1 with the normal project profile and existing renv library.
- Semantic directory created at 2026-08-21T02:03:11+0200.
- Fresh result HTML written at 2026-08-21T02:04:50+0200.
- Total wall time was approximately 128 seconds.
- Exit status: 1.
- Final error: `gt HTML semantic post-render ERROR: Every native gt table must have one Quarto tbl-* endpoint.`

Three Pandoc resource warnings also appeared during the sole render:

1. Could not fetch `../../audit/hypotheses/H06/H06_analysis_preparation.html`.
2. Could not fetch `../../audit/hypotheses/H05/H05_analysis_preparation.html`.
3. Could not fetch `../../Datatype.woff2`.

Both companion HTML targets exist in the build tree. The font target does not.
The fresh H06 page contains no embedded execution error, hook error, warning,
stderr block, or unresolved cross-reference marker. These terminal warnings
remain part of the stopped record and were not repaired.

## Semantic diagnosis

Read-only R 4.6.1 inspection with xml2 1.6.0 found 13 native `gt` tables in the
fresh HTML. Eleven have unique Quarto `tbl-*` ancestors. Two do not:

- source chunk `exploratory-two-part-formulas`, nearest generated wrapper
  `doehfmulan`; and
- source chunk `exact-confirmatory-formulas`, nearest generated wrapper
  `oxkdsizyuq`.

The hook checks every native `gt` table before staging a repair, so these two
unlabelled displays caused it to stop before semantic namespacing. The external
semantic directory remained empty. No summary or reversible ledger was
created, and the transactional repair engine did not alter the fresh HTML.

The unnamespaced page has 1,804 document ID occurrences but 1,796 unique IDs.
Five ID names are duplicated, accounting for eight extra occurrences. Of 883
explicit `headers` tokens, 149 resolve exactly once document-wide, 692 are
unresolved, and 42 are ambiguous. The required semantic table contract is
therefore not met. All six figure endpoints are present.

## Read-only link and structure inspection

The fresh page has 1,710 unique href values. Of 1,708 internal hrefs, none has a
missing target and none has an invalid fragment. The four deviation links each
resolve to exactly one target: `DEV-015`, `DEV-030`, `DEV-031`, and `DEV-032`.
The held H06 daily target was not rendered or inspected. Its pre-existing build
file remained unchanged. The H06 navigation link is active, and all nine
country-coded site labels are present.

## Build and protection reconciliation

No build file was added or removed and no build symlink exists. Eight build
paths changed:

- the fresh H06 result HTML;
- `search.json` and `sitemap.xml`;
- one byte-identical Bootstrap CSS file with mtime-only drift; and
- four H06 PNG build copies, each now byte-identical to its accepted protected
  source artifact.

Three target-local Quarto support files outside `_build/nathealth` were also
rewritten by the sole render: the H06 freeze result, H06 index record, and H06
cross-reference record under `.quarto`. They are disposable render
intermediates and are not in the protected set. Their pre-render bytes were not
part of the order-47b build inventory, so the reconciliation records their exact
post-render identities and this preimage limitation explicitly. No other
non-build project file has a post-render mtime, apart from this evidence package.

All 75 protected paths remained exact. This includes the H06 contract, the
companion QMD and HTML, the accepted figure and table artifacts, source CSVs,
profile, lockfile, H06 daily sources, historical evidence, tests, and manifests.
`git diff --check` passed for the authorized result source and this evidence
package. All evidence CSVs parsed successfully under R 4.6.1.
The held companion identities remain:

- QMD: `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`,
  59,613 bytes.
- HTML: `222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`,
  771,694 bytes.

The fresh, semantically unrepaired result HTML is
`dc62f37001c2d7e9f5a2daa9167023e006aafecc72c2d0137925093e573027c1`,
4,862,444 bytes.

No loopback server was started, so there is no order-47b server listener to
stop. Existing loopback listeners were unrelated to this project. A discarded
read-only shell inventory attempt shadowed zsh's `PATH` through a local variable
and stopped before making a valid comparison. It changed no file. The corrected
read-only inventory then produced the eight-path reconciliation recorded here.

## Stop boundary

The source repair is retained, but order 47b is not accepted as a completed
render. No additional source cleanup, second render, Quarto target, scientific
computation, artifact regeneration, test, manifest, contract, profile, package,
lockfile, ledger, companion, H06 daily file, commit, push, or upload was
performed.
