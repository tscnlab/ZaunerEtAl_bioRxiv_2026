# Stopped include-path check

The second verifier completed the table-content and markup checks, then
stopped because its anchored regular expression did not span a multiline
manuscript block. It returned the complete block instead of the include path.
The abstract extractor used the same flawed multiline assumption.

The corrected verifier extracts the single include line directly and uses
the exact Abstract/Introduction delimiters for the abstract. No manuscript,
table cell, page, image payload or map was changed. The completed partial
checks, stopped result and executed verifier remain in this directory.
The next full verification uses `verification_v3/`.
