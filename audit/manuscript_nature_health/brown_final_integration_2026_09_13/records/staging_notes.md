# Source-staging execution notes

The first two staging calls stopped at the first identity check, before any
preimage or candidate copy was created. OpenSSL retained hash-class attributes
after `as.character()`, so `identical()` rejected an equal plain-text expected
hash. The corrected helper converts the value to a plain string. Inspection
also found and corrected a two-character transcription omission in the later
configuration hash literal. No source discrepancy was found. The copy helper
permits an existing destination only when it is byte-identical to its source.
No render, model load, display generation or live-file edit occurred.

The preliminary read-only R inspection used an incorrect column name while
printing the already adjusted site-reference subset. Its empty printout was
not interpreted as a scientific result. The complete accepted table had
already been read, and final reconciliation explicitly uses the stored
`p_adjusted` field, checks its existence and expects all three retained rows.

During source-check development, strict checks also stopped on: a canonical
exploratory CSV not being a direct manifest member; p-value whitespace; a
link regex matching English prose; the word ceiling; and an incorrectly named
old Brown sentence in a prefix-preservation assertion. These were resolved,
not bypassed. The canonical CSV was reconciled in R against its sealed
endpoint-catalog leaf with identical data-frame values, names and row order;
the sealed leaf controls claims. The p-value/link/prefix issues were checker
scope corrections. Brown-only concision brought main prose plus headings to
4,500 words without changing non-Brown text. Final checks were rerun from the
beginning and passed. No failed check was treated as scientific evidence.

An attempted read of a guessed clarity-checker filename found no file. The
installed skill inventory identified `scripts/check_invariants.py`; the
previously read checker and its remaining tail were used. Its self-tests pass.
Return code 1 for the actual comparison is expected and explicitly reconciled
because this accepted Brown update changes numerical tokens.
