# Order72e SVG preview: mobile stop and checker disposition

Date: 2026-09-11

The first SVG preview candidate remains SHA-256
7688f8ea58e0045fca25c6de971e418b7c6c873dc83f75ed34d942fdcb1c36b4,
29,370,696 bytes. The selection source remains
9acec033d0c24cbb0ee7649c38f55d5cea90052e11b6be7fc5f9e7310890d8f3,
49,865 bytes. The canonical old HTML remains
82100e0d3990dec39f61e94970e7a434b02cf94a6d25819ede1be4d24f4130a6.

The owner records one visible mobile defect: the Coordination status table
extends from x=25.50 to 382.86 at a 390-pixel CSS review width, with root client
width 375 and scroll width 383. The resulting 8-pixel page overflow is outside
the 20 SVGs and scientific table scrollers. Desktop 1440 and tablet 708 pass.
The coordinator accepts this as a bounded layout defect requiring one existing
accessible local-table-scroll wrapper. All 14 body rows and 45 table cells
remain unchanged. No CSS or scientific display repair is justified.

## Explicit checker history

The 91-member Order72f release does not remain wholly live-exact: its pinned
checker changed from 0e97b32919e8ba1c52a3d67e56a8d01573c3aa853f3e9c5826ead47dfb54c375
(32,612 bytes) to
ef2fd6bf1bd3a3c0a70d8771a8f4da4ea1b96ea86d89e015ddd5cf14337702e9
(34,346 bytes). The owner documents that this happened during post-render
diagnosis. It was not separately represented in the previous release.
Do not rewrite that history or label the old 91-row seal live-exact.

The coordinator has independently reversed exactly the added descendant-text,
historical-rendered-cell and two-caption smart-typography classifications.
The reconstructed earlier file reproduces the exact pinned SHA and size and is
now durably retained in this package.

Independent R 4.6.1 verification confirms every one of the 19 retained tables
has the same complete ordered normalized rendered cell vector as the frozen
historical preview. Ordered non-empty source text tokens also reconcile for
all 19 tables. The differing empty-cell placement and source whitespace are
rendering-shape issues, not changed data. The caption normalization concerns
only NBSP and straight/curly quotation marks in the two approved inserted
captions; source strings and scientific values remain unchanged.

The live checker transition is therefore accepted now as an evidence-only
classification, with both versions preserved. Further checks use a new copied
verifier under Order72h. Neither historical checker is edited again.

## Prospective recovery proof

The wrapper-only source candidate is SHA-256
197e571f3aaa2be34747ee742a20018f98d541eed87851250b4f3eda131c72a9,
49,967 bytes. Removing exactly its opening and closing wrapper reproduces the
entire 49,865-byte preimage exactly. The table preimage/postimage text, source
preimage, prospective source and reversal script are retained here.

The copied verifier is SHA-256
ae2e8a3a4a43c99dc7e0bccf49b812d26cfd695d775e6da001822dbb97983cd7,
38,251 bytes. It retains all current source, SVG, table, caption, link, privacy
and semantic gates; adds exact source/reverse and accessible-wrapper checks;
and requires all 22 complete table-cell vectors and visible text to remain
identical to the first SVG candidate.

The complete prospective source/HTML path passes 43/43 under R 4.6.1 against
a temporary, explicitly simulated HTML containing only the equivalent wrapper.
This proves the verifier path, not visual acceptance of a new render. No
project render, canonical source edit, SVG change or canonical HTML promotion
occurred during this independent review.

The stopped preview server was identified as PID7430, serving only the owner's
served directory on 127.0.0.1:8765. It exited before the coordinator's attempted
SIGINT; the command returned no such process, so no coordinator signal was
delivered. A fresh independent lsof probe found no listener. Owner teardown
and visual-stop records remain the detailed lifecycle evidence.

