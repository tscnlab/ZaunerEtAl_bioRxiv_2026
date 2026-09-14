# Static container follow-up

The completed source/static verifier passed all 1,111 checks. A subsequent
source-layout inspection identified one container issue: the S2 parent had a
fixed width while its content-aware table was allowed to expand. A future
capture rectangle should grow with the entire table, not only its preferred
minimum width.

Attempt 02 changes only the S2 parent/table width behavior to max-content/auto
with the same declared minimum and identical column preferences. All values,
source text, fonts, PNG payloads, row partitions and notes remain unchanged.
The new candidate uses its own paths and hashes. This is a static source fix,
not a browser fit finding or visual acceptance.
