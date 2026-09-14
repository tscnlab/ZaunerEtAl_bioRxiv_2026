# REPORT-017 Preparation 04 focused-test stop

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/04_metric_derivation.qmd`  
Outcome: **STOP. The sole targeted render passed, but the focused test retained one stale exact-string assertion for superseded gap-timing-unaware MDER wording.**

No browser server was started and no visual QA was attempted after the focused
test failed. Preparation 05 remained held.

## Preflight and bounded-render contract

The controlling order was
`audit/report_harmonization/owner_orders/22_preparation04_phase4_render.md`,
SHA-256
`74a92c0464a2c2f624e3434a17ee66d5fbddafa96d5c5150993067978cde57d1`.

Immediate pre-render identities matched the released pins:

| File | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/preparation/04_metric_derivation.qmd` | `86041585edfb60ba0f3137d268418e7479b369be859b41350d2347bd81e064a6` | 80,557 |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` | 7,404 |
| `tests/test_preparation04_report.R` | `bab6b85bcd7c445c41681231ce84e1420816a7cc5887883b90e27534ae92080d` | 13,332 |
| `audit/handoffs/preparation_reports_worker_handoff.md` | `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640` | 31,435 |

Static inspection found exactly 16 bounded R chunks, 13 `tbl-*` endpoints,
one empirical MDER figure, and one Mermaid overview. It found no call to a
builder, production verifier, writer, renderer, `source()`, `system()`, or
`system2()`. The page reads stored artifacts, checks identities and schema,
formats native `gt` tables, and draws the MDER display from the frozen
verification summary.

The normal project startup used R 4.6.1, the project `.Rprofile`,
`renv/activate.R`, and the project library at
`renv/library/macos/R-4.6/aarch64-apple-darwin23`. Recorded versions were
Quarto 1.9.37, `renv` 1.2.3, knitr 1.51, `gt` 1.3.0, and rmarkdown 2.31. The
narrowly elevated permission was used only for transient access to the
existing user-owned `renv` sandbox cache. No package was installed or updated,
and `renv.lock` was not edited.

The preceding 106-path comparison differed only at the released Preparation
04 QMD and `_quarto-nathealth.yml`, which were the accepted source
harmonization and profile-placement changes. The fresh pre-render inventory is
`report017_preparation04_prerender_scoped_readset.csv`, SHA-256
`c078bc318ce1d14659047ae62cba70e8b37843ad55ef9f9de9eb3285f405bc2a`.

## Sole targeted render

Exactly one Quarto command was run:

```text
quarto render notebooks/preparation/04_metric_derivation.qmd --profile nathealth
```

It began at `2026-08-13T15:25:21+0200`, completed at
`2026-08-13T15:26:32+0200`, returned exit status 0, and took approximately
71 seconds including normal project startup. The log recorded all 35 document
stages, including the 13 native `gt` tables and the stored-summary MDER figure.

The new target HTML is
`_build/nathealth/notebooks/preparation/04_metric_derivation.html`, SHA-256
`fba5e6f81251123b16deb6728321a558c3722c6bc26c4a946edf8712c570dd06`,
558,230 bytes. The MDER PNG remained byte-identical at SHA-256
`423cae8946a50bd6e611ff14708b7ff0543546f3fdc9e9fa030ca917838d75ce`,
47,303 bytes.

The bounded build delta contained five paths:

- the target HTML changed in content;
- `search.json` changed in content to SHA-256
  `c8bf3a770a29ca0c91518f9bbafa7f42397989bbfd572918be226cd73b8099ba`;
- `sitemap.xml` was touched and remained 5,219 bytes at SHA-256
  `8b935ede8f26c9a5fa8ce58001f6b9e91c8f78702d0922b281be02592938d422`;
- the MDER PNG was touched but remained byte-identical; and
- the shared Bootstrap CSS was touched but remained byte-identical at
  SHA-256
  `b3d78f1077461003efc2b21acc3f81ee6ba80468fe09df310b4c339e2e19133c`
  and 498,438 bytes.

## Exact focused-test stop

The focused command was:

```text
Rscript tests/test_preparation04_report.R _build/nathealth/notebooks/preparation/04_metric_derivation.html
```

It ran under normal project R 4.6.1 startup and returned exit status 1 with:

```text
Error: Missing MDER rule: earlier 725 near-eye and 729 chest availability wording
Execution halted
```

The obsolete requirements occur in the `mder_contract` vector at current test
lines 191 and 192:

```r
"earlier 725 near-eye and 729 chest availability wording",
"is superseded by these independently verified counts",
```

The current accepted source and rendered HTML instead contain the exact visible
sentence `The earlier 725/729 availability record is superseded.` The source and
HTML also retain the accepted current values `687 of 811`, `723 of 897`, and
the statement that all `25,620 non-MDER participant-day cells` were exactly
unchanged. This stop therefore identifies a stale reporting-test literal, not
a scientific discrepancy.

## Preservation evidence

The post-render comparison passed all 106 scoped paths by byte size and
SHA-256. It is stored in
`report017_preparation04_postrender_scoped_verification.csv`, SHA-256
`c6461e27abbaf9162bb1bedd6856ca973746d1b9ea7ee1560e92875fce475697`.

The QMD, profile, focused test, and handoff retained their exact released
identities after rendering and the failed test. No preparation builder,
scientific verifier, model, prediction, bootstrap, simulation, Shapley
calculation, or hypothesis computation ran. No data, metric, sample,
scientific artifact, decision, production script, configuration, or handoff
was edited.

This record seals the stopped state before any separately authorized test-only
recovery.
