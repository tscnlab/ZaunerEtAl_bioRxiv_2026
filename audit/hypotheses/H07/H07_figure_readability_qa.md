# H07 reader-facing figure readability QA

Date: 2026-08-07
Policy: REPORT-011
Overall outcome: PASS

## Physical-size basis

All four reader-facing PNGs use tightly bounded canvases and were inspected at
an intended display width of 170 mm on A4 portrait pages with 20-mm side
margins. The two results figures use 9 × 18-inch source canvases at 270 dpi
(2430 × 4860 pixels). Their display-reduction factor is 0.743657: essential
10.5-pt text resolves to 7.81 pt and central 12-pt text to 8.92 pt. The two
preparation figures use 8.5-inch-wide source canvases at 300 dpi. Their
display-reduction factor is 0.787402: essential 10-pt text resolves to 7.87 pt
and central 11-pt text to 8.66 pt. All calculated effective sizes exceed 7 pt.

The two 340-mm-tall results figures cannot fit on one A4 page at the intended
width. Each was therefore inspected in two contiguous, non-overlapping page
crops at exactly 170-mm display width; together the two crops cover the full
figure without further reduction. Each preparation figure was inspected whole
at exactly 170-mm width. The six QA-only raster proofs are indexed in
`artifacts/12_manifests/H07/H07_figure_A4_proof_index.csv`. A4 page geometry is
not part of any final figure asset.

## Figure-level inspection

| Proof page(s) | Figure ID | Result |
|---:|---|---|
| 1–2 | `fig-h07-near-smooth-derivative-pairs` | PASS |
| 3–4 | `fig-h07-chest-smooth-derivative-pairs` | PASS |
| 5 | `fig-h07-prep-metric-sample-support` | PASS |
| 6 | `fig-h07-prep-site-photoperiod-ranges` | PASS |

Every proof and its original PNG was inspected for clipping or cropping,
overlaps, text distortion, awkward line breaks, broken units, readable
essential text, legend-to-data-region balance, and distinguishability of
points, lines, rugs, ribbons, and endpoint marks. Captions and non-empty alt
text were also verified in the rendered H07 results and preparation HTML.
All checks passed.

For both placement-specific results figures, all nine paired rows were
inspected. Each row retains the main fitted metric-value smooth above its
corresponding first-derivative panel. Zero-reference lines, uncertainty
ribbons, observed-value rugs, qualifying transition markers, and highlighted
post-transition tails remain distinguishable. Titles, four-line subtitles,
facet strips, axes, ticks, and metric labels are unclipped and balanced.

For the preparation figures, all nine metric labels and both placement symbols
remain legible in the sample-support display. Submitted-manuscript site names,
site colours, placement panels, range segments, and endpoint marks remain
legible in the photoperiod-support display. Neither preparation figure implies
a placement-equivalence contrast.

This QA used frozen raster assets and rendered HTML only. It did not fit a
model, recalculate a prediction or derivative, or run resampling.
