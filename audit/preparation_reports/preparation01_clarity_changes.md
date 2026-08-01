# Preparation 01 clarity and display record

Date: 2026-08-01

Source: `notebooks/preparation/01_import_state_alignment.qmd`

Rendered HTML:
`_build/nathealth/notebooks/preparation/01_import_state_alignment.html`

## Meaning preserved

- The fixed site releases, repository revisions, DOIs, URLs, byte sizes, and
  SHA-256 identities are unchanged.
- UTC remains the actual-time coordinate and local wall time remains the
  time-of-day coordinate; repeated autumn clock minutes remain distinct.
- A one-minute value still requires every expected original reading.
- Diary-defined sleep is the half-open interval from sleep preparation to
  wake and remains a retained bedside-sleep measurement.
- Only wear-log `off` outside diary-defined sleep is treated as true non-wear.
- The strict 100,000 lx melEDI operating limit is unchanged; the raw value is
  retained and the analytical melEDI value is unavailable at or above it.
- Near-eye and chest samples remain separate, and no participant, day, minute,
  state, or signal value was changed.

## Reader-facing changes

- Replaced the production build and verifier calls with direct reads of the
  two accepted artifact manifests, the fixed-source inventory, and stored
  audit CSVs.
- Added a purpose-and-position opening, an explicit render-boundary note, and
  an accessible data-to-analysis diagram.
- Reorganized the report into source identity, time handling, one-minute
  aggregation, state-period preparation, state alignment, operating-limit
  handling, sample accounting, validation, production provenance, and exact
  handoff artifacts.
- Replaced raw `kable` outputs with 14 semantic `gt` tables.
- Converted single-row and two-row wide summaries to two- or three-column
  vertical layouts; retained one seven-column site table only where the
  near-eye/chest correspondence is the scientific comparison.
- Converted the production-code map to the approved 38%/62% two-column
  layout so explanatory text has sufficient width.
- Applied submitted-manuscript site names and order, `melEDI`, and “period.”

## Verification

- Static bounded-render and structure test: **PASS**.
- Final-profile page-specific read-set baseline: 149 entries; SHA-256
  `e905f08f77b2a362965db94795b0b8965ba0130b57f4f68942759c524980dbc6`.
- Post-render read-set comparison: 149 unchanged, 0 mismatches.
- Rendered HTML SHA-256:
  `6c45e5d23a25808c74f60677f5e3873bfdb2926cc0bfc8a6a9f4411e8d0ddeec`.
- REPORT-011 layout review: no empirical data figure is present. The Mermaid
  chain uses the profile's normal readable text size. Long-source, state,
  sample, and script displays use bounded two- or three-column layouts or
  compact numeric columns, with no result encoded in small annotation text.
  The generated HTML contains responsive overflow wrappers for all `gt`
  tables. Final owner browser review remains available at the rendered path.
