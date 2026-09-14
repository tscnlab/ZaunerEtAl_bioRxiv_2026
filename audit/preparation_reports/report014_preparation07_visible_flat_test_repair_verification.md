# REPORT-014 Preparation 07 visible-flat test repair verification

Date: 2026-08-14

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Outcome: **PASS. The two authorized test search targets now use the existing
whitespace-normalized `visible_flat` object. The complete source-only focused
test passes under R 4.6.1.**

No Quarto or knitr command was run. No QMD chunk, strict verifier, builder,
selection routine, or scientific computation was executed. No QMD, HTML,
configuration, data, artifact, manifest, production script, decision, ledger,
lockfile, or handoff was edited.

## Authority and exact starting state

The controlling order was
`audit/report_harmonization/owner_orders/26b_preparation07_visible_flat_test_repair.md`,
SHA-256
`3d53cdb732812354e461c825726cef163c6da1c584dc252e58f07456e10bec3a`.
The preceding stopped checkpoint and its non-circular manifest remained exact:

- `audit/preparation_reports/report014_preparation07_test_classification_failed_focused_test_verification.md`:
  `8c784d8e424304b980e73a64088a96b49e0e61e6a20a69b573f00f73e3c34369`;
- `audit/preparation_reports/report014_preparation07_test_classification_failed_focused_test_manifest.csv`:
  `9e26c5e2022cfd71e7be5f4e3f59745e45db8e65fe53f33de8d42c7bdc72f3b2`.

Both released pins matched immediately before editing:

| File | Starting SHA-256 | Bytes |
|---|---|---:|
| `notebooks/preparation/07_example_days.qmd` | `ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae` | 39,361 |
| `tests/test_preparation07_report.R` | `a22182cb9b15e96d5c9e8dd66e98c486345d996c947ca757044f0bdbe0a96457` | 11,887 |

## Exact two-line repair

Only `tests/test_preparation07_report.R` changed. Its post-edit identity is
`958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163`
with 11,897 bytes. The exact zero-context diff is:

```diff
@@ -264,2 +264,2 @@
-  grepl("figure source-data CSV", visible, fixed = TRUE) &&
-    grepl("split into three three-panel figures", visible, fixed = TRUE),
+  grepl("figure source-data CSV", visible_flat, fixed = TRUE) &&
+    grepl("split into three three-panel figures", visible_flat, fixed = TRUE),
```

Both required phrases, the error message, and every other assertion remain
unchanged. The accepted QMD remained byte-identical at
`ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae`.

## R 4.6.1 verification

The normal-profile parse command returned exit status 0:

```text
R version 4.6.1 (2026-06-24)
test_parse=PASS
```

The authorized source-only command was then run without an HTML argument:

```text
Rscript tests/test_preparation07_report.R
```

It returned exit status 0:

```text
PASS: Preparation 07 satisfies the bounded-render, fixed-input, gt-table, accessible-figure, site-display, and provenance contract.
```

Normal startup emitted renv's informational dependency-discovery note. It did
not alter `renv.lock` or another protected identity.

## Reversibility and diff hygiene

The unified pre-to-post patch was reverse-applied in memory to the post-edit
test. The reconstructed SHA-256 was exactly
`a22182cb9b15e96d5c9e8dd66e98c486345d996c947ca757044f0bdbe0a96457`,
which reproduces the released starting test byte-for-byte. `git diff --check`
passed for the focused test.

## Protected-identity result

All 30 checked authority and protected paths matched their accepted byte sizes
and SHA-256 identities after parsing and the passing focused test. This set
covered the QMD, stale HTML, profile, strict verifier, truthful historical
manifest, sealed equivalence audit inputs, both preceding stopped checkpoints,
the complete 15-path Preparation 07 scientific/display set, and `renv.lock`.
The scientific RDS files were hashed as bytes only and were not opened or
compared.

Key final identities were:

| File | SHA-256 |
|---|---|
| Preparation 07 QMD | `ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae` |
| Focused test | `958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163` |
| Nathealth profile | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| Stale HTML | `e37609f5adab0a5b57ce96d0229e4bac07dae3c713fe28aca3da68066ba12bdc` |
| Strict verifier | `9a39ce7ab8e99187fdf14f2b750c3e3f9aa308de127e75a4923639dfb84d49b6` |
| Historical showcase manifest | `c5ca66b2a6ec4fabbe57d08135db7f365bcd123365caab6c987bcb2b62f7a322` |
| Current site-context RDS | `39ffe488de86f5d7cdc56d65c582c9de31f9054f8565936b4ec74e01491f26d0` |
| Equivalence audit report | `870cbb5d5f9414f61ee7db05b61a12eb51d56c9273e9ae7dfd05094984c47164` |
| Equivalence evidence | `0757fc175c44fd33e9d8b06e4f9352699c18bfe50bbcf1c65d141f3f36a1cb97` |
| Equivalence seal | `01a07b87799faeb8291bb6187ced96ab7abdcf2399ee77c5dcfd19d608b1194c` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

The paired non-circular manifest records every checked path, byte count, role,
and SHA-256 identity. No scientific builder, strict verifier, fixed-seed
selection, artifact regeneration, model, prediction, bootstrap, simulation,
Shapley calculation, Quarto command, knitr command, HTML audit, browser QA, or
render occurred. Preparation 07 and all later renders remain held pending
independent source/test acceptance and a separate render release.
