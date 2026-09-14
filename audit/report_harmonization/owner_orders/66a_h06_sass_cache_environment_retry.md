# REPORT-018 owner order 66a: H06 Sass-cache environment retry

Date: 2026-09-02

Owner: H06 task `019fbd4a-288b-7a72-ac70-2d17ba6d2f04`

Status: `SEALED_FOR_ONE_ENVIRONMENT_ONLY_RETRY`

## Authority and disposition

Order 66 is independently accepted at an environment-only stop under
`audit/report_harmonization/report018_h06_order66_environment_stop_independent_acceptance.md`.
The sole result command completed all 43 knitr steps and failed before Pandoc,
semantic repair, and HTML production because sandboxed Quarto could not open
its normal user-owned Sass database.

This is not a source, scientific, semantic, or page defect. This order changes
only the filesystem permission boundary for one replacement execution of the
same target. The H06 preparation page and every later target remain held.

## Exact preflight

Before Quarto, the owner must:

1. reproduce every row of the Order 66a dispatch manifest by exact SHA-256 and
   byte count;
2. reproduce the 16-row independent Order 66 environment-stop acceptance
   manifest;
3. run `scripts/report_harmonization/check_h06_order66_environment_stop.R`
   under R 4.6.1 and require its exact PASS;
4. rerun
   `scripts/report_harmonization/check_h06_employment_eligibility_reader_source_acceptance.R`
   and require 46/46 sensitivity members, 31/31 report checks, both accepted
   sources, and the focused test to pass;
5. require the result QMD `5f8ec988...`, preparation QMD `5b128499...`,
   historical result HTML `bf3f7011...`, held preparation HTML `ae3dd53c...`,
   profile `e54c7179...`, and lockfile `3bf99c63...` exact;
6. require all 889 current build files totalling 373,232,508 bytes, zero build
   symlinks, no `H06.knit.md`, and the first failed semantic directory still
   empty;
7. require the existing Sass database
   `/Users/zauner/Library/Caches/quarto/sass/sass.kv` to be user-owned, 36,864
   bytes, SHA-256
   `22f60821f5020edfa0900fc872503bbe993388c7f5acb86c059bc53dcd606853`,
   with no WAL or SHM file; and
8. use narrowly elevated read-only process inventory only if required, and
   require no competing H06, Quarto, Pandoc, semantic-hook, or project
   loopback process. Ignore and preserve unrelated R and application work.

Create one new fresh empty absolute semantic-audit directory under
`/private/tmp`. Stop before Quarto on any failed project, cache, process,
build, source, or scientific pin.

## One environment-only retry

From the project root, invoke exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-private-tmp-directory> \
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS_USER=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

Run the complete command with narrowly elevated filesystem access sufficient
for Quarto to use its existing user-owned Sass cache. Do not change `HOME`,
`XDG_CACHE_HOME`, `DENO_DIR`, the R library, autoloader setting, target, QMD,
or profile. Do not delete, clear, replace, redirect, copy, rename, chmod, or
chown a cache file. Quarto may perform only its normal transactional cache
access during this execution.

If the command fails, stop and seal the complete one-attempt state. No second
retry, alternate target, cache workaround, profile bypass, or source repair is
authorized.

## Successful-render continuation

On exit 0 with completed semantic repair, continue without another Quarto
command through the complete Order 66 post-render contract:

1. require exactly one `main#quarto-document-content`, 14 native `gt` tables,
   and six source-ordered figures;
2. verify the complete semantic summary and ledger, zero duplicate IDs, exact
   table-scoped header resolution, and raw reversal plus reapplication;
3. verify the employment-eligibility section, exact sample flow, three stored
   effects and intervals, adjusted p-values, stability wording, separate
   predictor-by-site disposition, and diagnostic qualification;
4. require the three source-CSV links to resolve to exact source-identical
   build resources, with no reader link to the unregistered sensitivity QMD;
5. run the focused reader-source test and complete existing H06 result
   contracts under their accepted REPORT-018 classifications;
6. require all scientific artifacts, sources, held preparation HTML, handoff,
   profile, and lockfile exact;
7. classify only the H06 result endpoint, normal search and sitemap updates,
   and exact target-owned source-identical resources, with no additional build
   delta and zero symlinks; and
8. record Sass-cache paths, sizes, ownership, and hashes before and after as
   environment evidence without copying cache contents into the project.

Do not patch or rerender after a post-render failure.

## Secure loopback QA

Only after complete post-render PASS:

1. repeat the zero-symlink preflight;
2. serve only `_build/nathealth` on one unused high port bound only to
   `127.0.0.1`;
3. inspect `/notebooks/hypotheses/H06.html` at 1,440 by 1,000, 708 by 1,000,
   and 720 by 500;
4. inspect all 14 tables, six figures, the new sensitivity section, scrollers,
   disclosures, captions, alt text, navigation, right-hand and collapsed
   mobile tables of contents, reciprocal preparation link, source-data links,
   and deviation links;
5. inspect exported figures at 642 pixels, the 170-mm final width, under the
   accepted text-size and no-clipping contracts;
6. reject page overflow, clipping, overlap, missing content, broken
   interaction, unresolved link, or page-attributable console warning or
   error; and
7. close or reset the QA surface, stop the server, prove no listener remains,
   and require byte-identical build and protected inventories across QA.

## Writes, prohibitions, and return

On success, writes are limited to the canonical H06 result HTML and ordinary
target-owned resources, normal search and sitemap updates, the fresh external
semantic directory, and new bounded non-circular Order 66a execution,
semantic, reconciliation, screenshot, visual-QA, lifecycle, and completion
evidence under an H06-owned Order 66a evidence directory.

No QMD, source, test, helper, historical manifest, handoff, preparation page,
profile, package, lockfile, model, estimate, interval, p-value, FDR decision,
diagnostic, source data, scientific artifact, H06_daily file, manuscript,
shared configuration, ledger, companion render, later target, full-project
render, commit, push, or upload may change.

Return one non-circular completion or fail-closed package. The mandatory next
stop is independent H06 result acceptance or the complete single-retry
environment failure.
