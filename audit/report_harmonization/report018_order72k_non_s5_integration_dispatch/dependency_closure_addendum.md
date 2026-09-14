# Order72k direct dependency closure

The Writer's source-reference scan identified 15 HTML table fragments and six
provenance metadata files directly referenced by the frozen selection QMD but
absent from the original 186 input pins. This is an input-inventory omission,
not a request to revise or recompute those resources.

The Harmonizer confirms candidate-only copying of these exact 21 files under
the existing Order72k copied-resource scope. Their paths, SHA-256 identities,
byte sizes and original references are in `dependency_closure_pins.csv`,
SHA-256 `c43661fc9595057ead1272b9d02a9750c32a43484e4584d6c8d0b3a9fa36a88f`.

Read-only R 4.6.1 verification found all 21 files to be regular, non-symlink
inputs matching the Writer's recorded identities and direct references in
the frozen selection QMD. Twenty identities also match prior accepted
manifests. The remaining item is the selection-asset manifest itself, whose
SHA-256 remains the previously recorded `30ff83aac8a932d9702e7b7ec9c8c561729703da1a390c022099508067960640`.
No conflicting prior identity was found. Full comparison and
session details are in `dependency_closure_identity.csv` and
`dependency_closure_session.txt`.

Copy only the listed files into the two authorized candidate roots as needed
to satisfy those direct references. Preserve their bytes on copy, record the
source-to-copy mapping, and rebase candidate references to the copied files.
Do not recursively copy their linked evidence trees or serve the source
project. Unpinned legacy PNGs superseded by the accepted SVG mapping need not
be copied. Preserve the distinction between the selection S10 fragment and
the already pinned manuscript S10 fragment; do not substitute one for the
other. Only the font-layer changes already released by Order72k may affect
candidate table presentation. Scientific content and source inputs remain
unchanged.

This additive inventory leaves the original order, 186-row inventory, release
seals, write boundary, rendering budget, visual lease and Brown hold intact.
Proceed with the existing integration work after checking these added pins.
No further author decision is needed for this unchanged dependency closure.

The addendum and exact pin-file hash were sent to Writer task
`019ffb39-372e-7262-bfac-192751fd0e63`; the send tool acknowledged that target
without an error.
