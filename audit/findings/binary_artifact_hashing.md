# Binary artifact hashing

Finding ID: `FIND-009`  
Status: repair implemented; canonical downstream refresh in progress  
Severity: high for provenance, no scientific-value effect established  
Date: 2026-07-30

## Finding

The canonical artifact helper passed `file(path)` to
`openssl::sha256()`. For binary `.RData` and `.rds` files, this unopened
text-mode connection did not hash the exact file bytes. It produced a stable
pipeline-internal digest, but not the standard bytewise SHA-256 reported by
`digest::digest(..., file = TRUE)`, `shasum -a 256`, or an explicitly binary
R connection.

An R audit of the current artifact tree found:

- 35 of 35 cached `.RData` files with different old and bytewise digests;
- 66 of 66 generated `.rds` files with different old and bytewise digests;
- 60 of 60 `.csv` files whose file hashes were already byte-correct; and
- 17 CSV artifacts that nevertheless embedded stale binary-input digests in
  provenance fields.

The file paths, byte sizes, modification times, pinned repository commits,
and contents did not change. This is a provenance defect, not evidence of a
data-value change.

## Repair

`artifact_sha256()` now:

1. opens the file explicitly with `file(path, "rb")`;
2. closes the connection with `on.exit()`; and
3. returns one unclassed lowercase hexadecimal character value.

The regression fixture includes NUL bytes, CRLF and LF line endings, high
bytes, ordinary text, connection closure, and class/attribute removal.

The 35 cached pinned sources were reconciled locally without downloading.
The exact old-to-new mapping is
`audit/reconciliation/pinned_download_hash_reconciliation.csv`. The mapping
uses project-relative paths, reproduces every old digest, verifies unchanged
bytes and metadata, and records zero downloads. The runtime pinned manifest
and `audit/baseline/pinned_source_hashes.csv` now contain bytewise hashes.

## Required downstream refresh

Artifacts must be regenerated in dependency order:

1. full Preparation 01 import/state alignment;
2. full Preparation 02 coverage/sample flow;
3. full Preparation 03 fixed reference profiles;
4. cutoff-neutral Preparation 04 state-support diagnostics;
5. cutoff-neutral MDER support diagnostics; and
6. all later metrics, models, displays, and claims.

Optional BAUA smoke artifacts must be rerun or removed before final packaging.
No stale binary digest may remain in a final manifest, settings table,
embedded RDS provenance attribute, or audit statement.

## Scientific-value verification

Before regeneration, an R baseline was retained outside the project for:

- aligned row, participant, and participant-day counts;
- eligible coverage rows and participant-days;
- the saturation audit;
- the full state-support candidate table; and
- bytewise hashes of the canonical artifacts.

The hash repair remains a low-risk provenance repair only if regenerated
scientific values and counts reconcile exactly. Any discrepancy in data
values, inclusion, support, or analytical output reopens the finding as a
scientific gate.

## Reopening condition

Reopen this finding for any non-bytewise hash producer, unexplained digest
state, changed cached bytes or source metadata, stale embedded input hash, or
scientific-value mismatch after regeneration.
