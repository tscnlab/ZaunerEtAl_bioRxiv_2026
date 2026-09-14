# H01 order 31e visual QA status

Status: **STOPPED_VISUAL_DEFECT**

## Completed checks

- Served the exact H01 result route from a read-only server rooted at `_build/nathealth`, bound only to `127.0.0.1:55068`.
- Inspected the page in the in-app Browser at 1440 by 1000 with device pixel ratio 2.
- Confirmed document scroll width 1,425 px equals client width 1,425 px, with no page-level horizontal overflow.
- Measured 36 tables and 10 figures.
- Confirmed zero desktop table overflow and no required desktop table scrollers.
- Measured minimum table-cell text at 10 px, equal to 7.5 pt, and captions at 15.3 px.
- Inspected the principal publication table and all ten figure endpoints at the desktop viewport.
- Retained desktop overview, principal-table, figure, and diagnostic-tab screenshots.

## Blocking finding

`H01-REPORT017-31E-VIS-001`: the raster legend embedded in `fig-h01-model-support` reads **BH-adjusted result**. The accepted reader-facing compact-display terminology is **FDR-adjusted result**. The figure caption and alt text already use FDR terminology.

The same wording is embedded in the stored source PNG at `artifacts/10_figures/H01/stage3/H01_stage3_model_support.png`, SHA-256 `601c65eebff8260b9c19d6f5e3a6054799e1fb7fa7f39442745073cb36098e7a`. This is not a semantic-hook or browser-scaling defect.

The DOM audit could not detect the wording inside a raster image. Its compact-display text check therefore passed, but the visual inspection correctly supersedes that limited check.

## Checks not run after the stop

The 708 by 1000 viewport inspection and the principal figure/table 200% review were not run. The controlling order required an immediate stop on any unexpected visual defect. No repair, source edit, asset regeneration, or second render was attempted.

The loopback server was stopped and no listener remains. Post-QA protected and build inventories show zero drift.
