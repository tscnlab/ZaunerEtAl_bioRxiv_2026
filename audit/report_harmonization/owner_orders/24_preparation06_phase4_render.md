# REPORT-017 owner order 24: Preparation 06 targeted render and visual QA

Date: 2026-08-13  
Coordinator decision: REPORT-017 / CHG-134  
Harmonization acceptance prerequisite: Preparation 05 accepted in
`audit/report_harmonization/report017_preparation05_independent_acceptance.md`  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/06_model_ready_datasets.qmd`

## Serial release

Preparation 06 is the sole active REPORT-017 render owner. Preparation 07 and
every later page remain held. Do not start another page while this order is
open.

## Required preflight identities

Recheck these identities immediately before execution and stop on drift:

- `notebooks/preparation/06_model_ready_datasets.qmd`:
  `2067db45d46b49bec34985f68eb9e10d5e35377548c5103218321261d50f4c5b`;
- `_quarto-nathealth.yml`:
  `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`;
- `tests/test_preparation06_report.R`:
  `e4b02061832be158372b54e1c473e0f221ab84cdd0aa7fb38e7d41cfb82f6f51`;
- `audit/handoffs/preparation_reports_worker_handoff.md`:
  `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640`.

The currently stale target HTML is
`_build/nathealth/notebooks/preparation/06_model_ready_datasets.html`,
SHA-256
`8211aff02f0f886211347e1d363d721036bb08017bc06b773dacfd36320cd401`.
It is a preflight reference, not an accepted render of the current source.

The preceding 168-path METRIC-011 read-set baseline is
`audit/preparation_reports/preparation06_metric011_prerender_scoped_readset.csv`,
SHA-256
`f03f6a9e7eccba3b4cbdbd8dc494b44b48adb583c73f5d9fa93556412260fe30`.
Its handoff comparison is
`audit/preparation_reports/preparation06_metric011_handoff_scoped_verification.csv`,
SHA-256
`404a10ccfee70ad54d5560d876d1c52fad97beb6d10de89c24e40a098d6b7a35`.
Reconcile all 168 paths to the current source and profile identities. The
accepted source-only harmonization and shared H06_daily profile placement are
the expected documentation/configuration changes relative to that older
baseline. Every other protected model-input artifact, acquisition input,
metric artifact, context file, manifest, audit, decision, production script,
and environment identity must remain exact. Seal a fresh current preread
inventory and compare it again after rendering and after loopback QA. Stop on
any unexplained drift.

The existing stored-data display figure is
`_build/nathealth/notebooks/preparation/06_model_ready_datasets_files/figure-html/fig-site-composition-1.png`,
SHA-256
`058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da`.
Its paired source data are
`artifacts/08_diagnostics/preanalysis_comparison/categorical_levels.csv`,
SHA-256
`809d109d3647ef4ac1798ef9eb59c06e2c7db41f5b9ce1dade4d0a8b583f0a22`.
The prior generated dimensions were 2,160 by 1,958 pixels. The plot is a
display of accepted stored data and must not trigger a scientific rebuild.

## Sole render command

Run exactly once:

```text
quarto render notebooks/preparation/06_model_ready_datasets.qmd --profile nathealth
```

Use Quarto 1.9.37, R 4.6.1, the normal project `.Rprofile`, and
`renv/activate.R`. Use only the already approved narrow elevated access for
transient writes to the existing user-owned renv cache. Do not bypass the
project profile, install or update a package, edit `renv.lock`, render another
target, or run a full-project render.

No source edit is authorized in this order. If the render, focused test, or
visual inspection exposes a defect, stop, preserve the evidence, and return a
bounded correction request.

## Scientific and provenance boundary

Rendering may read accepted stored model-input, metric, site-context,
manifest, reconciliation, and diagnostic evidence; perform the page's bounded
identity and schema checks; calculate its existing lightweight display
summaries; and format its current tables and stored-data figure. It must not
run a normalization, assembly, context, temporal-provenance, model-data,
H01-frame, descriptive-comparison, preparation, metric, or scientific
builder or verifier. It must not change a sample, metric, MDER or L10 value,
fit a model, predict, estimate autocorrelation, bootstrap, simulate, run
Shapley analysis, or overwrite an accepted artifact.

Preserve every count, value, unit, definition, sample distinction, prepared
frame, source-data file, manifest identity, and scientific qualification. In
particular:

- keep prepared-frame counts distinct from fitted-model samples;
- keep metric-support hours distinct from observations;
- retain the approved first-use explanation and values for the
  gap-timing-unaware dataset;
- retain the current METRIC-010 and METRIC-011 wording, values, evidence, and
  version-specific provenance boundaries;
- preserve the visible Preparation 04/06 reconstruction qualifications and do
  not resolve or weaken them editorially; and
- preserve the exact dynamic
  `[DEV-056](../preregistration_deviations.qmd#dev-056)` link and its current
  consequence wording.

## Focused post-render checks

Run the existing focused Preparation 06 test under R 4.6.1 against the new
target HTML. Also perform scoped R-source parse checks, dynamic-link and
anchor checks, country-coded-site checks, navigation checks, and
`git diff --check` for the authorized scope. If the test contains a stale
assertion, stop and return the exact assertion. Do not edit the test without
separate authorization.

Verify that the HTML contains:

- the accepted title, purpose, preparation-chain position, information
  hierarchy, glossary, and render-boundary callout;
- all 19 current `tbl-*` endpoints as native `gt` tables, each with exactly
  one nonempty Quarto-owned caption and its intended notes, labels, rows, and
  ordering;
- `fig-site-composition` with its informative caption, substantive alt text,
  all nine country-coded sites, registered order and colours, direct counts,
  and paired source-data link;
- the current primary and gap-timing-unaware model-ready inputs, site and
  daylight context, elapsed-time provenance, shared near-eye and chest
  samples, H01 prepared frames, MDER and L10 handoffs, and exact hypothesis
  handoff identities;
- the resolved exact DEV-056 anchor and every other dynamic internal link;
  and
- the active Preparation 06 navigation entry with the current profile order,
  including H06_daily in its accepted later hypothesis position.

Reject rendered R errors or warnings, raw tibble or console output, duplicate
or missing identifiers, empty link labels, hard-coded internal `.html` or
absolute-local source links, unresolved current-page fragments, links into
`_build`, or an unexpected change to the stored-data figure or source data.

## Visual QA and table policy

After all nonvisual checks pass, serve the existing build through one
temporary static server rooted exactly at `_build/nathealth`, bound only to
`127.0.0.1` on an unused high or ephemeral port. Preflight the document root
for symlinks and stop if any resolves outside that root. Record the exact
server command, operating-system PID, address, port, document root, start
time, exact Preparation 06 URL, stop time, process termination, and listener
closure. Use only the ordinary in-app Browser. Do not use `file://`, Chrome,
Computer Use, CDP, a LAN bind, or a public tunnel.

Inspect at a typical 1440 by 1000 desktop/laptop viewport and at a requested
708 by 1000 narrow viewport:

- typography, headings, callouts, wrapping, link labels, navigation, and
  page-level clipping or overflow;
- the existing left-to-right overview Mermaid diagram, including measured
  label size, clipping, overlap, and harmful compression or expansion;
- all 19 native HTML tables, their captions, headers, rows, notes, long paths
  and hashes, and adjacent content; and
- the site-composition figure at its intended display size, including all
  nine site labels and colours, counts, axes, caption, alt text, and
  source-data link.

Mermaid labels must remain legible and measure at least 7 pt at both requested
viewports. Do not pre-emptively change the current `flowchart LR` declaration.
If the rendered diagram fails the threshold or has clipping or overlap, stop
and return the exact measured defect. No diagram edit is authorized here.

For native HTML tables, the controlling readability check is the typical
desktop/laptop viewport. At 708 pixels, require page integrity and a contained,
usable horizontal-scroll affordance. A dense table does not have to fit
without scrolling. If an exported table appears unexpectedly, stop. An
exported table's PNG at intended final size would be the controlling visual
artifact. Preparation 06 is expected to contain native HTML tables only. Its
PNG is a figure and must separately pass the intended-final-size figure check.

Retain desktop and narrow screenshots in the owner audit scope. Stop the
server immediately after QA, confirm no listener remains, then rehash the
source, configuration, HTML, figure, source data, protected read set, and
scoped build inventory. Report every final hash, byte count, viewport
measurement, render duration, command, relevant package and environment
identity, and any transient build files touched. Do not release Preparation
07. Return the complete evidence for independent harmonizer acceptance.
