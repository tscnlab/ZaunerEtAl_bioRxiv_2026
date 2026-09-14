# H01 METRIC-011 figure-readability QA

Date: 2026-08-12  
Scope: display-only review of the four Stage 3 figures regenerated from
verified stored H01 outputs after the bounded L10 production integration.
No model, prediction, simulation, or bootstrap was run for this review.

| Figure | Pixel dimensions | Final-size checks | Status |
|---|---:|---|---|
| Primary near-eye site contrasts | 3680 x 4640 | Site labels and per-site `n` values legible; ratio/difference tags visible; filled versus open points and thick versus thin intervals distinguish supported contrasts; null lines aligned; no clipping, overlap, or squeezed panels. | PASS |
| Complementary chest site contrasts | 3680 x 6720 | Site labels and per-site `n` values legible; ratio/difference tags visible; significance encodings distinguishable; shared null-line geometry retained; no clipping, overlap, or squeezed panels. | PASS |
| R-squared intervals | 3360 x 2560 | Metric labels, placement facets, interval endpoints, shapes, and legend are legible; no clipping or label collision. | PASS |
| Paired near-eye versus chest comparison | 3840 x 2176 | Equal axis geometry, identity and null lines, point labels, predictor shapes, and legend are legible; no clipping or unresolved overlap. | PASS |

The figures meet REPORT-011 at their rendered dimensions. Registered site
names, order, and colours are retained. Meaning is not conveyed by colour
alone in the site-contrast or paired-placement figures.

