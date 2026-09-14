# REPORT-014/017 H04 order-35b source independent acceptance

Date: 2026-08-20

Status: ACCEPTED SOURCE-ONLY. Every H04 render remains held.

## Independent verification

Order 35b moved exactly two source line boundaries. `Delft (NL)` is now
contiguous in the result QMD, and `Munich (DE)` is now contiguous in the
preparation/provenance QMD. No non-whitespace character or token changed.

The accepted current sources are:

- `notebooks/hypotheses/H04.qmd`, SHA-256
  `f8adb6d78be041ce296dd7e89eb92769b128631c1b4227ce5d8ab3d526daf1d5`,
  83,285 bytes;
- `audit/hypotheses/H04/H04_analysis_preparation.qmd`, SHA-256
  `efdb5be8dc194695f40c50249fab14905ec337bc63079ae589557de860188474`,
  91,202 bytes;
- `audit/handoffs/H04_worker_handoff.md`, SHA-256
  `99de6fd036b7e7c52a55406615642024092e3177317255101c4a5db1ff391036`,
  31,926 bytes.

The full result and companion sources are independently identical to their
preimages after removing whitespace. Their token sequences, all R chunk
bodies, chunk labels, inline-R expressions, endpoint order, captions, alt
text, links, formulas, numeric tokens, assignments, artifact references, and
source-data references remain exact. The two QMD reverse proofs reproduce the
accepted order-35a hashes. The handoff append reverses exactly to its
dispatched preimage while preserving every historical byte.

## Test and preservation results

Independent R 4.6.1 audit passes:

- 19 of 19 source-reflow checks;
- all 37 H04 source-harmonization gates;
- the participant random-intercept assessment against accepted stored
  artifacts, without refitting;
- the global country-coded-site contract across all 37 reader QMDs with zero
  findings;
- 30 of 30 protected identities; and
- all 24 rows of the non-circular owner manifest.

The owner execution record is
`audit/hypotheses/H04/report017_order35b_country_label_reflow/H04_order35b_execution_record.md`,
SHA-256 `6be8b796639ebcd6d876989f6f1a2e08ef8de117d3a0bc2fa5609310161f1f79`.
The 24-row owner manifest is SHA-256
`76bdf811aff2d38326b5c1cc1a27e0cf8d0cca1aa8c73d4638c1917b9e829b54`.

The global findings recorded by H01 at the sequencing checkpoint are therefore
resolved without scientific or rendered-output change. All prior order-35 and
order-35a evidence remains historical and byte-identical.

No QMD was executed. No scientific wording, value, formula, code chunk, test,
artifact, source data, existing manifest, HTML/build copy, profile, shared
configuration, ledger, package, or lockfile changed. No Quarto command,
scientific computation, artifact regeneration, render, commit, push, or upload
occurred.

H04 is idle with its source package accepted. It may enter the serial
REPORT-017 render queue only through a later separate release. H01 remains the
sole active integration path.
