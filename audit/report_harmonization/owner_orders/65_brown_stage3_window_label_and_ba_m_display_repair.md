# Owner order 65: Brown Stage 3 recommendation-window and BA-M display repair

Date: 2026-09-02

Workflow: `REPORT-018`

Status: **FINAL DISPATCH ORDER**

Owner task: `019fffdf-66d4-7802-9091-09283ad27b7f`

## Authority and resolved queue item

This order releases queue item 1 from
`audit/report_harmonization/report018_post_navigation_display_queue_2026_08_24.md`,
SHA-256 `9ebb1d81ef202b420aec42d12e5de372871edec780c5f72885e18d327f0f5a36`.

It supersedes the proposed, undispatched order in
`audit/report_harmonization/owner_orders/brown_stage3_window_label_and_ba_m_display_repair_proposed.md`.
Every scientific-preservation, candidate-first, visual-QA, source-ownership,
prohibition, stop, and return requirement in that proposed order is part of
this final order unless explicitly replaced below. The exact authorized
change scope remains the existing 42-action matrix in
`audit/report_harmonization/report018_brown_stage3_window_label_change_matrix.csv`:
19 QMD substitutions, 13 builder substitutions, and ten candidate-first
durable asset transitions.

## Current preflight overlay

The later accepted 12 px table convergence changed two QMD identities after
the proposal was sealed. Use the historical 57-row inventory plus this exact
two-row overlay:

`audit/report_harmonization/report018_brown_stage3_window_label_dispatch_pin_delta_2026_09_02.csv`

The current controlling identities are:

- Stage 3 QMD: 55,556 bytes,
  `cca627a3f9a60f5c4b7d04112145c865c4035646b60668f9be765298682b12af`.
- Stage 4 QMD, protected and not a mutation target: 25,252 bytes,
  `577121dbca925e26d47307cd66ff6b02a15e9295b0ad46064accfd8f6b69106d`.

All other inventory pins remain exactly those in the historical inventory.
The same two-row overlay supersedes only the corresponding QMD identities in
the historical 38-row BA-M manifest. Its other 36 rows remain exact.
Run this preflight before any mutation:

```sh
Rscript --vanilla scripts/report_harmonization/check_brown_stage3_window_label_dispatch_current.R \
  /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
  /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026
```

Require `BROWN_ORDER65_PREFLIGHT=PASS`. Stop before editing if any assertion
fails.

## Current prospective source identities

Exact in-memory application of all 32 text substitutions to the current owner
preimages must produce:

| Target | Bytes | SHA-256 |
|---|---:|---|
| `audit/analyses/brown_adherence/07_results.qmd` | 29,578 | `d941731ae4cef7e4d903c9968407694bd3554ff805a1d26a04e9daaee1bb3aaa` |
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | 56,230 | `9a6f2402f57640fb19319845b7d25f0ade1697dfab0ff262bf6dc5a47b97654e` |
| `audit/analyses/brown_adherence/stage3/01_build_stage3_displays.R` | 21,156 | `9746ab27c8fc268e040b6045b8939feec6e057e291e0dac08ecf1d137e02ef27` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/workday_site_and_coverage_guides_amendment/01_build_displays.R` | 16,195 | `e7a06c8cf645d900d72a769cdf5a8163c7471879c70646393ab7c96ceef731e0` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/00_build_ba_m6_display.R` | 18,033 | `fa12843257bf43136286e783ece85802ded974a9f4fa1350a2108b6dbb3ab0e3` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/01_build_stage3_outputs.R` | 20,831 | `86b019d44d313ad7a9da80bdb3ca34f0f7c8ff5f6259c1724daadaeb5d21c160` |

The Stage 3 identity differs from the proposal only because its accepted table
font convergence is preserved. The Stage 4 QMD remains protected and
byte-identical.

## Reader-facing result

Apply the matrix exactly once and build only the dedicated candidate package
authorized by the proposed order. Across the five affected Stage 3 displays:

- show `Daytime`, `Pre-sleep`, and `Sleep` as the Brown et al.
  recommendation-window labels;
- retain `Wake` as the internal analytical and source-data state;
- do not call the three window categories `contexts`;
- retain plain-language meanings in place of reader-facing `BA-M4` or `BA-M6`
  labels;
- use `Evening` to `Pre-sleep` only for the exact three-hour recommendation
  window enumerated in the matrix; and
- preserve all data, estimates, intervals, p-values, FDR decisions, samples,
  models, sources, markers, geometry, panel order, and non-causal
  qualifications.

Do not make a global `Wake` replacement. Do not alter genuine uses of
behavioral context, sensor position, complementary chest, or bedside sleep
environment.

## Candidate-first and promotion boundary

Create a new evidence directory under
`audit/analyses/brown_adherence/language_harmonization/window_label_repair/`.
Use one dedicated R 4.6.1 refresh and one focused verifier. Read only the five
frozen CSVs listed in the proposed order. Generate ten candidates in a fresh
temporary directory, verify all source, mapping, geometry, typography,
decoded-pixel, SVG, and visual-QA requirements, then make one recoverable
promotion of exactly the five PNG/SVG pairs enumerated in the matrix.

Do not execute the four historical broad builders. Do not edit historical
tests, verifiers, manifests, handoffs, completion records, HTML, or accepted
source data. Create only new non-circular evidence for this order. Fail on any
seventeenth changed existing path beyond the six text sources and ten figure
endpoints.

## Render and ownership boundary

No Quarto, Pandoc, or knitr execution is authorized. No browser server or HTML
mutation is authorized. Stage 4 remains protected. All manuscript, H06_daily,
H03/H04, shared configuration, package, lockfile, ledger, analysis, model, and
scientific-result paths remain out of scope.

Return the complete source/display package for independent acceptance. Later
Stage 3 and linked-page renders require separate serial releases.

## Stop rule

If a pin, matrix occurrence, protected-token check, formatter check,
scientific-preservation check, candidate check, or visual check fails, stop
once and return one consolidated defect list. Do not patch and retry within
this order.
