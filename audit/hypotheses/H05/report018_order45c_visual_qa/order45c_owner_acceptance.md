# REPORT-018 H05 companion order 45c owner acceptance

Date: 2026-08-20

Disposition: **ACCEPTED**

## Boundary

Order 45c performed no render, source edit, test edit, manifest edit, scientific
execution, artifact regeneration, profile change, or package change. It inspected
the existing order-45b companion HTML through the approved read-only loopback
surface. The accepted H05 result page remained frozen.

The order-45b test stop remains classified as a nonblocking historical HTML-link
expectation under REPORT-018. The accepted source uses a dynamic `.qmd` link and
the rendered link resolves correctly. This classification did not change the
test or reader source.

## Visual acceptance

The H05 companion passed secure loopback QA at 1440 by 1000, 708 by 1000, and
720 by 500 as the 200-percent-equivalent viewport.

- All 22 native gt tables are contained and readable. The minimum table-cell
  text is 9 px at every checked viewport.
- Five tables require horizontal movement at the narrow viewport. All five
  scrollers were exercised successfully, with 31 to 230 px available travel.
- Every table has exactly one nonempty caption.
- All three figures are unclipped and retain nonempty alt text and captions.
  Their lightbox views load the expected 1920 by 1305, 2112 by 1248, and
  2112 by 1344 PNGs completely.
- The top-down Mermaid is 586 by 750 px, has 18 text elements, and retains
  16 px minimum text at desktop and narrow widths.
- Headings, three callouts, active navigation, reciprocal links, code
  disclosures, and page wrapping remain usable. A disclosure was opened and
  closed successfully.
- No page-level horizontal overflow, clipping, overlap, embedded error node,
  browser warning, or browser error was observed.

The optional `/favicon.ico` request returned 404 in the static-server access
log. It is a deferred site cosmetic under REPORT-018 and does not affect the
document.

## Loopback and preservation

The server root was exactly `_build/nathealth`, with zero symlinks. It bound
only to `127.0.0.1:63192` and served only the exact H05 companion route and its
retained assets. It was stopped cleanly and `lsof` found no listener afterward.

The complete 836-file build inventory is byte-identical before and after QA at
SHA-256 `fc5b883724477532baa2697eb94864c53e26991a2f49b34cc3a43dc2ebb9fe11`.
All 158 protected paths are byte-identical at SHA-256
`651c973d28b7b83135cb2492412f5821f515f4fb211eb5a6c09ee61ea7ac1fe3`.
The symlink inventories are also byte-identical and contain zero entries.

## Accepted identities

- H05 result QMD: `7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0`
- H05 result HTML: `a088e105be1987508280e91b938142773c8fb9275f1e924ac1ec9958a9b199f1`
- H05 companion QMD: `843f60f890daac0e41c6655bc365ab0325e3f582e011610469a799946b2f2811`
- H05 companion HTML: `856dbd21920b65dce6437172022d0e6130410d9e357259a4d50aa1f6fe2461d8`
- H05 preparation manifest: `49ab691f8d86852ec034ed49ffa773032c3acdf3312d7fef5de7849c9ff07d80`
- H05 preparation test, unchanged: `ec738f56fb8b3cf94755fd5055d128d1a22bcc31a435554568aaa15acf78890e`
- Nature Health profile: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`

H05 result and companion integration is complete. H06 hourly result may become
the next serial REPORT-018 target only after its outstanding bounded display
artifact prerequisite is accepted.
