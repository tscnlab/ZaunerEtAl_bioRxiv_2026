# Brown Stage 4 language-harmonization render release verification

Date: 2026-08-21

Runtime: R 4.6.1, digest 0.6.39

Command:

```text
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
Rscript --vanilla scripts/report_harmonization/check_brown_stage4_language_harmonization_render_release.R
```

Result:

```text
BROWN_STAGE4_RENDER_RELEASE=PASS central=7/7 stage3_acceptance=26/26 source_manifest=19/19 historical_stage4=112_exact+1_authorized_qmd_transition stage4=18_chunks/17_tables/1_mermaid/3_result_links lock=exact R=4.6.1 digest=0.6.39
```

