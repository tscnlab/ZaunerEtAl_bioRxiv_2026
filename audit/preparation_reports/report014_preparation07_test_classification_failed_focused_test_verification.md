# REPORT-014 Preparation 07 test-classification repair stop

Date: 2026-08-14

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Outcome: **STOP. The exact order-26a test-classification repair parses under
R 4.6.1, but the source-only focused test reaches one additional pre-existing,
whitespace-sensitive visible-literal assertion and exits with status 1.**

No Quarto or knitr command was run. No QMD chunk, strict verifier, builder,
selection routine, or scientific computation was executed. No QMD, HTML,
configuration, data, artifact, manifest, production script, decision, ledger,
lockfile, or handoff was edited during this follow-up.

## Authority and exact starting state

The controlling order was
`audit/report_harmonization/owner_orders/26a_preparation07_test_classification_repair.md`,
SHA-256
`2a918717486216f3642fea31fbd9d02da76fbad6d725a2e30d2b4a0354bbb765`.
The preceding stopped checkpoint and its non-circular manifest remained exact:

- `audit/preparation_reports/report014_preparation07_provenance_failed_focused_test_verification.md`:
  `9de292ad59a9b0b8b00f60810fe1d54993a903a3dfa585fb0ac37c91043d3808`;
- `audit/preparation_reports/report014_preparation07_provenance_failed_focused_test_manifest.csv`:
  `80bb383ebd86fbc67753cf749da493ab2ac5166241b4a80ae1041e62820015a5`.

Both released pins matched before editing:

| File | Starting SHA-256 | Bytes |
|---|---|---:|
| `notebooks/preparation/07_example_days.qmd` | `ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae` | 39,361 |
| `tests/test_preparation07_report.R` | `707139e3c19e3ed10308a04876e6c2c2b08cf03a5f5c1faf16d4739d18220bcd` | 11,431 |

## Exact authorized test delta

Only `tests/test_preparation07_report.R` changed. Its post-edit identity is
`a22182cb9b15e96d5c9e8dd66e98c486345d996c947ca757044f0bdbe0a96457`
with 11,887 bytes. The Preparation 07 QMD remained byte-identical at
`ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae`.

The zero-context pre-to-post diff is:

```diff
@@ -190 +189,0 @@
-  "None of the Preparation 07",
@@ -192,2 +190,0 @@
-  "does not rerun the fixed-seed selection",
-  "does not rerun",
@@ -196 +192,0 @@
-  "20260730",
@@ -200,0 +197,10 @@
+}
+for (token in c(
+  "none enters an H01–H11 model",
+  "selection was not repeated",
+  "does not repeat the selection"
+)) {
+  expect_true(
+    grepl(token, visible_flat, fixed = TRUE),
+    paste("Missing visible semantic statement:", token)
+  )
@@ -201,0 +208,12 @@
+expect_true(
+  grepl("unique(manifest$seed) == 20260730L", full, fixed = TRUE),
+  "The fixed-seed source assertion is absent."
+)
+expect_true(
+  grepl(
+    "The full production verifier is deliberately not rerun here because",
+    full,
+    fixed = TRUE
+  ),
+  "The full-source verifier-not-rerun assertion is absent."
+)
```

This removes only the four released stale classifications, adds the three
approved `visible_flat` semantic checks, and retains fixed-seed and
verifier-not-rerun evidence as full-source assertions. All other test gates
remain unchanged.

## Parse, reversibility, and diff hygiene

The authorized normal-profile parse command returned exit status 0:

```text
R version 4.6.1 (2026-06-24)
test_parse=PASS
```

The normal startup also emitted renv's informational dependency-discovery
note. It did not change `renv.lock` or another protected identity.

The unified pre-to-post patch was reverse-applied in memory to the post-edit
test. The reconstructed SHA-256 was exactly
`707139e3c19e3ed10308a04876e6c2c2b08cf03a5f5c1faf16d4739d18220bcd`,
which reproduces the released test byte-for-byte. `git diff --check` passed for
the focused test.

## Exact focused-test stop

The authorized source-only command was run without an HTML argument:

```text
Rscript tests/test_preparation07_report.R
```

It reached the next focused assertion and returned exit status 1:

```text
Error: The readable figure split or paired source-data statement is absent.
Execution halted
```

Read-only source inspection identifies the exact mechanism. The accepted QMD
contains `figure source-data CSV` and the sentence fragment `split into three
three-panel` at line 831, followed by `figures` at line 832. The focused test
uses `grepl(..., visible, fixed = TRUE)` to require the single uninterrupted
literal `split into three three-panel figures`. Because `visible` preserves the
source newline, that fixed string does not match. The paired source-data link,
the three-figure split, and their reader-facing meaning are present in the
unchanged accepted QMD.

This assertion and source line break both existed at the start of order 26a.
The failure is therefore a visible-literal test-harness mismatch, not source
drift and not evidence of a data, display, provenance, or scientific-result
change. Order 26a requires a stop on any additional failure, so no further test
edit or retry was made.

## Protected identities

All 27 checked protected and authority paths matched their accepted byte sizes
and SHA-256 identities after the parse and stopped test. The scientific RDS
files were hashed as bytes only and were not opened or compared.

| Protected file | Bytes | SHA-256 |
|---|---:|---|
| Order 26a | 3,814 | `2a918717486216f3642fea31fbd9d02da76fbad6d725a2e30d2b4a0354bbb765` |
| Preceding stopped record | 8,493 | `9de292ad59a9b0b8b00f60810fe1d54993a903a3dfa585fb0ac37c91043d3808` |
| Preceding stopped manifest | 4,082 | `80bb383ebd86fbc67753cf749da493ab2ac5166241b4a80ae1041e62820015a5` |
| Preparation 07 QMD | 39,361 | `ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae` |
| Nathealth profile | 7,404 | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| Prepared coverage RDS | 19,922,480 | `00085dc32ae370f059da9bfb6dfbf560eda4c4376fdb0727d2ef3c0b4fec34ee` |
| Current site-context RDS | 41,068 | `39ffe488de86f5d7cdc56d65c582c9de31f9054f8565936b4ec74e01491f26d0` |
| Current site-context CSV | 470,213 | `7dc64cc5026947ef96d6e4ab112bb767414420be97817f022082248db68d7028` |
| Site display registry | 295 | `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809` |
| Site metadata | 2,439 | `8aa5492ea357fa2e91b5d5fa3c9fd990ba82149632962320b4834e4e5693291b` |
| Eligible-day counts | 108 | `c80e41ddc53ad1d5a68d4dafd2adfc6c939b947b875d0286c6ebb6291fd833a4` |
| Selected days | 1,334 | `36490be48ae13b5da8f7534af35652b90a3ee4b4c83ab595c5deb28c1f4c5481` |
| Selection settings | 544 | `807039893f3a464472ab490fac192d1d8e5b4882fc78129ac29ab4834d926121` |
| Durable PNG | 808,132 | `a35e8189bdbdb450411bfe7f71d52964c17e45a7a26fdb44e82776d201b00ff3` |
| Durable SVG | 2,408,619 | `5ad003220cb1d5a1d2b223af206f4a1e608b4e1fa0e695d656989dde62b0ea4a` |
| Paired source-data CSV | 3,297,558 | `15e12011effbdf8fdbf7835be235b7b50406838278d411df023e924e81bea1e4` |
| Truthful historical manifest | 2,674 | `c5ca66b2a6ec4fabbe57d08135db7f365bcd123365caab6c987bcb2b62f7a322` |
| Display builder | 967 | `44a5d60a8fd6f97fa9a8f4fce29485e312efbe18fdaaa9d755d58a945a4389cb` |
| Display module | 25,549 | `d77ca354f9bc927c293a5160194c481343f8e14cfc014a9e6985f70694db1ba0` |
| Strict historical verifier | 18,675 | `9a39ce7ab8e99187fdf14f2b750c3e3f9aa308de127e75a4923639dfb84d49b6` |
| Equivalence audit report | 9,342 | `870cbb5d5f9414f61ee7db05b61a12eb51d56c9273e9ae7dfd05094984c47164` |
| Equivalence evidence | 4,824 | `0757fc175c44fd33e9d8b06e4f9352699c18bfe50bbcf1c65d141f3f36a1cb97` |
| Equivalence seal | 538 | `01a07b87799faeb8291bb6187ced96ab7abdcf2399ee77c5dcfd19d608b1194c` |
| Preceding render-stop record | 8,449 | `1e482a14f95cb23a4bbc80669b4619ad21ee8ce7e957f498fc88ac0d01bfa1ad` |
| Preceding render-stop manifest | 3,861 | `bb05d47604b26e0082c9059a22a5ff2dd091410dc153f60702d55fb9056df591` |
| Stale HTML | 271,468 | `e37609f5adab0a5b57ce96d0229e4bac07dae3c713fe28aca3da68066ba12bdc` |
| `renv.lock` | 603,493 | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

No scientific builder, strict verifier, fixed-seed selection, artifact
regeneration, model, prediction, bootstrap, simulation, Shapley calculation,
Quarto command, knitr command, HTML audit, browser QA, or render occurred.
Preparation 07 and all later renders remain held pending a separately bounded
coordinator disposition for the newly exposed test-harness mismatch.
