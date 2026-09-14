# REPORT-018 H05 companion independent acceptance

Date: 2026-08-20

Disposition: **ACCEPTED**

## Independent review

The no-rerender order-45c return is accepted. The owner acceptance is
`audit/hypotheses/H05/report018_order45c_visual_qa/order45c_owner_acceptance.md`,
SHA-256 `fab88a034c5eb88cd07c21a1257026a537603c408e3e43fb55c873a664a73ec9`.
Its non-circular manifest is SHA-256
`a6b636b972577ec6651113f89678fdc274cdedb45247734f0ebb68117fe076b4`
and passes 51/51 exact, unique rows under R 4.6.1.

The accepted order-45b HTML has 22 native gt tables, three figures, one
top-down Mermaid, document-wide unique IDs, resolved table-header references,
resolved reciprocal and internal links, active navigation, nine country-coded
sites, and no embedded error, warning, stderr, or unresolved-reference node.
The semantic repair remains exactly reversible. The remaining source-side test
expectation for a literal `.html` link is nonblocking under REPORT-018 because
the source uses the accepted dynamic `.qmd` link and the rendered link resolves.

Secure loopback QA passed at 1440 by 1000, 708 by 1000, and 720 by 500 as the
200-percent-equivalent viewport. All 22 tables are usable. Five wide narrow
tables expose contained horizontal scrollers, and all five were exercised
successfully. Every table has a nonempty caption. The three figures, their
captions and alt text, the Mermaid, callouts, code disclosures, headings,
navigation, and links are legible and usable. No page-level overflow, clipping,
overlap, browser warning, or browser error was observed. The optional favicon
404 remains a deferred site cosmetic.

The loopback server bound only to `127.0.0.1:63192`, stopped cleanly, and left
no listener. The pre-QA and post-QA build inventories are byte-identical at
SHA-256 `fc5b883724477532baa2697eb94864c53e26991a2f49b34cc3a43dc2ebb9fe11`
for 836 files and zero symlinks. All 158 protected identities are unchanged at
SHA-256 `651c973d28b7b83135cb2492412f5821f515f4fb211eb5a6c09ee61ea7ac1fe3`.

## Accepted identities

- H05 result QMD: `7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0`
- H05 result HTML: `a088e105be1987508280e91b938142773c8fb9275f1e924ac1ec9958a9b199f1`
- H05 companion QMD: `843f60f890daac0e41c6655bc365ab0325e3f582e011610469a799946b2f2811`
- H05 companion HTML: `856dbd21920b65dce6437172022d0e6130410d9e357259a4d50aa1f6fe2461d8`
- H05 preparation manifest: `49ab691f8d86852ec034ed49ffa773032c3acdf3312d7fef5de7849c9ff07d80`
- H05 preparation test: `ec738f56fb8b3cf94755fd5055d128d1a22bcc31a435554568aaa15acf78890e`
- Nature Health profile: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`
- coordination matrix: `482e30f8b778dd04ad44b339fbefb33adaf1296d23cdf8162526d77e37f4e2e7`

H05 result and companion integration is complete. The serial render gate is
clear. H06 hourly result is next, subject to acceptance of its already recorded
bounded display-artifact prerequisite. No later target is released by this
acceptance.
