# REPORT-018 owner order 70c: landing-page harness cardinality recovery

Date: 2026-09-02

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

Status: `SEALED_FOR_ONE_PRE_TRANSFORM_HARNESS_CONTINUATION`

## Authority and stopped state

Order 70 stopped before candidate transformation because its sealed
integration program incorrectly required the accepted standalone manuscript's
literal `<meta name="author"` token to be globally unique. Independent R
4.6.1 verification accepts the stop: the nine-row owner seal is exact, the
candidate remains an exact 892-file accepted-build copy with zero symbolic
links, the candidate and live landing pages remain at `600b7a3d...`, the
corpus manifest remains at `5d66d43d...`, and the production DOCX is absent.

The accepted manuscript contains exactly 28 ordered author metadata elements.
A complete in-memory prospective replay also found two masked cases of the
same harness-only mismatch. The TOC-actions insertion retains `</nav>`, and
the manuscript-style insertion retains `</head>`, while the general
replacement helper requires its preimage to disappear.

The central prospective checker passes 50 of 50 literal, XPath, and semantic
checks when the three sites below are corrected. This order authorizes only
that consolidated three-site harness repair, one reseal, and one continuation
from the untouched existing candidate copy. Every Order 70, 70a, and 70b
boundary remains controlling.

## Exact preflight

Before editing the harness, reproduce:

- the Order 70 stop acceptance and its non-circular central manifest;
- the owner stop record at `49bd7ef8...`, 1,327 bytes, and its nine-row seal
  at `011ecdd5...`, 1,565 bytes;
- the stopped program at `5c9d894b...`, 52,114 bytes, and its one-row seal at
  `f62d5717...`, 198 bytes;
- the untouched candidate root and exact 892-file inventory at
  `a45ec438...`, 124,510 bytes, with zero symbolic links;
- the unchanged live and candidate landing pages at `600b7a3d...`;
- the unchanged corpus manifest at `5d66d43d...` and absent production DOCX;
  and
- the central preflight program at `0a026156...`, 15,958 bytes, and its
  50-row PASS result at `37413096...`, 3,042 bytes.

Require no competing writer for the candidate, production landing page,
corpus manifest, production DOCX, or Order 70 evidence directory. Stop before
any edit on a mismatch.

## Exact harness repair

Make only these three logical corrections in
`order70_integrate_verify_promote.R`:

1. Replace the manuscript author-metadata call to `find_fixed_once()` with an
   exact expected-cardinality selection. Require exactly 28 occurrences of
   `<meta name="author"`, require every returned position to be positive, and
   use the first occurrence as the metadata-block start. Retain the existing
   later DOM checks requiring exactly 28 candidate and source author metadata
   values and exactly 28 body author paragraphs in exact accepted order and
   content. Missing, added, reordered, changed, or extra-duplicated author
   metadata must fail.
2. Add one fail-closed helper for insertion before a retained boundary. It
   must require exactly one boundary occurrence, require the insertion to be
   absent, insert once immediately before the boundary, require the boundary
   to remain exactly once, require the insertion to occur exactly once, and
   require the result to differ from the input.
3. Use that helper only for the two verified retained-boundary operations:
   insert `toc_actions` immediately before the sole `</nav>` in the new TOC,
   and insert `custom_style` plus its newline immediately before the sole
   `</head>` in the candidate document.

Do not change the behavior or call sites of the general replacement helper.
Do not change any token, selector, expectation, manuscript content,
navigation content, style content, SVG content, path, hash, promotion logic,
or browser criterion.

Require an exact focused diff, R 4.6.1 parse, and byte-exact reverse proof to
the stopped 52,114-byte preimage. Create a new one-row implementation seal
before executing the postimage.

## Mandatory in-memory replay

Before touching the existing candidate copy, run the central preflight checker
once and require all 50 checks to pass. Require exact preservation of:

- 28 ordered author metadata values and 28 body author paragraphs;
- one main element and one canonical TOC;
- 19 native semantic tables and 20 figure endpoints;
- 2,762 resolving table-header tokens and 124 resolving manuscript fragment
  links;
- 74 embedded images and the exact 108,600-byte Brown SVG at `200e85cb...`;
- all manuscript main children byte-for-byte after DOM serialization; and
- all 20 site scripts in exact order and content.

The replay must remain in memory and must not write candidate or production
content. Stop on any failed or newly inconsistent literal or selector.

## One continuation

After all repair and replay gates pass, continue the original Order 70 once
from the existing untouched candidate root. Do not create or copy a second
candidate baseline. Recheck its 892-file exact identity and zero symbolic
links immediately before execution.

The repaired program may then perform the already authorized candidate
transformation, static and DOM validation, browser QA, one-time promotion,
production QA, corpus-manifest reseal, and final completion seal exactly as
specified by Orders 70, 70a, and 70b. It may add only the exact corrected DOCX
and replace only the landing page in the build. The other 891 accepted build
members, including the other 36 HTML routes, remain byte-identical.

At the first genuinely new defect, stop and seal once. Do not patch or retry
again inside Order 70c.

## Return and prohibitions

Return the focused three-site diff, reverse proof, repaired program identity,
new program seal, 50-row replay result, candidate and production results,
promotion and corpus reseal evidence, 37-route static and browser results,
completion record, non-circular completion manifest, and server teardown.

Do not run Quarto, knitr, Pandoc, a QMD, a report helper, scientific code, or
a full-profile render. Do not edit manuscript content, HTML authority, DOCX
authority, SVG, figure, table, caption, stylesheet, shared include, profile,
package state, lockfile, other route, or historical evidence. Do not commit,
push, upload, deploy, or submit.
