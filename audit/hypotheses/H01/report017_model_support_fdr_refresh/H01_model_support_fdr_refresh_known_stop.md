# H01 REPORT-017 order 31f controlled stop

Date: 2026-08-14

The bounded model-support display repair passed. The old-label PNG and
SVG were regenerated from the frozen current METRIC-011 source and matched
the sealed pre-repair artifacts exactly. The installed PNG differs only in
5,697 legend-title pixels, and the installed SVG differs only at its single
legend-title node.

The unchanged REPORT-016 focused test cannot complete against the accepted
current H01 QMD. The QMD contains 40 links to 36 unique registration-record
anchors, and all 36 anchors exist in
`notebooks/preregistration_deviations.qmd`. Line 198 of the unchanged test
still asserts that no `preregistration_deviations.qmd` link exists. The
harmonization coordinator directed that this unrelated assertion remain
unchanged under order 31f.

Accordingly, the Stage 3 and worker manifests remain at their accepted
pre-refresh identities and still contain the sealed pre-refresh hashes for
the builder, PNG, and SVG. They were not partially resealed. The current
targets, refresh script, focused display test, REPORT-016 test, QMDs, stopped
HTML, and historical REPORT-016 records remain frozen at the identities in
the accompanying owner manifest. No Quarto render or scientific computation
ran after the coordinator-directed stop.
