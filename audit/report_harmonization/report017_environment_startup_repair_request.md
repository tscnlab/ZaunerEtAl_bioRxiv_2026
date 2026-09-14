# REPORT-017 scoped environment-startup repair request

Date: 2026-08-13  
Requested owner: central coordinator or environment owner  
Status: **repair required before the Phase 4 serial render queue resumes**

## Problem statement

The sole authorized Descriptives target-render command did not reach knitr.
Its R 4.6.1 child spent approximately 72 minutes 28 seconds below
`R_LoadProfile` in repeated `dir.create()` and `file.info()` work during
project renv activation. The owner interrupted the nonproductive startup loop
after a read-only stack sample established that the QMD and its packages had
not loaded. No source, build output, scientific artifact, package, or lockfile
changed.

The sealed evidence is in
`audit/report_harmonization/report017_render_order_01_blocked_verification.md`.

Current startup identities are:

- `.Rprofile`:
  `3f9d62fc3f1bf5888a09816101b705f9844ef4cd44ee5ad157f4168dac4af4d4`;
- `renv/activate.R`:
  `51798a35c2772b94b4a73ae7a7cc928975ff6e628a17bad1bc73d30defca82e6`;
- `renv.lock`:
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

## Requested diagnostic and repair boundary

Please diagnose and repair only normal project R startup. Do not render a QMD
as the diagnostic, and do not modify a reader source, scientific artifact,
package version, or `renv.lock`.

1. Reproduce the problem with a non-rendering R 4.6.1 startup smoke command
   under a short bounded timeout. Record the exact command, environment
   variables relevant to renv paths, process duration, exit status, and the
   resolved project and library paths.
2. If startup does not complete promptly, capture a short read-only stack or
   system-call trace that identifies the exact path used by the repeated
   directory creation or file-information calls. Do not infer the path from
   the bootstrap source alone.
3. Determine whether the loop is caused by the project library path, a global
   renv cache path, a profile or sandbox path, a stale link, or another
   environment condition. Record the observed cause before changing it.
4. Apply the smallest coordinator-owned or environment-owned repair. Do not
   install or update packages, do not edit `renv.lock`, and do not bypass the
   project profile for the final render.
5. Verify that a fresh normal R 4.6.1 project startup completes within the
   bounded smoke window, loads renv 1.2.3 from the intended project library,
   and reports the expected `.libPaths()` without changing the three sealed
   startup identities unless a separately authorized repair explicitly
   requires one.
6. Return pre-change and post-change identities for every changed environment
   file or path, the exact smoke-test output, and confirmation that no package,
   lockfile, scientific artifact, reader source, or build output changed.

If the repair would require an activation-script edit, package restoration,
cache reconstruction, library relocation, or profile bypass, stop and obtain
explicit coordinator and author authorization for that expanded action. A
manual `.libPaths()` override used for the display-only diagnostic is not an
accepted substitute for the normal project-profile render path.

## Release gate

After the normal startup smoke passes, release exactly one fresh targeted
command:

```text
quarto render notebooks/descriptives.qmd --profile nathealth
```

Before that command, recheck the accepted source and profile hashes recorded
in the blocked verification. The Descriptives owner must also apply and seal
the separately authorized reader-only footnote correction before the fresh
render. The broad Descriptives scientific test remains excluded. The fresh
render must use the existing narrow stored-input and HTML acceptance
contracts, then return final-size visual evidence. No later owner render may
start until Descriptives is accepted.

