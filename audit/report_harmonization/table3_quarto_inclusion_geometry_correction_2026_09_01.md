# Table 3 Quarto-inclusion geometry correction

Date: 2026-09-01

Status: **SOURCE-ONLY ACCEPTED; RENDER AND RESEAL DEFERRED**

## Reason

The manuscript integration check showed that Quarto processed the embedded
native `gt` table because its table element carried
`data-quarto-disable-processing="false"`. During inclusion, that processing
discarded the native seven-column `colgroup` and replaced the accepted table
base size with the surrounding document size. The result redistributed Table
3 columns despite the fixed 1,160 px table width.

## Bounded correction

- Set `data-quarto-disable-processing="true"` on the harmonizer-owned Table 3
  fragment and its standalone preview.
- Retain the accepted fixed seven-column geometry:
  `135 / 205 / 135 / 155 / 125 / 205 / 200 px`.
- Retain the 1,160 px table width and 145 × 82 px density thumbnails.
- Set the native Table 3 body/header base to 12 px.
- Add the manuscript reader-table type contract to both selection QMDs: 12 px
  table base, 125% title, and 90% source notes/footnotes.
- Replace the selection page's older 132 rem Table 3 minimum width and
  150 × 100 px thumbnails with the accepted 1,160 px and 145 × 82 px geometry.
- Harmonize the MDER source note with manuscript-facing language:
  “The MDER uses the mean of viable minute-level ratios in both the descriptive
  summary and geographic-association model cells.” This removes the internal
  task label `H01` and the workflow term “accepted.”

Apart from that source-note wording, no value, metric order, sample, statistic,
interval, p-value, R² quantity, image payload, table hierarchy, or scientific
claim changed.

## Source transitions

| Path | Pre-edit SHA-256 | Post-edit SHA-256 |
|---|---|---|
| `audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html` | `2f7f6f475d9fe55ee37da3c73aa12474e347ec4619889278fbca0aeab2f40e1c` | `93bcec9b54a4d7972afe8989b4d8d0fb66ca1f7ed0da21bda5cbede6d99c6b96` |
| `audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate-preview.html` | `f5519d056e32e698b8d4a70ef9da332b2e81386e2795951587d208b5f30fb07d` | `72d4c5f7f7e4753cda36d3614446e5f87806462d943f5fa7812154ac06bdf388` |
| `audit/manuscript_nature_health/manuscript_figure_table_selection.qmd` | `462e1610233185cf3655443cafdc1fd8009ec17646187cae806636815b06e441` | `ee5f0844a404e95b858a7b175f8a1e1c72aca6b74891110e60c9c8b34f616d70` |
| `audit/manuscript_nature_health/manuscript_figure_table_selection_all_gt_candidate.qmd` | `462e1610233185cf3655443cafdc1fd8009ec17646187cae806636815b06e441` | `ee5f0844a404e95b858a7b175f8a1e1c72aca6b74891110e60c9c8b34f616d70` |

## Reader-language convergence after the geometry seal

| Path | Geometry-sealed SHA-256 | Final source SHA-256 |
|---|---|---|
| `audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html` | `93bcec9b54a4d7972afe8989b4d8d0fb66ca1f7ed0da21bda5cbede6d99c6b96` | `081d0278badfb1f40d29ffd4cb8ac18b5a285f049323f9c5c2142eede7f727e0` |
| `audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate-preview.html` | `72d4c5f7f7e4753cda36d3614446e5f87806462d943f5fa7812154ac06bdf388` | `427a5826534ad3471000e920f361bf06b500b9bfc19234bda07aadda42550f07` |

The two selection QMDs were unchanged by the reader-language convergence and
remain identical at
`ee5f0844a404e95b858a7b175f8a1e1c72aca6b74891110e60c9c8b34f616d70`.

## Verification

R 4.6.1 checks passed for:

- one processing-disable attribute and no processing-enable attribute in each
  Table 3 HTML endpoint;
- one exact accepted `colgroup` in each endpoint;
- one 12 px native table base in each endpoint;
- identical selection QMDs with the 12 px type contract and accepted Table 3
  geometry;
- absence of the retired 132 rem and 150 × 100 px selection overrides; and
- exact reverse reconstruction of all four pre-edit SHA-256 identities using
  only the authorized presentation substitutions.

The final reader-language check additionally verified the exact source-note
sentence in both HTML endpoints, absence of the superseded wording, and exact
reverse reconstruction of both geometry-sealed endpoint identities using only
the single authorized sentence substitution.

No QMD was executed and no Quarto or report render, artifact rebuild, manifest
rewrite, package change, or serial-queue action occurred.
