# REPORT-018 sealed Order 71b2a: Word bookmark clerical correction

Date: 2026-09-03

Owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_FOR_ONE_DISPATCH`

## Purpose

Order 71b2 stopped before mutation because its statement that `fig-s3`
"already resolves" was literally false. Independent inspection confirms that
`fig-s3` is absent from both the internal-hyperlink target set and bookmark
set in every frozen DOCX. It is not one of the 22 unresolved targets.

This continuation corrects only that clerical precondition. Every other
boundary and requirement of Order 71b2 remains unchanged.

## Corrected precondition

Before mutation, require exactly:

- 124 internal hyperlinks;
- 102 unique internal target names;
- 173 unique existing bookmark names and IDs in the stopped candidate;
- the exact 22-name unresolved set listed in the clarification proof;
- zero `w:anchor="fig-s3"` elements; and
- zero `w:name="fig-s3"` bookmark starts.

After mutation, require exactly:

- the same 124 internal hyperlinks and same 102 unique target names;
- 195 unique bookmark names and IDs;
- zero unresolved targets;
- preservation of every one of the 173 pre-existing bookmark elements;
- zero duplicate bookmark names or IDs;
- zero `w:anchor="fig-s3"` elements; and
- zero `w:name="fig-s3"` bookmark starts.

Do not create, infer, or manufacture a `fig-s3` hyperlink or bookmark. Add
exactly the 22 already sealed zero-width bookmark pairs and no 23rd pair.

## Execution boundary

1. Replay the new dispatch manifest and the Order 71b2a clarification proof.
2. Reconfirm all frozen input identities and the Writer's no-mutation stop.
3. Apply the same focused postprocessor helper specified in Order 71b2, with
   only the corrected `fig-s3` condition above.
4. Run the postprocessor exactly once from the frozen fresh raw DOCX into a
   new candidate path. Preserve the stopped candidate unchanged.
5. Run the complete structural verification specified by Order 71b2,
   including the corrected before-and-after bookmark inventories.
6. Only after structural PASS, run the still-unused single bundled
   `render_docx.py` page render and inspect every page at original resolution.
7. Promote once to the canonical DOCX only after every gate passes.
8. Return the complete non-circular evidence manifest, canonical postimage,
   structural results, page inventory, and every-page QA record.

No Quarto render, browser capture, manuscript-content edit, scientific edit,
visible-content edit, accepted HTML change, website change, figure-source
change, second artifact marker, second postprocessing pass, or second page
render is authorized. Preserve the accepted direct Supplementary Figure S6
SVG in the HTML/source chain. Stop on any mismatch, nonunique destination,
unexpected target, 23rd bookmark pair, or protected-identity change.

Order 71c remains held until independent acceptance of the promoted canonical
DOCX.
