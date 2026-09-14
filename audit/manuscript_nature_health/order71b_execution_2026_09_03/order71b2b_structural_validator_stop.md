# Order 71b2b structural-validator stop

Date: 2026-09-03

Disposition: `STOP_BEFORE_PAGE_RENDER_OR_PROMOTION`

The recovery postprocessor invocation completed and produced the repaired
candidate with SHA-256
`9dd88539d7fea176423ecc5b201ea1ef8c92b925c561ffd5cb6ee9b5463f0e92`.
Its built-in bookmark checks passed: 124 internal hyperlinks, 102 unique
targets, 173 to 195 unique paired bookmarks, exactly 22 additions, zero
unresolved targets, exact XML reversal, and zero `fig-s3` hyperlinks or
bookmarks.

The complete Order 71b validator then stopped at its supplementary-figure
heading cardinality check. The validator requires two paragraphs beginning
`Supplementary Figure S<n>.` for every S1 through S17. The accepted combined
sections S13 through S17 instead contain one Heading 3 beginning
`Supplementary Figure S<n> and Table` and one caption beginning
`Supplementary Figure S<n>.`. Read-only inspection confirmed two uniquely
resolved paragraphs for every supplementary figure when the accepted combined
heading form is included. S1 through S12 each have two period-form paragraphs;
S13 through S17 each have one period-form caption and one combined heading.

This is a validator condition that had been masked by its earlier stop at the
unresolved-bookmark assertion. It is not a candidate content defect. The
successful repaired candidate is preserved unchanged. No page render,
canonical promotion, Quarto render, capture refresh, manuscript-content edit,
HTML change, website change, or second artifact marker occurred. A sealed
validator-only continuation is required before page rendering.
