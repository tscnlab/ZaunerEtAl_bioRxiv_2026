# REPORT-017 Preparation 07 figure-text source/test independent acceptance

Date: 2026-08-14

Outcome: **ACCEPTED FOR A SEPARATE TARGET-RENDER RELEASE.** The bounded
figure-theme repair and its focused-test repair are exact, reversible, and
source-only. The full Preparation 07 focused source test passes under R 4.6.1.
No render or browser session ran during this acceptance, so Preparation 07 and
every hypothesis render remain held until the coordinator issues a separate
render release.

## Accepted identities

| Item | SHA-256 |
|---|---|
| Preparation 07 QMD | `e5b89c62b03af2e7989f76cb9578608b92420978393a7c857fd5edcc335dbcb1` |
| Focused test | `9d3a19b7d30ee0a6d5b0b643da628e25e970b232cf2f812fae1efdb4fe8fff58` |
| Nature Health profile | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| Existing stopped HTML | `aa531fb4aef06d6ac897dfdbb9f493e83ad3d431d8e87b309cdffb31f0691401` |

The existing HTML is intentionally stale relative to the accepted 10 pt source
settings. It is not evidence about the repaired figures' final-size appearance.

## Source repair

Order 29 changed only four isolated display literals inside
`make_showcase_plot()`:

- `legend.title` from 9.5 to 10;
- `legend.text` from 9 to 10;
- `strip.text` from 9.5 to 10; and
- `axis.text` from 9 to 10.

`axis.title` remains 10. The source reverse proof reconstructs QMD SHA-256
`37cfe876cf687e874d44d08761cd8f5d18a7c3ad809aa99c9ee449072eb1b9c7`.
The numeric proof contains 402 tokens before and after, exactly four authorized
changes, and 398 unchanged tokens. The earlier independent stop acceptance
already verified that the existing HTML, 38 protected paths, and 817-file build
inventory did not change when the source-only test stopped.

## Focused-test repair

Order 29a changed only the existing typography assertion. It now requires
exact 10 pt `legend.title`, `legend.text`, `axis.text`, and `axis.title`
settings, plus a whitespace-tolerant `strip.text` block whose first size is
10. The assertion message and all other gates are unchanged.

Independent in-memory reverse substitution of lines 256 to 267 reconstructs
the accepted pre-edit test SHA-256
`958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163`
exactly. The owner's reverse proof records the same result.

## Independent verification

The complete source-only command

```text
Rscript tests/test_preparation07_report.R
```

ran under R 4.6.1 with the normal project profile and returned exit status 0:

```text
PASS: Preparation 07 satisfies the bounded-render, fixed-input, gt-table,
accessible-figure, site-display, and provenance contract.
```

The test received no HTML argument. It parsed the bounded QMD chunks but did
not execute them. No Quarto command, QMD chunk, browser, loopback server,
package operation, or scientific calculation ran.

The owner's non-circular manifest independently verifies 16/16 file hashes and
byte counts. Its post-test comparison verifies 38/38 protected paths as
unchanged. The QMD, profile, stopped HTML, data, stored figures, source data,
manifests, decisions, ledgers, and scientific outputs retain their accepted
identities. Scoped `git diff --check` passes for the focused test.

## Disposition

The Preparation 07 source and focused test are accepted. The next permissible
step is exactly one fresh target render of
`notebooks/preparation/07_example_days.qmd` through the Nature Health profile,
followed by the already approved focused, semantic, protected-identity,
seven-native-table, three-figure/source-data, durable PNG/SVG, desktop and
708-pixel secure-loopback visual, and listener-teardown checks. The repaired
10 pt figure text must be judged at final displayed size. No hypothesis render
is released by this acceptance.
