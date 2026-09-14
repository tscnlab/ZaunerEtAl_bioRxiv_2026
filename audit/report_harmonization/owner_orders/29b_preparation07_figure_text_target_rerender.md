# REPORT-017 order 29b: Preparation 07 figure-text target rerender

Date: 2026-08-14

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Status: coordinator-released for exactly one target render

## Authority and required starting identities

This order implements the coordinator's REPORT-017 release after independent
acceptance of orders 29 and 29a. Recheck every identity immediately before
rendering and stop on drift:

| Item | Required SHA-256 |
|---|---|
| `notebooks/preparation/07_example_days.qmd` | `e5b89c62b03af2e7989f76cb9578608b92420978393a7c857fd5edcc335dbcb1` |
| `tests/test_preparation07_report.R` | `9d3a19b7d30ee0a6d5b0b643da628e25e970b232cf2f812fae1efdb4fe8fff58` |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| stopped target HTML | `aa531fb4aef06d6ac897dfdbb9f493e83ad3d431d8e87b309cdffb31f0691401` |
| independent source/test acceptance | `242210e5a723b127a1013596c16d88747c4248673e7cb8a142fcf017c9e5a3b3` |
| independent 16-entry manifest | `b100420011df99c1e67593c3c78af87c2ef2e54b9cef361dba6bccc38cd656bd` |

Confirm the accepted protected-input inventory and the current scoped
`_build/nathealth` inventory before execution. Preflight the build root for
symlinks and stop if any symlink resolves outside that root.

## Sole render command

Run exactly:

```text
quarto render notebooks/preparation/07_example_days.qmd --profile nathealth
```

Use the normal project `.Rprofile` and `renv/activate.R` path with the already
approved narrow access for transient writes to the existing user-owned renv
cache. Do not bypass the profile, install or update packages, edit
`renv.lock`, render another target, or run a full-project render.

## Required nonvisual checks

After the render:

1. Recheck the source, focused test, and profile identities above.
2. Run the complete focused Preparation 07 test against the new target HTML
   under R 4.6.1. It must pass every source and HTML assertion.
3. Verify the exact intended build delta. Record target HTML, target-owned
   HTML figure files, search index, sitemap, and any byte-identical stylesheet
   mtime refresh separately. Stop on an unexplained build change.
4. Reconcile the accepted protected-input set. Data, manifests, scientific
   outputs, durable source-data CSV, and durable PNG/SVG files must remain
   byte-identical.
5. Verify exactly seven native `gt` table endpoints with one Quarto caption
   each, exactly three figure endpoints with captions and alt text, all paired
   figure/source-data links, and absence of raw tibble or error output.
6. Verify semantic headings, the provenance-equivalence explanation and pins,
   country-coded site names, dynamic internal links, navigation, nonempty link
   labels, and absence of unresolved cross-reference warnings.
7. Confirm that the rendered figures are refreshed only from the frozen
   `artifacts/11_source_data/prepared_day_showcase.csv`. Do not rerun the
   fixed-seed selection or the strict production verifier.

No model, prediction, simulation, bootstrap, Shapley analysis, builder,
scientific verifier, source-data regeneration, durable figure regeneration,
or other scientific computation is authorized.

## Secure loopback visual QA

Use one temporary read-only static server rooted exactly at
`_build/nathealth`, bound only to `127.0.0.1` on an unused high or
OS-selected port. Record the command, PID, address, port, document root,
start time, and exact Preparation 07 URL. Inspect only that route in the
in-app Browser at 1440 x 1000 and 708 x 1000.

At both viewports, inspect title and heading hierarchy, callouts, wrapping,
clipping, overlap, navigation, captions, alt text, and link labels. Apply the
accepted table-display rule: native HTML tables must work reasonably at a
typical desktop width, and a contained usable horizontal scroller is
acceptable at 708 pixels; exported table PNGs, if any, are judged at their
intended exported size.

For the existing vertical Mermaid diagram, confirm legible labels of at least
7 pt at final size with no clipping, overlap, or harmful vertical expansion.
For each of the three showcase figures, measure the repaired legend title,
legend text, facet-strip text, and axis text at final displayed size. Confirm
that the accepted 10 pt source settings yield legible final text, with no
clipping, overlap, compressed panels, broken units, awkward wrapping, or
indistinguishable marks. Check the frozen data pattern and site order without
adjudicating or recomputing a result.

Stop the server immediately after QA, including after any browser rejection.
Record termination and prove that no listener remains on the port. Rehash the
source, test, profile, target HTML, target-owned figures, protected inputs, and
scoped build inventory after teardown.

## Return contract

Return:

- exact command, R/Quarto/package environment, exit status, and wall time;
- pre/post hashes and byte counts for the source, test, profile, target HTML,
  target-owned figure outputs, and every authorized build delta;
- focused-test, native-table, semantic, link/navigation, country-code, and
  no-error results;
- protected-input and durable PNG/SVG invariance evidence;
- desktop and 708-pixel screenshots or screenshot hashes, measured Mermaid
  and figure text sizes, table-scrolling verdict, and any limitations;
- server lifecycle and no-listener evidence; and
- a non-circular manifest covering the final verification record and its
  controlling evidence.

Stop and report any drift, render error, scientific discrepancy, missing
endpoint, broken link, or display defect. Do not edit the QMD, test, profile,
artifacts, manifests, ledgers, or scientific files. Every hypothesis render
remains held until Preparation 07 is independently accepted after this run.
