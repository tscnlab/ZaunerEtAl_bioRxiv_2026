# H01 pre-fit checkpoint

Date: 2026-07-30  
Status: preparation and method package approved; ready for fitting; no H01 model fitted

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
- No H01 exposure model, estimate, confidence interval or rebuilt \(p\)-value
  has been produced.

## Pinned identities

| Item | SHA-256 |
|---|---|
| Manuscript-prepared input manifest | `af74cc9fa36e426222d9b5f2328e2261c00b14436feb8d86fbf137d0ff313267` |
| Main H01 manifest | `48f7cb7a9539bd1a35237275187a76528f1daacfc9abe368cbc4bc1397ed0375` |
| Manuscript-prepared H01 manifest | `672312ba62871317b0910fbd781f7f6db92e6718fed26961e17a986a5eb989f5` |
| Shared H01 implementation fingerprint | `e07db16818e565aff40fa6b9f79f34a31eb943d6c393343ca96471b795bacbed` |
| Shared H01 code | `c7d66825c359066ec6dce1a623408d532c4686fd0b77bfe1da5e392fcc7f5516` |
| Preparation 06 HTML | `b9f2a074b3020c1466d6737b9da30ce97080f09c08568e9301b773b5b57f0dd1` |
| H01 HTML before approval refresh | `3c9b9c5b277df8e479f77e6adda64ee90059bf7cd5c2aa8aba40964e5131a852` |

## Prepared H01 rows

- 45,410 rows per scenario interface.
- 12,447 all-available near-eye rows.
- 13,763 all-available chest rows.
- 640 paired participant-days, represented by 9,600 daily metric rows per
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

Start a new task dedicated to H01 model fitting, diagnostics, bootstrap
confidence intervals, site deviations from the overall mean, variation
summaries, main-versus-manuscript-prepared comparison, claim review and H01
HTML output.

The new task should explicitly re-authorize the relevant specialist skills,
because skill authorization does not carry across tasks. It should not edit
shared preparation rules, central ledgers, Quarto configuration or manuscript
files without returning the change to the coordinating task.
