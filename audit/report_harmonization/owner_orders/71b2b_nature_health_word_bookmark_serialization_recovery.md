# REPORT-018 sealed Order 71b2b: Word bookmark serialization recovery

Date: 2026-09-03

Owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_FOR_ONE_DISPATCH`

## Purpose and authority

Order 71b2a completed its preflight and source-reversal checks, then its single
postprocessor invocation stopped before bookmark mutation or save because a
generic lxml element does not implement python-docx's `.xml` convenience
property. The intended candidate is absent. No page-render or promotion
counter was consumed.

This recovery authorizes one mechanical source correction and one replacement
postprocessor invocation. Every scientific, content, rendering and promotion
boundary in Orders 71b2 and 71b2a remains controlling.

## Authorized source correction

Starting from the exact 47,744-byte postprocessor with SHA-256
`074867c89d9600566de77f65890a8260fa2c13766e0ebeb351a9688f1d1a0c71`:

1. add exactly one `from lxml import etree` import;
2. replace exactly the four generic bookmark-element `.xml` snapshots in
   `protected_starts`, `protected_ends`, `starts_after_map` and
   `ends_after_map` with
   `etree.tostring(bookmark, encoding="unicode")`; and
3. make no other source change.

Retain `root.xml`, `reversed_root.xml`, paragraph `_p.xml` snapshots and all
other accepted logic unchanged. Before invocation, require the focused source
diff to be exactly reversible to the frozen 47,744-byte preimage.

## Recovery execution

1. Replay the new non-circular dispatch manifest and no-save dry-probe record.
2. Reconfirm both prior Writer stop records and every frozen identity.
3. Apply only the five-line-equivalent source correction above.
4. Invoke the postprocessor once from the frozen fresh raw DOCX into a new
   candidate. Preserve the earlier stopped candidate unchanged.
5. Require the full corrected bookmark contract: 124 hyperlinks, 102 unique
   targets, 173 to 195 unique paired bookmarks, exact 22 additions, zero
   unresolved targets, all 173 existing bookmark serializations preserved,
   exact reversal, and `fig-s3` absent before and after.
6. Run the complete Order 71b structural validation against the new candidate.
7. Only after structural PASS, run the still-unused single bundled
   `render_docx.py` page render and inspect every page at original resolution.
8. Promote once to the canonical DOCX only after every structural and visual
   gate passes. Return the exact canonical postimage and complete non-circular
   evidence manifest.

No Quarto render, browser capture, table or figure regeneration, accepted
source or HTML change, website change, scientific change, visible-content
change, second artifact marker, second recovery invocation or second page
render is authorized. Preserve the accepted direct Supplementary Figure S6
SVG in the Quarto/HTML chain. Stop on any mismatch.

Order 71c remains held until independent acceptance of the promoted canonical
DOCX.
