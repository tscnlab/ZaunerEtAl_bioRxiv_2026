# H04 REPORT-014/017 order 35a execution audit

Date: 2026-08-15

Order: `audit/report_harmonization/owner_orders/35a_h04_complete_test_contract_correction_and_source_seal.md`

Order SHA-256: `ffbcb9542427a611d10f284e880e13b690066f4e6dbd1f8f1d3919de2a8670f5`

Disposition: **PASS**

## Preflight

R 4.6.1 with `digest` 0.6.39 checked all 18 rows of
`audit/report_harmonization/report017_h04_order35a_dispatch_manifest.csv`.
All 18 hashes and byte counts matched before editing.

The result QMD remained
`63e815683e1e81dadd480aeb230c7913de7726aa9242f5ce89ec4a0e7e90471c`.
The companion QMD remained
`52160297aaaa65f9cc0e36839adb0fcbe86e55631c847476b5006f03d657e9da`.
No QMD was edited or executed.

## Exact test-only change

Only `tests/hypotheses/H04/test_h04_report017_source_harmonization.R`
changed. The four authorized corrections were:

1. complete the expected `tbl-h04-prep-output-map` SHA-256;
2. correct the expected identity of the first excluded audit HTML;
3. correct the expected identity of the second excluded audit HTML; and
4. remove only `ignore.case = TRUE` from the existing fixed-string scientific
   role check.

The exact zero-context unified diff is
`H04_order35a_four_change_diff.patch`. The reverse-proof CSV records one
forward and one reverse occurrence for every change. Reversing those four
changes in memory reconstructed the pre-edit file exactly:

- pre-edit SHA-256:
  `02e7494ad081f6395fe19ceca2ed3ded1fe8bc3e8dbaf550e3279f3406ac427f`,
  33,154 bytes;
- post-edit SHA-256:
  `934ec16dcd2b7e6c4b2771f09f35c0832d059d695c21c5b917ba3303bd16c19b`,
  33,144 bytes.

The corrected test parsed under R 4.6.1 before the sealed test sequence.

## Single sealed test sequence

The two prescribed commands were run once, in this order:

```text
Rscript --vanilla tests/hypotheses/H04/test_h04_participant_random_intercept_assessment.R
H04_ORDER35_AUDIT_CSV=audit/hypotheses/H04/report017_order35a/H04_order35a_source_audit.csv Rscript --vanilla tests/hypotheses/H04/test_h04_report017_source_harmonization.R
```

| Test | Exit | Wall time | Result |
|---|---:|---:|---|
| Participant random-intercept assessment | 0 | 3.127867875 s | Passed |
| REPORT-017 source harmonization | 0 | 0.846782166 s | 37/37 PASS, no R warning |

The source-audit CSV is
`09a9d857ef2dce9d46902678e9c5630bdcb4ace93cbc00f4a5d72aa4267f621d`,
8,648 bytes. It is identical to the coordinator's independently reconstructed
prospective audit output.

The test environment was:

- R 4.6.1;
- `digest` 0.6.39;
- `dplyr` 1.2.1;
- `tibble` 3.3.1;
- `readr` 2.2.0;
- `openssl` 2.4.2;
- `glmmTMB` 1.1.14;
- `lme4` 2.0.1;
- `performance` 0.17.1; and
- `insight` 1.5.2.

The participant-model package versions are read from the unchanged accepted
environment record. No model was fitted or regenerated.

## Preservation and whitespace checks

`H04_order35a_protected_identity_audit.csv` contains 18 PASS rows. Seventeen
dispatch identities remain byte-identical. The eighteenth row records the one
authorized test mutation and its exact order-35a post-edit identity.

The scoped command

```text
git diff --check -- tests/hypotheses/H04/test_h04_report017_source_harmonization.R audit/hypotheses/H04/report017_order35a
```

exited 0 with no diagnostic. Because these paths are untracked in the current
worktree, each new or changed file was also checked with
`git diff --no-index --check`. Each no-index comparison exited 1 solely because
content differs from its comparison file, and produced no whitespace-error
diagnostic.

## Boundary

No existing order-35 evidence, H04 handoff, scientific artifact, current or
historical manifest, HTML, figure, source data, model, diagnostic, script,
profile, shared file, bibliography, manuscript, package, or lockfile was
edited. No Quarto render, QMD execution, fit, prediction, simulation,
bootstrap, Shapley allocation, artifact regeneration, commit, push, or upload
occurred. REPORT-017 rendering remains held, and H01 remains the only active
render path.
