# Proposed Brown Stage 3 recommendation-window and BA-M reader-label consolidation

Date: 2026-08-24

Workflow: `REPORT-018`

Status: **PROPOSED FOR CENTRAL REVIEW; NOT DISPATCHED**

Owner: `019fffdf-66d4-7802-9091-09283ad27b7f`

## Authority and purpose

This proposed source-and-display-only order implements queue item 1 in
`audit/report_harmonization/report018_post_navigation_display_queue_2026_08_24.md`,
SHA-256 `9ebb1d81ef202b420aec42d12e5de372871edec780c5f72885e18d327f0f5a36`.

It consolidates two linked decisions before either is independently accepted:

1. the completed owner-pass repair that translates reader-facing `BA-M4` and
   `BA-M6` labels into their scientific meanings; and
2. the superseding author decision that all affected Brown Stage 3 figure axes
   use `Daytime`, `Pre-sleep`, and `Sleep`, with captions identifying these as
   the Brown et al. recommendation windows.

`Wake` remains the internal analytical and source-data state. `Daytime` is a
display label only. The term `context` remains permitted for genuine sensor-
position, sleep-environment, or behavioral interpretation, but not as a name
for one of the three recommendation-window categories.

## Hard preflight pins

Before any mutation, require all rows in
`audit/report_harmonization/report018_brown_stage3_window_label_inventory.csv`
whose status is `controlling`, `pending_owner_PASS`, `accepted_stale_render`,
`accepted_frozen`, `protected`, `historical_pending_evidence`, or
`historical_frozen` to match their exact recorded SHA-256 and byte identities.
In particular:

- current pending Stage 3 QMD: `ea8f639a5b58ef591bf4716928ef32db4de68b30e157e2670867a5c0ee2d9c05`,
  55,601 bytes;
- accepted Stage 3 HTML, held: `3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d`,
  4,825,090 bytes;
- current pending Stage 4 QMD, protected:
  `8fc81d9b28b60a3ab28315b6e83f884e55d2f8cbcb7cb374312414b1922c9c92`,
  25,275 bytes;
- accepted Stage 4 HTML, protected:
  `54e85fe7873a8b54772341ce95241e5dc93ec7ab14aef99f0b1b72773b0f5954`,
  4,341,698 bytes;
- linked `07_results.qmd`: `a1c9b4662038c584d6338d0b38378ae572f27fc4ef84fa558557ff9137640cef`,
  29,588 bytes;
- linked `07_results.html`, held:
  `06edb255a521cc285832dc31846de39878648856bde7ee9cbb6959f83db629c8`,
  1,374,116 bytes;
- pending 38-row BA-M repair manifest:
  `eec6b7c03da8769b32d828b5eae8f8cec6819dc27ac9e6d6a8824c5d37eb16e1`;
- all four builders, five frozen CSV inputs, and ten durable PNG/SVG endpoints
  at the identities in the inventory; and
- every historical verifier, manifest, handoff, completion record, accepted
  source preimage, package, lockfile, and scientific artifact in the pending
  BA-M package.

Stop before editing if any hard pin differs. The mutable global coordination
state is dispatch evidence only and is not an owner execution pin.

## Exact authorized source changes

Apply every fixed substitution in
`audit/report_harmonization/report018_brown_stage3_window_label_change_matrix.csv`
exactly once. In that matrix, `<<NL>>` denotes one LF byte. Require an exact
forward proof and exact reverse reconstruction for every text row.

Existing files that may change are limited to:

1. `audit/analyses/brown_adherence/07_results.qmd`;
2. `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd`;
3. `audit/analyses/brown_adherence/stage3/01_build_stage3_displays.R`;
4. `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/workday_site_and_coverage_guides_amendment/01_build_displays.R`;
5. `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/00_build_ba_m6_display.R`; and
6. `audit/analyses/brown_adherence/stage3_cross_state_association/01_build_stage3_outputs.R`.

The builder edits must keep `Wake` as the internal factor value, order key,
profile key, predictor state, and color key. They may only add the explicit
display mapping `Wake = Daytime`, retain `Pre-sleep` and `Sleep`, and replace
the bounded artwork language in the matrix. Require Air 0.4.1 format checks on
the four builders and any new R implementation or verifier. The four builder
postimages must already be canonical, so Air must be a no-op. Fail if a
formatter would introduce an unlisted byte change. Require R 4.6.1 parse and
exact semantic checks. Do not execute any of the four broad historical
builders.

Exact in-memory application of the 32 text substitutions, before any owner
mutation, must reproduce these prospective identities:

| Target | Bytes | SHA-256 |
|---|---:|---|
| `audit/analyses/brown_adherence/07_results.qmd` | 29,578 | `d941731ae4cef7e4d903c9968407694bd3554ff805a1d26a04e9daaee1bb3aaa` |
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | 56,275 | `a57d26e7174a2223607e13c2071b3f9073e40c1b7749895b19705dea3856e65e` |
| `audit/analyses/brown_adherence/stage3/01_build_stage3_displays.R` | 21,156 | `9746ab27c8fc268e040b6045b8939feec6e057e291e0dac08ecf1d137e02ef27` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/workday_site_and_coverage_guides_amendment/01_build_displays.R` | 16,195 | `e7a06c8cf645d900d72a769cdf5a8163c7471879c70646393ab7c96ceef731e0` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/00_build_ba_m6_display.R` | 18,033 | `fa12843257bf43136286e783ece85802ded974a9f4fa1350a2108b6dbb3ab0e3` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/01_build_stage3_outputs.R` | 20,831 | `86b019d44d313ad7a9da80bdb3ca34f0f7c8ff5f6259c1724daadaeb5d21c160` |

The Stage 4 QMD is not a mutation target. Its internal BA-M identifiers remain
permitted only because each is immediately translated as provenance. The
Stage 3 QMD and all five artworks must contain no reader-facing BA-M identifier
after this order.

## Dedicated candidate-first refresh

Create a new evidence directory under
`audit/analyses/brown_adherence/language_harmonization/window_label_repair/`.
Create one dedicated R 4.6.1 display refresh and one focused verifier there.
The refresh may read only these five frozen CSVs:

1. `stage3/source_data/figure_adherence_levels_source.csv`, six rows;
2. `workday_site_and_coverage_guides_amendment/source_data/main_site_workday_adherence_forest_source.csv`, 27 rows;
3. `site_free_work_vs_equal_site_inference_amendment/source_data/main_site_free_work_forest_with_ba_m6_source.csv`, 27 rows;
4. `workday_site_and_coverage_guides_amendment/source_data/main_coverage_sensitivity_forest_source.csv`, six rows; and
5. `stage3_cross_state_association/source_data/figure_participant_state_profiles.csv`, 417 rows.

It may also embed only the accepted display constants, dimensions, palettes,
shapes, seeds, site order, panel order, and line styles copied exactly from the
four pinned builders. It must fail if any frozen source identity, row count,
column set, internal state set, or accepted display constant differs. It may
not read a model, model frame, inferential RDS, participant identifier, raw
measurement file, or any unlisted source.

Write ten candidate files to one fresh absolute directory outside durable
targets. Do not write or copy any source CSV. Before promotion, require:

- five PNGs and five SVGs with the exact accepted dimensions and DPI;
- exact source-row, mapped-aesthetic, point, interval, line, marker, profile,
  layer, panel, palette, order, and seed equality;
- exactly five orange diamonds and three black asterisks in the Free-minus-
  Work forest, exactly seven emphasized Work-day sites, both accepted reference
  lines, and every accepted non-color cue;
- exactly 417 raincloud points from 139 anonymous three-window profiles, with
  equal-cycle means, pairing lines, density geometry, summaries, and seeds
  unchanged;
- `Daytime`, `Pre-sleep`, and `Sleep` in every affected axis or facet, with no
  displayed `Wake` or `Evening` token;
- no category label containing `context`;
- no reader-facing BA-M token and exact retention of the already accepted
  plain-language Figure 3 legend and notes;
- normalized SVG structure and all non-text geometry equal to the accepted
  baseline, allowing only approved text nodes and directly dependent
  text-length metadata to change;
- decoded PNG changes confined to predeclared text bands, with zero changed
  data-panel pixels outside those bands; and
- original-size, 170 mm, 1440 by 1000, 708 by 1000, and 720 by 500
  200-percent-equivalent visual QA, including legibility, clipping, overlap,
  wrapping, symbols, lines, legends, labels, and a minimum 7-point essential-
  text floor at intended final size.

Only after the complete candidate package passes may the owner make one
recoverable, one-time promotion of exactly these ten durable endpoints:

- `stage3/figures/adherence_levels.png` and `.svg`;
- `workday_site_and_coverage_guides_amendment/figures/main_site_workday_adherence_forest.png` and `.svg`;
- `site_free_work_vs_equal_site_inference_amendment/figures/main_site_free_work_forest_with_ba_m6.png` and `.svg`;
- `workday_site_and_coverage_guides_amendment/figures/main_coverage_sensitivity_guides.png` and `.svg`; and
- `stage3_cross_state_association/figures/participant_state_raincloud.png` and `.svg`.

Preserve exact recoverable preimages before promotion. Require every durable
postimage to be byte-identical to its accepted candidate. Do not regenerate or
promote any other figure or source-data file.

## Source and scientific preservation checks

The focused verifier must run once before promotion against candidates and
once after promotion against durable endpoints. It must require all of the
following:

1. Every matrix text preimage occurs exactly once before editing, every
   postimage exactly once after editing, and exact reverse substitution
   recovers all six source preimages byte-for-byte.
2. The Stage 3 QMD has the same R chunk labels, executable R expressions,
   inline R expressions, table and figure endpoints, relative link targets,
   source-data links, anchors, formulas, and numeric-token multiset, except for
   the enumerated caption and alt-text prose.
3. The linked `07_results.qmd` changes only the one exact Evening-to-Pre-sleep
   sentence and preserves all other bytes by reverse proof.
4. All five captions contain the exact sentence or equivalent approved
   construction identifying `Daytime`, `Pre-sleep`, and `Sleep` as Brown et al.
   recommendation windows. No caption calls the categories contexts.
5. Genuine primary near-eye, complementary chest, bedside sleep-environment,
   and behavioral-context qualifications remain exact.
6. Every number, estimate, interval, raw or adjusted p-value, FDR family and
   decision, sample, site, model identity, marker, line, legend meaning,
   source-data row, and non-causal qualification remains exact.
7. The pending BA-M owner package remains 38 of 38 exact and non-circular.
   Stage 3 contains zero reader-facing BA-M4 or BA-M6 tokens. Stage 4 remains
   byte-identical and retains immediate scientific translations for its
   provenance-only BA-M identifiers.
8. The four historical builders parse, the new refresh and verifier parse,
   the no-fit/no-prediction/no-inference/no-resampling/no-write scan passes,
   and scoped diff and whitespace checks pass.

If any assertion or visual check fails, stop once, preserve all candidates and
preimages, and return one consolidated defect list. Do not patch and retry
within this order.

## Current evidence and historical boundary

Do not edit any existing test, verifier, manifest, handoff, completion record,
HTML, or historical evidence. In particular, preserve the pending BA-M
verifier, its 38-row manifest, owner handoff, and completion record byte-for-
byte. They remain historical evidence for the accepted baseline transition.

Create only new, non-circular current evidence in the new window-label repair
directory. The new package may include:

- the dedicated refresh and focused verifier;
- exact preimages and forward/reverse proofs;
- candidate and durable identity inventories;
- source, mapping, geometry, SVG, decoded-pixel, typography, and visual-QA
  checks;
- a current direct display manifest that excludes itself;
- one completion record; and
- one new owner handoff.

No broad manifest builder is authorized. Historical manifests retain their old
identities. The new current manifest must enumerate the exact historical-to-
current transitions for the two QMDs, four builders, and ten promoted assets,
and fail on a seventeenth changed existing path.

## Render boundary

No Quarto, Pandoc, knitr execution, browser server, or HTML mutation is
authorized in this source/display order. Return the complete source/display
package for independent acceptance.

If independently accepted, central coordination must issue later serial render
releases. The integrated Stage 3 page remains a separate, exact target using
the established R 4.6.1 library, renv-autoloader-disabled startup, candidate-
first semantic repair, privacy/link/endpoint checks, and complete loopback
visual QA. Because this order also corrects one reader sentence in
`07_results.qmd`, that linked page requires its own separately sealed serial
render or an explicit central decision to retain its stale HTML. Neither render
is implied by this proposed order.

Stage 4, H06_daily, H03/H04, all later queue items, and every other render stay
held.

## Prohibitions

No model fit or refit, prediction, inference, simulation, resampling,
bootstrap, source-data regeneration, figure-source regeneration, participant-
level access, broad builder, QMD execution, Quarto render, HTML edit, Stage 4
edit, package or lock change, profile or shared configuration change, ledger
edit, manuscript edit, commit, push, upload, or owner wake is authorized by
this proposed record.
