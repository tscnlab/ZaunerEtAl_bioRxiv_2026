# REPORT-017 H01 gt HTML semantic post-render integration verification

Date: 2026-08-14

Status: **PASS for the Stage C source-only integration gate. Ready for
independent acceptance. No Quarto render ran, and no durable HTML changed.**

## Authority and scope

The controlling source-only order is
`audit/report_harmonization/owner_orders/31d_h01_gt_semantic_post_render_integration.md`,
SHA-256
`3f19729b3d60a76ae34d443e138517709b19a446899dbca221ce2653f2264f74`.
It follows independent coordinator acceptance of Stage A, Stage B, and order
31c.

Stage C created only the post-render wrapper, its focused test, and directly
dependent harmonizer records. It added one profile-specific post-render
declaration to `_quarto-nathealth.yml`. It did not run Quarto, edit any QMD,
modify the durable H01 HTML, execute knitr, change a scientific artifact,
change a package or lockfile, or alter a base Quarto profile.

## Implemented identities

- `scripts/report_harmonization/post_render_gt_html_semantics.R`, SHA-256
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`,
  21,453 bytes;
- `tests/report_harmonization/test_post_render_gt_html_semantics.R`, SHA-256
  `696e3308275d366dcc4aefb8e60c36d7c4c42d02a88402e3d06717b6383d0fae`,
  16,662 bytes; and
- `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`,
  7,480 bytes.

The accepted repair engine remains byte-identical at SHA-256
`7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`.

## Exact profile change

The sole Stage C profile addition is:

```yaml
project:
  post-render: scripts/report_harmonization/post_render_gt_html_semantics.R
```

The actual line is under the existing `project` mapping after `execute-dir`.
Removing exactly that line from the 7,480-byte current profile reconstructs
the accepted 7,404-byte pre-hook profile at SHA-256
`5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`.
The parsed profile still contains exactly 37 positive render sources and nine
explicit exclusions. Their order, the sidebar, `_build/nathealth` output
directory, and every other option are unchanged. `_quarto.yml` remains
`44e4a7435494d570baca6e7b0de75b15be015a52c811c076dd2b8b959d70f59c`;
`_quarto-website.yml` remains
`f0327d16ca5b402893c920d14c32b33975ca8d1e954f1d1e5a1ef5e26313e8f9`.

## Wrapper behavior

The wrapper implements Quarto 1.9.37's documented project-script contract.
It runs from the main project directory and consumes the declared output list
from `QUARTO_PROJECT_OUTPUT_FILES`. When
`QUARTO_USE_FILE_FOR_PROJECT_OUTPUT_FILES` is present, it reads that exact
Quarto-provided list file and ignores the direct variable. It requires the
declared profile output directory to resolve exactly to `_build/nathealth`.

Before any output write it:

- normalizes every declared path, requires every path to exist, rejects
  duplicate paths and paths outside the declared output directory, and marks
  non-HTML files as `IGNORED_NON_HTML`;
- reads HTML as raw bytes, selects only native `gt_table` tables inside unique
  Quarto `tbl-*` endpoints, and distinguishes `NO_GT`, `ALREADY_REPAIRED`,
  unrepaired, and partial or ambiguous states;
- rejects duplicate within-table IDs, nonunique endpoints, partial namespace
  markers, unresolved or non-header `headers` targets, document-wide
  collisions, and unsupported ID references;
- sources the accepted Stage A repair engine and prepares every unrepaired
  target, repaired HTML, and reversible ledger under R's external temporary
  directory, after first verifying the engine's exact accepted SHA-256; and
- validates the complete namespaced-ID and header-resolution postcondition
  for all staged targets before finalizing any declared HTML.

Finalization replaces only declared unrepaired HTML files, reapplies each
original permission mode, and verifies the exact staged bytes. An error in
any finalization step restores every touched file from its retained raw bytes
and exits nonzero. Default operation writes no audit record. An optional
absolute existing `GT_HTML_SEMANTIC_AUDIT_DIR` outside the project and output
trees may retain per-file reversible ledgers and one combined summary for a
separately authorized run.

The wrapper never reserializes the source document. The accepted repair
engine permits only targeted raw-byte substitutions of `id` and `headers`
attribute values inside native gt tables. Visible text, values, rows, cells,
header cells, captions, notes, links, endpoints, spans, classes, styles, and
element order remain protected.

## Focused R 4.6.1 verification

The complete command

```text
Rscript --vanilla tests/report_harmonization/test_post_render_gt_html_semantics.R
```

passes with:

```text
gt HTML post-render wrapper focused test PASS: defective H01 repaired as 36 tables, 783 IDs, 4,798 headers, and 5,581 reversible substitutions; idempotence, indirection, external audit, two-phase validation, rollback, path confinement, profile reversal, and 11 project protections passed.
```

All mutations in this test occur in a temporary project copy. The suite
verifies:

- the exact H01 temporary-copy repair at output SHA-256
  `f96183693bfb3f8dc6570c1666f7e9202a47a9cd3bf9c9f62d1c30c941dfb054`;
- 36 unique table endpoints, 783 ID substitutions, 4,798 reconstructed
  `headers` substitutions, and 5,581 permitted substitutions in total;
- an exact 5,581-row reverse ledger that reconstructs the sealed input SHA-256
  `ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`;
- complete visible-text, parsed-DOM, row, cell, header-cell, link, table,
  permission, and semantic-header preservation;
- direct output-list handling, Quarto's output-list-file indirection, and an
  actual `Rscript` entry-point invocation with simulated Quarto variables;
- an already repaired copy, repeat invocation, no-gt HTML, ignored non-HTML,
  and no project-side default audit output;
- optional external audit output outside the temporary project;
- rejection of output-directory escapes, missing output declarations,
  nonexistent outputs, missing indirection files, an incorrect output
  directory, relative or invalid audit paths, project-internal audit paths,
  repair-engine identity drift, and partial repairs before target mutation;
- prevalidation of all targets before final writes; and
- exact two-file byte and permission rollback after an injected second-file
  finalization failure.

The focused test pins and rechecks the accepted repair engine, current H01
result and companion sources, H01 owner test, current profile, both base
profiles, sealed H01 HTML, stored L10 support CSV, and both accepted H01
reporting manifests. All 11 identities are exact before and after.

The complete H01 reporting command also passes without changing files:

```text
Rscript --vanilla tests/hypotheses/H01/test_h01_reporting_inputs.R
```

with `H01 reporting input and HTML structure tests passed`.

The reusable Stage A temporary-copy test remains byte-identical at SHA-256
`d5d06f831c7b09690b63fbc39f6f37d745fcbb8644197415541d767702523db6`.
It retains the accepted pre-hook profile as historical Stage A execution
context and was not modified or used as the current Stage C profile test. The
new Stage C focused test is the live protection for the post-hook profile.

## Toolchain and static checks

The verified versions are:

- R 4.6.1;
- gt 1.3.0;
- xml2 1.6.0;
- htmltools 0.5.9;
- knitr 1.51;
- digest 0.6.39;
- yaml 2.3.12;
- Quarto 1.9.37; and
- Air 0.4.1.

Both new R files parse under R 4.6.1. Air format checking passes. YAML parsing,
exact profile reversal, render-count and order checks, protected-input checks,
and scoped `git diff --check` pass.

## Preservation and next gate

The H01 result QMD remains
`31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`;
the companion remains
`962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8`;
the H01 focused owner test remains
`ab648ac80bc1c8a149a11bb958fd683b38722487c53179b42b215a2b000e6fd5`;
the reporting manifest remains
`d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`;
and the Stage 3 reporting manifest remains
`08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f`.
The durable H01 HTML remains defective but byte-identical at
`ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`,
as required by this source-only gate.

No render is released by this record. A fresh H01 result render, durable HTML
post-render repair, semantic and visual QA, the H01 companion, and all later
REPORT-017 targets remain held pending independent coordinator acceptance.
