# REPORT-017 H02 order 33e baseline recovery verification

Date: 2026-08-20

## Disposition

The six-file pre-order-33 H02 baseline has been reconstructed again at
`/private/tmp/H02-order33-recovered.7uqdRv`. The recovery is structural only.
No QMD was executed, no research data were read, and no project source, test,
scientific artifact, render, profile, lockfile, or historical record changed.

The H02 owner correctly stopped order 33d before mutation because the prior
temporary baseline path retained only empty directory scaffolding after the
environment transition. Every project and control-package preflight pin had
matched before that stop.

## Recovery method

The earlier patch-based recovery implementation stopped before applying its
patch because the live order-33 source-diff evidence had advanced from the
historical order-33a identity `7e05106b...` to the order-33c identity
`c79b040c...`. The latter identity is already pinned by the approved order 33d
dispatch manifest, but it is not a byte-identical substitute for the historical
patch.

The replacement recovery implementation is
`scripts/report_harmonization/reconstruct_h02_order33_baseline_from_git_blobs.R`,
SHA-256 `72d050737e2b294286b93080563de025ddd809a631acfb47064cf69f5acfc607`,
4,162 bytes. Under R 4.6.1 it:

1. requires one fresh empty output directory;
2. requires each of the six full Git object identities sealed in the durable
   earlier recovery inventory to exist and have type `blob`;
3. writes only those six blobs beneath the requested temporary directory;
4. verifies every reconstructed file by full SHA-256, byte count, and full Git
   blob identity; and
5. writes one local six-row inventory beside the reconstructed files.

The script parses under R 4.6.1 and passes Air 0.4.1 formatting checks.

One initial attempt of the new implementation stopped on a harness-only
`system2()` stream-status check before producing an accepted recovery. That
temporary directory, `/private/tmp/H02-order33-recovered.2ssp7R`, is retained
as failed-attempt evidence and is not an execution input. The corrected
implementation was then run once in a new fresh directory.

## Exact recovered baseline

The successful directory is
`/private/tmp/H02-order33-recovered.7uqdRv`. R 4.6.1 independently verified
all six reconstructed files against the prior durable inventory:

| Path | SHA-256 | Bytes | Git blob |
|---|---|---:|---|
| `notebooks/hypotheses/H02.qmd` | `56f6ded2dae5420e36231958d0b1a50f5f938d0d9dd2172301b2340861a0ff20` | 56,571 | `37e88ca1c057fb9b216867c0bbea26b1ce7cb4c0` |
| `audit/hypotheses/H02/H02_analysis_preparation.qmd` | `3d298f2f45165107bc69bbc3b35f1414a5d0cb905d8aa09c839d1e862618e808` | 54,702 | `bbc96aa28ec51933de00edd406b2f1f37413ca33` |
| `tests/hypotheses/H02/test_h02_reader_report.R` | `c54718734b679139a4d7f0c121c58daf8d5fe5efed49feeef2cc37eac25b185c` | 7,494 | `b2df8d0b446fd075253c9b3a38024f9f0e0fc8c3` |
| `tests/hypotheses/H02/test_h02_preparation_report.R` | `8c42a8a42856e5b9fb190a4e44de716f41ee1c8b7ef4eadd66c12c7663fd823d` | 5,475 | `4f2e681da03c98e22e93a3183e502babae9749c9` |
| `tests/hypotheses/H02/test_h02_paired_placement_display.R` | `17e1706ce8720ac48925e47be1b6ab2c246bbd900c7412b838834e8c39f3404a` | 3,591 | `0ca61dbe48a8546ec1fc113c72e340db031dacc2` |
| `audit/handoffs/H02_worker_handoff.md` | `0cf26a7038e7c49dc8e9790798b5ed3e1d01a5431cf0e1d8845b02892b96bc94` | 39,985 | `f6fbf32a8665d58fd3e87db4e3962b47612373f7` |

The temporary generated inventory is SHA-256
`39200f8f0758390e09a25449a9262cfb6eed34bcb1d1eea832bd0662834da7e7`,
1,088 bytes. Its durable six-row counterpart is
`audit/report_harmonization/report017_h02_order33e_fresh_baseline_inventory.csv`,
SHA-256 `0cff837c068f84fe1142f8214358bc9c75120d525d8ed36262bdf6e817a82d0d`,
1,030 bytes. The two inventories contain the same paths, SHA-256 identities,
byte counts, Git blobs, and PASS statuses. No symlink exists under the fresh
recovery directory.

## Continuation boundary

The owner may now resume the still-unexecuted order 33d mutation and its one
unchanged complete verifier invocation, substituting only the fresh recovered
baseline path above for the environment-cleaned path. No preliminary project
test, additional source classification, QMD execution, render, scientific
computation, shared edit, patch after failure, or second verifier retry is
authorized.
