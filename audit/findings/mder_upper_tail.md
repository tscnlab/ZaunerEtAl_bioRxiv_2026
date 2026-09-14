# MDER upper-tail device-day audit

Finding ID: `FIND-018`  
Related historical decisions: `METRIC-003`; `METRIC-008`  
Current decision: `METRIC-010`  
Status: **historical ratio-of-integrals audit; new-estimand upper tail reopened**  
Date: 2026-07-30  
Severity: high for MDER models and maximum-value claims

> **Supersession notice (2026-08-11).** The arithmetic and device evidence on
> this page remains valid for the former ratio-of-integrals values, but its two
> prespecified device-days and sensitivity disposition do not automatically
> transfer to the mean-of-momentary-ratios estimand. Under `METRIC-010`, the
> primary maxima are 1.857 near eye and 3.574 at the chest. Each MDER-dependent
> hypothesis must inspect the new upper tail and influence under the new
> fitted sample before making a stability claim.

## Finding

The two largest ratios of paired observed MEDI and LIGHT integrals are:

- KNUST_S003, glasses, 2024-10-27: 1.3966; and
- KNUST_S007, chest, 2024-11-19: 2.4556.

The top ten MDER values per placement, their paired integrals, ordinary
support, and both signal-profile supports independently reproduce from the
one-minute eligible pairs. The maximum MDER discrepancy is
\(2.44\times10^{-15}\), and the maximum integral discrepancy is
\(1.31\times10^{-10}\) lx h. Neither maximum is caused by DST, duplicate
timestamps, saturation, or positive MEDI paired with zero LIGHT. A raw
native-epoch audit also reproduces the one-minute aggregation across all
5,760 inspected target and counterpart minutes.

## Device-day interpretation

### KNUST_S003, near eye

The value 1.3966 is isolated relative to the participant's other near-eye days
(0.630–0.989) and the same-day chest value (0.884). Five minutes with
minute-level ratios at least 2.5 contribute 29.4% of the daily MEDI integral.
The raw 10-second channels contain abrupt LIGHT/channel changes while MEDI is
sometimes unchanged, consistent with a possible stale or asynchronous
derived-channel episode. This is suspicious but not proven invalid.

### KNUST_S007, chest

The value 2.4556 is driven by the bedside diary-sleep segment. That segment
has MDER 12.7 and contributes 68.1% of the daily MEDI integral but only 13.0%
of LIGHT. Waking-context MDER is approximately 0.90, same-day near-eye MDER is
0.834, and the next three chest days are 0.951, 0.903, and 0.862. The raw
channels show a sustained, almost single-channel short-wavelength exposure.
The current data cannot distinguish a real narrowband bedside source from a
device or positioning artifact.

The remaining upper tail is provisionally plausible or valid-extreme. A
THUAS value around 1.25–1.26 occurs at both placements on the same day and
passes the 90% support gate, supporting a shared spectral environment.

## Device provenance and available context

The two anomalous records were independently linked through the original
commit-pinned `file.name` field. Both were recorded by the same physical
ActLumus logger, serial 2962:

- KNUST_S003 used serial 2962 near eye and serial 3333 at the chest; and
- KNUST_S007 used serial 3333 near eye and serial 2962 at the chest.

Thus the two placement-specific maxima share a device even though they arose
four weeks apart, in different participants, and at different placements.
This raises the plausibility of an intermittent device/channel episode, but
does not establish one.

Serial 2962 contributed 77 KNUST participant-days, of which 68 have estimable
MDER; serial 3333 contributed 86 participant-days, of which 79 have estimable
MDER. After excluding only the two prespecified anomalous days, the maximum
MDER was 0.989 for serial 2962 and 0.998 for serial 3333, and their means were
0.864 and 0.851, respectively. The available data therefore do not indicate
a persistent device-wide upward calibration shift. They remain compatible
with an intermittent channel problem or two genuine, unusual spectra.

The two exact commit-pinned device reports for serial 2962 identify hardware
version 1.0, firmware 1.7, software 2.2.0 and device model AL0101. Both report
`FLASH_CORRUPTED: false`, `ERROR_CODE: 0`, and `POWER_DOWN_FLAG: 0`. They
contain no per-channel calibration record capable of adjudicating the
episodes. The release's metadata workbook defines device-level metadata
fields but contains no participant-device calibration history.

For KNUST_S007 on 2024-11-19, the pinned hourly light-context diary labels
21:00–24:00 as "Darkness during sleep", with neither sleep light ingress nor
another secondary source reported. The sleep diary places preparation for
sleep at 20:45 and contains no explanatory comment. These reports do not
explain the high bedside segment, but a coarse self-report of darkness cannot
exclude a dim, spectrally narrow source or a positioning effect.

The complete reproducible device-assignment audit is under
`audit/reconciliation/preparation04/mder_device_qc/`; its producer is
`audit/scripts/audit_mder_device_assignment.R`. The provenance result is
recorded separately as `FIND-021`.

## Registered 90% support sensitivity

The 90% conjunctive support scenario removes both suspicious maxima:

| Placement | Days at 80% | Days at 90% | Maximum at 80% | Maximum at 90% | Mean at 80% | Mean at 90% |
|---|---:|---:|---:|---:|---:|---:|
| glasses | 733 | 601 | 1.397 | 1.261 | 0.844 | 0.842 |
| chest | 825 | 691 | 2.456 | 1.254 | 0.887 | 0.881 |

Central distributions are stable, while maxima are support-sensitive.
Omitting KNUST has negligible impact on means, medians, and the 99th
percentile.

## Approved disposition

- Retain the approved 80% conjunctive support rule and ratio-of-integrals
  definition as primary.
- Do not delete either device-day merely because it is extreme.
- The available device serial/report, calibration-history, and bedside
  context checks are complete and do not establish invalidity; retain this
  limitation explicitly.
- Require the registered 90% common-support sensitivity.
- Require a clearly labelled sensitivity excluding the two unresolved
  anomalous device-days.
- Require state-separated full-day versus waking-only MDER as an explanatory
  sensitivity without replacing the approved hybrid 24-hour primary
  construct.
- If device verification remains unavailable, retain both primary values but
  classify MDER conclusions as influence-sensitive unless all sensitivities
  agree.

The author approved this disposition on 2026-07-30. Available device and
context checks are now complete. The two values remain in the primary
dataset; no observation is silently recoded or deleted. MDER models and
claims must include the registered 90% support, two-day exclusion, and
waking-only explanatory scenarios before their stability can be classified.
The primary disposition is therefore closed and is not an open author gate;
the three registered sensitivity obligations remain pending.

Reopen if new device/calibration records establish invalidity, the
paired-channel definition changes, or a registered sensitivity alters a
substantive conclusion.
