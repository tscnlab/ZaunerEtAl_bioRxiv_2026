# H06_daily Order 21 independent display acceptance

Date: 2026-08-13

Scope: REPORT-014 display-only Order 21

Verdict: **ACCEPTED**

## Accepted change

The refreshed
`artifacts/10_figures/H06_daily/H06_daily_stage3_primary_site_deviations.png`
is accepted. Its SHA-256 changed from
`69fd3786901993e9e9c0cfb3432abde07fbed14ccac03bea08ed9ea55751400c`
to
`a1ddd2ae719d5a6ab11c1c591801d4b4aa7cb06f9eb0bcad7c983d8024fd86e1`
because the three authorized baked labels changed from `equal-site` to
`site-average`. Dimensions remain 3070 by 4251 pixels, RGB, at 300 dpi.

The dedicated display script reads only the frozen figure CSV and site display
registry, validates their accepted identities and structure, and writes only
the authorized PNG. Static inspection found no model load, prediction,
inferential calculation, source-data write, Quarto invocation, or broad-builder
execution. The accepted plot-construction comparison preserves mappings,
ordering, layers, scales, facets, geometry, colours, dimensions, and theme.

## Independent checks

The durable check
`scripts/report_harmonization/check_h06_daily_order21_display.R` ran under R
4.6.1 and passed:

- all 13 owner-manifest paths, SHA-256 identities, and byte counts;
- all 34 protected paths, SHA-256 identities, and byte counts; and
- both visual-QA views, at original resolution and a 170 mm final-width proxy.

Independent visual inspection confirmed the revised title, subtitle, and
footer, all ten interaction panels, all nine country-coded site labels per
panel, readable text, intact points and confidence intervals, and no clipping,
overlap, uncoded site label, or visible `equal-site` wording.

The checker's first durable invocation stopped because its own use of
`identical()` compared a named vector with an unnamed vector. Adding
`unname()` repaired only the checker. No scientific, source, display, or
manifest file changed as a result. The final invocation exited successfully.

## Preservation boundary

The frozen plot CSV, site registry, accepted Order 20 QMDs, protected SVG,
historical alt-text record, main H06 material, shared configuration, models,
accepted scientific outputs, and all other protected identities are
byte-identical. No estimate, interval, p-value, FDR decision, diagnostic,
sensitivity, sample, source-data row, or claim changed. No Quarto render,
commit, push, or shared-profile edit occurred.

## Integration disposition

Orders 20 and 21 are independently accepted. H06_daily may now receive the
bounded coordinator-owned source-only profile placement immediately after the
main hourly H06 result and its preparation/provenance companion. The
complementary H06_daily result and its own companion must remain adjacent.

This acceptance does not release an H06_daily render. Its focused render and
loopback visual QA remain held until the active REPORT-017 serial queue reaches
H06_daily. Hourly H06 remains the main analysis and H06_daily remains
complementary evidence.

The non-circular acceptance manifest is
`audit/report_harmonization/h06_daily_order21_display_acceptance_manifest.csv`.
