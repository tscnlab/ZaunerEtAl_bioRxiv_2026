# REPORT-014/017 order 33e: H02 fresh-baseline order 33d continuation

Date: 2026-08-20

Owner: H02 task `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`

This is a path-only continuation of the independently approved order 33d. It
does not authorize a new source classification, a preliminary test, or another
verifier retry. The previous attempt stopped at hard preflight before mutation
because the earlier temporary recovered baseline had been cleaned by the
environment transition.

## Controlling identities

- approved order 33d:
  `audit/report_harmonization/owner_orders/33d_h02_missing_argument_walker_and_final_verifier.md`,
  SHA-256 `eb6214469a241776217e42b875a2b4e4063e7fdea072385d19487c9372915432`;
- order 33d dispatch manifest:
  `audit/report_harmonization/report017_h02_order33d_dispatch_manifest.csv`,
  SHA-256 `712ef5269c2d592b1956c67bb2ee8e23cdc8fcb2b12e50611479c4398d68be17`;
- current result QMD:
  `4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d`;
- current companion QMD:
  `92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1`;
- current preparation test:
  `d7ff45696f15d7bc02e8e66adabd02ee0c1f952f71fca35280885418c6b1181b`;
- prospective preparation test after exactly the two approved indexed-walker
  changes:
  `ead7a55246a2625b1382acc302b6004892dbf7f7830285f2bae830cb0859d3f8`,
  14,895 bytes;
- current verifier:
  `ce7ad12f41e728ec3faf271855b0cdf82545ca934b3b1efbaedd3f265a5a7c2a`;
- recovery verification:
  `audit/report_harmonization/report017_h02_order33e_baseline_recovery_verification.md`,
  SHA-256 `3c215925a756d7900f622856ad617f120634948687b018a820adb08c05ae2e09`;
- Git-blob recovery implementation:
  `scripts/report_harmonization/reconstruct_h02_order33_baseline_from_git_blobs.R`,
  SHA-256 `72d050737e2b294286b93080563de025ddd809a631acfb47064cf69f5acfc607`;
- durable six-row recovery inventory:
  `audit/report_harmonization/report017_h02_order33e_fresh_baseline_inventory.csv`,
  SHA-256 `0cff837c068f84fe1142f8214358bc9c75120d525d8ed36262bdf6e817a82d0d`.

## Fresh recovered baseline

Use exactly:

`/private/tmp/H02-order33-recovered.7uqdRv`

Its generated inventory is
`/private/tmp/H02-order33-recovered.7uqdRv/H02_order33_reconstructed_baseline_inventory.csv`,
SHA-256 `39200f8f0758390e09a25449a9262cfb6eed34bcb1d1eea832bd0662834da7e7`,
1,088 bytes. R 4.6.1 independently verified all six file paths, SHA-256
identities, byte counts, and full Git blob identities against the durable
inventory. Stop before editing if that exact directory or any declared member
is absent or differs.

## Authorized continuation

1. Recheck all 31 rows of the order 33d dispatch manifest and all six fresh
   baseline identities. Stop before mutation on any mismatch.
2. Create the exact 14-file stopped-evidence snapshot required by order 33d.
3. In `tests/hypotheses/H02/test_h02_preparation_report.R`, apply exactly the
   two already approved indexed-walker changes from order 33d. No other test or
   source line may change.
4. Require R 4.6.1 parsing and exact reverse proof to the current test, but run
   no preliminary project test or verifier dry run.
5. Invoke the complete unchanged verifier exactly once:

   ```text
   NATHEALTH_PROJECT_ROOT=<project-root> Rscript --vanilla audit/hypotheses/H02/report017_order33_source_rewrite/run_h02_order33_source_audit.R /private/tmp/H02-order33-recovered.7uqdRv audit/hypotheses/H02/report017_order33_source_rewrite
   ```

6. On PASS, complete only the bounded non-circular source-only evidence seal
   required by order 33d and return every final identity. On any startup or
   assertion failure, stop once and seal the complete state without patching
   or retrying.

## Preserved boundary

All order 33d protections remain unchanged. Do not edit either QMD, the reader
or paired-placement test, handoff, historical evidence, profile, shared files,
scientific artifacts, models, estimates, figures, or tables. Do not execute a
QMD, run Quarto, render, fit, predict, bootstrap, rerun Shapley allocation,
recompute a p-value, change a package or lockfile, commit, or push. H02 has no
render authorization.
