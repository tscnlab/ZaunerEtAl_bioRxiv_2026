# REPORT-018 H03 result independent acceptance

Date: 2026-08-20

Status: **ACCEPTED**

The H03 result page is independently accepted for its targeted render,
semantic table repair, links, navigation, scientific-input preservation, and
visual display. The H03 companion remains the sole next serial target.

## Source and execution identities

The accepted result source is `notebooks/hypotheses/H03.qmd`, SHA-256
`45ea5a009efd3b451c392dfc23bef584c7b16e087bf4093780b051cfde42ae41`.
The held companion source is
`audit/hypotheses/H03/H03_analysis_preparation.qmd`, SHA-256
`59270288388e48ceef880ffa4a2ba0e87b8deeb9a8046b49510c4e525ff8c131`.
The shared profile remains SHA-256
`80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

Order 40 ran exactly one target command through the normal project profile
under R 4.6.1 and Quarto 1.9.37:

```text
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H03-order40-semantics.nvawK2 quarto render notebooks/hypotheses/H03.qmd --profile nathealth
```

The render exited zero. No H03 companion or other target was rendered. No
source, test, manifest, profile, package, lockfile, scientific artifact, model,
estimate, or central scientific record was changed by the owner execution.

The fresh accepted result HTML is
`_build/nathealth/notebooks/hypotheses/H03.html`, SHA-256
`abe4be0b127c66b357eca66ab5e90609e0ac7902ca611c5f0e8a9adf410f2cc1`,
335,521 bytes.

## Independent semantic and structural replay

R 4.6.1 independently loaded the accepted post-render wrapper and repair
engine, inspected the durable HTML as `ALREADY_REPAIRED`, and replayed the
retained semantic ledger in both directions. The 719-row ledger exactly
reconstructed pre-hook HTML SHA-256
`c6916b8a74af00942192f88ad5af53b33bc30f0b2b85fe660032261add90fb07`.
Forward reapplication reproduced the accepted HTML byte-for-byte.

The semantic result contains 14 native gt tables, 98 generated table IDs, 621
`headers` attributes, and 719 substitutions. Independent XML inspection found
208 unique document IDs, 14 table endpoints, eight figure endpoints, and 1,082
header tokens. Every header token resolves exactly once to a `th` in its own
table.

The owner evidence confirms the exact endpoint order, complete captions and
alt text, 11 source-data downloads, eight figure sources, five links to the
unique `dev-013`, `dev-014`, `dev-022`, `dev-023`, and `dev-024` anchors,
active navigation, the resolved Supplementary information target, nine
country-coded sites, and zero embedded error, warning, stderr, or unresolved
cross-reference nodes.

The post-render and post-QA build inventories are byte-identical, with 1,127
entries and zero symlinks. The only content changes from the pre-render build
were the H03 HTML, `search.json`, and `sitemap.xml`. Three additional files had
byte-identical modification-time touches. All 464 protected paths were exact
through rendering. During browser QA, only the two separately coordinator-owned
central ledgers changed; the remaining 462 protected paths stayed exact.

## REPORT-018 deferred serial conditions

Two conditions are accepted as serial-state metadata rather than H03 result
defects:

1. `DEFERRED_HELD_COMPANION`: the result link to
   `../../audit/hypotheses/H03/H03_analysis_preparation.html#sec-h03-prep-participant-random-intercept`
   is exact. The accepted companion source declares that anchor exactly once.
   The held companion HTML remains SHA-256
   `813492b5b1941716c1996f8a0c1b88c658e6eefb52e2569be62744fe965308bf`
   and is intentionally stale until the next serial render. No other internal
   link is unresolved.
2. `DEFERRED_TEST_LITERAL`: the unchanged source-harmonization test retains
   the pre-render H03 HTML hash. Read-only comparison found that result HTML
   identity to be its only mismatched protected-context entry. The accepted
   source-only PASS remains the controlling test evidence. No test edit or
   rerun is required under REPORT-018.

The optional `/favicon.ico` 404 remains a nonblocking site cosmetic observation.

## Independent visual replay

The eight-row independent visual record is
`audit/report_harmonization/report018_h03_result_independent_visual_qa.csv`,
SHA-256
`2a094d14433c92dca4d8933a5074c35df0e2f77abc51173cf88ef4fd18aefa27`.

A separate secure-loopback replay inspected the exact H03 route at 1440 x
1000, 708 x 1000, and the 720 x 500 200-percent-equivalent viewport. Desktop
client and scroll widths were both 1,425 px; narrow widths were both 693 px;
and 200-percent-equivalent widths were both 705 px. The principal table and
figure, all 14 table containers, all eight figure containers, title, Answer in
brief callout, navigation, captions, and responsive wrapping remained readable
and contained.

The independent server was rooted exactly at `_build/nathealth` and bound only
to `127.0.0.1:63044`. The browser console had zero warnings and zero errors.
The tab was closed, the viewport reset, the server stopped normally, and
`lsof` found no listener on the port.

## REPORT-018 transition

H03 result integration is accepted. No language, cosmetic, optional-link, or
historical-test-literal cleanup loop is opened. The H03 preparation and
provenance companion is the sole next serial render target, and its render must
materialize the already accepted participant random-intercept anchor before the
companion can be accepted.
