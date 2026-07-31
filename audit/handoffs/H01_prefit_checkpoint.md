# H01 pre-fit checkpoint

Date: 2026-07-30; current-input repin 2026-07-31
Status: preparation and method package approved; regenerated inputs repinned;
fit-stage verification passed; production bootstrap pending

## Scope now complete

- The main H01 data and the manuscript-prepared-data sensitivity both contain
  the familiar 17 H01 metrics.
- The formal sensitivity changes the prepared data only. Both scenarios use
  model implementation `new_h01_h11`.
- The reported manuscript values and manuscript-generating code remain
  discussion-only audit comparators; they are not a formal sensitivity arm.
- Main and sensitivity data pass through the same row, inclusion,
  sample-flow and exclusion implementation.
- Near-eye remains primary; paired/common-sample near-eye and chest remain
  comparison/complementary scenarios; placements are not pooled.
- The original checkpoint preceded model fitting. After the approved Gate A
  and Gate B repairs and the exact-all-zero day exclusion, the fit stage was
  rerun against the identities below. Estimates, confidence intervals and
  rebuilt \(p\)-values from that fit stage remain provisional until the
  production bootstrap and final diagnostic review are complete.

## Pinned identities

| Item | SHA-256 |
|---|---|
| Manuscript-prepared input manifest | `e604342c87e9cf4a97e766e248200fd4514da1ee9d1165829654f4769c5c0bfc` |
| Main H01 data | `018b9a50c007a850ba21d026cc7a9fd7d6906322993c98785b3dccb8f19b7475` |
| Main H01 manifest | `ea9d47f624a8777f8416447612bfcc2309cf2bac40fdf4fd5021c8767806dfbf` |
| Manuscript-prepared H01 data | `c5ea147312735ccaa46ffaf642058115e8ed9d41376262e351a86b84a689e98a` |
| Manuscript-prepared H01 manifest | `cb47b3678146604aadca875a96f79909e2d73355162683ff0603f038f3b31a25` |
| Shared H01 implementation fingerprint | `e07db16818e565aff40fa6b9f79f34a31eb943d6c393343ca96471b795bacbed` |
| Shared H01 code | `c7d66825c359066ec6dce1a623408d532c4686fd0b77bfe1da5e392fcc7f5516` |
| Preparation 06 HTML | `8afa6ad4a253deba41a59f4463c25e40ccadac7e4477cf4916fc625211b930e8` |
| Current H01 HTML | `482970c0c185d105edb75de7628977bcaa122eec91bb20cbb7ac24817c485804` |

## Prepared H01 rows

- 45,650 rows in the current main H01 interface.
- 12,522 all-available near-eye rows: 816 participant-days for the 15
  day-level metrics and 141 participants for IS and IV.
- 13,838 all-available chest rows: 902 participant-days for the 15 day-level
  metrics and 154 participants for IS and IV.
- 643 paired participant-days, represented by 9,645 daily metric rows per
  placement.
- Paired participant-level IS and IV remain unavailable until recalculated on
  paired common days.
- The retained manuscript-prepared artifacts do not contain exact
  metric-support minutes. Their support hours are `unavailable`, not zero.

Every fitted model must store its exact analysis frame and reconcile model
observations, participants, participant-days or contributing days, and sites
after transformations and missing-value handling. Main-data support hours are
reported where available.

## Verified repairs

- The manuscript-prepared one-hour data average repeated fall-back hours
  exactly as the manuscript preparation did: 19,176 near-eye and 21,288 chest
  hours.
- Five manuscript-prepared CSV/RDS pairs are directly compared; a CSV plus
  output-inventory alteration is rejected.
- The H01 sensitivity preserves its own dose and MDER definitions and labels.
- Twenty-nine near-eye and 33 chest negative L10 midpoints are restored to the
  ordinary 24-hour clock before the common H01 nighttime transformation is
  applied once.
- Isolated deterministic rebuilds, undeclared-file rejection, CSV/RDS
  corruption rejection, coordinated RDS/CSV/manifest tamper rejection, and
  main-artifact immutability pass under R 4.6.1.
- All 33 protected `manuscript/R0_NatMed/` files still match their baseline
  SHA-256 values and total 47,690,015 bytes.

## Author decisions approved before fitting

The author approved both remaining method decisions on 2026-07-30, before any
rebuilt H01 model was fitted:

1. the complete 17-metric response-family package (`H01-005`); and
2. the formal fourth 17-test Benjamini--Hochberg family comparing the full
   site model with the linear-latitude model on identical rows (`H01-006`).

Together with amended decision `H01-001`, H01 now has four separate
17-model-level-test families: site, photoperiod, latitude, and
site-versus-latitude adequacy. Required diagnostics may still open a major
gate for a common replacement model, but they do not reopen the approved
starting package automatically.

## Suggested next-task boundary

Continue the dedicated H01 task with production bootstrap confidence
intervals, diagnostic review, site deviations from the overall mean,
variation summaries, main-versus-manuscript-prepared comparison, claim review
and H01 HTML output.

The new task should explicitly re-authorize the relevant specialist skills,
because skill authorization does not carry across tasks. It should not edit
shared preparation rules, central ledgers, Quarto configuration or manuscript
files without returning the change to the coordinating task.
