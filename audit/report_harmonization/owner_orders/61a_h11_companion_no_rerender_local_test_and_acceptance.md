# REPORT-018 owner order 61a: H11 companion no-rerender local test and acceptance

Date: 2026-08-22

Owner: H11 task `019fba59-0f3c-74a0-ab3d-58d389365ad1`

Scope: one H11-local preparation-test correction, one direct manifest-row
reseal, one test execution, and completion of companion static and visual QA

Status: `SEALED_FOR_ONE_DISPATCH`

## Authority

Order 61 is independently accepted at a rendered no-rerender stop under
`audit/report_harmonization/report018_h11_order61_rendered_stop_independent_acceptance.md`.
The single H11 companion render is consumed and must not be repeated. The
fresh companion HTML remains fixed at
`58518d708e4feb6145bd0beb773b6b9ae4937afdf4a9e44e19d4215d9ca86162c`,
771,221 bytes.

The complete independent R 4.6.1 replay passes after replacing only the final
generic verification call in the H11 preparation test with equivalent strict
H11-local rendered integration checks. No page, source, scientific, semantic,
manifest, helper, build, or environment defect remains.

Keep `audit/report_harmonization/coordination_matrix.csv` byte-identical at
SHA-256
`c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac`,
42,552 bytes. Its retained H11 Order 60 token is a checker invariant. Record
Order 61a through a separate durable dispatch receipt and do not edit the
shared matrix.

## Mandatory preflight

Before mutation, require all of the following:

1. reproduce the non-circular Order 61a dispatch manifest exactly;
2. reproduce the independent Order 61 stopped-acceptance manifest exactly;
3. run
   `scripts/report_harmonization/check_report018_h11_order61_stop_and_no_rerender_completion.R`
   under R 4.6.1 against a fresh temporary evidence directory and require the
   exact PASS summary with eight checks, owner 44 of 44, current manifest 283
   of 283, semantic 26 plus 179 plus 801, prospective test
   `64b427b4...`/11,831, prospective manifest `bd34dbfd...`/73,184, and test
   exit 0;
4. require the result QMD/HTML
   `7909ba06...`/`2c8a34ec...`, companion source/build QMD
   `3f5a0d2e...`, companion HTML `58518d70...`, preparation test
   `4c31cb41...`, helper `317f3106...`, current manifest `3dbd9263...`,
   shared verifier `6afff45a...`, profile `80dd0557...`, lockfile
   `3bf99c63...`, and sensitivity QMD/HTML
   `d2d17770...`/`b9af89c0...` exact;
5. require all 44 owner-seal paths, all 283 current preparation-manifest paths,
   all 193 scientific assets, and all Order 61 semantic evidence exact;
6. require zero symlinks below `_build/nathealth`; and
7. require no competing H11, Quarto, Pandoc, semantic-hook, helper, or
   task-owned loopback process. Use the established narrowly elevated
   read-only process inventory if required. Leave unrelated processes alone.

Stop without mutation on any failed condition.

## Sole test correction

Edit only `tests/hypotheses/H11/test_h11_preparation_report.R`. Replace the
single final call beginning with
`verification <- verify_hypothesis_preparation_companion(` and ending with its
closing `  )` with the exact H11-local block encoded as `replacement_block` in
the independent checker.

The local block must preserve or strengthen the generic rendered-page gates:

- require at least one rendered link to
  `../../../notebooks/hypotheses/H11.html`;
- require at least one note callout and zero important, warning, caution, or
  danger callouts;
- require adjacent result and preparation entries in `_quarto-nathealth.yml`;
- require the preparation source, source-identical build QMD, fresh companion
  HTML, and profile in the current manifest;
- require H11 scripts and paired source-data members in that manifest; and
- construct the same `verification` fields from the already loaded figures,
  tables, manifest, executable calls, and byte-identical source/build QMDs.

The exact test postimage must be
`64b427b4bc11f79a1ea2cd539eee7e30184271ef05cbba7b3f511a2f105a15a3`,
11,831 bytes. Require R 4.6.1 parse, Air 0.4.1 format check, scoped whitespace
PASS, and exact raw reversal to
`4c31cb4120fdb0530609906df707c161b875c0859a917de61f3baa1050d24180`,
10,561 bytes. No shared verifier or other test may change.

## Sole direct manifest reseal

Do not run the helper. In
`artifacts/12_manifests/H11/H11_preparation_report_manifest.csv`, change only
the existing unique row for
`tests/hypotheses/H11/test_h11_preparation_report.R` from the fixed preimage
hash and 10,561 bytes to the exact postimage hash and 11,831 bytes. Preserve
all other fields and all other rows byte-for-byte through an exact row-level
audit. Require exactly 283 unique, non-circular, live-exact paths and exact
manifest SHA-256
`bd34dbfd6d2e929c825fe76281dfd384d8b0ef851b3d99a52b155c3216cfc6d9`,
73,184 bytes. Exact reverse of that one row must reproduce
`3dbd92632afd32d392ef7ed456dc6f61d32e58ec73b03bd8d8e3451dfcb1afe8`.

## Single complete preparation-test execution

After both exact postimages pass, run exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
Rscript --vanilla tests/hypotheses/H11/test_h11_preparation_report.R
```

Require exit 0 and the normal H11 preparation-companion PASS message. Do not
run the test a second time. Do not run the helper, Quarto, knitr, Pandoc, or
the semantic hook. On failure, stop and seal the complete state.

## Complete static and semantic verification

Only after the test passes, verify against the preserved current HTML:

1. exactly one `main#quarto-document-content`, 26 native `gt` tables, three
   figure images with nonempty alt text, and one top-down Mermaid;
2. exact semantic reversal and reapplication for 179 ID, 801 `headers`, and
   980 total substitutions;
3. zero duplicate document IDs and all 1,193 scoped table-header tokens
   resolving exactly once within their own table;
4. both rendered result links, all 20 relative-link occurrences to 17 unique
   targets, and all 14 source fragments resolving;
5. zero embedded error, warning, stderr, or unresolved-reference nodes;
6. all 283 preparation-manifest rows, 193 scientific assets, accepted result
   source/HTML, companion source/HTML, Stage 3 test/manifest, REPORT-016 test,
   handoff, profile, lockfile, and sensitivity endpoints exact; and
7. only the authorized preparation-test and its direct current-manifest row
   transitions in project state. Preserve all historical evidence exactly.

## Bounded loopback QA

Only after the complete test and static checks pass, apply the active
`$quarto-authoring` procedure:

1. rehash the source, profile, HTML, and scoped build inventory;
2. require zero symlinks under `_build/nathealth`, including zero links that
   escape the served root;
3. serve only `_build/nathealth` on one unused high port bound strictly to
   `127.0.0.1` with read-only GET/HEAD behavior;
4. inspect exactly
   `/audit/hypotheses/H11/H11_analysis_preparation.html` at 1,440 by 1,000,
   708 by 1,000, and 720 by 500;
5. inspect all 26 tables, three figures, Mermaid, code disclosures, contained
   narrow scrollers, captions, alt text, navigation, reciprocal links,
   deviations, and paired source-data links;
6. inspect each figure at 642 pixels or exact 170-mm display width and require
   at least 7-point essential and minor text;
7. reject overflow, clipping, overlap, missing content, broken interaction,
   privacy leakage, or page-attributable console warning or error;
8. close or reset the QA surface, stop the server, wait for process exit, and
   prove no listener remains; and
9. require byte-identical build, protected, scientific, source, profile, HTML,
   and semantic evidence across QA.

## Writes, prohibitions, and return

Writes are limited to the one H11 preparation test, the one direct current
manifest row, and new bounded Order 61a source-diff, reverse-proof, test,
static, semantic-reuse, link, screenshot, visual-QA, lifecycle, inventory,
completion, and non-circular evidence under
`audit/hypotheses/H11/report018_order61a_no_rerender_completion/`.

No helper, Quarto command, render, QMD execution, QMD or HTML edit, semantic
rewrite, shared-verifier edit, model, estimate, interval, p-value, FDR
decision, diagnostic, scientific artifact, Stage 3 manifest, handoff, profile,
package, lockfile, sensitivity action, ledger, later target, full-project
action, commit, push, upload, or deletion of retained evidence is authorized.

Return one complete non-circular acceptance package or one combined
fail-closed stop for a genuinely new defect. The mandatory next stop is
independent H11 result-and-companion acceptance. The sensitivity battery and
all later targets remain held.
