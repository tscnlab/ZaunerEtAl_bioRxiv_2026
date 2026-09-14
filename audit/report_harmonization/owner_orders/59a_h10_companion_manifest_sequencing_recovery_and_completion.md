# REPORT-018 order 59a: H10 companion manifest-sequencing recovery and completion

Date: 2026-08-22

Owner: `019fdc1b-b77b-7972-aed0-784da328e115`

Status: `AUTHORIZED_ONCE_NO_RERENDER_RECOVERY`

## Purpose and controlling disposition

Complete H10 result-and-companion integration after the accepted Order 59 evidence-sequencing stop. The current H10 companion HTML is already rendered and semantically repaired. The sole consumed helper execution produced 275 rows because six Order 59 evidence files existed before its inventory. The preparation test and browser QA were not run.

This order preserves that 275-row manifest and all 13 current Order 59 evidence files as immutable historical evidence. It authorizes one exact helper classification, one additional helper execution, one unchanged preparation-test execution, static verification, and secure-loopback QA. It authorizes no Quarto command or page render.

Controlling records:

- `audit/report_harmonization/report018_h10_order59_stopped_independent_acceptance.md`, SHA-256 `671bfbd72a9ee14de28472929eeaad4d0a25bee1b9ffb7dfaa78ed9812a91d82`, 4,867 bytes.
- `audit/report_harmonization/report018_h10_order59_stopped_independent_acceptance_manifest.csv`, SHA-256 `c4bb9a9412370fc9d3361e1fd4b9d58d32dd7a9b2808257158868571c4f72594`, 18 rows.
- `scripts/report_harmonization/check_h10_order59_stop_and_recovery.R`, SHA-256 `65e93822940442ced7446541055c1ec33633e85ea46d9ab3676a6bd6e15c2c3d`.
- `audit/report_harmonization/report018_h10_order59_recovery_preflight/report018_h10_order59_recovery_preflight_checks.csv`, SHA-256 `66d2a7d5427ccacad8f7109ba994c31c2000c00fbe423caeac89dd6cdc967293`, 10 of 10 passed.
- exact six-row diagnosis `audit/report_harmonization/report018_h10_order59_recovery_preflight/order59_exact_six_row_diagnosis.csv`, SHA-256 `95b93f21a643f7377e0a4e9f13643368cc7e21c0159cfc0b7e1dbcce0d3845cd`.
- exact 13-row exclusion set `audit/report_harmonization/report018_h10_order59_recovery_preflight/order59_historical_evidence_exclusions.csv`, SHA-256 `5806b0381238770fd099d990543978d7373a23d1cadfd5310a54859a6e4e01c3`.
- isolated 269-row replay manifest `audit/report_harmonization/report018_h10_order59_recovery_preflight/isolated_recovery_manifest.csv`, SHA-256 `08642e6e290e253340c414df1e0497619b4717374032bcc168667a955a5772e6`.
- isolated execution and visual records SHA-256 `a1598d5354786dc7de0c316cf44794e0b3b3cd0a7e94468348b51e543048e6ef` and `9ae5498b20da1fdbb9a3d0d448545e0761f6a77eafedd671f1695efab5571579`.

Fresh R 4.6.1 replay reports:

`REPORT018_H10_ORDER59_RECOVERY_PREFLIGHT=PASS owner=31/31 six=6/6 historical=13/13 manifest=269/269 test=PASS tables=19 figures=2 headers=1050 visual=10/10 R=4.6.1`

## Mandatory preflight pins

Before changing a file, reproduce all of the following:

- Order 59 stop record `71091cdfbf73cdf837062da4eb9491f1f7858fd118c27f9e74bd4e10e0e189ab`;
- Order 59 31-row non-circular seal `841fd913ca48bee3c56461b9815dcf89664f72563c3d8bacfff81d151d594ea5`, 31 of 31 live-exact;
- current 275-row manifest `056d875d4459c52fef87d2c1895da8d157558c3097187fe77aac8aa21005b19c`, 205,083 bytes, unique and 275 of 275 live-exact;
- current helper `292ad3335dac8241f317983d5017a5a1d5dbce51fef245d2c30889cf4a3dcf97`, 10,437 bytes;
- unchanged preparation test `8b206d4cf565b6f5a767e6e99afb9e587db8255f2239cb3761eebaa8e69d1608`, 17,039 bytes;
- result QMD `0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d`, 49,224 bytes;
- accepted result HTML `37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14`, 359,702 bytes;
- companion authoring and build QMD `706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6`, 58,446 bytes each;
- fresh companion HTML `dc2aa864a1b1edf01043444af425df40564779e83b72f00c206068fdba19a7b9`, 652,030 bytes;
- reader test `dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af`, 25,803 bytes;
- semantic summary `4a3848b85d2e454dea54a2577759498953f160a1c0c43921147408a88d480682`;
- semantic ledger `f43f701108cbdf5cdc9e62a2a2e231a6a00dd5e99ddc3700d03c4dd96de0324b`;
- normal profile `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`, 7,480 bytes;
- H11 source `7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867`, 57,462 bytes;
- obsolete source-side `audit/hypotheses/H10/H10_analysis_preparation.html` absent;
- no active H10, Quarto, Pandoc, semantic-hook, or loopback process.

Run the central checker once before mutation and require its exact PASS message. Audit the complete dispatch manifest before mutation. Stop if any hard pin differs.

## Chronological evidence rule

Do not create a new file anywhere below `audit/hypotheses/H10/` before the additional helper execution completes and its 269-row output passes the immediate gate.

Store pre-helper command output and inventories only in one fresh `/private/tmp/H10-order59a-preflight.XXXXXX` directory. Record its path. After the helper gate passes, create the new durable evidence root:

`audit/hypotheses/H10/report018_order59a_companion_recovery_completion/`

Copy or regenerate the bounded preflight records into that root only after the helper inventory. This ordering is part of the acceptance contract.

## Exact existing-file write boundary

Only these existing files may change:

1. `scripts/hypotheses/H10/build_h10_preparation_report_manifest.R`
2. `_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.qmd`, only through the helper's source-identical copy and with no byte transition
3. `artifacts/12_manifests/H10/H10_preparation_report_manifest.csv`

The preparation test remains byte-identical. No existing evidence file may change. New evidence is permitted only under the post-helper evidence root specified above.

## Exact helper transition

Replace the current helper byte-for-byte with:

`audit/report_harmonization/report018_h10_order59_recovery_preflight/prospective_build_h10_preparation_report_manifest.R`

Required postimage: SHA-256 `26619260657ec0cb1d7ac7614af9e3e349a524ee242dd5645b27e31f4cb142f0`, 11,294 bytes.

The sole new contract is an exact 13-path historical-evidence exclusion. The helper must:

- require all 13 sealed Order 59 evidence files to exist;
- exclude exactly the paths in `order59_historical_evidence_exclusions.csv`;
- exclude no other H10 audit path;
- preserve every other helper expression and inventory rule.

Removing this exact block must reconstruct current helper SHA-256 `292ad3335dac8241f317983d5017a5a1d5dbce51fef245d2c30889cf4a3dcf97` and 10,437 bytes. R 4.6.1 parse and Air 0.4.1 must pass. Do not format or edit another file.

## One additional helper execution

After the exact helper postimage is installed, run it exactly once under R 4.6.1 with `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE` and the accepted R 4.6.1 library. No preliminary helper execution and no further retry are permitted.

Require immediately:

- terminal message `H10 preparation-report manifest completed: 269 current files`;
- source and build companion QMDs remain byte-identical at `706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6`;
- exactly 269 unique manifest rows;
- the path set equals the sealed 269-row preview exactly;
- all 269 rows are live-exact after resolving the helper row through the installed postimage;
- the helper row is the only identity difference from the earlier preview;
- no row names the manifest itself;
- no row names an Order 59 historical evidence path;
- no new H10 evidence path existed when the helper enumerated files.

If this gate fails, stop and seal without a helper retry.

Only after this gate passes may the new owner evidence root be created.

## One unchanged preparation-test execution

Run `tests/hypotheses/H10/test_h10_preparation_report.R` exactly once under R 4.6.1 in strict default mode. Require the terminal PASS message for 19 `gt` tables, two descriptive figures, and 68 frozen frames.

Do not edit, replace, format, or run the preparation test before the helper gate. Do not rerun it after a failure.

## Static, semantic, link, and protection completion

Against the preserved companion HTML, require:

- exactly one `main#quarto-document-content`;
- 19 native `gt` tables and two exact figure endpoints in source order;
- one top-down Mermaid diagram;
- zero duplicate document IDs;
- all 1,050 table-header tokens resolving exactly once to intended scoped header cells;
- exact raw semantic reversal and exact reapplication to current HTML;
- all current construct, coverage, provenance, model, multiplicity, diagnostic, and limitation statements;
- zero embedded error, warning, or unresolved-reference node;
- all 23 required local links resolving, including six required fragments, reciprocal result links, and registration-record anchors;
- active navigation and all country-coded sites;
- all 57 scientific assets exact.

Relative to the sealed Order 59 stopped state, the complete build inventory must remain byte-identical. The helper may rewrite the build QMD only to the same bytes. The four already classified target-owned build transitions in `independent_build_delta.csv` remain historical and unchanged.

Relative to the sealed Order 59 stopped protected inventory, exactly the helper and current preparation manifest may change. The current preparation test, both QMDs, both accepted HTMLs, semantic evidence, result reader test, profile, scientific artifacts, H11, and every historical record remain exact. New post-helper owner evidence is accounted separately and may not be inserted into the preparation manifest.

## Secure-loopback visual QA

Serve only `_build/nathealth` on an available port bound to `127.0.0.1`. Inspect the existing companion page at:

- 1440 by 1000;
- 708 by 1000;
- 720 by 500 as the 200-percent-equivalent view;
- exact 642-pixel 170-mm-equivalent widths for both exported figures.

Inspect the complete reader flow, all 19 tables, both figures, the Mermaid diagram, callouts, headings, captions, notes, axes, legends, links, navigation, country labels, and any narrow scrollers. Require no clipping, overlap, missing content, broken scroller, page-level horizontal overflow, or fresh page-attributable console warning or error.

Close all QA tabs, reset the viewport, stop the server, and prove no listener remains. Run one read-only post-QA audit. Require the HTML, semantic evidence, build inventory, accepted result, QMDs, test identities, profile, scientific assets, H11 source, and 269-row manifest to remain unchanged across QA.

## Prohibitions

Do not invoke Quarto, knitr, Pandoc, or the semantic hook. Do not render or rerender any page. Do not edit or execute either QMD. Do not restore the obsolete source-side HTML. Do not change the preparation test, reader test, result, companion HTML, scientific artifacts, model, estimate, interval, p-value, FDR decision, diagnostic, profile, shared configuration, package, lockfile, ledger, historical manifest, H11, or later target. Do not run a scientific builder, broad manifest builder, model, prediction, bootstrap, simulation, or sensitivity analysis. Do not commit, push, upload, or delete historical evidence.

## Completion or stop

On complete PASS, write one concise completion record and one exact, unique, non-circular owner manifest under the post-helper evidence root. Include the exact 13-path exclusion, helper reverse proof, one helper execution, one preparation-test execution, 269-row manifest audit, semantic/static/link/protected/build checks, visual observations, and listener teardown.

On any genuinely new mismatch or page defect, stop once and return one consolidated fail-closed record. Do not patch or retry.

H11 and every later target remain held pending independent H10 companion acceptance.
