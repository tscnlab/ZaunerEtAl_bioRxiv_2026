# Nature Health audit record

Status: active  
Started: 2026-07-29  
Scope: Nature Health retargeting, reproducibility audit, analysis repair, and local submission preparation

This directory contains the tracked audit trail for the Nature Health
submission. It is separate from journal-facing files in
`manuscript/R0_NatHealth/`.

## Directory structure

- `evidence/`: source-grounded reading notes and evidence records.
- `decisions/`: approved analytical and reporting decisions, including their
  rationale, consequences, and reopening conditions.
- `ledgers/`: machine-readable registers for decisions, external evidence,
  findings, deviations, changes, sample flow, result differences, and claim
  provenance as those records are created.

## Record rules

1. Every record includes a date, status, and source locator.
2. Companion-paper findings are labelled according to their actual evidential
   role. Exploratory unadjusted p-values are not described as confirmatory
   evidence and are not imported into this study's multiplicity families.
3. Decisions that alter an estimand, inclusion rule, metric, statistical
   model, multiplicity family, substantive result, preregistration
   interpretation, or manuscript claim require an explicit gate record.
4. Analytical discrepancies are reproduced and resolved in R before they are
   treated as scientific findings.
5. Audit records may describe earlier states of the project. Public-facing
   documents describe the final analysis on its own terms.
6. Raw participant data, credentials, local caches, and journal-only upload
   files do not belong in this directory.

## Current placement decision

Simple pooling of glasses- and chest-position measurements is rejected.
Near-eye measurements remain primary. Chest measurements are retained as
paired/common-sample complementary evidence. The basis and implementation
constraints are recorded in
[`decisions/placement_decision.md`](decisions/placement_decision.md).

