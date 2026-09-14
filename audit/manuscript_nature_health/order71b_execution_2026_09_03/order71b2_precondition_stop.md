# Order 71b2 precondition stop

Date: 2026-09-03

Disposition: `STOP_BEFORE_MUTATION`

The 16-row Order 71b2 dispatch manifest reproduced exactly under R 4.6.1.
The stopped candidate contained 124 internal hyperlinks, 102 unique internal
target names, 173 unique bookmark names and IDs, and 173 matching bookmark-end
IDs. The exact sealed 22-name unresolved target set reproduced.

The additional sealed precondition that `fig-s3` already resolve did not
reproduce. Direct OOXML and `python-docx` inspection found neither
`w:anchor="fig-s3"` nor `w:name="fig-s3"` in any of these frozen inputs:

- preserved raw DOCX, SHA-256
  `9cb087d8ee3d3e24fe17dea265e3898b2078c90e3cdd10bd02d4012b72f99786`;
- stopped candidate, SHA-256
  `313311f6cf87fdf7bf37fc27129cfc7b7048304587d1383ea53e77424756399d`;
- protected canonical DOCX, SHA-256
  `6cd592391f720829ed278a35e81c854ee7fd54eca6a4a4e664faad7b37310f91`.

`fig-s3` is absent from the internal-hyperlink target set, which is why it is
not among the 22 unresolved targets. No postprocessor edit, postprocessing
pass, page render, canonical promotion, Quarto render, capture refresh, or
second artifact marker occurred. A corrected sealed continuation is required
before work resumes.
