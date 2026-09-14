# H06 preparation figure readability and layout review

Inspection date: 2026-08-11

Inspection basis: the three final PNG assets were placed without added page
canvas at 170 mm on separate A4 portrait pages with 20-mm side margins. The
resulting three-page physical-size proof was inspected together with the direct
Quarto HTML render.

## Physical-size calculation

| Figure | Native canvas | Native width | Intended width | Scale factor | Smallest essential nominal text | Effective final text |
|---|---:|---:|---:|---:|---:|---:|
| `fig-h06-prep-response-distribution` | 1920 × 1113 px | 254.0 mm | 170.0 mm | 0.669 | 12 pt | 8.03 pt |
| `fig-h06-prep-site-day-activity-support` | 2112 × 1536 px | 279.4 mm | 170.0 mm | 0.608 | 12 pt | 7.30 pt |
| `fig-h06-prep-clock-support` | 1920 × 1152 px | 254.0 mm | 170.0 mm | 0.669 | 12 pt | 8.03 pt |

All essential text remains at least 7 pt after scaling.

## Visual inspection

### `fig-h06-prep-response-distribution`

- Clipping/cropping: PASS. Both panel titles, subtitles, placement labels,
  endpoints, and axes remain within the 170-mm figure canvas.
- Overlap/wrapping/distortion: PASS. The percentile key and exact-zero subtitle
  remain separate and readable; labels do not collide with marks.
- Data-region balance: PASS. The positive-value and zero-share panels give
  sufficient space to their different scales without leaving an ambiguous
  visual gap.
- Marks and text: PASS. Thin and thick intervals, filled medians, open P99
  points, colours, true symlog ticks, percentages, and units remain distinct.

### `fig-h06-prep-site-day-activity-support`

- Clipping/cropping: PASS. All nine site labels, both placement headings, four
  joint-category labels, and the two legends remain inside the final canvas.
- Overlap/wrapping/distortion: PASS. Wrapped category labels align with their
  columns and no symbol obscures a site label or legend key.
- Data-region balance: PASS. The two placement panels remain aligned, with the
  legends close enough to interpret without compressing the data region.
- Marks and text: PASS. Site colours, support-size differences, filled circles,
  and open sparse-cell circles remain distinguishable at final size.

### `fig-h06-prep-clock-support`

- Clipping/cropping: PASS. The repaired two-row legend and both panels are fully
  contained; the title, axis titles, clock ticks, and category labels are not
  cut off.
- Overlap/wrapping/distortion: PASS. Legend rows do not collide and the line
  encodings remain visually separate across the full 24-hour range.
- Data-region balance: PASS. Near-eye and chest receive equal space, and the
  compact legend does not dominate the figure.
- Marks and text: PASS. Four colours, solid/dashed activity encodings, points,
  grid lines, participant-hour values, and local-clock labels remain readable.

Captions and alt text are present for all three figures in the Quarto source
and direct HTML render. No clipping, overlap, unexpected wrapping, shape or
text distortion, or unbalanced data region was observed.

Overall outcome: PASS
