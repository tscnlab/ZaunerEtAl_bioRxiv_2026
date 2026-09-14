# Order72k: exact S2 accessibility-aware guard proposal

Status: TEMP-ONLY PROPOSAL FOR CENTRAL REVIEW. No owner edit, capture slot,
dispatch, browser, server, render or visual acceptance is authorized here.

## Exact prospective transition

Only the current Writer helper would change after a separate sealed release:

- Preimage SHA256: 7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a, 21,562 bytes.
- Prospective SHA256: ecf7525cb5a89438b43588c8ac2acd9ed8e8bcb568b3fc78676ba349792871ec, 42,404 bytes.
- File: capture_word_tables.mjs in this temporary directory.
- Exact forward and reverse changes: forward.diff and reverse.diff.
- Zero-fuzz application of reverse.diff reproduced the exact 21,562-byte preimage.

Neither CSS file changes. Both remain
03d9ff7f9cbe1d258d335f262b948f32f6b8e59dba46dbe9cf336c9d6708a4e9,
2,493 bytes. S2 stays 1,490 pixels total, Unit80, Scaling100, all other widths
unchanged, viewport3000/device-scale2, all 14 columns and the same 7/5/5 metric
partitions. No font, padding, miniplot, text, data or page-size change is made.

## Guard behavior

The helper contains an immutable 17-record contract derived in R from the
three independently reconciled source representations. Each record pins the
body-row/column14 location, exact description and inline style, image payload
SHA256, absent alt attribute and original aria-hidden image attribute.
Runtime source descriptors must reproduce those records before cloning.

Only a direct, single-text-node span associated with the sole sibling image
in its exact table cell can qualify. Source and capture checks additionally
require the expected computed absolute positioning, 1px dimensions, hidden
overflow, zero clip rectangle, inset clip path and nowrap semantics. A missing,
extra, moved, nested, restyled or re-associated span fails closed.

The generic overflow-clearing loop skips only those already validated span
element identities, preserving the original hidden inline style. It behaves
as before for every other element. After each vertical partition is laid out,
the exact subset is revalidated at the correct original row offset: 7, 5, 5.

The visible-text containment walker skips only text directly belonging to
those revalidated single-text-node spans. It still traverses all thead/tbody/
tfoot th/td cells and checks all other nonempty text on left, right, top and
bottom using the unchanged 0.5px tolerance. The distribution column is not
exempt. Unit, Scaling, visible distribution text, headers and notes retain
their containment gate. Original image containment/aspect-ratio checks and
the exact body-cell comparison remain mandatory before each PNG.

Each part's verification gains screenReaderDescriptions proof metadata with
the exact text/style/location/image hash and explicit source/style checks.
The existing key/files/path/bodyCells/other verification fields are retained.
No accessibility node or payload is removed, shortened or exposed.

## Completed static evidence

Node syntax passed. The extracted pure predicates, actual production
overflow-clearing block and synthetic element fixtures passed 404 checks.
They cover all 17 source records, all 7/5/5 partitions, altered text/style/
location/image association/count/nesting, changed computed hidden semantics,
and visible text overflowing each edge in Unit, Scaling, Distribution,
headers and notes. Repeated browser-callback predicates are byte-equivalent
after indentation normalization.

R supplied exact source descriptors and payload strings. Computed-style test
values are explicitly synthetic, not observed browser measurements. Therefore
these tests cannot establish actual layout, image readability or Word output.
No browser was launched. The full prospective helper was never executed;
only node --check and the extracted-function static test ran.

The final R verification reproduced all 335 stopped owner members and all
2,309 prior preservation rows with only the three already authorized exact
preimage aliases. All live owner files remain unchanged. No source or
scientific result was modified or recalculated. See verification_session.txt,
proposal_identities.csv, owner_335_unchanged.csv, reverse_proof_log.txt,
node_syntax.txt and static_test_results.json.

The reverse-proof verifier is intentionally single-use in this directory.
For independent replay, apply reverse.diff to a fresh temporary copy of the
prospective helper with zero fuzz, then compare against the pinned preimage.

## Complete bounded downstream request for central decision

If centrally accepted, a separate sealed release would need to authorize:

1. Preserve a new exact helper7f5cdeb3 preimage, then apply only this prospective
   helper. Preserve both CSS files and all earlier evidence. Historical pins
   must resolve by exact path AND expected version: the stopped335 helper maps
   to the new retained7f5cdeb3 copy, while older8dd21ba1 helper references keep
   their existing exact earlier preimage. No other historical exception.
2. One explicitly additional S2-only capture into a fresh attempt5 destination,
   not an implicit retry or restored allowance. Use the same immutable12-file
   preview root, same Node/Playwright/Chrome, task TMPDIR and only-s2 route.
   Obtain actual narrow tool permissions. A fresh exclusive visual lease and
   restart-only server receipt are required. No separate browser probe.
3. Require all new source/hidden-span and all existing visible-text/image gates
   before PNG creation. A failure stops without tuning or another attempt.
   Preserve and compare 244 exact cells and 17 payloads, all 14 columns, three
   complete headers and final notes in R. Inspect all three parts at original
   size and unchanged intended Word size, maximum15.55 by8.90 inches with aspect
   ratio retained in the existing A3 landscape section. A static test is not
   a visual acceptance substitute.
4. Teardown the exact task server/context and verify absence. Only on actual
   S2 PASS, append an exact new manifest/path mapping for assembly. Reuse the
   four accepted S5/S6/S10 table PNG parts unchanged. Do not rerun or overwrite
   historical correction manifests that still record attempt2/width1400.
5. Use only the existing unused consolidated correction allowance: selection
   HTML, main HTML and main DOCX once each. Assembly/SVG embedding and office
   QA retain their original unconsumed two-run limits. No additional budget is
   implied here. Native Word still requires the user's unlock; no automatic
   unlock or substitute native acceptance.

Table3, accepted SVGs, historical Brown FigureS5 and its separate scientific
hold, optional H11 exclusion, standalone editable-table exports and all
canonical boundaries remain unchanged. Do not wake Writer from this proposal.
