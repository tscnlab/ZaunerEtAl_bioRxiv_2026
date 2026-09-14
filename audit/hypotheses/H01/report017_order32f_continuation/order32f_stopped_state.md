# REPORT-017 H01 order 32f stopped state

Date: 2026-08-15

## Disposition

Order 32f stopped during the single authorized fresh-candidate run. The failure occurred before complete candidate validation and before any durable figure replacement, builder edit, test edit, manifest reseal, Quarto render, or browser QA. The partial candidate directory is retained intact at `/private/tmp/H01-order32f-candidates.eDOsrp`.

## Completed authorized work

- The 37-row order-32f dispatch and nested 41-row order-32e stopped-state seal were exact before mutation.
- The three authorized harness corrections were applied to `scripts/hypotheses/H01/refresh_h01_order32d_figures.R`.
- Air 0.4.1 was applied only to that refresh implementation.
- R 4.6.1 parsing passed.
- Pre-Air and post-Air abstract syntax trees were identical at SHA-256 `d4c6ab99ff51074687aab31e688bc619a94f728c6c710750314ca60793d9dd3e`.
- `air format --check` passed.
- The one required non-mutating preflight passed every contract. Its exact output is stored in `preflight_output.txt`.
- One fresh candidate directory was created and proved empty before use.
- The fresh candidate run was executed exactly once and exited nonzero.

## New fail-closed harness defect

The failure is at refresh-script lines 778 through 792. Inside the geometry-check `lapply()`, the expression `filter(.data$figure_id == figure_id)` resolves the right-hand `figure_id` through the data mask. It therefore retains all three `baseline_specs` rows instead of the current figure's one row. The subsequent one-row `mutate()` receives three `expected$png_width` values and stops with `expected_width must be size 1, not 3`.

This defect is outside the three corrections authorized by order 32f. It was not patched or retried.

## Partial validations completed before the stop

- All six source-derived baselines reproduced their exact expected PNG/SVG identities.
- All six durable figures retained their sealed identities.
- Figure 1 reproduced the exact source-to-sealed provenance transition: 9,477 changed pixels, x 1927 through 2496, y 2256 through 2325, and SVG lines 366 through 369 only.
- The current fresh candidates are byte-identical to the prior stopped order-32e candidates, but remain unaccepted because the complete validation package did not finish.

## Preservation

- Post-failure order-32f dispatch reconciliation is 36/37 exact. The sole expected difference is the authorized refresh implementation, from SHA-256 `999637d9d84ec3544db95d423b6c363d4d0c4ccfe588a76139bf6062e674638f` and 23,015 bytes to `10288d5fb28df713c43f52a5f3e984070d8062701a28a3e6eb4fe8d9d8b223aa` and 28,717 bytes.
- Post-failure nested order-32e seal reconciliation is 40/41 exact, with the same sole expected refresh-script transition.
- Both H01 QMDs, both durable HTML pages, the accepted builder, the Quarto profile, all six durable figures, all source-data CSVs, all tests, all manifests, the handoff, and all scientific artifacts remain unchanged.
- `/private/tmp/H01-order32e-candidates.hltKEs` remains 12/12 exact.
- `/private/tmp/H01-order32d-quarantine.Xc28uF` remains 3/3 exact.
- `/private/tmp/H01-order32d-candidates.nW90PN` remains empty.
- No model, inference, prediction, bootstrap, resample, Shapley calculation, or other scientific computation ran.
- No Quarto render, companion render, later-target render, commit, push, or upload ran.

## Exact refresh implementation identities

- Pre-order-32f copy: `999637d9d84ec3544db95d423b6c363d4d0c4ccfe588a76139bf6062e674638f`, 23,015 bytes.
- Post-correction, pre-Air copy: `e06bb2a29a09f13466c57dde57e25e3ba0028da95b99bb203a4e67b8e2346bef`, 28,663 bytes.
- Current post-Air implementation: `10288d5fb28df713c43f52a5f3e984070d8062701a28a3e6eb4fe8d9d8b223aa`, 28,717 bytes.
- Preflight script: `69a48992e3fcc9f2e5c951ebc8c5be2a215a60cf6be697928379dab82fc3d057`, 13,303 bytes.

## Required next decision

A separate bounded authorization is required to correct the geometry-check data-mask collision, rerun a new candidate attempt, and continue the held durable replacement, reseal, result render, and complete QA sequence. The current partial candidates must not be promoted.
