# H05 shared change request

Status: **requested; no shared file edited by the H05 Stage 1 worker**

## Target

`audit/hypotheses/H05-H08_migration_map.md`, H05 site-screen description
(currently around lines 320–334).

## Confirmed discrepancy

The migration map states that each of the four questionnaire-by-site omnibus
p-values was passed alone to `p.adjust(..., n = 4)`. Direct inspection and
exact R evaluation of the submitted H05 pipeline show different semantics:

1. the four `joint_tests()` rows are assembled by `unnest(test)`;
2. the following ungrouped `mutate(p.value = p.adjust(p.value, "fdr", n = 4))`
   receives the complete four-value vector; and
3. the resulting adjusted p-values are 0.00764, 0.591, 0.106, and 0.0164 for
   F2–F5, respectively.

The scalar-`n = 4` counterfactual would instead give 0.00764, 1, 0.318, and
0.0328. Both implementations retain F2 and F5 at 0.05, so the correction does
not change which V0 factors passed the screen.

## Requested correction

Replace the scalar-adjustment description for the **four-factor site screen**
with wording that it performs one four-value BH adjustment after unnesting.
Keep the separate association-level finding unchanged: within each of the 68
metric-by-factor groups, the submitted correlation code does pass a single
Pearson p-value to `p.adjust(..., n = 68)`, so the H05 association-family
scalar-adjustment defect remains confirmed.

## Inferential impact

None of this validates the conclusion that H05 can omit site. The
questionnaire-by-site screen is diagnostic, is not the registered outcome
model, and cannot establish absence of site confounding. DEV-028 and H05-G1
remain open.

## Evidence

- `RQ2.qmd`, H05 site-screen block, approximately lines 1616–1647
- `RQ2_chest.qmd`, duplicated H05 site-screen block
- `audit/hypotheses/H05/01_audit_and_plan.qmd`, evaluated
  `reproduce-v0-site-screen` cell
- `audit/hypotheses/H05/h05_stage1_v0_site_screen.csv`
