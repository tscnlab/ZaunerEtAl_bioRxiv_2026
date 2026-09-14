# Order 61a H11 companion visual QA

## Page-level inspection

The preserved companion was inspected at the exact route under a server rooted only at `_build/nathealth`.

- At 1440 by 1000, the document width was exactly 1440 pixels. All 26 native `gt` tables and their captions were contained. Six long code-line elements extended only inside three contained horizontal code scrollers. The three figures, the rendered top-down Mermaid, 34 code disclosures, table captions, figure captions, alt text, table of contents, and reciprocal links were present.
- At 708 by 1000, the document width was exactly 708 pixels. All 26 tables remained contained, the sidebar collapsed to its navigation control, all 32 narrow code scrollers remained local to their code blocks, and no element produced uncontained page overflow.
- At 720 by 500, the document width was exactly 720 pixels. All 26 tables remained contained, all figures loaded, the sidebar navigation opened and closed correctly, and no element produced uncontained page overflow.
- One code disclosure was opened and closed. Its code content became visible when open and was hidden again when closed.
- The responsive sidebar opened to a 433.42-pixel panel with `aria-expanded="true"`, then closed with `aria-expanded="false"`.
- Browser warning and error logs were empty on the desktop, 708-pixel, 720-pixel, and figure-proof surfaces.
- Nine important local targets returned HTTP 200 to read-only HEAD requests. These included both reciprocal report routes, the deviations page, the inherited H02 companion, and all three paired figure source-data files.
- No local filesystem path, user name, embedded execution error, unresolved reference, clipping, overlap, distorted text, awkward unit break, or missing reader content was observed.

## Figure inspection at 170 mm

Each figure was displayed at exactly 642 pixels wide from its unmodified 2550-pixel PNG.

| Figure | Rendered size | Essential text | Minor text | Visual assessment |
|---|---:|---:|---:|---|
| Site and recorded biological-sex support | 642 by 468 px | 7.87 pt | 7.09 pt | PASS |
| Original-unit melEDI support | 642 by 528 px | 7.87 pt | 7.09 pt | PASS |
| Activity matching and attrition | 642 by 468 px | 7.87 pt | 7.09 pt | PASS |

The figures were tightly bounded and free of cropping, overlap, distortion, awkward wrapping, imbalanced legends, or indistinguishable marks. Axis, tick, legend, facet, direct-label, and annotation text remained legible. The activity-attrition display uses bars that start at zero and terminate at directly labelled percentages, so there are no connector lines that appear to start or end without an endpoint.

## Disposition

PASS. The preserved HTML satisfies the bounded loopback visual and interaction contract. No render, source edit, model execution, prediction, or scientific recomputation occurred.
