# H09 Order72j execution commands

All R commands used R 4.6.1, disabled the renv autoloader, and selected the
accepted project R 4.6 library explicitly.

## Passing preflight

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23' H09_ORDER72J_PROJECT_ROOT='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026' H09_ORDER72J_OWNER_ROOT='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/hypotheses/H09/report018_order72j_split_svg_export' Rscript --vanilla audit/hypotheses/H09/report018_order72j_split_svg_export/code/check_h09_order72j_svg_exports.R pre
```

Result: `REPORT018_ORDER72J_H09_PREFLIGHT=PASS pins=123+37+566 functions=4 layers=8`.
Wall time reported by the execution tool: 2.1 seconds.

## Single native-device export trial

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23' H09_ORDER72J_PROJECT_ROOT='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026' H09_ORDER72J_OWNER_ROOT='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/hypotheses/H09/report018_order72j_split_svg_export' Rscript --vanilla audit/hypotheses/H09/report018_order72j_split_svg_export/code/build_h09_order72j_svg_exports.R export
```

Both native `svglite` device calls completed and wrote their trial files. The
process then exited nonzero because a validation-only assertion used scalar
`&&` for a two-element existence vector. The trials were retained and the
device was not rerun. Wall time reported by the execution tool: 1.4 seconds.

## Passing static postcheck and candidate seal

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23' H09_ORDER72J_PROJECT_ROOT='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026' H09_ORDER72J_OWNER_ROOT='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/hypotheses/H09/report018_order72j_split_svg_export' Rscript --vanilla audit/hypotheses/H09/report018_order72j_split_svg_export/code/check_h09_order72j_svg_exports.R post
```

Result: `REPORT018_ORDER72J_H09_STATIC=PASS` with both candidate hashes, all
123 + 37 + 566 pins exact, and visual lease `NOT_ISSUED`. Wall time reported
by the execution tool: 2.5 seconds.

## Final package seal

The same environment prefix is used with:

```sh
Rscript --vanilla audit/hypotheses/H09/report018_order72j_split_svg_export/code/seal_h09_order72j_component_review.R
```

