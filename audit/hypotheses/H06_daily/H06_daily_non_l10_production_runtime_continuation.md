# H06-D-013 checkpointed runtime continuation

- Date: 2026-08-12
- Gate: H06-D-G2
- Scientific authorization: H06-D-013 / CHG-123
- Runtime amendment: direct author instruction in the H06_daily task

## Author instruction

The author first authorized checkpointed continuation of H06-D-013 from the
existing sealed checkpoints with at most 15 additional minutes of serial
computation. After a forced process restart, the author instructed the task to
continue. The restart did not advance any persisted scientific checkpoint.

The owner then explicitly superseded the 15-minute ceiling: checkpointed serial
computation may continue through completion, provided a bounded health check is
performed and reported at least every 15 minutes. Each check must cover
checkpoint progress and completed refits, the non-estimable/failure rate,
runtime trend, repeated checkpoint failures if any, and verification that
protected inputs and identities remain unchanged. Scientific scope and the
mandatory H06-D-G2 author stop remain unchanged.

## Sealed continuation origin

The continuation starts from the last valid persisted state:

- production phase: `BASE_COMPLETE`;
- completed influence cells: 237 of 468;
- completed influence refits in the cell index: 33,669;
- additionally preserved partial refits in cell 238: 125 of 146;
- total preserved influence refits: 33,794 of 66,664;
- remaining influence refits: 32,870;
- base-model wall time: 427.316 seconds;
- completed-cell influence wall time: 3,170.248 seconds;
- partial-cell influence wall time: 2.204 seconds; and
- total persisted base-plus-influence wall time: 3,599.768 seconds.

The original influence runner remains byte-identical. A continuation controller
may replace only its expired 3,600-second runtime stop in memory with the
required bounded health-check call. All frame construction, model fitting,
deletion ordering, diagnostics, checkpoint structures, failure rules, hashes,
and scientific output code remain unchanged. Existing checkpoints must
continue to validate against the original runner's code hash.

## Boundary

The continuation is serial and has no replacement runtime ceiling. It must stop
if the systemic failure rule triggers, if a pin or checkpoint identity fails,
if checkpoint failures repeat, or when H06-D-G2 is reached. Health checks are
written at the start, at least every 900 seconds while computation is active,
and at completion. The extension does not authorize a new model, sensitivity,
family, placement, sample role, bootstrap, simulation, Stage 3/4 work, shared
edit, main-H06 edit, commit, or push. REPORT-016/CHG-126 remains independent and
must not be consumed.
