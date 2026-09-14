# REPORT-014 H04 post-closure source acceptance

Date: 2026-08-14

Status: **Accepted for source-only harmonization. REPORT-017 rendering remains
held.**

## Scope

This acceptance covers the bounded reader-language, cross-link, and registered
website-source synchronization returned by the H04 owner in commit
`2c8c097ed1b312058cbf3ff69c31fc501fa7c994`. It does not independently reopen
or recompute the owner-approved H04 scientific analyses.

The current H04 handoff was read completely before this acceptance. All five
returned source, helper, test, and handoff identities match the owner's sealed
return. The Nature Health profile is unchanged.

## Accepted source contract

- Both visible result-table labels now use **Participant-level variation**.
- The companion uses **participant-level variation** in its explanation of the
  exploratory mixed model.
- Each page explains plainly that the participant random intercept allows
  participants to have different overall exposure levels while retaining the
  fixed activity-by-site structure.
- The companion identifies `glmmTMB` as the R software used to fit the
  generalized linear mixed model.
- The companion anchor
  `sec-h04-prep-participant-random-intercept` occurs exactly once.
- The result source contains exactly one dynamic relative `.qmd` link to that
  anchor. The general reciprocal companion-to-result `.qmd` link remains.
- The primary population-mean analysis, the separate within-participant and
  between-participant sensitivity, and the exploratory participant
  random-intercept decomposition remain clearly distinct.

No editorial wording exposed a new scientific discrepancy.

## Registered website evidence

The two HTML identities were initially easy to confuse because both are
registered H04 pages. They are unchanged and resolve as follows:

- result HTML: `cad724ca28c651db62f2bb11a51d0d53adbf133785a6d9477f600900269e3cbe`;
- preparation companion HTML:
  `73e1c1f097b2053fd55bfea4857d3c72490af490bfa5e7ebf96c8f801bb57a8f`.

The registered website QMD copy is byte-identical to the accepted companion
source at
`28e44e527f1048cdd2b56cf2d7d7ed4b6a1faea5b8cd2c6765068fb2bf994d3d`.
The H04-local helper reads the canonical website HTML and assets and does not
require a parallel source-side HTML copy.

These existing HTML files remain owner-scoped verification evidence. They are
not REPORT-017 render acceptance.

## Output catalog refresh

The existing structural catalog builder completed under R 4.6.1 against the
current Descriptives and H01 through H11 sources. It executed no QMD code. The
fresh catalog contains 274 outputs: 76 figures and 198 tables. The separately
sealed H06 daily addendum remains the authority for that complementary report.

The catalog now contains all 24 H04 `tbl-*` and `fig-*` endpoints in exact
source order, with current source lines, captions, and figure alt text.

Two supplemental tables were added:

- `tbl-h04-participant-random-intercept`, role **supplement: detailed result or
  context**;
- `tbl-h04-mundlak`, role **supplement: sensitivity or comparison**.

The provisional principal roles remain unchanged:

- `fig-h04-primary-estimates`, proposed main H04 figure;
- `tbl-h04-primary-results`, proposed main H04 table.

The refreshed catalog has 274 rows and SHA-256
`43110e4f20a4e9d6257351fad4905c08587f85a28aa27d2a932b0d33b88b6894`.
It also captures the current H03 participant-random-intercept table as a
supplemental detailed-result endpoint. This does not release the queued H03
source synchronization or any H03 render.
Principal and supplemental appearance remains provisional until the authorized
REPORT-017 target render and author visual review.

## Verification

R 4.6.1 structural checks passed for:

- exact terminology counts;
- the unique companion anchor and exact dynamic target;
- reciprocal source links;
- byte identity of the companion and registered website QMD copy;
- exact equality between all 24 current H04 source endpoints and the 24 H04
  catalog rows;
- exact catalog source positions;
- unchanged provisional principal roles and the two new supplemental roles;
- 274 unique catalog labels; and
- R parsing of the H04-local helper and focused preparation test.

Scoped `git diff --check` passed. No Quarto render, code-chunk execution, model
fit, prediction, resampling, artifact regeneration, profile edit, central
ledger edit, commit, or push was performed by the harmonizer.

## Identity seal

The non-circular 12-entry identity manifest is
`audit/report_harmonization/report014_h04_postclosure_source_acceptance_manifest.csv`,
SHA-256
`9a3309d723968f8bb8db74ff3e46b200210d47ef37f8f23708c0fee70e05e1b5`.

H04 remains queued at its normal serial position. H01 remains the sole active
REPORT-017 owner, and no H04 render is released by this acceptance.
