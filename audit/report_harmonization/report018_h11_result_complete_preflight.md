# REPORT-018 H11 complete result-only preflight

Date: 2026-08-22

Disposition: `PASS_RESULT_ONLY_RELEASE_ELIGIBLE`

## Scope

This is the complete read-only downstream preflight required before any H11
render release. It inspects the accepted result and companion sources, normal
profile, knitr engine, source expressions, endpoint and link inventories,
current and historical manifests, focused tests, scientific assets, build
resources, semantic expectations, expected render deltas, secure-loopback
harness, and current process state. It does not edit H11, execute a QMD, run a
helper or preparation test, invoke Quarto render, or change a build target.

`quarto inspect notebooks/hypotheses/H11.qmd --profile nathealth` confirms
Quarto 1.9.37, the knitr engine, HTML target `H11.html`, and the normal
`nathealth` profile.

## Fixed release pins

- Result QMD: `7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867`, 57,462 bytes.
- Companion QMD: `3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816`, 54,527 bytes.
- Stale result HTML: `c5724711ad1aa94631df0b6186fee92398d414ae02690ade08f320b29d6b6db7`, 289,711 bytes.
- Held companion HTML: `fd6307a6a2e9365f95f18f1fd668165cf833847cab58bac9d3be1e8a9b6dde11`, 775,131 bytes.
- Stage 3 reader test: `088e0a1235d2561515613271e497ae55124a2bbe39f5fa9e2173583df131dea8`.
- REPORT-016 disposition test: `3d945c2b813ffaa2291ddebbe01f1f45c5c4ae7fe10256c9a1c8b15c3b531e7b`.
- Preparation test: `7c565618a4d3ec1c2240419b1daead2189616fce97931dde68e0a9450db8f41f`.
- Preparation helper: `317f31069e6019475023b3097b1d7f1b00435755e0a109e40535fab89b570bf8`.
- Immutable 69-row Stage 3 manifest: `2f55cef62117af71beab6e320fac842489b24be149209ea60a1d54cbd172f645`.
- Held 282-row preparation manifest: `00ce783a5958f6f958db1d2d6d78076760953ad1c51cc18c30abb697557c8e5c`.
- H11 handoff: `5f01ac88745d55d749854b41d22ce3bd0afe43f42dbbaded98da7a61e1b53289`.
- Normal profile: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- Held sensitivity source and HTML: `d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70` and `b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780`.

## Complete transition classification

The immutable Stage 3 manifest has exactly 67 live-exact rows and exactly two
accepted historical-to-current transitions:

1. `audit/decisions/figure_readability_and_layout.md`, from
   `62cedcc013c404a445455cae9beff5ffd21c6a2d82689103a98406e34cceb0b3`
   to `33bac9392c35ed2fb6fd8bef0cf80ba867229e97d31cd1ea28ce625a51c1565b`.
2. `notebooks/hypotheses/H11.qmd`, from
   `e4f13510317e62888f7fd785bacd8bd20ad9f3e90d24fa7bc9dc59e7215ec2e7`
   to `7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867`.

After one successful result render, the only permitted third transition is
`_build/nathealth/notebooks/hypotheses/H11.html`. Its live identity must equal
the semantic summary's accepted post-hook SHA-256. The historical manifest
must remain byte-identical, and any fourth mismatch fails.

The held preparation manifest is 278 of 282 live exact. Its complete current
historical set is the figure-readability decision, result source, companion
source, and normal profile. After the result render, only the result HTML may
join this set. The helper and preparation test remain unexecuted and
byte-identical. The H11 companion is not integrated in this order.

## Complete source, test, and endpoint replay

R 4.6.1 parses 81 result-source expressions. The source contains exactly 15
`tbl-*` endpoints and eight `fig-*` endpoints, with no model fit, prediction,
simulation, bootstrap, or scientific artifact write. It contains 26 local
link occurrences to 23 unique targets. The 12 central deviation-link
occurrences resolve to ten unique registered anchors: DEV-001, DEV-003,
DEV-019, DEV-042, DEV-043, DEV-044, DEV-045, DEV-047, DEV-048, and DEV-057.

The complete transition-aware Stage 3 and REPORT-016 tests both pass through
their final assertions in temporary copies. This classifies the two current
historical identities, the accepted source wording, the exact 12 result and
13 companion central-link occurrences, and the current QMD identities without
modifying either historical test. The rendered fresh page must independently
reproduce the same live contracts.

All 193 H11 scientific asset files are frozen. All 34 current H11 build
resource copies are source-identical. The build root contains 1,180 entries
and zero symlinks. The exact permitted content-changing result-render delta is
the result HTML, `search.json`, and `sitemap.xml`. No result-side build QMD is
expected. Every other build path and all 34 H11 resources must remain exact.

## Semantic and visual acceptance contract

The stale result HTML is evidence only. A fresh accepted endpoint must contain
exactly one `main#quarto-document-content`, 15 native `gt` tables, the eight
source-ordered figures, zero duplicate IDs, scoped and resolving table
`headers` tokens, nonempty captions and alt text, valid local links and
fragments, and no embedded error or unresolved-reference node. The semantic
hook must emit an external summary and reversible ledger whose raw reversal
and reapplication are exact.

If all static gates pass, serve only `_build/nathealth` on one unused high port
bound to `127.0.0.1`, after repeating the zero-symlink preflight. Inspect the
exact route `/notebooks/hypotheses/H11.html` at 1,440 by 1,000, 708 by 1,000,
and 720 by 500 as the 200-percent-equivalent view. Inspect every table and
figure, narrow table scrolling, navigation, disclosures, captions, links,
clipping, overlap, page overflow, and browser console. Inspect each exported
figure at 642 pixels, the exact 170-mm display width, and require essential
text of at least 7 points. Close the QA surface, stop the server, prove no
listener remains, and rehash build, protected, scientific, source, companion,
profile, and sensitivity identities.

## Process and serial boundary

The elevated read-only process inventory found zero H11, Quarto, Pandoc,
semantic-hook, or loopback processes. One LightLogWeb Shiny process and four
PPID-1 LightLogWeb `mirai` daemons are unrelated to this project and are not
render competitors. They were not altered. H10 is closed. H11 result is the
only eligible serial render. H11 companion and the sensitivity battery remain
held.
