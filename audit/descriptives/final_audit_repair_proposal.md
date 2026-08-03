# Final descriptive-figure audit repair proposal

## Finding

Visual inspection of the clean descriptive rebuild found two presentation-only defects. In the level and exposure-history distribution figures, adjacent pseudo-log tick labels below 1 lx overlapped. In the clock-time distribution figure, the terminal 24:00 label was clipped at the right image boundary.

## Proposed repair

- Retain the pseudo-log transformations and plotted observations, but use a sparser, metric-category-specific set of labelled breaks and compact deterministic labels.
- Omit the duplicate terminal-midnight tick from the circular timing panels; retain 00:00 at the left boundary and state in the axis title that the scale wraps at midnight.

## Scientific impact assessment

The repair changes no input, inclusion rule, denominator, statistic, uncertainty interval, metric value, or geometry. It changes axis annotation only. The source-data exports therefore remain unchanged; the affected PNG and SVG hashes and the descriptive artifact manifest must be regenerated.

## Decision

Approved for implementation within the descriptive-only plotting module, followed by a targeted rebuild and renewed visual inspection.
