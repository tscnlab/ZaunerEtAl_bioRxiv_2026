# REPORT-018 H09 result-page central concurrence and serial release

Date: 2026-08-21

Disposition: **RELEASED FOR EXACTLY ONE H09 RESULT RENDER**

The independently accepted H08 result and companion integration clears the
serial render gate. This release applies only to the H09 result page. The H09
companion and every later REPORT-018 render remain held pending separate
independent result acceptance.

## Controlling acceptance and current pins

The preceding serial acceptance is:

- `audit/report_harmonization/report018_h08_companion_independent_acceptance.md`,
  SHA-256
  `beacb92b41ee7f142bf95b8e2fb53cf8e8595ba3339d99c8277c53b5e1bbc816`;
  and
- its 30-row non-circular manifest, SHA-256
  `d84f7bda237c29ce73eb465a8d521dad920fb0bff499c5e0244931bc4c699297`.

The released H09 pins are:

- result QMD `notebooks/hypotheses/H09.qmd`, SHA-256
  `c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6`,
  36,970 bytes;
- held companion QMD
  `audit/hypotheses/H09/H09_analysis_preparation.qmd`, SHA-256
  `7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46`,
  47,901 bytes;
- stale result HTML `_build/nathealth/notebooks/hypotheses/H09.html`,
  SHA-256
  `ce6c4c644af675e5feb25dcbc834b55c3ddfc87ec3dc581c95366edc0de067b1`,
  229,798 bytes;
- held companion HTML
  `_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html`,
  SHA-256
  `4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05`,
  593,181 bytes; and
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
`scripts/report_harmonization/check_h09_result_report018_release.R`, SHA-256
`2e4046aa949b3a4ef8ef428c4bfd02a3ecd9b7c54a3fee1703f0f527aa4363b7`,
passed under R 4.6.1 after Air 0.4.1 and R parse checks. Its 42-row pin input is
`audit/report_harmonization/report018_h09_result_release_pins.csv`, SHA-256
`d65f20daa2ec1955aaa48bcdf7a9ec6c4e98c84c444a5d24348fe807a1578947`.

Fresh verification passed:

- 42 of 42 exact, unique release pins;
- 17 parseable R chunks, 11 native `gt` table endpoints, and four figure
  endpoints in accepted source order;
- exactly 23 relative link occurrences and 21 unique reader or source-data
  targets, with DEV-037, DEV-038, and DEV-039 resolving and IMP-009 absent;
- all five accepted Wilkinson formula literals;
- zero fit, refit, prediction, simulation, bootstrap, p-value recalculation,
  or artifact-writing calls;
- 20 primary model rows, eight complete five-member FDR families, six
  near-eye and four chest adjusted-significant rows, and zero
  adjusted-significant interactions;
- the accepted near-eye first-above-250 MCTQ and MEQ estimates, intervals,
  and adjusted p-values;
- four accepted result figures with paired source data; and
- zero symlinks in `_build/nathealth`.

## Historical test and manifest classification

The unchanged Stage 3 manifest has 108 rows. Exactly 97 are live-exact. Its
11 current historical transitions are the accepted changes to the shared H09
handoffs and gate, figure-readability decision, two model-data audits, metric
registry, result QMD, contract, Stage 2 runner, and shared profile. The exact
path set is frozen in the central checker. The historical manifest must remain
byte-identical. After the render, its result-HTML row becomes the twelfth
expected historical-to-live transition. Every other row must remain exact.

The unchanged H09 reader test is a pre-harmonization historical contract. It
still checks reader-facing `BH-adjusted` language, while the accepted current
source uses FDR wording. Preserve the test byte-for-byte and do not execute it
in this result-only order. The held preparation test also remains unexecuted.
Use a new order-specific verifier under the evidence directory to enforce the
accepted current source and rendered-page contract.

This classification does not waive any scientific value, formula, link,
semantic, table, figure, source-data, or reader-page requirement.

## Sole authorized render

After reproducing every non-matrix hard pin, completing pre-render build and
protected inventories, confirming zero build symlinks and no competing render
process, and creating one fresh empty absolute semantic-evidence directory
under `/private/tmp`, run exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> \
quarto render notebooks/hypotheses/H09.qmd --profile nathealth
```

The narrow elevated filesystem access already established for the existing
user-owned Quarto and R caches is authorized for this command. Do not change
`HOME`, reset or redirect a cache, install or restore packages, bypass the
profile or semantic hook, render the companion, render another page, or
render the full project. If startup fails before QMD execution, stop once with
complete environment evidence. Do not retry.

The page may read accepted stored tables, source CSVs, registries, and figures
and format their frozen values. It must not fit or refit a model, predict,
bootstrap, simulate, resample, recalculate p-values, change a classification,
or rebuild a scientific artifact.

## Required result-page acceptance

After the sole render, require all of the following against the fresh result
HTML:

1. R 4.6.1 and Quarto 1.9.37, render exit 0, and no embedded error, warning,
   stderr, unresolved cross-reference, or raw execution trace.
2. Exactly 11 native `gt` tables and four figures in accepted source order,
   with every endpoint, caption, note, value, label, alt text, and paired
   source relationship preserved.
3. `tbl-h09-formulas` contains the exact five ordered evaluated Wilkinson
   formulas in one semantic table, with no separate formula-object output.
4. Semantic-hook disposition `REPAIRED` or an independently justified
   already-repaired disposition. Retain the external summary and complete
   reversible ledger. Require unique document IDs and every explicit
   `headers` token to resolve exactly once to its intended `th` inside its own
   table. Reverse the ledger in a temporary copy and require the recorded
   pre-hook identity.
5. Preserve the Answer in brief callout, exact samples, the primary near-eye
   and complementary chest hierarchy, eight complete FDR families, the
   accepted adjusted-significance counts, interaction conclusion, qualified
   diagnostics, gap-timing-unaware sensitivities, and non-causal wording.
6. Preserve all 23 link occurrences and 21 unique relative targets, the
   reciprocal companion target, DEV-037 through DEV-039 anchors, active
   navigation, and country-coded sites.
7. Run the new order-specific verifier against the fresh HTML. Preserve and do
   not execute or edit either historical H09 report test.
8. Preserve every accepted input, source CSV, durable figure, test, historical
   manifest, held companion QMD and HTML, profile, hook, engine, lockfile,
   central ledger, preceding H08 endpoints, and unrelated build member
   byte-for-byte.
9. Classify the complete build delta. Only the H09 result HTML, normal
   target-owned source-identical resource copies, and expected search or
   sitemap integration changes may change. Any target-regenerated display
   requires deterministic same-source and visible-content verification.
10. Keep `audit/report_harmonization/phase4_corpus_manifest.csv`
    byte-identical. Its H09 HTML row becomes one expected
    historical-to-fresh transition until later integration. Verify navigation
    and links directly against the fresh page.

## Secure loopback visual QA

Only after all nonvisual checks pass, serve exactly `_build/nathealth` from one
temporary read-only server bound only to `127.0.0.1`. Inspect only the H09
result route at 1440 by 1000, 708 by 1000, and a 720 by 500
200-percent-equivalent view.

Inspect the complete reader flow, all 11 tables, all four figures, callouts,
headings, captions, links, navigation, wrapping, disclosures, axes, legends,
symbols, site codes, clipping, overlap, and page overflow. Inspect every
exported figure at its intended 170-mm final size. The historical figure
manifest records effective essential-text values from 5.10 to 6.69 points,
so this order must make a fresh reader-facing final-size assessment rather
than treating the historical status as sufficient. Require actual essential
text to meet the accepted 7-point floor. If it does not, return one
consolidated fail-closed readability finding without patching or rerendering.
A genuinely wide table may use a visible contained horizontal scroller at
narrow width if it causes no page-level overflow.

Stop the server immediately after QA. Prove that neither its process nor a
listener remains, reset the viewport, close the QA tab, and rehash the source,
profile, result target, held companion, complete build, and protected
inventories.

## Return and hold

Return one complete acceptance package or one consolidated fail-closed defect
list. Do not patch or rerender within this order. Do not open another language
or cosmetic cleanup loop. Retain semantic evidence until independent
acceptance.

No H09 companion render or later target is released. No source, test,
historical or current manifest, scientific artifact, profile, ledger,
package, lockfile, commit, push, upload, or publication change is authorized.
