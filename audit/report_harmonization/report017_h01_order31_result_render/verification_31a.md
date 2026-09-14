# REPORT-017 H01 order 31a existing-HTML verification

Date: 2026-08-14

Status: **structural contracts passed; semantic and link audit failed before secure-loopback visual QA.**

## Release and preservation

The order 31a identity matched
`cca90345dcbc6db724b25859aad99641d5599a108d7142d952363505063138d5`.
All 14 release and repaired-corpus pins matched before execution. The retained
H01 result HTML remained
`ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`
at 1,371,249 bytes. The protected companion HTML remained
`5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`.

The precheck reconciled all 1,215 protected paths by SHA-256, byte count, and
retained mtime. The complete Nature Health build reconciled all 1,123 nodes,
including 817 files and zero symlinks. The same checks passed after the
bounded static audit failure. No protected or build byte or retained mtime
changed.

No Quarto, knitr, render, model, prediction, bootstrap, scientific builder,
or scientific recomputation ran. No source, test, profile, scientific
artifact, HTML, lockfile, manuscript, or central ledger was edited.

## R 4.6.1 contracts

The H01 focused reporting test passed. The repaired navigation contract
passed for 37 accepted reader sources. The reader-link contract passed for 37
QMD sources and 86 deviation IDs and anchors. The country-coded study-site
contract passed for all 37 reader-facing QMD sources.

The navigation contract invoked its accepted corpus builder and reproduced
the pinned 37-source corpus manifest byte-for-byte at SHA-256
`52baecfc4d40288cf26cbe259115abddb72f749eae7e538eebafae97ced6aafb`.

## Existing-HTML semantic checks

Static DOM parsing confirmed all of the following:

- exactly 36 labelled native gt tables, each with one Quarto caption and a
  nonempty table head and body;
- exactly 10 labelled figures, each with a nonempty caption, alt text, and an
  existing stored image;
- the principal table and principal figure endpoints;
- all 15 required report sections and the Answer in brief hierarchy;
- no cell-output errors, cell-output warnings, unresolved reference elements,
  raw console dump, leaked fitted-object marker, or prohibited workflow term;
- the active H01 sidebar entry;
- working H01 companion, Preparation 04, and Preparation 06 links;
- all 36 unique exact deviation anchors; and
- all displayed H01 source-data links.

Four controlling requirements failed:

1. There are 109 duplicated DOM ID names across 720 occurrences, producing
   611 extra occurrences. Every duplicate occurs inside native gt tables.
2. Eight compact cells in `tbl-h01-l10-noon-support` display
   `Primary 17-test BH family` instead of FDR terminology.
3. The visible Supplementary information link targets
   `../../supplementary_information.html`, which is absent from the retained
   Nature Health build.
4. Two visible Edit this page links expose the external GitHub source target
   `notebooks/hypotheses/H01.qmd`.

The exact affected IDs, gt owners, compact cells, and link targets are in the
paired CSV evidence. These findings do not alter or question any scientific
value.

## Mandatory stop and visual QA

Order 31a requires a stop on any semantic failure, unresolved link, or
forbidden reader target. The loopback server was therefore not started. No
port or PID was allocated, no Browser navigation occurred, and no screenshot
or viewport measurement was made. Desktop, narrow, 200 percent, 36-table,
10-figure, and stored-PNG visual review remain held for a separate
disposition and release.

The principal figure and table remain provisional, as specified by the
controlling order.
