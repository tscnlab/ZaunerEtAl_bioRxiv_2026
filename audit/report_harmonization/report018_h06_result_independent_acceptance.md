# REPORT-018 H06 hourly result independent acceptance

Date: 2026-08-21  
Disposition: **ACCEPTED**  
Next eligible serial target: `audit/hypotheses/H06/H06_analysis_preparation.qmd`

## Accepted scope

REPORT-018 order 47c is independently accepted for the H06 hourly result
page. The sole authorized source change added Quarto table endpoints and
captions to the two existing native formula tables. Their executable R bodies,
formulas, values, roles, source notes, and positions remain unchanged. The
result source is now
`d65c197cb37db32101d8a43fcdc80198ab599a95cb73259abd187c9b2b58d350`
at 60,791 bytes.

The sole target render completed all 41 cells under R 4.6.1 and Quarto 1.9.37
through the normal project profile. The configured post-render hook returned
`REPAIRED`. The accepted HTML is
`8b5f1b0ada997290ec5324de35e0c874fd25e2e9ef052281acaab07d0a3dccaa`
at 4,874,263 bytes.

No H06 companion, H06 daily, later target, or full project render occurred.
No model, inference, source-data transformation, scientific artifact
regeneration, package, lockfile, profile, ledger, commit, push, upload, or
publication action occurred.

## Independent replay

An independent R 4.6.1 replay using xml2 1.6.0, gt 1.3.0, digest 0.6.39,
and jsonlite verified:

1. the non-circular owner manifest is exact for all 40 unique rows;
2. the result source, H06 contract, held companion source and HTML, profile,
   semantic wrapper and engine, and lockfile reproduce their accepted pins;
3. the final page contains exactly 13 native gt tables and six intended figure
   endpoints;
4. all table endpoints are unique, every table has a nonempty Quarto-owned
   caption, and every figure has nonempty alt text;
5. the two added captions are exactly `Exploratory two-part formulas.` and
   `Exact evaluated Wilkinson formulas.`;
6. the semantic ledger contains 64 ID substitutions and 340 `headers`
   substitutions, for 404 total mutations across 13 tables;
7. reversing the ledger reconstructs pre-hook HTML
   `c5a0dfe1d5076cc4c0a7cdaf926eff3811dab0f9bece5f5a2b34af9730e73371`
   exactly, and reapplying it reconstructs the accepted final HTML exactly;
8. document IDs are unique and every explicit table `headers` token resolves
   exactly once within its own table to the intended `th` element;
9. no embedded error, warning, or stderr node is present;
10. all four declared deviation anchors, active H06 navigation, and all nine
    country-coded study sites are present; and
11. the accepted visual evidence contains 13 tables and six figures at both
    desktop and narrow viewports, with no page overflow at 1440 by 1000,
    708 by 1000, or the 720 by 500 200-percent-equivalent view.

Independent inspection of the retained screenshots confirms that the
principal figure and table are readable at desktop size, the dense site table
remains readable at narrow width, both added formula tables wrap within their
cells, and the narrow model-check table uses the permitted contained horizontal
scroller. The six stored PNGs passed the controlling 170-mm exported-output
inspection for titles, axes, legends, labels, symbols, panels, and disclosures.

## Preserved boundaries

All 90 protected order-47c paths are exact after rendering and QA. The held
companion remains:

- source
  `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`;
- HTML
  `222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`.

The 836-member build inventory has no added or removed member. Content changes
are limited to the accepted H06 result HTML plus normal search and sitemap
updates; the shared bootstrap CSS was byte-identical with only an mtime touch.
The H06 target-local Quarto freeze, index, and cross-reference records changed
as expected.

The secure loopback server was rooted exactly at `_build/nathealth`, bound only
to `127.0.0.1:54873`, and used only for the H06 route. It was stopped after QA;
`lsof` found no remaining listener, browser logs were empty, and the viewport
override was reset.

The same three previously sealed Pandoc resource-fetch warnings occurred and
no additional warning appeared. Both referenced companion targets resolve in
the retained site, and none of the terminal warnings is embedded in the page.
They remain deferred under REPORT-018 and do not block integration acceptance.

A temporary read-only checker initially assumed every accepted table required
a source-note block. Four accepted tables intentionally have none. The checker
was corrected to preserve and compare the actual pre-hook source-note
structure and to require the two formula-table notes. The definitive check
passed. This was a verifier assumption, not a page defect, and no source change
or rerender followed.

## Serial disposition

The H06 hourly result is accepted for source, targeted render, native-table
semantics, links, navigation, protected preservation, responsive HTML, and
exported figure appearance. The H06 preparation/provenance companion is the
sole next eligible serial target. H06 daily and all later targets remain held
until the companion is independently accepted.
