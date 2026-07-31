# H02/H11 true-time sequence provenance

Finding ID: `FIND-019`  
Status: implementation and independent verification passed; current bundle approved
Date: 2026-07-30; current-input repin 2026-07-31
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
  `039031c1b8f362a911d750007504f01b943b91d7c7089ee8fb985b6a6871104a`;
- `artifacts/05_metrics/metrics_chest_30_minute.rds`:
  `3c762936558099a904b9b8dbe1489cd912ec623b5d14490e2053c5af1fd766e6`;
- `artifacts/03_coverage/light_glasses_coverage.rds`:
  `00085dc32ae370f059da9bfb6dfbf560eda4c4376fdb0727d2ef3c0b4fec34ee`;
- `artifacts/03_coverage/light_chest_coverage.rds`:
  `07f2be7b58839b384eda76c6bf21ca736791fc81e22c07bd4615e35bbb0ff1ce`.

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
| `true_utc_source_bins.rds` | 123,702 | `08d1adfb3e55c93da043b74d07dfade203c34f720c88062fa83eec5ebd1844f9` |
| `true_utc_source_bins.csv` | 123,702 | `b77a80e327660607ccf24299b932f2d6e1c6eeb06ab8fac2b19d9aa577f101fd` |
| `wall_outcome_links.rds` | 123,696 | `69232e8f7bdfbf379e7f92a220d2ecad893bce38e9ec57add313f5545e62829a` |
| `wall_outcome_links.csv` | 123,696 | `0e8baf5e7548efff60c2cc2c4eda3418dfcddb02b5523acb30506f8a77890850` |
| `artifact_manifest.csv` | 4 | `9355f7ca4f249059cf49808a3fb1caf9e764a6160f5d61beba8234a2bfbdef7d` |

The current bundle was regenerated from the final verified coverage and
metric artifacts after the accepted preparation repairs, including the
exact-all-zero melEDI day exclusion. Its coordinated approval is recorded in
`audit/decisions/h02_shared_input_transition.md`.

## Independent verification

The R 4.6.1 verifier independently reconstructs bins by elapsed minutes from
each true-UTC local-day start rather than calling the producer. It verifies
the upstream hashes, RDS/CSV agreement, every source and wall key, exact
outcome links, support totals, sequence starts, and the known daylight-saving
scope. The complete verification passed with:

- 123,702 true-UTC source bins and 123,696 wall outcomes;
- 18 averaged two-to-one fall-back wall rows, representing 36 source bins;
- 12 zero-link structural spring-gap wall rows;
- six fall-back participant-days and four spring-forward
  placement-participant-days;
- 119,537 sequence-eligible source bins and 2,632 sequence starts.

Focused tests cover ordinary, fall-back, and spring-forward days, unusable
outcomes, duplicate keys, a full build and verification from a non-project
working directory, and a refreshed-hash scientific corruption. The corrupted
sequence reason is rejected by the independent reconstruction.

The manifest uses an exact 20-column deterministic schema. It excludes
runtime write timestamps and records output paths relative to the output
project root and input/upstream-manifest paths relative to an explicit input
root. Same-root and alternate-output-root builds produce the identical
current manifest hash, and both producer and verifier reject paths outside the
declared provenance root. The current manifest and all four scientific files
were reverified after the final shared-input regeneration.

The shared preparation step does not fit a temporal model or alter a
clock-aligned outcome. H02 is authorized to rebuild and refit against the
approved current bundle; H11 must inherit the same temporal-provenance inputs.
No temporal model may construct `AR.start`, another correlation index, or a
gap-free sequence solely from participant order or `local_date + clock_bin`.

## Reopening condition

Reopen after any change to fall-back averaging, temporal aggregation,
sequence construction, the H02/H11 outcome grid, or the autocorrelation
strategy.
