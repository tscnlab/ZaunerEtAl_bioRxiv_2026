# Selection integration repair and replacement-render release

Date: 2026-09-01

Status: **SOURCE REPLAY AND TEMPORARY RENDER CHECKS PASS**

## Scope

This record covers the bounded source-only repair of the Nature Health figure
and table selection document after Table 3 approval. The repair:

1. preserves the approved Table 3 order used by the descriptive table:
   Duration, Dynamics, Exposure history, Level, Spectrum, Timing;
2. namespaces the four remaining raw `gt` fragments so every table ID and
   `headers` reference is unique in the combined document;
3. refreshes the accepted-output, planning-source, semantic, and selected-asset
   inventories against current owner source postimages;
4. updates the structural checker to the current 20-fragment, 23-table design;
5. performs a no-execute Quarto render to a temporary filename; and
6. releases the canonical replacement render to the coordinating task.

No analysis, accepted estimate, interval, p-value, model, hypothesis source,
manuscript source, or Supplementary Information source was modified or rerun.

## Toolchain

- R 4.6.1
- gt 1.3.0
- Quarto 1.9.37

## Selected preimages

| Artifact | SHA-256 before repair |
|---|---|
| Selection QMD | `0f267a8721b404918f092e3405ba428182105286aee977ad46c4c892e6d11826` |
| Table 3 fragment | `392ebbff583ab1ad44177979214c491f243de45715e9b1057c4048d66982d128` |
| H02 near-eye Shapley fragment | `28a6588de9294bac1a1d2b3f346d10ae4a6ae3d9b20c40af741062d998fe043a` |
| H02 chest Shapley fragment | `ba91d09301b7d9e6a7a5b5c0d85643a06d116bcf9b2ea553c555bafbcffb09d9` |
| Person-level synthesis fragment | `2f9d810b7bde443181f73c3bb16d81dff68363aae177e7db2b7a9a3e01be4b41` |
| Accepted-output inventory | `9e47fe5f5a0d18f4e2ddb5652957030139cdefc80dd01bf1b532e4ed318a87c3` |
| Planning-source inventory | `b1481e09bb6b99f1708a09b4bad22cac400627965fd52ac5ba8b109e5f11a969` |
| Semantic summary | `1b6ff4e07b6c80fa480f6b8f30bb40333bbc47af364132516487306dbd3ca00c` |
| Semantic reverse ledger | `895be65aad2f20895c1ad75850689ce390ae1824430585378d6fd9c48d0ccf8f` |
| Selection-asset manifest | `79cf2cff9610cd9b6f7c69dece95ef44630c07f2256e74103598888680061fb2` |

## Current postimages

| Artifact | SHA-256 after repair |
|---|---|
| Selection QMD | `0f267a8721b404918f092e3405ba428182105286aee977ad46c4c892e6d11826` |
| Table 3 fragment | `d50b25afae95a95d61641349116e504a2bbf06780b43a46b195ac468246e8dc2` |
| H02 near-eye Shapley fragment | `1147881a649557c66e9f494193bbe521ef429eec533e5c3787e41b9817bb0a28` |
| H02 chest Shapley fragment | `1fd4579929dcacccbd6258e007f29367d9738d1a3b162abfe23936fc922ac3d8` |
| Person-level synthesis fragment | `6831c15b00f9e89b676f9aec846ce2c866bc28b51b541f0080c49d250e7bdcf2` |
| Accepted-output inventory | `8dd3ccb0fcad52bdfd34f2fb24855588b94c24086ecf031fea976be8a11fc30a` |
| Planning-source inventory | `b9019423abfc66b54812a2a8a1a2ec49f7d41e5ffce4cfcdb9f07cb2ecfa469b` |
| Semantic summary | `e5d28a6bde1495cd4142e64636b9b98a659e432a968c9db666490dd1f075b0ef` |
| Semantic reverse ledger | `691b1e088c6f85822f91b44c564eab79a4429120b98372bba10afb7093cfa53b` |
| Selection-asset manifest | `b25306a5e395fd83f0daf493a37e1a2abfa5ae92ecf2bab59f0211796cd7e8a1` |
| Temporary integrated HTML | `288f1d372935202840d617ed21f613b1a82c38700823cc914688e35c005bda4e` |

The selected-asset manifest contains 33 unique current paths. It includes all
20 selected table fragments, the four selected figure inputs, the three Brown
assets, and six inventory or semantic artifacts.

## Reversible semantic repair

The integration replay classified 16 fragments as already repaired and four
as repaired in this pass. It made 259 deterministic ID and `headers`
substitutions. For all 20 fragments, the reverse replay reproduced the exact
preimage SHA-256. The repaired fragments and substitution counts were:

| Fragment | Substitutions |
|---|---:|
| Table 3 | 135 |
| H02 near-eye Shapley | 34 |
| H02 chest Shapley | 34 |
| Person-level synthesis | 56 |

The complete row-level proof is stored in
`audit/manuscript_nature_health/figure_table_selection_assets/table_preview_semantic_ledger.csv`.

## Commands and results

```text
Rscript --vanilla scripts/report_harmonization/replay_manuscript_figure_table_selection_integration.R
MANUSCRIPT_SELECTION_INTEGRATION_REPLAY=PASS fragments=20 repaired=4 substitutions=259 manifest=33 R=4.6.1 gt=1.3.0

Rscript --vanilla scripts/report_harmonization/check_manuscript_table3_gt_candidate_revision.R
TABLE3_GT_CANDIDATE_REVISION=PASS checks=14

Rscript --vanilla scripts/report_harmonization/check_remaining_manuscript_gt_candidates.R
REMAINING_GT_CHECK=PASS checks=15

quarto render audit/manuscript_nature_health/manuscript_figure_table_selection_integration_check.qmd --to html --no-execute

NATHEALTH_SELECTION_QMD=audit/manuscript_nature_health/manuscript_figure_table_selection_integration_check.qmd \
NATHEALTH_SELECTION_HTML=audit/manuscript_nature_health/manuscript_figure_table_selection_integration_check.html \
NATHEALTH_SELECTION_QA_DIR=/private/tmp/nathealth-selection-integration/qa \
Rscript --vanilla scripts/report_harmonization/check_manuscript_figure_table_selection.R
MANUSCRIPT_DISPLAY_SELECTION=PASS checks=39 tables=23 gt=20 images=56 headers=2882 html=288f1d372935202840d617ed21f613b1a82c38700823cc914688e35c005bda4e bytes=30537097 R=4.6.1
```

The checker verified zero duplicate IDs and required every `headers` token to
resolve exactly once within its own table. It also verified the exact Table 3
descriptive group order and metric order, 17 density thumbnails, accessible
table-scroller labels, and current author-decision and display inventories.

## Visual boundary and release

The in-app browser security policy blocked direct navigation to the temporary
local filename. No workaround was attempted. The canonical replacement is
therefore released to the coordinator after the full 39-check temporary-render
gate. Visual inspection will be performed on the canonical page already open
in the app after that single replacement render is complete.

The coordinator produced the canonical replacement at
`audit/manuscript_nature_health/manuscript_figure_table_selection.html`. Its
SHA-256 is
`288f1d372935202840d617ed21f613b1a82c38700823cc914688e35c005bda4e`,
which is byte-identical to the validated temporary render. The exact temporary
QMD, complete HTML, and failed root-level partial HTML were then removed. They
are not recoverable from this workspace, but the validated result is preserved
as the canonical HTML.
