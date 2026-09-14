# REPORT-018 H11 Order 60 environment-stop independent acceptance

Date: 2026-08-22

Disposition: `ACCEPTED_STOPPED_ENVIRONMENT`

## Independent result

The Order 60 stopped state is independently accepted. R 4.6.1 reproduces all
14 independent checks:

- the owner 58-row seal is 58/58 exact, unique, and non-circular;
- the original 30-row dispatch and 28-row complete preflight seals are exact;
- the sole target command exited 1 only after knitr completed all 53 cells and
  emitted `H11.knit.md`;
- the Quarto failure is exactly `ERROR: unable to open database file` during
  Sass bundle resolution before HTML production;
- the pre-render and post-failure build inventories are byte-identical at
  1,180 members, with 871 files, 309 directories, and zero symlinks;
- the pre-render and post-failure protected inventories are byte-identical,
  and all 336 paths remain live-exact;
- all 193 H11 scientific assets remain exact;
- the result source, held companion source and HTML, stale result HTML,
  profile, lockfile, sensitivity source, and sensitivity HTML remain exact;
- the external semantic directory has zero entries;
- no H11, Quarto, Pandoc, semantic-hook, or task-owned loopback process
  remains; and
- the existing user-owned Sass database is unchanged at 36,864 bytes and
  SHA-256
  `22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853`,
  with no WAL or SHM file.

The direct Quarto-bundled Deno probe opened the database under narrow access
and returned schema version 1 without changing its identity. Sandboxed access
reproduced the same database-open denial seen by Quarto. This is the
previously accepted macOS Quarto Sass-cache permission boundary, not an H11
source, scientific, semantic, or reader-page defect.

## Controlling identities

- owner stop record:
  `audit/hypotheses/H11/report018_order60_result_fail_closed/order60_fail_closed_record.md`,
  SHA-256 `b95694026d449a310c1149ddafb81de33374781ee246d6d4972a3321960fbfdb`;
- owner 58-row seal:
  `audit/hypotheses/H11/report018_order60_result_fail_closed/order60_fail_closed_non_circular_evidence_manifest.csv`,
  SHA-256 `fad21fab11cfb0c323c7386beeaffb30201989aaa901ff0337ad2b80d226fa40`;
- independent checker:
  `scripts/report_harmonization/check_report018_h11_order60_environment_stop.R`,
  SHA-256 `47bccc10cc956c949543d7114c981ac38462a9a080ca3049fe53e2dc0912674a`;
- 14-row independent verification:
  `audit/report_harmonization/report018_h11_order60_environment_stop_independent_verification.csv`,
  SHA-256 `a40da333361435f6e0bba6bbaa6995e5dbed3caffcabb6605cb64816de392896`;
- result QMD:
  `notebooks/hypotheses/H11.qmd`, SHA-256
  `7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867`;
- stale result HTML:
  `_build/nathealth/notebooks/hypotheses/H11.html`, SHA-256
  `c5724711ad1aa94631df0b6186fee92398d414ae02690ade08f320b29d6b6db7`;
- held companion QMD and HTML: SHA-256 `3f5a0d2e...` and `fd6307a6...`;
- held sensitivity QMD and HTML: SHA-256 `d2d17770...` and `b9af89c0...`;
- profile: SHA-256 `80dd0557...`; and
- lockfile: SHA-256 `3bf99c63...`.

## Bounded recovery authority

This accepted stop supports exactly one environment-only retry of the same
H11 result target with narrow elevated access to the existing user-owned
Quarto Sass cache. The target, QMD, profile, R 4.6.1 library, renv-autoloader
setting, scientific assets, tests, manifests, helper, companion, sensitivity
battery, and all Order 60 evidence remain fixed.

No cache reset or redirect, source edit, scientific execution, alternate
target, companion render, sensitivity execution, full-project render, or
second retry is permitted. The mandatory next stop is independent acceptance
of either the successful H11 result page or the complete one-attempt
environment failure package.
