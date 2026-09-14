# REPORT-017 H01 order 32k companion independent acceptance

Date: 2026-08-20

## Disposition

The H01 preparation and provenance companion is independently accepted on its
existing order-32i rendered HTML. Order 32k completed the authorized no-render
finalization, source-test reconciliation, direct current-manifest reseal, and
secure-loopback visual review. No repeat render or reader-source correction is
required.

Together with the previously accepted H01 result page, this closes H01's
current REPORT-017 result and companion integration. Principal-output
appearance remains provisional for final author approval.

## Accepted identities

- result QMD: `notebooks/hypotheses/H01.qmd`, SHA-256
  `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`;
- result HTML: `_build/nathealth/notebooks/hypotheses/H01.html`, SHA-256
  `df78ac3c2ed91515058b6af38e01b85b4baae74118699c008a29ba4dacf4d007`;
- companion QMD:
  `audit/hypotheses/H01/H01_analysis_preparation.qmd`, SHA-256
  `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`;
- synchronized build QMD:
  `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.qmd`,
  the same SHA-256 `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`;
- companion HTML:
  `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html`,
  SHA-256
  `5ab6587465f01f946fcf133f9f81a69168e08fa866f69830c2378e6c3cf250fe`;
- Nature Health profile: `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- preparation source and HTML test, SHA-256
  `7c1466cd8f964e0696c3c0a17fc2c53a9702dd7ccbb84e0e4926089b56de0fc6`;
- 65-row preparation manifest, SHA-256
  `310a017f49992e8a4a17f8497b66112b8352364ef80526c11709c1f39155653e`;
- current worker manifest, SHA-256
  `d695d40401f3d6758fa81a8370d7bd224c3526a8038258e835e5917c8f675bb6`.

The owner acceptance record is
`audit/hypotheses/H01/report017_order32k_companion_acceptance/order32k_acceptance_record.md`,
SHA-256 `b0a7f6ec7a2cbd3912191d779ed1b418020b7224802b5053a01b6fbc66a688d9`.
Its non-circular completion manifest is SHA-256
`1b69dc2f2b102e105ef7554b33a0c40a137fa5216016d9d78a3043814a7701b5`.

## Independent structural and preservation checks

R 4.6.1 independently verifies all 80 rows of the owner completion manifest
by path, SHA-256, and byte count. Paths are unique, and the manifest does not
contain itself.

The accepted companion contains exactly 20 native `gt` table endpoints and
two figure endpoints in source order. All table captions, figure captions,
alt text, notes, source-data links, and endpoint identities are present. The
semantic repair is exactly reversible and records 20 tables, 169 changed IDs,
797 changed `headers` attributes, and 966 substitutions. The final document
has no duplicate IDs. All 1,442 explicit table-header tokens resolve once to
the intended `th` in their own table, and all 1,471 supported ID references
resolve once.

All 21 HTML contracts pass, including reciprocal result links, registration
links and anchors, active navigation, the two restored source-data downloads,
country-coded study sites, and the absence of forbidden local or build links,
unresolved references, and error or warning nodes. The complete preparation,
reporting, REPORT-016, navigation, reader-link, and deviation tests pass. The
global country-site test's only earlier findings were the separately
authorized H04 line reflows, which are now independently accepted under H04
order 35b.

The 65-row preparation manifest is live-exact. The 1,659-row worker-manifest
audit has 1,657 live-exact rows and exactly two accepted historical
transitions for the H01 result HTML and Nature Health profile. All 1,118 build
inventory members are content-identical before and after order 32k. The
protected reconciliation covers 1,725 paths: 1,720 are byte-identical, two are
the authorized H01 order-32k changes, one is mutable coordination evidence,
and two are the independently sealed H04 order-35b source reflows. No extra
path changed.

## Independent visual review

The secure loopback record served only `_build/nathealth` on
`127.0.0.1:62390`. The exact companion route was inspected at 1440 x 1000,
708 x 1000, and a 200-percent-equivalent detailed viewport. The server was
then stopped, and the lifecycle record reports neither a remaining process nor
a listener.

Independent inspection of the retained screenshots and both native 2016 x
1497 figure PNGs confirms:

- the top-to-bottom Mermaid map is complete and legible;
- both figures have readable labels and legends at native and displayed size;
- the 20 tables remain usable on desktop and narrow screens;
- tables 18 and 19 use a contained horizontal scroller at narrow width, with
  the recorded 75-pixel scroll range working as intended;
- the near-eye and chest sample tabs are readable;
- headings, callouts, captions, links, and navigation are unobstructed; and
- there is no document-level horizontal overflow, clipping, or overlap.

The visual acceptance table passes all 13 checks, and the browser console has
no warning or error entry. Post-QA source, profile, HTML, build, and protected
identities remain stable.

## Boundary and next step

No Quarto command, scientific computation, model operation, artifact
regeneration, QMD or HTML edit, profile or ledger change, package or lockfile
change, commit, push, or upload occurred during independent acceptance.

H01 is idle with both reader pages accepted. H02 remains source-only accepted
and has no render authorization until a separate coordinator release.
