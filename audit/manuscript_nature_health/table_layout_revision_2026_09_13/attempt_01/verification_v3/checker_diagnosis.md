# Completed checker run and exact diagnosis

The third run completed 1,111 checks, of which 1,046 passed. Inspection found
three checker representation issues, not a change in any numerical value:

1. `xml_text()` concatenates the estimate and interval across an HTML `br`.
   The display intentionally places them on different lines. The corrected
   text walker treats only `br` as a whitespace boundary and otherwise keeps
   every character. It does not remove punctuation or compare rounded values.
2. In this xml2 version, setting an attribute to `NA_character_` writes the
   literal attribute value `NA`. The normalized row copy therefore still had
   the candidate-only attributes. The corrected checker removes the three
   specified attributes from the attribute vector and compares all remaining
   serialized row markup exactly.
3. After removal of Table 2's A/B panel labels, the remaining panel column is
   entirely empty. Automatic CSV type conversion reads it as logical NA rather
   than the original character empty strings. The unaffected-row comparison
   now reads both CSV files as character fields, preserving every stored field.

The original checks and executed verifier remain here. No candidate source,
page, cell, map or embedded image was changed. Verification continues in
`verification_v4/`; all numerical checks still compare the accepted source
strings and independently verify the descriptive fractions in R 4.6.1.
