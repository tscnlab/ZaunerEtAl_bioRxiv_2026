# renv status timeout-runner validation

The process-level timeout was tested on a harmless child R process, not on
`renv::status()`. The child printed `fixture-start`, flushed its output, and
then requested a five-second sleep. The wrapper used a 0.2-second wall-clock
limit.

Observed result:

| Field | Value |
|---|---:|
| Elapsed time | 0.209 seconds |
| Timed out | `TRUE` |
| Termination attempted | `TRUE` |
| Termination succeeded | `TRUE` |
| Process alive after termination | `FALSE` |
| Exit status | `-9` |
| Retained stdout | `fixture-start` |

A separate fast child completed normally with exit status `0`. The automated
test in `tests/test_renv_status_timeout.R` repeats both cases with warnings
treated as errors. The actual project status call remains deliberately
unexecuted until the final lockfile gate.
