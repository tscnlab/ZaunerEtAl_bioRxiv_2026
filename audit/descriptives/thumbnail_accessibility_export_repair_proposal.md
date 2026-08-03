# Metric-thumbnail accessibility export repair proposal

Date: 2026-07-31

## Finding

The final `gt` object contains 17 metric-specific `alt` attributes on the
miniature distribution images, but the rendered Quarto HTML removes those
attributes while rewriting the embedded data-URI images. The visible table and
stand-alone PNG export are correct, yet the final HTML leaves the redundant
thumbnail images without an accessible treatment.

## Proposed repair

For each thumbnail cell, add a metric-specific text description in an inline
visually hidden span and mark the image itself as decorative with
`aria-hidden="true"`, `role="presentation"`, and an empty `alt` attribute.
Use complete inline hiding CSS so the description remains non-visible in the
stand-alone `gtsave()` screenshot as well as the Quarto page. Retain the exact
submitted ridge geometry, dimensions, table values, and table styling.

## Scientific impact

None. This changes HTML accessibility markup only. It must not change table
data, estimates, denominators, plot values, or the visible table export.

## Acceptance criteria

- The stand-alone metric-table PNG remains 3420 × 4288 pixels and has no
  visible hidden-description text.
- The rendered HTML contains 17 metric-specific hidden descriptions and 17
  decorative-image markers.
- Clean-session table, manifest, and render tests pass.
