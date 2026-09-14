# REPORT-017 H01 order 32j stopped state

Date: 2026-08-20

Status: **STOPPED, new preparation-manifest cardinality defect**

## Outcome

The 28-row dispatch, 1,709-path protected inventory, 1,115-entry build inventory, helper parse, and exact helper reverse proof passed. The helper ran exactly once under normal R 4.6.1 project startup and exited 0. It restored both protected downloads and synchronized the build QMD exactly to the accepted authoring QMD.

The required 62-row postcondition failed because the unchanged dynamic script discovery produced 65 live-exact rows. The three additional current H01 scripts are:

- `scripts/hypotheses/H01/reconcile_h01_report016_deviations.R`
- `scripts/hypotheses/H01/refresh_h01_order32d_figures.R`
- `scripts/hypotheses/H01/refresh_h01_stage3_model_support_fdr_label.R`

All 65 rows are live-exact and no prior row was removed. The order's fixed cardinality is therefore incompatible with the helper's preserved all-H01-R-script discovery contract. No scientific result changed.

## Fail-closed disposition

The authorized four-row worker-manifest reseal was withheld. The worker manifest remains byte-identical to its dispatch identity and is 1653/1659 live-exact. Its six mismatches are exactly the two accepted historical result/profile transitions plus the four rows that order 32j intended to reseal.

The full no-render suite completed safely: five tests passed and two failed. The H01 preparation test contains a stale fixed-literal assertion for `17 prespecified light-exposure metrics`, while the exact accepted source uses `17-response package`. The global country-site test also reports two unrelated H04 line-wrap findings: Delft in the H04 result and Munich in the H04 companion.

The read-only companion audit passed all 21 contracts: 20 native gt tables, two figure endpoints, unique document IDs, 1,442 within-table header tokens, 1,471 explicit ID references, 780 reader links, two restored download links, reciprocal navigation, country-coded H01 sites, and reversible semantic repair.

Secure loopback visual QA and its static server were not started because the required manifest and test gates did not pass. No Quarto command, render, QMD execution, model, prediction, bootstrap, simulation, or other scientific computation ran.

## Current key identities

- helper: `da6e5c743d8eb693b35453b7a67344fb012344144697d2d0c0b94a0d91cbdcbf`, 8460 bytes
- authoring and build QMD: `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`, 55827 bytes each
- accepted companion HTML: `5ab6587465f01f946fcf133f9f81a69168e08fa866f69830c2378e6c3cf250fe`, 727310 bytes
- 65-row preparation manifest: `310a017f49992e8a4a17f8497b66112b8352364ef80526c11709c1f39155653e`, 14470 bytes
- unchanged worker manifest: `882c1e63290384723b47d1bf67eb524c6a18e21d710eb60c989067bfe08c387c`, 397567 bytes

## Required coordinator disposition

Issue one bounded continuation that either accepts the truthful 65-row manifest and updates the fixed cardinality contract, or explicitly defines why the three live H01 scripts must be excluded. The existing dynamic discovery behavior favors accepting 65 rows. The continuation must also classify the stale H01 preparation-test literal. The unrelated H04 country-site findings belong to the H04 owner.
