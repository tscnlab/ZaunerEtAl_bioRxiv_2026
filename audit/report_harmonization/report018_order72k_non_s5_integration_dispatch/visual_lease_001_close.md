# Visual lease 001 closure

Writer released `ORDER72K-VISUAL-LEASE-001` in its sealed stopped return.
The teardown receipt records task tab 4 closed, viewport override reset,
only pre-existing tabs 1 and 2 retained, and no Word document opened.
The task server PID 35776 was stopped at 2026-09-11T19:32:18Z; the failed
capture PID 36917 was absent from the final Writer process check.

Harmonizer independently checked port 58005 with
`lsof -nP -iTCP:58005 -sTCP:LISTEN`. Exit code was 1 with no output.
No task listener remains at that port. No new visual session was started.
A recovery requires a fresh serial QA allocation rather than reuse of this
closed lease. The Mac-unlock request remains outstanding.
