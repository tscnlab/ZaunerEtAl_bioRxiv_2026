# REPORT-017 order 32g: final H01 scalar-safe geometry continuation

Date: 2026-08-15

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: authorized for one consolidated continuation

## Purpose

Continue the already authorized H01 result-page display repair from the independently accepted order 32f stop. Make one scalar-safe correction to the candidate geometry validator, then complete one fresh candidate validation, one durable six-target replacement, direct current-manifest resealing, exactly one H01 result render, semantic verification, and the complete visual-QA package. Do not split this order.

The scientific H01 result and preparation sources remain accepted. This order repairs only display-validation infrastructure and the already approved display artifacts. It does not authorize a model, estimate, interval, p-value, diagnostic, sample, claim, or source-data change.

## Controlling accepted state

- Independent order 32f stopped-state acceptance: `audit/report_harmonization/report017_h01_order32f_stopped_state_independent_acceptance.md`, SHA-256 `1b06370f6ec10b25ba3784df6ab3516660cd47a14f79fb4e008ad1801a33a008`.
- Independent 25-row manifest: `audit/report_harmonization/report017_h01_order32f_stopped_state_independent_manifest.csv`, SHA-256 `7e27de24284757e6e77a3d0bf2e7a2275d8e390555352212c935ad6b7f84a787`, verified 25/25 exact under R 4.6.1.
- Owner order 32f stop record: `audit/hypotheses/H01/report017_order32f_continuation/order32f_stopped_state.md`, SHA-256 `9a050f6603b3d33452813193cd22deb56ca5f991cf3d86a42cc25d3b305dbdcd`.
- Owner 11-row stop seal: SHA-256 `872a129792bf677c805aaee51b131e49d614fcc9c86e682d0c9c661925efa7a7`, verified 11/11 exact under R 4.6.1.
- Current stopped refresh implementation: `scripts/hypotheses/H01/refresh_h01_order32d_figures.R`, SHA-256 `10288d5fb28df713c43f52a5f3e984070d8062701a28a3e6eb4fe8d9d8b223aa`, 28,717 bytes.
- Result QMD: `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`.
- Frozen companion QMD: `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`.
- Stopped result HTML: `d1bc9159526c92b9cc9256c58a8232d4779f0014a3aa39ed3680b4e58fb25410`.
- Frozen companion HTML: `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`.
- Profile: `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
- Builder: `35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7`.

Recheck the complete order 32g dispatch manifest before any mutation. Stop if any project pin or retained temporary identity differs.

## Immutable temporary evidence

Preserve these three directories and every member byte-for-byte throughout this order:

1. `/private/tmp/H01-order32e-candidates.hltKEs`.
2. `/private/tmp/H01-order32f-candidates.eDOsrp`.
3. `/private/tmp/H01-order32d-quarantine.Xc28uF`.

The order 32f directory contains exactly 16 stopped-evidence files: 12 PNG/SVG files plus `baseline_identity_check.csv`, `durable_identity_check.csv`, `figure1_baseline_provenance.csv`, and `output_inventory.csv`. Inventory all 16 before mutation and after completion or stop. The quarantine contains exactly three accepted recovery files, and their original build paths remain absent. Do not move, delete, recreate, rename, overwrite, or promote any member of these directories.

## Authorized scalar-safe geometry correction

Edit only the geometry-check `lapply()` block in `scripts/hypotheses/H01/refresh_h01_order32d_figures.R`:

1. Rename its closure scalar from `figure_id` to `current_figure_id`.
2. Before any tibble or data-mask operation, bind:
   - `current_paths <- candidate_paths[[current_figure_id]]`;
   - `candidate_png <- current_paths[["png"]]`;
   - `current_spec <- baseline_specs[baseline_specs$figure_id == current_figure_id, , drop = FALSE]`.
3. Use base subsetting exactly as shown. Do not use a tidy data-mask comparison to select the specification.
4. Fail closed unless `nrow(current_spec) == 1L`.
5. In the one-row `mutate()`, assign:
   - `figure_id = current_figure_id`;
   - `expected_width = current_spec$png_width[[1]]`;
   - `expected_height = current_spec$png_height[[1]]`.
6. Change no other plotting, validation, source, or scientific logic.

Copy the pre-edit implementation into the new order 32g evidence directory. Record an exact one-hunk diff and reverse proof to SHA-256 `10288d5f...`. Run Air 0.4.1 only on this refresh implementation. Record pre-Air and post-Air identities and prove the parsed abstract syntax is unchanged by Air. Parse under R 4.6.1 and run `air format --check` plus scoped `git diff --check`.

## One non-mutating preflight

Before generating new candidates, run one R 4.6.1 preflight that does not write a project or retained-evidence file. It must:

- exercise the corrected geometry helper for all three figure IDs;
- require one and only one matching `baseline_specs` row for each ID;
- validate expected pixel dimensions and approximately 320 dpi for all three retained candidate PNGs;
- replay the full remaining-path audit already accepted after order 32f: SVG node structure and visible-text multiset 3/3, all 30 paired labels exactly once, terminal-`px` widths valid, zero label collisions, minimum final text sizes at least 7 pt, frozen source identities, and exact Figure 1/5/6 baseline contracts;
- confirm the complete 16-file order 32f directory, the complete order 32e directory, and all three quarantine files remain exact.

Do not run a preliminary candidate generation or a partial copy of the candidate script. If the preflight fails, seal one stopped state and do not patch or retry.

## One fresh candidate run

After a passing preflight, create one new empty candidate directory with `mktemp -d` under `/private/tmp`. Record its resolved path, permissions, emptiness, and creation time. Run the corrected refresh implementation exactly once under R 4.6.1 with a new attempt ID.

Require all existing candidate contracts from orders 32d through 32f:

- exact frozen input identities and row/key equality;
- exact source-derived baseline identities, including the bounded Figure 1 sealed-to-source provenance transition;
- exact candidate dimensions and 320 dpi;
- unchanged rows, mapped aesthetics, layers, labels, facets, axes, scales, colours, shapes, null/identity lines, and ordering;
- SVG structural and visible-text preservation;
- zero paired-label collisions;
- final-size text at least 7 pt at 708 pixels for Figures 1 and 6;
- original-size, intended-final-size, 1440-pixel, 708-pixel, and 200-percent visual checks;
- Figure 1 and Figure 6 status symbols and text legible without clipping or overlap;
- all 30 Figure 5 direct labels present, legible, non-overlapping, and unclipped.

If any candidate or validation fails, keep the new directory intact, do not write a durable target, and return one complete stopped-state defect list.

## Durable display replacement and direct reseal

Only after every candidate check passes:

1. Update only the already authorized display literals in `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R`. Do not run the full builder.
2. Replace exactly the six durable Figure 1, 5, and 6 PNG/SVG targets once from the accepted fresh candidate directory.
3. Verify the exact six-target write set and prove every other scientific and display artifact unchanged.
4. Run the dedicated display tests and complete H01 source/reporting and REPORT-016 focused tests under R 4.6.1.
5. Reseal only directly dependent current rows for the builder, refresh implementation, six figures, focused tests, new bounded evidence, and direct manifest dependencies. Proceed from leaves upward. Do not run a broad manifest builder or alter any historical REPORT-016 or prior stopped-state record.

## Exactly one result render

After the artifact package, focused tests, and direct reseals all pass, run exactly one command:

```text
quarto render notebooks/hypotheses/H01.qmd --profile nathealth
```

Use the normal project R 4.6.1 profile and only the established narrow access to the existing user-owned renv cache if required. The configured post-render native-gt semantic hook must run normally. Do not use `--no-execute`, bypass the hook, render the companion, render another page, or render the full project.

The render may update only the target H01 HTML, the accepted source-identical build copies, and normal bounded search/sitemap outputs. Classify byte-identical mtime-only touches separately. Fail on any other unclassified build-content change.

## Complete post-render acceptance

Run the full REPORT-017 result-page acceptance in one pass:

- 36 native gt tables and ten intended figures with accepted labels, values, captions, notes, order, source-data links, and styles;
- semantic hook success, document-wide unique IDs, and every explicit `headers` token resolving exactly once to its intended `th` within its own table;
- complete H01 reporting, navigation, reader-link, deviation-link, and country-code contracts;
- 40 links to 36 unique central deviation anchors;
- no unresolved cross-reference, raw error, warning, or stderr node;
- Figure 1 and the principal table remain the first figure and table endpoints and retain accepted FDR language;
- every protected scientific/input/source identity unchanged.

Start one temporary read-only static server rooted exactly at `_build/nathealth`, bound only to `127.0.0.1` on one unused high port. Use only the in-app Browser. Inspect the complete page at 1440 by 1000 and 708 by 1000, plus 200-percent and intended-final-size reviews of the repaired figures and the principal table. Apply the accepted table policy: normal desktop/laptop usability, with contained horizontal scrolling allowed at narrow width. Inspect typography, legends, direct labels, clipping, overlap, callouts, links, navigation, and all ten figures at final display size. For exported tables, the PNG version is the controlling export check; HTML tables need to work reasonably at a typical screen size.

Stop the server immediately after QA. Prove no listener remains and no source, protected, temporary-evidence, or build drift occurred after QA.

## One-combined-stop rule

If any startup, candidate, artifact, test, reseal, render, semantic, link, protection, or visual check fails, do not patch, promote, or rerender. Finish every safely executable read-only check, seal one complete stopped state, and return the full defect list once.

## Prohibitions and queue state

Do not fit, refit, predict, bootstrap, resample, simulate, rerun Shapley, recompute inference, change source data, run the full builder, edit another hypothesis, edit the profile or central ledgers, install or update packages, edit `renv.lock`, delete retained evidence, commit, push, upload, or render another target.

The H01 companion and every later REPORT-017 render remain held until this result page receives independent semantic and visual acceptance.
