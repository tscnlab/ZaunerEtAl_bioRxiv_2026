# REPORT-017 H01 order 31e visual-stop independent acceptance

Date: 2026-08-14  
Finding: H01-REPORT017-31E-VIS-001  
Disposition: **ACCEPTED_STOPPED_VISUAL_DEFECT**

## Independent conclusion

The H01 result render and post-render native-gt semantic repair completed
successfully. The existing HTML has 36 semantically complete native gt tables,
10 figure endpoints, unique document IDs, resolved table header references,
and no embedded execution errors. The reversible semantic ledger recovers the
exact pre-hook HTML.

Desktop visual inspection then correctly found a reader-facing wording defect
in the principal raster figure. The legend inside
`fig-h01-model-support` reads **BH-adjusted result**, while the accepted compact
reader term is **FDR-adjusted result**. The caption and alt text already use FDR
terminology. This is a baked image-label defect, not a model, table-semantic,
browser-scaling, or Quarto-hook defect.

The owner stopped before narrow and 200% visual QA, did not repair or rerender,
stopped the loopback server, and left no listener. That stop follows the
controlling REPORT-017 contract.

## Accepted order 31e evidence

- H01 HTML SHA-256:
  `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa`
- owner verification SHA-256:
  `8a37fee0261afb1b74979f749f4665b362b16f7b4f4b5797e93fd6129bed7e77`
- 57-entry owner manifest SHA-256:
  `ee7b568a645f34891b2ea540378a14ae4963609f3ca2846d9c3ef7a2c7c5f0b8`
- semantic-hook summary SHA-256:
  `820fd31cf1449a66cfa1034e90b4980be789b42b403013a65dcf5df4092cdca3`
- reversible semantic ledger SHA-256:
  `94df7b866af366acb44478f50590778f3c446e076c9029481b0f69edcd06d2f9`
- hook disposition and counts: `REPAIRED`, 36 tables, 783 ID changes,
  4,798 `headers` changes, and 5,581 reversible substitutions
- protected reconciliation: only the authorized H01 HTML changed among 1,215
  protected paths; post-QA drift was zero
- loopback lifecycle: server stopped and no listener remained on
  `127.0.0.1:55068`

An independent R 4.6.1 audit verified every row in the owner manifest. The
desktop screenshot confirms the legend mismatch visually.

## Frozen-source suitability check

The current reader report links the accepted METRIC-011 support-matrix source:

- `artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_model_support_figure_source.csv`
- SHA-256 `cf869aa233aca9230a9d295f7efae69fc51c1258a80daf90258d08122f5effc0`

The earlier figure source is:

- `artifacts/11_source_data/H01/stage3/H01_stage3_model_support_figure_source.csv`
- SHA-256 `2054c097bb6b901ebc12491c78082fe5a56ebca2ccc5e2c61afe7e21244c3772`

The read-only R 4.6.1 comparison found 136 rows in each source, unique
metric-by-placement-by-question keys, and exact equality for all plotting
fields: metric order and ID, manuscript metric name, placement label, question
order and ID, question label, support status, and support symbol. Differences
are confined to the stored statistic, raw p-value, log-likelihood, and adjusted
p-value columns. None of those numerical columns is mapped to colour, symbol,
position, order, facet, or label in this support matrix.

Audit evidence:

- `/private/tmp/H01_VIS001_AUDIT.Ynn9ZM/compare_support_sources.R`, SHA-256
  `b13593dbc692da4b330de4d63fbf8e755109ad2439d2782f5054feae40dc5d9e`
- `/private/tmp/H01_VIS001_AUDIT.Ynn9ZM/support_source_comparison.csv`, SHA-256
  `b6d4caa0be10581d6b9580e3eaf893c90e15147366ecf94ab737cef547a23592`

The accepted current source is therefore suitable for a display-only refresh
that preserves every plotted scientific state.

## Proposed bounded display repair gate

Before any new Quarto render, the H01 owner should receive a separate
display-artifact repair order with the following exact boundary:

1. In `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R`, change only
   the legend-title literal `BH-adjusted result` to `FDR-adjusted result` so a
   future complete rebuild cannot reintroduce the stale reader term.
2. Add a dedicated H01 display-refresh script that reads only the frozen
   METRIC-011 source above and writes only
   `H01_stage3_model_support.png` and `H01_stage3_model_support.svg`. It must not
   source or execute the full Stage 3 builder, read a fitted model, or write a
   table, source-data file, diagnostic, or other figure.
3. Preserve all 136 plotted cells, their order, support statuses, symbols,
   colours, facets, labels, theme, physical dimensions, and 320 dpi PNG
   resolution. The current PNG is 3,360 by 2,368 pixels. Only the legend title
   may change visibly.
4. Add a focused R 4.6.1 test that pins the frozen input, proves the plotting
   field equality and unique keys, checks the one-literal builder change,
   verifies PNG/SVG dimensions and visible FDR wording, and rejects visible BH
   wording. Require the PNG image-difference region to be confined to the
   legend-title area and the normalized SVG display structure to be unchanged
   apart from that title.
5. Record pre/post PNG, SVG, builder, refresh-script, source-data, package, and
   visual-QA identities in a non-circular H01 display-repair manifest.
6. Update the current Stage 3 and worker manifests truthfully for the changed
   builder, PNG, SVG, and new refresh script. Preserve the historical
   REPORT-016 protected inventory and reconciliation manifest unchanged.
7. Update only the REPORT-016 focused test classification needed to allow
   these exact display-only paths with exact pre/post identities. Continue to
   require every other protected scientific artifact byte-for-byte.
8. Run the complete H01 reporting and REPORT-016 tests under R 4.6.1. No Quarto
   render is authorized at this gate.

The repair must not change data, source CSVs, models, fits, estimates,
intervals, p-values, FDR decisions, sample definitions, diagnostics, QMDs,
captions, alt text, the semantic hook, the profile, central ledgers, or any
other image.

## Later render gate

Only after independent acceptance of the display-artifact repair should a
separate order authorize one fresh H01 result render. That later render must
run the accepted post-render semantic hook, reproduce the 36-table semantic
postconditions, verify eight FDR and zero BH table labels, confirm the repaired
figure legend, and complete desktop, 708-pixel, and 200% visual QA. The H01
companion and every later hypothesis target remain held.

## Current queue state

Order 31e is accepted as a correct stopped checkpoint, not as a completed H01
reader integration. H01 remains the sole active REPORT-017 document. No H03
source order or H02 render should begin until the H01 display repair and its
subsequent acceptance reach the coordinator-defined serial safe point.
