# Preserved preproduction validator failure

The initial static check stopped at the inherited `V0` table-header identifier in `audit/H01/02_implementation_and_v0_comparison.html`. The first validator incorrectly applied the entry-page unique-ID predicate to every historical report. Order017 expressly preserves exact inherited non-entry duplicate-ID multisets.

No production mutation occurred. The failed check CSV and the exact first validator are retained as `candidate_initial_static_failed_checks.csv` and `attempt001_verify_static.py`.

The corrected validator keeps strict unique headers in index and Supplementary Information. For every non-entry table it requires the complete old/new table serialization to be identical, requires every referenced header ID to exist, and requires exactly the old per-table ID multiplicity. This changes only classification of the explicit inherited duplicate-ID contract. It does not exempt a missing header, change a table or relax entry-page semantics.
