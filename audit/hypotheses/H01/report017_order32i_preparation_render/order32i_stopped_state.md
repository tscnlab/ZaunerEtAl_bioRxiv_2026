# REPORT-017 H01 order 32i stopped-state handoff

Date: 2026-08-20

## Disposition

**STOPPED after the one authorized render.** The render exited with status 0,
all 53 knitr cells completed, Pandoc completed, and the configured semantic
hook reported `REPAIRED`. Read-only verification then found a target-output
defect: the render removed both copied source-data CSVs while retaining their
two reader-facing links. The complete H01 preparation test consequently
failed. In accordance with order 32i, no patch, second render, or loopback
visual QA was attempted.

## Governing identities

- Order:
  `audit/report_harmonization/owner_orders/32i_h01_preparation_provenance_target_render.md`,
  SHA-256 `d8c0009a737db7aff3fd7249a6413a105002d1ebe2dfd395c41729844f19a4f0`.
- Dispatch manifest:
  `audit/report_harmonization/report017_h01_order32i_dispatch_manifest.csv`,
  SHA-256 `e72890b110f0d2cb37a76fc7b8f21b9458e13b981fc02261dbacaedd49227a49`.
- R 4.6.1 dispatch audit: 13/13 paths exact, unique, and non-circular before
  execution.
- Quarto 1.9.37; gt 1.3.0; knitr 1.51.

## Sole render

The one normal-profile command was:

```text
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H01-order32i-semantics.Or8lWE quarto render audit/hypotheses/H01/H01_analysis_preparation.qmd --profile nathealth
```

The command occupied approximately 65 seconds in the execution tool. The
target HTML was created at 2026-08-20 08:50:14 CEST and the semantic hook
completed at 08:50:56 CEST. No concurrent Quarto, Pandoc, or target R process
was present immediately before launch.

The fresh semantic directory was empty at creation, had mode `drwx------`,
and remains retained at:

`/private/tmp/H01-order32i-semantics.Or8lWE`

It contains only:

- `gt_html_semantic_post_render_summary.csv`, SHA-256
  `fb5962780baf042b3048f713110696ec64c17f4f16fe55d21b8e2a09a05ce359`,
  498 bytes;
- `001__build__nathealth__audit__hypotheses__H01__H01_analysis_preparation.html_gt_semantic_ledger.csv`,
  SHA-256
  `edf1d84bf367698cf9596fc3b194601ac1d045d0da1be3bbb5094344a278918f`,
  238,469 bytes.

## Successful contracts

- Semantic disposition: `REPAIRED`.
- Semantic counts: 20 tables, 169 rewritten IDs, 797 rewritten `headers`
  attributes, and 966 total substitutions.
- Reversing the 966-row ledger reconstructed the hook input exactly:
  SHA-256 `4b18c7068886c657c67de275fa2fa18e5562094d779f027cf5d9658fb61a9ffb`,
  685,267 bytes.
- Final target HTML: SHA-256
  `5ab6587465f01f946fcf133f9f81a69168e08fa866f69830c2378e6c3cf250fe`,
  727,310 bytes.
- The 20 native gt endpoints and two figure endpoints are complete, unique,
  and in the exact source order. Both figures have non-empty captions and alt
  text, and their image files exist.
- One top-to-bottom Mermaid source is present.
- The document has no duplicate IDs. All 1,442 explicit table-header tokens
  resolve exactly once to a `th` in their own table. All 1,471 explicit IDREF
  tokens resolve exactly once.
- No cell-output error or warning nodes and no unresolved cross-references are
  present.
- Reciprocal result and companion links, the result registration anchor, both
  registration links, active companion navigation, and all nine registered
  country-coded site names pass.
- No forbidden internal `.qmd`, `_build`, `file://`, or absolute-local reader
  link is present. External HTTPS edit actions remain external.
- Of 1,695 protected paths, 1,694 are byte-identical. The only expected change
  is the rendered target HTML. The accepted result QMD and HTML, profile,
  semantic wrapper and engine, test, handoff, and scientific artifacts remain
  byte-identical.

## Consolidated defects

### H01-ORDER32I-DEF-001: two source-data downloads were removed

The pre-render build contained these files, and the render deleted them:

- `H01_analysis_preparation_files/source-data/H01_preparation_fitted_sample_support.csv`,
  expected SHA-256
  `760e634fd6139b8c6561d185c95fb5c06ef5b41637c7b20f8c61b0e627ff37c7`,
  4,818 bytes;
- `H01_analysis_preparation_files/source-data/H01_preparation_model_frame_retention.csv`,
  expected SHA-256
  `28cc582f2778c849025f2ea77fee2036ce693378630d6f7e172adc0db6bb6d5b`,
  2,860 bytes.

The source-data directory was also removed. The rendered HTML retains both
links, so the link audit reports exactly two failures. The two original source
CSVs under `artifacts/11_source_data/H01/preparation/` remain protected and
unchanged.

### H01-ORDER32I-DEF-002: the rendered QMD copy remains stale

The current source SHA-256 is
`ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`.
The build copy remained at SHA-256
`85d51304a3a5808efa6ec4cf7bded79a07a31ff639a6643ec49be67fb8ed6dcc`.
The render did not refresh this target-owned copy.

### H01-ORDER32I-DEF-003: the preparation manifest is not live-exact

The complete test found 56/62 manifest rows exact. Two target source-data rows
are missing and four rows have changed hashes or sizes:

1. `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R`;
2. `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html`;
3. `_build/nathealth/notebooks/hypotheses/H01.html`;
4. `_quarto-nathealth.yml`.

Rows 1, 3, and 4 are the three previously classified source-only manifest
mismatches. Row 2 is the expected target-HTML change from this render. The
manifest itself remains at its dispatch SHA-256
`69c2215a3c789e31b4b9e820ae1a1c90485a74ec106d4c09269a71d859cdffd5`.
No manifest reseal was authorized or attempted.

## Test and build evidence

- Complete H01 preparation test: exit 1 after 0.352 seconds under R 4.6.1.
  First fail-closed assertion: `all(file.exists(manifest_files)) is not TRUE`.
- Build inventory: 1,118 entries before and 1,115 after.
- Content classification: 1,112 unchanged or mtime-only entries, three normal
  render outputs, and exactly three deletions comprising the source-data
  directory and two CSVs.
- Search and sitemap changes are classified as normal target-render output.
- The two figure PNGs and the shared Bootstrap CSS were byte-identical mtime
  touches only.
- Post-check and post-QA build inventories are identical.

## Visual-QA gate

The secure loopback server was not started. Order 32i permits loopback visual
QA only after all nonvisual checks pass. Because the source-data link and
complete preparation-test contracts failed, no port was bound, no page was
navigated, and no desktop, narrow, or 200% screenshots were taken. This is a
required gate stop, not a visual acceptance.

## Preservation and scope

No H01 source, test, current manifest, handoff, profile, semantic tool,
scientific input, scientific output, model, prediction, bootstrap, R-squared
allocation, package, lockfile, ledger, or manuscript file was changed. No
result page or other target was rendered. No commit, push, upload, or
publication action occurred.
