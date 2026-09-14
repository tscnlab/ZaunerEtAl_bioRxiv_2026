# Reader-facing deviation-status reconciliation request

Date: 2026-08-12  
Owner: central-ledger coordinator  
Status: **reader-facing deviation document stopped before generation**

## Structural evidence now passes

The authoritative deviation register and hypothesis crosswalk now contain the same 86 unique stable IDs. R 4.6.1 confirms that all IDs match the stable reader-anchor pattern, all register IDs have exactly one crosswalk row, all crosswalk IDs exist in the register, the two files have matching statuses, and the 86 lower-case Quarto anchors are unique.

The fail-closed check is:

```sh
Rscript --vanilla scripts/report_harmonization/check_deviation_source_contract.R
```

## Scientific wording/status discrepancy exposed by harmonization

The structural reconciliation does not yet make the register safe to translate into a current reader-facing document. Fifty-seven of 86 rows retain a nonterminal status:

- 25 `pending_author_decision`;
- 13 `open_reaudit`;
- 12 `open`;
- 6 `in_progress`; and
- 1 `h02_resolved_h11_pending`.

Several of those rows describe an earlier implementation as though it were still current, while the responsible owner handoffs now record an accepted and verified replacement. Clear examples are:

- `DEV-022`–`DEV-024`: the register describes the pre-repair H03 category, estimand, and multiplicity problems; the H03 handoff records an approved seven-category analysis, separate main and interaction tests, and complete adjusted families.
- `DEV-025`–`DEV-027` and `IMP-021`: the register describes the pre-repair H04 activity construction and screen; the H04 handoff records an approved weighted activity representation, separate estimands, and corrected reporting.
- `DEV-028`–`DEV-029` and `IMP-006`: the register describes the earlier H05 correlation implementation and scalar adjustment; the accepted H05 result uses the current model package and complete 68-test adjustment family.
- `DEV-030`–`DEV-032` and `IMP-007`: the register describes the rejected H06 architecture and stale result; the accepted hourly H06 analysis uses the revised marginal-mean model and verified H06 outputs.
- `DEV-033`–`DEV-034` and `IMP-008`: the register describes selected H07 outcomes and an unsupported ceiling claim; the accepted H07 analysis uses the complete nine-metric families and the approved derivative-defined descriptive rule.
- `DEV-035`–`DEV-036`: the register describes the earlier H08 joint test and scalar adjustment; the H08 handoff records the accepted final reader analysis.
- `DEV-037`–`DEV-039` and `IMP-009`: the register says MEQ is absent and estimates come from a different model; the accepted H09 report includes distinct MCTQ and MEQ models, site adjustment, and complete five-member FDR families.
- `DEV-040`–`DEV-041` and `IMP-011`: the register describes missing H10 interaction inference and an overwrite risk; the accepted H10 handoff records the current verified outputs and conclusions.
- `DEV-042`–`DEV-048` plus the H11 part of `IMP-005`: the register retains pre-decision H11 concerns, while the H11 handoff records completed Stage 4 sources with accepted global-curve inference and pointwise-interval limits.
- `IMP-001`, `IMP-004`, `IMP-010`, and related cross-hypothesis implementation rows retain open descriptions of errors that current accepted reports state have been corrected or superseded.

This is not an editorial wording choice. Publishing the register text verbatim would contradict accepted result and preparation pages; silently rewriting it from owner handoffs would make the harmonization task, rather than the central evidence, the scientific authority.

## Requested central action

At the next safe coordinator point, reconcile each nonterminal row against the accepted decision and current owner handoff. For every row, either:

1. update the central status and `observed_or_approved`, rationale, consequence, and source locator to the accepted current disposition; or
2. explicitly retain it as unresolved or historical and state the current reader-usable disposition, including the stable ID of any superseding entry.

Please also confirm whether environment-only and implementation-only records (`DOC-*`, `IMP-*`, and `REP-*`) are intended as full reader entries or as a separately labelled technical/history section. The approved document structure can accommodate either, but the choice must be central and explicit.

No reader-facing deviation QMD, owner deviation-link order, or deviation-anchor integration will be issued until this scientific wording/status reconciliation is complete.
