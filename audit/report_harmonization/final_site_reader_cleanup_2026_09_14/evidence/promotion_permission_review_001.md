# Promotion command rejected before process creation

14 September 2026. After all candidate, fixture, HTTP, browser and teardown gates passed, the requested frozen `transaction.py promote` command was submitted with escalated permission for its process guard and exact local promotion.

The safety reviewer rejected process creation because the visible request did not establish explicit user authorization for all 62 operations, including 15 public retirements and profile/corpus changes. This was a permission rejection, not an executed transaction or a failed postflight. The command was not rerun, downgraded to another permission mode, or executed indirectly.

An immediate read-only check confirmed that neither `evidence/live_transaction_journal.jsonl` nor `evidence/promotion_freeze.json` existed. A fresh protected preimage check was requested. The candidate server was already stopped, its connection refused, task-created candidate tabs closed, and viewport reset.

The Coordinator was informed of the exact rejection and asked for the exact user-authored approval and source turn, to establish the authorized scope for review. The existing recorded approval and exact sealed order are retained as evidence, not silently treated as a way to bypass the denial. Production remains unchanged pending resolution of this permission review.
