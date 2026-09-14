# REPORT-018 H05 result independent acceptance

Date: 2026-08-20

Disposition: **ACCEPTED**

## Independent review

The complete H05 order-44 return is accepted. The owner-equivalent acceptance
record is
`/private/tmp/H05-order44-evidence.3IiPQb/report018_h05_order44_acceptance.md`,
SHA-256 `b3b31d1db3e68d85c5a00f46f2c144796742ce4f39a46ba8bbec05d5c5cfec23`.
Its non-circular evidence manifest is SHA-256
`c49fe27dd1776e32e4d669f8f4ed032e034960fc8d71f5f65e90f98d9255649d`
and passes 33/33 exact, unique rows under R 4.6.1.

Exactly one normal-profile H05 result render completed under Quarto 1.9.37 and
R 4.6.1. The final HTML is
`_build/nathealth/notebooks/hypotheses/H05.html`, SHA-256
`a088e105be1987508280e91b938142773c8fb9275f1e924ac1ec9958a9b199f1`,
640,855 bytes. The semantic hook repaired 30 tables with 433 ID changes and
1,001 `headers` changes, for 1,434 reversible substitutions. Exact reversal
reproduced the recorded pre-hook SHA-256
`3286738fb0178d9d071960a252b471688a17bcf64d21d745ba8aa7064148813d`.

Static verification passes for 30 native gt tables, seven intended figures,
one caption per endpoint, complete alt text, source-data links, document-wide
unique IDs, 2,514 resolved header-ID tokens, zero unsupported ID references,
nine resolved preregistration-deviation links, reciprocal companion and
Supplementary information links, active navigation, the reader-facing
country-code contract, and zero embedded error, warning, stderr, or unresolved
reference nodes.

Secure loopback QA passed at 1440 by 1000, 708 by 1000, and 720 by 500 as the
200-percent-equivalent viewport. All 30 tables remain contained and usable.
The minimum table-cell text size at the tightest view is 11 px. All seven
controlling 300-dpi PNG exports, including the provisional principal figure,
were inspected at native size and in the rendered page. Labels, legends, axes,
symbols, panels, captions, the continued principal tables, disclosures,
headings, navigation, and links are readable and reachable. There is no
page-level horizontal overflow, clipping, or overlap. The optional favicon 404
is deferred as a nonblocking site cosmetic under REPORT-018.

The loopback server used only `127.0.0.1:59882`, was stopped, and left no
listener. The complete post-render and post-QA build inventories are
byte-identical at SHA-256
`49a47164036e3a0f465466b5b55f90d933cd449d591d3a4c0a00c9d88fa3e1e6`,
836 files and zero symlinks. All 135 protected paths remain exact relative to
the accepted post-render state. The build delta contains only the H05 result
HTML, `search.json`, and `sitemap.xml`.

## Accepted identities

- H05 result QMD: `7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0`
- H05 result HTML: `a088e105be1987508280e91b938142773c8fb9275f1e924ac1ec9958a9b199f1`
- held companion QMD: `0a5296442b46c8b9e43773d97eb979ffbbf3512faabe6f4399da2214d38cb81c`
- held companion HTML: `c44f4f77f4e2295f6b265ed9505c3c560361a7280562dd9ce1afce73149d5866`
- Nature Health profile: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`
- source-only acceptance: `07ae1d95e8374c9b29659e9fc760d392047b229252320e2767d7d68404ea07ec`

H05 result integration is complete. The H05 companion is the next eligible
serial REPORT-018 target after its current source, test, manifest, profile, and
stale-output pins are independently reproduced. Every later render remains
held.
