# REPORT-018 H09 order 56 consolidated display-repair concurrence

Date: 2026-08-22

Status: `APPROVED_ONE_CONSOLIDATED_DISPLAY_REPAIR_AND_RESULT_RERENDER`

## Controlling disposition

The independent stopped-state acceptance is
`audit/report_harmonization/report018_h09_order56_stopped_independent_acceptance.md`,
SHA-256 `1c470541bcd7a125a7332d256389f4b5776075b5923de6f88019c5d0c5b75c28`,
4,643 bytes. Its 41-row non-circular manifest is SHA-256
`02dcf6491b22fa154a7036c6badb4f0ea510f54978f92665210cf9dfd43029f5`,
6,637 bytes.

Order 56 established exactly one genuine H09 result-page defect. The four
reader figures have essential text below the 7-point floor at a 170-mm
display width. All nonvisual, semantic, scientific, link, navigation, build,
and protected-identity checks pass.

One consolidated repair and result rerender is authorized. It must correct
all four typography failures together, validate a complete candidate set
before any durable display write, promote the eight affected PNG/PDF files
together exactly once, and consume exactly one new H09 result render. It must
not open a language or cosmetic cleanup loop.

The H09 companion and every later REPORT-018 render remain held.

## 1. Frozen inputs and preflight

Before editing, require all of the following exact identities:

- result QMD `c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6`,
  36,970 bytes;
- stopped result HTML
  `dbc9122ca0a7be6e051741d8354f9ebdec8e072753d9b2592d6387f9716a7caa`,
  244,127 bytes;
- companion QMD
  `7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46`,
  47,901 bytes;
- held companion HTML
  `4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05`,
  593,181 bytes;
- current H09 builder
  `a234fcaabf254ee924fe3ceb2de1e6c9fbf3ef3f7be1e5a3c5ff3b2cf39bd9c6`,
  90,288 bytes;
- current H09 figure manifest
  `0ad64452efd82932b5db6782090f9b3660b31d63d115cd7d806c10597fbdf76b`,
  4,284 bytes;
- profile
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`,
  7,480 bytes; and
- `renv.lock`
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`,
  603,493 bytes.

Reproduce the 98-row owner stopped seal and the 41-row independent seal in
full. Confirm R 4.6.1, Quarto 1.9.37, Air 0.4.1, the accepted R 4.6.1 project
library, no competing Quarto or Pandoc process, and no build symlink.

Inventory the complete project-side protected set and `_build/nathealth`.
Preserve the stopped HTML as the pre-repair rendered baseline. Stop without a
patch if any preflight pin or ownership boundary fails.

## 2. Frozen display sources and current outputs

The dedicated refresh may read only these three scientific source CSVs:

1. `artifacts/11_source_data/H09/H09_primary_effects_data.csv`, SHA-256
   `3972ae75c9aef8551cc85f50d7a438b35b7a55dca58d81f3630133132a25aaf6`,
   6,778 bytes;
2. `artifacts/11_source_data/H09/H09_paired_placement_effects_data.csv`,
   SHA-256
   `ecc9fe09a1e823ec6b45b2b28239e56bf773a6d8a8c0bb458413e1e2e9b170b0`,
   8,394 bytes; and
3. `artifacts/11_source_data/H09/H09_primary_diagnostic_figure_data.csv`,
   SHA-256
   `b3119775c6725295b54af0fea735d89b892f4e9dcea94c9ff564248e5345854a`,
   9,773,267 bytes.

It may also read the exact current figure manifest as a display registry. It
must not read or deserialize a fitted model, inferential RDS, analytical
frame, broad scientific manifest, or package lock. It must not source or run
the full H09 Stage 2 builder.

The eight durable display preimages are:

1. `H09_primary_effects.png`, SHA-256
   `f288cfaff6e555715af30c778974e50d9bcc8c9a90c643b5e994ad2d8b95be1f`,
   139,103 bytes;
2. `H09_primary_effects.pdf`, SHA-256
   `b354077d2c1225104ecef7af1d879acd2037a7b740940392092b2d09f2f833e0`,
   17,970 bytes;
3. `H09_paired_placement_effects.png`, SHA-256
   `4cffc5339801d25e817639064b6f40e0b0a6bbe69a735e5f245d97cee898e185`,
   129,869 bytes;
4. `H09_paired_placement_effects.pdf`, SHA-256
   `5d8f8e95c4642ca29391941f63852776ee6d4ee3cb0cbdedfe74d24ec645ff7c`,
   16,857 bytes;
5. `H09_diagnostics_near_eye.png`, SHA-256
   `df6a267517ea08635a00fcfa153a1e3a7f6dbbbe764745860c16bd3b53165e96`,
   2,557,336 bytes;
6. `H09_diagnostics_near_eye.pdf`, SHA-256
   `a01d7184d3fc68bf33375f950c9ba422ac7f86f803cd214064ddf86d003ca5ac`,
   627,893 bytes;
7. `H09_diagnostics_chest.png`, SHA-256
   `e82b32d5d69a73e45a7d93e8b1bb8357dc3104e67c5f128eba4f3f5538961a75`,
   2,626,860 bytes; and
8. `H09_diagnostics_chest.pdf`, SHA-256
   `614b46f3cb2026ea1f6c7350959482ce4473c114b0c90ec066a176f73c635596`,
   695,820 bytes.

Use the complete hashes from the independent acceptance manifest. Preserve
recoverable copies of all eight preimages in the new order evidence before
durable promotion.

## 3. Authorized source implementation

Create exactly one dedicated R 4.6.1 refresh implementation and one focused
test at:

- `scripts/hypotheses/H09/refresh_h09_order56_figures.R`; and
- `tests/hypotheses/H09/test_h09_order56_display_repair.R`.

Use a new evidence root:

- `audit/hypotheses/H09/report018_order56a_display_repair/`.

The refresh must accept an explicit output directory and must not default to
the durable artifact directory. It must build all four PNG/PDF families from
the three frozen CSVs. It must expose both a historical-theme baseline mode
and the repaired-theme mode so the focused test can prove that only approved
display parameters differ.

Edit `scripts/hypotheses/H09/run_h09_stage2.R` only at the corresponding
theme-size, margin, panel-spacing, wrap-width, and permitted canvas-height
literals for these four figure families, plus the four directly corresponding
figure-manifest literals. Do not execute this builder. Require an exact
forward diff and reverse reconstruction to the accepted preimage.

Directly update only the four affected rows of
`artifacts/12_manifests/H09/H09_figure_manifest.csv` after the final candidate
is fixed. Preserve its schema, row order, the two unrendered V0 rows, source
paths, alt text, widths, DPI, and every unaffected value. Record truthful
nominal and effective typography, canvas height if changed, final dimensions,
and visual status.

The result and companion QMDs, historical H09 tests, Stage 3 manifests, handoff,
profile, semantic tools, and all scientific artifacts remain byte-identical.

## 4. Candidate-first typography contract

Build one historical-theme baseline and then a complete repaired candidate
set in fresh temporary directories outside the project. Before candidate
work, require:

- exact decoded PNG reproduction of the four current PNGs;
- PDF page geometry and rendered visible-content equivalence after excluding
  nondeterministic PDF metadata; and
- exact equality of every ggplot layer's scientific coordinates, groups,
  panel assignment, values, intervals, marks, scale breaks, labels, colours,
  shapes, and ordering.

The repaired candidates may change only essential typography, plot margins,
panel spacing, label wrap width, and canvas height. Width, scale multiplier,
and 300 DPI remain fixed. Canvas height may increase by no more than 25
percent. No panel, point, interval, reference line, axis meaning, category,
legend item, or label meaning may be added, removed, or reordered.

R 4.6.1 reproduces the minimum nominal text sizes needed for a 7-point
effective floor:

- 16.472648 pt for the 10.5-inch base-width figures; and
- 12.550589 pt for the 8-inch paired-placement figure.

Therefore require every essential text element to be at least 17 pt in the
primary-effects and both diagnostic candidates, and at least 13 pt in the
paired-placement candidate. Candidate values may not exceed 20 pt and 16 pt,
respectively. The final computed effective minimum must be at least 7.0 pt at
both 170 mm and the 643-pixel final-size display used by the stopped QA.

Inspect the complete candidate set at original size, 170 mm, 708 pixels, and
the 720 by 500 200-percent-equivalent view. Require no clipping, overlap,
missing label, illegible mark, broken legend, or excess whitespace that blocks
reading. If candidate validation fails, return one stopped package before any
durable promotion.

## 5. One eight-file promotion and direct current evidence

After all four candidates pass together, promote the eight PNG/PDF files
together exactly once. Do not promote one family early. Record:

- the exact eight-file preimage and postimage ledger;
- the frozen-source inventory;
- a no-scientific-call audit of the refresh implementation;
- the ggplot-layer equality audit;
- geometry, typography, PDF, pixel, and visual validation;
- exact builder and figure-manifest forward and reverse proofs; and
- a new non-circular current display manifest.

Do not run a broad manifest builder. Do not rewrite any historical Stage 3 or
preparation manifest. Classify their exact historical-to-current display
transitions only in the new order evidence and fail on any additional path.

## 6. Complete pre-render gate

Before Quarto, require:

1. all frozen input and protected identities exact;
2. all 17 result R chunks parse under R 4.6.1;
3. the dedicated focused display test passes in full;
4. all three source CSVs remain exact and all candidate scientific layers
   reconcile exactly to them;
5. all eight durable outputs are candidate-identical;
6. the builder and four figure-manifest rows match the approved display
   parameters and reverse exactly;
7. the historical tests and historical manifests remain byte-identical;
8. Air and R parse pass for both new R files, and scoped `git diff --check`
   passes; and
9. static call and input auditing proves no model, fit, refit, prediction,
   simulation, bootstrap, resampling, inference, p-value, FDR, diagnostic, or
   scientific source-data computation occurred.

Stop without rendering on any failure.

## 7. Exactly one H09 result rerender

After the complete pre-render gate passes, create one fresh, empty, absolute
semantic-audit directory and issue exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=<accepted-R-4.6.1-project-library> \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> \
quarto render notebooks/hypotheses/H09.qmd --profile nathealth
```

Use the accepted R 4.6.1 library and Quarto 1.9.37. Do not bypass the normal
profile or semantic hook. No second render is authorized.

## 8. Post-render acceptance

Against the fresh result HTML, require:

1. exactly 11 native gt tables, four figure endpoints, 23 link occurrences,
   and the accepted endpoint order;
2. semantic-hook `REPAIRED` or already-valid equivalent, exact reverse and
   forward evidence, unique document IDs, and every explicit `headers` token
   resolving once to its intended `th` inside its own table;
3. all result-page scientific, FDR-family, score-direction, instrument,
   deviation, reciprocal-link, navigation, and country-label contracts from
   order 56;
4. exact reconciliation of the four rendered images to the promoted durable
   PNGs and their frozen paired source CSVs;
5. zero error, warning, stderr, unresolved cross-reference, unsupported link,
   or local-path leakage; and
6. exact protection of the companion source and HTML, profile, historical
   tests and manifests, source CSVs, scientific artifacts, and unrelated
   document sets.

Classify the build delta explicitly. Only the H09 result HTML, source-identical
QMD copy, eight target-owned figure copies, search, sitemap, ordinary
source-identical target resources, and bounded semantic evidence may differ.
Keep the phase-4 corpus manifest unchanged in this result-only order.

## 9. Secure loopback QA and one combined return

After nonvisual acceptance, serve `_build/nathealth` read-only on one unused
high port bound only to `127.0.0.1`. Inspect the complete H09 result at 1440 by
1000, 708 by 1000, 720 by 500, and exact 170-mm figure width. Inspect all 11
tables and all four figures, including final-size typography, axes, legends,
symbols, panels, captions, disclosures, links, navigation, clipping,
wrapping, overlap, and overflow.

Stop the server, prove no listener remains, reset the viewport, close the QA
tab, and prove complete post-QA build and protected stability.

Return one non-circular completion package with exact commands, versions,
preimages, postimages, source and layer reconciliation, candidate history,
semantic reversal, screenshots, build and protected deltas, and server
lifecycle. If a genuinely new defect appears, complete all safe read-only
checks and return one consolidated stopped package. Do not patch or rerender
inside this order.

## Prohibitions

No result or companion QMD edit, companion render, source-data edit, model,
fit, refit, prediction, simulation, bootstrap, resampling, estimate, interval,
p-value, FDR decision, diagnostic calculation, sensitivity, scientific
artifact regeneration, full builder, broad manifest builder, historical test
or manifest rewrite, profile, package, lockfile, ledger, later render,
full-project render, commit, push, upload, or publication action is authorized.
