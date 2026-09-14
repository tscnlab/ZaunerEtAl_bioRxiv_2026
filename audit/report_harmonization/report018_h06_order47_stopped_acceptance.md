# REPORT-018 H06 order 47 stopped-state acceptance

Date: 2026-08-21  
Scope: hourly H06 result-page render only  
Disposition: **accepted execution stop; bounded provenance-only contract transition approved**

## Accepted execution record

Order 47 issued exactly one command:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/h06_order47_semantic.vAkayD quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

The command used Quarto 1.9.37 and R 4.6.1. It exited 1 after approximately
61 seconds in the H06 setup cell, before a new page or semantic-hook output was
produced. The exact assertion was:

```text
all(input_contract$hash_verified) is not TRUE
```

The stopped result HTML remains
`ff3518c09a4322dc8a2c23a961f2ef3ffc8d124843874547a40415c8330fd555`
at 6,109,797 bytes. The held companion HTML remains
`222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`
at 771,694 bytes. The semantic-audit directory is empty. The complete build
inventory remained 836 files, had no symlinks, and was byte-identical before
and after the attempt at inventory identity
`37b2920499664d1d54b610302f90dd3e32500338e6bbd2e7dc0ae7fa6b2e7e2d`.
No browser server or visual QA started.

## Exact stale contract pins

The current `scripts/hypotheses/H06/h06_contract.R` is
`9de4d56e462de9188bf1123984f3b06b3e01b01706a9618026e98f53444de2bb`
at 13,468 bytes. Exactly three of its 21 input identities are stale:

| Role | Path | Contract identity | Accepted current identity | Current bytes |
|---|---|---|---|---:|
| primary near-eye hourly | `artifacts/06_model_data/base/metrics_glasses_one_hour_context.rds` | `27b17c0232a90b6982377b1944b30e5574a02e691217a81f671ab14e45916f67` | `7591bcfaae4b49fdde2053160848e170895092b223f96108e538066ce210a951` | 248,236 |
| complementary chest hourly | `artifacts/06_model_data/base/metrics_chest_one_hour_context.rds` | `99885940c952c60ff6981ce029758ac43aec22c41cc27f22176fb3ab4f9c7186` | `18134eec529c36e5fd47c7b3bb1e3b909628b97986cd91eff8e59ee9b5343cbb` | 268,444 |
| current base-model manifest | `artifacts/12_manifests/base_model_data_artifacts.csv` | `b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09` | `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce` | 10,273 |

The other 18 contract identities match exactly.

## Scientific and provenance disposition

`audit/decisions/preparation06_current_base_model_gate.md` is the controlling
current-input decision. Its R 4.6.1 evidence establishes that the METRIC-011
transition changed exactly eight participant-day L10 mean values from
source-proven floating-point residuals to zero, while every 30-minute,
hourly, participant-level, and site/daylight-context scientific value remained
unchanged. It further establishes that all six accepted H06 hourly frames are
identical with tolerance zero and attributes included. The current base
manifest is therefore an accepted provenance-only transition for this
non-MDER H06 analysis.

The result QMD uses the two hourly RDS paths and the base manifest only through
`h06_input_contract()` and its identity assertion. It does not read those RDS
objects to calculate the displayed results. The page reads the already
accepted stored H06 result, table, figure, and source-data artifacts. The
render stop therefore identifies a stale provenance gate, not a scientific
result discrepancy and not a requirement to refit, recompute, or regenerate
an artifact.

## Approved continuation

One consolidated continuation may:

1. change only the three 64-character SHA-256 literals above in
   `scripts/hypotheses/H06/h06_contract.R`;
2. require an exact three-literal reverse substitution to the accepted
   preimage and the expected postimage
   `b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f`
   at 13,468 bytes;
3. parse the contract and verify all 21 input identities under R 4.6.1;
4. if and only if that source-only gate passes, run exactly one fresh H06
   result target render with the normal profile and semantic hook; and
5. complete the original order-47 semantic, link, protected-input,
   build-delta, secure-loopback, and visual acceptance package.

The continuation must stop on any other source, scientific, render, semantic,
link, protection, or visual defect. It may not alter a QMD, test, scientific
artifact, result value, figure, table, manifest, profile, package, lockfile,
ledger, companion page, H06 daily page, or any later target. No model fit,
prediction, resampling, simulation, inferential calculation, artifact
regeneration, full builder, full-project render, commit, push, upload, or
publication is authorized.

The H06 companion, H06 daily pages, H07, and all later serial renders remain
held pending independent H06 result-page acceptance.
