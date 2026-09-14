# REPORT-018 H05 order 45b stopped state

Date: 2026-08-20

Status: **render and integration succeeded; stopped at one stale test contract before visual QA**

## Source and render outcome

The exact one-row integrity repair is complete at:

- `audit/hypotheses/H05/H05_analysis_preparation.qmd`
- SHA-256 `843f60f890daac0e41c6655bc365ab0325e3f582e011610469a799946b2f2811`
- 77,823 bytes

Exact reverse substitution reproduces the pre-edit SHA-256
`cce35a2631206945b23144abc6cba44d7297237fc60c716d0d0e3949d128ee57`.
R 4.6.1 confirms 27 parsed R chunks, 22 table and three figure
endpoints, one top-down Mermaid, 17 accepted input identities, and all nine
integrity rows passing.

The sole authorized Quarto command completed under R 4.6.1 and Quarto 1.9.37.
All 57 knitr cells and Pandoc completed. The semantic hook reported
`REPAIRED`:

- pre-semantic HTML SHA-256
  `0c0517a89cf3cf22d5fe976d7c804b102a39e6e20ff0395327022e02e56e87ac`;
- final companion HTML SHA-256
  `856dbd21920b65dce6437172022d0e6130410d9e357259a4d50aa1f6fe2461d8`;
- 22 tables;
- 253 ID substitutions;
- 970 header-attribute substitutions;
- 1,223 total reversible substitutions.

The unchanged helper ran once and completed. The website companion QMD is
byte-identical to its authoring QMD. The rebuilt preparation manifest is
SHA-256
`49ab691f8d86852ec034ed49ffa773032c3acdf3312d7fef5de7849c9ff07d80`,
contains 142 unique rows, and verifies 142/142 live identities.

## Finding H05-45B-TEST-001

The unchanged preparation test ran once and stopped immediately with:

`The preparation source does not link to its result HTML.`

This is a low-severity stale shared source-test contract, not a document or
scientific defect. The shared verifier constructs and requires the literal
source path `../../../notebooks/hypotheses/H05.html`. The accepted companion
source instead uses the dynamic Quarto link
`../../../notebooks/hypotheses/H05.qmd`, which the rendered page correctly
converts to the accepted result HTML. Independent link resolution passes.
The H05 test also retains the same stale literal at its line 42.

Under the controlling REPORT-018 render-completion priority, this test cleanup
is deferred rather than used to reopen a source or render loop. The existing
fresh HTML may proceed under a separately sealed no-rerender semantic and
visual acceptance continuation. The shared test and H05 test remain
byte-identical.

## Independent nonvisual inspection completed after the stop

Read-only checks against the existing fresh HTML pass:

- 22 native gt tables and three figures;
- one top-down Mermaid;
- zero duplicate document IDs;
- 1,925 explicit table-header tokens, each resolving exactly once to a `th`
  in its own table;
- 26 document ID references, all resolving exactly once;
- exact semantic-ledger reversal to the pre-semantic HTML and exact
  reapplication to the final HTML;
- complete figure captions and alt text;
- active H05 companion navigation;
- every internal reader link and anchor resolves;
- all nine country-coded study-site names are present;
- zero embedded execution-error or warning nodes.

The project navigation, reader-link, and country-site tests pass for all 37
reader sources. Their navigation setup refreshed the harmonizer-owned 37-row
corpus manifest to its current source and HTML identities. That procedural
global refresh is outside the H05 owner mutation set and is recorded for the
harmonizer acceptance record.

## Build and scientific preservation

The post-render build contains 836 files and zero symlinks. The exact content
changes are limited to the companion HTML, source-identical website QMD,
`search.json`, and `sitemap.xml`. The three target-owned PNGs and shared CSS
were byte-identical metadata-only touches.

The only H05 protected-content changes across the render are the companion
HTML and source-identical website QMD. The accepted result source and HTML
remain
`7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0`
and
`a088e105be1987508280e91b938142773c8fb9275f1e924ac1ec9958a9b199f1`.
The helper, preparation test, profile, lockfile, and every scientific input and
artifact retain their sealed identities.

No model, estimate, interval, p-value, FDR decision, diagnostic, sample,
source data, scientific artifact, result render, later render, package,
lockfile, profile, ledger, manuscript, commit, push, or upload changed.

No loopback server or browser QA was started after the test failure. H05
companion acceptance and every later REPORT-018 target remain held pending the
no-rerender final visual continuation.

