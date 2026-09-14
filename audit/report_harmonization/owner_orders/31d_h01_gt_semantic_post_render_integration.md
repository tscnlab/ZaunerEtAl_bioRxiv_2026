# REPORT-017 order 31d: gt HTML semantic post-render integration gate

Date: 2026-08-14

Owner: report-harmonization coordinator

Status: **Released for source-only Stage C implementation and temporary-copy
verification. No Quarto render or durable HTML repair is authorized.**

## Accepted prerequisites

The coordinator independently accepted Stage A, Stage B, and order 31c. The
accepted inputs to this gate are:

- repair engine
  `scripts/report_harmonization/repair_gt_html_semantics.R`, SHA-256
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- H01 result QMD, SHA-256
  `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`;
- H01 preparation and provenance companion, SHA-256
  `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8`;
- H01 focused reporting test, SHA-256
  `ab648ac80bc1c8a149a11bb958fd683b38722487c53179b42b215a2b000e6fd5`;
- reporting manifest, SHA-256
  `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`;
- Stage 3 reporting manifest, SHA-256
  `08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f`;
- sealed pre-render H01 HTML, SHA-256
  `ceb68cc24bd24cabdbab94aabe770c75a7ce0d3942f5c099064ed80eecf6da72`;
  and
- pre-hook Nature Health profile, SHA-256
  `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`,
  7,404 bytes.

## Authorized files

This gate may:

1. create
   `scripts/report_harmonization/post_render_gt_html_semantics.R`;
2. create
   `tests/report_harmonization/test_post_render_gt_html_semantics.R`;
3. add only the profile-specific post-render script declaration under
   `project` in `_quarto-nathealth.yml`; and
4. create directly dependent harmonizer-owned order, verification, and
   non-circular manifest records.

No other source, configuration, package, lockfile, scientific artifact,
rendered HTML, ledger, manuscript, commit, or push change is authorized.

## Wrapper contract

The wrapper must run from the main project directory through Quarto's
documented post-render mechanism. It must consume only
`QUARTO_PROJECT_OUTPUT_FILES`, including the documented
`QUARTO_USE_FILE_FOR_PROJECT_OUTPUT_FILES` indirection. It must require
`QUARTO_PROJECT_OUTPUT_DIR` to resolve exactly to `_build/nathealth`, normalize
every declared output, reject missing files and path escapes, and ignore
non-HTML files.

For HTML, the wrapper must:

- no-op when no native gt table exists;
- no-op as `ALREADY_REPAIRED` when the complete deterministic namespace and
  header-resolution postcondition already holds;
- reject partial, colliding, or ambiguous states before writing;
- stage and validate every repair in temporary files before replacing any
  declared output;
- preserve file permissions and restore exact originals if finalization
  fails;
- change only native-gt `id` and `headers` attribute values;
- preserve visible text, values, order, captions, notes, links, table
  endpoints, spans, classes, styles, QMDs, and scientific artifacts; and
- emit concise target, hash, table, ID, header, and disposition status.

The default path writes no audit output. A specifically authorized audit run
may set an absolute existing `GT_HTML_SEMANTIC_AUDIT_DIR` outside both the
project and output trees to retain per-file reversible ledgers and one
combined summary. R 4.6.1 and gt 1.3.0 are mandatory.

## Focused verification contract

All test mutations must be confined to temporary copies. The focused suite
must cover:

- the defective sealed H01 HTML with the accepted 36-table, 783-ID,
  4,798-header, and 5,581-total reversible outcome;
- an already repaired copy, repeat invocation, no-gt HTML, and ignored
  non-HTML output;
- direct and file-list-indirected Quarto environment variables;
- an optional external audit directory and exact reverse ledger;
- output-directory escape, missing outputs, nonexistent outputs, partial
  repair, invalid audit directories, and incorrect output-directory failures;
- all-target prevalidation before final writes and exact rollback on an
  injected finalization failure;
- visible-text, DOM, count, native-table, header-resolution, and permission
  preservation; and
- exact profile reversal, 37 render sources, unchanged navigation order,
  unchanged base profiles, R parsing, Air formatting, YAML parsing, protected
  identities, and scoped whitespace and diff checks.

The repair engine and current H01 source, companion, test, manifests, durable
HTML, stored L10 display source, and profile must be pinned as execution
context. Mutable source identities must not be embedded in the reusable repair
algorithm.

## Hold

Do not run Quarto. Do not modify the durable H01 HTML. The H01 result rerender,
H01 companion, and every later REPORT-017 target remain held pending
independent coordinator acceptance of this Stage C source-only gate.
