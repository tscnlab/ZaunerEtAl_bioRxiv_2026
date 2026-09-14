# H10 Stage 2 figure visual QA

Date: 2026-08-12  
Status: **PASS**

The final PNGs were inspected at their native export dimensions. Every PDF
was confirmed to contain one page at the registered physical size, rasterized
from the PDF at 100 dpi, and inspected independently. The checks covered
clipping, overlaps, distortion, illegible text, awkward line breaks, excess
whitespace, placement labels, legends, captions, and agreement between the
PNG and PDF composition.

| Figure | Intended size (in) | PNG size (px) | PNG | PDF | Assessment |
|---|---:|---:|---|---|---|
| Primary age associations | 9.4 × 8.5 | 2820 × 2550 | PASS | PASS | All 17 metric labels, both placements, intervals, legend, axis title, and caption are readable. |
| Primary biological-sex associations | 9.4 × 8.5 | 2820 × 2550 | PASS | PASS | All 17 metric labels, both placements, intervals, legend, axis title, and caption are readable. |
| Placement-matched associations | 9.4 × 5.8 | 2820 × 1740 | PASS | PASS | Age and Female-minus-Male panels are separated; interval bars and two-row metric-category legend do not overlap. |
| Primary versus gap-timing-unaware associations | 9.4 × 5.8 | 2820 × 1740 | PASS | PASS | Predictor panels, component 95% confidence intervals, placement legend, identity line, and definition caption are readable. |
| Diagnostic assessment | 9.4 × 8.2 | 2820 × 2460 | PASS | PASS | All 68 tiles, four model labels, 17 metric labels, legend, and caption are visible. |
| Frozen V0 near-eye recreation | 10 × 5 | 3000 × 1500 | PASS | PASS | The original erroneous y-axis label is visibly retained by design; this is not a QA failure. |
| Corrected frozen V0 near-eye display | 10 × 5 | 3000 × 1500 | PASS | PASS | Only the erroneous duration-axis label is corrected; the plot and note remain readable. |
| Frozen V0 chest recreation | 10 × 5 | 3000 × 1500 | PASS | PASS | The original erroneous y-axis label is visibly retained by design; this is not a QA failure. |
| Corrected frozen V0 chest display | 10 × 5 | 3000 × 1500 | PASS | PASS | Only the erroneous duration-axis label is corrected; the plot and note remain readable. |

The figure manifest resolves all nine PNG/PDF/source-CSV triplets. The
publication figures use the registered compact display sizes rather than an
A4 canvas. No H10 figure required the nonnegative melEDI symlog rule because
the inferential displays show standardized effects or timing/duration values,
not a strongly right-skewed nonnegative melEDI response distribution that
includes zero.

The FIND-049/CHG-101 reseal regenerated only the primary-versus-gap common-
sample figure from sealed current tables; all other scientific figures were
retained byte-for-byte. All nine PNG/PDF/source-data triplets passed the same
checks after the selective update. The reader addendum's 68-page diagnostic appendix was also inspected at
the four MDER pages (17, 34, 51, and 68). A long-title clipping defect on pages
34 and 68 was corrected by narrower wrapping and a concise assessment line;
both pages then passed reinspection with fully visible titles, panel labels,
points, reference lines, axes, and legends.

Provenance qualification: `PREP-003` / `FIND-044` remains open only for complete
independent reconstruction of the exact current state-support classification.
The current Preparation 06 model-ready layer and METRIC-010 MDER values,
including the FIND-049/CHG-101 gap repair, are independently verified. This is
not evidence that the data are incorrect; every finite gap MDER is now strictly
positive.

## METRIC-011 reseal

METRIC-011 regenerated the five Stage 2 displays that can contain the primary
L10 slot or affected BH-derived fields: the age and biological-sex forests,
placement-matched comparison, primary-versus-gap comparison, and diagnostic
assessment. The four V0 recreation/correction figures remained unchanged. The
reader overview and the retained/all-model core diagnostic displays were also
rebuilt from sealed tables and frozen fitted/residual rows; no fitting or
prediction occurred.

All eight reader proof pages and both preparation proof pages passed inspection
at the intended 170-mm display width. The L10 diagnostic appendix pages 5, 22,
39, and 56 were additionally rasterized from the final 68-page PDF and checked
at original resolution. Titles, assessment lines, panel strips, axes, site
legend, points, and reference lines are fully inside the canvas and readable.
No clipping, overlap, distortion, awkward line break, excess whitespace, or
unreadable essential text remains.
