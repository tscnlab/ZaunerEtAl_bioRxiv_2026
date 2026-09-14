# H06 daily source harmonization verification

Date: 2026-08-13

Status: accepted source-only editorial revision; baked-label figure repair and
all rendering remain pending

## Scientific and editorial identities

The historical scientific baseline remains commit
`442ddd1b592374440f1446c26234c5d6e12cce92`, sealed centrally under
H06-D-016/CHG-135 and H06-D-017/CHG-136. Its reader-source identities are:

- result: `0318fd6cf874380631296d35095486b9de7f987a9779e4dc5d59c5a635a8c3dc`;
- preparation companion:
  `fdfe94cf96e16ecfff3455c3e2427bd94c6419ee62350211a724821870058c0e`.

REPORT-014 order 20 produced the separate provisional editorial identities:

- result: `01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08`;
- preparation companion:
  `ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709`.

Only those two owner QMDs changed in the order-local diff. No shared file,
scientific output, source-data file, model, test result, or accepted baseline
record changed.

## Independent source review

The revised pair passes the approved harmonization contract:

- The hourly H06 analysis is identified as the main H06 result. H06 daily is
  consistently described as complementary, preregistration-oriented evidence.
- Result and companion link to each other through relative `.qmd` targets. Both
  link dynamically to main H06.
- DEV-015, DEV-030, DEV-031, and DEV-032 still link to their exact stable
  anchors in `notebooks/preregistration_deviations.qmd`.
- The result now uses `site-average estimate` or its context-specific ratio and
  contrast forms, with an equal-weight explanation. It uses
  `predictor-by-site interaction`, explained as allowing an association to
  differ among sites.
- A compact `How to read the estimates` glossary explains site-average
  estimates, predictor-by-site interactions, pointwise 95% CIs, FDR
  adjustment, participant random intercepts, common samples, model checks, and
  AR(1).
- The nonlinear GAMM is explained before the abbreviation is used as a reader
  shorthand. The exact `mgcv::bam()` engine and formula remain in the detailed
  exploratory method section.
- Shifted-log and back-transformed quantities retain the accepted formula,
  describe the original reader unit, and distinguish geometric-mean-like
  values of `Y + 0.1` from raw arithmetic means.
- Literal site names in prose carry the ISO alpha-2 country code. Dynamic site
  displays continue to read `config/site_display_registry.csv`.
- Reader text and display labels contain no `BH`, `equal-site`, unexplained
  heterogeneity shorthand, `submitted site colours`, hard-coded internal HTML,
  `_build`, `file://`, or absolute local path. Internal object names remain
  unchanged in code.
- Color is described as a site identifier rather than a significance encoding.

The extended Answer in brief callout is retained as a documented
H06-daily-specific structural departure. It must summarize three contexts over
15 registered daily metrics, the interaction qualification, the exploratory
joint model, and the complementary time-of-day analysis without suppressing
the non-estimable L10 and qualified MDER results. The compact glossary remains
outside the callout. Final information hierarchy and appearance remain
provisional for the later author visual review.

## R 4.6.1 preservation check

`scripts/report_harmonization/check_h06_daily_order20_source.R` compares both
current sources with commit `442ddd1b592374440f1446c26234c5d6e12cce92`.
The final run under R 4.6.1 passed:

- 15 result chunks and one inline R expression parse without execution;
- 19 companion chunks parse without execution;
- chunk-label sets, figure and table identifier sets, artifact-reference sets,
  literal formula blocks, and unique numeric-token sets are unchanged;
- seven result and two companion dynamic QMD links resolve, including all
  requested anchors; and
- the forbidden reader-link and vocabulary checks pass.

The owner additionally showed that eight result chunks and four companion
chunks changed only reader-facing display strings or labels. No prepared
object, formula, value, filter, join, row order, or scientific computation
changed. `git diff --check` passes for the pair.

No QMD was rendered and no R chunk was executed during order 20. The only R
execution in this independent review was the non-analytical static parser and
source-preservation check above.

## Held display artifact

Static visual inspection identified one remaining baked term:

`artifacts/10_figures/H06_daily/H06_daily_stage3_primary_site_deviations.png`

The image already displays all nine study-site names with country codes, but
its title, subtitle, and footer still say `equal-site`. Its accepted pre-repair
identity is
`69fd3786901993e9e9c0cfb3432abde07fbed14ccac03bea08ed9ea55751400c`
(3070 by 4251 pixels). The frozen plot-source CSV remains
`12193a0a1795fe478bf4829a3986c2b1290510038e4c4aed59aa7e61714bcbcc`.

This image must be repaired in a separate display-only operation using the
frozen plot-source data, with no model fit, estimate, interval, p-value,
diagnostic, source-data, main-H06, shared-file, or QMD-render change. The
repair requires pre/post identities and final-size visual QA.

H06 daily therefore remains outside `_quarto-nathealth.yml` and outside the
active REPORT-017 render sequence. Profile integration may be requested only
after the image repair is independently accepted.
