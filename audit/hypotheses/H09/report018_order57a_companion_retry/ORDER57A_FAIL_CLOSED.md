# REPORT-018 H09 order 57a fail-closed record

Date: 2026-08-22

Status: **STOPPED after the sole authorized companion retry failed.**

## Authorized source repair and preflight

The three bounded provenance repairs were applied exactly:

- `scripts/hypotheses/H09/h09_contract.R` is SHA-256
  `866b0f8736c8a25f50a3f1ce6e38c5d33d4666d4bf06031f0021ee1cb6d0b701`,
  16,374 bytes;
- `artifacts/06_model_data/H09/H09_input_audit.csv` is SHA-256
  `1ea3910539378434533dcaeeaee6ab613e325468d99ffd10e02bdc868a4175ed`,
  4,401 bytes; and
- `audit/hypotheses/H09/H09_analysis_preparation.qmd` is SHA-256
  `286c391fb228268804ba199d38bd5341509b3a66d434e30aa09fc1007a19443e`,
  48,400 bytes.

Each postimage reversed exactly to its required preimage. The complete R 4.6.1
preflight passed 21 of 21 checks. It reproduced 49 of 49 dispatch rows, 30 of
30 independent stopped-acceptance rows, the complete 45-row order-57 owner
seal, all 16 current input-audit rows, all eleven current result inputs, the
20-domain scientific-scope audit, 25,620 exact non-MDER cells, all 40 H09 gap
frames covering 32,492 frame rows, 57 live-exact historical scientific members
plus eight accepted display transitions, 22 parseable chunks, 19 table
endpoints, one figure, one top-down Mermaid diagram, 23 relative link
occurrences to 22 unique targets, 113 live preparation-manifest rows plus the
same 19 classified historical transitions, 851 build files, zero build
symlinks, 16 historical source-side support files, and 545 protected files.

The independent scientific-scope checker ran exactly once and reproduced all
20 checks. No scientific model, prediction, estimate, p-value, diagnostic,
sensitivity analysis, resampling, or scientific artifact was run or written.

## Sole retry outcome

Exactly one Quarto retry was made for
`audit/hypotheses/H09/H09_analysis_preparation.qmd` with the `nathealth`
profile, R 4.6.1, the accepted project library, the semantic hook, and a fresh
external semantic directory. It executed through 16 of the 19 table chunks and
then exited with status 1 in `tbl-h09-prep-reader-manifest-check` at source
lines 1004 to 1048 because
`all(manifest_check$Status == "PASS")` was false.

No additional retry was attempted. The conditional preparation-manifest
helper was not run because the retry and semantic hook did not succeed. No
browser QA was started because the nonvisual acceptance gate did not pass.

## Exact blocking contract

The unchanged Stage 3 manifest
`artifacts/12_manifests/H09/H09_stage3_artifacts.csv` remains SHA-256
`0103aad8bf3b2424358fc139b85b95564054745b180a80d1e12c27ff72e1bef2`,
24,678 bytes. It contains 108 rows. After excluding the two handoff records
declared mutable by the companion code, 106 rows remain. Exactly 87 are
live-exact and 19 retain historical identities.

The 19 mismatches are:

1. `audit/hypotheses/H09/H09_stage1_gate_and_stage2_transition.md`
2. `scripts/hypotheses/H09/h09_contract.R`
3. `scripts/hypotheses/H09/run_h09_stage2.R`
4. `artifacts/10_figures/H09/H09_diagnostics_chest.pdf`
5. `artifacts/10_figures/H09/H09_diagnostics_chest.png`
6. `artifacts/10_figures/H09/H09_diagnostics_near_eye.pdf`
7. `artifacts/10_figures/H09/H09_diagnostics_near_eye.png`
8. `artifacts/10_figures/H09/H09_paired_placement_effects.pdf`
9. `artifacts/10_figures/H09/H09_paired_placement_effects.png`
10. `artifacts/10_figures/H09/H09_primary_effects.pdf`
11. `artifacts/10_figures/H09/H09_primary_effects.png`
12. `artifacts/06_model_data/H09/H09_base_bundle_audit.csv`
13. `artifacts/06_model_data/H09/H09_input_audit.csv`
14. `artifacts/12_manifests/H09/H09_figure_manifest.csv`
15. `_build/nathealth/notebooks/hypotheses/H09.html`
16. `notebooks/hypotheses/H09.qmd`
17. `config/metric_display_registry.csv`
18. `_quarto-nathealth.yml`
19. `audit/decisions/figure_readability_and_layout.md`

These are not new scientific drift from the retry. They include the exact
Order 57a provenance postimages and previously accepted reporting, shared,
and display transitions. The companion chunk nevertheless requires every
non-handoff Stage 3 manifest row to be live-exact and provides no historical
transition classification. The frozen manifest and the unqualified assertion
therefore cannot both pass in the current accepted state. Order 57a authorizes
neither a Stage 3 manifest rewrite nor another companion code-path edit.

## Fail-closed preservation

Read-only postfailure checks passed 16 of 16 domains and confirmed:

- all 851 build files remained byte-identical and the build remained
  symlink-free;
- all 545 protected files remained byte-identical;
- all 16 historical source-side support files remained byte-identical;
- the complete order-57 failure history remained 45 of 45 exact;
- all three authorized source postimages remained exact;
- the accepted result page, scientific and display artifacts, source data,
  tests, helper, profile, semantic code, phase-4 manifest, handoff, lockfile,
  historical manifests, and historical excluded-transition record remained
  exact;
- the canonical companion HTML and build QMD retained their held historical
  identities;
- the external semantic directory remained empty because execution stopped
  before post-render repair;
- the Sass cache remained byte-identical; and
- no Quarto, Pandoc, H09 semantic, helper, additional retry, browser-QA, or
  task-owned loopback process remained after teardown.

The fresh external working and semantic directories are retained for
independent acceptance. Any correction of the Stage 3 manifest assertion or
historical-transition handling requires a new sealed owner order. No further
render is available under Order 57a.
