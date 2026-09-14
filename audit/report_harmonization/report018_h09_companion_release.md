# REPORT-018 H09 companion serial release

Date: 2026-08-22

Disposition: **RELEASED FOR EXACTLY ONE H09 COMPANION RENDER**

The H09 result page is independently accepted. This release applies only to
the H09 analysis-preparation and provenance companion. Every later
REPORT-018 render remains held pending independent companion acceptance.

## Serial prerequisite and accepted result

The controlling result acceptance is
`audit/report_harmonization/report018_h09_order56b_result_independent_acceptance.md`,
SHA-256
`4748b3b18e6ca0589e00e629490cca97aa72507589be6165e1893640d08b5288`,
with its 37-row non-circular manifest at SHA-256
`cf3e85d447a6e4523e647a29e6989d678d29bed6af7c18f11523db0208175df3`.

The accepted result endpoints remain fixed at:

- QMD `notebooks/hypotheses/H09.qmd`, SHA-256
  `c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6`,
  36,970 bytes; and
- HTML `_build/nathealth/notebooks/hypotheses/H09.html`, SHA-256
  `901fd63b45182be70ef77166c418633220a7226d86f52e14d1c79afbfc7cdd16`,
  244,127 bytes.

## Companion preflight

The R 4.6.1 checker
`scripts/report_harmonization/check_h09_companion_report018_release.R`,
SHA-256
`9fcd89bc7d2585d927fd4527e0cbd8a893e52cb87f353cabb38ef04a9f5cffdc`,
passed 30 of 30 checks. Its verification output is SHA-256
`89a533044dac43c0f179761900b7f598bf2c43d14df915847f0b73bffa8d64a6`.
The 34-row pin set is SHA-256
`16a181126f1978f7c18f6be621612ab1e422442f55889e302611c1db66f2e677`.

The preflight establishes:

- 34 of 34 current hard pins and all 37 result-acceptance members exact;
- 22 parseable R chunks, 19 unique native-table endpoints, one figure
  endpoint, and one top-down Mermaid endpoint in accepted source order;
- 23 relative reader and source-data link occurrences to 22 unique targets,
  all resolving, including two dynamic result links and the result
  preregistration-deviation anchor;
- no model fit, refit, prediction, simulation, resampling, bootstrap,
  p-value recalculation, or scientific-regeneration call;
- the frozen 108-row model-frame index as the sole source for the companion
  sample-support figure;
- exactly 113 of 132 current preparation-manifest rows live-exact, with only
  19 accepted source, result, profile, registry, figure, and contract
  historical transitions;
- a predicted 450-member post-render preparation manifest when the dedicated
  helper runs before durable order evidence is created;
- 851 current build files and zero build symlinks; and
- R 4.6.1, digest 0.6.39, and Quarto 1.9.37.

## Historical test classification

Preserve `tests/hypotheses/H09/test_h09_preparation_report.R` byte-for-byte
and do not execute it. It retains exactly three obsolete integration
assumptions:

1. a hard-coded `../../../notebooks/hypotheses/H09.html` source link instead
   of the accepted dynamic `.qmd` result link;
2. a hard-coded result-to-companion `.html` source link instead of the
   accepted dynamic `.qmd` companion link; and
3. an assertion that H09 is absent from the normal profile, although the
   accepted profile now places the result and companion adjacently.

These are historical test classifications only. A new order-specific
verifier must reproduce every current source, scientific, semantic, endpoint,
link, navigation, accessibility, and manifest contract against the fresh
page. Preserve the historical result test unchanged and unexecuted as well.

## Authorized execution

Before rendering, reproduce every non-matrix dispatch member, confirm no
competing Quarto, Pandoc, H09 semantic, or loopback process, inventory the
complete build and protected H09 scopes, and create one fresh empty absolute
semantic-audit directory under `/private/tmp`.

From the main project root, run exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> \
quarto render audit/hypotheses/H09/H09_analysis_preparation.qmd --profile nathealth
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
Rscript --vanilla scripts/hypotheses/H09/build_h09_preparation_report_manifest.R
```

All pre-render and render-working evidence must remain under `/private/tmp`
until this helper completes. Create the durable order evidence directory only
after the helper has written the manifest. Require:

- authoring and build companion QMDs byte-identical at the accepted source
  identity;
- exactly 450 unique manifest rows;
- every row live-exact;
- no row for the preparation manifest itself; and
- no order-specific evidence path included in the manifest.

The helper may change only the source-identical build QMD and the truthful
current H09 preparation manifest. Do not rerun it. The historical source-side
HTML and its 16-file support tree must remain byte-identical and must not be
copied over the canonical website output.

## Complete post-render acceptance

Before browser QA, require all of the following:

1. render exit 0 under R 4.6.1 and Quarto 1.9.37, with no embedded execution
   error, unresolved cross-reference, or raw trace;
2. exactly 19 native `gt` tables, one figure, and one top-down Mermaid in
   accepted source order, with every endpoint, caption, note, cell, label,
   alt text, and source relationship present;
3. semantic repair of all 19 tables, exact ledger reversal and reapplication,
   zero duplicate document IDs, and every `headers` token resolving exactly
   once to an intended `th` inside its own table;
4. all 23 relative target occurrences and all required fragments resolving,
   including the two dynamic result links, reciprocal result-to-companion
   navigation, DEV-037, DEV-038, DEV-039, and the result deviation-section
   anchor;
5. the accepted score directions, sample counts, formulas, model settings,
   four complete five-outcome FDR families, diagnostic qualifications,
   sensitivities, METRIC-011 provenance, code map, output map, and environment
   contracts reproduced from frozen inputs without scientific recomputation;
6. the accepted result source and HTML, profile, helper, historical tests,
   scientific and display artifacts, source CSVs, handoff, phase-4 manifest,
   semantic wrapper and engine, lockfile, and unrelated paths exact;
7. the phase-4 manifest retained byte-for-byte with its H09 result and
   companion HTML rows classified as historical-to-current after this render;
8. the historical source-side companion HTML and support tree retained
   byte-for-byte; and
9. every build delta target-owned, source-identical, or an expected search or
   sitemap update. The one generated companion PNG must derive from the same
   frozen 108-row model-frame index and preserve geometry, values, labels,
   panels, colours, and visible content. No durable scientific or display
   artifact may change.

## Secure loopback visual QA

Only after all nonvisual gates pass, serve `_build/nathealth` through one
temporary read-only server bound only to `127.0.0.1`. Inspect only the H09
companion route at 1440 by 1000, 708 by 1000, and 720 by 500 as the
200-percent-equivalent view. Inspect all 19 tables, the figure, the Mermaid
diagram, headings, callouts, captions, notes, links, navigation, wrapping,
disclosures, and final provenance. Exercise every required narrow table
scroller.

Inspect the figure at its intended 170-mm final size and require at least
7-point essential text. Require zero page-level overflow, clipping, overlap,
missing content, broken interaction, or report-attributable console warning
or error. Close the QA surface, reset the viewport, stop the server, prove no
listener remains, and require post-QA build and protected inventories to be
byte-identical to their post-render states.

## Prohibitions and next stop

No source, helper, historical test, model, estimate, interval, p-value,
classification, scientific artifact, durable figure, profile, shared ledger,
package, lockfile, handoff, manuscript, commit, push, upload, or publication
change is authorized. Do not render the result again, render a later target,
retry a failed command, or open a language or cosmetic cleanup loop.

Return one complete acceptance record and one unique non-circular evidence
manifest, or one consolidated fail-closed record. Retain external semantic
evidence until independent acceptance. The mandatory next stop is independent
H09 companion acceptance. Every later render remains held.
