# REPORT-017 H01 order 32i stopped-state independent acceptance

Date: 2026-08-20

Status: STOPPED STATE ACCEPTED. The H01 result remains accepted. The H01
companion is not yet accepted because two reader download targets are absent.

## Independently reproduced state

The owner ran exactly one normal-profile target render for
`audit/hypotheses/H01/H01_analysis_preparation.qmd`. R 4.6.1 and Quarto
1.9.37 completed all 53 cells and Pandoc with exit status 0. The configured
semantic hook reported `REPAIRED` for 20 tables, 169 IDs, 797 `headers`
attributes, and 966 reversible substitutions.

The final companion HTML is
`_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html`,
SHA-256 `5ab6587465f01f946fcf133f9f81a69168e08fa866f69830c2378e6c3cf250fe`,
727,310 bytes. Reversing the retained semantic ledger reproduces the hook
input SHA-256
`4b18c7068886c657c67de275fa2fa18e5562094d779f027cf5d9658fb61a9ffb`.
The harmonizer independently verified the retained external summary and
ledger identities.

The owner stopped correctly before loopback QA. The owner record is
`audit/hypotheses/H01/report017_order32i_preparation_render/order32i_stopped_state.md`,
SHA-256 `b36ae6f42509d2dfd2c611473190b101b70d339a3c79c9029487b4075b16366d`.
Its 44-row non-circular evidence manifest is SHA-256
`bdf00b7a3035308f743961d272b755c1df6901de4c75f493d487937f0fe20440`.
Independent R 4.6.1 verification passed all 44 identities and byte counts.

## Accepted successful checks

The current HTML has exactly 20 native gt-table endpoints and two figure
endpoints in source order. Captions and alt text are present. There is one
top-to-bottom Mermaid source, zero duplicate IDs, 1,442 of 1,442 table-header
tokens resolve, and 1,471 of 1,471 IDREF tokens resolve. Reciprocal links,
registration links, active navigation, and all nine country-coded study sites
pass. There are no cell error or warning nodes, unresolved references, or
forbidden local reader links. Of 1,695 protected paths, 1,694 are unchanged;
the only expected change is the companion HTML. The accepted result QMD and
HTML, companion QMD, profile, semantic tools, test, handoff, and scientific
artifacts remain exact.

## Confirmed render-integration defects

### H01-ORDER32I-DEF-001: missing source-data downloads

The target render rebuilt `H01_analysis_preparation_files` and removed its
custom `source-data` subdirectory. The HTML still links to two files in that
directory. The missing copies must be byte-identical to the protected source
CSVs:

- `H01_preparation_fitted_sample_support.csv`, SHA-256
  `760e634fd6139b8c6561d185c95fb5c06ef5b41637c7b20f8c61b0e627ff37c7`,
  4,818 bytes;
- `H01_preparation_model_frame_retention.csv`, SHA-256
  `28cc582f2778c849025f2ea77fee2036ce693378630d6f7e172adc0db6bb6d5b`,
  2,860 bytes.

Read-only source inspection confirms that the existing
`build_h01_preparation_report_manifest.R` helper is the post-render step that
creates these two copies. Order 32i intentionally did not run it.

### H01-ORDER32I-DEF-002: stale rendered QMD copy

The build copy remains SHA-256
`85d51304a3a5808efa6ec4cf7bded79a07a31ff639a6643ec49be67fb8ed6dcc`,
while the accepted authoring QMD is SHA-256
`ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`.
The existing helper inventories the build copy but does not synchronize it.

### H01-ORDER32I-DEF-003: current preparation manifest not resealed

The 62-row preparation manifest has six live mismatches: the two missing
downloads, the newly rendered companion HTML, and three previously accepted
current identities for the Stage 3 builder, result HTML, and profile. This is
a current-provenance integration issue, not scientific drift.

## Bounded next action proposed for coordinator authorization

Use one no-render continuation. Extend only the existing H01 preparation
manifest helper so it synchronizes the accepted authoring QMD to the build QMD
with byte-identity checks, while retaining its existing source-data copy
checks. Run that helper once to restore the two downloads and write the fully
current 62-row preparation manifest. Reseal only the directly dependent
current worker-manifest rows. Then run the complete preparation, reporting,
and REPORT-016 checks, the exact link and semantic checks against the existing
HTML, and the deferred secure-loopback visual QA. Preserve all historical
evidence, scientific artifacts, QMDs, profile, result HTML, and semantic
outputs. No Quarto rerender is needed or proposed.

Until that package is authorized and accepted, H01 remains the sole render
path and every later REPORT-017 render remains held.
