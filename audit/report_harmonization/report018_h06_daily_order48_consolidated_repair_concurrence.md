# REPORT-018 H06_daily order 48 consolidated repair concurrence

Date: 2026-08-21  
Disposition: **APPROVED_FOR_ONE_CONSOLIDATED_REPAIR_AND_RERENDER_ORDER**

## Controlling stopped-state authority

The controlling independent stop acceptance is:

- `audit/report_harmonization/report018_h06_daily_order48_stopped_independent_acceptance.md`,
  SHA-256
  `a0864132f3d9a860f178494f080ea02b7c56e873a6c5d0704398a7ac7d7da244`,
  6,096 bytes;
- its 24-row non-circular manifest, SHA-256
  `c963b3cea63e11258e5bf2bd8c76b926545896c7a8a169406d94c390519f34fc`;
  and
- the independent checker, SHA-256
  `5705f04a16abb7389b32d6d2c0aa53baa2c214c6603864711d20cf31e998e563`.

The checker and manifest have been independently replayed under R 4.6.1.
All 108 owner rows are exact. The accepted stopped result HTML is
`15c537269ac0be96ce06c6b574946dc0b98d46afe36c3c696f804a216a7d0c76`
at 11,691,631 bytes.

There are exactly two genuine display defects and no scientific, semantic,
link, navigation, protected-input, or integration defect. One consolidated
continuation is authorized so the page can reach REPORT-018 acceptance without
separate source, artifact, and render loops.

## A. Exact table-source repair

In `notebooks/hypotheses/H06_daily.qmd`, change only the predicate inside the
live `placement_table()` helper from:

```r
filter(.data$predictor_id == predictor_id)
```

to:

```r
filter(.data$predictor_id == .env$predictor_id)
```

The identical expression inside the unused `primary_table()` helper must stay
frozen. It did not create a rendered defect and is outside this repair.

The only accepted QMD transition is:

- preimage
  `01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08`,
  65,344 bytes;
- postimage
  `8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639`,
  65,349 bytes.

Require exact forward diff and reverse reconstruction. Before rendering, an R
4.6.1 focused contract must prove three distinct predictor subsets, each with
exactly 60 source rows, 15 metric slots, and four placement scenarios. After
rendering, Tables 5 through 7 must have distinct bodies, 15 metric rows and
four placement columns each, with every displayed cell reconciling to its
predictor-specific frozen source row.

## B. Dedicated display-only refresh

Add one H06_daily-owned R 4.6.1 refresh implementation and one focused
verifier. The refresh may read only:

- ratio source
  `c7a1c0018e82db71e2fb0fe74d6e3e5a6645948017b10dd938fce18f6c5c2a9d`;
- absolute source
  `2b695be686e6fdfdef9bdad4082be1fdcd1100e0d3d763fac35b4a75b8df11a7`;
- FDR source
  `4a9a7c3f0877872e2efe7bfddd73afac1c50299f60474bd8d328ce945f17ddf1`;
- site-deviation source
  `12193a0a1795fe478bf4829a3986c2b1290510038e4c4aed59aa7e61714bcbcc`;
  and
- `config/site_display_registry.csv`, SHA-256
  `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`.

It must not read a model, fitted object, inferential RDS, analytical frame, or
broad scientific manifest. Do not edit or execute any broad historical
builder.

The refresh must first reconstruct the current figures with the historical
theme in a temporary baseline directory. Accept exact bytes when the device is
deterministic. If only serialization metadata differs, require decoded PNG
pixels to be identical and normalized SVG content to be identical. Any visible
or geometrical baseline difference stops before candidate work.

Then create candidates outside durable targets. Bounded candidate iterations
are allowed before the first durable write, but only typography, plot margins,
panel spacing, label wrap width, and canvas height may vary. Output width and
DPI stay fixed. Canvas height may increase by at most 15 percent if needed to
avoid collisions. No data layer, scale, break, label meaning, facet, panel
order, category, colour, shape, line, point, interval, or null reference may
change.

Every essential text role must reach at least 7.0 pt at both 170 mm and the
642-pixel narrow display. The prospective nominal floors at the current widths
are:

- 12.6 pt for the two 12-inch primary figures;
- 12.5 pt for the 11.8-inch FDR overview; and
- 10.8 pt for the 260-mm site-deviation figure.

Nominal essential-text sizes may be increased only within these bounded
ranges during candidate validation:

- 12.6 to 14.0 pt for the primary ratio and absolute figures;
- 12.5 to 14.0 pt for the FDR overview; and
- 10.8 to 12.0 pt for the site-deviation figure.

Candidate validation must cover original size, 170-mm width, 708-pixel page
width, and the 200-percent-equivalent view. Require all labels, panels, axes,
legends, symbols, and disclosures present, with zero clipping or overlap.

## C. One canonical display transition

After one complete candidate passes, preserve exact recoverable copies of the
six current preimages in owner evidence and replace only:

1. `H06_daily_non_l10_production_primary_ratio_effects.png`, current SHA-256
   `a50f6b25c1c09abca1700870594d26a15e2085ec1c2a4c8eb5f6bc0f727cfa66`;
2. `H06_daily_non_l10_production_primary_absolute_effects.png`, current
   SHA-256
   `da67b5f8a27b49d7c4d0e6426563d79aaa540ef835e350d02fd952a3a134c686`;
3. `H06_daily_stage3_fdr_overview.png`, current SHA-256
   `48283afc83e9ebcd0f7d02177dacc162287940126c335b47efab11cc54c9edd9`;
4. `H06_daily_stage3_fdr_overview.svg`, current SHA-256
   `ef8a3ba3d502804c5b7a01f9d21fada9d598006b8d6fcd83f0c721bd96dbda84`;
5. `H06_daily_stage3_primary_site_deviations.png`, current SHA-256
   `a1ddd2ae719d5a6ab11c1c591801d4b4aa7cb06f9eb0bcad7c983d8024fd86e1`;
   and
6. `H06_daily_stage3_primary_site_deviations.svg`, current SHA-256
   `b23f9a6838c2ecc476bdb5e68c203e0c7a85d05479a65841f75ee02d21e20b1c`.

The six-file candidate set must be promoted together once only. Figure 5,
`H06_daily_temporal_h02_primary_context_functions.png` at SHA-256
`e28c639f23b3f33687ca046a77069153bb66073d29cd03d96fd03408c4317d98`,
must remain byte-identical.

Preserve the four paired source CSVs and every scientific value exactly. Do
not rewrite historical H06_daily tests or manifests. Record the QMD and six
display transitions in a new current, non-circular order manifest and visual
provenance package. This new evidence is the direct current display reseal.

## D. One result rerender and complete acceptance

Only after sections A through C pass, create one fresh empty absolute semantic
directory and issue exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H06_daily.qmd --profile nathealth
```

Use normal R 4.6.1 project and `renv` startup with only the established narrow
access to the existing user-owned cache. Do not bypass the profile or semantic
hook.

Repeat the complete order-48 acceptance package against the new result HTML:

- exactly 14 native `gt` tables, five figures, seven dynamic links, and the
  accepted endpoint order;
- semantic repair with exact reverse and reapplication, unique IDs, and every
  explicit `headers` token resolving exactly once inside its own table;
- predictor-specific Tables 5 through 7 with complete source reconciliation;
- all figure and paired-source relationships, captions, alt text, links,
  anchors, navigation, hierarchy, and country-coded sites;
- zero embedded error, warning, stderr, unresolved cross-reference, or raw
  trace;
- full build and protected inventories, with only the approved QMD, six
  display files, target-owned resource copies, result HTML, search, sitemap,
  and bounded new evidence classified; and
- secure loopback QA at 1440 by 1000, 708 by 1000, 720 by 500 as the
  200-percent-equivalent view, original figure sizes, and 170-mm figure width,
  followed by complete teardown and post-QA identity proof.

Return one combined completion or one combined stopped-state package. If a
genuinely new defect appears, do not patch or rerender.

## Prohibitions and serial hold

No source-data edit, model, fit, refit, prediction, estimate, interval,
p-value, FDR decision, diagnostic, sensitivity, inference, scientific
artifact regeneration, broad builder, historical test or manifest rewrite,
companion edit or render, later render, full project render, profile, package,
lockfile, ledger, commit, push, upload, or publication action is authorized.

The H06_daily companion and every later REPORT-018 target remain held pending
independent result-page acceptance.
