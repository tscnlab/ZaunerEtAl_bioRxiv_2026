# Preregistration-deviation crosswalk reconciliation

Decision ID: `REPORT-015`  
Change ID: `CHG-125`  
Date: 2026-08-12  
Status: verified central reconciliation

## Purpose

The preregistration-deviation reader document must be generated from an exact,
authoritative relationship between every entry in
`audit/ledgers/deviation_register.csv` and its affected hypothesis or
hypotheses. The harmonization task correctly stopped when five register IDs
were absent from `audit/ledgers/deviation_hypothesis_crosswalk.csv` and two
historical MDER rows had statuses that no longer matched the register.

## Authoritative repairs

| ID | Affected hypotheses | Relationship | Authoritative status |
|---|---|---|---|
| `IMP-022` | H01, H05, H06, H09, H10 | Direct outcome: analytical M10/L10 scope | `approved` |
| `DEV-057` | H01--H11 | Upstream participant-day inclusion | `approved` |
| `DEV-058` | H01, H05, H06, H10 | Direct MDER outcome | `approved_implemented_independently_verified_gap_repair_complete` |
| `IMP-023` | H01 | Direct H01 outcome transformation | `approved` |
| `IMP-024` | H01 | Direct H01 outcome interpretation | `approved` |
| `DEV-051` | H01, H05, H06, H10 | Historical direct MDER outcome | `superseded_by_METRIC_010` |
| `IMP-013` | H01, H05, H06, H10 | Historical direct MDER outcome | `superseded_resolved_by_METRIC_010` |

`IMP-022` covers the hypothesis analyses whose analytical registries include
the M10/L10 midpoint or related timing outcomes. The all-zero participant-day
rule in `DEV-057` is an upstream inclusion decision for every hypothesis.
`DEV-058`, `DEV-051`, and `IMP-013` share the hypotheses whose model-facing
outcome families contain MDER. `IMP-023` and `IMP-024` are H01-specific.

The two historical MDER rows remain part of the record; their status and
source now point readers to the current author-approved MDER decision rather
than suggesting that the superseded implementation still controls current
results.

## Implementation boundary

Only the central crosswalk rows, this reconciliation record, and their ledger
entries change. No deviation description in the authoritative register is
rewritten, and no scientific data, metric, sample, model, result, report, or
claim changes. The harmonization task may proceed with the deviation-document
generation only after an R verification confirms one unique crosswalk row per
register ID, no missing or extra IDs, and exact status agreement.

## Reopening condition

Reopen if the deviation register changes, a hypothesis relationship is shown
to be incomplete, a status ceases to match the register, or the generated
reader document cannot trace each displayed entry back to one unique
authoritative row.

