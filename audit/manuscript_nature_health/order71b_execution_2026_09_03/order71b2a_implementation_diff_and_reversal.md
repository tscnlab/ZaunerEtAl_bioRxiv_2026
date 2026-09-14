# Order 71b2a implementation diff and reversal

Date: 2026-09-03

The only implementation source changed was
`scripts/manuscript_nature_health/prepare_word_manuscript.py`.

- sealed preimage: SHA-256
  `1a2b8091b34cd0fa88dcf6143cf336c52b531773e66e1578ac818fddfba97adf`,
  38,747 bytes;
- focused postimage: SHA-256
  `074867c89d9600566de77f65890a8260fa2c13766e0ebeb351a9688f1d1a0c71`,
  47,744 bytes.

The patch adds one fail-closed helper and calls it exactly once after all
display replacements and before document saving. The helper verifies the
sealed before-state, maps exactly 22 unique caption or Heading 3 destinations,
adds 22 zero-width bookmark pairs with new numeric IDs, verifies the sealed
after-state, and removes those pairs from an in-memory copy to require an
exact reproduction of the pre-repair document XML. It explicitly requires
`fig-s3` to remain absent from hyperlinks and bookmarks.

The companion reversal checker removes only the new constants, helper, call,
and JSON audit field in memory and requires exact reproduction of the sealed
preimage hash and byte count. No Quarto configuration, QMD, HTML, capture,
scientific artifact, stopped candidate, canonical DOCX, or website file was
changed in this implementation step.
