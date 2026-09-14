# H10 preparation-figure readability QA

Date: 2026-08-12  
Overall outcome: PASS

## Inspection basis

The two preparation-companion PNGs were placed without enlargement at their
declared 170-mm display width on separate A4 portrait QA pages. The A4 pages
are inspection scaffolds only and are not final assets. The proof is
`artifacts/12_manifests/H10/H10_preparation_figure_A4_proofs.pdf`.

Both source rasters are 2,820 pixels wide at 300 dpi and use a 9.4-inch base
canvas. At 170 mm, the reduction factor is 0.712. The smallest effective
essential text is 6.05 pt and central text is 7.12 pt, meeting the physical-
size thresholds.

## Figure-level inspection

- `fig-h10-prep-age-distribution` — PASS. Both placement panels, all submitted
  site labels and colours, boxplots, participant marks, measured-biological-
  sex shapes, age axis, and legend are readable. There is no clipping,
  overlap, distortion, awkward wrapping, or excess whitespace. The blank
  Tübingen row in the chest panel correctly communicates that this site has no
  chest sample.
- `fig-h10-prep-sample-support` — PASS. All 17 metric labels, the participant-
  level and participant-day facets, both placement marks, percentage axis,
  reference line, and legend are readable. Wrapped labels do not compress the
  data region, and the near-eye and chest marks remain distinguishable.

Both figures show age or fitted-row proportions, not nonnegative strongly
right-skewed melEDI-like response values. The symlog display rule is therefore
not applicable. Each PNG has a paired native PDF and an exact source-data CSV.
