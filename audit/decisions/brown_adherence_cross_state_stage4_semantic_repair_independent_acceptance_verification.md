# Brown adherence cross-state Stage 4 semantic repair acceptance verification

Date: 2026-08-21  
Status: pass  
Disposition: `ACCEPTED_REPAIR_PENDING_AUTHOR_APPROVAL`

## Command and environment

The durable independent checker is:

`scripts/report_harmonization/check_brown_stage4_semantic_repair_independent_acceptance.R`

It was executed from the central project with:

```text
Rscript --vanilla scripts/report_harmonization/check_brown_stage4_semantic_repair_independent_acceptance.R /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026 /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026
```

Environment:

- R version 4.6.1 (2026-06-24)
- `gt` 1.3.0
- `xml2` 1.6.0
- `digest` 0.6.39
- no project profile or `renv` activation
- no QMD execution, Quarto render, browser server, model package, or
  scientific computation

Air formatting and R parsing passed for the checker. Scoped
`git diff --check` passed.

## Reproduced output

```text
Brown Stage 4 semantic repair independent acceptance PASS
R version: R version 4.6.1 (2026-06-24)
Renewed package: 113/113 exact, unique, non-circular
Repair: 100 IDs plus 552 headers; 683/683 IDREF tokens resolve once
Document IDs: 963 unique; exact composed reverse to 697ec3a5...
Historical package: 76 unchanged plus 3 exact baseline transitions
Protected identities: 806/806 exact; additional renders: 0
Disposition: repair accepted; author gate and writer follow-up remain held
```

The checker independently rehashes every renewed manifest member and all 806
protected paths, audits the historical transition set, reconstructs the exact
pre-repair HTML from the current HTML and repair ledgers, compares visible text
and normalized DOM, and validates every document ID and table-header IDREF.

Port 50370 had no listening process. The task-owned temporary candidate path
recorded by the teardown evidence was absent.

## Conclusion

`BA-CS-G4-SEM-001` is closed. The repaired Stage 4 package is accepted for
author review. `BA-CS-G4-REVIEW` and the writer provenance follow-up remain
held pending explicit author approval.
