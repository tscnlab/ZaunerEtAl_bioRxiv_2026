# H07 METRIC-011 bounded reconciliation

Date: 2026-08-12  
Status: complete; no scientific conclusion changed  
Scope: H07 L10 mean branches only

## Controlling seals

- Numerical-zero decision:
  `audit/decisions/l10_numerical_zero_normalization.md`, SHA-256
  `23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797`.
- Shared evidence manifest:
  `audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv`,
  SHA-256
  `a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb`.
- Metric manifest SHA-256:
  `028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e`.
- Site/context manifest SHA-256:
  `c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518`.
- Base-model-data manifest SHA-256:
  `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce`.
- Base bundle pin:
  `e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916`.

The delegated near-eye and chest hashes `013afe75...` and `497466cc...`
identify the sealed participant-day context objects. H07 directly consumes
their enriched descendants, currently pinned as `b469fa8f...` near eye and
`10aebeb5...` chest in the same base manifest and bundle.

## Scientific input change

Exactly eight primary `l10_mean_medi` cells changed from
`4.163336342344337e-17` lx to exact zero: three near-eye cells and five chest
cells. Participant-day keys, sample membership, all non-L10 scientific values,
all hourly and 30-minute values, and all gap-timing-unaware scientific values
were unchanged.

## Bounded execution

The accepted artifact tree was copied to an isolated staging root. Only the
following fitted branches were reopened with the accepted formulas, Gaussian
identity family on `log10(value + 0.1)`, and
`mgcv::gam(method = "REML")`:

- 18 primary L10 fits: nine candidate models at each placement;
- 24 sensitivity L10 fits: three accepted models for each of eight full
  paired, gap-timing-unaware, and preparation-common runs; and
- 17 L10 leave-one-site-out fits: nine near-eye and eight chest site
  omissions.

The historical V0 reconstruction, longest-period-only sensitivity, dose
sensitivities, all non-L10 checkpoints, and the unrelated Tweedie
distribution pilot were not refit. The aggregate derivative and diagnostic
builders read frozen non-L10 checkpoints only to reconstruct complete tables.
Before installation, non-L10 rows were restored from the accepted tables;
only the two adjusted-test tables retained complete-family BH recomputation.

The final update plan installed 138 hash-verified artifacts:

- 108 changed L10 model/frame files;
- 26 tables with only their L10 rows replaced;
- two complete adjusted-test tables whose BH families contain L10;
- the direct H07 input manifest; and
- one L10-containing derivative-pilot diagnostic figure.

The unchanged LOSO run registry and unrelated Tweedie pilot remained
byte-for-byte frozen.

## Verification result

- All 947 non-L10 H07 model/frame files were byte-identical in staging.
- All eight declared non-L10 sample, diagnostic, and raw-test preservation
  checks passed; small diagnostic CSV round-trip differences below `1e-12`
  were removed by restoring accepted non-L10 rows before installation.
- Non-L10 raw model-test p-values were exact. BH recomputation changed no
  significance label and no p-value rounded under REPORT-008.
- Primary, sensitivity, model-form, and leave-one-site-out classification
  fields had zero changes.
- L10 transition grid points were unchanged at both placements. Numerical
  derivative differences were limited to floating-point roundoff of about
  `10^-15`.
- The accepted primary conclusion remains six of nine derivative-defined
  plateau patterns near eye and seven of nine at the chest. L10 remains a
  pattern at both placements.

This preservation result does not strengthen the evidentiary interpretation.
The pattern remains post-result, pointwise, descriptive, and non-equivalent;
site, collection period, latitude, photoperiod overlap, and concurvity
limitations remain unchanged.

## Durable evidence

- `artifacts/12_manifests/H07/H07_METRIC-011_reconciliation_summary.csv`;
- `artifacts/12_manifests/H07/H07_METRIC-011_scientific_comparison.csv`;
- `artifacts/12_manifests/H07/H07_METRIC-011_artifact_update_manifest.csv`;
- `scripts/hypotheses/H07/reconcile_h07_metric011.R`; and
- the updated H07 input, model, table, audit, and preparation manifests.

The reconciliation script aborts before application if a seal differs, any
non-L10 model/frame changes, any declared non-L10 preservation check fails,
or any scientific classification or REPORT-008 display value changes.
