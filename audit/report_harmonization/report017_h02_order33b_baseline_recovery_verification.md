# REPORT-017 H02 order 33b baseline recovery verification

Date: 2026-08-15

Status: exact pre-order-33 source baseline recovered; one verifier retry awaits coordinator release

## Stopped owner return

Order 33b applied exactly the four authorized test-only classifications and
parsed both corrected tests under R 4.6.1. Its single verifier command exited
inside the opening `normalizePath()` call because the original temporary
baseline directory had disappeared across an environment restart. No verifier
audit check, focused test, QMD parse, project write, or seal step ran.

The current corrected test identities are:

- result-reader test: `0b044d2995645f6cfa50e28e2bdf330b8801002761a84520b169a1a3eb6771db`, 16,044 bytes;
- preparation test: `d7ff45696f15d7bc02e8e66adabd02ee0c1f952f71fca35280885418c6b1181b`, 14,726 bytes.

Both H02 QMDs, the verifier, paired-placement test, stopped order-33a evidence,
historical manifests, HTML, profile, lockfile, handoff, and scientific artifacts
remain at the order-33b preflight identities.

## Durable recovery inputs

The sealed order-33a versions of the two tests were copied byte-for-byte into
harmonizer-owned recovery paths:

- `test_h02_reader_report_order33a.R`: `b7eed310a4939ab566faa7c1b8b818bc2f7ab105f59076d6c186bf783704d137`, 15,038 bytes;
- `test_h02_preparation_report_order33a.R`: `b19c5a0beb18d9faf7506ab9dde9d73964a5d5b9fb9a13259865b5a358132a6d`, 13,645 bytes.

The recovery implementation is
`scripts/report_harmonization/reconstruct_h02_order33_baseline.R`, SHA-256
`a06d9d73b5dd0bd74a75e50620803686eeda90a330b79cef6d62c999db3ba4ed`,
5,861 bytes. It requires R 4.6.1 and a fresh empty output directory. It reads
only six current or recovered text files plus the sealed full source diff. It
does not execute a QMD or read research data.

## Exact reconstruction

The script was run once to
`/private/tmp/H02-order33-recovered.HO2BJm`. It verified the current side of
all six patch entries by full SHA-256 and Git blob prefix, rewrote only the two
absolute path prefixes in the sealed diff, checked the reverse patch, applied
it inside the fresh temporary directory, and verified every reconstructed
baseline Git blob against the old prefix sealed in the patch.

The reconstructed baseline is exact:

| Path | SHA-256 | Bytes | Git blob |
|---|---|---:|---|
| `notebooks/hypotheses/H02.qmd` | `56f6ded2dae5420e36231958d0b1a50f5f938d0d9dd2172301b2340861a0ff20` | 56,571 | `37e88ca1c057fb9b216867c0bbea26b1ce7cb4c0` |
| `audit/hypotheses/H02/H02_analysis_preparation.qmd` | `3d298f2f45165107bc69bbc3b35f1414a5d0cb905d8aa09c839d1e862618e808` | 54,702 | `bbc96aa28ec51933de00edd406b2f1f37413ca33` |
| `tests/hypotheses/H02/test_h02_reader_report.R` | `c54718734b679139a4d7f0c121c58daf8d5fe5efed49feeef2cc37eac25b185c` | 7,494 | `b2df8d0b446fd075253c9b3a38024f9f0e0fc8c3` |
| `tests/hypotheses/H02/test_h02_preparation_report.R` | `8c42a8a42856e5b9fb190a4e44de716f41ee1c8b7ef4eadd66c12c7663fd823d` | 5,475 | `4f2e681da03c98e22e93a3183e502babae9749c9` |
| `tests/hypotheses/H02/test_h02_paired_placement_display.R` | `17e1706ce8720ac48925e47be1b6ab2c246bbd900c7412b838834e8c39f3404a` | 3,591 | `0ca61dbe48a8546ec1fc113c72e340db031dacc2` |
| `audit/handoffs/H02_worker_handoff.md` | `0cf26a7038e7c49dc8e9790798b5ed3e1d01a5431cf0e1d8845b02892b96bc94` | 39,985 | `f6fbf32a8665d58fd3e87db4e3962b47612373f7` |

The six-row recovery inventory is SHA-256
`e6f7869f1d32cecbfb7f421726731f8bfbbaab0c9f62bbc72f6fa6537344df49`.
The relative recovery patch is SHA-256
`8783e88f69dead72e0fd16115f2456c5ff6097b33a969d34f44c2bffe2f70375`.

## Disposition

The failure is an environment-evidence loss, not a source, test, or scientific
defect. A single bounded continuation may use the already verified recovered
directory as the baseline and rerun the exact unchanged verifier once. If the
directory disappears before execution, the same continuation may create one
fresh empty temporary directory and invoke the sealed recovery script once
before the verifier. It must not edit the tests again, patch the verifier, or
run a preliminary project test.

No H02 render is released. H01 remains the sole active render path.
