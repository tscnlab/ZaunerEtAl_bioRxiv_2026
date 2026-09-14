# REPORT-018 H05 order 45a stopped state

Date: 2026-08-20

Status: **stopped after the sole authorized render exposed one new render-gate defect**

## Completed source repair

The bounded H01 contract provenance repair remains at:

- `audit/hypotheses/H05/H05_analysis_preparation.qmd`
- SHA-256 `cce35a2631206945b23144abc6cba44d7297237fc60c716d0d0e3949d128ee57`
- 77,741 bytes

Its exact preimage remains at
`audit/hypotheses/H05/report017_order36a_assignment_walker/snapshots/stopped_H05_analysis_preparation.qmd`,
SHA-256
`0a5296442b46c8b9e43773d97eb979ffbbf3512faabe6f4399da2214d38cb81c`,
75,630 bytes. The recorded source diff is SHA-256
`fa763ce280507ea3930d551d2386a2ace2616f43a18295341a9c966da620fd0c`.

The R 4.6.1 preflight passed all 17 input rows: 16 direct identity
matches, one exact accepted transition for the shared H01 contract, and zero
failures. The current and stored metric registries are exact for all 17 rows
and the six H05 model-defining fields. All 27 R chunks parse, the 22 table and
three figure endpoints are retained, the one Mermaid remains top-down, and no
prohibited fit, prediction, simulation, bootstrap, resampling, or write call
was added.

## Sole render attempt

The only command was:

`GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H05-order45a-semantics.sKI8sq quarto render audit/hypotheses/H05/H05_analysis_preparation.qmd --profile nathealth`

It ran under R 4.6.1 and Quarto 1.9.37 through the normal project profile.
Dependency discovery took 38 seconds. The input-identity table at cell 6 of
57 passed. The render then stopped at cell 8 of 57,
`tbl-h05-prep-integrity-checks`, with exit status 1:

`all(integrity_checks$Status == "PASS") is not TRUE`

The semantic hook was not reached. The fresh mode-0700 semantic directory is
empty. The helper and preparation test were not executed, and no loopback
server or browser QA was started. No patch or second render followed.

## Finding H05-45A-INT-001

This is a low-severity provenance/render-gate classification defect, not a
scientific discrepancy.

The preceding input table requires and proves exactly 16
`PASS` rows plus one `PASS_ACCEPTED_TRANSITION` row. The next integrity table
still defines its first row as passing only when all 17 codes are the literal
value `PASS`. That condition is necessarily false after the accepted
transition. Its expected and observed text is also stale at `17 matches` and
`16 matches` despite all 17 rows being accepted.

The other integrity rows depend only on the unchanged LEBA audit, metric and
run registries, stored model-frame archive, and frame index. No source or data
change in order 45a affects those checks. The smallest safe continuation is to
change only this integrity-table row so it counts both accepted verification
codes, reports 17 accepted inputs, and fails on any code outside `PASS` and
`PASS_ACCEPTED_TRANSITION`.

## Preservation

The complete build inventory is byte-identical before and after the failed
render:

- 836 files;
- zero symlinks;
- inventory SHA-256
  `e938b4ff1649943491dfaf1391c618578cc00842f6e70ccce7ef616e7a613070`.

The 150-path protected inventory is also byte-identical before and after:

- SHA-256
  `7f6cb9560ab8778d573c4e87d9040e26983230487e808d98e3969ec9050e999c`.

The accepted H05 result QMD and HTML remain
`7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0`
and
`a088e105be1987508280e91b938142773c8fb9275f1e924ac1ec9958a9b199f1`.
The stale companion HTML and website QMD remain
`c44f4f77f4e2295f6b265ed9505c3c560361a7280562dd9ce1afce73149d5866`
and
`f8087740def5e4e75e5bf5eff82d9f58acf1865954a16919719a7280f3447bfc`.
The profile, helper, preparation test, and preparation manifest remain at
their sealed order-45a pins.

No model, estimate, interval, p-value, FDR decision, diagnostic, sample,
scientific artifact, result page, package, lockfile, profile, ledger, commit,
push, or upload changed.

H05 companion acceptance and every later REPORT-018 target remain held.
