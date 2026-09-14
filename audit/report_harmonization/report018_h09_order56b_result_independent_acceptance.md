# REPORT-018 H09 order 56b result independent acceptance

Date: 2026-08-22

Disposition: **ACCEPTED**

## Independent result

The H09 result page is independently accepted after the single authorized
Sass-cache environment retry.

Fresh R 4.6.1 replay verifies:

- the 118-member owner evidence manifest is exact, unique, and non-circular;
- the one environment-only retry used the accepted H09 target and `nathealth`
  profile, disabled the renv autoloader, retained the accepted R library and
  normal `HOME`, `XDG_CACHE_HOME`, and `DENO_DIR`, and exited successfully;
- the existing Quarto Sass cache remained user-owned and all 25 cache members
  remained byte-identical;
- the result HTML is
  `901fd63b45182be70ef77166c418633220a7226d86f52e14d1c79afbfc7cdd16`,
  244,127 bytes;
- semantic repair made exactly 54 ID and 505 `headers` substitutions across
  11 native `gt` tables, for 559 reversible substitutions in total;
- the 559-row raw ledger, six semantic reverse checks, one unique document
  main element, zero duplicate document IDs, and all 505 table-header tokens
  pass independently;
- all 11 table endpoints and four figure endpoints pass, and every rendered
  figure matches its accepted durable display file;
- all 16 nonvisual domains, 23 link occurrences, 21 unique targets, reciprocal
  navigation, deviation anchors, score directions, FDR-family contracts,
  country labels, and protected reader claims pass;
- nine visual-QA domains pass at 1440 by 1000, 708 by 1000, 720 by 500, and
  exact 170-mm figure width; all four figures retain at least 7.224 effective
  points for essential text;
- all 851 build paths and 275 protected paths reconcile after QA;
- all nine fixed source identities and all 17 current display-manifest members
  remain exact; and
- the loopback server was bound only to `127.0.0.1`, stopped cleanly, and left
  no H09 render, semantic-hook, R, server, or listener process.

The rejected stitched long-page captures are evidence of a QA-harness
limitation only. Acceptance uses bounded anchor-specific captures that retain
each table and figure at its true on-page size. No page change or additional
render occurred.

## Controlling identities

- result QMD:
  `notebooks/hypotheses/H09.qmd`, SHA-256
  `c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6`;
- accepted result HTML:
  `_build/nathealth/notebooks/hypotheses/H09.html`, SHA-256
  `901fd63b45182be70ef77166c418633220a7226d86f52e14d1c79afbfc7cdd16`;
- held companion QMD:
  `audit/hypotheses/H09/H09_analysis_preparation.qmd`, SHA-256
  `7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46`;
- held companion HTML:
  `_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html`,
  SHA-256
  `4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05`;
- owner acceptance:
  `audit/hypotheses/H09/report018_order56b_environment_retry/ORDER56B_ACCEPTANCE.md`,
  SHA-256
  `a44988f7e9afae9ca4064ae3f7ec971a7e48a3dc47bb5056aef6992b3b845cdd`;
- owner 118-member seal:
  `audit/hypotheses/H09/report018_order56b_environment_retry/order56b_evidence_manifest.csv`,
  SHA-256
  `2b4e45d93120364f4b9589184e93d92f2e247a749226667c75ce00e46779ce2a`;
- independent checker:
  `scripts/report_harmonization/check_report018_h09_order56b_result_acceptance.R`,
  SHA-256
  `b0fd0d497930875605e48c9d5aa2b60c8645562ab56235fc1d43b1ee8d5c1828`;
  and
- independent 14-check verification:
  `audit/report_harmonization/report018_h09_order56b_result_independent_verification.csv`,
  SHA-256
  `03ee9fb855190c7efcfa4a230e4c3db4a0d845dfe06f6e4b2cb84fbbbfa6928a`.

## Next serial boundary

The H09 result is accepted. The H09 preparation/provenance companion is now
eligible for one separately sealed companion-only REPORT-018 render order.
That order must preserve the accepted result QMD and HTML, every repaired
display identity, all scientific artifacts, the profile, semantic tools, and
the complete order-56 through order-56b evidence chain. No later target may be
released before independent companion acceptance.
