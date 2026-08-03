# DISPLAY-001 final visual repair proposal

## Finding

Direct inspection of the final latitude–photoperiod raster found that its nine
direct labels still used internal site codes (`RISE`, `THUAS`, and so on).
The plotted order and colours already came from
`config/site_display_registry.csv`, but the visible text did not satisfy
DISPLAY-001.

## Proposed repair

- Join no new data and change no analytical field.
- Derive the direct label text with the existing registry-backed
  `replica_site_label()` helper in both descriptive latitude plotting helpers.
- Add a durable SVG assertion that all nine registered display names occur in
  exact registry order.

## Scientific impact assessment

The repair changes no site code in data, participant-day, photoperiod value,
latitude, density, point, colour, order, statistic, or interpretation. It
changes only reader-facing label text and its type size.

## Decision

Approved for implementation in the descriptive-only plotting module, followed
by a targeted rebuild, deterministic test, render, and renewed visual and
read-only audit checks.
