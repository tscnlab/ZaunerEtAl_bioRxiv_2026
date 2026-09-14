# REPORT-017 H01 gt HTML semantic repair dry-run verification

Date: 2026-08-14

Status: **PASS for bounded implementation, temporary-copy dry run, and the
post-order-31c final dependency refresh. Ready for independent acceptance. No
profile hook or durable HTML repair is implemented or authorized.**

## Authorization and scope

This implements only stage A of the coordinator disposition for
H01-31A-SEM-001 under the active `$create-gt-tables` workflow. The repair
engine and focused test are harmonizer-owned. The engine was exercised only on
a temporary copy of the current H01 result HTML. `_quarto-nathealth.yml`, all
QMDs, all scientific artifacts, all packages and lockfiles, and all durable
rendered HTML remained unchanged.

Stage A did not edit any QMD. The separately accepted order 31b later changed
the H01 result QMD and its focused owner test. This reseal therefore keeps the
H01 QMD used for the original dry run as historical execution-time evidence,
while the reusable Stage A test protects only the six live inputs on which the
HTML repair depends.

The implementation is:

- `scripts/report_harmonization/repair_gt_html_semantics.R`, SHA-256
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- `tests/report_harmonization/test_gt_html_semantic_repair.R`, SHA-256
  `d5d06f831c7b09690b63fbc39f6f37d745fcbb8644197415541d767702523db6`;
  and
- the diagnostic scope audit
  `scripts/report_harmonization/check_h01_gt_accessibility_scope.R`, SHA-256
  `0a30a240d2756753396e170995b38d4e312ee320d81f651109e1404ccaabce7c`.

## Fail-closed implementation

The repair engine reads the input as raw bytes and uses xml2 only to establish
the table and header structure. Before any output write it requires:

- R 4.6.1 and gt 1.3.0;
- a nonempty set of native gt tables, each inside a unique Quarto `tbl-*`
  endpoint;
- zero duplicate internal IDs within every individual table;
- exact agreement between DOM-order `id` and `headers` attributes and their
  raw-byte occurrences;
- a unique structural decomposition of every existing body-cell `headers`
  value;
- every intended reference resolving to a `th` element with `col`, `row`,
  `colgroup`, or `rowgroup` scope inside the same table;
- zero references to an old internal ID through `aria-labelledby`,
  `aria-describedby`, the other enumerated ARIA IDREF attributes, `for`,
  `list`, `form`, `itemref`, or a fragment `href`; and
- nonoverlapping raw-byte replacement ranges.

For each table, IDs are deterministically assigned in DOM order as
`<table-endpoint>--gt-####`. Each body-cell `headers` value is rebuilt from its
resolved old semantic headers and the new ID map. The engine changes only the
quoted values of `id` and `headers` attributes within native gt tables. It
does not reserialize the document parser tree.

Before writing the temporary output and mapping ledger, the engine verifies
in memory that:

- all document IDs are unique;
- every explicit `headers` token resolves exactly once within its own table
  and to a `th` element;
- the full-document and per-table visible text are identical;
- table, row, cell, header-cell, ID, and `headers` counts are identical;
- the complete parsed DOM is identical after replacing the two permitted
  mutable attribute values with neutral placeholders; and
- reversing exactly the planned raw-byte substitutions reproduces the input
  byte-for-byte.

Any ambiguity, unexpected reference attribute, collision, count change, or
other structural difference stops before output is written.

## Temporary-copy execution

The sealed H01 HTML was copied to:

`/private/tmp/report017-h01-gt-dry-run.pF8CnV/H01-input.html`

The sole repair command was:

```text
Rscript --vanilla scripts/report_harmonization/repair_gt_html_semantics.R /private/tmp/report017-h01-gt-dry-run.pF8CnV/H01-input.html /private/tmp/report017-h01-gt-dry-run.pF8CnV/H01-repaired.html audit/report_harmonization/report017_h01_gt_semantic_dry_run_mapping.csv
```

It passed with:

- 36 unique Quarto table endpoints;
- 783 deterministic internal-ID substitutions;
- 4,798 reconstructed `headers` substitutions;
- 5,581 total allowed raw-attribute substitutions;
- zero unsupported old-ID references;
- input SHA-256
  `ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`
  at 1,371,249 bytes;
- temporary output SHA-256
  `f96183693bfb3f8dc6570c1666f7e9202a47a9cd3bf9c9f62d1c30c941dfb054`
  at 1,626,062 bytes; and
- exact reverse SHA-256
  `ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`.

The 5,581-row reversible mapping ledger is
`audit/report_harmonization/report017_h01_gt_semantic_dry_run_mapping.csv`,
SHA-256
`b9971f45a91af81bfdd34fef6a32a2bab44f864895aab5807e2a0d53c88c5d8f`.
It records the table endpoint, attribute type and index, pre- and post-value,
pre- and post-byte ranges, byte counts, and intended old and new header IDs.

The compact execution summary is
`audit/report_harmonization/report017_h01_gt_semantic_dry_run_summary.csv`.

## Focused verification

The following commands pass:

```text
Rscript --vanilla tests/report_harmonization/test_gt_html_semantic_repair.R
Rscript --vanilla scripts/report_harmonization/check_h01_gt_accessibility_scope.R
air format --check scripts/report_harmonization/check_h01_gt_accessibility_scope.R scripts/report_harmonization/repair_gt_html_semantics.R tests/report_harmonization/test_gt_html_semantic_repair.R
```

The focused test independently recreates a temporary input, output, and
ledger. It verifies all 5,581 reversible mutations, the 36-table and exact
attribute counts, and six live protected project identities before and after.
Those live pins are the H01 companion QMD, Nature Health profile, durable H01
HTML, stored L10 support CSV, reporting manifest, and Stage 3 reporting
manifest. It also reproduces the gt 1.3.0 mismatch using a minimal
`Model unit` table.

The original dry run and the first post-order-31b classification reseal used
reporting-manifest SHA-256
`54b9b062a949c7aa0c4949a068670cd8b65ef65c8d785aeb71ba4167057aa676`
and Stage 3 reporting-manifest SHA-256
`684046903baae35c8cf624bd3d0b317f0bdd5a31daf548d520a5ca759d7b43d8`.
Those identities remain historical dry-run execution evidence. Order 31c
changed only the H01 QMD hash and byte fields in the two manifest rows. The
final reusable test now protects the accepted live reporting manifest at
SHA-256
`d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`
and the accepted live Stage 3 reporting manifest at SHA-256
`08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f`.

The historical H01 result QMD used during the original Stage A dry run was
SHA-256
`5a3f1a03c5c83fba24f59d85d5fb949dd73162d9df9f33fde1a14a17aadda7a9`
at 90,547 bytes. It remains in the Stage A manifest as historical
execution-time evidence and is not a reusable live protection. The accepted
order 31b source is separately sealed at SHA-256
`31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`
at 90,640 bytes, with its focused owner test at SHA-256
`ab648ac80bc1c8a149a11bb958fd683b38722487c53179b42b215a2b000e6fd5`
at 21,025 bytes. Neither live Stage B file is an input to the temporary-copy
Stage A repair test.

The runtime was R 4.6.1 with gt 1.3.0, xml2 1.6.0, htmltools 0.5.9, knitr
1.51, and digest 0.6.39. The recorded Quarto version is 1.9.37. Quarto and
knitr were not executed.

## Preservation and next gate

The durable H01 result HTML remains byte-identical at SHA-256
`ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`.
No profile hook exists, and the temporary repaired HTML is not part of the
Nature Health build.

Order 31b separately completed the H01 compact FDR display-label repair and is
accepted for its bounded source/test change. Order 31c completed the two-row
manifest-only reseal, with 49/49 reporting-manifest and 95/95 Stage 3
reporting-manifest identities exact and the complete H01 reporting test
passing. A profile-specific post-render hook and a fresh H01 render remain
prohibited until the coordinator independently accepts this final Stage A
reseal and issues a new release. The H01 companion and every later hypothesis
target remain held.
