# REPORT-018 Order 67a candidate verifier stop

Date: 2026-09-02

Status: `STOPPED_BEFORE_BROWSER_AND_PROMOTION_VERIFIER_ONLY`

The Order 67a dispatch, independent Order 67 stop acceptance, duplicate-ID gate clarification, exact build preflight, stylesheet pins, include pin, corpus-manifest pin, and process gate all passed. The task-owned implementation script was sealed before its first execution at SHA-256 `5cbbaae8a152fc4b2db38853b5258519b6646481483e6314ddede90b7abc1f16`, 65,084 bytes.

The first candidate execution copied the accepted 892-file build with zero symbolic links and applied exactly the authorized script substitution to the 37 HTML routes. The isolated include candidate is SHA-256 `153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980`, 1,542 bytes. Candidate inventory comparison finds exactly 37 changed files, all registered HTML routes, and no other delta.

The script then stopped before writing its candidate evidence outputs because `identical()` compared two R `table` objects whose values and ID names were identical but whose dimension-name labels inherited the different variable names `accepted_ids` and `candidate_ids`. This made `duplicate_multiset_exact` false on the seven legacy duplicate-bearing routes even though:

- all 37 ordered ID sequences are exactly identical;
- all 63 duplicate ID values and their names are identical;
- all 149 extra duplicate instances are identical; and
- the only unequal `table` attribute is its non-substantive dimension-name label.

This is a verifier-only defect. It is not an HTML, DOM, duplicate-ID, navigation, candidate, source, scientific, semantic, link, or build defect.

No browser QA or promotion occurred. The live shared include remains SHA-256 `926a5fc051f032100714ae01b53c5ba2937c91ff2406ab5354484bf8fd7f553d`, the live corpus manifest remains SHA-256 `c42c326230818a93aa89322155b933c2f536f09bd447ab09b72f934fba75e76f`, and all live production files remain unchanged. No sealed implementation script was patched or rerun.

Coordinator disposition is required before any verifier correction, candidate revalidation, browser QA, promotion, or reseal.
