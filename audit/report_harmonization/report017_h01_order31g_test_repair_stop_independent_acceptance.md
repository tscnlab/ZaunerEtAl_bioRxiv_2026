# REPORT-017 H01 order 31g controlled-stop independent acceptance

Date: 2026-08-14

Status: **Accepted as a complete test-only controlled stop. The dynamic-link
repair passes its exact contract. The complete REPORT-016 test remains held on
two pre-refresh image pins and no manifest has been partially resealed.**

## Accepted test transition

The sole source edit is
`tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`:

- pre-edit SHA-256
  `55c89eb03f9510ea3bce937a26da04d552d9eb4d6c2f87aec34884af69715765`,
  6,617 bytes;
- post-edit SHA-256
  `bbb994c0c339b39798307dcc8d4f98512518db55856e805ed53684594f6effea`,
  7,861 bytes; and
- exact one-hunk patch SHA-256
  `f1166d90680badbe98ec271f011f69d916052d2c5986bace32278266e649cb48`.

The reconstructed pre-edit source reproduces the accepted pre-edit identity.
The post-edit test and the seal script parse under R 4.6.1.

## Independent link-contract replay

An independent R 4.6.1 replay verified:

- exactly 40 targets;
- exactly 36 unique anchors;
- the exact relative prefix
  `../preregistration_deviations.qmd#` for every target;
- lower-case form for every linked anchor; and
- exactly one declaration of each linked anchor in
  `notebooks/preregistration_deviations.qmd`.

The owner evidence is
`audit/hypotheses/H01/report017_report016_dynamic_link_test_repair/H01_report016_dynamic_link_contract.csv`,
SHA-256
`e3da0a3145123f540094c96d9254da098fed3764956a287c58e6302e7516754b`.

## Exact remaining stop

The complete REPORT-016 test exits at the unchanged historical
protected-artifact equality gate. Exactly two rows differ:

| Path | Historical SHA-256 | Accepted current SHA-256 |
|---|---|---|
| `artifacts/10_figures/H01/stage3/H01_stage3_model_support.png` | `601c65eebff8260b9c19d6f5e3a6054799e1fb7fa7f39442745073cb36098e7a` | `2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b` |
| `artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg` | `c054674bacdd41ca2d02fff0a784955dfd77caf7604dacc166ccd0c8e1cfc098` | `602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966` |

These are exactly the order 31f title-only display transition already accepted
under the independent stopped-state record. The historical REPORT-016
inventory must remain unchanged. The current test needs a separately
authorized exact transition classification before the complete test can
proceed.

The stopped test was not rerun. The Stage 3, worker, and reporting manifests
remain unchanged at SHA-256
`08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f`,
`51288b656723bc7d29027b3bd5877fa7f18837135d6f7fe1d6c0b96bbe312006`,
and `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`.
The worker manifest and historical order 31f owner manifest still pin the
pre-31g test and are correctly classified as held rather than silently
rewritten.

## Seal and preservation

The 27-row non-circular owner manifest is SHA-256
`523bb9a7431d7cae032af92452947754ad2de0ac73caacfbc4a1ebe3c0041af3`.
Independent replay verified all 27 paths, hashes, and byte counts. The exact
two-row stop evidence is SHA-256
`428e6da5cd5489e602524a2c5c03bca4d57cfa42b4911a4217c030b867e36bad`.
The controlled-stop narrative is SHA-256
`97c78ce87717f6474a33423c4ee8637f9a5d4045a2ebfc2bbfe07e6a307ae3f7`.

The H01 QMD, builder, refreshed PNG and SVG, stopped HTML, profile, semantic
hook, source data, models, scientific outputs, packages, and lockfile remain
unchanged. No Quarto render or scientific computation ran. H01 and every
later REPORT-017 target remain held pending a separate coordinator decision.
