# BAUA import and state-alignment smoke reconciliation

Status: import, alignment, and coverage subset smoke passed; full-source reconciliation pending  
Date: 2026-07-30  
Runtime: R 4.6.1, clean `Rscript --vanilla` session

## Purpose

BAUA was processed in the isolated run directory
`artifacts/02_aligned/runs/subset_baua/` before the nine-site build was
allowed to write canonical artifacts. This test checked both the internal
assertions and agreement with the saved stage-1 objects wherever the approved
repairs should not change values. These counts are preparation diagnostics,
not manuscript results.

## Pipeline checks

| Placement | Native rows | One-minute rows | Participants | Native epoch | Duplicate absolute keys | Join cardinality |
|---|---:|---:|---:|---:|---:|---|
| Near-eye | 1,252,800 | 208,800 | 19 | 10 s | 0 | Preserved |
| Chest | 1,408,320 | 234,720 | 22 | 10 s | 0 | Preserved |

Every minute had the expected six source timestamps. The aligned outputs
retained the same row count as their imported one-minute inputs. The joint
non-wear assertion passed: no row flagged as invalid non-wear retained finite
analytical MEDI or LIGHT.

The approved operating boundary identified no BAUA near-eye minute and seven
BAUA chest minutes at or above 100,000 lx melanopic EDI. The seven chest
minutes involved four participants and five participant-days. Their
illuminance values were not independently thresholded.

## Reconciliation with the saved stage-1 objects

Rows were matched in R by participant and pseudo-local one-minute timestamp;
BAUA had no fall-back collision in its acquisition interval.

| Placement | Matched rows | Finite MEDI in saved object | Finite MEDI after repair | Finite in both | Exact finite-value matches | Saved-only finite MEDI |
|---|---:|---:|---:|---:|---:|---:|
| Near-eye | 208,800 | 174,065 | 174,065 | 174,065 | 174,065 | 0 |
| Chest | 234,720 | 191,595 | 191,588 | 191,588 | 191,588 | 7 |

Thus every mutually finite BAUA MEDI value was numerically identical. The
only MEDI difference was the expected seven-minute chest boundary change.

The saved preparation retained finite LIGHT during some logged `off` periods.
After applying the approved joint non-wear mask, finite LIGHT fell from
180,989 to 174,065 near-eye minutes and from 200,770 to 191,595 chest minutes.
The seven saturated chest minutes retain finite LIGHT but do not form a valid
MEDI–LIGHT pair.

## Coverage and sample-flow reconciliation

Preparation 02 was then run from a separate clean R 4.6.1 process against the
isolated aligned artifacts. It evaluated the registered inclusive 50%
within-hour rule followed by the 80% within-day rule on the complete
1,440-minute pseudo-local wall-clock grid, while retaining every real
true-UTC row.

| Placement | Input participant-days | Eligible participant-days | Participants contributing eligible days | Finite eligible MEDI minutes | Finite eligible LIGHT minutes |
|---|---:|---:|---:|---:|---:|
| Near-eye | 145 | 106 | 18 | 146,820 | 146,820 |
| Chest | 163 | 113 | 20 | 157,388 | 157,393 |

The eligible participant-day key sets were exactly the same as in the saved
stage-2 BAUA objects: 106 of 106 near-eye days and 113 of 113 chest days
matched, with no key unique to either implementation. Every mutually finite
MEDI value also matched exactly. The five fewer eligible chest MEDI minutes
are the subset of the seven newly range-invalid minutes that occurred on
otherwise eligible participant-days.

The repaired joint non-wear rule intentionally changes the eligible LIGHT
count without changing the participant-day selection. Relative to the saved
stage-2 objects, it removes 1,380 near-eye and 1,307 chest LIGHT minutes that
had no valid paired MEDI during true non-wear. The five range-invalid chest
MEDI minutes retain finite LIGHT, which explains the five-minute difference
between eligible MEDI and LIGHT counts; these rows remain unavailable to
paired-channel metrics.

## Gate

This subset establishes that the native-epoch aggregation, state alignment,
and registered coverage code reproduce the BAUA MEDI values and eligible-day
set exactly outside the explicitly approved operating-boundary change, while
implementing the approved LIGHT non-wear repair. It authorizes the full
pinned-release run. The complete nine-site comparison may supersede these
counts and remains the scientific gate.
