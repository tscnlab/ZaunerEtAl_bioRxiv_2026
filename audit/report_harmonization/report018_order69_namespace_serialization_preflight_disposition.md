# REPORT-018 Order 69 namespace-serialization preflight disposition

Date: 2026-09-02

Owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `AUTHORIZED_TO_CONTINUE_ORDER69_AFTER_ONE_CORRECTED_TEMPORARY_PREFLIGHT`

## Finding

The Order 69 prospective A4 geometry check passed every required substantive
assertion before the DOCX-only render. The reference-derived portrait page size
is 11,901 by 16,840 twips, the final portrait margins have the same complete
attribute mapping as the reference-derived base margins, the intended landscape
sections use the swapped A4 dimensions with the previously accepted landscape
margin logic, and no section uses 12,240 by 15,840 US Letter geometry.

The sole stop arose from an additional owner-authored comparison of raw
`etree.tostring()` bytes for an isolated copied `w:pgMar` element and the same
element after attachment to the Word document tree. The attached element
inherits additional namespace declarations from the document root. Namespace
declarations can therefore change the serialized bytes without changing the
element's expanded name, attributes, text, children, or WordprocessingML
meaning. Read-only inspection confirmed identical complete attribute mappings
and zero children for both elements.

This is a temporary test-harness classification. It is not a DOCX source,
reference-document, page-geometry, scientific, or rendered-output defect. No
render, postprocessing pass, canonical-output replacement, HTML render, or
website write occurred before the stop.

## Bounded continuation

Authorize exactly one correction of the temporary prospective test. Replace
only the raw serialization equality with semantic XML element equivalence that
requires:

1. the same expanded element name;
2. the same complete attribute mapping, including every WordprocessingML
   margin attribute and value;
3. equivalent text and tail values after the test's explicit empty-element
   normalization, if such values are present;
4. the same child count and recursively equivalent child content; and
5. the already required A4 portrait, landscape, margin, and no-US-Letter
   assertions.

Exclusive XML canonicalization is also acceptable if and only if the checker
first proves the same expanded element name and complete attribute mapping.
The test must not ignore, delete, or normalize any `w:pgMar` attribute.

Run this corrected temporary preflight exactly once. If it passes, continue the
already sealed Order 69 without another source edit: one DOCX-only render, one
postprocessing pass using the current authorized postprocessor postimage, and
the complete structural and page-by-page verification. If any substantive
geometry, margin, source, preservation, environment, render, postprocessing, or
layout check fails, stop without retry.

## Frozen live state at disposition

- controlling Order 69: SHA-256
  `6d0a9dd39dd969f99fc97853aaf0070da0a42739c50d092c777a4bcbbbdd051e`
- Order 69 dispatch manifest: SHA-256
  `8e1f2cddb0741afe0ffdd9037b79d957e2b0bb372cd1370994efa2ad06a54244`
- reference DOCX: SHA-256
  `8c0cf634a4958aa05412de3f5f15aa92c40cbb5331a2319f761530472697e15f`
- current nested profile postimage: SHA-256
  `c7c3fc8a96f1e65914cfb88c8d4de2bf8bcacb75fcf37902b262c79d2becae24`
- current authorized postprocessor postimage: SHA-256
  `aae7c9307510ee5adc295e9e4d93e39496b0b50cc47d46bcfe5f22c6cf28e2c7`
- preserved profile preimage: SHA-256
  `2aa2911f13d4532aa8ce98e38363a5c92b1d2bdc025b3c8bba49950077e76b33`
- preserved postprocessor preimage: SHA-256
  `0e6310467104be48993ca00f63d18e8e0b6d9ac7b59605ac18f749ee250a8d9c`
- unchanged canonical DOCX preimage: SHA-256
  `07ff074d4bd4124656063f69a2437b4c646a8240ad771ce94d30339f41d0604c`
- unchanged accepted standalone HTML: SHA-256
  `8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac`

Order 70 website integration remains held until independent acceptance of the
corrected Word manuscript.
