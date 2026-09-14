# H06 REPORT-017 order-37 bounded source audit

Date: 2026-08-14

Scope: source-only harmonization of the main hourly H06 result, its
preparation/provenance companion, and the H06 worker handoff.

## Preflight

Every owner-scoped order pin matched before editing:

- result source: `692c28ce165eda27e0b85dbb73f2e834a31a188ae8eefe9f1391980bd5641459`, 56,355 bytes;
- companion source: `205eac1ee6d878353a2b23c3741e18ef7480765882d6e0baad0808963b3aa731`, 55,895 bytes;
- worker handoff: `5080334fa1f1ac82c60359111b5aa44065cdf2075e3a7a672fd9c225e3ba3829`, 24,781 bytes;
- Stage 2 test: `489115354c11de17b627e4e2cb28cef9f54654a50756a7d4897dda3080b29b89`, 15,916 bytes;
- Stage 3 test: `a6e3e307b023588b475587876be86eeb9c0f7b9d9d1597df946dd112458940aa`, 35,771 bytes;
- preparation test: `2b9f02f7caa448a3c7fdb88b0febc5ce306239002ebe220b6f5f7a7c4285a4fc`, 12,918 bytes;
- Stage 2 manifest: `2407f2045d960be1025dbd5e338d0df9a733bd4caf2afc29f16a9680fb355752`, 227 data rows;
- Stage 3 manifest: `d77054228581a2700f80f0c571536ae2799a7e5ac0f6869d189767e0dfe3bb21`, 301 data rows; and
- preparation manifest: `db976477b9cdbce2a6d4575e382b2f04062e8834c086f1d82cb25d7e8a2176e4`, 315 data rows.

## Source revision

The final result source is
`938f1a253bffefa99947783dc1ae4c739f92ad82fb224a4d8626d91bcebea061`,
60,541 bytes. The final companion source is
`f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`,
59,613 bytes. The final handoff is
`5bf8dc5a5ee0a27f15edeceef1aaac7d10fd3d0bbf1895517fea8451cdea99a3`,
10,408 bytes.

The result now places `fig-h06-core-effects` first and
`tbl-h06-primary-effects` immediately after it. It retains exactly 11
cross-referenced tables, two native formula displays, six figures, and 20
labelled R chunks. The companion retains exactly 30 tables, three figures, 34
labelled R chunks, and its complete top-down Mermaid map. Both sources set
`lightbox: true`.

Only reader structure, definitions, dynamic navigation, disclosure placement,
and display-label mappings changed. Raw stored states, fail-closed assertions,
formulas, filters, joins, orderings, prepared-object references, scientific
values, artifact references, and source-data references remain protected.

The hourly analysis remains the main H06 result. H06 daily remains separate,
complementary participant-day evidence. Near-eye remains primary and chest
remains complementary non-ocular evidence.

## Scientific preservation

No data were imported, transformed, summarized, or rewritten during this
order. No QMD was executed. No model was fit, refit, deserialized, predicted
from, compared, diagnosed, bootstrapped, simulated, or resampled. No p-value,
FDR result, contrast, curve, sensitivity, residual result, figure, source CSV,
or scientific artifact was recalculated or regenerated.

The existing historical manifest mismatch sets remain expected at four Stage
2 paths, five Stage 3 paths, and four preparation paths. The source-only test
checks the exact path sets rather than treating them as new defects.

The current HTML files remain stale context. They are not evidence that the
revised sources rendered successfully.

## Deferred work

The four baked-label figure repairs in the sealed owner order remain deferred.
No pixel, vector, plotted quantity, curve, interval, point, support bar, order,
symbol, colour, facet, null line, dimension, or DPI changed. REPORT-017 keeps
both H06 renders on hold until that separate repair and serial render release.

The exact one-shot source-only result, elapsed time, R version, package version,
defect list, and non-circular manifest audit are written by
`tests/hypotheses/H06/test_h06_report017_source_harmonization.R` to the same
evidence directory.
