# H11 Order72j independent static acceptance

Date: 2026-09-11.

Status: STATIC_CANDIDATE_ACCEPTED_VISUAL_PENDING. This is not final component,
native Word, LibreOffice or promotion acceptance.

## Exact candidate and independent proof

Candidate:
`audit/hypotheses/H11/report018_order72j_libreoffice_compatibility/candidate/H11_reader_near_eye_curves_arial_safe_margin.svg`
SHA-256 ca613c8860b38625524518d106f0408ad264f90d78ef92bd9abd87f4daad904e,
25,243 bytes.

Accepted source:
`audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg`
SHA-256 ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe.

Under R 4.6.1, independent exact literal substitution of 34 Helvetica font-family
declarations to Arial, outer height 792.00pt to 828.00pt, and viewBox height
792.00 to 828.00 reproduces every candidate byte. The inverse substitutions
reproduce every accepted-source byte and SHA. Width, origin and all other
content remain unchanged. This directly verifies the permitted 36-point
bottom-canvas extension and excludes an unreported coordinate or text edit.

The candidate parses as SVG, retains the same 34 visible text nodes, has six
unique IDs and 11 resolving local references, and has no image, raster payload,
script, foreignObject, metadata or external-resource dependency. The owner's
14 structure checks and the independent 14-check audit pass. Exactly one
candidate attempt is recorded.

The owner's 20-member unique non-circular manifest rehashes exactly at
eb483dba0314be78780159ba96b16b98b8b00ad9f790d768064f83e56ce924c0.
The release seal passes 123/123, H11 execution inputs pass 34/34, and protected
paths pass 531/531. All three owner pre/post inventory CSV pairs are
byte-identical. The owner seal remained exact after the independent audit.

The independent checker did not run the owner's implementation, generate a
figure, inspect a browser, start a server, open an Office document, or promote
any file. Its R script, output checks and rehash evidence are retained here.

## Remaining boundary

The Harmonizer may coordinate the browser visual lease already authorized by
Order72j. It has reported assigning that lease to H11 because H07/H09 had not
yet reached their visual safe points. This record does not issue a competing
lease or expand the scope.

Keep the current 20-member owner seal and its NOT_ISSUED lease-state snapshot
unchanged as historical static evidence. Add later browser evidence and a new
QA seal without overwriting those members. Rehash the candidate after QA.

Native Word non-regression and demonstrated LibreOffice improvement remain
required before this optional candidate can supersede the accepted S17.
No Word/LibreOffice generation or canonical replacement is released by this
static acceptance. If compatibility does not improve, retain the accepted
source. H07/H09 completion does not depend on this optional result. Brown,
table, Quarto, Word and manuscript integration holds remain unchanged.
