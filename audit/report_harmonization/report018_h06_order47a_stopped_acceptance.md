# REPORT-018 H06 order 47a stopped-state acceptance

Date: 2026-08-21  
Disposition: **contract transition accepted; one reader-display execution
defect confirmed; bounded result-source repair approved**

## Accepted completed work

Order 47a changed exactly three SHA-256 literals in
`scripts/hypotheses/H06/h06_contract.R`:

- preimage
  `9de4d56e462de9188bf1123984f3b06b3e01b01706a9618026e98f53444de2bb`,
  13,468 bytes;
- postimage
  `b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f`,
  13,468 bytes; and
- exact reverse substitution reproduced the preimage byte-for-byte.

R 4.6.1 parsed the postimage and verified all 21 unique contract paths as
existing regular non-symlinks with exact current SHA-256 identities. The only
transition roles were `primary_near_eye_hourly`,
`complementary_chest_hourly`, and `current_base_model_manifest`. This is the
approved current METRIC-011 provenance bundle. The contract transition is
accepted and must not be rolled back.

## Accepted stopped render

Order 47a then issued exactly one command:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/h06_order47a_semantic.LTK1Qz quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

Quarto 1.9.37 used R 4.6.1 and the normal project profile. The command reached
cell 40 of 41 and exited 1 after approximately 84 seconds in
`tbl-h06-figure-readability-checks`. The exact error was:

```text
Error in dplyr::select():
In argument: dplyr::if_else(...).
Caused by error:
object '.data' not found
```

The `Status` expression is a data transformation inside `dplyr::select()`.
`select()` evaluates tidy-selection expressions and does not provide `.data`
for this computed column. The same complete expression is valid in
`dplyr::transmute()`.

## Independent source diagnosis

The source has one and only one `dplyr::if_else()` expression nested inside a
`dplyr::select()` call. It is the stopped figure-readability table at result
lines 1565 through 1578. The render executed every preceding cell, and the
remaining source contains no second occurrence of this invalid pattern.

An R 4.6.1 read-only evaluation loaded the exact three accepted figure-QA
CSVs, reconstructed the six-row `reader_figure_qa` object, and applied the
prospective `dplyr::transmute()` expression. It returned exactly six rows and
seven display columns in original order, retained every figure identifier and
numeric value, and returned `Verified` for all six accepted PASS statuses.

Replacing only the target token `dplyr::select(` with
`dplyr::transmute(` produces the prospective result-source identity
`2e88ad6b3a4aaffd2dfbf429a77c5d0865256554bb9b7799648fe63b976f1526`
at 60,680 bytes. Reversing only that token reproduces source preimage
`468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2`
at 60,677 bytes.

This is a reader-table execution repair. It changes no source data, status,
figure-QA value, scientific result, displayed wording, caption, table label,
endpoint, or claim.

## Preserved stopped state

- The stale result HTML remains
  `ff3518c09a4322dc8a2c23a961f2ef3ffc8d124843874547a40415c8330fd555`
  at 6,109,797 bytes.
- The held companion QMD remains
  `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`
  at 59,613 bytes.
- The held companion HTML remains
  `222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`
  at 771,694 bytes.
- The pre-render and post-failure build inventories are identical at
  `46c2e4dbbfa4700e37966af8d7847042e37509369c62535579ef1aed55471353`
  across 836 files, with no content, mtime, path-set, or symlink change.
- All 60 protected paths are exact.
- The semantic-audit directory is empty and no render or loopback process
  remains.
- No hook, browser QA, model, inference, test rerun, artifact regeneration,
  companion render, or H06 daily render occurred.

The owner completion record is
`ce169fa29100dd1b896f913caf471f72cb16477d4f413798e848fa63cda36f72`
and its 22-row non-circular evidence manifest is
`11516245a9d8388111431d793d6d4f118c528ffda6a0ad5e206dd4ac110abf08`.

## Approved continuation

One consolidated continuation may change only the exact target
`dplyr::select(` token to `dplyr::transmute(`, require the prospective identity
and exact reverse proof above, parse all result R chunks, scan the complete
source for any second computed `if_else()` inside `select()`, and rerun the
six-row display transformation under R 4.6.1. If and only if all source gates
pass, it may issue exactly one fresh H06 result render and complete the full
semantic, link, build, protected-input, secure-loopback, and visual package
already required by order 47a.

No additional source wording or cleanup is approved. Do not alter the accepted
contract postimage. No model, scientific calculation, source-data change,
artifact regeneration, manifest edit, test edit, companion render, H06 daily
render, later target, profile, package, lockfile, ledger, commit, push, upload,
or publication is authorized. Stop once on any genuinely new defect.
