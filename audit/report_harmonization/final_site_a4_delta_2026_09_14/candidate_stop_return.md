# Order015 consolidated stop: file-list ordering assertion

14 September 2026. Harmonizer returns one finding, `ORDER015-BUILD-001`.

The single candidate packaging pass stopped at `helpers/build_candidate.py:31`, after copying the live public tree and writing the six preflighted replacements. It must not be reported as completed or promoted. The original helpers, marker and candidate have been preserved without a second build or recovery.

## Cause and exact state

`common.inv()` sorts `pathlib.Path` objects by path components. The final assertion compares that list with a list sorted by the full path strings. These are different orders for this tree, although every corresponding path, byte count and SHA-256 is exact. There are 36 displaced list positions. The first is position479: the Path-sorted list has `audit/hypotheses/H03/H03_analysis_preparation 2.html`, while the string-sorted list has `audit/hypotheses/H03-H11_gated_workflow.html`.

Read-only diagnosis verified the complete914-file candidate by path-keyed identity against the sealed target matrix and live baseline: exactly six replacements,908 preserved files, zero additions and zero removals. Each of the six files matches its prescribed postimage. Both HTML transformations reproduce the accepted raw operation ledger and exact whole-file reversals; the search projection and prospective two-cell corpus also reproduce exactly. All seven rollback preimages remain exact.

This is a new implementation/checker defect, not an established content discrepancy. The same sequence assumption appears in `check_closure.py`'s post phase and must be considered in any separately authorized verification recovery. Neither helper was patched. The in-memory preflight established postimage identities but did not test the final inventory comparison's ordering, which is why it did not catch this defect.

## Preserved boundaries

Fresh checks reproduced all4617 protected/input hash rows, the complete live914 inventory, the live corpus, both historical owner package memberships, the earlier candidate inventory, Writer318/QA75 and the original11 helper identities. No source, accepted SVG artwork, manuscript donor, live website, corpus, historical evidence, package, lock or remote state changed. The Writer was not contacted. No Quarto, R content check, Office conversion or scientific computation was run after the failure.

No Order015 server or browser tab was started; there was no viewport override to reset. The approved narrow process check found no continuing Order015 build or preview process. Browser and download QA have not been performed for this candidate, and no visual acceptance is claimed. The live accepted site remains Order013.

## Evidence and requested next decision

- `evidence/build_failure_output.txt`: original session42569 error and exit status.
- `evidence/failure_diagnosis.json`: consolidated exact-state diagnosis.
- `evidence/failure_inventory_order_difference.csv`: all36 displaced positions.
- `evidence/failure_candidate_inventory.csv`: preserved914-file candidate snapshot.
- `evidence/failure_six_postimages.csv`: six exact target identities.
- `evidence/failure_live_inventory.csv` and `failure_protected_checks.csv`: fresh unchanged closure.
- `evidence/seven_backup_manifest.csv`: exact rollback set.
- `evidence/phase4_corpus_manifest.prospective.csv`: candidate-only corpus; not live.
- Existing raw-operation, reversal and search evidence remains intact.

Request independent review and, only if accepted, a separately scoped verifier-only recovery using this exact existing candidate. Such a release should preserve this failed attempt, correct the comparison convention in new recovery verification, produce the missing proposed-promotion/inventory records from these exact files, and authorize the still-pending static, R4.6.1 and bounded browser checks. No second packaging pass, source edit, Writer wakeup or live promotion is requested under Order015 itself.

Disposition: `STOPPED_IMPLEMENTATION_DEFECT_PENDING_COORDINATOR_DECISION`. The failure manifest and separate failure seal are non-circular; they are not a completion or promotion seal.
