# REPORT-018 H07 order 53 stopped-state independent acceptance

Date: 2026-08-21

Status: `ACCEPTED_STOPPED_EXPECTED_CANONICAL_OUTPUT_CLEANUP`

## Disposition

The sole H07 preparation/provenance render, semantic hook, and dedicated manifest helper completed successfully. The owner then stopped before browser QA because Quarto removed the obsolete source-side HTML and its 15-file local asset tree.

The 16-path removal is accepted as canonical-output cleanup under REPORT-018. The current reader endpoint is `_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html`. The removed source-side outputs must remain absent. Their former hashes and byte counts remain historical evidence in the order-53 inventories and stopped-state record. They must not be restored or represented as live preparation-manifest members.

The raw reader-link failure is separately classified as a checker false negative. Three `javascript:void(0)` Quarto code controls are not filesystem or reader-navigation targets. All 405 applicable links resolve.

There is no source, scientific, semantic, navigation, or rendered-page defect established by this stop. Browser and final-size QA remain unconsumed.

## Independent R verification

The central checker is `scripts/report_harmonization/check_h07_order53_stopped_acceptance.R`, SHA-256 `cca5e26f8227479f250f16b1ee227ea1388b0edde46a33eba082549419c6fd93`, 14,440 bytes. Its verification table is `audit/report_harmonization/report018_h07_order53_stopped_independent_verification.csv`, SHA-256 `95b96b41fcb815d04ca4cd69ee53f05c7e7e49e5d45e38b4f2aeda712bd5628e`, 7,675 bytes.

R 4.6.1 reported:

```text
H07_ORDER53_STOPPED_INDEPENDENT_ACCEPTANCE=PASS checks=41/41 owner_manifest=47/47 live_manifest=1235/1235 removed=16 tables=21 figures=3 links=405 semantic=21/116/734/850 R=4.6.1 digest=0.6.39 xml2=1.6.0
```

The independent replay verified:

1. The owner stopped-state record is SHA-256 `22a0f7e6bd5ba808496138420a75c097600e4ce4276248233ce609d04211ee95`, 12,411 bytes.
2. The owner 47-row non-circular manifest is SHA-256 `0b059a86079ceea2a4e0922185903a24537065e5683efe976def238770eb7c85`, 9,273 bytes, with 47 of 47 paths live-exact and unique.
3. The accepted H07 result source and HTML remain exact at `c779c57f...` and `78148604...`.
4. The companion authoring and build QMDs are byte-identical at `a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b`, 49,762 bytes.
5. The fresh canonical companion HTML is SHA-256 `4c03a3e3cdfa1c6eac13d5785ceee8306e6d0941278b679a1eb88e357b270d93`, 654,955 bytes.
6. The preparation manifest is SHA-256 `db1b00058848d27eed9d5ece9d9eae97851d1bdc997c4f2fe28d2ce9abd3c8e2`, 335,146 bytes, with 1,235 of 1,235 unique non-circular rows live-exact.
7. The semantic hook reports `REPAIRED` for 21 tables, 116 IDs, 734 `headers` attributes, and 850 substitutions. Its ledger contains exactly 850 rows. Reverse and reapplication checks pass, visible and structural invariance checks pass, document IDs are unique, and 1,144 table-header tokens resolve.
8. The page contains 21 native gt tables, two PNG figures, and one top-down Mermaid. All 405 applicable links resolve. Nine country-coded study sites and the required navigation, phrases, formulas, source-data rows, and result links pass.
9. The unchanged result reader test passed. The stale preparation test remained byte-identical and unexecuted.
10. No browser QA or loopback server ran, and the final process audit found no relevant process or listener.

## Authorized next boundary

The owner may receive one separately sealed no-rerender continuation that performs only complete static revalidation against the preserved canonical HTML, secure-loopback viewport and final-size QA, teardown, and one completion or genuine-page-defect seal. The helper, tests, QMDs, HTML, manifest, profile, and scientific artifacts must remain byte-identical. No Quarto command or QMD execution is needed or authorized.

H08 and every later render remain held until independent H07 companion acceptance.

