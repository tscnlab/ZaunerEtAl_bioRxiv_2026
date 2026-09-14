# H01 METRIC-011 pre-production environment incident

Date: 2026-08-12  
Scope: operational environment only; no scientific output accepted

The first production invocation used R 4.6.1 but omitted the explicit project
`R_LIBS_USER` path. The parent process completed its read-only gate checks,
then all forked bootstrap attempts failed immediately because the workers
could not load `lme4`. The bounded bootstrap function consequently reported
zero successful joint refits and stopped on its required-success check.

No draw, checkpoint, summary, diagnostic, provenance, or manifest file was
written by that invocation. The accepted H01 package and every protected
artifact were unchanged.

Before relaunch, the runner gained a fail-fast assertion that the project R
4.6.1 library is present in `.libPaths()` and that `lme4` and `performance`
are available. The scientific inputs, formulas, response family,
transformation, target registry, seed scheme, joint-refit function, success
criteria, and requested 1,000 successful refits are unchanged from the
verified pilot. The authorized production rerun explicitly supplies:

`R_LIBS_USER=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23`

This is an environment-path correction, not a model, estimand, or output
change, and does not require a new pilot.
