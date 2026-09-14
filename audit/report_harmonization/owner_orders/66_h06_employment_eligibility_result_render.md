# REPORT-018 owner order 66: H06 employment-eligibility result render

Date: 2026-09-02

Owner: H06 task `019fbd4a-288b-7a72-ac70-2d17ba6d2f04`

Status: `SEALED_FOR_ONE_RESULT_ONLY_DISPATCH`

## Authority and scope

The H06 employment-eligibility reader-source integration is independently
accepted at
`audit/report_harmonization/report018_h06_employment_eligibility_reader_source_independent_acceptance.md`.
This order releases exactly one render of the H06 result source. The H06
preparation page, H06_daily, and every later target remain held.

No source edit is authorized. This is a stored-output reader integration. No
model fit or refit, prediction, contrast, p-value or FDR calculation,
simulation, resampling, scientific artifact generation, or sample change is
authorized.

## Hard preflight

Before any Quarto command:

1. reproduce every row of the non-circular dispatch manifest by exact SHA-256
   and byte count;
2. run
   `scripts/report_harmonization/check_h06_employment_eligibility_reader_source_acceptance.R`
   under R 4.6.1 with the accepted project library and require its exact PASS;
3. require result QMD
   `5f8ec988d680e1a3e3dbf2410f0d4e6a49ded80a9990b3a09661aebdc98cbd4e`
   and held preparation QMD
   `5b128499a1f1a9312089ec47dfd1ba30cebb2a31059608659c0aa464753abfa0`;
4. require the focused source test `aa3031f9...`, the accepted 46-member
   sensitivity manifest `aa820c8d...`, all 31 report checks, and the complete
   stored sample, association, comparison, and heterogeneity inputs exact;
5. require current historical result HTML `bf3f7011...`, held preparation HTML
   `ae3dd53c...`, navigation profile `e54c7179...`, and lockfile `3bf99c63...`;
6. parse all result R chunks without executing them and require exactly 14
   unique `tbl-*` endpoints and six unique `fig-*` endpoints in source order;
7. snapshot complete build and protected inventories, require zero symlinks
   under `_build/nathealth`, and require no competing H06, Quarto, Pandoc,
   semantic-hook, or loopback process; and
8. create one fresh empty absolute semantic-audit directory outside the
   project and evidence trees.

Stop before rendering on any additional drift. Do not patch a source, test,
helper, manifest, handoff, profile, package, lockfile, or scientific artifact.

## Sole target render

From the project root, run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-private-tmp-directory> \
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS_USER=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

Use R 4.6.1, Quarto 1.9.37, knitr, the accepted navigation profile, and the
configured semantic hook. Do not activate the project autoloader, bypass the
profile, run another target, or render a second time. If startup, knitr,
Pandoc, semantic repair, or target production fails, terminate related
processes, preserve evidence, and return one fail-closed stop without retry.

## Complete post-render verification

Before browser QA, verify all of the following against the fresh canonical
HTML:

1. exactly one `main#quarto-document-content`, 14 native `gt` tables, and the
   exact six source-ordered figure endpoints;
2. the configured semantic hook completed with a nonempty summary and ledger,
   zero duplicate document IDs, and every scoped `headers` token resolving
   exactly once to its intended header within the same table;
3. exact raw-HTML reversal and reapplication of the semantic ledger;
4. every table and figure has its source-defined endpoint, caption, and
   accessible text where applicable, with zero embedded error or warning node;
5. the new employment-eligibility section and table show the exact accepted
   primary and restricted samples, three stored effects, three confidence
   intervals, adjusted p-values, stability wording, and the separate
   predictor-by-site disposition;
6. the three declared source-CSV links resolve to source-identical build
   resources, and no link targets the unregistered standalone sensitivity
   QMD;
7. the focused reader-source test and the complete existing H06 result
   contracts pass under their accepted REPORT-018 classifications;
8. all scientific artifacts, result source, held preparation source and HTML,
   handoff, profile, package state, and lockfile remain exact; and
9. build changes are confined to the H06 result endpoint, site search and
   sitemap outputs, and exact source-identical resources declared by this
   target. Fail on any unclassified added, removed, or content-changed path.

Do not patch, run a broad builder, edit a historical manifest or test, or
rerender after a post-render failure.

## Secure loopback QA

Only after complete post-render verification passes:

1. repeat the zero-symlink audit of `_build/nathealth`;
2. serve only `_build/nathealth` on one unused high port bound only to
   `127.0.0.1`;
3. inspect `/notebooks/hypotheses/H06.html` at 1,440 by 1,000, 708 by 1,000,
   and 720 by 500 as the 200-percent-equivalent view;
4. inspect all 14 tables and six figures, including contained narrow table
   scrollers, disclosures, captions, alternate text, the new sensitivity
   section, navigation shell, right-hand `On this page` panel, collapsed
   mobile table of contents, reciprocal preparation link, source-data links,
   and deviation links;
5. inspect exported figures at 642 pixels, the 170-mm final width, and retain
   the accepted minimum essential-text and no-clipping contracts;
6. require no page-level horizontal overflow, overlap, missing content,
   broken interaction, unresolved fragment, or page-attributable console
   warning or error; and
7. close or reset the browser surface, stop the server, prove no listener
   remains, and rehash the build and protected inventories.

Require byte-identical inventories across QA except for no path. Run the exact
post-QA no-drift equivalent of the post-render checks.

## Return boundary

Return one non-circular completion manifest and acceptance record, or one
consolidated fail-closed record. Record R, Quarto, and consequential package
versions; the single render command and status; semantic summary, ledger,
reversal, build delta, protected delta, link audit, visual observations,
screenshots, server lifecycle, and no-listener proof.

No H06 preparation render, H06_daily action, later target, full-project render,
source repair, analysis, scientific regeneration, profile or shared-config
change, package or lock change, manuscript edit, coordination-ledger edit,
commit, push, or upload is authorized.
