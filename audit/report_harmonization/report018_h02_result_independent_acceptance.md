# REPORT-018 H02 result independent acceptance

Date: 2026-08-20

Status: **ACCEPTED**

The H02 result page is accepted for source, targeted render integration,
semantic table repair, internal links subject only to the shared DOC-001 hold,
and visual display. The H02 companion remains held for its later separate
render after `supplementary_information.qmd`.

## Independently reproduced identities

- completion record:
  `audit/hypotheses/H02/report017_order33g_result_completion/completion_record.md`,
  SHA-256
  `39e5f2b4104c83587a8022a196d5eec16b9c7429f910dcc127dbb74284eb3b88`;
- 77-row owner manifest:
  `audit/hypotheses/H02/report017_order33g_result_completion/owner_evidence_manifest.csv`,
  SHA-256
  `aa19322c402b9260b6687dc4a65a4b14ac6e761acf5b8fa1edd33d0830e5c0db`;
- reader test:
  `479a702e7c5c52cf85e8591300a30c759da945f4c65ecb28cad67bb2e6752d3f`,
  16,545 bytes;
- result QMD:
  `4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d`;
- result HTML:
  `736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9`,
  296,427 bytes;
- held companion QMD and HTML:
  `92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1`
  and
  `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa`;
- profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

R 4.6.1 independently verified all 77 manifest rows, byte counts, unique
paths, and non-circularity. The reader test has the exact expected post-edit
identity. Its nine authorized substitutions reverse byte-for-byte to the
accepted pre-edit test.

## Nonvisual acceptance

The full reader test and unchanged paired-placement test both exit 0. The
preparation test was correctly neither edited nor executed. It remains at
SHA-256
`ead7a55246a2625b1382acc302b6004892dbf7f7830285f2bae830cb0859d3f8`
for the later companion integration.

The unchanged fresh result HTML passes:

- 15 native gt table endpoints and five figure endpoints in accepted order;
- exactly one nonempty caption for every endpoint;
- zero duplicate document IDs;
- 530 of 530 table-header references and 552 of 552 document ID references;
- 22 preregistration links to 18 unique accepted anchors;
- all nine country-coded site labels;
- all image, alt-text, source-data, navigation, disclosure, and no-error or
  warning contracts;
- exact semantic reversal to pre-hook SHA-256
  `9c3d2c9fe062756cd2a3454522bf440cc12153999621557a61eb19fa073a8e84`,
  with normalized DOM and visible text unchanged;
- exact 210-path protected reconciliation.

Exactly one internal reader link is unresolved:
`../../supplementary_information.html`, labelled `Supplementary information`.
It is the accepted shared DOC-001 hold. No second unresolved or forbidden
target occurs.

## Visual acceptance

The existing HTML was inspected through one bounded read-only server rooted
exactly at `_build/nathealth` and bound only to `127.0.0.1:50880`. The exact
H02 route passed at 1440 x 1000, 708 x 1000, and the 720 x 500
200-percent-equivalent viewport.

All 15 tables, all five figures, the three disclosure controls, captions,
axes, labels, legends, symbols, panels, callouts, navigation, wrapping, and
links were inspected. There was no page overflow, clipped figure, overlapping
content, or browser warning or error. The five stored PNG sources also passed
at intended final size. Independent review of the desktop, narrow,
disclosure, and principal-figure captures agrees with the recorded PASS.

The server was stopped. No listener remained on port 50880 and no process
remained at PID 67689. Previsual and postvisual accepted inventories are
byte-identical across 218 rows. Previsual and postvisual build inventories are
byte-identical across 1,124 rows with zero symlinks.

## Held companion state

The preparation manifest retains exactly four expected current mismatches:
the accepted result HTML, profile, companion QMD, and result QMD. The stale
build-side companion QMD, preparation-test rendered branch, and these four
classifications are deferred to the later H02 companion render. They are not
H02 result defects.

## REPORT-018 transition

The sole cleanup exception is complete. No new cleanup loop may open. The
shared queue now proceeds directly to `supplementary_information.qmd`, then
the H02 companion, then H03 through H11 result and companion pairs in profile
order, `sensitivity_battery.qmd`, and the final integrated corpus audit and
DOC-001 disposition.
