# H09 Stage 3 observed-pattern composite: source-only verification

Date: 2026-08-24

Status: **SOURCE-READY; RENDER AND BROWSER QA DEFERRED**

## Authorized scope

This bounded change adds one reader-facing composite to
`notebooks/hypotheses/H09.qmd`, one display-only R builder, one focused test,
paired source data, PNG/PDF assets, one figure-manifest row, and this
source-only evidence. It does not change a fitted model, result table,
multiplicity decision, registered outcome, or accepted interpretation.

No Quarto command was run. Neither accepted H09 HTML was written. The result
HTML remains SHA-256
`901fd63b45182be70ef77166c418633220a7226d86f52e14d1c79afbfc7cdd16`;
the companion HTML remains SHA-256
`09b604b011ef14c138c15720b419a9ca200e15f71ce3e40a9b85c23f6803f96d`.

## Accepted panel roles and caption scope

- **Panel A:** six primary near-eye associations that meet the stored,
  instrument-specific five-outcome FDR rule. Site-coloured and site-shaped
  points are exact fitted participant-days. Black lines are
  equal-site-average fixed-effect relationships from the accepted
  site-adjusted REML main-effect models with random effects set to zero. Grey
  ribbons are 95% confidence intervals for those mean relationships. The
  panels retain MCTQ MSFsc and MEQ as distinct constructs and show M10
  midpoint, L10 midpoint, and first time above 250 lx melEDI for each.
- **Panel B:** descriptive participant-level MCTQ MSFsc and MEQ distributions
  in submitted site order and colours. This panel is not an inferential site
  comparison. It contains 185 complete MCTQ records and 186 complete MEQ
  records from the pinned aggregate chronotype input.
- The caption states that the preceding forest plot retains all ten primary
  near-eye estimates, so the focused observed-data panels cannot be read as a
  replacement for the complete inferential display.
- L10 retains the accepted linear nighttime coordinate. Reader-facing tick
  labels convert that coordinate back to clock time.

## Scientific-preservation checks

The focused R 4.6.1 test completed successfully. It verified:

1. all ten registered primary near-eye frame identities before selecting the
   six stored FDR-supported targets;
2. 4,701 exact participant-day point rows from six frozen frames;
3. 606 line/ribbon rows, 101 per target, read from the paired CSV before
   plotting;
4. equality of every stored line slope to the accepted result and equality of
   each stored-fit covariance-derived slope CI to the accepted 95% CI;
5. equal-site sum contrasts in every contributing accepted model;
6. 371 de-identified participant-level chronotype rows from the pinned input;
7. submitted site names, ordering, colours, and shape-based site distinction;
8. absence of participant IDs, dates, model-row IDs, and raw p-values from the
   paired source CSV; and
9. absence of model-fitting, model-update, smoothing, and resampling calls in
   the display builder.

The builder plots the paired CSV after its numerical round trip. The CSV has
5,678 rows and 34 columns: 4,701 participant-day rows, 606 stored-model
line/ribbon rows, and 371 participant-level chronotype rows. It contains the
stored adjusted p-value and FDR decision only where needed to identify Panel A
targets. It does not contain a raw p-value column.

Command:

```text
NATHEALTH_PROJECT_ROOT=<project-root> RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla tests/hypotheses/H09/test_h09_stage3_observed_figure.R
```

Result:

```text
H09 Stage 3 composite checks passed: six frozen FDR-supported primary near-eye associations, exact equal-site-average lines and 95% CIs, 371 de-identified participant-level chronotype rows, registered sites, paired plotting data, and no model fitting
```

R was 4.6.1. Consequential package versions were digest 0.6.39, dplyr 1.2.1,
ggplot2 4.0.3, lme4 2.0.1, patchwork 1.3.2, png 0.1.9, ragg 1.5.2, and
readr 2.2.0.

## Reader-table handoff

A safe compact table preview omits raw p and uses:

1. Outcome
2. Instrument and coefficient unit
3. Estimate
4. 95% CI
5. FDR-adjusted p-value, with significance decided before formatting
6. Exact fitted sample: participants, participant-days, observations, hours,
   and sites

## Exact source-ready identities

| Artifact | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/hypotheses/H09.qmd` | `9db9671d61b39a81fa83b234e08832cef516ee91688ac8bc4150385629648df9` | 39,543 |
| `scripts/hypotheses/H09/build_h09_stage3_observed_figure.R` | `5c9c1cf58267471157335382f1271cd499020d9a70d380ca655ba72f0cc11712` | 27,063 |
| `tests/hypotheses/H09/test_h09_stage3_observed_figure.R` | `2d61b4c1f9355c093a8503216978a29163eeb26a14d13f65424dd9ba15e92356` | 7,148 |
| `artifacts/10_figures/H09/H09_observed_timing_patterns.png` | `a23cb2a9a90a232ae9bf3f94ec7b1c5ac0e3c83933d056c0920ffd59e8e0eb59` | 2,064,948 |
| `artifacts/10_figures/H09/H09_observed_timing_patterns.pdf` | `6912f7b1730219f5ece1d78c69fa96db0497156066fce9c9329039240d6293f3` | 148,889 |
| `artifacts/11_source_data/H09/H09_observed_timing_patterns_data.csv` | `34640aba210181b973902e00cd6924f79f6ae76faf01fa3c5b66078e2e2e7cee` | 3,028,981 |
| `artifacts/12_manifests/H09/H09_figure_manifest.csv` | `19d9bc31a342e7fca4082634d0fe4748050f1eefd57788973bf018355b4683f1` | 5,484 |

The figure is 4,725 by 3,825 pixels. The recorded 17 pt smallest essential
nominal text yields 7.224 pt at the intended 170 mm display width, above the
7 pt floor. Local original-dimension inspection found no clipping, overlap,
or missing panel. Final HTML, narrow, 200-percent-equivalent, and final-size
browser QA remain explicitly deferred to the separately authorized H09
render.

## Non-circular seal

`artifacts/12_manifests/H09/H09_stage3_observed_figure_source_seal.csv`
contains 24 unique live-exact members and excludes itself. Independent R 4.6.1
recalculation passed 24/24 hashes and byte counts.

Seal SHA-256:
`26cecf7b8482850899c3b1f7e399a6c7be2e3695e04dd0eb7093400f489431ab`
(3,666 bytes).
