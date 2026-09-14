# REPORT-014/017 order 36b: H05 endpoint metadata and wrapped-prose verifier

Date: 2026-08-20

Owner: H05 task `019fba35-6fd8-73c3-970f-e41f8b759bb6`

Status: authorized final source-only verifier; every H05 render remains held

## Purpose

Correct both shared causes of the six remaining verifier-only failures and run
the complete H05 source verifier once. Do not edit either QMD or the handoff.

Controlling acceptance:

- `audit/report_harmonization/report017_h05_order36a_stopped_independent_acceptance.md`;
- order-36a stopped record
  `audit/hypotheses/H05/report017_order36a_assignment_walker/order36a_stopped_state.md`,
  SHA-256
  `36c4242f14c520db7c4a71e0f8dad07455fddaafbf995af5399e68c2f652ceb2`;
- order-36a stopped manifest, SHA-256
  `ea41cbcdbd0f3ee6a57835898d25d3ec54694672a5bfb19f3e11ca51f50a4433`;
- generated six-row defect list
  `audit/hypotheses/H05/report017_order36/defect_list.csv`, SHA-256
  `29c44fc01304f3a92fb6cb32f8e578f3721b45a1106ba15bf79a97af36ab4952`;
- generated 135-row source manifest, SHA-256
  `70ed24b61d942b4e5d8e97539fb40ce5cf93fcb21b3d06323cb53c435b619b60`.

The coordination matrix is dispatch evidence only, not a hard owner pin.

## Hard preflight

Require these exact current identities:

- result QMD `7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0`,
  74,309 bytes;
- companion QMD `0a5296442b46c8b9e43773d97eb979ffbbf3512faabe6f4399da2214d38cb81c`,
  75,630 bytes;
- H05 handoff `71a8d4664504da7b6e621d5b24aa699df793ee120373ae28aeb75d1c980246da`,
  19,132 bytes;
- current verifier
  `a39c924b5ed35eb7ed20093574b766d23ab5e7abd001e32b6792f452bde080da`,
  60,058 bytes;
- all seven order-36a snapshot rows exact;
- all 34 order-36a stopped-manifest rows exact;
- all 135 current order-36 source-manifest rows exact; and
- all order-36 owner-scoped and protected pins retained from orders 36 and
  36a, including the three `/private/tmp` pre-edit snapshots.

Stop before mutation on any drift.

## Preserve the failed evidence

Create
`audit/hypotheses/H05/report017_order36b_final_verifier/`. Before editing the
verifier or rerunning it, copy every current regular file directly under
`audit/hypotheses/H05/report017_order36/` into a
`prior_order36a_failed_evidence/` subdirectory. Record source and copied paths,
hashes, byte counts, and roles in a non-circular snapshot manifest. Require
exact path-set equality and all copies byte-identical. Preserve the complete
order-36a evidence directory byte-for-byte.

## Exact verifier changes

Edit only
`tests/hypotheses/H05/test_h05_report017_source_harmonization.R`.

1. Change only the two chunk-label assignments to remove vector names at the
   boundary:

```r
result_labels <- unname(chunk_labels(current_chunks$result))
companion_labels <- unname(chunk_labels(current_chunks$companion))
```

Do not edit any expected endpoint vector or endpoint condition.

2. In `unfit_scope_and_suppression`, leave the required phrase unchanged and
   change only its second search target from raw `result_visible` to:

```r
gsub("[[:space:]]+", " ", result_visible)
```

Do not change the QMD wording or any other scientific-boundary assertion.

Create exact verifier diff and reverse proof to SHA-256
`a39c924b5ed35eb7ed20093574b766d23ab5e7abd001e32b6792f452bde080da`.
Parse under R 4.6.1. A bounded structural check may demonstrate named versus
unnamed endpoint equality and the wrapped-phrase normalization. Do not run a
preliminary project test or partial verifier.

## One complete verifier invocation

Run exactly once:

```sh
H05_ORDER36_PRE_DIR=/private/tmp/h05-report017-order36.pdKad8 Rscript --vanilla tests/hypotheses/H05/test_h05_report017_source_harmonization.R
```

Require all 54 gates to pass and the newly generated order-36 source manifest
to be unique, non-circular, and live-exact. Then create one completion record
and one non-circular order-36b manifest under the new evidence directory. Pin
the preserved failed evidence, verifier diff and reverse proof, command,
runtime, package versions, final verifier, all final order-36 evidence, and
the final source-manifest audit. Exclude the order-36b manifest itself.

On PASS, the existing handoff's source-only PASS sentence becomes accepted.
On any new failure, do not patch or retry. Seal one stopped state and keep the
handoff provisional.

## Prohibitions

Do not edit either H05 QMD, the H05 handoff, any existing H05 test or manifest,
build output, profile, semantic hook, shared file, catalog, central record,
scientific artifact, script, package, or lockfile. Do not run Quarto, execute a
QMD, calculate science, regenerate an artifact, render, commit, push, or
upload. Every H05 render remains held.
