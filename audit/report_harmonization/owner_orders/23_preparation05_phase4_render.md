# REPORT-017 owner order 23: Preparation 05 targeted render and visual QA

Date: 2026-08-13  
Coordinator decision: REPORT-017 / CHG-134  
Harmonization acceptance prerequisite: Preparation 04 accepted in
`audit/report_harmonization/report017_preparation04_independent_acceptance.md`  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/05_model_input_acquisition.qmd`

## Serial release

Preparation 05 is the sole active REPORT-017 render owner. Preparation 06 and
every later page remain held. Do not start another page while this order is
open.

## Required preflight identities

Recheck these identities immediately before execution and stop on drift:

- `notebooks/preparation/05_model_input_acquisition.qmd`:
  `184c40b45f349dc7129a86a2e8a0cf57665df7f9a82a4183ea1128b09954ad1d`;
- `_quarto-nathealth.yml`:
  `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`;
- `tests/test_preparation05_report.R`:
  `c7a38c0b8c66b52776f307640198586a7ed22b95fd87c7c3f123a38e8594b7c2`;
- `audit/handoffs/preparation_reports_worker_handoff.md`:
  `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640`.

The currently stale target HTML is
`_build/nathealth/notebooks/preparation/05_model_input_acquisition.html`,
SHA-256
`1e3cddd7e66168159e5fb97564aa3fa274fb760571265bd0c6eb84597b72291d`.
It is a preflight reference, not an accepted render of the current source.

The preceding 128-path read-set baseline is
`audit/preparation_reports/preparation05_final_profile_prerender_scoped_readset.csv`,
SHA-256
`c9aee2be47e89ccaf36759ce448c3b003421a185ceb19c5c86a4c06704c909ad`.
Its final-profile handoff comparison is
`audit/preparation_reports/preparation05_final_profile_handoff_scoped_verification.csv`,
SHA-256
`245a9c3372fe769fddda9aa37b36bbd69fa4d83ab7984966a949481ddea4536a`.
Reconcile all 128 paths to the current source and profile identities. The
accepted source-only harmonization and shared H06_daily profile placement are
the two expected documentation/configuration changes relative to that older
baseline. Every other protected acquisition input, accepted local file,
registry, manifest, audit, decision, script, and environment identity must
remain exact. Seal a fresh current preread inventory and compare it again
after rendering and after loopback QA. Stop on any unexplained drift.

## Sole render command

Run exactly once:

```text
quarto render notebooks/preparation/05_model_input_acquisition.qmd --profile nathealth
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

Rendering may read the accepted registries, acquisition manifest, local fixed
files, object audit, and column audit; perform the page's bounded identity and
schema checks; and format the existing display summaries. It must not contact
the network, acquire or overwrite a source file, run an acquisition builder or
scientific verifier, normalize or recode a variable, create a model input,
join a hypothesis sample, fit a model, predict, estimate autocorrelation,
bootstrap, simulate, run Shapley analysis, or change an accepted artifact.

Preserve every release, commit, DOI, path, object name, column count, file
count, row count, hash, byte count, site-modality mapping, source exception,
sample boundary, table value, and scientific or provenance statement. The
page must continue to distinguish immutable acquisition from Preparation 06
normalization and analysis.

## Focused post-render checks

Run the existing focused Preparation 05 test under R 4.6.1 against the new
target HTML. Also perform scoped R-source parse checks, link and anchor checks,
country-coded-site checks, navigation checks, and `git diff --check` for the
authorized scope. If the test contains a stale assertion, stop and return the
exact assertion. Do not edit the test without separate authorization.

Verify that the HTML contains:

- the accepted title, purpose, preparation-chain position, information
  hierarchy, and render-boundary callout;
- all nine current `tbl-*` endpoints as native `gt` tables, each with exactly
  one nonempty Quarto-owned caption, plus the intact source notes on the eight
  endpoints that define one in the accepted source;
- the complete 9-site by 7-modality grid, the 63/63 acquisition outcome, the
  963-column structural audit, the fixed release/commit/DOI identities, exact
  sleep-diary reuse, and the scoped Munich (DE) exercise-diary correction;
- submitted reader site names with country codes, registered order and
  colours, and no uncoded study-site label;
- dynamic and resolved internal links, including Preparation 06 and the two
  detailed provenance records; and
- the active Preparation 05 navigation entry with the current profile order,
  including H06_daily in its accepted later hypothesis position.

Reject rendered R errors or warnings, raw tibble or console output, duplicate
or missing identifiers, empty link labels, hard-coded internal `.html` or
absolute-local source links, unresolved current-page fragments, links into
`_build`, network access, or an unexpected generated empirical figure.

## Visual QA and table policy

After all nonvisual checks pass, serve the existing build through one
temporary static server rooted exactly at `_build/nathealth`, bound only to
`127.0.0.1` on an unused high or ephemeral port. Preflight the document root
for symlinks and stop if any resolves outside that root. Record the exact
server command, operating-system PID, address, port, document root, start
time, exact Preparation 05 URL, stop time, process termination, and listener
closure. Use only the ordinary in-app Browser. Do not use `file://`, Chrome,
Computer Use, CDP, a LAN bind, or a public tunnel.

Inspect at a typical 1440 by 1000 desktop/laptop viewport and at a requested
708 by 1000 narrow viewport:

- typography, headings, callouts, wrapping, link labels, navigation, and
  page-level clipping or overflow;
- the existing left-to-right overview Mermaid diagram, including measured
  label size, clipping, overlap, and harmful compression or expansion;
- all nine native HTML tables, their captions, headers, rows, notes, and
  adjacent content; and
- the complete site-release and acquisition-verification displays, including
  country-coded site names, colours, long release identifiers, paths, and
  source notes.

Mermaid labels must remain legible and measure at least 7 pt at both requested
viewports. Do not pre-emptively change the current `flowchart LR` declaration.
If the rendered diagram fails the threshold or has clipping or overlap, stop
and return the exact measured defect. No diagram edit is authorized here.

For native HTML tables, the controlling readability check is the typical
desktop/laptop viewport. At 708 pixels, require page integrity and a contained,
usable horizontal-scroll affordance. A dense table does not have to fit
without scrolling. If an exported table appears unexpectedly, stop. An
exported table's PNG at intended final size would be the controlling visual
artifact, but Preparation 05 is expected to contain native HTML tables only
and no empirical reader-facing figure.

Retain desktop and narrow screenshots in the owner audit scope. Stop the
server immediately after QA, confirm no listener remains, then rehash the
source, configuration, HTML, protected read set, and scoped build inventory.
Report every final hash, byte count, viewport measurement, render duration,
command, relevant package and environment identity, and any transient build
files touched. Do not release Preparation 06. Return the complete evidence for
independent harmonizer acceptance.
