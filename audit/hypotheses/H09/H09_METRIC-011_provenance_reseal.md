# H09 provenance-only reseal for METRIC-011

Date: 2026-08-12

Status: **complete; H09 scientific estimand, fitted results, diagnostics, and
claims unchanged**

## Controlling evidence

| Record | SHA-256 |
|---|---|
| `audit/decisions/l10_numerical_zero_normalization.md` | `23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797` |
| `audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv` | `a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb` |

The evidence manifest contains seven `PASS` records produced with R 4.6.1.
Every listed member was rechecked against its sealed SHA-256 and byte count.

## Why H09 does not change scientifically

METRIC-011 changed exactly eight values in the primary prepared data: three
near-eye and five chest `l10_mean_medi` cells changed from
`4.163336342344337e-17` lx to exact zero. H09 does not analyse L10 mean
melEDI. Its registered rolling-window outcome is the timing of the L10
midpoint, represented by `l10_midpoint` and model column `l10_hour`.

The H09 metric registry contains no L10-mean response. The current enriched
near-eye and chest data reproduced all 12 stored primary L10-midpoint model
frames exactly: 9,378 stored rows had exact participant-day keys, exact raw
midpoint hours, exact negative-hour-converted model values, and a maximum
absolute difference of 0 hours. The checks cover MCTQ and MEQ in the
all-available, paired-common, and gap-common primary frames.

All 65 scientific H09 artifacts covered by the accepted Stage 3 seal remain
byte-identical. These include model frames, 540 stored model objects, result
tables, diagnostics, sensitivity outputs, figures, and source data. No model
was fitted or refitted, and no prediction, diagnostic, simulation, bootstrap,
or sensitivity calculation was rerun.

## Bounded repins

Only H09 citations to identities changed by METRIC-011 were repinned.

| H09 identity | Prior SHA-256 | Current SHA-256 |
|---|---|---|
| Metric manifest | `6ec3185620d921e1f81b8464e850249613deb823988187d58794b3471303f4e8` | `028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e` |
| Base manifest | `142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4` | `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce` |
| Near-eye context RDS | `2326428dde8d0be1eb1b8d7e84ea3d2eac12db5e595d4966955d546fce27d4fc` | `013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a` |
| Chest context RDS | `f8106f1c5ecaf7488a59f94f11bee472356be6c39d72564b1e6de3b4c3a5d8d3` | `497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057` |
| Near-eye enriched RDS | `fc80f8a2a94a447c5470db36c1ad1915868463501f04e9db3218f8156efc59d2` | `b469fa8f0a743de1cbb1075f78879b84ab602c74cc44fb97da45dee596681f42` |
| Chest enriched RDS | `ce81c159fe018f35bec9bff44c9cd12f91fd4be1ea2696c56a8e91e628a9e2d3` | `10aebeb5dabb53e8f3ee0747b62c31707da344e11b7068261c2ada2a0b7badc9` |
| Base input bundle | `fb5ccac6cc96a97b27b41dd34ba3551565a4d48414ca5e4e694f08106cf2030b` | `e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916` |

The current base manifest also verifies the sealed site/context manifest
identity `c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518`.

## Deliberate exclusions

This task did not absorb unrelated shared drift. The controlling METRIC-011
manifest transition shows that the gap-timing-unaware preparation manifest
was unchanged by METRIC-011, and its scientific values were invariant.
Therefore the older H09 gap-data and gap-manifest pin mismatches were recorded
but not repinned here. The independently changed metric-display registry was
also recorded but not repinned. Their exact observed identities and the
non-action are preserved in
`artifacts/06_model_data/H09/H09_METRIC-011_excluded_shared_drift.csv`.

Existing Stage 2, Stage 3, and preparation manifests remain the historical
scientific and report seals. The bounded overlay manifest
`artifacts/12_manifests/H09/H09_METRIC-011_provenance_reseal_manifest.csv`
contains only the controlling evidence, repinned inputs, H09 provenance
records, verification code, and the unchanged-scientific-identity proof.

## Reproduction

```sh
env R_PROFILE_USER=/dev/null \
  Rscript --vanilla scripts/hypotheses/H09/reseal_h09_metric011.R

env R_PROFILE_USER=/dev/null \
  Rscript --vanilla tests/hypotheses/H09/test_h09_metric011_reseal.R
```

The reseal script performs identity and value-preservation checks only. It
does not source H09 model-fitting code.
