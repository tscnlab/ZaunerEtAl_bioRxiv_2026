# H06_daily targeted gap clock-hour repair authorization

- Date: 2026-08-12
- Task-local gate: H06-D-G2B-GAP-CLOCK-REPAIR
- Parent workflow: H06-D-014 / H06-D-G2A

The author approved a targeted, task-owned repair of the H06_daily
gap-timing-unaware clock outcomes after reviewing the H06-D-G2A unit audit.
The repair converts the shared gap clock-hour values to the existing
H06_daily minute-scale frame contract exactly once, solely inside new
H06_daily-owned code and artifacts. The shared prepared data are not changed.

The authorized scientific scope is limited to the 90 cells formed by five
clock outcomes (metric slots 9--13), two placements, three approved sample
roles, and three approved predictors in the gap-timing-unaware dataset. The
accepted model hierarchy, timing routes, Student-t and actual-date AR
sidecars, participant/site deletion diagnostics, visual residual review, and
H01-aligned diagnostic rules remain unchanged. AR and influence findings are
reported as nonblocking sidecars unless they expose an actual construct or
observed-support failure.

Only the 30 corrected gap timing tests and the mathematically dependent
rank/q-value/decision fields in the six complete gap 15-slot BH families may
change. The 378 unaffected non-L10 cells, all primary families, L10 slot 3,
MDER raw/model results, the temporal and pre-sleep branches, main H06, other
hypotheses, shared preparation, central ledgers, and historical H06-D-G2 and
H06-D-G2A records must remain byte-identical.

The work must run serially and checkpointed, use R 4.6.1 and the synchronized
project library, and stop at H06-D-G2B-GAP-CLOCK-REPAIR for author review.
