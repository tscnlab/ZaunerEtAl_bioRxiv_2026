# REPORT-018 owner order 70: final manuscript landing-page integration

Date: 2026-09-02

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

Status: `SEALED_FOR_ONE_NO_RENDER_LANDING_PAGE_INTEGRATION`

## Authority and objective

The accepted self-contained Nature Health manuscript HTML is the final
manuscript display authority. The corrected Order 69b DOCX is the final Word
download authority. Navigation Order 67a is the accepted 37-route site-shell
authority. This order authorizes one candidate-first integration of the final
manuscript into the website landing page, one exact DOCX copy needed by the
manuscript download link, one atomic production promotion, and one direct
corpus-manifest reseal.

This is a no-render operation. The result must present the complete accepted
manuscript, figures, native semantic tables, captions, references,
Supplementary Information, and accepted table of contents inside the existing
Nature Health website shell. The existing navbar, search surface, desktop and
mobile table-of-contents behavior, footer, page navigation, responsive shell,
and links to the other 36 reader routes must remain usable. No prior landing-
page manuscript content may remain mixed with the final manuscript.

## Exact accepted inputs

Before creating a candidate or changing a live path, reproduce every row of
the Order 70 dispatch manifest by exact SHA-256 and byte count. In particular,
require:

- final standalone HTML
  `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html`
  at `8fba7308...`, 30,881,505 bytes;
- final corrected DOCX
  `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`
  at `6cd59239...`, 28,792,333 bytes;
- accepted manuscript QMD at `9853f0bd...`, 80,774 bytes;
- Order 68a HTML acceptance and Order 69b Word acceptance, including their
  exact non-circular central manifests;
- Navigation Order 67a independent acceptance and its exact central manifest;
- the accepted 892-member website inventory at `a45ec438...`;
- the 37-row corpus manifest at `5d66d43d...`, 11,479 bytes;
- current landing page `_build/nathealth/index.html` at `600b7a3d...`,
  405,444 bytes;
- the current shared mobile-TOC include at `15396773...`, 1,542 bytes;
- both Nature Health stylesheets at `051d9468...`, 4,548 bytes; and
- the accepted Brown participant-state SVG at `200e85cb...`, 108,600 bytes.

Reproduce the complete accepted build at 892 files, zero symbolic links, and
exact agreement with the accepted website inventory. Require no competing
writer for `_build/nathealth`, `phase4_corpus_manifest.csv`, the manuscript
outputs, the navigation shell, or the Order 70 evidence directory. Unrelated
processes outside this path-conflict predicate must not be interrupted.

Create a fresh isolated candidate root under `/private/tmp` and a fresh owner
evidence directory below
`audit/report_harmonization/nathealth_final_landing_integration_2026_09_02/`.
Stop before any candidate or live write on a mismatch.

## Candidate construction boundary

Construct the landing-page candidate from the accepted current website shell
and the accepted standalone HTML. The task may create one sealed,
deterministic, non-analytical integration and verification program in the new
evidence directory. It may use a tolerant HTML DOM parser. It must not invoke
Quarto, knitr, Pandoc, an R Markdown render, a semantic repair hook, a report
helper, or scientific code.

The transformation must:

1. retain the accepted site navbar, search, footer, route navigation, shared
   site assets, and Order 67a desktop and mobile TOC behavior;
2. replace the landing-page manuscript content and page-local TOC with the
   accepted standalone manuscript content and TOC;
3. carry only the inline stylesheet and script resources from the standalone
   document that are necessary for exact manuscript layout or interaction,
   while preventing duplicate runtime initialization and duplicate document
   IDs;
4. preserve manuscript-visible text, 28 authors, section order, captions,
   footnotes, bibliography, 19 native semantic tables, 20 accepted figure
   endpoints, all table-header relationships, all manuscript fragment links,
   and all embedded media;
5. preserve the accepted SVG representation of the Brown participant-state
   figure. A PNG, JPEG, canvas, screenshot, or other raster replacement is
   forbidden;
6. preserve the exact accepted manuscript download label and make its sole
   local document target resolve to the exact final corrected DOCX;
7. create no external manuscript resource file other than the exact byte copy
   `_build/nathealth/ZaunerEtAl2026_NatHealth_phase3_brown.docx`; and
8. change no accepted scientific or manuscript content and perform no
   scientific calculation.

The expected candidate build has 893 regular files and zero symbolic links.
Its only differences from the 892-member accepted build are the replacement
landing-page HTML and the one exact DOCX addition. The other 891 accepted
build members, including the other 36 HTML routes, must be byte-identical.

## Static and DOM acceptance gates

Before browser QA, verify all 37 HTML routes in the isolated candidate. Require:

- one document main element, one canonical desktop TOC, and one Order 67a
  mobile-TOC script per route;
- no duplicate document IDs and complete resolution of every IDREF,
  table-header token, local link, and required fragment;
- byte-identical other 36 HTML routes, unchanged previous and next route
  navigation there, and unchanged endpoint order there;
- on the candidate landing page, exact semantic preservation of all 28
  authors, 19 native tables, 20 accepted figure endpoints, 2,762 resolving
  table-header tokens, and 124 resolving manuscript internal fragments;
- no broken data URI, missing image, raster substitution for the accepted SVG,
  local source path, mixed legacy landing-page section, or duplicate runtime;
- the exact corrected DOCX at the resolved download target; and
- all 893 candidate members live-exact in a non-circular inventory.

Record an element-level manuscript preservation ledger, a 37-route DOM and
local-reference result table, a one-row landing-page transition, a one-row
DOCX addition, and a protected 36-route hash comparison.

## Candidate browser QA

Serve only the isolated candidate on an unused high port bound to
`127.0.0.1`. Exercise all 37 routes at 708 by 1,000 and 390 by 844 pixels.
On every route, open **On this page**, require all cloned links to be visible
and keyboard-focusable, follow the first link, confirm its target, reopen the
control, and verify cloned link order against the desktop TOC. Reject page
overflow, clipping, overlap, missing content, broken interaction, bad local
reference, or page-attributable console warning or error.

Inspect the candidate landing page completely at 1,440 by 1,000, 708 by
1,000, and 390 by 844 pixels. Cover the title and author block, all main
figures and tables, all Supplementary Information displays, references,
captions, the Table 3 distribution plots, the accepted Brown SVG display, the
two-page Supplementary Figure S8 content as represented in HTML, the
Supplementary Figure S12 display without the removed MDER legend, desktop and
mobile TOCs, navbar, search, footer, route navigation, and DOCX download.
Require all content legible and complete with no horizontal page overflow.

Save bounded screenshots that cover the landing-page top, representative
main displays, Table 3, accepted Brown SVG display, Supplementary Figures S8
and S12, the ending references and supplementary tables, and desktop and
mobile navigation states. Stop the candidate server and prove its listener
absent.

## One-time promotion and corpus reseal

Only after every candidate gate passes, create a presealed promotion manifest
and recoverable backup outside the repository. Promote exactly once:

1. the candidate landing page to `_build/nathealth/index.html`; and
2. the exact corrected DOCX copy to
   `_build/nathealth/ZaunerEtAl2026_NatHealth_phase3_brown.docx`.

If either write or its immediate verification fails, restore the landing-page
preimage, remove only the newly added DOCX, and stop. No partial production
state may remain.

After successful promotion, require 893 regular build files, zero symbolic
links, exact candidate-to-production identity, byte-identical other 36 HTML
routes, and byte-identical other 891 accepted build members. The standalone
HTML, corrected canonical DOCX, QMD, `index.qmd`, profile, shared include,
stylesheets, scientific artifacts, package state, lockfiles, and all source
files remain unchanged.

Then update only the landing-page `html_sha256` in the existing 37-row
`audit/report_harmonization/phase4_corpus_manifest.csv`. Preserve all 37
historical source paths and source hashes and every other cell in meaning.
Verify all 37 registered HTML hashes against production. The manifest must be
unique, non-circular, and must not claim that the unchanged `index.qmd`
rendered the no-render landing-page integration.

## Production verification and return

Repeat the full 37-route DOM, local-reference, navigation, TOC, console, and
708/390 browser contract against production. Repeat the complete landing-page
1,440/708/390 inspection and DOCX download check. Confirm that no service
worker, cache, stale tab, or earlier candidate supplied the production
result. Stop the production server and prove its listener absent.

On complete PASS, write one completion record and one unique, non-circular
owner evidence manifest that excludes itself. Return:

1. exact identities of the integration program and its seal;
2. candidate and production landing-page identities;
3. copied DOCX identity and resolved download evidence;
4. 893-member candidate and production inventories;
5. 36-route protection proof and the 37-route DOM/reference results;
6. manuscript preservation, SVG, table-header, figure, table, and fragment
   results;
7. candidate and production browser evidence and screenshots;
8. promotion, backup, rollback, cache, and server-lifecycle evidence;
9. resealed corpus-manifest identity and 37 of 37 live-hash proof; and
10. completion-record and non-circular evidence-manifest identities.

Stop and seal once on any new defect. Do not patch, retry, rerender, or widen
scope inside this order.

## Prohibitions

Do not edit or execute any QMD. Do not run Quarto, knitr, Pandoc, a report
helper, semantic repair hook, analytical script, model, or scientific test.
Do not edit manuscript text, tables, figures, captions, numerical values,
citations, accepted SVG, canonical HTML, canonical DOCX, navigation include,
stylesheets, profile, package state, lockfiles, handoffs, tests, or other 36
site routes. Do not render the manuscript, a hypothesis page, a supplementary
document, the root website, or the full project. Do not commit, push, upload,
deploy, delete historical evidence, or alter an analysis cache.
