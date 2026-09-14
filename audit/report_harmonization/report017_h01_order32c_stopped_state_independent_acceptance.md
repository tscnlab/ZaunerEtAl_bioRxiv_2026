# REPORT-017 H01 order 32c stopped-state independent acceptance

Date: 2026-08-15

Disposition: **The stopped state is independently accepted. The H01 result
render and semantic integration pass. H01 remains held only for a consolidated
three-figure display repair and build-tree duplicate cleanup.**

## Evidence replay

The owner returned
`audit/hypotheses/H01/report017_order32c_result_render/owner_evidence_manifest.csv`
at SHA-256
`d058cdbceed5e7cd1912d9a0f931646d44141b8bfab755e53d1c65794ca7890b`.
R 4.6.1 independently verified all 119 paths, SHA-256 identities, and byte
counts.

The current accepted identities are:

- result QMD:
  `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`;
- frozen companion QMD:
  `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`;
- fresh result HTML:
  `d1bc9159526c92b9cc9256c58a8232d4779f0014a3aa39ed3680b4e58fb25410`;
- frozen companion HTML:
  `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`;
  and
- Nature Health profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

Exactly one Quarto 1.9.37 target render ran under R 4.6.1. The configured
semantic hook reported `REPAIRED` for 36 native gt tables, 783 internal IDs,
and 4,798 `headers` attributes. The fresh page has ten intended figure
endpoints, zero duplicate document IDs, 11,084 table-header references that
resolve once within their own table, and zero unresolved explicit ID
references. H01 reporting, navigation, reader-link, and deviation-link tests
pass. The 40 deviation links resolve to 36 unique central anchors. The H01
deviation reconciliation independently preserves 1,161 scientific artifacts.

Independent visual inspection of the retained desktop and narrow evidence
confirms the reported Figure 5 label collisions and the small narrow-screen
text in Figures 1 and 6. The page otherwise has no document-level or
uncontained narrow overflow, no missing figure or caption, and no browser
console error or warning. The loopback server is stopped and no listener
remains.

## Independent classification

### Accepted render behavior

`H01-32C-BUILD-001` and `H01-32C-BUILD-002` are expected target-resource
synchronization, not source or scientific drift. The target render copied the
current source-identical model-support PNG and current source-identical Stage 3
manifest into the website build. Their source paths remained unchanged. A
later H01 render contract should permit exact source-identical resource-copy
refreshes used or linked by the target page, while continuing to fail on any
other content change.

### Build-tree hygiene hold

`H01-32C-BUILD-003` remains a real build-tree hygiene hold. Three ` 2`
duplicate paths became visible during QA. They preserve older bytes and have
current change times, while their stored birth and modification times predate
the QA window. No accepted build member was overwritten. Before the next
render, the exact three files should be rehashed and moved intact to a fresh
recovery directory outside the project, then the build inventory should prove
their absence and every accepted member's preservation. They should not be
deleted or silently normalized.

### Corpus check outside H01

`H01-32C-CORPUS-001` does not invalidate H01. The two H04 source locations
already render the complete country-coded names `Delft (NL)` and `Munich
(DE)`. The current country-code test sees the site name and its parenthesized
code on adjacent source lines. The H04 owner should reflow those two phrases at
its next safe source-only point, or the test should be made whitespace-aware,
without changing rendered prose. The corpus-wide gate remains open until that
bounded H04 classification is accepted.

### Confirmed H01 display defects

- `H01-32C-VIS-001`: Figure 5 has overlapping direct labels in the dense
  central clusters of both matched-placement panels.
- `H01-32C-VIS-002`: important raster text in Figure 1 and Figure 6 is below
  the normal 7-point final-size readability target at the 708-pixel viewport.

These are display-only defects. They do not expose a scientific discrepancy
and do not affect samples, estimates, intervals, p-values, FDR decisions,
diagnostics, source data, or claims.

### Non-page findings

`H01-32C-CHECK-001` is a stale evidence-only section-ID expectation. The
actual accepted source and HTML endpoints pass. The two evidence-capture
limitations do not invalidate the retained command, lifecycle, hook,
inventory, semantic, screenshot, teardown, or no-listener evidence. The
recovered R-startup and sandbox-bind stops changed no source or output.

## Proposed one-pass repair gate

To avoid another sequence of piecemeal loops, the next H01 owner order should
combine all remaining H01 work before one rerender:

1. Rehash and recoverably quarantine the three exact duplicate build files.
2. Create one dedicated display-refresh implementation for Figures 1, 5, and
   6. It may read only the three frozen figure-source CSVs and the minimum
   frozen registries/constants needed by the accepted plot construction.
3. Update only the corresponding display literals in the reproducible Stage 3
   builder. Do not run the full builder.
4. For Figure 5, change only deterministic label-layout parameters needed to
   remove all text collisions. Preserve every point, label, estimate,
   predictor, colour, shape, panel, axis, null line, identity line, and source
   row.
5. For Figures 1 and 6, increase only plot-text and symbol sizes needed to
   reach at least 7 points at the 708-pixel final display. Preserve every tile,
   status, symbol, row, column, placement, legend category, colour, source row,
   dimension, and DPI.
6. Generate temporary candidates first and require desktop, 708-pixel, 200
   percent, original-size, and intended final-size QA before replacing the six
   durable PNG/SVG files once.
7. Add focused pixel/structure/source-data and visual tests, correct the stale
   evidence-only section-ID expectation, reseal only direct current manifest
   rows, and preserve all historical evidence.
8. If all source, artifact, and protected checks pass, run exactly one fresh
   H01 result target render through the semantic hook and repeat the complete
   semantic, link, table, figure, and secure-loopback QA. Return one combined
   stopped state if anything remains.

The companion and every later REPORT-017 target remain held until this package
is authorized, implemented, and independently accepted.
