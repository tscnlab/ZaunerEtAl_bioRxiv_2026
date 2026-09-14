# REPORT-017 Preparation 07 stopped render

Date: 2026-08-13

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Target: `notebooks/preparation/07_example_days.qmd`

Outcome: **STOP. The sole authorized target render reached the page's bounded input-identity check and failed because the sealed showcase manifest records the preceding site-solar-context SHA-256 rather than the accepted current SHA-256.**

No focused test, semantic audit, loopback server, browser inspection, or visual
QA was run after this failure. No second render was attempted. No source,
test, configuration, data, artifact, manifest, decision, ledger, or handoff was
edited.

## Controlling order and immediate pins

The controlling order was
`audit/report_harmonization/owner_orders/25_preparation07_phase4_render.md`,
SHA-256
`513b676b22deb1b5d31ec47667b731b2cf9b49014ea11f34a1f4371f517b775e`.

All immediate pins matched immediately before execution and remained exact
after the stopped render:

| File | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/preparation/07_example_days.qmd` | `2293d2520dabaacc7394a39c00b5ac62911da1d34fb489ecf4bf232c55a2998f` | 33,032 |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` | 7,404 |
| `tests/test_preparation07_report.R` | `be2505e1960ffb6ebbe1bdbc675fdd2da37e036a1eeb797e5c709f32f191fd2f` | 8,317 |
| `audit/handoffs/preparation_reports_worker_handoff.md` | `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640` | 31,435 |
| `_build/nathealth/notebooks/preparation/07_example_days.html` | `e37609f5adab0a5b57ce96d0229e4bac07dae3c713fe28aca3da68066ba12bdc` | 271,468 |

The HTML identity is the released stale-render reference. The failed command
did not replace it.

## Scoped preread reconciliation

The older page-specific preread inventory was
`audit/preparation_reports/preparation07_prerender_scoped_readset.csv`,
SHA-256
`d969d3b04d817ab6de822bef34e38c09eb2f606df172e7796a1996858a9b2da7`.
The older handoff comparison was
`audit/preparation_reports/preparation07_final_handoff_scoped_verification.csv`,
SHA-256
`1d1dd1d863d8c051e8be4041e3d4471f96f50eab131ce308700d48777f1cf9c7`.

The controlling 15 Preparation 07 paths reconciled exactly as ordered:

- 12 paths retained their older byte sizes and SHA-256 identities;
- the accepted current QMD had the released identity shown above;
- `artifacts/06_model_data/context/site_solar_context.rds` had the accepted
  current SHA-256
  `39ffe488de86f5d7cdc56d65c582c9de31f9054f8565936b4ec74e01491f26d0`
  and 41,068 bytes; and
- `scripts/pipeline/prepared_day_showcase.R` had the accepted REPORT-013
  identity
  `d77ca354f9bc927c293a5160194c481343f8e14cfc014a9e6985f70694db1ba0`
  and 25,549 bytes.

The module contained one explicit
`LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)` call. An in-memory
reverse substitution to `LightLogR::symlog_trans()` reproduced preceding
module SHA-256
`820fa16531f505e4561c133ccea19cfb8924218fde82d7548c0af281b538d3ee`
exactly. The controlling display-scale decision was
`audit/decisions/reader_facing_symlog_scale.md`, SHA-256
`8ddfd61216c57ed9f5a0ec59420df3da71edd95c5c77eb1ebe62f3d986a06d58`.

The fresh preread inventory is
`audit/preparation_reports/report017_preparation07_prerender_scoped_readset.csv`,
SHA-256
`2086d6c1d2bf6afe50b6a93a2612f102d9380c1d41a7eb2ccaeafa2f693e2120`.
It contains 15 rows: 12 `unchanged`, three `accepted_later_identity`, and zero
unexpected differences.

## Bounded execution check

Static inspection covered all 11 R chunks before execution. The chunks read
the accepted stored coverage, site-solar-context, site metadata, selection,
source-data, and manifest files; check identities and schemas; form existing
lightweight descriptive summaries; and format seven tables and three figures.

No chunk sourced or called a builder or production verifier. No chunk wrote a
file, repeated the fixed-seed selection, regenerated a durable artifact, fit a
model, predicted, estimated autocorrelation, resampled, bootstrapped,
simulated, ran Shapley analysis, used the network, or ran hypothesis
computation. The source retained the unchanged `flowchart LR` declaration.

## Sole render command and environment

Exactly one Quarto command was run:

```text
quarto render notebooks/preparation/07_example_days.qmd --profile nathealth
```

The normal project startup used R 4.6.1, Quarto 1.9.37, the project
`.Rprofile`, `renv/activate.R`, and the project library
`renv/library/macos/R-4.6/aarch64-apple-darwin23`. Recorded package identities
included `renv` 1.2.3, knitr 1.51, `gt` 1.3.0, ggplot2 4.0.3, and LightLogR
0.10.3. The narrowly elevated permission was limited to transient access to
the existing user-owned R 4.6 renv cache. No package was installed or updated,
and `renv.lock` was not edited.

The command started at `2026-08-13T18:37:07+0200` and ended at
`2026-08-13T18:37:58+0200`. `/usr/bin/time` recorded 50.20 seconds real,
38.68 seconds user, and 11.19 seconds system time. The shell process returned
status 0, but Quarto emitted a fatal page-render error and `Execution halted`.
The scientific and reporting verdict is therefore **FAIL**, irrespective of
that process status.

## Exact stopped condition

Execution stopped in `setup-preparation-07` at QMD line 244:

```r
stopifnot(all(input_identity$Status == "PASS"))
```

Quarto reported:

```text
Error:
! all(input_identity$Status == "PASS") is not TRUE
Quitting from 07_example_days.qmd:20-490 [setup-preparation-07]
Execution halted
WARN: Error encountered when rendering files
```

Read-only inspection located the failed identity comparison:

| Evidence | SHA-256 or recorded SHA-256 | Result |
|---|---|---|
| Current `artifacts/06_model_data/context/site_solar_context.rds` | `39ffe488de86f5d7cdc56d65c582c9de31f9054f8565936b4ec74e01491f26d0` | Accepted current input |
| `solar_context_input_sha256` in all six rows of `artifacts/12_manifests/prepared_day_showcase_artifacts.csv` | `b0e8de539572ee595cc91027e7a2d919ba01237f780e50a76e5e4468d497c4bf` | Preceding input identity |
| Showcase artifact manifest file | `c5ca66b2a6ec4fabbe57d08135db7f365bcd123365caab6c987bcb2b62f7a322` | Unchanged sealed manifest |

The manifest's coverage-input and site-metadata hashes still match their
current accepted files. Only its stored site-solar-context provenance pin
differs. This is a version-specific provenance mismatch between the sealed
display manifest and the coordinator-authorized current site-context input.
It is not, by itself, evidence that the stored display values, current
site-context data, or downstream scientific results are incorrect.

## Preservation and build delta

The failed-render protected comparison is
`audit/preparation_reports/report017_preparation07_failed_render_scoped_verification.csv`,
SHA-256
`56bb1ff12edf7a75705fd697d8fefbcd467260d970df62b26ff8ec781f202073`.
All 15 paths matched the fresh preread by byte size and SHA-256. There were
zero mismatches.

The pre-render and failed-render build inventories are, respectively:

- `audit/preparation_reports/report017_preparation07_prerender_build_inventory.csv`,
  SHA-256
  `0132c31e5423fc8c43e87d1eb6daea884711e9ed0676a5b793f017f679199590`;
- `audit/preparation_reports/report017_preparation07_failed_render_build_inventory.csv`,
  SHA-256
  `0132c31e5423fc8c43e87d1eb6daea884711e9ed0676a5b793f017f679199590`.

Each inventory contains 829 build files. They are byte-identical, so the
bounded build delta is zero paths. The stale HTML and its three generated
figure PNGs retained their preflight identities. The durable display files
also remained exact:

| Stored display file | SHA-256 | Bytes |
|---|---|---:|
| `artifacts/10_figures/prepared_day_showcase.png` | `a35e8189bdbdb450411bfe7f71d52964c17e45a7a26fdb44e82776d201b00ff3` | 808,132 |
| `artifacts/10_figures/prepared_day_showcase.svg` | `5ad003220cb1d5a1d2b223af206f4a1e608b4e1fa0e695d656989dde62b0ea4a` | 2,408,619 |
| `artifacts/11_source_data/prepared_day_showcase.csv` | `15e12011effbdf8fdbf7835be235b7b50406838278d411df023e924e81bea1e4` | 3,297,558 |

No loopback server was started, so there was no server PID, listener, or
browser process to terminate. Desktop and 708-pixel QA were not attempted.
Preparation 07 remains stopped at the input-identity boundary. A separately
bounded coordinator disposition is required before any repair or new render.
No hypothesis render was released or run, and DOC-001 remains open.
