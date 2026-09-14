# REPORT-018 H08 result-page central concurrence and serial release

Date: 2026-08-21

Disposition: **RELEASED FOR EXACTLY ONE H08 RESULT RENDER**

The independently accepted H07 result and companion integration clears the
serial render gate. This release applies only to the H08 result page. The H08
companion and every later REPORT-018 render remain held pending separate
independent result acceptance.

## Controlling acceptance and current pins

The preceding serial acceptance is:

- `audit/report_harmonization/report018_h07_companion_independent_acceptance.md`,
  SHA-256
  `d721a733c3ccb5867f7cbed4fc442858f9c4561354db5023422e96765e854ca4`;
  and
- its 34-row non-circular manifest, SHA-256
  `fd57630a224c6f998712bcf457f422cab4303e751fd1d15370be9d1595b07fb7`.

The released H08 pins are:

- result QMD `notebooks/hypotheses/H08.qmd`, SHA-256
  `1b6b50b21e22d60909a65b125ce74be54829e5efc10de33f888fcd294c7374b1`,
  44,031 bytes;
- held companion QMD
  `audit/hypotheses/H08/H08_analysis_preparation.qmd`, SHA-256
  `3eeeda47c909be2ca32bf234af18f2d690f1c3e7b26e854f7311c0d8300f6f2d`,
  57,777 bytes;
- stale result HTML `_build/nathealth/notebooks/hypotheses/H08.html`,
  SHA-256
  `a08a888a40ec58669c61a47b7500159388577eaad49ece5440b9bee9da6a93e1`,
  299,712 bytes;
- held companion HTML
  `_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html`,
  SHA-256
  `95f5ba0aede0ee6cf0d1b65fcdc53623d52810f8316c846cb214b4fb34a5f135`,
  675,700 bytes; and
- `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`,
  with the result and companion adjacent in the render list and website
  navigation.

The semantic wrapper and accepted engine remain exact at SHA-256
`28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`
and
`7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`.
The lockfile remains SHA-256
`3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.
R is 4.6.1 and Quarto is 1.9.37.

The coordination-matrix row in the pin set is release-time evidence only. It
is not an owner execution pin because dispatching this order will truthfully
update that coordinator-owned file. The completed central checker must not be
rerun after that expected transition. Every other pin remains a hard owner
preflight identity.

## Independent source and integration preflight

The read-only checker
`scripts/report_harmonization/check_h08_result_report018_release.R`, SHA-256
`06c523c34776008d76cd8e2a2d4fde217adbe0e7b61de7ea87d2d4987d8a0a26`,
passed under R 4.6.1 after Air 0.4.1 and R parse checks. Its 31-row pin input is
`audit/report_harmonization/report018_h08_result_release_pins.csv`, SHA-256
`49388f62105372f81cc0ef4cbbb7ce28eba2553b76d6b263806856eb15331714`.

Fresh verification passed:

- 31 of 31 exact, unique release pins;
- 22 parseable R chunks, 15 native `gt` table endpoints, and five figure
  endpoints in accepted source order;
- exactly 26 unique relative reader and source-data targets, with DEV-035 and
  DEV-036 resolving and DOC-001 absent;
- all nine accepted Wilkinson formula literals;
- zero fit, refit, prediction, simulation, bootstrap, p-value recalculation,
  or artifact-writing calls;
- nine near-eye and nine chest primary rows, eight complete nine-member FDR
  families, and zero multiplicity-retained associations;
- the accepted near-eye corrected-dose estimate and interval, raw p-value,
  and adjusted p-value;
- all five result figures at or above the accepted 7-point final-size floor;
  and
- zero symlinks in `_build/nathealth`.

## Historical test and manifest classification

The unchanged Stage 3 manifest has 102 rows. Exactly 100 are live-exact. Its
only two current historical transitions are:

1. the accepted source-only result-QMD transition from `13b3547c...` to
   `1b6b50b2...`; and
2. the accepted shared-profile transition from `02aed2be...` to
   `80dd0557...`.

The historical manifest must remain byte-identical. After the render, its
result-HTML row will become the third expected historical-to-live transition.
Every other row must remain exact.

The unchanged H08 reader test is also a pre-harmonization historical contract.
It requires `Results in brief`, rejects `Answer in brief`, requires visible
`BH-adjusted` wording, and expects 14 native tables. The accepted source now
requires `Answer in brief`, FDR wording, and 15 native tables because the
formula endpoint is a native `gt` table. Preserve the test byte-for-byte and
do not execute it in this result-only order. The held preparation test also
remains unexecuted. Use a new order-specific verifier under the evidence
directory to enforce the accepted current source and rendered-page contract.

This classification does not waive any scientific value, source, formula,
link, semantic, table, figure, or reader-page requirement.

## Sole authorized render

After reproducing every non-matrix hard pin, completing pre-render build and
protected inventories, confirming zero build symlinks and no competing
render process, and creating one fresh empty absolute semantic-evidence
directory under `/private/tmp`, run exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> \
quarto render notebooks/hypotheses/H08.qmd --profile nathealth
```

The narrow elevated filesystem access already established for the existing
user-owned Quarto and R caches is authorized for this command. Do not change
`HOME`, reset or redirect a cache, install or restore packages, bypass the
profile or semantic hook, render the companion, render another page, or
render the full project. If startup fails before QMD execution, stop once
with complete environment evidence. Do not retry.

The page may read accepted stored tables, source CSVs, registries, and
figures and format their frozen values. It must not fit or refit a model,
predict, bootstrap, simulate, resample, recalculate p-values, change a
classification, or rebuild a scientific artifact.

## Required result-page acceptance

After the sole render, require all of the following against the fresh result
HTML:

1. R 4.6.1 and Quarto 1.9.37, render exit 0, and no embedded error, warning,
   stderr, unresolved cross-reference, or raw execution trace.
2. Exactly 15 native `gt` tables and five figures in accepted source order,
   with every endpoint, caption, note, value, label, alt text, and paired
   source relationship preserved.
3. `tbl-h08-formulas` contains the exact nine ordered evaluated formula
   strings in one semantic table, with no separate formula-object output.
4. Semantic-hook disposition `REPAIRED` or an independently justified
   already-repaired disposition. Retain the external summary and complete
   reversible ledger. Require unique document IDs and every explicit
   `headers` token to resolve exactly once to its intended `th` inside its own
   table. Reverse the ledger in a temporary copy and require the recorded
   pre-hook identity.
5. Preserve the Answer in brief callout, mixed effect scales, exact samples,
   eight complete FDR families, primary near-eye and complementary chest
   hierarchy, model-check and sensitivity qualifications, and the conclusion
   that no association retained FDR-adjusted support.
6. Preserve all 26 unique relative targets, the reciprocal companion target,
   DEV-035 and DEV-036 anchors, active navigation, and country-coded sites.
7. Run the new order-specific verifier against the fresh HTML. Preserve and do
   not execute or edit either historical H08 report test.
8. Preserve every accepted input, source CSV, durable figure, test, historical
   manifest, held companion QMD and HTML, profile, hook, engine, lockfile,
   central ledger, preceding H07 endpoints, and unrelated build member
   byte-for-byte.
9. Classify the complete build delta. Only the H08 result HTML, normal
   target-owned source-identical resource copies, and expected search or
   sitemap integration changes may change. Any target-regenerated display
   requires deterministic same-source and visible-content verification.
10. Keep `audit/report_harmonization/phase4_corpus_manifest.csv`
    byte-identical. Its H08 HTML row becomes one expected historical-to-fresh
    transition until later integration. Verify navigation and links directly
    against the fresh page.

The five accepted result PNGs remain immutable. Their deferred baked wording
is not a request for a display-refresh loop under the author's render-
completion priority. Inspect the actual rendered figures fully and report a
genuine scientific or readability defect if one exists. Do not reopen a
language or cosmetic cleanup pass.

## Secure loopback visual QA

Only after all nonvisual checks pass, serve exactly `_build/nathealth` from one
temporary read-only server bound only to `127.0.0.1`. Inspect only the H08
result route at 1440 by 1000, 708 by 1000, and a 720 by 500
200-percent-equivalent view.

Inspect the complete reader flow, all 15 tables, all five figures, callouts,
headings, captions, links, navigation, wrapping, disclosures, axes, legends,
symbols, site codes, clipping, overlap, and page overflow. Inspect every
exported figure at its intended 170-mm final size and require essential text
of at least 7 points. A genuinely wide table may use a visible contained
horizontal scroller at narrow width if it does not create page-level overflow.

Stop the server immediately after QA. Prove that neither its process nor a
listener remains, reset the viewport, close the QA tab, and rehash the source,
profile, result target, held companion, complete build, and protected
inventories.

## Return and hold

Return one complete acceptance package or one consolidated fail-closed defect
list. Do not patch or rerender within this order. Do not open another language
or cosmetic cleanup loop. Retain semantic evidence until independent
acceptance.

No H08 companion render or later target is released. No source, test,
historical or current manifest, scientific artifact, profile, ledger,
package, lockfile, commit, push, upload, or publication change is authorized.
