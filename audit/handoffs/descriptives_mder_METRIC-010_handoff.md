# Descriptives METRIC-010 repaired-gap handoff

Date: 2026-08-11  
Scope: Table 2 and the MDER layer of Figure 3 only. No hypothesis model was
fitted, and no non-MDER scientific result was rebuilt or changed.

## Controlling estimand and source

Daily MDER is the arithmetic mean of viable one-minute
`melEDI / photopic illuminance` ratios. Both channels must be finite and
strictly positive. Support is evaluated on a complete 1,440-minute local
wall-clock grid; a daily value is retained at 720 or more viable ratios
(inclusive 50%). Fall-back duplicate local minutes are averaged within channel
before forming the ratio, and spring-forward absent minutes remain missing.

This descriptive refresh consumes the repaired gap-timing-unaware artifacts,
not the earlier relabelled frozen values:

| Artifact | SHA-256 |
|---|---|
| Controlling decision | `1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de` |
| Gap preparation manifest | `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935` |
| Gap participant-day RDS | `7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1` |
| Gap MDER-support RDS | `a0bc5d7ea2142709412da2253158086416ddb730b0f60ff616bba9d6ccb1edc5` |
| Gap repair evidence | `81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018` |

All four supplied gap pins and the current controlling decision were verified
before any descriptive output was replaced.

## Verified descriptive support

| Placement | Candidate days | Participants with MDER | Days with MDER | Mean | Median |
|---|---:|---:|---:|---:|---:|
| Near eye | 811 | 137 | 687 | 0.7242573273064842 | 0.7238676304180038 |
| Chest | 897 | 152 | 723 | 0.7567377375268886 | 0.7495174856978176 |

The R source-to-display audit matched all 1,410 finite plotted MDER rows to the
repaired participant-day RDS by placement, site, participant, date, metric,
and value (CSV round-trip tolerance below `1e-14`). The durable support audit
is `audit/descriptives/mder_metric010_refresh_verification.csv` (SHA-256
`f4209c9978366a9affbf14ea456efd1f32c259a8cbaf2b1c3c9a50921efedc4b`).

## Refreshed reader-facing outputs

| Output | Dimensions | SHA-256 |
|---|---:|---|
| `artifacts/09_tables/descriptives/metric_descriptive_summary_replica.csv` | 170 × 37 rows/columns | `970f85fd9d463b2d302af49babfa9ba6c0d6a7f5db4a0844483db3ed36a1a39b` |
| `artifacts/09_tables/descriptives/metric_descriptive_summary_replica.png` | 3640 × 3740 px | `5986419255a8a24429e0c6299eca83a3e8202be298f6a1c34e74b3db24e9e644` |
| `artifacts/11_source_data/descriptives/metric_plot_values.csv` | 146,077 × 24 rows/columns | `dc57f7df322259dbbd1be6f2b94b3696f56ef702a7aa7302ee71d9084ed1d26d` |
| `artifacts/10_figures/descriptives/near_eye_metric_distributions.png` | 3011 × 3011 px, 450 dpi | `060d1dcb3ec519ed1d74904c5457cc945346c53e25d08a9ea0f083d29f184d04` |
| `artifacts/10_figures/descriptives/near_eye_metric_distributions.jpeg` | 3011 × 3011 px | `4969761d583231199538f6a1b2359f00cf98c2ce43ad24f82a34bfd79db7ed13` |
| `artifacts/10_figures/descriptives/near_eye_metric_distributions.pdf` | 6.6929 × 6.6929 in | `de437b5a4830b99534090b2947b59f3f236e7f3f38bb58289aa89126c8f85148` |
| `artifacts/10_figures/descriptives/near_eye_metric_distributions.svg` | vector | `63c21b0d084b76e63e50d24f097ab3a881c7056ca4d73c7def5f7a064d1daf05` |
| `artifacts/08_diagnostics/descriptives/a4_mockups/near_eye_metric_distributions_a4.png` | 1240 × 1754 px, 150 dpi | `01ba42d878f0107c2b479e9bf944b49bcc8f548f1318219394473bf443bc1b36` |
| `_build/nathealth/notebooks/descriptives.html` | 2,196,315 bytes | `b5293acd3b494ca5645e4a5a0cff8227e1ce3fa10d2151a7ad24db130ecb39c1` |

Additional refreshed records:

- `metric_distribution_summary.csv`: `5866dcaacf1291cdfc63e49fe83492a2a86d9732e8de20e0d15ddd8cfe87eaa5`
- `metric_availability.csv`: `5e6857870a90907c9cf44464d2125aee638791c437fa2fb29595ab125db3e72e`
- `previous_table2_comparison.csv`: `88217f95f7c48e9b3941e697b8d099bde5163486eba2bb0eb5d139049e1e572a`
- descriptive artifact manifest: `859da83af2e01b9c32d07de476173fa3d6014ffdd2928ed5fd93b9ccec465fa5`

## Non-MDER preservation

`audit/descriptives/mder_metric010_non_mder_preservation.csv` (SHA-256
`2f5661b803582d1bf4a3eae117491322e295b82d3f28151aa3ba2dd796a40abf`)
records identical before/after hashes for every non-MDER row in the metric
summary, availability table, publication-table source, and figure source. It
also records identical hashes for every PNG/JPEG/PDF/SVG and A4 mock-up of
Figures 1, 2, 4, and 5 and for all non-MDER publication-table PNGs.

Key unchanged PNG hashes are:

- Figure 1: `97c4e60318a9e0733da44a97cc8bd176ac4ebc85c4e41bdd40d900b32fca7248`
- Figure 2 near eye: `be583f1caa254c5f28fa19489a99cb7b497a58f353e17b4d62bd75b7e351ec50`
- Figure 2 chest: `b9727d9ff587548f77aa18a5483ab6430c242c721a291b09cfd059541b58f765`
- Figure 4: `c6f080bd520c85f219749b2911702f6d29c3165bb2097b03e8b8437c2da96a1d`
- Figure 5: `b027935213185841c3b565dfbb440cf2fcf07dca03b4e19d2c1744270fd66ed6`

## Verification and visual QA

- Changed R files parse under R 4.6.1.
- `tests/descriptives/run_tests.R`: **PASS**.
- Bounded `renv` status: **PASS**.
- `renv.lock` remained unchanged at SHA-256
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.
- Thirteen shared manifests and 22 prepared inputs: **PASS**.
- Page-only Quarto render and publication to the Nature Health build path:
  **PASS**.
- Static HTML QA confirms the 13-manifest statement, first-use MDER estimand,
  and Overall Table 2 display `0.724`, `N=137`, `d=687`.
- Table 2, Figure 3, and its A4 print-width mock-up were visually inspected.
  The MDER row/panel is legible; site order and colours are retained; no
  clipping, overlap, malformed labels, or panel imbalance was observed.

## Environment and provenance

- R: 4.6.1
- Package record: `audit/descriptives/mder_metric010_package_versions.csv`
  (SHA-256
  `1795bdd53d9c1d4d4d02101b061ce46b83b32fd3972eb80bd9d8067a66a8e42c`)
- Shared-source record: `audit/descriptives/mder_metric010_source_provenance.csv`
  (SHA-256
  `ca6ca87ed2e41491fa0dbb610bd1670643eef006299da687d6d06f07f13abc55`)
- Shared-manifest audit: `audit/descriptives/shared_manifest_verification.csv`
  (SHA-256
  `4b2c1f3eaadc68ada0d39826134aa1ce994e4671f45cf0d675ff0de7367f28b0`)
- Prepared-input audit: `audit/descriptives/prepared_input_provenance.csv`
  (SHA-256
  `189ec643c786382f70b735b188b25601b7f581f1c7c27c98bf46a1081aba9750`)
