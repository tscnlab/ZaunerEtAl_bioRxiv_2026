# REPORT-018 Order 69 styles XML declaration disposition

Date: 2026-09-02

Owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `AUTHORIZED_FOR_ONE_CORRECTED_STRUCTURAL_CHECK_AND_CANDIDATE_PROMOTION`

## Independent finding

The single authorized DOCX-only render and the single authorized Word
postprocessing pass completed. The candidate Word file is
`audit/manuscript_nature_health/reference_doc_word_correction_2026_09_02/candidate_reference_styled.docx`,
SHA-256 `218b6ba29fcc70fb5754725476c3e804eb84bd5700540ba673cb9554372fb009`,
28,792,251 bytes.

The owner structural audit passed the required manuscript-content, display,
A4 geometry, margin, footer, numbering, typography, caption, alternative-text,
Supplementary Figure S8 crop, and reference-style signature checks. The sole
stop came from an additional owner-authored raw-byte comparison of
`word/styles.xml` before and after postprocessing.

Independent read-only inspection reproduced the difference and its scope:

- raw styles part: 64,925 bytes, SHA-256
  `7eb6d5478c1c4fadf1c7f01b6ad93c289d08ffcd190ad09528ea064325a8e82a`;
- candidate styles part: 63,770 bytes, SHA-256
  `ffbfce98d680fd2565184471557b3d870b85a839fe7e8f5fb4d00175ded32d1a`;
- both parsed roots have the same expanded `w:styles` name, the same root
  attributes, and 115 children;
- serialization of the parsed root elements with the XML declaration omitted
  is byte-identical at SHA-256
  `b6d50f7e80dd74dec3de188120e4597f1b729e46090e7a635ee68613a3cc2c72`;
- exclusive XML canonicalization is byte-identical at 77,278 bytes and
  SHA-256
  `be4ee30f3c397b46e63c61f1cd64bc189f804bff3391fdf54d0fa661f9be312b`;
  and
- the visible prefix difference is the XML declaration produced by
  `python-docx`, including `standalone='yes'`, plus serialization formatting.

The complete styles element is therefore semantically and canonically exact.
This is a temporary verification-harness issue, not a Word style, layout,
content, accessibility, scientific, or rendering defect.

## Bounded continuation

Replace only the temporary structural check's raw `word/styles.xml` byte
assertion with a semantic comparison that requires the same expanded root
name, complete root attribute mapping, and recursively equivalent element
content. A parsed-root serialization without the XML declaration or exclusive
XML canonicalization is acceptable. The check must continue to verify every
selected reference style signature separately and must not ignore any style
element, property, attribute, or text value.

Run the corrected structural verification exactly once against the existing
raw and candidate DOCX files. Do not rerender, rerun the postprocessor, or
change the profile, postprocessor, manuscript source, HTML, displays, or
website. If the corrected verification passes, promote the existing candidate
to the canonical DOCX exactly once, then perform the complete page rendering,
page-by-page visual inspection, preservation checks, evidence seal, and
teardown already required by Order 69. Stop without retry on any substantive
new defect.

Order 70 website integration remains held until independent acceptance of the
completed Order 69 Word manuscript.
