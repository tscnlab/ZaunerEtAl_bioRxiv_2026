# Phase 2 `gt` table audit

- Current table candidates audited: 195
- Current native `gt` renders: 190
- Current non-`gt` renders: 5
- Resolved unique table anchors: 184
- Tables with exactly one resolved Quarto caption: 195
- Tables whose rendered caption matches the source caption: 195
- Rendered semantic table cores (`thead` + `tbody` + headers): 194
- Current complete native-`gt` publication structures: 179
- Nonconforming `tbl-` identifiers: 11
- Endpoints requiring conversion or identifier repair: 16

All manuscript main and supplemental table endpoints are proposed to use
native `gt_tbl` objects printed from labelled knitr cells. The current
non-`gt` conversion targets are listed in
`phase2_gt_conversion_targets.csv`. This audit does not execute QMD code
or assess scientific values.
