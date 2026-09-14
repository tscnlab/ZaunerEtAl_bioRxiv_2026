# REPORT-018 Order 71b2a `fig-s3` clarification proof

Date: 2026-09-03

Disposition: `PASS_FOR_EXACT_22_TARGET_REPAIR`

The Writer correctly stopped Order 71b2 before mutation because its literal
`fig-s3` precondition did not match the frozen OOXML.

Independent read-only XML inspection under R 4.6.1 reproduced the following:

| DOCX | Internal hyperlinks | Unique targets | Unique bookmark names | `fig-s3` hyperlink targets | `fig-s3` bookmarks | Unresolved targets |
|---|---:|---:|---:|---:|---:|---:|
| Preserved raw | 124 | 102 | 179 | 0 | 0 | 16 |
| Stopped candidate | 124 | 102 | 173 | 0 | 0 | 22 |
| Protected canonical | 124 | 102 | 173 | 0 | 0 | 22 |

The stopped candidate and protected canonical have the same exact unresolved
set: `fig-study-overview`, `fig-daily-architecture`,
`fig-activity-context`, `tbl-participant-site`, `tbl-brown-adherence`,
`tbl-metric-context`, `fig-s1`, `fig-s2`, and `fig-s4` through `fig-s17`.

`fig-s3` is not an unresolved target. It is absent from both the 102-name
internal-hyperlink target set and the bookmark-name set. This is intentional
frozen structure, not a 23rd defect. The repair must keep `fig-s3` absent and
must add exactly the already sealed 22 bookmark pairs.

All frozen identities remain exact. The Writer stop record confirms that no
postprocessor edit, postprocessing pass, page render, promotion, Quarto render,
capture refresh, or artifact-marker counter was consumed.

