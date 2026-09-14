# REPORT-018 H08 companion serial release

Date: 2026-08-21

Disposition: **RELEASED FOR EXACTLY ONE H08 COMPANION RENDER**

The H08 result page is independently accepted. This release applies only to
the H08 analysis-preparation and provenance companion. Every later
REPORT-018 render remains held pending independent companion acceptance.

## Serial prerequisite and accepted result

The controlling result acceptance is
`audit/report_harmonization/report018_h08_result_independent_acceptance.md`,
SHA-256
`6b9e66643ab8c94aca11e5bf9804e0e314beb3c8b2eefa668532372e14d32fd7`,
with its 31-row non-circular manifest at SHA-256
`8f7c3351b1fa085f4f23f00ccff9bd21d13be7ef67cabd1767e690991087c0eb`.

The accepted result endpoints remain fixed at:

- QMD `notebooks/hypotheses/H08.qmd`, SHA-256
  `1b6b50b21e22d60909a65b125ce74be54829e5efc10de33f888fcd294c7374b1`,
  44,031 bytes; and
- HTML `_build/nathealth/notebooks/hypotheses/H08.html`, SHA-256
  `472848d0da3e3996fa1727151048e3cab4a7e363dba3dc8eda8b024eb5a4ca9a`,
  340,040 bytes.

## Companion preflight

The R 4.6.1 checker
`scripts/report_harmonization/check_h08_companion_report018_release.R`,
SHA-256
`4e5e82d02d7f509aac6bb2719a8ec4367f0af55fb7cfe1c755512f68833e32fa`,
passed 32 of 32 checks. Its verification output is SHA-256
`1d654a189cf7aba6e6c428f89cfbbe6b6627433910b64310e8057c6fe828f26a`.
The 34-row pin set is SHA-256
`340c236b006a18c2f42ba2d5563dc7cab9267cce2c500a7bbd43e18e9881b309`.

The preflight establishes:

- 34 of 34 current hard pins and all 31 result-acceptance members exact;
- 24 parseable R chunks, 19 unique native-table endpoints, three unique
  figure endpoints, and one top-down Mermaid endpoint in accepted source
  order;
- 25 relative reader and source-data links, all resolving, including three
  dynamic result links and the result preregistration-deviation anchor;
- no model fit, refit, prediction, simulation, resampling, bootstrap,
  p-value recalculation, or scientific-regeneration call;
- six frozen companion source-data files with the accepted 18, 24, 9, 153,
  17, and 56 row counts;
- eight complete nine-member FDR families and zero retained associations;
- three companion figures with exact current baseline identities and an
  accepted 8-point final-size text floor;
- exactly 121 of 125 current preparation-manifest rows live-exact, with only
  the accepted companion-QMD, result-QMD, result-HTML, and profile
  historical transitions;
- a predicted 258-member post-render preparation manifest when the dedicated
  helper runs before any durable order evidence is created;
- 851 current build files and zero build symlinks; and
- R 4.6.1, digest 0.6.39, and Quarto 1.9.37.

## Historical test classification

Preserve `tests/hypotheses/H08/test_h08_preparation_report.R` byte-for-byte
and do not execute it. It still requires the obsolete hard-coded source
literal `../../../notebooks/hypotheses/H08.html`. The accepted source instead
uses three dynamic `.qmd` result links, which Quarto resolves to the accepted
HTML route. The historical result test is also preserved and unexecuted.

This is a test-classification boundary only. A new order-specific verifier
must reproduce every current source, scientific, semantic, endpoint, link,
navigation, accessibility, and manifest contract against the fresh page.

## Authorized execution

Before rendering, reproduce every non-matrix dispatch member, confirm no
competing Quarto, Pandoc, H08 semantic, or loopback process, inventory the
complete build and protected H08 scopes, and create one fresh empty absolute
semantic-audit directory under `/private/tmp`.

From the main project root, run exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> \
quarto render audit/hypotheses/H08/H08_analysis_preparation.qmd --profile nathealth
```

The established narrow access to the existing user-owned Quarto and R caches
is authorized for this command. Do not change `HOME`, redirect or reset a
cache, restore or install packages, bypass the normal profile or semantic
hook, render the result again, render another page, or render the full
project. If startup or rendering fails, stop once with complete evidence. No
retry is authorized.

## One helper execution and non-circular ordering

If and only if the render and semantic hook succeed, execute exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
Rscript --vanilla scripts/hypotheses/H08/build_h08_preparation_report_manifest.R
```

All pre-render and render-working evidence must remain under `/private/tmp`
until this helper completes. Create the durable order evidence directory only
after the helper has written the manifest. Require:

- authoring and build companion QMDs byte-identical;
- exactly 258 unique manifest rows;
- every row live-exact;
- no row for the preparation manifest itself; and
- no order-specific evidence path included in the manifest.

The helper may change only the source-identical build QMD and the truthful
current H08 preparation manifest. Do not rerun it.

## Complete post-render acceptance

Before browser QA, require all of the following:

1. render exit 0 under R 4.6.1 and Quarto 1.9.37, with no embedded execution
   error, unresolved cross-reference, or raw trace;
2. exactly 19 native `gt` tables, three figures, and one top-down Mermaid in
   accepted source order, with every endpoint, caption, note, cell, label,
   alt text, and paired-source relationship present;
3. semantic repair of all 19 tables, exact ledger reversal and reapplication,
   zero duplicate document IDs, and every `headers` token resolving exactly
   once to an intended `th` inside its own table;
4. all 25 relative targets and required fragments resolving, including the
   three dynamic result links, reciprocal result-to-companion navigation,
   DEV-035, DEV-036, and the result preregistration-deviation anchor;
5. the accepted score, sample, formula, model-setting, FDR-family, response,
   influence, sensitivity, METRIC-011, code-map, output-map, and environment
   contracts reproduced from frozen inputs without scientific recomputation;
6. the accepted result source and HTML, profile, helper, historical tests,
   scientific and display artifacts, source CSVs, handoff, phase-4 manifest,
   semantic wrapper and engine, lockfile, and unrelated paths exact;
7. the phase-4 manifest retained byte-for-byte with its H08 result and
   companion HTML rows classified as historical-to-current after this
   render;
8. the source-side historical companion HTML remains absent and is not
   restored; and
9. every build delta is target-owned, source-identical, or an expected search
   or sitemap update. Any regenerated companion PNG must be tied to the same
   frozen CSV rows and pass geometry, content, final-size, and visible-reader
   checks. No durable scientific or display artifact may change.

## Secure loopback visual QA

Only after all nonvisual gates pass, serve `_build/nathealth` through one
temporary read-only server bound only to `127.0.0.1`. Inspect only the H08
companion route at 1440 by 1000, 708 by 1000, and 720 by 500 as the
200-percent-equivalent view. Inspect all 19 tables, all three figures, the
Mermaid diagram, headings, callouts, captions, notes, links, navigation,
wrapping, disclosures, and final provenance. Exercise every required narrow
table scroller.

Inspect the three figures at their intended 170-mm final size and require at
least 7-point essential text. Require zero page-level overflow, clipping,
overlap, missing content, broken interaction, or report-attributable console
warning or error. Close the QA surface, reset the viewport, stop the server,
prove no listener remains, and require post-QA build and protected inventories
to be byte-identical to their post-render states.

## Prohibitions and next stop

No source, helper, historical test, model, estimate, interval, p-value,
classification, scientific artifact, durable figure, profile, shared ledger,
package, lockfile, handoff, manuscript, commit, push, upload, or publication
change is authorized. Do not render the result again, render a later target,
retry a failed command, or open a language or cosmetic cleanup loop.

Return one complete acceptance record and one unique non-circular evidence
manifest, or one consolidated fail-closed record. The mandatory next stop is
independent H08 companion acceptance. Every later render remains held.
