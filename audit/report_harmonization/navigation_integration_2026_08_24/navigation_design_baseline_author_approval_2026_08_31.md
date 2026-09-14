# Nature Health navigation design baseline author approval

Date: 2026-08-31

Status: **AUTHOR APPROVED AND CONTROLLING FOR `rewrite/NH`**

The author approved the integrated Nature Health website page structure and design as the design baseline for the `rewrite/NH` branch. The shared checkout was independently observed on `rewrite/NH` when this approval was sealed.

## Controlling accepted integration

The controlling implementation remains the independently accepted no-rerender navigation integration recorded in `navigation_integration_independent_acceptance.md`, SHA-256 `a580431b8b806da30876839a688dd49d1a6abcd6e21ce02deddf39bbfe5387f4`.

Its accepted corpus identity remains:

- live 37-row Phase 4 corpus manifest SHA-256 `c42c326230818a93aa89322155b933c2f536f09bd447ab09b72f934fba75e76f`;
- navigation integration completion record SHA-256 `59dd0c11a1f9fe0768488f964b306c3bc26c5f6473b75bc3e75861594ea00896`;
- 208-member completion manifest SHA-256 `152b038e69b45dcea300b57ed762f14c7da3402a573712bfc0d1f019c99d5f77`;
- `_quarto-nathealth.yml` SHA-256 `e54c71794f4f763a8b50417ab83ff3db37bc9af3fef3f4d1910576ab12c61bc7`;
- `styles-nathealth.css` SHA-256 `051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87`;
- `_includes/nathealth-mobile-toc.html` SHA-256 `926a5fc051f032100714ae01b53c5ba2937c91ff2406ab5354484bf8fd7f553d`.

The accepted integration comprises 37 registered reader routes, 572 native gt tables, 160 figures, 86 preregistration-deviation anchors, and 46,385 resolving local references. Browser evidence passed all 74 route-breakpoint checks and all 15 representative interaction checks.

## Required design invariants

Future `rewrite/NH` renders, manuscript work, and website integration must preserve:

1. the manuscript as the direct landing page;
2. the grouped top navigation menus and their section-specific submenus;
3. the consistently titled right-hand `On this page` table of contents on desktop;
4. the accessible collapsed `On this page` table of contents on narrow screens;
5. all 37 registered routes in their accepted order, including adjacent result and provenance pairs;
6. the accepted previous/next page sequence;
7. search and repository actions;
8. the Nature Health profile-specific styling boundary, without changing the base website presentation; and
9. the accepted responsive layout and local-link integrity.

The prior sidebar design is retired for `rewrite/NH` and must not be restored by a later targeted render, manuscript update, profile edit, or integration step.

## Operational boundary

This approval establishes the navigation design baseline. It does not itself authorize a Quarto render, QMD execution, manuscript-content edit, scientific computation, artifact regeneration, publication, commit, push, or upload.

Any future targeted render that changes a reader HTML endpoint must use the accepted Nature Health profile shell and verify that the invariants above remain present after rendering. Any proposed navigation redesign requires a separately bounded change and renewed author-facing review.
