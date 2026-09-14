# HTML verifier change chronology

Date: 2026-09-11

This chronology classifies a QA-checker adjustment. It did not change the QMD,
rendered candidate, canonical HTML, table fragments, accepted SVGs, or any
scientific value.

1. The one authorized Quarto render completed at approximately 14:54. The
   rendered candidate was relocated into the owner root under the subsequent
   directory-only recovery at approximately 14:57.
2. The pinned checker, SHA-256
   `0e97b32919e8ba1c52a3d67e56a8d01573c3aa853f3e9c5826ead47dfb54c375`,
   32,612 bytes, then stopped on rendered-table cell-vector and inserted-caption
   equality checks.
3. At 15:02, `diagnose_html_verifier.R` and two endpoint diagnostic CSV files
   were created. They showed that Quarto had introduced empty cells into the
   rendered `gt` DOM, shifting whole-cell `xml_text` vectors even though the
   ordered non-empty descendant text nodes remained exact. They also exposed
   only smart-typography differences in the approved inserted captions.
4. At 15:06, the checker was adjusted once. Source versus rendered table
   semantics were compared as normalized, non-empty descendant text-node token
   sequences. A separate comparison of every complete rendered cell vector
   against the frozen preimage HTML retained the DOM-shape preservation gate.
   NBSP and straight-versus-curly quotation normalization was applied only to
   the two coordinator-approved inserted captions. The resulting checker is
   SHA-256
   `ef2fd6bf1bd3a3c0a70d8771a8f4da4ea1b96ea86d89e015ddd5cf14337702e9`,
   34,346 bytes, and it passed 38 of 38 HTML checks.
5. No content file or candidate was changed and no rerender occurred during
   this diagnostic and classification sequence. Browser QA began only after
   the 38-check pass.

Diagnostic identities:

- `diagnose_html_verifier.R`: SHA-256
  `abf4cd146266f25f711662d322c5fa6d4a59aab6b319b70090fd6f105008905a`,
  2,773 bytes.
- `tbl-h08-near-eye-results_cell_diagnostic.csv`: SHA-256
  `3e5a143e53ad83eb6b1a6f75761eee14506b4b0ad25729a4f3deef1b364f88ac`,
  3,306 bytes.
- `tbl-participant-site-manuscript_cell_diagnostic.csv`: SHA-256
  `724e1625624128d8dd0fdccc93e1111258e01948c144d28f8beb4c4aec113057`,
  10,456 bytes.
