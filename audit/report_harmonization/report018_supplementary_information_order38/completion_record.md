# REPORT-018 order 38 Supplementary information completion

Date: 2026-08-20

Disposition: **OWNER PASS, AWAITING INDEPENDENT ACCEPTANCE**

## Execution boundary

The unchanged `supplementary_information.qmd` was rendered exactly once with:

```text
quarto render supplementary_information.qmd --profile nathealth
```

Quarto 1.9.37 completed at 2026-08-20 12:07:18 CEST with exit status 0.
The source is static, so Pandoc ran without knitr or scientific computation.
The configured semantic hook reported `NO_GT`, with zero tables and zero
attribute substitutions. No second Quarto command was run.

The target is `_build/nathealth/supplementary_information.html`, SHA-256
`a0b5d097b12ee4a7cbfbcd5cb4740f1eac81bf1c9dba1e4e00a9d5644bfec4eb`,
49,234 bytes.

## Source, corpus, and HTML verification

- The source remains
  `8d013e4d37ca5ff438988e82907a26d65b98a9a47cc2d62ec3ddcd0e2b3862fa`.
- The Nature Health profile remains
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- The base profile, bibliography, CSL, CSS, semantic wrapper, semantic engine,
  corpus builder, navigation test, and reader-link test retain every released
  identity.
- The rebuilt 37-row corpus manifest is
  `bd3e06250bd981ed6ebadc3708f7dcc393c7373e738e0994e5857411eeb3fc6f`.
  All 37 source identities and all 37 expected HTML targets pass.
- Navigation, reader links, 86 deviation anchors, and country-coded study-site
  contracts pass under R 4.6.1.
- The page has the exact title and all 20 outline headings, active Supplementary
  navigation, zero native tables, zero figures, and zero embedded error,
  warning, or stderr nodes.
- All retained internal links resolve. Reader actions have nonempty visible or
  accessible labels. The 11 empty-text links are generated heading anchors and
  each has the accessible label `Anchor`.

The missing Supplementary target that controlled DOC-001 now exists and the
retained-site link audit passes. The technical missing-target condition is
resolved. Central DOC-001 closure remains subject only to independent order-38
acceptance and requires no source expansion in this order.

## Build reconciliation

The pre-render inventory contained 1,124 entries: 822 files, 302 directories,
and zero symlinks. The post-render inventory contains 1,125 entries: 823 files,
302 directories, and zero symlinks.

Content changes are confined to the new target HTML, `search.json`, and
`sitemap.xml`. A Bootstrap CSS file was touched but remained byte-identical;
root and Bootstrap directory mtimes changed. `build_delta.csv` classifies all
six inventory differences. There is no unclassified content change.

The complete post-render and post-QA build inventories are byte-identical at
SHA-256
`c2ab9a69dca6f4ecf890312f0ea65fe788ab07e834dbac2ce1f4fff3a27c8c1c`.
The 17-path protected pin inventories are byte-identical before rendering,
after rendering, and after QA at SHA-256
`bd9e5f448242cbec204c1d41f3dd55ab32b436842bc209c6de749b81645fd223`.

## Secure loopback visual QA

A temporary read-only static server was rooted exactly at `_build/nathealth`,
bound only to `127.0.0.1:54200`, and used only for the exact Supplementary
route. PID 80460 was stopped with a clean keyboard interrupt. A subsequent
`lsof` listener check returned no listener.

Desktop 1440 x 1000 and narrow 708 x 1000 inspection pass. The title, all
headings, prose, sidebar state, navigation, and footer are readable. Both
viewports have scroll width equal to client width, with zero measured overflow
elements and zero measured content-block overlaps. The narrow sidebar opens,
shows the correct active item, scrolls independently, and closes normally.
The browser console contains no warning or error entries.

Four in-app Browser screenshots are retained in this evidence directory:

- `visual_desktop_1440x1000.png`, SHA-256 `5b6c36fa74187542a74f4cb65a11eb95df8ce8dbd994fef48fce163df8bc7bbb`;
- `visual_narrow_708x1000.png`, SHA-256 `ce98564aa9777707fa8e9314fc25c9cbe29f6e3c1a237215bae786907a0662e3`;
- `visual_narrow_navigation_708x1000.png`, SHA-256 `e7eb1967407917e87636e9a548d1fc02855fa1eb92394c76f5e1e471f8a4df11`;
- `visual_narrow_footer_708x1000.png`, SHA-256 `1c7bb0c5bd869a33045dc21bfbbb55d265f3dfe0f55a80b3457d6f6ac64ac438`.

The two full-page captures repeat the static page navigation and footer during
the in-app Browser's full-page stitching. This is capture behavior, not page
duplication: the DOM contains exactly one page-navigation element and one
footer, both with static positioning, and the normal narrow bottom-viewport
capture shows the single instances in their final layout.

## Concurrent order-record transition

The immutable execution-time dispatch manifest remains
`c28c7751fcc77e6ef098238ad6ff2c5f01aa884c885744d989105d7a8bbd9ef0`.
It truthfully pins the order at execution time as
`3e59a5f9f9315e7ef071c30d62ba131ac324fe19b2fc31beb52b80e140fce4c4`,
5,311 bytes. During post-render verification, the coordinator resealed that
same order path to
`c93c21082427412a22657aebca3b533a8f2aa675fbe723c701b4ceec7f4480d7`,
6,189 bytes. The render had already completed and was not repeated.
`order_record_transition.csv` preserves both roles without rewriting history.

The coordination matrix is now
`ac04a9bd3ec62b13af2e905b7f0bb7a5e0b9b4a04f0324a0d2a9c579f215b9ab`
and records owner completion awaiting independent acceptance. The H02 companion
and every later render remain held.

## Preservation statement

No source QMD, profile, bibliography, CSL, CSS, package, lockfile, ledger,
manuscript, hypothesis page, preparation page, scientific input, scientific
artifact, or previously accepted HTML was edited. No commit, push, upload,
publication, model fit, prediction, bootstrap, simulation, or scientific
recomputation occurred.

This acceptance concerns successful integration of the current static outline.
It does not represent acceptance of a final journal Supplementary Information
narrative.
