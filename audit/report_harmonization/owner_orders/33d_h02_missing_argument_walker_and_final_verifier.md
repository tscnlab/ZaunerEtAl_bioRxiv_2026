# REPORT-014/017 order 33d: H02 missing-argument walker and final verifier

Date: 2026-08-15

Owner: H02 task `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`

Status: prepared for coordinator review and release

## Purpose

Order 33c verified the recovered baseline and reached the full source-only suite. Its only failure is a recursive test walker that cannot traverse five ordinary missing pairlist elements in parsed R function formals. Independent review applied the bounded walker correction on a temporary copy and ran the complete preparation source-only test to PASS. This order preserves the order33c stopped evidence, applies that one test correction, and permits one final complete verifier invocation.

Controlling review:

`audit/report_harmonization/report017_h02_order33c_walker_stop_independent_acceptance.md`

## Exact preflight pins

Stop without editing if any hard pin differs:

- result QMD: `4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d`;
- companion QMD: `92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1`;
- reader test: `0b044d2995645f6cfa50e28e2bdf330b8801002761a84520b169a1a3eb6771db`;
- preparation test: `d7ff45696f15d7bc02e8e66adabd02ee0c1f952f71fca35280885418c6b1181b`;
- paired-placement test: `873c43f0d863c78c22e3e0635d054f09bc521a24d618afcda134a831ac7e7d8a`;
- unchanged verifier: `ce7ad12f41e728ec3faf271855b0cdf82545ca934b3b1efbaedd3f265a5a7c2a`;
- recovered baseline directory: `/private/tmp/H02-order33-recovered.HO2BJm`;
- durable recovered-baseline inventory: `e6f7869f1d32cecbfb7f421726731f8bfbbaab0c9f62bbc72f6fa6537344df49`;
- recovery verification: `dfa414ff95c9eaab475a1b7912be42c8eaccba00b46367f199ed834413551994`;
- order33c stopped execution record: `850b07056c1f6191d5890f33ec41a79d0189327449ebfb0af3daf2638d6970d6`;
- order33c stopped source audit: `47f258e8221979a726debdbc2fd72a8ac953c19e63cca046d79566b846053d72`;
- order33c stopped test results: `2d8023eea95dd0ac32eec2c7f9586ea29a321a709d761ab871fb5fa0f986f43e`;
- order33c stopped source manifest: `f1f4e990159518de9bc2d446cacc5f96c3d3f9c2dd764cc86d290e8699152420`.

The harmonizer coordination-matrix identity is dispatch evidence only, not an owner execution pin while disjoint source-only orders are active.

## Preserve the complete order33c stopped evidence first

Before editing, create `audit/hypotheses/H02/report017_order33c_stopped/`. Copy every one of the 14 current files from `audit/hypotheses/H02/report017_order33_source_rewrite/` into it without changing names or bytes. Create a non-circular snapshot manifest outside the copied set that records each source path, snapshot path, SHA-256, and byte count. Require exact source-to-snapshot equality before continuing.

Do not replace, normalize, or reinterpret the copied evidence. It is the historical record of the 41/42 and 2/3 stop.

## Only authorized test edit

Edit only `tests/hypotheses/H02/test_h02_preparation_report.R` inside `collect_call_heads()`:

1. Replace `for (element in node) visit(element)` for expression and pairlist traversal with an indexed `seq_along(node)` loop. Skip only children identical to `quote(expr = )`; recurse into every other child.
2. In the existing call-argument loop over indices 2 through `length(node)`, add the same missing-child guard before recursion.

Do not change `call_head_name()`, the forbidden-call set, any source/HTML/manifest assertion, or any other test line. The post-edit test must be SHA-256 `ead7a55246a2625b1382acc302b6004892dbf7f7830285f2bae830cb0859d3f8`, 14,895 bytes. Record an exact reverse proof to the pre-edit identity and an R 4.6.1 parse check. Do not run a preliminary focused test.

## One final verifier invocation

After the snapshot and test edit pass their structural checks, run exactly once:

```sh
NATHEALTH_PROJECT_ROOT=<project-root> Rscript --vanilla audit/hypotheses/H02/report017_order33_source_rewrite/run_h02_order33_source_audit.R /private/tmp/H02-order33-recovered.HO2BJm audit/hypotheses/H02/report017_order33_source_rewrite
```

Expected completion is 42 of 42 audit checks, three of three focused tests, 53 source-manifest rows, and a passing non-circular row audit. If startup or any assertion fails, stop once, preserve all output, and do not patch or retry.

If the verifier passes, create only bounded H02-owned order33d completion evidence and a non-circular manifest. Prove that the 14-file order33c stopped snapshot remains exact, both QMDs and all scientific/protected/historical-render identities remain unchanged, only the authorized preparation test and verifier-written current evidence changed, and scoped `git diff --check` passes.

## Prohibitions and holds

Do not edit either QMD, the reader or paired test, verifier, recovered baseline, historical manifest, HTML, handoff, scientific artifact, shared profile, central ledger, harmonizer record, package, or lockfile. Do not run Quarto, execute a QMD, fit or refit, predict, simulate, bootstrap, rerun Shapley allocation, recalculate a p-value, regenerate a figure, render, commit, push, or upload.

H02 rendering remains held. H01 remains the only active render path.
