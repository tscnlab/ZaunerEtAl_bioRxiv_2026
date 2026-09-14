# Candidate structural check, first attempt

Date: 2026-09-02

Status: stopped before canonical promotion for coordinator disposition.

The single authorized DOCX-only Quarto render and the single authorized Word postprocessing pass both completed successfully. The candidate is `candidate_reference_styled.docx`, 28,792,251 bytes, SHA-256 `218b6ba29fcc70fb5754725476c3e804eb84bd5700540ba673cb9554372fb009`.

The structural audit passed every substantive check, including:

- body text and display media preserved exactly from the accepted preimage;
- all reference typography and selected style properties;
- 27 alternating A4 portrait and landscape sections with the intended margins;
- 54 resolving even/default footer references and reference-equivalent footer semantics;
- zero native tables, 53 inline images, complete alternative text, and exact display order;
- all 19 accepted table outputs, 20 conceptual figures, and 32 table-image parts;
- exact two-part Supplementary Figure S8 crops;
- complete title, author list, abstract, 91 cited references, declarations, and supplementary sequence.

The sole failed assertion was an additional raw-byte equality check between the raw Quarto and postprocessed `word/styles.xml` parts. A formatted diff showed that the only difference was the XML declaration: the postprocessed file added `standalone="yes"`. The complete `<w:styles>` root element and its descendants were otherwise identical, and all selected reference style signatures matched exactly.

The canonical DOCX was not replaced. No page-image render, HTML render, or website write occurred after this stop.

Coordinator disposition `report018_order69_styles_xml_declaration_disposition.md` independently reproduced the XML-declaration-only difference and authorized semantic root equivalence. The corrected temporary structural audit then passed all 202 checks against the existing raw render and existing postprocessed candidate. The full result is recorded in `candidate_structural_checks.json`.
