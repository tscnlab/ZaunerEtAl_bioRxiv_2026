# Preparation 02 clarity and display record

Date: 2026-08-01

Source: `notebooks/preparation/02_coverage_sample_flow.qmd`

Rendered HTML:
`_build/nathealth/notebooks/preparation/02_coverage_sample_flow.html`

## Meaning preserved

- Rule A still uses valid melEDI across the fixed 1,440-minute hybrid day,
  with a threshold of at least 80% (1,152 minutes).
- The 50% hourly threshold remains limited to hourly summaries and does not
  mask otherwise observed minutes from daily or minute-based metrics.
- Diary-defined sleep remains in the daily denominator.
- An otherwise passing day is still excluded only when all finite melEDI
  values are exactly 0 lx; individual zero readings remain valid.
- Repeated autumn wall-clock minutes remain separate in actual time and are
  combined only for the local-clock coverage decision.
- No actual-time row, coverage flag, participant-day, sample-flow count, or
  signal value changed.

## Reader-facing changes

- Replaced the coverage builder call with direct reads of the accepted
  manifest, settings, hourly and daily decisions, reason-coded periods, and
  sample flow.
- Added the purpose and chain position, an explicit render boundary, an
  accessible process diagram, and the approved gap-timing-unaware dataset
  explanation.
- Replaced wide raw tables with 11 semantic `gt` tables. Overall settings and
  daily-distribution results use three-column comparison layouts; the script
  map uses the approved 38%/62% two-column layout.
- Separated the general coverage decisions, site-level retention, daily
  support distribution, reasons for unavailable data, full sample flow,
  validation evidence, and artifacts passed forward.
- Applied submitted-manuscript site names and order, `melEDI`, and “period.”

## Verification

- Static and rendered-HTML bounded-render test: **PASS**.
- Final-profile page-specific read-set baseline: 32 entries; SHA-256
  `e9c0893af93ee8b9794ef726b66895abea1f35d02d7306ca345d3c6771cbce5f`.
- Post-render comparison: 32 unchanged, 0 mismatches.
- Rendered HTML SHA-256:
  `54f0c716963d5ce5736eb2b10817cee78c7a733762cacc9eb65005d7dcb452d9`.
- REPORT-011 layout review: no empirical figure is present. The accessible
  Mermaid chain uses normal profile typography; long narrative cells are
  confined to two- or three-column displays, and multi-column tables contain
  short labels and numeric values with responsive overflow wrappers.
