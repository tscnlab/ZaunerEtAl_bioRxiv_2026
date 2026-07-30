# H02/H11 true-time sequence provenance

Finding ID: `FIND-019`  
Status: implementation and independent verification passed; provenance gate closed  
Date: 2026-07-30  
Severity: high for temporal autocorrelation; no current metric value is invalidated

## Finding

The main-analysis 30-minute and one-hour metric artifacts are deliberately
pseudo-local wall-clock grids. They retain `local_date`, `clock_bin`, the
number of represented real minutes, and daylight-saving fold counts, but no
true-UTC bin identifier or ordered source-bin provenance. This is correct for
clock-aligned exposure summaries, including the approved averaging of
repeated fall-back wall minutes. It is not sufficient to establish elapsed
adjacency for an autocorrelation model.

In particular, `local_date + clock_bin` cannot distinguish:

- ordinary neighboring real-time bins;
- bins separated by missing real time;
- the two real occurrences of a repeated fall-back wall-clock bin; or
- a clock-aligned row that averages observations from both occurrences.

H02 and H11 require clock time as an explanatory coordinate but true elapsed
time for ordering, sequence starts, and autocorrelation. Those two roles must
not be inferred from the same flattened key.

## Scope in the main-analysis data

A read-only R 4.6.1 audit of the complete 30-minute artifacts found
daylight-saving fold content on:

| Placement | Participant-days | Participants | Affected 30-minute bins | Repeated real minutes represented |
|---|---:|---:|---:|---:|
| Near eye | 4 | 4 | 8 | 240 |
| Chest | 2 | 2 | 4 | 120 |

The near-eye rows occur at FUSPCEU and MPI; the chest rows occur at FUSPCEU.
The small count limits the numerical scope but does not make a wall-clock key
a valid elapsed-time key.

Inputs and recorded SHA-256 values were:

- `artifacts/05_metrics/metrics_glasses_30_minute.rds`:
  `b641145c79ddb7ef9331f188c57d4fe0b1d3f1cc4c3b9e3b974fc92a2683889e`;
- `artifacts/05_metrics/metrics_chest_30_minute.rds`:
  `d2fca0bf193c450124c31df58a7deb3a4603aaa7bde86c63bdea63997b992b27`;
- `artifacts/03_coverage/light_glasses_coverage.rds`:
  `6242b7f876658ec8f7bdd9998c4f6b06cdb85f613320f10314e2ff0ad2d2d9e6`;
- `artifacts/03_coverage/light_chest_coverage.rds`:
  `8c0eb074d799753e98bb0dc7b82d6ea2fe11aa8be1fb1e54b21dddc266e59426`.

The audit grouped each 30-minute artifact by site, participant, placement,
and local date and counted rows with positive `dst_fold_wall_minutes`. It did
not fit a model or alter an analytical artifact.

## Implemented repair

Preparation 06 now creates an explicit temporal-sequence provenance artifact
from the verified one-minute real-time data. It retains:

- the true-UTC source-bin start and end;
- pseudo-local clock bin and offset/fold provenance;
- participant and participant-day keys;
- observed and expected real-time support;
- a reason-coded sequence-start flag based on true elapsed adjacency; and
- a link to the corresponding clock-aligned outcome row or a declaration
  that the true-time and clock-aligned planes cannot be represented
  one-to-one.

The implementation preserves two explicit planes:

1. a pseudo-local wall-clock plane for the time-of-day estimand; and
2. a true-UTC plane for elapsed ordering and dependence.

The producer does not recalculate, copy, or replace `metric_value_lx`. It
copies only exact outcome keys, support fields, admissibility, and finite-value
status from the main-analysis wall outcomes. A source bin is sequence-eligible
only when its wall outcome is both usable and one-to-one. True-UTC gaps,
missing wall bins, unusable outcomes, and the two real bins represented by an
averaged fall-back outcome terminate a sequence. Spring-forward wall rows with
no real-time source bin are retained in the wall-link artifact with explicit
zero-link provenance.

The implementation is in:

- `scripts/pipeline/temporal_sequence_provenance.R`;
- `scripts/pipeline/build_temporal_sequence_provenance.R`; and
- `scripts/pipeline/verify_temporal_sequence_provenance_artifacts.R`.

The durable outputs under
`artifacts/06_model_data/temporal_provenance/` are:

| Artifact | Rows | SHA-256 |
|---|---:|---|
| `true_utc_source_bins.rds` | 122,982 | `87c05a2534479c02ed62e16bc74a4c8a6a061aff125a528e404f403b3e2ff46b` |
| `true_utc_source_bins.csv` | 122,982 | `88c7d2bb953a26290031e589ac4d51ca026889b0403299f8ba9db6b2f436b4b5` |
| `wall_outcome_links.rds` | 122,976 | `a617893e74bbbd760950c185d0c548ff55692c52ded554a527dad2d72f2e6eb4` |
| `wall_outcome_links.csv` | 122,976 | `b4e7623f2b930162f33f08f9e426e915f28226a32181c41e297e7d3eb0a25141` |
| `artifact_manifest.csv` | 4 | `d05f8cf2ba7f5be01ae2fa5eb9c27350da2f84ed07508a731e243f1db23e1bb6` |

The current manifest fingerprint changed when the verified metric manifest
was regenerated after the darkest-10-hour roundoff repair. The four
scientific temporal artifacts retain their recorded hashes. See
`audit/findings/temporal_manifest_hash_reconciliation.md`.

## Independent verification

The R 4.6.1 verifier independently reconstructs bins by elapsed minutes from
each true-UTC local-day start rather than calling the producer. It verifies
the upstream hashes, RDS/CSV agreement, every source and wall key, exact
outcome links, support totals, sequence starts, and the known daylight-saving
scope. The complete verification passed with:

- 122,982 true-UTC source bins and 122,976 wall outcomes;
- 18 averaged two-to-one fall-back wall rows, representing 36 source bins;
- 12 zero-link structural spring-gap wall rows;
- six fall-back participant-days and four spring-forward
  placement-participant-days;
- 118,635 sequence-eligible source bins and 2,583 sequence starts.

Focused tests cover ordinary, fall-back, and spring-forward days, unusable
outcomes, duplicate keys, a full build and verification from a non-project
working directory, and a refreshed-hash scientific corruption. The corrupted
sequence reason is rejected by the independent reconstruction.

The manifest uses an exact 20-column deterministic schema. It excludes
runtime write timestamps and records output paths relative to the output
project root and input/upstream-manifest paths relative to an explicit input
root. Same-root and alternate-output-root builds produce the identical
current manifest hash, and both producer and verifier reject paths outside the
declared provenance root. This portability repair did not change any of the
four scientific artifact hashes.

No temporal model was fitted and no clock-aligned outcome was changed.
H02/H11 model fitting is therefore no longer blocked by missing provenance,
but the eventual autocorrelation and correlation structure remains a separate
model-specification gate. No temporal model may construct `AR.start`, another
correlation index, or a gap-free sequence solely from participant order or
`local_date + clock_bin`.

## Reopening condition

Reopen after any change to fall-back averaging, temporal aggregation,
sequence construction, the H02/H11 outcome grid, or the autocorrelation
strategy.
