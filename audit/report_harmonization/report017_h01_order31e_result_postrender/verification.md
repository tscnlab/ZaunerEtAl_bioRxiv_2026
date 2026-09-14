# REPORT-017 H01 order 31e owner verification

## Disposition

**STOPPED_VISUAL_DEFECT**

The sole authorized H01 result render completed successfully, the gt semantic hook repaired the expected HTML semantics, and all completed structural, semantic, manifest, link, navigation, and preservation checks passed. Desktop visual QA then found one unexpected reader-facing defect in the principal figure: its embedded raster legend says **BH-adjusted result** instead of **FDR-adjusted result**. Work stopped before the narrow and 200% visual checks, and before any repair or second render.

## Render and semantic repair

- Final H01 HTML SHA-256: `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa`
- Final H01 HTML bytes: 1,626,484
- Hook disposition: `REPAIRED`
- Native gt tables: 36
- Internal-ID substitutions: 783
- Reconstructed `headers` substitutions: 4,798
- Total permitted substitutions: 5,581
- Reverse-ledger result: exact recovery of pre-hook SHA-256 `317d2ea152f4c8250c59f14f342192549acb2ae6d99e50765d13501df78bbfe3`
- Visible text, normalized DOM, table structure, captions, notes, links, and counts across the hook boundary: preserved

## External reversible audit evidence

Directory retained intact: `/private/tmp/H01_REPORT017_31e.owP2my`

- Summary: `gt_html_semantic_post_render_summary.csv`, SHA-256 `820fd31cf1449a66cfa1034e90b4980be789b42b403013a65dcf5df4092cdca3`, 459 bytes
- Ledger: `001__build__nathealth__notebooks__hypotheses__H01.html_gt_semantic_ledger.csv`, SHA-256 `94df7b866af366acb44478f50590778f3c446e076c9029481b0f69edcd06d2f9`, 1,620,684 bytes
- Directory contents: exactly one combined summary and one H01 reversible ledger
- Directory mode: 700

## Preservation

- Protected inventory: 1,215 paths
- Authorized protected change: only `_build/nathealth/notebooks/hypotheses/H01.html`
- Post-QA protected drift: zero
- Build inventory: 1,135 entries before and after, comprising 829 files and 306 directories
- Build symlinks: zero
- Expected build effects were limited to the target HTML, navigation/search metadata, a refreshed accepted Stage 3 manifest copy, directory mtimes, and one byte-identical CSS mtime update.
- No model, fit, prediction, bootstrap, resampling, or scientific artifact regeneration occurred.
- No source, test, profile, companion, shared configuration, dependency, lockfile, ledger, manuscript, commit, or push change occurred during this order.

## Reader and visual QA

The completed reader-semantic audit found 36 native gt tables, 10 figure endpoints, 203 reader links, 36 exact deviation anchors, zero embedded errors, and only the known DOC-001 Supplementary information hold. External GitHub Edit actions were treated as external links.

At 1440 by 1000, the document had no page-level horizontal overflow. All 36 tables fit without desktop overflow. Minimum measured table-cell text was 10 px, equal to 7.5 pt. The principal table was readable.

Visual finding `H01-REPORT017-31E-VIS-001` is documented in `visual_stop_finding.json` and `visual_qa_status.md`. The 708 by 1000 and 200% checks remain incomplete because the order required an immediate stop.

## Required next authorization

A separate, bounded display-only repair should regenerate the stored principal support figure from accepted stored source data, changing only the legend label from **BH-adjusted result** to **FDR-adjusted result**. It should then receive a new single-target render and visual-QA authorization. No scientific calculation or model refit is indicated.
