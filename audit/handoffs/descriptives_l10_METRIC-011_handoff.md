# Descriptives METRIC-011 handoff

Date: 2026-08-12

Status: **bounded L10 numerical-zero refresh complete**

## Scope and result

The descriptives consume the controlling METRIC-011 repair without a full
descriptive rebuild. Exactly eight `l10_mean_medi` participant-day values were
changed from `4.163336342344337e-17` lx to exact `0` lx: three near-eye KNUST
days, four chest KNUST days, and one chest FUSPCEU day. No model, hypothesis
analysis, bootstrap, simulation, or figure recomputation was run.

The exact-zero L10 counts changed as follows:

| Placement | Before | After | Positive roundoff after | Support |
|---|---:|---:|---:|---|
| Near-eye | 111 | 114 | 0 | 141 participants / 816 participant-days |
| Chest | 120 | 125 | 0 | 154 participants / 902 participant-days |

Support is unchanged at every site. The only reader-summary string that
changes is the complementary chest Kumasi L10 middle-50% display: its lower
quartile is now exact `0` rather than the machine residual. Table 2 is the
near-eye table, so every visible numerical Table 2 value remains unchanged at
the approved maximum of three decimal places. Its L10 thumbnail source now
contains the three repaired near-eye zeros and continues to use
`LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)`.

The exported Table 2 PNG is byte-identical to the accepted export because the
three corrected positions are visually indistinguishable from zero at the
approved scale. It remains 3640 x 3740 pixels with SHA-256
`5986419255a8a24429e0c6299eca83a3e8202be298f6a1c34e74b3db24e9e644`.
It was inspected at full resolution; its accepted layout, labels, thumbnails,
and clipping behaviour are unchanged.

The 4 x 4 reader-facing Figure 3 contract does not contain an L10-mean panel.
Its PNG, JPEG, PDF, SVG, and A4 mock-up therefore remain byte-identical. All
other reader-facing figures and non-Table-2 publication tables were likewise
hash-guarded and unchanged. The 36-row preservation audit passes in full: 3
non-L10 source-row frames and 33 reader-facing exports.

## Controlling inputs

| Artifact | SHA-256 |
|---|---|
| `audit/decisions/l10_numerical_zero_normalization.md` | `23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797` |
| `audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv` | `a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb` |
| metric manifest | `028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e` |
| site/context manifest | `c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518` |
| base-model manifest | `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce` |
| base input bundle | `e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916` |
| near-eye participant-day context RDS | `013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a` |
| chest participant-day context RDS | `497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

The shared preparation, central decisions, site registry, and lockfile were
read only for this refresh.

## Updated outputs

| Output | SHA-256 |
|---|---|
| `artifacts/09_tables/descriptives/metric_distribution_summary.csv` | `f75db6bfcd0c1c783b8a45edd1dc6e4a30eb0ea538a40ca597623c5512d123cc` |
| `artifacts/09_tables/descriptives/metric_descriptive_summary_replica.csv` | `efd808cabcb90ca0d1254bf0195cc5ccb198a1d0d615037682bf8ed674d6a03b` |
| `artifacts/11_source_data/descriptives/metric_plot_values.csv` | `613b8cb50b478e762fd06d675f6dad1729b5ae5320826e9c5b2c0d71080eae81` |
| Table 2 PNG | `5986419255a8a24429e0c6299eca83a3e8202be298f6a1c34e74b3db24e9e644` |
| `artifacts/12_manifests/descriptives/figure_source_data_map.csv` | `8fd1bc4c5441d2102810bc5ca95f89ffd6a9a57b61bd58077ca8dd002e00ec5b` |
| `artifacts/12_manifests/descriptives/descriptive_artifacts.csv` | `b09f7bb5184e44e62272188eb7c9624669832ecdc31ecd809254bf3992544c75` |
| rendered descriptives HTML | `2d88888c888bc6f89374bd43753c239329bb1b9dd33f0f6e466d5cece5556ce0` |

The report now explains at first use that source windows verified as entirely
zero remain exact 0 lx and that machine-precision residuals are not interpreted
as positive exposure.

## Unchanged figure evidence

| Figure | PNG SHA-256 | A4 mock-up SHA-256 |
|---|---|---|
| Figure 1 overview | `97c4e60318a9e0733da44a97cc8bd176ac4ebc85c4e41bdd40d900b32fca7248` | `41f9aa5fd6fe3bd9a280483507a2cc6c1bdce451a000bf8b6812a6ff36a2a590` |
| Figure 2 near-eye profiles | `be583f1caa254c5f28fa19489a99cb7b497a58f353e17b4d62bd75b7e351ec50` | `164b23b31237bb59d49db88243b97d9effe3d2eb82e9c8c4d19963f444941303` |
| Figure 2 chest profiles | `b9727d9ff587548f77aa18a5483ab6430c242c721a291b09cfd059541b58f765` | `700ddba96fd3ff5d476e2675efa53ea3ff82aa1788b29c73600f31ab44f6b4fa` |
| Figure 3 metric distributions | `060d1dcb3ec519ed1d74904c5457cc945346c53e25d08a9ea0f083d29f184d04` | `01ba42d878f0107c2b479e9bf944b49bcc8f548f1318219394473bf443bc1b36` |
| Figure 4 time-series explanation | `c6f080bd520c85f219749b2911702f6d29c3165bb2097b03e8b8437c2da96a1d` | `792f331e99f1cb871d1e5cdbf3377470fc26f24ffc6c8565e6dbfeaedf814c21` |
| Figure 5 latitude/photoperiod | `b027935213185841c3b565dfbb440cf2fcf07dca03b4e19d2c1744270fd66ed6` | `20de3e34a47d0e5010170fdf9fddc249d42d1283af5afe24cc3cbdf65c368eaa` |

## Focused verification

| Check | Result |
|---|---|
| Changed-cell reconciliation against controlling evidence | PASS; exactly 8 L10 values, each old residual to exact zero |
| Exact-zero and support audit | PASS; 111 to 114 near-eye, 120 to 125 chest; support unchanged |
| Table 2 display and transform | PASS; visible values unchanged; `symlog-1-10-1` |
| Full-resolution Table 2 inspection | PASS; byte-identical accepted 3640 x 3740 export |
| Non-L10/source/export preservation | PASS; 36/36 rows |
| R parse checks | PASS |
| `tests/descriptives/run_tests.R` in the R 4.6.1 project library | PASS |
| Page-only Quarto render | PASS; all 31 knitr chunks and Pandoc completed |
| Rendered HTML structural inspection | PASS; L10 prose present, 8 tables, 14 figure elements |
| Browser inspection of local HTML | NOT TESTED; the browser security policy blocks `file://` reloads |
| Bounded source-aware `renv::status()` | TIMED OUT safely at 60 seconds after reporting 1,178 source files; child process terminated successfully; no unbounded status was run |

The bounded environment timeout does not alter the validated scientific or
display outputs. The lockfile remained byte-identical at the controlling hash,
and the package versions used by the scoped R run are recorded in
`audit/descriptives/l10_metric011_package_versions.csv`.

## Audit files

- `audit/descriptives/l10_metric011_changed_cells.csv`
- `audit/descriptives/l10_metric011_zero_count_effect.csv`
- `audit/descriptives/l10_metric011_summary_effect.csv`
- `audit/descriptives/l10_metric011_table_effect.csv`
- `audit/descriptives/l10_metric011_symlog_display.csv`
- `audit/descriptives/l10_metric011_non_l10_preservation.csv`
- `audit/descriptives/l10_metric011_refresh_verification.csv`
- `audit/descriptives/l10_metric011_source_provenance.csv`
- `audit/descriptives/l10_metric011_package_versions.csv`

