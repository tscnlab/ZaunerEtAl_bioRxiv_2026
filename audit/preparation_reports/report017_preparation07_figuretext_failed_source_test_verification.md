# REPORT-017 Preparation 07 figure-text repair source-test stop

Date: 2026-08-14

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Target source: `notebooks/preparation/07_example_days.qmd`

Outcome: **STOP before render. The exact four-literal display repair is
confined, reversible, and protected-input safe, but the required source-only
focused test still asserts the replaced 9 pt and 9.5 pt literals and exits 1.**

No Quarto render ran. The stopped HTML and all 817 existing build files remain
byte- and mtime-identical to the accepted starting state. No browser or
loopback server was started. No scientific, preparation, durable display,
configuration, test, decision, ledger, lockfile, or hypothesis artifact was
changed.

## Authority and starting pins

The controlling order is
`audit/report_harmonization/owner_orders/29_preparation07_figure_text_repair.md`,
SHA-256
`725d7651ebe3c95a44d837cfdaf1770d9b9dc1be8dfedced8fd8c543823f9321`.
Every starting pin matched before the edit:

| Item | SHA-256 |
|---|---|
| Preparation 07 QMD | `37cfe876cf687e874d44d08761cd8f5d18a7c3ad809aa99c9ee449072eb1b9c7` |
| Focused test | `958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163` |
| Nature Health profile | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| Stopped HTML | `aa531fb4aef06d6ac897dfdbb9f493e83ad3d431d8e87b309cdffb31f0691401` |
| Owner figure-text stop | `4e6936d6094939d215da1a4341b63d3a4cc2eb7a27ffd558d2fe051e788a1b2f` |
| Owner stop manifest | `0c8a6c9039b844eced19c55bdce539b9c94ec0c64bbeb586f6fa6ff8e197f415` |
| Independent stop acceptance | `759496e47503a8b70e7b015cca0f572047d7efacb35aa689e3d70f0c0ca269d9` |
| Independent acceptance manifest | `2d4f21b2e7cfc2266d96ece77baf021f503fea5918caa7d8eb9560893436c80d` |

The prerepair protected inventory contains 38 paths at SHA-256
`cbc5b73492af6b0da0266baec59972fb5ffe7b98c6d6fd77a02e591852ff7b79`.
The prerepair build inventory contains 817 regular files at SHA-256
`9ab3459065c543e0531d26e00d5bf5b21c0d9aea46191c4e1573a92542aff641`.
The build-root symlink audit contains zero paths and has SHA-256
`ca8b6d442f48a783518fa17c21fde410d9f4da14acfcb0205891593b9fedded4`.

## Exact authorized source repair

Only the four ordered theme literals changed:

```diff
-      legend.title = ggplot2::element_text(size = 9.5),
-      legend.text = ggplot2::element_text(size = 9),
+      legend.title = ggplot2::element_text(size = 10),
+      legend.text = ggplot2::element_text(size = 10),
@@
-        size = 9.5,
+        size = 10,
@@
-      axis.text = ggplot2::element_text(size = 9),
+      axis.text = ggplot2::element_text(size = 10),
```

`axis.title = ggplot2::element_text(size = 10)` remains unchanged. The
post-edit QMD is 39,361 bytes with SHA-256
`e5b89c62b03af2e7989f76cb9578608b92420978393a7c857fd5edcc335dbcb1`.
Reversing only the four substitutions reconstructs the accepted pre-edit
SHA-256 exactly. The proof CSV has SHA-256
`b08623ad18169072172cb37241b6c67e717fb4216d0c576cde0044e0fa84fb31`.

Using the recorded numeric-token expression, both sources contain 402
numeric tokens. Exactly four tokens differ and the other 398 are identical.
The numeric-token proof has SHA-256
`a86c5f792111eacfca7573bce3e82a3d5ae5437d5a8c9cd2804b3878de78ff1d`.
The repaired protected inventory has SHA-256
`3a48482232fbf7a0b9d9832db353bde6e2467c5d387765012bbe9dc141187590`:
37 paths are unchanged and the QMD is the sole authorized difference. The
before/after comparison has SHA-256
`5d3105f89e47c20c3eda999303726368df4e5bbf21ef8ac6e36ebd55f74e4499`.

A source-scoped `git diff --check` for the Preparation 07 QMD and focused
test passes. The repository-wide command also reports pre-existing trailing
whitespace in concurrent descriptives and MDER audit files. Those paths are
outside this order and were not edited.

## Stopped source-only focused test

The required command was run through normal project startup with no HTML
argument and therefore did not evaluate a QMD chunk:

```text
/usr/bin/time -p Rscript tests/test_preparation07_report.R
```

It used R 4.6.1, the project root, the first library at
`renv/library/macos/R-4.6/aarch64-apple-darwin23`, and renv 1.2.3. Quarto
1.9.37 is installed, but no Quarto render command ran. The test exited 1 after
16.48 seconds with this exact assertion:

```text
Error: REPORT-011 figure typography contract is absent.
Execution halted
```

The preceding normal-profile message was renv's established informational
dependency-discovery note. No package was installed or updated.

The failure mechanism is a stale exact-literal test contract. Lines 257 to
260 of `tests/test_preparation07_report.R` require all of the following old
source strings:

- `axis.text = ggplot2::element_text(size = 9)`;
- a `strip.text` block containing `size = 9.5`; and
- `legend.text = ggplot2::element_text(size = 9)`.

Order 29 requires those exact three old sizes, plus the 9.5 pt legend title,
to become 10 pt. The repaired QMD therefore cannot satisfy this conjunction.
This is a source-test wording mismatch caused by the authorized display
repair, not a scientific discrepancy and not evidence of source or build
drift. No test repair was inferred or attempted.

## Preservation after the stop

All 38 repaired-baseline protected paths remain exact after the stopped test.
The post-test protected inventory is byte-identical to the repaired pre-render
inventory at SHA-256
`3a48482232fbf7a0b9d9832db353bde6e2467c5d387765012bbe9dc141187590`.
Its explicit 38-row comparison has SHA-256
`198efbd45086a0ec6398f3bcff5ae3fb413ab0207a3884c1e18bb11b8bf91263`.

The 817-path post-test build inventory is byte- and mtime-identical to the
accepted prerepair build inventory at SHA-256
`9ab3459065c543e0531d26e00d5bf5b21c0d9aea46191c4e1573a92542aff641`.
The complete comparison contains zero changed, added, or removed paths and
has SHA-256
`df6c750951f5747c66cfb14b80aa9a7d6532af11d49f5d3c8f8683b52d439ad3`.

The stopped HTML remains 297,095 bytes at SHA-256
`aa531fb4aef06d6ac897dfdbb9f493e83ad3d431d8e87b309cdffb31f0691401`.
The durable showcase PNG, SVG, and paired source CSV remain exact at:

- `a35e8189bdbdb450411bfe7f71d52964c17e45a7a26fdb44e82776d201b00ff3`;
- `5ad003220cb1d5a1d2b223af206f4a1e608b4e1fa0e695d656989dde62b0ea4a`;
  and
- `15e12011effbdf8fdbf7835be235b7b50406838278d411df023e924e81bea1e4`.

## Disposition

Preparation 07 is stopped at the required source-only focused-test gate. The
authorized four-literal QMD repair and all evidence are preserved for a
separately bounded coordinator disposition. No target render, browser QA,
server lifecycle, hypothesis render, or scientific computation occurred.
