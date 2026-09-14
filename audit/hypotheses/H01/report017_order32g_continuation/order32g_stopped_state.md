# REPORT-017 H01 order 32g stopped state

Date: 2026-08-15

Status: fail-closed after the first focused-test failure. No Quarto render was
run.

## Completed authorized work

- The 35-row dispatch seal passed before mutation.
- The scalar-safe geometry correction was applied to the dedicated refresh
  implementation, Air 0.4.1 preserved its parsed abstract syntax, and the one
  R 4.6.1 scalar-geometry preflight passed.
- One fresh candidate directory was created at
  `/private/tmp/H01-order32g-candidates.Q1iS0N`. Its single candidate run
  passed all three geometry checks, all three SVG structure and text checks,
  all 30 paired labels, zero label collisions, and minimum final text sizes of
  7.133 pt for Figure 1 and 7.095 pt for Figure 6.
- The fresh candidates were visually checked at original size, intended final
  size, 1440 pixels, 708 pixels, and 200 percent. No clipping, overlap, or
  illegible required text was found.
- Exactly six durable PNG/SVG targets were replaced once. All six are
  byte-identical to the accepted fresh candidates.
- The dedicated order-32g display test passed under R 4.6.1.

## First failing check

Command:

```text
env R_PROFILE_USER=/dev/null \
R_LIBS_USER=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
RENV_PATHS_SANDBOX=/private/tmp/H01-order32g-renv-sandbox \
NATHEALTH_PROJECT_ROOT=<project> \
Rscript --vanilla tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R
```

Observed result:

```text
Error: identical(artifact_sha256(path), core_manifest$sha256[[index]]) is not TRUE
Execution halted
```

The complete read-only mismatch audit found exactly one row. The immutable
historical core manifest expects the pre-order test at SHA-256
`121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb`
and 6,747 bytes, while the current transition-aware test is SHA-256
`dcd3e62574a493d18733a9cb50eb6eb9d7493f8ac7bbb27918dc6535dcd1a603`
and 8,224 bytes. The old test was not retained as a separate evidence copy
before the current test was updated. All other rows in that historical core
manifest resolve exactly after the authorized pre-32g builder and Figure 1
substitutions.

This requires a separate coordinator disposition. The two bounded options are
to recover or reconstruct the exact pre-order test as historical evidence, or
to authorize an explicit historical-to-current test transition classifier.
The historical core manifest itself remains unchanged.

## Combined stopped-state defect list

1. Historical test evidence is unavailable at the identity expected by the
   immutable FDR-refresh core manifest. This is the sole newly discovered
   focused-test defect.
2. Direct manifest resealing did not begin. The Stage 3 manifest therefore
   reports eight expected transition mismatches: the six figures, builder,
   and updated FDR-display test.
3. The worker manifest reports eleven mismatches. Nine are the same current
   order transitions plus the REPORT-016 test; two are previously accepted
   broad-manifest historical pins for the H01 HTML and profile. The reporting
   manifest remains 49/49 exact.
4. The REPORT-016 and full reporting tests were not run after the first
   failure because their current manifest dependencies were intentionally
   left unresealed.
5. The result render, semantic hook, loopback browser inspection, and
   post-render QA were not run.

## Preserved state

- Result QMD: `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`.
- Companion QMD: `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`.
- Unrendered result HTML:
  `d1bc9159526c92b9cc9256c58a8232d4779f0014a3aa39ed3680b4e58fb25410`.
- Frozen companion HTML:
  `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`.
- Profile: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- All 31 members of the three required retained temporary evidence sets are
  exact: 12 order-32e candidates, 16 order-32f files, and three quarantine
  files.
- The fresh order-32g candidate directory remains intact with 38 files.
- No model, inference, source-data, QMD, profile, central-ledger, package,
  lockfile, companion HTML, or result HTML change occurred.

The exact row-level audits are in this directory. The stopped-state seal ran
under R 4.6.1 and passed.
