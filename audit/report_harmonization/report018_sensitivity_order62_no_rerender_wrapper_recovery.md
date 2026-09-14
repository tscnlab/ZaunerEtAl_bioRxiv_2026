# REPORT-018 Order 62 no-rerender wrapper recovery

Status: `AUTHORIZED_WRAPPER_ONLY_RECOVERY`

The sealed no-rerender wrapper stopped before invoking the temporary complete
checker. Its generic `replace_once()` postcondition required the replaced
token to be absent from the output, but the accepted missing-or-empty ledger
replacement necessarily retains that token in one branch.

This recovery preserves the sealed wrapper at SHA-256
`1420cefd49acf699cb1673b2877b44534fca832f092f294786ba3673a1e3491c`.
One outer task-owned wrapper may require exactly one source occurrence before
each substitution and remove only the incompatible absence postcondition in a
temporary copy. It then runs the existing no-rerender wrapper once for the
requested phase. The complete page verifier, its three accepted
classifications, and all render, source, semantic, protected, and QA
boundaries remain unchanged.

No Quarto command, page replacement, source edit, semantic rerun, or
scientific computation is authorized.
