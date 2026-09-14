# REPORT-017 order 32a: H01 consolidated verifier missing-argument repair

Date: 2026-08-15

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: authorized verifier-only source gate; all H01 rendering remains held

## Purpose

Complete the single consolidated order-32 source verification after its recursive R-call walker stopped before running any focused test. This is one verifier repair and one complete verifier execution. It is not permission to revise the assembled H01 rewrite.

Controlling records:

- Order 32: `audit/report_harmonization/owner_orders/32_h01_consolidated_reader_rewrite.md`.
- Stop disposition: `audit/report_harmonization/report017_h01_order32_verifier_stop_disposition.md`.
- Consolidated-pass protocol: `audit/report_harmonization/report017_consolidated_document_pass_protocol.md`, SHA-256 `13b5bb6708e0b044117a48f9577026e57896a935aed58f6b512948a828fe6923`.
- Baseline reconstruction script: `scripts/report_harmonization/reconstruct_h01_order32_baseline.sh`, SHA-256 `c3c7ea4348d18fa93cc8d0e74656a22dcc9fe5f52836a9ab1e1f331969ddc0c6`.
- Baseline reconstruction manifest: `audit/report_harmonization/report017_h01_order32a_baseline_reconstruction_manifest.csv`, SHA-256 `f2abc82cd0b705d6524fdb4b34d9b31d1a4034a351784295e66050132d34a544`.
- Dispatch-time coordination evidence: `audit/report_harmonization/coordination_matrix.csv`, SHA-256 `19ddb8ce3cc2471dc70a6c93ea4d8854e86dec0a1808b37d7c30deda03ad2f69`. This is evidence only, not a mutable global execution pin.

## Hard preflight pins

The following files must match exactly before any owner action:

| Path | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/hypotheses/H01.qmd` | `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb` | 93,260 |
| `audit/hypotheses/H01/H01_analysis_preparation.qmd` | `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f` | 55,827 |
| `tests/hypotheses/H01/test_h01_reporting_inputs.R` | `48f374cc70b69a6d96a95dc425ffd9676b2e83133a5554ae1c19eda939c0c8af` | 23,014 |
| `tests/hypotheses/H01/test_h01_preparation_report.R` | `379414830e5bcd656ac460c2ad93616ecbcab104259c56a8fcf9296da8c0f2c4` | 10,993 |
| `tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R` | `c359489b45703ae243d277817832e305716271dd54a7713620ceb4a7943d6393` | 14,658 |
| `tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R` | `121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb` | 6,747 |
| `artifacts/12_manifests/H01_reporting_artifacts.csv` | `dfa9e15f44f0919277264765e84b49b7be78e4822df014abed678b29a9a951b4` | 11,054 |
| `artifacts/12_manifests/H01_stage3_reporting_artifacts.csv` | `e9fe8740785e9f4d29e17c4333fdc0615347299c1dabea1d62ffad1cdafd11f9` | 26,497 |
| `artifacts/12_manifests/H01/H01_preparation_report_manifest.csv` | `cb89845e92b39f5bab7a0524508a3f7e2ce1d19ebbc99afe12f1ebf8eb9aefb5` | 13,841 |
| `artifacts/12_manifests/H01_worker_artifacts.csv` | `0d98bcc4ffe312e27ec89e352fdd84eea4ce1b8b8f9b9169307d314ba466b031` | 394,888 |
| `audit/handoffs/H01_worker_handoff.md` | `0de574566315d44934d3c6dd5fd91be9045e2f6b43887c9e3ad98d97caf1f19b` | 97,406 |
| `_quarto-nathealth.yml` | `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3` | 7,480 |
| `_build/nathealth/notebooks/hypotheses/H01.html` | `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa` | 1,626,484 |
| `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html` | `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38` | 667,418 |

The original verifier and complete stopped evidence must also match:

| Path | SHA-256 | Bytes |
|---|---|---:|
| `audit/hypotheses/H01/report017_order32_source_rewrite/run_h01_order32_source_audit.R` | `79eef03a3978b85447e93590346a69c165e05e4bfb1e64d89dd7b44ddc1e902c` | 34,759 |
| `audit/hypotheses/H01/report017_order32_source_rewrite/H01_order32_stopped_attempt.md` | `113347e9bbb16211b79a72b81bc6bc2e3b97384b02cb43071a07072126f80450` | 1,527 |
| `audit/hypotheses/H01/report017_order32_source_rewrite/H01_order32_stopped_defects.csv` | `c7d36c298dc39d4d173f69dd2f9950e14d20a010dbfe3a4f87d59fdda1efb0dd` | 935 |
| `audit/hypotheses/H01/report017_order32_source_rewrite/H01_order32_stopped_identities.csv` | `6bab2c4dad7cedc59e646cb8b4199f497c0158667587cae64ad361e2dbf14a5d` | 3,070 |
| `audit/hypotheses/H01/report017_order32_source_rewrite/H01_order32_stopped_non_circular_manifest.csv` | `5b217fe7f185a4f5cae9f8abf17390c94a6f7e2097be7dc7fccc388a128c29cb` | 2,865 |

Stop before writing if any hard pin differs.

## Authorized changes

Create only a new H01-owned verifier-repair evidence directory, for example:

`audit/hypotheses/H01/report017_order32a_verifier_repair/`

Inside it:

1. Copy the original verifier to `run_h01_order32a_source_audit.R`.
2. Add exactly one executable statement as the first line of the nested `walk` function inside `collect_calls`:

   ```r
   if (missing(object)) return(invisible(NULL))
   ```

3. Preserve every other verifier byte and all verification logic. A reverse substitution that removes only this statement must reproduce the original verifier SHA-256 exactly.
4. Create a bounded seal script and non-circular evidence manifest for this order. These may write only inside the new evidence directory.

Do not edit any existing QMD, test, manifest, handoff, HTML, profile, original verifier, or stopped record.

## Exact baseline reconstruction

1. Create one fresh empty directory with `mktemp -d`, using an order-specific name under `/private/tmp`.
2. Record its resolved absolute path, initial emptiness, and permissions.
3. Run the accepted reconstruction script once against that directory.
4. Require all six reported baseline hashes and byte counts to match the order-32 preflight identities embedded in the script.
5. Retain the temporary baseline until independent harmonizer acceptance.

The reverse-patch bundle is structural evidence only. Do not alter it or use it to modify the shared checkout.

## Single complete verification execution

After the exact repair and baseline reconstruction are complete, run the new verifier exactly once under R 4.6.1. Use the same project library and profile suppression as the stopped attempt:

```sh
env R_PROFILE_USER=/dev/null \
  R_LIBS_USER=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  NATHEALTH_PROJECT_ROOT=<project> \
  Rscript --vanilla \
  audit/hypotheses/H01/report017_order32a_verifier_repair/run_h01_order32a_source_audit.R \
  <fresh-exact-baseline-directory> \
  audit/hypotheses/H01/report017_order32a_verifier_repair
```

Do not run a preliminary focused test, partial verifier, or dry run. The complete verifier must run all four prescribed focused tests, source and endpoint contracts, formula and numeric-token preservation, link and anchor contracts, current and historical manifest checks, reverse proofs, and scoped diff checks in one pass.

If the verifier returns any failure, do not patch or rerun. Seal the complete failure list and all current identities once, then stop.

If it passes, run only the bounded evidence seal. Require:

- the original verifier and stopped evidence unchanged;
- the repaired-verifier one-line reverse proof;
- all H01 assembled sources, tests, current manifests, handoff, held HTML, profile, and scientific artifacts unchanged from preflight;
- the exact six-file reconstructed baseline identities;
- the complete verifier acceptance record and every generated CSV;
- exact commands, R version, consequential package versions, runtimes, exit status, and environment variables;
- a non-circular manifest whose own path is excluded from its rows;
- scoped `git diff --check`.

## Prohibited work

Do not render Quarto or execute a QMD. Do not fit, refit, predict, simulate, bootstrap, resample, rerun a reporting builder, recompute a result, or regenerate an artifact. Do not edit packages, `renv.lock`, the profile, semantic hook, central ledgers, harmonizer-wide records, another hypothesis, manuscript files, or build outputs. Do not commit or push.

Stop after the one complete source-only verification and sealed return. H01 result rendering, H01 companion rendering, H06 display artifacts, H03 synchronization rendering, and every later REPORT-017 render remain held.
