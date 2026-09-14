# Brown Stage 3 order 50 independent acceptance verification

Date: 2026-08-21

Runtime: R 4.6.1, digest 0.6.39, xml2 1.6.0

Command:

```text
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
Rscript --vanilla scripts/report_harmonization/check_brown_stage3_order50_independent_acceptance.R
```

Result:

```text
BROWN_ORDER50_INDEPENDENT=PASS central=4/4 manifest=80/80 candidate=25/25 finalization=28/28 protected=1565/1565 served=31/31 visual=19/19 screenshots=7/7 endpoints=16_tables+5_figures semantics=120_ids+335_headers+43_idrefs ledger=455_reverse+forward listener=absent R=4.6.1 digest=0.6.39 xml2=1.6.0
```

The independent visual review covered the native full-page capture, the
390-pixel full-page capture, and all five figure captures. The two wide site
forest plots are correctly contained by reader-operated horizontal scrollers.
No clipping, overlap, missing content, broken figure, page overflow, or reader
defect was found.

