# REPORT-018 order 59: H10 companion no-rerender integration completion

Date: 2026-08-22

Owner: `019fdc1b-b77b-7972-aed0-784da328e115`

Status: `AUTHORIZED_ONCE_NO_RERENDER`

## Purpose and controlling disposition

Complete H10 result-and-companion integration without another render. The result page is independently accepted. During the coordinator's isolated companion preflight, the target resolved from the live project and exactly one H10 companion render completed. That render is the consumed companion render. It produced a structurally valid fresh page and complete semantic evidence, but the H10 helper, preparation test, and browser QA have not run.

This order preserves the fresh HTML and permits only the exact current-contract helper/test transitions, one helper execution, one preparation-test execution, static verification, secure-loopback visual QA, and a non-circular completion or stopped seal.

Controlling records:

- `audit/report_harmonization/report018_h10_result_independent_acceptance.md`, SHA-256 `ca9cfdfcb14283d0b6a6b969be46f28c7c104272264bb2e29f466b7f2ff09450`.
- `audit/report_harmonization/report018_h10_result_independent_acceptance_manifest.csv`, SHA-256 `5ad1bdde6140a3b1b7280b2d8759ade989fd55a59f7765f56ff909e1e6fd59df`, 23 rows.
- `audit/report_harmonization/report018_h10_companion_preflight_execution_path_disposition.md`, SHA-256 `7c535e9d71509ec1709c6c88a448dbfac8595c2e4964139e589107bccda19c33`.
- `scripts/report_harmonization/check_h10_order58a_result_and_companion_preflight.R`, SHA-256 `ad039d13d4e0ec5dfc1538016bd14bba563af8c4a4125b04faa6937e1fb36074`.
- `audit/report_harmonization/report018_h10_companion_preflight/independent_preflight_checks.csv`, SHA-256 `0b0dcfefc484036498cda1def0d0a78b8835dcfcbc51e2bdd38a9423f2124c66`, 12 of 12 passed.

## Mandatory preflight pins

Before changing a file, reproduce all of the following:

- result QMD `0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d`, 49,224 bytes;
- accepted result HTML `37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14`, 359,702 bytes;
- companion QMD `706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6`, 58,446 bytes;
- fresh companion HTML `dc2aa864a1b1edf01043444af425df40564779e83b72f00c206068fdba19a7b9`, 652,030 bytes;
- current helper preimage `3ec19add42cf53f4cda9dcfa24ba9cf6301f45af0b24d8e8549b2727912d5200`, 10,757 bytes;
- current preparation-test preimage `15d20f3c3fe4d5387eb64152479d07ea0e94b397b27b0a7b59b3d41c7a1924c4`, 15,201 bytes;
- current preparation manifest `091c2661020dce63826ea7a21745dd3a1328681f343ba256b04f852b9fef518c`, 170,241 bytes;
- reader test `dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af`, 25,803 bytes;
- immutable Stage 3 manifest `b556d9fdb19eeda766414bab30420846ee5c46138e9d7861f61e92da7516683e`, 147,622 bytes;
- normal profile `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`, 7,480 bytes;
- H11 QMD `7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867`, 57,462 bytes;
- semantic summary `4a3848b85d2e454dea54a2577759498953f160a1c0c43921147408a88d480682`;
- semantic ledger `f43f701108cbdf5cdc9e62a2a2e231a6a00dd5e99ddc3700d03c4dd96de0324b`;
- obsolete source-side `audit/hypotheses/H10/H10_analysis_preparation.html` remains absent;
- no active H10, Quarto, Pandoc, semantic-hook, or loopback process.

Audit the full dispatch manifest before mutation. Stop if any hard pin differs.

## Exact write boundary

Only these existing files may change:

1. `scripts/hypotheses/H10/build_h10_preparation_report_manifest.R`
2. `tests/hypotheses/H10/test_h10_preparation_report.R`
3. `_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.qmd`
4. `artifacts/12_manifests/H10/H10_preparation_report_manifest.csv`

New evidence may be written only below:

`audit/hypotheses/H10/report018_order59_companion_no_rerender_completion/`

The build QMD and current manifest may change only through the single authorized helper execution. The source-side HTML must remain absent. No other existing path may change.

## Exact helper transition

Replace only `scripts/hypotheses/H10/build_h10_preparation_report_manifest.R` with the accepted postimage stored at:

`audit/report_harmonization/report018_h10_companion_preflight/prospective_build_h10_preparation_report_manifest.R`

Required postimage: SHA-256 `292ad3335dac8241f317983d5017a5a1d5dbce51fef245d2c30889cf4a3dcf97`, 10,437 bytes.

The change removes only the obsolete source-side standalone HTML declaration, existence check, inventory row, and required-path row. It retains authoring-to-build QMD synchronization and every other manifest contract. Prove the exact reverse to preimage `3ec19add42cf53f4cda9dcfa24ba9cf6301f45af0b24d8e8549b2727912d5200`. R 4.6.1 parse and Air 0.4.1 must pass.

## Exact preparation-test transition

Replace only `tests/hypotheses/H10/test_h10_preparation_report.R` with the accepted postimage stored at:

`audit/report_harmonization/report018_h10_companion_preflight/prospective_test_h10_preparation_report.R`

Required postimage: SHA-256 `8b206d4cf565b6f5a767e6e99afb9e587db8255f2239cb3761eebaa8e69d1608`, 17,039 bytes.

The postimage:

- retains strict current source/build-QMD identity, profile adjacency, live-manifest, no-model-call, stored-output, endpoint, semantic, source-data, sample, model, multiplicity, diagnostic, figure-readability, reciprocal-navigation, and privacy contracts;
- checks dynamic `.qmd` source links while retaining rendered `.html` link and pagination checks;
- replaces the complete stale terminology set with exact accepted current wording for the 720-minute MDER threshold, shared general coverage rules, gap-timing-unaware construction, biological-sex and separate unanalysed-gender variables, complete 17-metric families, current MDER and L10 normalization, the repaired missing gap-MDER day, Preparation 06 provenance, and the preregistered age-and-gender quote;
- does not change a source QMD or scientific expectation.

Prove the exact reverse to preimage `15d20f3c3fe4d5387eb64152479d07ea0e94b397b27b0a7b59b3d41c7a1924c4`. R 4.6.1 parse and Air 0.4.1 must pass.

## Single helper and test executions

After both exact postimages are in place:

1. Run `scripts/hypotheses/H10/build_h10_preparation_report_manifest.R` exactly once under R 4.6.1 with the normal project library.
2. Require the build QMD to become byte-identical to the authoring QMD at SHA-256 `706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6`.
3. Require a 269-row preparation manifest with unique paths, no circular self-row, all members live-exact, all environment fields populated, and no obsolete source-side HTML row. The preview is `audit/report_harmonization/report018_h10_companion_preflight/prospective_preparation_report_manifest_preview.csv`, SHA-256 `440ad63b3a540c11c3ca86bf912399b9773167d1aac09b90a757708cb4424238`.
4. Run `tests/hypotheses/H10/test_h10_preparation_report.R` exactly once under R 4.6.1 in its default strict mode.
5. Require the terminal PASS message for 19 `gt` tables, two descriptive figures, and 68 frozen frames.

No preliminary helper or preparation-test execution is permitted. No retry is permitted.

## Static and semantic completion

Against the preserved companion HTML, require:

- exactly one `main#quarto-document-content`;
- 19 native `gt` tables and two exact figure endpoints in immutable source order;
- one top-down Mermaid diagram;
- zero duplicate document IDs;
- all 1,050 `headers` tokens resolving exactly once to intended scoped `th` cells within their own table;
- exact semantic raw reversal to `c3014cafdd8a1d0906c7f570de8bd6f979a70153c9b83175e47a27703ca7c1b6` and reapplication to current HTML;
- all current construct, coverage, provenance, model, multiplicity, diagnostic, and limitation statements required by the accepted test;
- no embedded errors, warnings, unresolved references, or false construct wording;
- all local links and fragments resolve, including reciprocal result links and registration-record anchors;
- active navigation and country-coded sites;
- all 57 scientific assets remain exact.

Relative to the accepted result-page build inventory, require exactly five build transitions after helper completion:

1. the source-identical H10 Stage 3 manifest build copy;
2. the source-identical H10 companion build QMD;
3. the accepted companion HTML;
4. `search.json`;
5. `sitemap.xml`.

No build symlink or additional build delta is permitted.

Relative to the accepted 150-row protected inventory, require exactly four classified changes: removal of the obsolete source-side HTML, the exact helper postimage, the exact preparation-test postimage, and the truthful 269-row current manifest transition. All other protected rows must remain exact.

## Secure-loopback visual QA

Serve only `_build/nathealth` on an available port bound to `127.0.0.1`. Inspect the existing companion HTML at:

- 1440 by 1000;
- 708 by 1000;
- 720 by 500 as the 200-percent-equivalent view;
- exact 170-mm display widths for both exported figures.

Inspect the full reader flow, all 19 tables, both figures, the Mermaid diagram, callouts, headings, captions, notes, axes, legends, links, navigation, country labels, and any narrow table scrollers. Require no clipping, overlap, missing content, broken scroller, page-level horizontal overflow, or page-attributable console error. Record screenshots and observations. Close QA tabs, reset the viewport, stop the server, and prove no listener remains.

Run a read-only post-QA audit and require the HTML, semantic evidence, build inventory, protected inventory, accepted result, QMDs, profile, scientific assets, and H11 source to remain unchanged across QA.

## Prohibitions

Do not invoke Quarto, knitr, Pandoc, or the semantic hook. Do not rerender any page. Do not edit or execute either QMD. Do not restore the obsolete source-side HTML. Do not run a model, prediction, bootstrap, simulation, sensitivity analysis, scientific builder, broad manifest builder, package operation, or lockfile operation. Do not edit scientific artifacts, the accepted result, the profile, shared configuration, ledgers, historical manifests, H11, or any later target. Do not commit, push, upload, or delete historical evidence.

## Completion or stop

On complete PASS, write one concise completion record and one exact, unique, non-circular owner manifest in the authorized evidence directory. Return all final hashes, row counts, static checks, semantic checks, visual observations, lifecycle checks, and classified deltas for independent acceptance.

On any new mismatch or page defect, stop once, preserve the current HTML and all evidence, and return one consolidated fail-closed record. Do not patch or retry.
