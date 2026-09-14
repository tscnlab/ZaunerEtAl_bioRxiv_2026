# REPORT-017 Preparation 06 focused-test stop

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/06_model_ready_datasets.qmd`  
Outcome: **STOP. The sole targeted render passed, but the focused test retained a stale exact-string assertion for historical MDER provenance wording.**

No browser server was started and no visual QA was attempted after the focused
test failed. Preparation 07 remained held.

## Preflight and bounded-render contract

The controlling order was
`audit/report_harmonization/owner_orders/24_preparation06_phase4_render.md`,
SHA-256
`30810c721f19f3de87b31512dbc16bc3b9ff154fb68078de0695468e28355411`.

Immediate pre-render identities matched the released pins:

| File | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/preparation/06_model_ready_datasets.qmd` | `2067db45d46b49bec34985f68eb9e10d5e35377548c5103218321261d50f4c5b` | 87,267 |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` | 7,404 |
| `tests/test_preparation06_report.R` | `e4b02061832be158372b54e1c473e0f221ab84cdd0aa7fb38e7d41cfb82f6f51` | 17,041 |
| `audit/handoffs/preparation_reports_worker_handoff.md` | `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640` | 31,435 |

The preceding 168-path baseline differed only at the released Preparation 06
QMD and `_quarto-nathealth.yml`. These were the accepted source harmonization
and profile-placement changes. The other 166 paths were exact. The fresh
pre-render inventory is
`audit/preparation_reports/report017_preparation06_prerender_scoped_readset.csv`,
SHA-256
`196d5cc05ff561adf464c6721e11fdfd888799e86c343c955dba6ba99da9c918`.

Static inspection found 21 bounded R chunks, 19 `tbl-*` endpoints, one stored
site-composition figure, and one Mermaid overview. It found no call to a
builder, production scientific verifier, model, renderer, writer, network
operation, `source()`, `system()`, or `system2()`. The page reads stored
artifacts, performs bounded identity and schema checks, formats reader-facing
tables, and draws the display from stored inputs.

The normal project startup used R 4.6.1, the project `.Rprofile`,
`renv/activate.R`, and the project library at
`renv/library/macos/R-4.6/aarch64-apple-darwin23`. Recorded versions were
Quarto 1.9.37, `renv` 1.2.3, knitr 1.51, rmarkdown 2.31, `gt` 1.3.0,
`digest` 0.6.39, dplyr 1.2.1, ggplot2 4.0.3, readr 2.2.0, scales 1.4.0,
tibble 3.3.1, and tidyr 1.3.2. The narrowly elevated permission was used only
for transient access to the existing user-owned `renv` sandbox cache. No
package was installed or updated, and `renv.lock` was not edited.

## Sole targeted render

Exactly one Quarto command was run:

```text
quarto render notebooks/preparation/06_model_ready_datasets.qmd --profile nathealth
```

The render guard began at `2026-08-13T15:17:28Z` and ended at
`2026-08-13T15:18:54Z`. The Quarto process returned exit status 0 after
approximately 58 seconds of observed command wall time and completed all 45
document stages. No second render was run.

The new target HTML is
`_build/nathealth/notebooks/preparation/06_model_ready_datasets.html`, SHA-256
`2179253dc28326c0cef4084327e3eb76f755bdc1d493209697da02f5c3855814`,
665,739 bytes. The site-composition PNG remained byte-identical at SHA-256
`058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da`,
224,765 bytes. Its paired stored source-data CSV remained byte-identical at
SHA-256
`809d109d3647ef4ac1798ef9eb59c06e2c7db41f5b9ce1dade4d0a8b583f0a22`,
21,916 bytes.

The bounded build delta contained five paths:

- the target HTML changed in content from the released stale hash
  `8211aff02f0f886211347e1d363d721036bb08017bc06b773dacfd36320cd401`
  to the new hash above;
- `search.json` changed in content to SHA-256
  `9f8438e7a8b56da5de786b4f95dcaf46989f7d80363f2b32b5c54b273559d434`;
- `sitemap.xml` changed in content to SHA-256
  `ba974e43a774ed29795d86e2b8ad06da58dfbb56923fa9e614e22eedfc98d26d`;
- the site-composition PNG was touched but remained byte-identical; and
- the shared Bootstrap CSS was touched but remained byte-identical at
  SHA-256
  `b3d78f1077461003efc2b21acc3f81ee6ba80468fe09df310b4c339e2e19133c`
  and 498,438 bytes.

The pre-render and post-render build inventories are, respectively,
`report017_preparation06_prerender_build_inventory.csv`, SHA-256
`2278813dbe0365d533ee3a37ff7e6b0546f346408dbd3657d11a446b51ddee73`,
and `report017_preparation06_postrender_build_inventory.csv`, SHA-256
`10db1ea49fe7d940653d61802a85374497c935058968e5c5c6b1f8be6eeb91e6`.

## Exact focused-test stop

The focused command was run once under the same normal R 4.6.1 project
startup:

```text
Rscript tests/test_preparation06_report.R _build/nathealth/notebooks/preparation/06_model_ready_datasets.html
```

It took 16.899 seconds and returned exit status 1 with:

```text
Error: Missing MDER reporting contract: historical METRIC-003 provenance
Execution halted
```

The first failing literal is at current test line 177 inside `mder_contract`:

```r
"historical METRIC-003 provenance",
```

The accepted QMD instead states at lines 1901 to 1903 that current MDER uses
no time-profile weighting, exclusion, or scaling, is not a ratio of daily
integrals, and that the older ratio-of-integrals and profile-based exclusion
records document an earlier method that is not active. Its stored-record table
also labels the earlier record as `Historical ratio-of-integrals support gate`,
and the table note explains why that superseded record remains visible.

The stopped test therefore identifies a stale exact reporting-test literal.
It is not evidence of a scientific discrepancy. The test exited on this first
failed token, so later assertions were not adjudicated in this run. No test,
QMD, HTML, configuration, artifact, or handoff repair was made.

## Preservation and stop evidence

The post-render comparison passed all 168 scoped paths by byte size and
SHA-256. It is stored in
`audit/preparation_reports/report017_preparation06_postrender_scoped_verification.csv`,
SHA-256
`c3aac5103aafec66326d18c84575fe0b10ce45761cc8cbd13316031bbbe74091`.

The QMD, profile, focused test, handoff, figure, and paired source data retained
their exact released identities after rendering and the failed test. No
preparation builder, scientific verifier, model, prediction, bootstrap,
simulation, Shapley calculation, or hypothesis computation ran. No data,
metric, sample, scientific artifact, decision, production script,
configuration, handoff, or source was edited.

No loopback server was started, no browser was opened for this page, and no
desktop or narrow visual assertion was made. Preparation 07 remains held. This
record seals the stopped state before any separately authorized test-only
disposition.
