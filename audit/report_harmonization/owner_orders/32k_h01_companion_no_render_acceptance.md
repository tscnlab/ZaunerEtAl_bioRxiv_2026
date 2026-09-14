# REPORT-017 order 32k: H01 companion no-render acceptance

Date: 2026-08-20

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: authorized final no-render continuation; no Quarto command is authorized

## Purpose

Accept the truthful 65-row H01 preparation manifest produced by order 32j,
correct one classification-stale source-test literal, directly reseal five
current worker-manifest rows, run the complete H01 non-render checks, and
complete secure-loopback visual QA on the existing companion HTML.

This is one consolidated continuation. Do not rerun the preparation-manifest
helper. Do not render. Return one complete acceptance or one combined stopped
state only for a genuinely new mismatch.

Controlling harmonizer records:

- order-32j stopped-state independent acceptance:
  `audit/report_harmonization/report017_h01_order32j_stopped_independent_acceptance.md`,
  SHA-256
  `0f3269ff7c027d0b896d5f16a300164ff453bfc0ec7bda3e56bc497334e1f158`;
- 23-row non-circular acceptance manifest:
  `audit/report_harmonization/report017_h01_order32j_stopped_acceptance_manifest.csv`,
  SHA-256
  `7d32414236f9152028083fc8ceb91a22105ce72016208dcc284f18c482021a23`;
- owner stop:
  `audit/hypotheses/H01/report017_order32j_no_render_finalization/order32j_stopped_state.md`,
  SHA-256
  `32bd4cbc03396da17d4f701a674ad49d1969afd4519f34107037f1ad42796e9e`;
- owner 60-row evidence manifest, SHA-256
  `79235526da709ca63d4531b1d5e34588f9482bf5992738bf5fe69ab1a4299a1c`.

The coordination-matrix identity at dispatch is evidence only. It is not a
mutable owner execution pin while path-disjoint source-only work proceeds.

## Hard preflight pins

Before mutation, require every row in the order-32k dispatch manifest to match
its exact SHA-256 and byte count. In particular, require:

- accepted helper, which is protected and must not run:
  `scripts/hypotheses/H01/build_h01_preparation_report_manifest.R`,
  `da6e5c743d8eb693b35453b7a67344fb012344144697d2d0c0b94a0d91cbdcbf`,
  8,460 bytes;
- authoring companion QMD and synchronized build QMD:
  `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`,
  55,827 bytes each;
- accepted companion HTML:
  `5ab6587465f01f946fcf133f9f81a69168e08fa866f69830c2378e6c3cf250fe`,
  727,310 bytes;
- accepted result QMD and HTML:
  `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`
  and
  `df78ac3c2ed91515058b6af38e01b85b4baae74118699c008a29ba4dacf4d007`;
- Nature Health profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- truthful 65-row preparation manifest:
  `310a017f49992e8a4a17f8497b66112b8352364ef80526c11709c1f39155653e`,
  14,470 bytes;
- pre-reseal worker manifest:
  `882c1e63290384723b47d1bf67eb524c6a18e21d710eb60c989067bfe08c387c`;
- preparation test:
  `379414830e5bcd656ac460c2ad93616ecbcab104259c56a8fcf9296da8c0f2c4`,
  10,993 bytes;
- reporting and REPORT-016 tests:
  `48f374cc70b69a6d96a95dc425ffd9676b2e83133a5554ae1c19eda939c0c8af`
  and
  `140cc2d0305026885f8703e2aa349d324d1cef9a8d7d92c9b72314d845d0f8ab`;
- semantic wrapper and engine:
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`
  and
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- both protected source CSVs and restored downloads at their exact shared
  identities `760e634f...`, 4,818 bytes, and `28cc582f...`, 2,860 bytes.

Require the preparation manifest to have exactly 65 unique paths, no self-row,
all identities live-exact, exactly the three accepted additions relative to
the 62-row preimage, and no removals. Require the worker manifest to have
exactly six live mismatches: the four order-32j current rows plus the two
established historical result-HTML and profile rows.

Stop before mutation on any other drift.

## Authorized mutable paths

Only these existing paths may change:

1. `tests/hypotheses/H01/test_h01_preparation_report.R`;
2. `artifacts/12_manifests/H01_worker_artifacts.csv`.

New order-32k snapshots, exact diff and reverse proof, row-level reseal
evidence, test logs, semantic/link audits, protected inventories, global and
H01-scoped country-site evidence, loopback lifecycle records, screenshots,
visual measurements, and the non-circular completion manifest may be written
only under
`audit/hypotheses/H01/report017_order32k_companion_acceptance/`.

No other project or build path may change.

## One exact test repair

In `tests/hypotheses/H01/test_h01_preparation_report.R`, replace only the
literal:

```text
17 prespecified light-exposure metrics
```

with:

```text
17-response package
```

Preserve every other byte and test gate. Before editing, retain an exact
preimage. Require one-hunk diff evidence, R 4.6.1 parse, and reverse
substitution that reproduces SHA-256
`379414830e5bcd656ac460c2ad93616ecbcab104259c56a8fcf9296da8c0f2c4`.

Do not run a preliminary project test before this complete authorized edit.

## Direct five-row worker-manifest reseal

Do not run any manifest builder. Update only the SHA-256 and byte fields for
these five existing unique rows, in leaf-up dependency order, to their live
post-edit identities:

1. `scripts/hypotheses/H01/build_h01_preparation_report_manifest.R`;
2. `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.qmd`;
3. `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html`;
4. `artifacts/12_manifests/H01/H01_preparation_report_manifest.csv`;
5. `tests/hypotheses/H01/test_h01_preparation_report.R`.

Preserve every other field, row, and row order. Verify the two restored
download rows against their exact live hashes and bytes without changing
them. Preserve the historical result-HTML and profile rows unchanged and
classified as historical. Fail on any duplicate target path, sixth rewritten
row, unexpected live mismatch, self-row, or circular dependency.

Record exact five-row before and after values and a reverse proof that restores
the full pre-reseal worker-manifest bytes.

## Complete no-render verification

Run under R 4.6.1:

1. the complete H01 preparation test;
2. the complete H01 reporting test;
3. the complete H01 REPORT-016 deviation-reconciliation test;
4. the accepted semantic ID, header, and supported-IDREF audit against the
   existing companion HTML;
5. reader-link, preregistration-deviation, and navigation contracts;
6. current preparation and worker manifest audits;
7. the complete H01 protected scientific and build-identity reconciliation;
8. an H01-scoped country-code audit; and
9. the unchanged global country-code test only to confirm its exact expected
   failure set.

Require the H01 companion to retain exactly 20 native gt-table endpoints, two
figure endpoints, zero duplicate IDs, 1,442 resolving header tokens, 1,471
resolving supported ID references, all reciprocal and deviation links, both
downloads, active navigation, nine country-coded study sites, and no raw
error, warning, stderr, unresolved reference, or forbidden local/build link.

The global country-code test must report exactly and only:

- `notebooks/hypotheses/H04.qmd:886`, bare `Delft` caused by source wrapping;
- `audit/hypotheses/H04/H04_analysis_preparation.qmd:914`, bare `Munich`
  caused by source wrapping.

Record that exact two-path failure set durably before any H04 work may begin.
Any additional global finding is a new mismatch and stops this order.

After the direct reseal, the worker manifest may differ from live files only at
the two established historical result-HTML and profile rows. The 65-row
preparation manifest must remain byte-identical and 65 of 65 live-exact.

## Secure loopback visual QA

Use the active `$quarto-authoring` bounded loopback procedure without
rendering. Record source, profile, companion HTML, and scoped build hashes.
Preflight `_build/nathealth` for symlinks and stop if any symlink resolves
outside that root.

Start one temporary read-only static server rooted exactly at
`_build/nathealth`, bound only to `127.0.0.1` on one unused high or ephemeral
port. Record command, PID, address, port, document root, start time, and exact
URL. Navigate only to:

```text
audit/hypotheses/H01/H01_analysis_preparation.html
```

Inspect at 1,440 by 1,000 pixels, 708 by 1,000 pixels, 200 percent zoom, and
the intended final display sizes. Inspect headings, callouts, all 20 tables,
both figures, the top-to-bottom Mermaid, captions, notes, reciprocal and
download links, navigation, typography, wrapping, clipping, overlap, page
overflow, and horizontal-scroll affordances.

HTML tables must work reasonably at typical desktop and laptop sizes. At
narrow width, a wide table may use a contained, usable horizontal scroller.
For any exported table representation, its PNG is the controlling final-size
visual check.

Capture screenshots and measurements. Stop the server immediately after QA,
verify process exit and no remaining listener, reset the viewport, and rehash
the complete preflight set. Browser inspection must not change any build file.

## Completion and stop rule

Return one combined record with exact commands, R and consequential package
versions, test pre/post identities, five-row worker-manifest proof, 65-row
manifest audit, complete test results, semantic and link counts, exact H04-only
global failure set, visual measurements, screenshots, server lifecycle,
protected reconciliation, and one non-circular manifest that excludes itself.

If any genuinely new mismatch remains, finish all safe read-only inspection,
do not patch or retry, and return one combined stopped-state defect list.

No helper rerun, Quarto command, render, QMD or HTML edit, scientific
execution, artifact regeneration, broad manifest builder, profile, semantic
tool, central ledger, package or lockfile change, commit, push, upload, or
later-target release is authorized. H01 remains the sole integration path.
H02 and every later render remain held.
