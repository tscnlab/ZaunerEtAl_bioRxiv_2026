# Brown Stage 3 language-harmonization render-release verification

Date: 2026-08-21

Status: **PASS; NO RENDER EXECUTED**

The durable read-only checker is:

`scripts/report_harmonization/check_brown_stage3_language_harmonization_render_release.R`

It was Air-formatted, parsed, and executed with R 4.6.1 and digest 0.6.39:

```text
Rscript --vanilla scripts/report_harmonization/check_brown_stage3_language_harmonization_render_release.R "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026" "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
```

It reproduced:

```text
BROWN_STAGE3_LANGUAGE_RENDER_RELEASE=PASS central_acceptance=32/32 harmonizer_acceptance=27/27 source_checkers=2/2 stage3_qmd=exact stage3_html=historical stage4=held semantic_engine=exact R=4.6.1 render=0
```

The check confirms that both independent source acceptances, both nested
manifests, both source checkers, the harmonized QMDs, both historical HTMLs,
the accepted semantic engine, and `renv.lock` are exact. No QMD, Quarto,
Pandoc, browser, model, or scientific computation was run while sealing this
release.
