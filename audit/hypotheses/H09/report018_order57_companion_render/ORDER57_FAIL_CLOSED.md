# REPORT-018 H09 order 57 fail-closed record

Date: 2026-08-22

Status: **STOPPED after the sole authorized companion render failed.**

## Execution outcome

The complete pre-render gate passed before execution. It reproduced 8 of 8
non-matrix dispatch identities, 25 of 25 central release identities, 34 of 34
release pins, and 37 of 37 accepted H09 result identities. It also confirmed
22 parseable R chunks, 19 table endpoints, one figure endpoint, one top-down
Mermaid diagram, 23 relative link occurrences to 22 unique targets, 113 live
preparation-manifest rows plus the exact 19 classified historical transitions,
851 build files, zero build symlinks, 16 historical source-side support files,
and 488 protected files.

Exactly one Quarto invocation was made for
`audit/hypotheses/H09/H09_analysis_preparation.qmd` with the `nathealth`
profile, R 4.6.1, the accepted project library, the semantic hook, and the
fresh external semantic directory. The invocation exited with status 1 in
`tbl-h09-prep-input-identities` at source lines 285 to 349 because
`all(verified_inputs$Verified == "PASS")` was false.

No retry was attempted. The conditional preparation-manifest helper was not
run because the render and semantic hook did not succeed. No browser QA was
started because the nonvisual gate did not pass.

## Exact blocking identities

The rendered input-identity assertion failed for exactly three of the eleven
required inputs:

| Input role | Recorded SHA-256 | Current SHA-256 | Recorded bytes | Current bytes |
|---|---|---|---:|---:|
| `gap_timing_unaware_metrics` | `28266064c6213eae6046ec6469d0dae39529f56e60933dcd581cf96c8590e1a4` | `7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1` | 88,760 | 88,248 |
| `gap_manifest` | `af74cc9fa36e426222d9b5f2328e2261c00b14436feb8d86fbf137d0ff313267` | `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935` | 3,970 | 4,497 |
| `metric_display_registry` | `6c0adc3ca061ac49591d71243dd7ff0693311eb1f499836cf52c2742328b8154` | `c82db05a77cc50ce5b9dbd459c90997fa6bb7d87c0b8e880c1bf8186fad06ed0` | 3,182 | 3,203 |

The source-side `H09_input_audit.csv` still records its own stored
`hash_verified` and `rows_verified` fields as true for these rows, but its
recorded input identities no longer match the current files. This is a real
upstream provenance-contract discrepancy exposed by the document's bounded
identity check. This owner order does not authorize repinning, source edits,
or adjudication of whether the upstream data change is scientifically
invariant.

## Fail-closed preservation

Read-only postfailure checks confirmed:

- all 851 build files remained byte-identical to their pre-render identities;
- all 488 protected files remained byte-identical;
- all 16 historical source-side support files remained byte-identical;
- the external semantic directory remained empty because execution stopped
  before the post-render hook;
- both historical H09 tests remained byte-identical and were not executed;
- the helper remained byte-identical and was not executed;
- the 132-row preparation manifest remained at SHA-256
  `8e1d633262b33df64e45f0fc3fd677f4bb1e8a69120cb76a9b152509b94f0aaf`;
- the held canonical and historical source-side companion HTML files both
  remained at SHA-256
  `4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05`;
- the stale build companion QMD remained at SHA-256
  `4640129c38a5aabd874549ff8d5ebc74b736a16fe6f900f4654b1573b2b69f5c`;
- the Sass cache remained byte-identical; and
- no Quarto, Pandoc, H09 semantic, helper, retry, or task-owned loopback
  process remained after teardown.

The fresh external working and semantic directories are retained for
independent acceptance. Mandatory next action is coordinator review of the
three upstream identity transitions. A new render requires a new sealed owner
order.
