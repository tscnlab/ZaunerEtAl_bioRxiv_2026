# H01 REPORT-016 deviation-alias reconciliation

Change ID: **CHG-130**  
Date: 2026-08-12  
Status: **structurally verified; no scientific change**

## Decision

The eight H01-local labels `H01-001` through `H01-008` are decision-layer
aliases or implementation details of existing central deviation records. They
are not additional preregistration deviations, do not receive new central
records, and must not be used as anchors on the reader-facing preregistration-
deviations page.

The coordinator accepts the H01 scientific owner's mapping:

| H01-local label | Authoritative central record or records |
|---|---|
| H01-001 | IMP-001 |
| H01-002 | DEV-009 |
| H01-003 | IMP-004 |
| H01-004 | IMP-003 and IMP-004 |
| H01-005 | DEV-018 |
| H01-006 | DEV-009 and IMP-001 |
| H01-007 | IMP-024 |
| H01-008 | IMP-023 |

The exact row-level rationale remains in
`audit/hypotheses/H01/report016/H01_REPORT016_local_id_mapping.csv`.
Reader-facing H01 links must target only the corresponding central anchors in
`notebooks/preregistration_deviations.qmd`.

## Scientific display reconciliation

The corrected H01 deviation display is accepted at SHA-256
`2671fc9af9d6764a8b64c1417c8c84b3eb63a2f0a0c2c4ff4adb4eddeb03a347`.
It now:

- identifies DEV-058/METRIC-010 as the current MDER definition;
- assigns DEV-057 to the complete exact-zero melEDI participant-day rule while
  retaining individual zero observations;
- distinguishes the registered longest-period midpoint from the separately
  labelled mean-timing sensitivity under DEV-008/DEV-054; and
- contains none of the eight H01-local labels.

This resolves RH-SCI-001 and releases H01 for its serial, exact dynamic-link
update under REPORT-016.

## Verification and boundary

Fresh R 4.6.1 verification confirmed that all seven target central IDs exist
in both the reader-disposition overlay and the hypothesis crosswalk, that each
is scoped to H01, and that the corrected table contains the required central
IDs but no `H01-001` through `H01-008` labels. The focused H01 reconciliation
test also passed while rehashing 1,161 protected scientific artifacts without
a mismatch.

This reconciliation changes no data, sample, metric, model, estimate,
interval, p-value, FDR result, diagnostic, sensitivity result, figure, or
scientific conclusion. It authorizes only the exact reader-facing dynamic-link
update and its structural verification. The unrelated pre-existing
REPORT-014 wording assertion about nine sites is outside this reconciliation.
