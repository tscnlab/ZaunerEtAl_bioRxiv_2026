# Circular descriptive-summary repair proposal

## Finding

During old-to-new table replication, a direct check against the normalized chronotype values showed that `circular_descriptive_summary()` passed `probabilities=` to `stats::quantile()`. The supported argument is `probs=`. Because the unrecognized argument was ignored through `...`, R returned its default five-number summary; the function then mislabeled the minimum, first quartile, and median as the first quartile, median, and third quartile.

## Proposed repair

Replace `probabilities = c(0.25, 0.5, 0.75)` with `probs = c(0.25, 0.5, 0.75)` and add clean-session tests against an independently evaluated circular-centering calculation.

## Scientific impact

The repair changes the displayed circular median and middle 50% for clock-time variables. It does not change prepared inputs, approved participant-day metric values, sample inclusion, the circular mean/resultant, or any non-timing summary. All tables, timing figures, comparisons, hashes, and prose that depend on circular quartiles must be regenerated.

## Decision

Approved for implementation in the descriptive-only contract helper, followed by a complete rebuild and parity tests.
