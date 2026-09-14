# Gap-timing-unaware dataset terminology

Decision ID: `REPORT-010`  
Date: 2026-08-01  
Status: approved

## Decision

Every reader-facing Stage 3 result report and Stage 4 analysis-preparation and
provenance companion calls the predefined data-preparation sensitivity the
**gap-timing-unaware dataset**.

At its first occurrence in each report, explain that this dataset still passed
the general 50%-per-hour and 80%-per-day coverage rules. The name means that
the timing of the remaining missing observations is not used for an additional
metric-specific adjustment. It does not mean that gaps, missingness, or
coverage were ignored.

For contrast in that first explanation only, the primary dataset may be
described as something that **could be interpreted as a time-sensitive primary
metric dataset**, because its approved metric preparation uses the timing of
remaining missing observations where that timing is relevant to the metric.
After this explanation, call it simply **the primary dataset**. Do not adopt
“time-sensitive primary metric dataset” as a standing scenario name.

After the definition, use **gap-timing-unaware dataset** consistently in
reader-facing prose, headings, tables, figures, captions, legends, callouts,
alt text, and visible link text. Do not use `V0`, `legacy`, `previous`,
`manuscript-prepared`, `alternative manuscript-prepared`, or similar
historical-artifact labels for this scenario in Stage 3 or Stage 4.

## Provenance names

Internal scenario identifiers, object names, artifact filenames, audit ledgers,
and established file paths may retain their existing names when changing them
would weaken traceability or break references. Reader-facing labels derived
from those objects must use the approved term.

This is a terminology change only. It does not change either dataset, the
50%/80% coverage rules, metric calculations, model samples, fitted models,
sensitivity classifications, or claims.

## Reopening condition

Reopen only if the preparation rules of either scenario change enough that the
term no longer describes the actual contrast, or if the author approves a
different reader-facing name.
