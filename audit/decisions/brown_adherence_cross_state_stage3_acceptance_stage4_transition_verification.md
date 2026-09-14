# Brown adherence cross-state Stage 3 acceptance and Stage 4 transition verification

Date: 2026-08-21  
Status: pass  
Decision: `BA-016`  
Change: `CHG-155`

## Verification command and environment

The durable checker is:

`scripts/report_harmonization/check_brown_ba016_stage3_acceptance_stage4_transition.R`

It was parsed and executed from the central project with:

```text
Rscript --vanilla scripts/report_harmonization/check_brown_ba016_stage3_acceptance_stage4_transition.R /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026 /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026
```

Environment:

- R version 4.6.1 (2026-06-24)
- digest 0.6.39
- no model package loaded
- no model fit, prediction, inference, resampling, QMD execution, render, or
  browser server started by this verification

## Central authority and ledgers

The controlling decision is:

`audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition.md`

SHA-256: `985c865228d392b8721810d33c5fe89cfc73163393b52ce3074752fda2192ebe`

The checker is:

`scripts/report_harmonization/check_brown_ba016_stage3_acceptance_stage4_transition.R`

SHA-256: `76f06edb7ad1ce080f532bcb64300302e5efcebdad1c03cc1fb95fe631a7e2cb`

The central ledgers parse under R 4.6.1 and contain exactly one `BA-016` row
and exactly one `CHG-155` row. Both have status
`author_approved_stage3_stage4_authorized` and point to the controlling
decision.

Post-transition ledger identities:

| Ledger | Bytes | SHA-256 |
|---|---:|---|
| `audit/ledgers/decision_register.csv` | 147,325 | `7424b0ada651534f6108ce90b96343c27f47cefb7c0fbe7cb4c5b2eeb19911e6` |
| `audit/ledgers/change_log.csv` | 212,363 | `734d313e41171d280ce97d1ce7ff74c3ea68bd7c604a51409feb0ecd5d968a42` |

## Accepted package verification

The author supplied the exact required approval wording. The checker verified
the historical renewed gate, the central closure wording, and the new
`BA-CS-G4-REVIEW` stop.

The accepted task package passed:

- 76 of 76 fallback final-manifest members exact by path, byte count, and
  SHA-256;
- unique paths and a non-circular final manifest;
- 19 of 19 fallback-source checks;
- 27 of 27 fallback-candidate checks;
- 24 of 24 post-canonical checks;
- 28 of 28 replacement-render checks;
- 24 of 24 native visual checks;
- 10 of 10 deterministic 390-pixel checks;
- 10 of 10 intended-size figure checks;
- 21 of 21 finalization checks; and
- complete loopback teardown, no listener, post-QA hash stability, and
  removal of the temporary served copy.

The accepted identities include:

| Artifact | SHA-256 |
|---|---|
| Stage 3 QMD | `80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997` |
| Stage 3 HTML | `9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0` |
| 76-member final manifest | `69033a670469ba3c511afdd0dce0caa9cf55bc946af548d795584043442e3a21` |
| Stage 3 handoff | `d6a41b2988269a1af064b58130f6de8b54d00b787ba32d904e281fb6d145fd0e` |
| historical author gate | `e1347a11e65ecc78ab6da59f2fa2771728b1e796588b87342c113cf75ddb2616` |
| paired BA-M6 display source | `4c2d18282cd222930f91edac6606fd0a98ee313c975728a0cfe372ded565c1fc` |
| final BA-M6 PNG | `c2c58e3c8119457975d57e94b062ddba41ca828ad4326b1e1e6ac19bb7f1151a` |
| final BA-M6 SVG | `126acff6b1794864fc5b5797915046f884cc0890d445adc2aa437058f6d90fe0` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

## Scientific verification

R 4.6.1 read only the sealed CSV artifacts for the scientific result check.
It did not open a live model fit or recalculate an estimand.

The `BA-M6` primary file contains exactly 27 rows and exactly three
BH-significant localizations:

| State | Site | Difference, percentage points | BH-adjusted p-value |
|---|---|---:|---:|
| Wake | Dortmund (DE) | +15.000345 | 0.0039199900 |
| Wake | Madrid (ES) | -9.205294 | 0.0423087402 |
| Sleep | Kumasi (GH) | +6.257363 | 0.0003893979 |

All three retained direction in the sealed at-least-80-percent sensitivity,
all were fully estimable, and none triggered the unqualified-claim block. The
paired display source contains exactly 27 rows, five unchanged `BA-M4`
diamonds, three `BA-M6` asterisks, and 27 fully estimable support rows.

The verification preserves the accepted interpretation that the endpoint-
inflated Brown analysis remains the main analysis, the cross-state association
is exploratory, the within-participant day-level claim is withheld, the
between-participant inverse associations retain their limitations, and the
anonymous participant-profile display is descriptive only.

## Stage 4 boundary verification

Before authorization, the checker confirmed absence of:

- `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd`;
- `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html`; and
- `audit/analyses/brown_adherence/stage4_cross_state_association/`.

The transition therefore opens new Stage 4 paths without overwriting an
existing task artifact. The accepted Stage 3 package, shared Quarto profile,
manuscript, central scientific files, package environment, and lockfile remain
outside the task write boundary.

## Conclusion

`BA-CS-G3-INTEGRATED-REVIEW` is closed. The integrated Stage 3 package is
accepted. Bounded Stage 4 provenance work is authorized and must stop at
`BA-CS-G4-REVIEW`. Immediate accepted-result notification to Nature Health
writer task `019ffb39-372e-7262-bfac-192751fd0e63` is authorized. The author
also explicitly directs that writer to update the Nature Health manuscript
from this accepted Brown-adherence claim authority. Those manuscript-owned
edits belong to the writer task. Shared navigation and manuscript-file edits
remain outside the Brown task.

The non-circular transition manifest is:

`audit/decisions/brown_adherence_cross_state_stage3_acceptance_stage4_transition_manifest.csv`
