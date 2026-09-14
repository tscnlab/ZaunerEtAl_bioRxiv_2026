# REPORT-018 owner order 67a: mobile TOC clone-state repair and H06 completion

Date: 2026-09-02

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

Status: `SEALED_FOR_ONE_NO_RENDER_SHARED_SHELL_TRANSFORMATION`

## Authority and accepted disposition

Order 67 is independently accepted at its candidate-only fail-closed stop.
Changing the external stylesheet alone cannot repair the newly rendered H06
page because H06 embeds its profile CSS. A complete R 4.6.1 audit also finds
that 31 of the 37 accepted routes carry at least one Bootstrap `collapse`
class inside their desktop table of contents, with 115 collapsed lists in
total. Ten routes place the class on the root list and hide the entire mobile
clone.

The correct shared-shell repair is to remove Bootstrap presentation state only
from the cloned mobile list. The desktop TOC remains unchanged. This order
authorizes one candidate-first transformation, one atomic promotion of the
shared include and its 37 embedded HTML copies, one direct HTML-hash-only
corpus-manifest reseal, complete responsive verification, and completion of
the held H06 result QA. It authorizes no render and no substantive page edit.

## Exact preflight

Before creating a new candidate or changing any live path, the owner must:

1. reproduce every row of the Order 67a dispatch manifest by exact SHA-256
   and byte count;
2. reproduce the 19-row Order 67 independent-acceptance manifest at SHA-256
   `d46ee325d53d52075dfda69fd1de9465771bd1a033d1429f280f14aeeee4cc97`;
3. run
   `scripts/report_harmonization/check_report018_navigation_order67_stop_and_js_scope.R`
   once under R 4.6.1 and require its exact PASS contract:
   43 of 43 stopped members, 892 of 892 build files, 37 of 37 routes,
   31 collapse-bearing routes, 10 root-hidden routes, 115 collapsed lists,
   38 of 38 exact reversals, include postimage prefix `15396773`, and corpus
   postimage prefix `5d66d43d`;
4. require the Order 67 owner record `7fbf139a...`, 43-row seal `e5bd594c...`,
   candidate observation `32a6d3d3...`, failure screenshot `2e44f4e1...`, and
   server lifecycle evidence exact;
5. require the current shared include
   `_includes/nathealth-mobile-toc.html` at SHA-256 `926a5fc0...`, 1,388
   bytes;
6. require all 37 live HTML files and every other build member to reproduce
   the 892-row Order 66b build baseline at SHA-256 `8d00db3d...`, with zero
   symbolic links;
7. require the corpus manifest at SHA-256 `c42c3262...`, 11,479 bytes, and
   preserve all 37 source paths and source hashes as historical substantive
   provenance;
8. require both Nature Health stylesheets at SHA-256 `051d9468...`, 4,548
   bytes, and require the profile, H06 sources, H06 HTML, held preparation
   HTML, scientific seal, report verification, focused test, handoff, and
   lockfile exact;
9. require no competing shared-build writer, navigation promotion, Quarto,
   Pandoc, semantic-hook, or manuscript-render process; unrelated R and
   application processes are outside this predicate and must not be
   interrupted; and
10. preserve the complete Order 67 candidate and stopped evidence unchanged,
    create one fresh candidate root under `/private/tmp`, and create a fresh
    Order 67a evidence subdirectory under
    `audit/report_harmonization/navigation_mobile_toc_collapse_repair_2026_09_02/`.

Stop before any candidate or live write on any mismatch.

## Exact shared-script postimage

In `_includes/nathealth-mobile-toc.html`, immediately after
`const list = sourceList.cloneNode(true);`, add exactly:

```js
    list.classList.remove("collapse");
    list.querySelectorAll(".collapse").forEach((element) => {
      element.classList.remove("collapse");
    });
```

The exact prospective include is SHA-256
`153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980`,
1,542 bytes. Prove exact one-hunk reversal to `926a5fc0...`, 1,388 bytes.

This operation removes `collapse` only from the detached clone and its cloned
descendants. It must not change the source desktop TOC, the `show` state of any
source element, link targets, event handling, disclosure behavior, or any
other JavaScript.

## Deterministic HTML transformation

The current inner script body is byte-identical across all 37 accepted HTML
routes. In the candidate, replace that exact body once in every HTML file with
the postimage body from the accepted include. Each HTML must grow by exactly
154 bytes. Require:

- exactly one preimage occurrence and one postimage occurrence per route;
- exact reverse substitution for every route;
- 37 unique deterministic postimage hashes matching the central checker;
- no byte change outside the one script body;
- unchanged visible text, element and endpoint order, headings, tables,
  figures, captions, alternate text, IDs, header relationships, links,
  navigation blocks, metadata, styles, and scientific content; and
- exact composed semantic reversal for H06: reverse the shell patch and the
  accepted 424-row semantic ledger to recover the accepted raw render, then
  reapply both transformations to recover the candidate byte-for-byte.

One task-owned R 4.6.1 transformation and verification script may be created
inside the new evidence directory. It may read the accepted build, write only
the isolated candidate before promotion, produce exact transition tables, and
perform the one atomic promotion after all gates pass. It must be sealed before
execution and may not calculate or validate any scientific result.

## Candidate validation

The isolated candidate must retain 892 files and zero symbolic links. Its
exact delta from the accepted build is the 37 HTML routes and no other build
member. The shared include candidate is held separately and must have the
exact `15396773...` identity. Both stylesheets remain at `051d9468...`.

Before browser QA, run complete static and DOM checks across all 37 routes:

- exactly one desktop `nav#TOC`, one mobile-TOC script, and one main content
  element per route;
- no duplicate document IDs;
- every pre-existing IDREF and table-header relationship still resolves;
- all local links and required fragments resolve;
- all accepted table and figure endpoints remain exactly once and in the same
  order;
- previous and next navigation blocks remain byte-identical; and
- page-visible text and non-script DOM remain unchanged.

Serve only the candidate build on an unused high port bound to `127.0.0.1`.
At both 708 by 1,000 and 390 by 844 pixels, inspect all 37 routes. On each
route:

1. open **On this page**;
2. require every cloned link, including nested links, to be visible and
   effectively keyboard-focusable;
3. follow the first link and require its fragment to exist and the disclosure
   to close;
4. reopen the disclosure and verify the link order matches the desktop TOC;
5. reject horizontal page overflow, clipping, overlap, missing content,
   broken interaction, or page-attributable console warning or error.

Also inspect index, H06, and H09 at 1,440 by 1,000 pixels. Require the mobile
control hidden, the desktop right-hand TOC usable, and the accepted navigation
shell unchanged. Stop the candidate server and prove its listener absent.

## One-time atomic promotion

Only after every candidate gate passes, promote exactly:

1. `_includes/nathealth-mobile-toc.html` once; and
2. the 37 candidate HTML files to their exact current build paths once.

Use a presealed exact 38-row promotion manifest and a recoverable byte-exact
backup outside the project. If any write or immediate postflight check fails,
restore all 38 preimages and stop. No partial promoted state may remain.

After successful promotion, require the build to retain 892 files and zero
symbolic links. Its exact delta is 37 HTML files, each with only the authorized
154-byte script transition. The other 855 build files are byte-identical.
Outside the build, the only pre-reseal project change is the one shared
include. The source and built stylesheets remain unchanged.

## Direct corpus-manifest reseal

After promotion passes its immediate checks, update only the `html_exists`
and `html_sha256` values in the 37-row
`audit/report_harmonization/phase4_corpus_manifest.csv` so every HTML row is
live-exact. Preserve every other cell byte-for-byte in meaning, including all
37 historical source paths and source hashes. The exact resealed manifest is
SHA-256
`5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b`,
11,479 bytes.

Write a separate 37-row transition table recording each preimage and
postimage HTML hash and byte count. Record the three accepted pre-existing
HTML transitions for H01 result, H01 preparation, and H06 result separately
from the 37 shell transitions. Do not imply that a changed live authoring QMD
produced any accepted HTML, and do not update a source hash.

## Production QA and H06 completion

Repeat the full 37-route 708/390 browser contract against production, plus the
index, H06, and H09 desktop checks. For H06 also complete every deferred Order
66b check at 1,440 by 1,000, 708 by 1,000, 720 by 500, and 642-pixel figure
width:

- 14 tables and six figures complete and usable;
- employment-eligibility sensitivity section complete;
- disclosures, site-table scroller, desktop and mobile TOCs, primary
  navigation, reciprocal preparation link, three source-data links, and
  DEV-015, DEV-030, DEV-031, and DEV-032 links correct;
- figures complete, legible, and unclipped at the accepted 170-mm width;
- result, held preparation, and source-data routes return HTTP 200; and
- no page overflow, clipping, overlap, missing content, unresolved link,
  broken interaction, or page-attributable console warning or error.

Save bounded route results, visual observations, screenshots, link and console
checks, viewport evidence, exact DOM/static results, promotion and manifest
records, and server lifecycle evidence. Close or reset the QA surface, stop
the server, prove its listener absent, and rehash the complete build and
protected boundary.

## Final seal and stop rule

On complete PASS, write one completion record and one unique, non-circular
evidence manifest. Include the two orders and dispatches, both independent
acceptances, central checker, implementation, include and 37 HTML transitions,
candidate and production inventories, backups, corpus reseal, browser and H06
QA, screenshots, link and console results, lifecycle proof, and final hashes.
Exclude the final manifest itself.

Return exact SHA-256 and byte counts for the include, corpus manifest, H06
HTML, completion record, final evidence manifest, 37-route transition table,
and browser QA. The Coordinator will independently accept the shared shell and
close H06 before any manuscript or later shared-build render is released.

Stop and seal once on any genuinely new defect. Do not patch, retry, rerender,
or widen scope.

## Prohibitions

Do not run Quarto, knitr, Pandoc, a semantic hook, report helper, analytical
script, or broad manifest builder. Do not edit QMDs, page-visible HTML,
stylesheets, profiles, tests, scientific data or artifacts, package libraries,
lockfiles, handoffs, manuscript sources, search or sitemap assets, or ledgers.
Do not render any target, commit, push, upload, delete historical evidence, or
alter a cache.
