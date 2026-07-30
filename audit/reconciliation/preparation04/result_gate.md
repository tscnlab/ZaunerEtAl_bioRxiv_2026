# Preparation 04 result gate

Status: PASS for canonical primary metric derivation and approved dispositions; registered MDER sensitivities remain mandatory before conclusion stability is classified  
Date: 2026-07-30  
Environment: R 4.6.1; LightLogR 0.10.3; `TZ=UTC`  
Producer: `audit/scripts/finalize_preparation04_reconciliation.R`

All 1,708 canonical Rule A participant-days reconcile to the baseline keys: 811 near-eye days and 897 chest days, with no unmatched participant-day or site key. The independent core verifier passed the exact 29-artifact manifest and reconstructed all 1,708 days from minute-level inputs.

| Metric family | Near eye | Chest | Disposition |
|---|---:|---:|---|
| MDER | finite 725→733; paired median Δ +0.133; 90% support n=601 | finite 729→825; paired median Δ +0.160; 90% support n=691 | APPROVED PRIMARY under METRIC-008; 90% support, exact two-day exclusion, and waking-only sensitivities pending |
| M10 level | 811 finite | 897 finite | PASS; level retained for all five all-candidate ties |
| M10 timing | 809 finite; 2 all-candidate ties reason-coded missing | 894 finite; 3 all-candidate ties reason-coded missing | PASS under METRIC-007 |
| L10 timing | 809 finite | 894 finite | PASS |
| Longest bout | 811 primary lower bounds; 497 exact-only | 897 primary lower bounds; 565 exact-only | PASS under METRIC-006 |
| Mean timing >250 | 714 finite | 810 finite | PASS |
| First/last timing >250 | 717/679 finite | 786/773 finite | PASS; metric-specific support/censoring retained |
| Corrected dose | 736 finite | 827 finite | PASS |

## Closed M10 gate

The METRIC-007 repair is present in the canonical artifacts. M10 remains 0 lx on the five affected participant-days, while onset, midpoint, and offset are missing with `failure_reason = "all_candidates_tied"`. The resulting timing samples are exactly 809 near-eye and 894 chest days. This gate is closed and is no longer an author-input blocker.

## Approved MDER primary disposition

The two preidentified serial-2962 device-days remain unchanged in the primary 80% ratio-of-integrals artifacts, as approved by METRIC-008. Device and context provenance checks are complete; neither record is proven invalid. This is not an open author gate. However, every MDER model and claim must still be compared with (1) the registered 90% common-support scenario, (2) exclusion of exactly those two preidentified days, and (3) the full-day versus waking-only explanatory scenario before stability is classified.

Preparation 04 is therefore closed for primary artifact integrity and metric disposition. Downstream hypothesis work may proceed, but MDER conclusions remain sensitivity-pending rather than submission-ready.

## Provenance

- Run ID: `PREP04-R461-ac0325716421`.
- Metric manifest SHA-256: `ac0325716421f2d90bb83b445ffb6ad965b131e382373e45f4ad6157eac5937d`.
- Near-eye participant-day RDS SHA-256: `a3964a8d323b0f9cca52b55a56ac03619366ee45a4ecdfda150332e380e41f3d`.
- Chest participant-day RDS SHA-256: `35c86b572fcb9105c7c82dbdb9e6e15e1d2158870face66ff4c5a939072b7297`.
- Reconciliation artifact-manifest SHA-256: `bc4f54028bcfb423be03ce6eabf46af644ba16a46c3d67d39afa74a6fc8b52e7`.
- Evidence: `audit/reconciliation/preparation04/core_verification.md`; `audit/findings/m10_all_candidates_tied.md`; `audit/findings/mder_upper_tail.md`; `audit/findings/mder_device_provenance.md`.
