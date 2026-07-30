# Shared-device provenance of the two MDER upper-tail records

Finding ID: `FIND-021`  
Related finding: `FIND-018`  
Related decision: `METRIC-008`  
Status: provenance verified; episodes remain unresolved; sensitivities registered  
Date: 2026-07-30  
Severity: high for MDER influence and maximum-value claims

## Finding

Both measurement-suspicious MDER maxima were recorded by ActLumus serial
2962:

| Participant | Date | Placement | Device | MDER | 90% support |
|---|---|---|---:|---:|---|
| KNUST_S003 | 2024-10-27 | near eye | 2962 | 1.3966 | fail |
| KNUST_S007 | 2024-11-19 | chest | 2962 | 2.4556 | fail |

The participant-position-device mapping was recovered from the original
commit-pinned `file.name` field and joined many-to-one to the canonical
participant-day metrics. The mapping contains exactly two assignments for
each of 15 KNUST participants. For the two target participants, serials 2962
and 3333 were exchanged between near-eye and chest placements, which makes
the shared serial independently identifiable rather than inferred from
position.

## Device-wide comparison

Serial 2962 supplied 68 estimable KNUST MDER days and serial 3333 supplied 79.
The two maxima are the only approved anomalous days. Once those two days are
omitted for the registered influence scenario:

| Device | Estimable days retained | Mean MDER | 99th percentile | Maximum |
|---:|---:|---:|---:|---:|
| 2962 | 66 | 0.864 | 0.988 | 0.989 |
| 3333 | 79 | 0.851 | 0.976 | 0.998 |

This descriptive check does not support a persistent, global high-MDER shift
for serial 2962. It cannot distinguish an intermittent derived-channel fault
from a genuine unusual spectrum on the two affected days.

## Available device and context records

Both exact commit-pinned serial-2962 device reports show the same hardware,
firmware, software and model, with no flash-corruption, device-error, or
power-down flag. No per-channel calibration history is available in the
release. The generic metadata workbook contains a device-level schema but no
participant-device calibration table.

For the KNUST_S007 bedtime episode, the commit-pinned hourly light-context
diary reports darkness during sleep and no sleep light ingress from
21:00–24:00; the sleep diary records preparation for sleep at 20:45 and no
explanatory comment. The context is inconsistent with an obvious intentional
bright source, but it is too coarse to exclude a dim narrowband source,
bedside positioning, or device error.

## Disposition

The author approved retaining both observations under the primary 80%
conjunctive support rule while requiring:

1. the registered 90% common-support scenario;
2. a scenario excluding exactly these two preidentified device-days; and
3. a full-day versus waking-only explanatory comparison.

No latent calibration, measurement-error model, or silent device correction
is introduced. The primary result is classified as influence-sensitive unless
the registered scenarios agree. The device serial is retained in the
diagnostic audit but is not promoted to an unplanned primary model predictor.

## Reproducibility

Producer:
`audit/scripts/audit_mder_device_assignment.R`

Outputs:
`audit/reconciliation/preparation04/mder_device_qc/`

The R 4.6.1 audit records exact hashes for both canonical metric artifacts,
the metric manifest, the pinned-download manifest, and both KNUST native
source files. It asserts 30 unique participant-position assignments, 163
KNUST participant-day metric rows, and that both preidentified rows resolve
to serial 2962.

Reopen if device/calibration records establish invalidity, if another
serial-2962 anomaly is identified by a rule fixed independently of its
result, or if a registered sensitivity changes a substantive conclusion.
