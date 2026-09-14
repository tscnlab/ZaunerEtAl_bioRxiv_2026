# H04 revision 3 selection integration

Date: 2026-09-01

Status: **SOURCE-ONLY INTEGRATED; SELECTION RENDER HELD**

## Accepted owner inputs

- H04 result QMD:
  `243896d4c22f68d23027f77f3721882e0a3d55274e67014e75d6ff55e2e243af`
- accepted Figure 3 PNG:
  `22d402974fc0df26c77536e5db8af166e87637f2192ea4cc4f01da2d98ebb122`
- accepted Figure 3 SVG:
  `012453debcd7994ab8b8437bd1b829a4935b26d97803963c6621ee2093bd72dd`
- accepted caption:
  `a2f55a592ee759237497c7ac5197c54132862f25cd4625f829ebafc84471ae36`

The H04 owner and coordinator independently accepted the display revision.
The reader-facing response option is exactly `Other`. The frozen internal
factor key remains unchanged for reproducibility.

## Bounded selection changes

- Replaced the selection PNG and SVG with byte-identical copies of the
  accepted H04 revision 3 assets.
- Replaced the Figure 3 caption with the accepted caption text, preserving
  only HTML bold markup for panel letters.
- Updated the local coordination note and display-order/status rows from the
  superseded revision 2 request to accepted revision 3 wording.
- Replaced `Other/unspecified` with `Other` in the directly dependent Figure 3
  selection wording.
- Updated only the two H04 asset rows in
  `figure_table_selection_assets/selection_asset_manifest.csv`.

No other selected asset, scientific value, endpoint, internal factor key,
manuscript file, or accepted HTML was changed.

## Selection transitions

| Path | Pre-edit SHA-256 | Post-edit SHA-256 |
|---|---|---|
| `audit/manuscript_nature_health/manuscript_figure_table_selection.qmd` | `ee5f0844a404e95b858a7b175f8a1e1c72aca6b74891110e60c9c8b34f616d70` | `0f267a8721b404918f092e3405ba428182105286aee977ad46c4c892e6d11826` |
| `audit/manuscript_nature_health/manuscript_figure_table_selection_all_gt_candidate.qmd` | `ee5f0844a404e95b858a7b175f8a1e1c72aca6b74891110e60c9c8b34f616d70` | `0f267a8721b404918f092e3405ba428182105286aee977ad46c4c892e6d11826` |
| `audit/manuscript_nature_health/figure_table_selection_assets/H04_manuscript_figure3_selection_candidate.png` | `f7e85d44db0d80b9102ffaac0f9a3f4c1dfdbe3c39074fdfaff333dc3039f4ec` | `22d402974fc0df26c77536e5db8af166e87637f2192ea4cc4f01da2d98ebb122` |
| `audit/manuscript_nature_health/figure_table_selection_assets/H04_manuscript_figure3_selection_candidate.svg` | `9acc8907c5244a6d4557a260058060096c7de40f05f0aea235eb6d4b0dc4869b` | `012453debcd7994ab8b8437bd1b829a4935b26d97803963c6621ee2093bd72dd` |
| `audit/manuscript_nature_health/figure_table_selection_assets/selection_asset_manifest.csv` | `dca63a67fee2084bfc8c99649825ffe94a454c385cef02e83cf01504cf792aad` | `79cf2cfb5471618c4c28e6234ad873370aa96d409cbba6dedeb7de53e910dea4` |

The held accepted HTML remains unchanged at
`ad1b29613f2e418e3d61b995993891f0804d523140b5e590bee059c08e92c509`.
The prior completion manifest remains unchanged at
`8af68f98c6395358c217344ce37121c2ca7bd3b40d85e5af391d8b7a1702e3e8`
until the coordinator performs the single serial render and reseal.

## Source-only verification

- Both selection QMDs are byte-identical.
- The selection PNG and SVG are byte-identical to the accepted H04 inputs.
- The caption text is identical to the accepted caption after normalizing only
  Markdown versus HTML bold markers.
- `Other/unspecified` and `Other or unspecified` are absent from both selection
  QMDs.
- The exact accepted `Other` caption sentence is present in both selection
  QMDs.
- The asset manifest contains the exact accepted H04 hashes and byte sizes.
- The SVG passes XML validation.
- The PNG is readable at 4,725 by 7,063 pixels.
- `git diff --check` passes for all edited text files.

No R, knitr, Quarto, Pandoc, model, or scientific computation was run.
