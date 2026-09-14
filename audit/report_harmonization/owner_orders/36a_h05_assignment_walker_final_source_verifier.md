# REPORT-014/017 order 36a: H05 assignment walker and final source verifier

Date: 2026-08-20

Owner: H05 task `019fba35-6fd8-73c3-970f-e41f8b759bb6`

Status: authorized source-only continuation; every H05 render remains held

## Purpose

Resolve the single order-36 verifier classification defect and run the full
H05 source-only verifier once. Do not reopen or rewrite either reader source.
Do not patch iteratively.

Controlling records:

- stopped-state acceptance
  `audit/report_harmonization/report017_h05_order36_stopped_independent_acceptance.md`;
- original order
  `audit/report_harmonization/owner_orders/36_h05_consolidated_reader_and_companion_rewrite.md`,
  SHA-256
  `8b6f6cd056106ac0836edab81e5f1db49674642c22608e5ef7d965c764bcc560`;
- consolidated audit
  `audit/report_harmonization/report017_h05_consolidated_full_document_audit.md`,
  SHA-256
  `c27b15a29fc56142419dda2f2d5ecb860ad18775a67096fdffe857eb00e7932d`;
- 44-row change matrix
  `audit/report_harmonization/report017_h05_consolidated_change_matrix.csv`,
  SHA-256
  `5edf51a846e2d187bb76a534e4fe533b7e551c929f9fbf659fb8362b88f625b7`;
- 27-row audit manifest
  `audit/report_harmonization/report017_h05_consolidated_audit_manifest.csv`,
  SHA-256
  `b3e29a03f349e6ffa4cf1ab0adf5f39e8d6262fe4f2f38efdd51ccc63a59f452`.

The coordination-matrix identity at dispatch is evidence only, not an owner
execution pin while path-disjoint work proceeds.

## Hard preflight

Require these current identities before any write:

- `notebooks/hypotheses/H05.qmd`,
  `7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0`,
  74,309 bytes;
- `audit/hypotheses/H05/H05_analysis_preparation.qmd`,
  `0a5296442b46c8b9e43773d97eb979ffbbf3512faabe6f4399da2214d38cb81c`,
  75,630 bytes;
- `audit/handoffs/H05_stage4_handoff.md`,
  `71a8d4664504da7b6e621d5b24aa699df793ee120373ae28aeb75d1c980246da`,
  19,132 bytes;
- `tests/hypotheses/H05/test_h05_report017_source_harmonization.R`,
  `67550b6e1cb810ae4850a8f14157d000d619b2bd13e830e007233c8f2d02f43e`,
  59,836 bytes.

Require the three files in `/private/tmp/h05-report017-order36.pdKad8` with
these exact names, hashes, and byte counts:

- `H05.qmd.pre`, `b4167419ce0f22b635d41c98d3d7edda2717fc73e6c963371f79035a334d793c`,
  70,979 bytes;
- `H05_analysis_preparation.qmd.pre`,
  `f7d7d3ef4bdf9b29403e85592b7dd2737f7e3c9dcfdc0ff7275eeefa7735c28f`,
  74,171 bytes;
- `H05_stage4_handoff.md.pre`,
  `896205d9b7f0403e7cb70023ebb392526e58a30825c4d2b151488098602018b4`,
  14,619 bytes.

Recheck the three existing H05 tests, three existing H05 manifests, both stale
HTML files, profile, site registry, deviation page, output catalog, figure
builder, figures, source data, and protected scientific artifacts at the
exact pins declared by order 36. Stop before editing on any owner-scoped or
protected drift.

## Durable stopped-state snapshot

Before editing the verifier, create
`audit/hypotheses/H05/report017_order36a_assignment_walker/`. Copy into that
directory the three exact pre-edit snapshot files and the four current stopped
files: result QMD, companion QMD, handoff, and verifier. Record a non-circular
seven-row snapshot manifest with exact source path, copied path, SHA-256, byte
count, and role. Verify 7 of 7 before continuing.

These copies are evidence only. Do not run a QMD or use a snapshot as a reader
source.

## Sole verifier edit

Edit only `assignment_records()` in
`tests/hypotheses/H05/test_h05_report017_source_harmonization.R`.

For each parsed expression, derive one scalar operator before the assignment
condition:

```r
operator <- if (
  is.call(expression) && is.symbol(expression[[1L]])
) {
  as.character(expression[[1L]])
} else {
  NA_character_
}
```

Then require all of these in the existing assignment condition:

- `is.call(expression)`;
- `length(expression) >= 3L`;
- `!is.na(operator)`;
- `operator %in% c("<-", "=")`;
- `is.symbol(expression[[2L]])`.

Change no other verifier logic, expected set, source identity, test, gate,
output path, or handoff contract. Preserve both QMDs and the handoff
byte-for-byte.

Create an exact one-hunk verifier diff and reverse proof to SHA-256
`67550b6e1cb810ae4850a8f14157d000d619b2bd13e830e007233c8f2d02f43e`.
Parse the repaired verifier under R 4.6.1. A structural check may confirm that
the operator is scalar for one ordinary assignment and one namespaced
non-assignment call. Do not run a preliminary project test or partial verifier.

## Single complete verifier invocation

Run exactly once:

```sh
H05_ORDER36_PRE_DIR=/private/tmp/h05-report017-order36.pdKad8 Rscript --vanilla tests/hypotheses/H05/test_h05_report017_source_harmonization.R
```

The verifier must run under R 4.6.1 and must complete every order-36 source,
chunk-parse, endpoint, expression, numeric-token, vocabulary, link, protected
identity, reverse-proof, figure-inventory, manifest, whitespace, and handoff
gate. Require the generated
`audit/hypotheses/H05/report017_order36/H05_report017_order36_source_manifest.csv`
to be non-circular, unique by path, and live-exact for every row.

On PASS, create one completion record and one non-circular order-36a manifest
under the new evidence directory. Include the seven-row snapshot, exact
verifier diff and reverse proof, complete command and runtime, package
versions, final verifier identity, all order-36 generated evidence identities,
and the final source-manifest audit. Exclude the order-36a manifest itself.

The handoff's prospective PASS sentence becomes accepted only if the complete
verifier exits zero. If any new failure occurs, do not modify the handoff or
anything else. Do not patch or retry. Seal the single stopped state and state
that the handoff remains provisional.

## Prohibitions

Do not edit either H05 QMD, the H05 handoff, any existing H05 test or manifest,
any build output, profile, semantic hook, shared file, catalog, central record,
scientific artifact, script, package, or lockfile. Do not run Quarto, execute a
QMD, fit or refit a model, calculate inference, regenerate an artifact, commit,
push, or upload. Every H05 render remains held.
