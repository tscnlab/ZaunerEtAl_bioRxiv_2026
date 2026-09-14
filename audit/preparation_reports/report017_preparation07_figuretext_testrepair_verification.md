# REPORT-017 Preparation 07 figure-typography test repair

Date: 2026-08-14

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Outcome: **PASS for the bounded test-only order.** The typography assertion
now checks the approved 10 pt source contract, the repaired test parses, and
the complete source-only focused test passes under R 4.6.1. Preparation 07
rendering remains held.

No QMD chunk was evaluated. No Quarto command, browser, loopback server, or
render ran. The QMD, existing HTML, profile, data, artifacts, manifests,
decisions, ledgers, lockfile, and scientific outputs were not edited.

## Authority and verified starting state

The controlling order is
`audit/report_harmonization/owner_orders/29a_preparation07_figure_typography_test_repair.md`,
SHA-256
`7ff6fe2381d488c57dc9c6c0b900c63512438877a88571f7bfbf099ad506cd33`.
Every starting pin matched before editing:

| Item | SHA-256 |
|---|---|
| Repaired Preparation 07 QMD | `e5b89c62b03af2e7989f76cb9578608b92420978393a7c857fd5edcc335dbcb1` |
| Stale focused test | `958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163` |
| Existing stopped HTML | `aa531fb4aef06d6ac897dfdbb9f493e83ad3d431d8e87b309cdffb31f0691401` |
| Nature Health profile | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| Owner source-test stop | `9fa4f2ae38ce697043a98ae20dabb03eeb626b2e5fb8abf85d4277122544b357` |
| Owner historical stop manifest | `79fddcba317def3b90142e9205d3821c746b894a291f0d8e9c8abd65d322a485` |
| Independent stop acceptance | `d12eb171be6f562c1c806f9233dde766699ac7b57ff9e9033d324f6ce0a82a76` |
| Independent historical manifest | `3d1fdb100484ac5fe2261c636232102eea50b66243044ef3a25a32f323ab925f` |

## Exact authorized assertion repair

Only the existing assertion body changed. Its message remains byte-identical:
`REPORT-011 figure typography contract is absent.`

```diff
-  grepl("axis.text = ggplot2::element_text(size = 9)", full, fixed = TRUE) &&
-    grepl("strip.text = ggplot2::element_text(", full, fixed = TRUE) &&
-    grepl("size = 9.5", full, fixed = TRUE) &&
-    grepl("legend.text = ggplot2::element_text(size = 9)", full, fixed = TRUE),
+  grepl("legend.title = ggplot2::element_text(size = 10)", full, fixed = TRUE) &&
+    grepl("legend.text = ggplot2::element_text(size = 10)", full, fixed = TRUE) &&
+    grepl(
+      "strip\\.text\\s*=\\s*ggplot2::element_text\\(\\s*size\\s*=\\s*10\\s*,",
+      full,
+      perl = TRUE
+    ) &&
+    grepl("axis.text = ggplot2::element_text(size = 10)", full, fixed = TRUE) &&
+    grepl("axis.title = ggplot2::element_text(size = 10)", full, fixed = TRUE),
```

The four single-line settings use fixed-string checks. The multiline
`strip.text` block uses one whitespace-tolerant Perl regular expression and
requires `size = 10,` as the first setting inside `element_text()`. The
repaired test is 12,075 bytes with SHA-256
`9d3a19b7d30ee0a6d5b0b643da628e25e970b232cf2f812fae1efdb4fe8fff58`.

Replacing only this assertion body with its four original lines reconstructs
the accepted pre-edit test SHA-256 exactly. The reverse proof is
`audit/preparation_reports/report017_preparation07_figuretext_testrepair_reverse_proof.csv`,
SHA-256
`daf0e7f44592719646e717f4d73f0151db61ebbe94cef1b9f167aa0af1fc5f91`.
A scoped `git diff --check` for the test and QMD passes.

## R 4.6.1 verification

The repaired test was parsed through normal project startup:

```text
/usr/bin/time -p Rscript -e 'parse(file = "tests/test_preparation07_report.R"); ...'
```

Result: PASS under R 4.6.1. The measured elapsed time was 16.35 seconds.

The complete source-only focused test then ran without an HTML argument:

```text
/usr/bin/time -p Rscript tests/test_preparation07_report.R
```

Result: exit 0 after 16.40 seconds with:

```text
PASS: Preparation 07 satisfies the bounded-render, fixed-input, gt-table,
accessible-figure, site-display, and provenance contract.
```

Both commands used normal `.Rprofile` and project renv startup. The only
additional output was renv's established informational dependency-discovery
note. No package was installed or updated. The focused test read and parsed
the 11 bounded QMD chunks but did not execute them.

## Protected identities

Relative to the sealed stopped-test state, the pre-run comparison contains
37 unchanged paths and exactly one authorized difference, the focused test.
The repaired pre-run inventory has SHA-256
`e4db74bb377e76115637c285971ae4449e5e2517341ad9b6cccafb35e26485fd`;
the comparison has SHA-256
`d64ca6f8a4970307394a2c9f23530c78275c1799a6cba89b5251930f88d57ba2`.

After parsing and testing, all 38 repaired-baseline paths are exact. The
post-test inventory is byte-identical to the pre-run inventory at SHA-256
`e4db74bb377e76115637c285971ae4449e5e2517341ad9b6cccafb35e26485fd`.
The explicit 38-row comparison has SHA-256
`85725beea82d98cd9d783e21a5be72c28bf4fcbbc16f8b4e3aaddb26e673ffed`.

The QMD, HTML, and profile remain at their required hashes. The nine-row
identity check is
`audit/preparation_reports/report017_preparation07_figuretext_testrepair_identity_checks.csv`,
SHA-256
`c45f1a4729b1a5fb3435b33a39564d1ab7588313f393a69303acc7d8b557a2bf`.

The two earlier stop manifests remain byte-identical historical seals. A
present-state replay of each now reports exactly one expected difference:
their truthful historical test pin is
`958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163`,
while this authorized repair is
`9d3a19b7d30ee0a6d5b0b643da628e25e970b232cf2f812fae1efdb4fe8fff58`.
No other manifest entry differs. The historical manifests were not edited or
reinterpreted as current-state inventories.

## Disposition

Order 29a is complete. The repaired source and test are preserved for
independent source/test acceptance. Preparation 07 rendering, browser QA,
and every hypothesis render remain held pending a separate release.
