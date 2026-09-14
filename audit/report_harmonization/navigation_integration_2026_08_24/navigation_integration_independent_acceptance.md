# Navigation integration independent acceptance

Date: 2026-08-24

Status: **ACCEPTED**

An independent read-only replay under R 4.6.1 accepts the no-rerender Nature Health navigation integration.

## Reproduced acceptance

- completion record and 208-row completion manifest identities match exactly;
- 208/208 manifest members are exact, unique, and non-circular;
- all 37 historical source hashes are retained and all 37 live HTML hashes match the resealed manifest;
- promotion occurred exactly once for 37 HTML files and three navigation assets;
- the live build contains exactly 1,183 members: 874 files, 309 directories, and zero symlinks;
- fresh DOM checks pass all 37 routes, navigation bars, right-side tables of contents, mobile tables of contents, and preserved previous/next page-navigation elements;
- the corpus contains 572 native gt tables, 160 figures, and 86 preregistration-deviation anchors;
- all 46,385 local references resolve;
- the protected boundary contains exactly the authorized six added and six changed paths, with zero removed paths and all 11 classified live identities exact;
- browser evidence passes 74/74 route-breakpoint rows and 15/15 representative interaction rows;
- loopback port 57322 is closed and has no listener;
- post-audit build, manifest, source, and protected identities remain stable; and
- scoped `git diff --check` passes.

## Promotion-script disposition

The released promotion script remains SHA-256 `d96b8601b3b67fa4ed97c84ebc241e6ffbffd1a118839d2d0353bc5efa405d06`, 8,567 bytes. Its `capture_authoring_boundary()` function contains the intended two-argument `readr::write_csv(drift, file.path(...))` call. The reported malformed three-argument call was absent, so no promotion-script edit was necessary.

## Final accepted endpoints

- Phase 4 corpus manifest: SHA-256 `c42c326230818a93aa89322155b933c2f536f09bd447ab09b72f934fba75e76f`, 37 rows;
- completion record: SHA-256 `59dd0c11a1f9fe0768488f964b306c3bc26c5f6473b75bc3e75861594ea00896`;
- completion manifest: SHA-256 `152b038e69b45dcea300b57ed762f14c7da3402a573712bfc0d1f019c99d5f77`;
- final postflight checks: SHA-256 `05fe7ce77dc3cf1738b54202c70fca4dd18080de9af4995ae7e7e4d80f59a79a`;
- all-route browser QA: SHA-256 `cb94f621b43051005574f231b2b123d9174eb140689e77afd30bfb1eff6262a9`;
- representative browser QA: SHA-256 `1f92b6203333ba5fbeaba6bc52618f28589301f5359efcdb81dfdc9807c98c49`.

No Quarto render, QMD execution, scientific computation, source edit, model or artifact change, manuscript-content edit, commit, push, upload, or publication occurred during promotion or independent acceptance.

The H04, Brown, and H06_daily display requests remain separately queued and are not part of this accepted navigation integration.
