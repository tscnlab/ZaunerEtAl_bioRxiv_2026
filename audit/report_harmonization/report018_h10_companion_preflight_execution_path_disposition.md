# REPORT-018 H10 companion preflight execution-path disposition

Date: 2026-08-22

Status: `FRESH_HTML_PRESERVED_NO_RERENDER_COMPLETION_REQUIRED`

## Execution-path disclosure

During the coordinator's isolated downstream preflight, the Quarto invocation resolved the target from the live project rather than the intended temporary project root. Exactly one H10 companion render therefore completed in the live project before an owner order was dispatched. This is recorded as the consumed H10 companion render. It is not represented as an unconsumed preflight or repeated later.

The coordinator stopped before invoking the H10 helper, either H10 test, browser QA, or any second Quarto command. No QMD, model, scientific artifact, profile, package, lockfile, H10 result, H11 file, or later target changed. A narrowly elevated read-only process inventory found no surviving Quarto, Pandoc, H10-render, semantic-hook, or loopback process.

## Preserved rendered state

- Companion QMD remains `706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6`, 58,446 bytes.
- Fresh companion HTML is `dc2aa864a1b1edf01043444af425df40564779e83b72f00c206068fdba19a7b9`, 652,030 bytes.
- Semantic summary is `4a3848b85d2e454dea54a2577759498953f160a1c0c43921147408a88d480682`.
- Semantic ledger is `f43f701108cbdf5cdc9e62a2a2e231a6a00dd5e99ddc3700d03c4dd96de0324b`.
- The hook repaired 19 tables using 82 `id` substitutions and 1,050 `headers` substitutions, 1,132 total. Exact raw reversal recovers pre-hook SHA-256 `c3014cafdd8a1d0906c7f570de8bd6f979a70153c9b83175e47a27703ca7c1b6`, and reapplication recovers the current HTML exactly.

The former source-side `audit/hypotheses/H10/H10_analysis_preparation.html` is absent. This is accepted target cleanup. Canonical reader output is under `_build/nathealth`.

## Complete read-only downstream preflight

R 4.6.1 confirms:

- the accepted result and owner order 58a seal remain exact;
- 19 table endpoints and two figure endpoints match immutable QMD order;
- one top-down Mermaid diagram is present;
- the document has one `main#quarto-document-content`, zero duplicate IDs, and 1,050 table-header tokens that resolve exactly once to scoped header cells;
- all 23 local links resolve, including six exact fragments;
- all 57 scientific assets are unchanged;
- the only build changes from the accepted result-page baseline are the companion HTML, `search.json`, `sitemap.xml`, and a source-identical build copy of the immutable H10 Stage 3 manifest;
- the only protected-baseline change is removal of the obsolete source-side companion HTML;
- prospective helper SHA-256 `292ad3335dac8241f317983d5017a5a1d5dbce51fef245d2c30889cf4a3dcf97` produces a 269-row live-exact non-circular current manifest without the obsolete source-side HTML;
- prospective preparation-test SHA-256 `8b206d4cf565b6f5a767e6e99afb9e587db8255f2239cb3761eebaa8e69d1608` passes the complete companion contract after all 15 stale terminology assertions are replaced with exact accepted wording;
- both prospective R files parse and pass Air 0.4.1 formatting checks.

## Disposition

No rerender is permitted or needed. One owner continuation may apply only the two exact prospective postimages, run the helper exactly once, run the preparation test exactly once, complete static and secure-loopback visual QA against the preserved fresh HTML, and seal. Any new defect must stop fail closed. H11 remains held.
