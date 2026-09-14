# REPORT-018 Order 67a Air differential clarification

Date: 2026-09-02

Status: `DIFFERENTIAL_FORMAT_PARITY_ACCEPTED_NO_LIVE_FORMATTING`

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

This clarification is part of the already authorized Order 67a verifier-only
continuation. It supplies no new candidate, promotion, render, or retry
allowance.

The phrase “Require R parse and Air checks” in the controlling verifier-stop
disposition means differential formatting parity against the sealed original.
It does not require either implementation file to pass a clean-tree Air gate.

Independent verification establishes:

- the sealed original implementation remains SHA-256
  `5cbbaae8a152fc4b2db38853b5258519b6646481483e6314ddede90b7abc1f16`,
  65,084 bytes;
- the corrected task-owned copy is SHA-256
  `e3f1b14a7e6c2a4a51b52a3bfac78d484c71446cc7ad04cce8d8889c450e3c66`,
  65,208 bytes;
- the corrected copy parses under R 4.6.1;
- its raw diff from the sealed original is exactly the authorized replacement
  of one `duplicate_multiset_exact` expression;
- `air 0.4.1 format --check` returns status 1 and `Would reformat` for both
  the sealed original and corrected copy; and
- formatting temporary copies with Air produces files whose only mutual diff
  remains the same authorized duplicate-name and integer-count comparison.

The Air failure is therefore inherited formatting debt in the sealed original.
Formatting the corrected live copy would change unrelated lines and violate
the one-hunk boundary.

The owner must not format either live implementation. Instead, seal the
corrected copy exactly at `e3f1b14a...`, 65,208 bytes, and record these checks:

1. `Rscript --vanilla` parses the corrected copy under R 4.6.1.
2. The raw original-to-corrected diff is exactly one authorized expression.
3. Exact reverse substitution reproduces `5cbbaae8...`, 65,084 bytes.
4. Air 0.4.1 reports `Would reformat` for both unmodified files.
5. Air-formatted temporary copies differ only at the same authorized logical
   expression. Temporary formatted copies must never replace a project file.

On those five checks passing, the current corrected script identity is
accepted for its one already authorized candidate execution. All remaining
Order 67a gates, stop rules, and prohibitions remain unchanged.

