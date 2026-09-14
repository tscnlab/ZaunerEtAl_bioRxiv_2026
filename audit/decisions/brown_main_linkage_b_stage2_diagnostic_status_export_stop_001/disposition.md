# BA-018 diagnostic status-export stop

Date: 2026-09-12. Status: IMPLEMENTATION_STOP_CONFIRMED, RETRY HELD.
Authority chain: BA-018 / CHG-157 and qualified continuation 001.

The owner followed the stop boundary after one diagnostic job. This is a
metadata-assembly defect, not a new model or scientific result. No further
scientific execution or supervisor exception is released by this record.

## Exact stopped state

Owner root:
`/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/`.
Return: `completion_v2/continued_final_package_003/`.

- `final_manifest.csv`: `ef06de7af67271cfdd2b6ab4958aede173e5707d1a5d6c8c20f23f63db4877fe`,
  223/223 exact, unique and non-circular in independent R 4.6.1 replay.
- `final_manifest_verification.csv`:
  `aeea037787d3ec61d59941d365e3d5be469e760847e92fd5f951d38fd4a3666c`.
- `stage2_handoff.md`:
  `525adab617ccdac866d4d1261acc36bd2f40ac562ab441b24b6063dc485abc07`.
- All 20 finalization checks and 2,287 distinct protected files pass.
- Eight execution jobs, three nonzero exits, cumulative wall time
  100.50703887498821 seconds in the same 1,200-second ceiling.

The new `DIAGNOSTICS-PRIMARY-ANY` job used 1.0988522499974351 seconds,
returned exit 1 without timeout, reaped child 75010 and removed the lock.
Its driver remains `20c8a54701b7cd1772ce78aa5b18588dfa9459d08a13dd879ac4716ba58eb5f3`;
its v3 supervisor remains
`f4cfa0953a9dabb8a4c76d3847107507657b8e1ec51a35edbbfbd6f67be3e1d9`.
No diagnostic exports exist. The primary pair, all 23 estimand/family exports,
M1 FALSE, 12/13 scientific validation and the author-approved Pre-sleep
qualification remain intact. Support-80 diagnostics and all remaining
sensitivities are still unexecuted.

## Confirmed implementation finding BA-LB-DIAGNOSTIC-EXPORT-001

Category: implementation/provenance. Confidence: confirmed. Severity: medium
workflow blocker, not evidence of changed scientific estimates.

`code/07_run_primary_diagnostics.R` line 153 requests
`result$bundle$fit_gate$status`, but the frozen fit gate uses `fit_status`.
The nonexistent field produces a zero-length value in an otherwise one-row
`data.frame`, causing the recorded differing-row-count error.

The nine inherited diagnostic function bodies were fully inspected, as was
the complete new driver. A temporary field-only correction reverses exactly
to the stopped driver. R 4.6.1 synthetic replay tested both sample branches
from the diagnostic-return point through every later check and export:
17/17 checks pass, with 14 unique output-manifest members per synthetic
branch. The original field error reproduces before any export. A missing
correct field still fails. Technical status, the real stored M1 qualification
and a deliberately synthetic failed endpoint assessment remain separate.

All predictive, residual, draw and model functions were mocked or prohibited
in this replay. No model RDS was loaded, no real diagnostic was recalculated
and no author file was edited. These synthetic tests establish the downstream
bookkeeping behavior, not a scientific diagnostic PASS. Any real endpoint
or other mandatory diagnostic failure must still receive its proper stop
disposition rather than being concealed by construction-check PASS.

## Draw accounting and proposed recovery boundary

The diagnostic function returned before the metadata failure. It therefore
executed its 250 conditional predictive draws at seed 20260814 and randomized
residual construction at seed 20260815. No returned object, draw matrix,
diagnostic table, envelope or assessment was saved before the error. Those
in-memory results are unavailable after process termination. Two retained
constant-predictor correlation warnings were not the terminating error.

The failed attempt's 250 draws and its entire runtime stay charged. A complete
same-seed diagnostic retry would execute those 250 draws again, not supply
250 independent new evidential replicates. It cannot honestly be described
as no additional computation or erased from the attempted-draw ledger.

The existing maximum is 1,500 attempted draws over six named sample slots.
Completing all originally eligible slots plus this one repeat could require
1,750 attempted draws, with the same maximum 1,500 logical final diagnostic
draws and the same 1,200-second cumulative runtime. This narrow attempted-draw
recovery allowance requires explicit author approval. Do not silently use an
untriggered slot, reduce a required diagnostic or expand the cap.

If approved, prepare one versioned field/provenance/checkpoint correction,
validate the fit-status schema before calling the diagnostic function, save a
write-once raw diagnostic checkpoint immediately after it returns, and test
the complete driver and supervisor path with synthetic fixtures before owner
dispatch. Preserve every current driver, registry, package and failed exit.
No repeat fit, estimand derivation or revised inference is needed. The exact
future postimage, source registry, job ID, draw ledger and supervisor exception
must be sealed separately; the field-only audit candidate is NOT released.

This does not reopen the author's already accepted Pre-sleep qualification.
It asks only for the discarded diagnostic execution to be repeated with
honest accounting. BA-LB-G2-REVIEW and every report, R2/Shapley, S5, Writer,
Word/ZIP and website integration hold remain unchanged.
