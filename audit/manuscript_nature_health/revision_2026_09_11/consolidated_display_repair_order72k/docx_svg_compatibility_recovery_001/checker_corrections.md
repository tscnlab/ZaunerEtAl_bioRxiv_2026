# Independent checker corrections only

The original `verify_document.R`, its 57-check result (54 PASS), geometry
inventory and session log are retained byte-for-byte. No document, assembly
helper, embedding helper or input map was changed. No producer was rerun.

Three assumptions were corrected in `verify_document_verified.R`:

- The retained reference's style named `heading 1` has styleId `berschrift1`,
  not `Heading1`. Resolve that named style through styles.xml. Read-only
  inspection already showed all 13 section starts were present and true.
- Six main display bookmark names existed inside raw float wrappers and were
  correctly repaired after wrapper removal. Check all 22 new ID/name pairs
  (IDs 360 through 381), not 22 net-new names relative to the untouched raw
  document. Six repaired names and sixteen new names comprise the 22 repairs.
- For two wide table images, multiplying sub-EMU integer truncation by the
  aspect ratio exceeded a fixed two-EMU derived-error tolerance. The verified
  check is stricter: reproduce the unchanged helper's width/height bounds and
  exact Inches integer conversion, then require exact equality on both axes.

Every other test remains unchanged. New result files have `verified_` prefixes;
the original failed output is not overwritten. These are structural-checker
corrections, not scientific or document corrections. The separate checksum
serialization failure was likewise preserved; only its S3 class conversion
was corrected before JSON output. Neither issue consumed a new assembly or
embedding invocation.
