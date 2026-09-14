# REPORT-017 H01 order-32 consolidated source independent acceptance

Date: 2026-08-15

Disposition: accepted for source, tests, current manifests, historical preservation, and render readiness; rendered integration remains pending

## Accepted sources

- Result report: `notebooks/hypotheses/H01.qmd`, SHA-256 `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`, 93,260 bytes.
- Preparation and provenance companion: `audit/hypotheses/H01/H01_analysis_preparation.qmd`, SHA-256 `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`, 55,827 bytes.

The consolidated rewrite implements the complete approved 29-row source matrix. It preserves the accepted scientific content while establishing the approved reader hierarchy, early support orientation derived from the accepted exact-sample object, FDR reader language, dynamic registration and companion links, bounded disclosures, technical provenance separation, and the exact RH-SCI-H01-003 wording that model-specific term part-R² values may overlap and must not be summed.

## Independent verification

The final order-32b verifier is SHA-256 `9f8ef27787acce466daf2771dccf41d3e21cd92836300f52f2d30a4e86985a64`, 34,875 bytes. Its two-change reverse proof reproduces the accepted order-32a verifier SHA-256 `620b2fe71fcf25c542afa9c435f925887454db895059cbd4aa8617046369ea18`, 34,808 bytes.

One complete R 4.6.1 run completed in 6.68 seconds with exit status 0:

- 66 of 66 source contracts passed;
- four of four focused tests passed;
- 36 result tables and 10 result figures remain present exactly once;
- 20 companion tables and two companion figures remain present exactly once;
- `tbl-h01-primary-publication-summary` is the first result table endpoint;
- `fig-h01-model-support` is the first result figure endpoint;
- all formula, scientific numeric-token, source-data, artifact-reference, dynamic-link, registration-anchor, country-coded-site, historical-evidence, and direct-manifest contracts passed;
- all four current manifests passed their intended exact or explicitly classified state; and
- scoped `git diff --check` passed.

The focused tests independently report:

- H01 reporting source and held-HTML structure: PASS;
- H01 preparation source-only contract: PASS with 20 table and two figure endpoints;
- REPORT-016 reconciliation: PASS with 1,161 protected scientific artifacts unchanged; and
- model-support display refresh: PASS with 136 frozen cells and only the accepted legend-title PNG/SVG change.

The 21-row non-circular owner manifest is SHA-256 `86439ce8168161b34599a5596dfe3d81cf168e6111762d57d3d6592ecb9abcd2`. Independent R 4.6.1 verification reproduced all 21 hashes and byte counts, all 24 current dispatch identities, all 20 order-32a evidence identities, all 28 prior dispatch identities, and all six retained baseline identities.

## Scientific and execution boundary

No QMD chunk was executed. No model, fit, prediction, bootstrap, simulation, p-value, interval, sample definition, sensitivity, diagnostic, source-data file, or figure was recomputed or regenerated. No Quarto render, shared-profile change, package change, commit, or push occurred.

The held result HTML remains SHA-256 `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa`. The held companion HTML remains SHA-256 `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`. They predate the consolidated source rewrite and are not accepted as current rendered integration.

## Next gate

H01 is ready for separately authorized, serial, normal-profile targeted rendering of the result and companion, followed by semantic-hook validation, dynamic-link checks, native-table checks, protected-identity verification, and combined desktop and narrow secure-loopback visual QA. Principal output roles and appearance remain provisional pending that render and author review.
