# H01 REPORT-017 order 31e render evidence

## Command and environment

- Command: `GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H01_REPORT017_31e.owP2my quarto render notebooks/hypotheses/H01.qmd --profile nathealth`
- Working directory: `/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026`
- Normal project profile: retained, including `.Rprofile` and `renv/activate.R`
- R: 4.6.1
- Quarto: 1.9.37
- Start: 2026-08-14T15:20:18Z
- Observed completion: 2026-08-14T15:24:47Z
- Duration: approximately 269 seconds
- Exit status: 0
- Render count: exactly one H01 result-target render

The normal-profile startup used the previously approved narrow access to the existing user-owned renv cache. No package was installed or updated. Dependency discovery emitted the existing project note that discovery took about 32 seconds initially and about 31 seconds in two later normal-profile stages.

## Captured Quarto and hook outcome

All 75 H01 processing steps completed. Quarto produced `H01.knit.md`, Pandoc completed, and the final console line reported:

```text
Output created: ../../_build/nathealth/notebooks/hypotheses/H01.html
```

The semantic hook reported:

```text
gt-html-semantics target=_build/nathealth/notebooks/hypotheses/H01.html disposition=REPAIRED pre=317d2ea152f4c8250c59f14f342192549acb2ae6d99e50765d13501df78bbfe3 post=6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa tables=36 ids=783 headers=4798
```

The combined hook summary additionally records 5,581 total permitted substitutions.

## Durable output

- Final HTML: `_build/nathealth/notebooks/hypotheses/H01.html`
- SHA-256: `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa`
- Bytes: 1,626,484
- Mode: `-rw-r--r--`
- Modification time: 2026-08-14T17:24:32+0200

No companion, later hypothesis target, or full project render ran.
