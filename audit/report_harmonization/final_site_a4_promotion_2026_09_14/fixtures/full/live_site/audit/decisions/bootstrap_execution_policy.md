# Pilot-first bootstrap execution

Decision ID: `COMPUTE-001`
Date: 2026-07-31
Status: approved for future computation-heavy bootstrap and simulation runs

## Decision

Every computation-heavy bootstrap or simulation must pass a small production-
code pilot before the full run is launched.

The default pilot is 50 successful replicates for every planned target. Use
100 when the expected runtime remains practical or when 50 replicates do not
exercise the output and failure-handling paths adequately. A smaller pilot is
allowed only for an initial timing benchmark and does not replace the required
50- or 100-replicate review run.

The pilot must use the same:

- analysis inputs and pinned identities;
- transformations, formulas, distributions, links and estimands;
- resampling unit and joint-refit structure;
- target registry and output schema;
- failure, warning and convergence handling; and
- checkpoint and restart implementation

as the proposed full run. Pilot outputs must be stored separately and labelled
`PILOT — NOT FOR INFERENCE OR MANUSCRIPT REPORTING`.

## Review gate before the full run

After the pilot, the hypothesis task must report:

- requested and successful replicates, failures and warnings;
- elapsed time overall and by model or target;
- the projected full-run duration as a range, with the assumptions used;
- expected completion time and planned compute parallelism;
- peak-memory or disk concerns and whether restart/checkpoint behavior worked;
- preview tables and figures in the exact proposed reader-facing layout; and
- any numerical, diagnostic or presentation issue found in the pilot.

The full run may begin only after explicit author confirmation of the output
presentation and the proposed full-run cost. If the pilot exposes a code,
model, diagnostic or display problem, repair it and rerun the pilot before
requesting approval again.

## Scientific safeguards

Pilot estimates and intervals are too noisy for inference and must never be
copied into the manuscript, final result tables or claims. Model choices,
estimands and multiplicity families remain fixed before the pilot. A result-
dependent analytical change still requires the existing major-change process;
the pilot gate is not permission to search for a preferred result.

## Current H01 exception

The H01 production bootstrap had already been launched before this decision
was made and is not interrupted. The policy applies prospectively to every
new computation-heavy run, including a restarted H01 production run if its
implementation or requested outputs materially change.

## Reopening condition

Reopen if the pilot size, production replicate target, target registry,
resampling structure, runtime-estimation method or author-approval requirement
changes.
