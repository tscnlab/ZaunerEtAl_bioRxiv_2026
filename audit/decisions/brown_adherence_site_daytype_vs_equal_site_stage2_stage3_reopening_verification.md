# Brown adherence BA-015 reopening verification

Date: 2026-08-20
Status: PASS
Decision: `BA-015`
Change: `CHG-154`

## Purpose

This read-only preauthorization audit determines whether the author's request
to mark site-specific Free-minus-Work effects that differ from the
state-specific equal-site Free-minus-Work effect is already answered by a
frozen family, can be derived without model fitting, and can be bounded before
any new result is inspected.

The audit followed the active `$measurement-methods-audit` workflow. It did
not modify the Brown task worktree, calculate a new contrast, inspect a new
p-value, fit or refit a model, compile TMB code, render Quarto, or create a
scientific output.

## Finding

The request is new inference, not a display-only relabeling.

- `BA-M4` tests 27 site-specific Free-minus-Work effects against zero.
- `BA-M5` tests site-minus-equal-site adherence separately within Work and
  Free days.
- Neither family tests the requested difference-in-differences.
- The frozen selected response-scale interface contains the exact 54 cell
  estimates and stored covariance needed to define the requested 27 contrasts
  without fitting, recompiling, or predicting from a live model.

The bounded new family is therefore registered prospectively as `BA-M6` in
the controlling decision. Existing `BA-M1` through `BA-M5` identities and
interpretations remain unchanged.

## Execution

Authoritative runtime:

- R 4.6.1, 2026-06-24;
- `digest` 0.6.39; and
- existing main-project R 4.6.1 library, read only.

Command:

```text
Rscript --vanilla scripts/report_harmonization/check_brown_ba015_site_daytype_reopening.R \
  /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
  /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026
```

Checker:

- path:
  `scripts/report_harmonization/check_brown_ba015_site_daytype_reopening.R`;
- bytes: 12,529; and
- SHA-256:
  `e74398b9740f10027928c574e4911a3f38ce22aa0083841619e7176ea328749e`.

Air 0.4.1 formatting check: PASS.

## Results

The R 4.6.1 checker passed all fail-closed gates:

1. `BA-015` and `CHG-154` each occur exactly once in structurally valid
   central ledgers.
2. The controlling decision and all four inherited `BA-014` central records
   match their exact byte counts and SHA-256 identities.
3. The accepted Boundary Stage 2 manifest verifies 378 of 378 unique,
   non-circular members.
4. The accepted Boundary Stage 3 manifest verifies 82 of 82 unique,
   non-circular members.
5. The accepted `BA-014` final manifest verifies 86 of 86 unique,
   non-circular members and remains at
   `BA-CS-G3-INTEGRATED-REVIEW` pending explicit author review.
6. Both selected model bundles are exactly F3/R3/Q2/Q1/D0, have convergence
   code zero, positive-definite Hessians, and no structural failure.
7. For each of `primary_any_valid` and `support_80`, the frozen estimand object
   contains 54 ordered response-scale cells, 27 `BA-M4` rows, three `BA-M1`
   rows, and 54 `BA-M5` rows.
8. Each stored report has a finite 432 by 432 covariance matrix and
   `pdHess = TRUE`.
9. The first 54 report values and their standard errors reconcile exactly to
   the frozen cell table.
10. Each corresponding 54 by 54 cell covariance is symmetric within
    `1e-14` and passes Cholesky decomposition.
11. Neither authorized amendment root existed at audit time, confirming that
    no `BA-M6` output or amended Stage 3 display had been produced.

## Disposition

`BA-015` and `CHG-154` authorize one combined bounded Stage 2 inference and
Stage 3 display amendment. The primary family contains exactly 27
`primary_any_valid` contrasts with one Benjamini-Hochberg adjustment. The
identical 27 contrasts in `support_80` are a sensitivity and claim gate, not a
second multiplicity family.

The current five orange diamonds remain `BA-M4` versus-zero results. A second
redundant marker may be added only for primary `BA-M6` FDR results. Stage 4 and
writer notification remain blocked.

The author's prospective statement to approve Stage 3 after the correction
does not accept unseen numerical results or an unseen rendered page. After
the amendment is sealed and reviewed, the required wording remains:

> Approve Brown cross-state integrated Stage 3 as written.
