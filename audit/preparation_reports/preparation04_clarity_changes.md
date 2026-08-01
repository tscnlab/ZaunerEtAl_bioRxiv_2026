# Preparation 04 clarity and display record

Date: 2026-08-01

Source: `notebooks/preparation/04_metric_derivation.qmd`

Rendered HTML:
`_build/nathealth/notebooks/preparation/04_metric_derivation.html`

## Meaning preserved

- The full-day record remains a placement-specific hybrid of worn near-eye
  or chest measurement during wake and bedside sleep-environment measurement
  during diary-defined sleep; it is not described as continuous ocular
  exposure.
- Actual UTC time still determines elapsed duration, gaps, adjacency,
  continuous periods, dose, and paired MDER integrals. The local-clock plane
  still determines clock-aligned bins, M10/L10, timing, and interdaily
  stability.
- The 15-of-30 and 30-of-60 bin rules, zero-aware 0.1 lx offset, strict
  thresholds, 80% primary diary-period/MDER/window/relevance cutoffs,
  70%/90% sensitivities, and 1.25 dose-correction cap are unchanged.
- Only dose may receive the approved time-sensitive correction. MDER remains
  an unscaled ratio of paired melEDI and illuminance integrals.
- M10 still tests 841 non-wrapping one-minute starts; L10 still tests 1,440
  starts with midnight wrapping; no L5 value is produced.
- Metric-specific failure still makes only that value unavailable. It does
  not remove an otherwise eligible participant-day or unrelated metrics.
- No metric value, support classification, participant, participant-day,
  time-grid row, input, manifest, model frame, or downstream result changed.

## Reader-facing changes

- Replaced the state-support, MDER-support, and metric builders and the MDER
  verifier call with direct reads of current stored outputs.
- Added a clear purpose, exact inputs, position in the Preparation 01–06
  chain, bounded-render note, hybrid-measurement warning, and accessible
  process diagram.
- Explained the producing scripts in execution order with a 38%/62%
  two-column layout, avoiding the narrow narrative column identified in
  Preparation 06 Table 13.
- Added 13 semantic `gt` tables covering exact inputs, production modules,
  scientific rules, participants, sites, participant-days, time-grid rows,
  diary-period and MDER support, bin support, metric availability, gaps,
  daylight-saving handling, forwarded files, file identities, and
  version-specific verification.
- Split daylight-saving counts from the gap table so neither display relies
  on compressed columns.
- Added an accessible final-size figure of MDER retention across the fixed
  70%, 80%, and 90% cutoffs, paired with the stored
  `mder_support_candidate_summary.csv` source data.
- Identified the eight R data files passed to Preparation 06 and applied the
  approved first-use definition of the gap-timing-unaware dataset.
- Applied PREP-003: current manifest identities and stored summaries are
  reported as current; complete metric and MDER reconstruction results are
  explicitly limited to their earlier manifests and samples; exact
  current-manifest reconstruction remains FIND-044.

## Verification

- Static and rendered-HTML bounded-render test: **PASS**.
- Final-profile page-specific read-set baseline: 109 entries; SHA-256
  `2ce1db192a0c7c32042e8e4477d6ee637519f09a5bb51c6300804f262ba237ac`.
- Final post-render comparison: 109 unchanged, 0 mismatches.
- Current metric manifest SHA-256:
  `6ec3185620d921e1f81b8464e850249613deb823988187d58794b3471303f4e8`.
- Current MDER support manifest SHA-256:
  `9ca9b97dac5efd9ec4e7b43a1fb2227b7a13cf98ac4b92318606c4874f9e460b`.
- Current diary-period support manifest SHA-256:
  `755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619`.
- Rendered HTML SHA-256:
  `2dda2e1db895668d37a5e17a5a1ca5e97156c2f2b1ebdb7fb19b674023394fe0`.
- Rendered HTML contains 13 semantic `gt` tables, 14 resolved table/figure
  captions, one empirical image with alt text, and no unresolved table or
  figure cross-reference.
- Render context: R 4.6.1, `gt` 1.3.0, `ggplot2` 4.0.3, and Quarto 1.9.37
  using the `nathealth` profile.

## REPORT-011 figure and layout QA

- The MDER support figure was inspected at its final 7.2-by-4.2-inch aspect
  ratio. Axis and legend text are 9 pt; axis and legend titles are 10 pt.
- Near-eye and chest remain distinguishable by colour, line type, point
  shape, and vertical position.
- There is no clipping, cropping, overlap, distorted text, awkward wrapping,
  broken unit, compressed data region, or unbalanced legend.
- Narrative-heavy tables use two broad columns. The gap and daylight-saving
  summaries are separate compact tables, preventing narrow high-content
  cells.
