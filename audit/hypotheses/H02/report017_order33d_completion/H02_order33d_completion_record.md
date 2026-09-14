# H02 order 33d/33e source-only completion record

Date: 2026-08-20

Status: PASS, awaiting independent harmonizer acceptance

## Scope

This record seals the final source-only verification authorized by REPORT-014
and REPORT-017 orders 33d and 33e. No Quarto render, QMD execution, model fit,
prediction, simulation, bootstrap, Shapley allocation, p-value calculation,
figure or table regeneration, package change, commit, or push was performed.

## Fresh baseline and stopped-evidence snapshot

The verifier used only the independently recovered baseline at
`/private/tmp/H02-order33-recovered.7uqdRv`. Before mutation, R 4.6.1 verified
all six files against the durable inventory by SHA-256, byte count, and full
Git blob identity.

The complete order-33c stopped evidence was copied into
`audit/hypotheses/H02/report017_order33c_stopped/`. All 14 copies are
byte-identical to their stopped sources. The external snapshot manifest is
`audit/hypotheses/H02/H02_order33c_stopped_snapshot_manifest.csv`, SHA-256
`c49590c4557cfde17588fa904e7e464ce7db7cdb65b38a304204533a80d66fb5`.

## Authorized test correction

Only `collect_call_heads()` in
`tests/hypotheses/H02/test_h02_preparation_report.R` was edited. The expression
and pairlist traversal and the call-argument traversal now use indexed loops
that skip only children identical to `quote(expr = )`.

- pre-edit SHA-256: `d7ff45696f15d7bc02e8e66adabd02ee0c1f952f71fca35280885418c6b1181b`,
  14,726 bytes;
- post-edit SHA-256: `ead7a55246a2625b1382acc302b6004892dbf7f7830285f2bae830cb0859d3f8`,
  14,895 bytes;
- R 4.6.1 parse check: PASS;
- exact reverse substitution: reproduced the pre-edit SHA-256 and byte count.

No preliminary project test was run.

## Single complete verifier invocation

The unchanged verifier, SHA-256
`ce7ad12f41e728ec3faf271855b0cdf82545ca934b3b1efbaedd3f265a5a7c2a`,
was invoked exactly once with:

```text
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 Rscript --vanilla audit/hypotheses/H02/report017_order33_source_rewrite/run_h02_order33_source_audit.R /private/tmp/H02-order33-recovered.7uqdRv audit/hypotheses/H02/report017_order33_source_rewrite
```

The process exited with status 0 and reported:

- 42 of 42 audit checks PASS;
- three of three focused tests PASS;
- 53 source-manifest rows;
- source-manifest row audit PASS;
- 15 result tables and five result figures in the accepted order;
- 16 companion tables and four companion figures in the accepted order;
- 22 registration-link occurrences and 18 unique central anchors;
- the exact six-path worker and three-path preparation historical mismatch
  sets;
- 30 of 30 protected identities; and
- scoped Git diff check PASS.

## Bounded change audit

Relative to the 31 exact order-33d dispatch rows, exactly seven rows changed:

1. the authorized preparation test;
2. `H02_order33_current_identities.csv`;
3. `H02_order33_execution_record.md`;
4. `H02_order33_source_audit.csv`;
5. `H02_order33_source_diff.patch`;
6. `H02_order33_source_manifest.csv`; and
7. `H02_order33_test_results.csv`.

The latter six are outputs written by the unchanged verifier. The other 24
dispatch rows remained byte-identical. Both H02 QMDs, the reader and paired
tests, verifier, handoff, historical manifests and HTML, shared profile,
lockfile, and all protected scientific artifacts remained unchanged.

## Final verifier-written identities

| File | SHA-256 | Bytes |
|---|---|---:|
| `H02_order33_current_identities.csv` | `f5f218c3e572d31a173acf18fae348665ab0f01bf5591e5289b4540d390cb27b` | 4,833 |
| `H02_order33_execution_record.md` | `20d02334c50e6a59f886696e1afe84843f49fe904f6845db0f20d4fd59a818c9` | 2,415 |
| `H02_order33_source_audit.csv` | `c6d225bfc387c5f8f8619eaea69edc4dc9a8c544802d7c620677be7e4403de6d` | 16,768 |
| `H02_order33_source_diff.patch` | `50ba79d1976aa6149421dfa4ddec114b0b165cc0187ef71b9a8b6b2e498a3eaa` | 75,915 |
| `H02_order33_source_manifest.csv` | `d09677da2f5969a20f08987b7a164969db2885d4e811d2df5092d86c02ae20aa` | 14,272 |
| `H02_order33_test_results.csv` | `43ef8e01783f59e52f268e279ca65808e39bfc254d061ef90cf3d83ce48633d9` | 1,060 |

The separate completion manifest is non-circular: it inventories this record
and all sealed inputs and outputs but does not inventory itself.
