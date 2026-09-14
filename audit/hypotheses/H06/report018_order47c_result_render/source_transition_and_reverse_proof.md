# REPORT-018 H06 order 47c source transition

Status: PASS

## Exact source identities

- Accepted preimage: `notebooks/hypotheses/H06.qmd`, SHA-256 `2e88ad6b3a4aaffd2dfbf429a77c5d0865256554bb9b7799648fe63b976f1526`, 60,680 bytes.
- Authorized postimage: `notebooks/hypotheses/H06.qmd`, SHA-256 `d65c197cb37db32101d8a43fcdc80198ab599a95cb73259abd187c9b2b58d350`, 60,791 bytes.

## Exact transition

```diff
-#| label: exploratory-two-part-formulas
+#| label: tbl-h06-exploratory-two-part-formulas
+#| tbl-cap: "Exploratory two-part formulas."

-#| label: exact-confirmatory-formulas
+#| label: tbl-h06-exact-confirmatory-formulas
+#| tbl-cap: "Exact evaluated Wilkinson formulas."
```

Current locations are lines 1275-1276 and 1491-1492. The two R chunk bodies and every other source byte are unchanged.

## Reverse proof

The two approved metadata transitions were reversed in a temporary copy. The reconstructed file was byte-identical to the accepted preimage:

- reverse SHA-256: `2e88ad6b3a4aaffd2dfbf429a77c5d0865256554bb9b7799648fe63b976f1526`;
- reverse bytes: 60,680;
- byte comparison exit: 0.

The temporary preimage and reverse copy were stored under `/private/tmp/h06_order47c_preimage.Sm07B9/` during execution. They are not owner evidence dependencies.
