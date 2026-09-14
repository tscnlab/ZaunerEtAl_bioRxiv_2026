# REPORT-018 owner order 70a: landing-page legacy DOM baseline clarification

Date: 2026-09-02

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

Status: `NARROW_GATE_CORRECTION_WITHOUT_NEW_EXECUTION_AUTHORITY`

## Reason for clarification

Order 70 correctly requires the other 36 website routes to remain
byte-identical, but its absolute 37-route phrase requiring no duplicate IDs
and complete resolution of every inherited IDREF and table-header token is
incompatible with the accepted Navigation Order 67a legacy baseline. The
navigation owner identified the contradiction before creating a candidate,
an Order 70 evidence directory, or any live write.

The accepted Order 67a DOM evidence records seven legacy routes with 63
duplicate ID values, 149 extra duplicate instances, and 212 duplicate-bearing
nodes. Across the byte-frozen 36 non-index routes it also records 47,821 IDREF
tokens, of which 7,298 remain unresolved under the accepted raw-token audit,
and 46,736 table-header tokens, of which 5,509 remain unresolved. Their exact
per-route counts, duplicated `(route, id, count)` multiset, ID order, and
resolution classification are accepted historical accessibility debt. They
cannot be changed by this landing-page-only order.

## Corrected gate

This clarification replaces only the impossible absolute 37-route DOM
condition in Order 70. Every other Order 70 authority, pin, candidate gate,
browser gate, promotion rule, stop rule, and prohibition remains unchanged.

1. The new landing page must have zero duplicate document ID values, zero
   unresolved IDREF tokens, and zero unresolved table-header tokens. Every
   intended manuscript fragment and table-header relationship must resolve.
2. The other 36 routes must remain byte-identical and reproduce the complete
   accepted Order 67a legacy DOM baseline exactly. This includes the seven
   affected routes, 63 duplicate values, 149 extra instances, 212 affected
   nodes, the complete duplicate multiset, per-route ID order, the 7,298
   unresolved IDREF tokens, the 5,509 unresolved table-header tokens, and the
   complete per-route resolution classification.
3. Fail closed on any new duplicate value, added or removed duplicate
   instance, added or removed duplicate-bearing node, newly affected route,
   renamed legacy ID, new unresolved IDREF or header token, changed legacy
   resolution classification, or any other worsening of the baseline.
4. Do not repair, rename, remove, reorder, or reclassify any inherited ID,
   IDREF, table-header token, or relationship on the byte-frozen 36 routes.
5. The 37-route audit must report each route explicitly as either
   `CLEAN_NEW_LANDING_PAGE` or `ACCEPTED_LEGACY_BASELINE_PRESERVED`. It must
   report a separate `NEW_DEFECT` classification for any drift and stop
   immediately if that classification occurs.
6. Candidate and production evidence must compare the complete DOM baseline,
   not only aggregate counts. Exact byte identity of the 36 protected route
   files remains an independent required gate.

## Controlling baseline evidence

The owner must reproduce exactly before candidate construction:

- `candidate_dom_audit.csv` at SHA-256 `3ebf8104...`, 5,590 bytes;
- `legacy_duplicate_id_multiset.csv` at SHA-256 `551b4e54...`, 3,265 bytes;
- `legacy_duplicate_id_route_summary.csv` at SHA-256 `8f28de29...`, 2,415
  bytes; and
- the original Order 67a duplicate-ID clarification at SHA-256
  `a8cf8f78...`, 2,000 bytes, plus its non-circular manifest at `0887c744...`,
  1,566 bytes.

The accepted preimage landing page itself was clean under Order 67a with zero
duplicate IDs, zero unresolved IDREFs, and zero unresolved table-header
tokens. The new landing page must meet the same absolute cleanliness standard
while also satisfying all Order 70 manuscript-preservation gates.

## Boundary

This clarification grants no new file-write, render, retry, scientific,
stylesheet, shared-include, QMD, or route authority. It does not authorize a
second Order 70 execution. It permits the already acknowledged Order 70 to
continue once from its untouched pre-candidate state under the corrected
baseline-aware DOM gate.
