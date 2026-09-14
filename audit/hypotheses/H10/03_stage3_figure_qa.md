# H10 reader-figure readability QA

Date: 2026-08-12  
Overall outcome: PASS

## Inspection basis

The eight final reader-facing PNGs were placed without enlargement at their
declared 170-mm display width on separate A4 portrait QA pages. The A4 page is
an inspection scaffold only and is not part of any final asset. The proof is
`artifacts/12_manifests/H10/H10_stage3_figure_A4_proofs.pdf`.

Every source raster is 2,820 pixels wide at the declared 300 dpi and a
9.4-inch base canvas. At 170 mm, the reduction factor is 0.712. The smallest
essential nominal plot text is 8 pt, corresponding to 5.70 pt at final size;
central plot text is 10 pt, corresponding to 7.12 pt. These values pass the
REPORT-011 physical-size thresholds.

The compiled Quarto HTML was also checked structurally after a successful
single-document render: it contains exactly eight reader figures, each at
100% width with a caption and 395–655 characters of alt text, 12 compact `gt`
tables, and 17 resolved local CSV links. Automated visual navigation to
the local-file URL was blocked by the browser security policy, so no claim is
made that browser automation inspected that URL. The author-facing HTML is
therefore included in the H10 reader-report approval request.

## Figure-level inspection

- `fig-h10-age-associations` — PASS. All 17 metric labels, both placement
  series, points, 95% confidence intervals, zero line, axes, legend, and notes
  are legible. No clipping, overlap, distortion, awkward wrapping, or excess
  canvas whitespace was found within the tightly bounded figure.
- `fig-h10-age-site-overview` — PASS. Both fitted-sample age distributions,
  all 11 retained main estimates, the two heterogeneity panels, submitted
  site names and colours, intervals, annotations, and inferential
  qualifications remain readable and unclipped. One participant appears once
  in each relevant placement age distribution; no repeated participant-day
  age rows are displayed.
- `fig-h10-sex-associations` — PASS. All 17 metric labels, both placement
  series, points, 95% confidence intervals, zero line, axes, legend, and notes
  are legible and unclipped. The Female-minus-Male direction is unambiguous.
- `fig-h10-diagnostics` — PASS. The four association columns, 17 metric rows,
  two assessment colours, legend, and footnote remain distinct and readable;
  no cells or labels overlap.
- `fig-h10-core-diagnostics-age` — PASS. All nine retained age models and
  their 18 independently scaled residual-versus-fitted and normal Q–Q panels
  are readable. Site colours, zero and quartile-reference lines, axes, titles,
  and the two-row legend remain distinct; no panel is clipped or crowded.
- `fig-h10-core-diagnostics-biological-sex` — PASS. Both retained
  biological-sex models and their four independently scaled diagnostic panels
  are readable and unclipped. Site colours, reference lines, axes, titles, and
  legend remain distinct at final display size.
- `fig-h10-paired-placement` — PASS. Both panels, component 95% confidence
  intervals, points, null lines, identity lines, category colours, legend,
  and the non-equivalence qualification are readable and unclipped.
- `fig-h10-gap-common` — PASS. Both panels, component 95% confidence intervals,
  point colours, axes, null and identity lines, legend, and remaining-gap
  definition are readable and unclipped.

All plots display participant ages, standardized coefficients, categorical
assessments, or Pearson residuals rather than nonnegative, right-skewed
melEDI-like response values. REPORT-013 symlog display is therefore not
applicable. Native PDF exports remain paired with the PNGs, and each durable
figure has its own source-data CSV.

## All-model diagnostic appendix

The 68-page native PDF appendix was checked with Poppler after generation.
The page count is exactly 68, matching the unique primary
metric-placement-association models and the paired page index. Pages 4, 12,
40, 56, and 68 were rasterized and inspected at native proportions to cover
near-eye and chest models, age and biological-sex associations, Gaussian and
Tweedie responses, retained findings, qualified assessments, and the final
page. An initial long-title clipping problem was found in this inspection;
titles and subtitles were wrapped and the page height was increased before
the final appendix was regenerated. The final sampled pages have no clipping,
overlap, distortion, awkward wrapping, or excess whitespace, and their site
colours, points, reference lines, assessment text, and axes are readable.

For the METRIC-011 reseal, all four L10 pages (5, 22, 39, and 56) were
additionally rasterized from the final PDF and inspected at original
resolution. Their complete titles, assessment lines, residual-versus-fitted
and normal Q-Q panels, axes, site legend, points, and reference lines are
inside the page canvas and readable. No visual defect was found.
