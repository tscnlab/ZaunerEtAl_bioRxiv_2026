# Remaining manuscript-table gt candidate completion

Date: 2026-08-31

Status: **CANDIDATE COMPLETE, NOT INTEGRATED**

R 4.6.1 rebuilt the two H02 Shapley tables and the person-level evidence synthesis as native `gt` tables from the current accepted selection artifacts. No scientific value, interval, percentage, sample, decision, qualification, row order, or row-group order was recomputed or changed.

Verification passed 14/14 checks:

- both H02 candidates contain seven rows and the two accepted row groups;
- all 56 H02 source and candidate cells agree exactly after whitespace normalization;
- the person-level candidate contains seven rows and all 49 source and candidate cells agree exactly after whitespace normalization;
- each candidate contains one native `gt_table` with scoped semantic headers; and
- all three outputs were built under R 4.6.1.

The accepted selection QMD, accepted selection HTML, existing table fragments, hypothesis sources, scientific artifacts, and package state remain unchanged. Integration and Quarto rendering remain separately held.
