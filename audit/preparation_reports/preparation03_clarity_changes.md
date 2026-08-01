# Preparation 03 clarity and display record

Date: 2026-08-01

Source: `notebooks/preparation/03_reference_profiles.qmd`

Rendered HTML:
`_build/nathealth/notebooks/preparation/03_reference_profiles.html`

## Meaning preserved

- Inputs remain the near-eye and chest one-minute artifacts that passed
  Preparation 02 Rule A; the complete hybrid 24-hour day still includes
  bedside measurements during diary-defined sleep.
- Actual-time observations remain unchanged. Repeated autumn local-clock
  values are averaged only in the separate learning copy, after diary-period
  selection in actual time.
- Intensity profiles still take the within-participant median for each
  30-minute period and then the median across participants.
- Strict-threshold distributions still use the fraction of valid minutes with
  melEDI strictly greater than 250 lx, balanced first across participant-days
  within participant and then across participants.
- Pooled, site-specific, and leave-one-site-out profiles; 20- and
  5-participant minima; unsupported-period retention; and the prohibition on
  interpolation remain unchanged.
- Only the additive missing-dose correction may alter a metric value. M10,
  L10, threshold-timing, and MDER maps remain support-only. No L5 map was
  introduced.
- No profile, support flag, probability, relevance weight, artifact, or
  downstream metric was recalculated or changed.

## Reader-facing changes

- Replaced the profile builder call and raw `kable` output with direct reads of
  the accepted manifest, settings, provenance, support tables, fixed profiles,
  timing distributions, and relevance maps.
- Added the page purpose, exact inputs, its position between Preparations 02
  and 04, an explicit render boundary, and an accessible process diagram.
- Explained the scientific operations in their production order, including
  participant balancing, actual-time versus local-clock handling, strict
  threshold timing, support minima, unsupported periods, and map permissions.
- Added 11 semantic `gt` tables. Narrative-heavy script and artifact maps use
  38%/62% two-column layouts; other displays use compact comparison columns
  with explicit widths.
- Added an accessible stored-data figure of the pooled full-day melEDI and
  illuminance profiles, with a paired link to
  `artifacts/04_reference_profiles/reference_profiles.csv`.
- Applied PREP-002: current identity and stored-support checks are reported as
  current; the 394-of-394 independent reconstruction is explicitly limited to
  preceding manifest
  `c8e02302521360d3a5cb18f49e0a97aed4a1f0ea64343ead68bde274cddce10d`;
  current-manifest reconstruction remains open as FIND-043. The page states
  that this provenance gap is not evidence of an incorrect current artifact
  or downstream result.

## Verification

- Static and rendered-HTML bounded-render test: **PASS**.
- Final-profile page-specific read-set baseline: 39 entries; SHA-256
  `4a2246964c999d175474c09f63d63a3129bb7ad29f71ca18d10ed34df4335550`.
- Final post-render comparison: 39 unchanged, 0 mismatches.
- Current reference-profile manifest SHA-256:
  `5e08099602682a4b951b0304764f341932ef2f03ccd4c62f32793ea82084e062`.
- Rendered HTML SHA-256:
  `ea612c208c7f1113dc2f95bebac47eb28f4505831888c74d1e4a716d917c0188`.
- Rendered HTML contains 11 semantic `gt` tables, 13 resolved table/figure
  captions, one empirical image with alt text, and no unresolved table or
  figure cross-reference.
- Render context: R 4.6.1, `gt` 1.3.0, `ggplot2` 4.0.3, and Quarto 1.9.37
  using the `nathealth` profile.

## REPORT-011 figure and layout QA

- The empirical figure was inspected at its final 7.6-by-5.4-inch aspect
  ratio. Axis and legend text are 9 pt; axis titles and facet labels are
  10 pt.
- The final order is melEDI above illuminance, matching the alt text.
- No clipping, cropping, overlaps, distorted text, awkward wrapping, broken
  units, compressed data region, or legend imbalance was observed.
- Near-eye and chest lines remain distinguishable by both colour and point/
  line position; the source values are visible without relying on colour
  alone.
- Long hashes are supplied with invisible wrap opportunities, and explanatory
  prose is not placed in a narrow residual table column.
