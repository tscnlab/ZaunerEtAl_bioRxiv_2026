# REPORT-017 H01 order 32h result-page independent acceptance

Date: 2026-08-20

## Disposition

The H01 result source, targeted render, native-`gt` semantic repair, links,
scientific protections, and final-size output checks are independently
accepted. `H01-REPORT017-32H-VIS-001` is reclassified as a visual-QA harness
false positive, not a reader-page defect. No source correction or repeat
result render is required.

The failing coordinate check measured descendants of the representative
diagnostic tabset while its enclosing HTML disclosure was closed. Hidden
descendants can retain geometric boxes, but they are intentionally absent from
the interactive layout until the reader opens the disclosure. In that closed
state, the following section correctly occupies the released space.

## Independent evidence

The owner stop package reproduces at these identities:

- stopped-state record:
  `69ca9386bb8f8060723e6eae689191f5c8290bdbbdc3357f5e2dd08727c03b20`;
- visual-QA record:
  `2744e1c4151a4c9ddb7b2d91d0d865ee0cea1c035e79b2cdb2157f910e6f9467`;
- 99-row owner manifest:
  `0d4a21adb5afa9c3fafc5a941d6f941f2b212e761f40dedaea12390ec9701ba2`;
- H01 result source:
  `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`;
- preparation/provenance companion source:
  `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`;
- Nature Health profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- fresh H01 result HTML:
  `df78ac3c2ed91515058b6af38e01b85b4baae74118699c008a29ba4dacf4d007`;
- frozen companion HTML:
  `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`.

R 4.6.1 independently verified all 97 durable or currently live rows of the
owner manifest by path, SHA-256, and byte count. The two remaining rows point
to the owner-retained `/private/tmp` semantic ledger and summary. Those
temporary files are no longer present after the environment transition, but
their execution-time identities remain pinned in the durable owner manifest
and stopped-state record.

## Reader-interaction replay

A temporary read-only static server served only `_build/nathealth`, bound to
`127.0.0.1:56676`. A preflight found no symlinks under that document root.
The exact route was
`http://127.0.0.1:56676/notebooks/hypotheses/H01.html`.

The diagnostic disclosure was opened by clicking its visible summary, **Show
representative model-check details**, before testing its tabs. At 1440 x 1000:

- all four diagnostic tabs could be selected in turn;
- each selected tab had `aria-selected="true"` and a visible active panel;
- `document.elementFromPoint()` at each tab centre returned that same tab;
- every diagnostic image was complete at its preserved natural size of
  1800 x 810 pixels;
- the disclosure and Model checks section ended at the same position;
- Sensitivity analyses began 34 pixels below them; and
- overlap was zero.

The same four-tab interaction passed at 708 x 1000. The tab navigation had a
client width and scroll width of 642 pixels, so it introduced no hidden
horizontal overflow. Each selected panel and image was visible, and the
following section again began 34 pixels below the open disclosure.

The temporary viewport override was reset, the browser tab was closed, the
server was stopped, and `lsof` confirmed that no listener remained on port
56676. Post-QA hashes of both QMDs, the profile, result HTML, and companion HTML
remained exact.

## Accepted result-page boundary

The complete owner evidence remains controlling for the other order 32h
checks: exactly 36 native `gt` tables, ten intended figures, 40 links to 36
unique deviation anchors, semantic-header repair, unique document IDs,
resolved links, country-coded site names in H01, no error or warning nodes,
1,689 protected identities, and the bounded five-output build delta.

The H01 result page is accepted. Principal-output appearance remains
provisional for final author approval. The H01 preparation/provenance companion
has not been freshly rendered under REPORT-017 and remains the next serial H01
target pending coordinator release.
