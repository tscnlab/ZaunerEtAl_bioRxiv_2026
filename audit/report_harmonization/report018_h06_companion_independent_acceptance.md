# REPORT-018 H06 companion independent acceptance

Date: 2026-08-21

Disposition: **ACCEPTED**

## Independent review

The no-rerender order-47d companion return is accepted. The owner acceptance
is
`audit/hypotheses/H06/report018_order47d_companion_acceptance/completion_record.md`,
SHA-256
`a89dfc0651e45321eeb3937068fe22d2cff80f8086382cbb3770b7a4f08fc78e`.
Its non-circular owner manifest is SHA-256
`5816a6ea3d493eecde2d3188e9080de4b5058bcc03149e14652c13bdb5414b80`.
An independent R 4.6.1 replay verifies 146 of 146 exact, unique,
non-circular rows.

The continuation correctly preserves the two controlling central
classifications. The stale literal result-link test remains deferred under
REPORT-018 because the accepted source uses three dynamic `.qmd` result links,
zero retired `.html` result links, and the rendered targets resolve. The
response-distribution PNG transition is accepted deterministic target-owned
regeneration. Its current SHA-256 is
`ab51417026d3b3edd9c0af7a455961b9e018cd0d4396bc6ba2f615ac98e7f7a1`.
Independent central R 4.6.1 reproduction from the frozen source CSV was exact.

The accepted companion HTML contains 30 native gt tables, three figures, and
one top-down Mermaid. Document IDs are unique. All 1,142 explicit gt header
tokens resolve exactly once within their own tables, all 2,505 internal links
and required fragments resolve, active navigation and all nine country-coded
study sites are present, and no embedded error, warning, stderr, unresolved
cross-reference, or forbidden local/build path appears. The 985 semantic
substitutions remain exactly reversible.

Secure-loopback QA passed at 1440 by 1000, 708 by 1000, and 720 by 500 as the
200-percent-equivalent viewport. All 30 tables were inspected at desktop and
200-percent-equivalent size. Four wide tables expose contained narrow
scrollers, and each scroller reached both edges and reset. All three figures,
the Mermaid, headings, callout, captions, links, and navigation are legible
and usable without page-level overflow, clipping, overlap, browser warning,
or browser error. Independent inspection of the retained screenshots agrees
with the recorded PASS disposition.

The current response-distribution PNG passes the 170-mm check with 8.03-point
effective essential text. The other two figures pass at 7.30 and 8.03 points.
The loopback server bound only to `127.0.0.1:54317`, stopped cleanly, and left
no listener. The final reconciliation proves 821 of 821 build files and 469
of 469 protected paths byte-identical across QA.

One preliminary temporary postflight checker stopped before reconciliation
because it incorrectly prefixed two already absolute semantic-evidence paths.
The definitive read-only checker corrected only that temporary resolver and
passed. No project, build, browser, scientific, or held H06-daily file changed,
so this evidence-harness stop is nonblocking.

## Accepted identities

- H06 hourly result QMD:
  `d65c197cb37db32101d8a43fcdc80198ab599a95cb73259abd187c9b2b58d350`
- H06 hourly result HTML:
  `8b5f1b0ada997290ec5324de35e0c874fd25e2e9ef052281acaab07d0a3dccaa`
- H06 companion QMD:
  `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`
- H06 companion HTML:
  `f9a4f51db555454a2e7cd0ea70895978b71016e6bd2c7310ae5033ad3c7ed378`
- H06 preparation manifest:
  `a3bd413daf9e154d78f32e49caea0697303c8d86ce387892ab081b06ae8b6bbc`
- H06 preparation test, unchanged and deferred only for the classified
  literal-link expectation:
  `2b9f02f7caa448a3c7fdb88b0febc5ce306239002ebe220b6f5f7a7c4285a4fc`
- Nature Health profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`
- coordination matrix:
  `3813794523090f4cab710e60c274aa449d7eaad238319096fdd31c46ff545b55`

H06 hourly result and companion integration is complete. H06_daily is the
next eligible serial result target, but no H06_daily render is released by
this acceptance. Central concurrence and a separate exact render order remain
required.
