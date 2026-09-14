# Brown simple-frame preservation stop: independent disposition

Date: 2026-09-12. Finding: `BA-LB-SIMPLE-FRAME-PRESERVATION-001`.
Authority chain: BA-018 / CHG-157, qualified continuation 001 and diagnostic
export recovery 001. Status: METADATA-ONLY VERIFICATION-REFERENCE DEFECT
CONFIRMED. NO REPAIR, FIT OR RETRY RELEASED.

## Verdict and preserved stop

The stopped assertion does not establish a changed timestamp, denominator,
membership or scientific field. It compares different metadata baselines.
The cause is confirmed and a narrow reference correction is supported by a
full temporary downstream construction replay. The actual owner remains
stopped and no sensitivity construction package is accepted or promoted.

Owner Stage 2 root:
`/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/`.
Owner return: `completion_v2/continued_final_package_004/`.

- Final manifest: `dadaeea48843c05704e129c5903ce84474452b85cf12bc76eb36d7b4f3a8dee3`,
  independently 326/326 exact, unique and non-circular.
- Verification: `d8b16726ee9f24823f7842219281881bfec8b55ea31e5cfa4684efef57ae6d23`.
- Handoff: `b4d19a6b0e119aa1b4f6be62d0e0e38aaccc03f6a11c82e47ce78e544e00d2e1`.
- Gate: `9d91c4b17011220039503bd08867607817b0e9a6922c3768ee8bf62eaf4e9c76`.
- Finalization: 23/23 PASS; 4,533 protected group rows and all 2,287 distinct
  paths independently exact.

Twelve jobs retain four nonzero exits, no timeouts and reaped children.
Their cumulative time is 107.00817287495011 seconds. A read-only process
probe confirms the exact stopped child PID 82331 is absent. No computational
lock or author `sensitivities/simple_frames/` directory exists.

Both completed primary diagnostic packages have 15/15 exact manifest members,
14/14 construction checks and retained raw checkpoints. Attempted diagnostic
draws remain 750, with 500 logical draws durably exported. No new fit or draw
occurred in the stopped support job. The Pre-sleep M1 coverage criterion and
its approved qualification remain unchanged; temporal qualifications remain.

## Confirmed finding

Category: implementation/provenance verification. Confidence: confirmed.
Severity: medium workflow blocker; no demonstrated scientific discrepancy.

`code/08_simple_sensitivity_contract.R` constructs each of the eight samples
by ordinary data-frame row subsetting. For strict thresholds it selects all
rows and replaces only the five declared response-derived fields.

`code/09_construct_simple_sensitivities.R`, frozen SHA-256
`83544bf3c563c0cd86065e0d62eead009ad403d91f23a8f47d851d36f58a4e10`,
compares the strict frame's unchanged columns against an unsliced `b_any`.
The other seven checks compare against a row-subset reference instead.

Read-only R 4.6.1 reconstruction finds the strict frame and source both have
2,298 rows and 34 columns, with identical column names and row names.
Exactly three columns outside the five authorized response fields differ
under `identical()`:

| Column | Actual difference | Preserved identity |
| --- | --- | --- |
| `behavior_date` | Descriptive `label` attribute becomes NULL after subsetting | Exact numeric date values, row order and Date class |
| `period_start_utc` | Descriptive `label` attribute becomes NULL after subsetting | Exact numeric instants, POSIXct/POSIXt classes and UTC time zone |
| `period_end_utc` | Descriptive `label` attribute becomes NULL after subsetting | Exact numeric instants, POSIXct/POSIXt classes and UTC time zone |

The frozen original labels remain intact in `frames/model_frames.rds`.
They describe the diary fields and local-coordinate/true-instant distinction.
They were not rewritten in the source. Their omission in the newly sliced
copies is recorded explicitly, not hidden as literal whole-object equality.
Removing only each expected label from a temporary copy makes each entire
time vector exactly identical. No other attribute difference exists in those
vectors. Object-level names, class and row-name attributes are exact.

The strict numerical response changes are the registered substitutions from
the frozen strict numerator/denominator fields. The primary frame, model pair,
primary estimands, sample definitions and scientific evidence are unchanged.

## Bounded correction supported by the audit, not yet released

Keep the pure sensitivity-construction function and all source data unchanged.
Compare strict unchanged columns to the same all-row subset operation used to
construct that sample, rather than to an unsliced object:

```r
b_any[rep(TRUE, nrow(b_any)), setdiff(names(b_any), strict_columns), drop = FALSE]
```

This replaces only the right-hand comparison expression. It is not permission
to strip attributes globally, disable attribute checks, relax `identical()`,
change dates/time zones, restore data from a different linkage, or change the
scientific construction. A later implementation should add explicit labeled
Date/POSIXct regression fixtures that retain the scientific-value/class/time-
zone checks and classify only the three expected descriptive-label omissions.

The prospective one-expression audit candidate reverses exactly to the
stopped driver. It remains temporary evidence, not an authorized owner file.
Any future version will also require new self/registry identities and a
specific supervisor exception for this exact failed construction job. Do not
modify the failed job, rerun its consumed ID, amend v4 silently or reuse the
temporary construction outputs as production sensitivity frames.

## Full read-only downstream verification

The original assertion failure was reproduced before any temporary export.
The prospective comparison then passed the entire remaining construction
logic with actual frozen frame inputs and writes redirected solely to a
temporary audit directory:

- eight exact Stage 1 membership/count reconciliations;
- all seven non-strict source-subset preservation checks;
- all 45 design-rank checks across nine inputs;
- the existing seven final construction checks;
- six unique, exact temporary export members, with no circular manifest;
- strict response substitution from the registered frozen fields;
- negative tests rejecting changed dates/instants, UTC time zone,
  denominator and row order.

The combined independent downstream suite is 21/21 PASS. This includes pure
design-matrix and initial-parameter construction, not model fitting. No TMB
object, optimizer, saved model, prediction, contrast, p-value, inference,
diagnostic draw, author output, render, report or reader artifact was produced.
All authoritative inputs were rehashed unchanged afterward.

Analytical audit scripts and derived outputs are retained outside the author
project at `/private/tmp/ba018-strict-preservation-audit.FN6TWw/`. Their exact
identities and input pins are included in the independent manifest. These
temporary RDS files contain controlled audit copies and are not reader data
or a release for reuse. No participant identifiers or individual timestamps
are reproduced in this disposition.

R-recorded elapsed time for the two focused construction/metadata audits and
the original/corrected downstream replays is recorded separately in
`audit_compute_accounting.csv`. Keep this additional read-only computational
time in any later cumulative-budget disposition; do not reset the 1,200-second
ceiling. Hash-only preservation checks are not scientific computation.

The first package-accounting query used the preceding package's column names
and stopped at the draw-total assertion. Package 004 uses `attempted_to_date`
and `completed_logical_draws`. The corrected exact six-row schema reconciles
750 attempted and 500 logical draws. No owner value changed; no scientific
work was repeated to correct that audit query.

## Required next boundary

This record accepts the integrity and classification of the stop, not complete
Stage 2 science and not execution of a correction. Prepare one separately
sealed versioned comparison/metadata-fixture/provenance continuation only if
implementation is authorized. Preserve all 326 owner members, both successful
diagnostic packages, all primary outputs and the exact failed histories.

`BA-LB-G2-REVIEW` remains mandatory. No retry, fit, diagnostic repeat, model
change, source/report edit, R2/Shapley, Stage 3/4, S5, Writer integration,
manuscript/Word/ZIP/website operation or render is released by this audit.
