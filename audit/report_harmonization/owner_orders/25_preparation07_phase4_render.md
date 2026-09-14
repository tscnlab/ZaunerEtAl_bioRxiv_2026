# REPORT-017 owner order 25: Preparation 07 targeted render and visual QA

Date: 2026-08-13  
Coordinator decision: REPORT-017 / CHG-134  
Harmonization acceptance prerequisite: Preparation 06 accepted in
`audit/report_harmonization/report017_preparation06_independent_acceptance.md`  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/07_example_days.qmd`

## Serial release

Preparation 07 is the sole active REPORT-017 render owner. Every hypothesis
result and companion render, including H06_daily, remains held. Do not start
another page while this order is open.

## Required preflight identities

Recheck these identities immediately before execution and stop on drift:

- `notebooks/preparation/07_example_days.qmd`:
  `2293d2520dabaacc7394a39c00b5ac62911da1d34fb489ecf4bf232c55a2998f`;
- `_quarto-nathealth.yml`:
  `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`;
- `tests/test_preparation07_report.R`:
  `be2505e1960ffb6ebbe1bdbc675fdd2da37e036a1eeb797e5c709f32f191fd2f`;
- `audit/handoffs/preparation_reports_worker_handoff.md`:
  `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640`.

The currently stale target HTML is
`_build/nathealth/notebooks/preparation/07_example_days.html`, SHA-256
`e37609f5adab0a5b57ce96d0229e4bac07dae3c713fe28aca3da68066ba12bdc`.
It is a preflight reference, not an accepted render of the current source.

The older page-specific handoff comparison is
`audit/preparation_reports/preparation07_final_handoff_scoped_verification.csv`,
SHA-256
`1d1dd1d863d8c051e8be4041e3d4471f96f50eab131ce308700d48777f1cf9c7`.
The older preread set is
`audit/preparation_reports/preparation07_prerender_scoped_readset.csv`,
SHA-256
`d969d3b04d817ab6de822bef34e38c09eb2f606df172e7796a1996858a9b2da7`.

Reconcile the 15 Preparation 07 paths in the older comparison to the current
state. Exactly three accepted later identities differ from its original
baseline:

1. The accepted reader source is the current QMD identity listed above.
2. `artifacts/06_model_data/context/site_solar_context.rds` is now
   `39ffe488de86f5d7cdc56d65c582c9de31f9054f8565936b4ec74e01491f26d0`.
   This is the accepted Preparation 06 METRIC-011 site-context input recorded
   by the current site-context manifest and REPORT-017 gates.
3. `scripts/pipeline/prepared_day_showcase.R` is now
   `d77ca354f9bc927c293a5160194c481343f8e14cfc014a9e6985f70694db1ba0`.
   Its sole change from older identity
   `820fa16531f505e4561c133ccea19cfb8924218fde82d7548c0af281b538d3ee`
   is the approved display-scale specification
   `LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)`. In-memory reverse
   substitution has already reproduced the older hash exactly under
   `audit/decisions/reader_facing_symlog_scale.md`, SHA-256
   `8ddfd61216c57ed9f5a0ec59420df3da71edd95c5c77eb1ebe62f3d986a06d58`.

The other 12 paths must retain the exact identities in the older comparison.
Seal a fresh current preread inventory and compare it again after rendering
and after loopback QA. Stop on any unexplained drift.

The stored display artifacts are:

- `artifacts/12_manifests/prepared_day_showcase_artifacts.csv`:
  `c5ca66b2a6ec4fabbe57d08135db7f365bcd123365caab6c987bcb2b62f7a322`;
- `artifacts/10_figures/prepared_day_showcase.png`:
  `a35e8189bdbdb450411bfe7f71d52964c17e45a7a26fdb44e82776d201b00ff3`;
- `artifacts/10_figures/prepared_day_showcase.svg`:
  `5ad003220cb1d5a1d2b223af206f4a1e608b4e1fa0e695d656989dde62b0ea4a`;
- `artifacts/11_source_data/prepared_day_showcase.csv`:
  `15e12011effbdf8fdbf7835be235b7b50406838278d411df023e924e81bea1e4`.

The stale HTML currently has these three generated display figures:

- `fig-example-days-1-1.png`:
  `ad6ee88b1df7a0b2f17d513825d74887cc009b74317ae23d43bb16a14c2d9ad8`;
- `fig-example-days-2-1.png`:
  `837d65b0f35f490e2c76ac4e170ebd633a349c4aff821fe82eae2be7ebb6b53d`;
- `fig-example-days-3-1.png`:
  `fd6f1cb73718674fdb6544e89bb684be0723bb33378709c399c4b161e1ec5629`.

Their current generated dimensions are 2,850 by 1,260, 2,850 by 1,110, and
2,850 by 1,110 pixels. They are displays drawn from the frozen source-data
CSV. The durable 3-by-3 PNG is 3,600 by 2,700 pixels. Rendering must not run
the fixed-seed selection or rewrite a durable display artifact.

## Sole render command

Run exactly once:

```text
quarto render notebooks/preparation/07_example_days.qmd --profile nathealth
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

Before rendering, statically inspect all 11 R chunks. They may read the
accepted coverage, solar-context, site-metadata, stored selection, source-data,
and manifest files; perform bounded identity and schema checks; calculate the
existing lightweight descriptive summaries; and format the current tables and
three display figures. They must not source or call either the showcase builder
or scientific verifier, run a fixed-seed selection, write a file, fit a model,
predict, estimate autocorrelation, bootstrap, simulate, run Shapley analysis,
or regenerate a durable artifact.

Preserve every stored selection, seed, count, value, unit, site-day choice,
coverage rule, sample distinction, source-data value, display break, site
name, site order, and colour. Preserve the explicit statement that Preparation
07 is a display-only inspection and that none of its selection, source data,
or figures enters H01-H11.

## Focused post-render checks

Run the existing focused Preparation 07 test under R 4.6.1 against the new
target HTML. Also perform scoped R-source parse checks, dynamic-link and anchor
checks, country-coded-site checks, navigation checks, and `git diff --check`
for the authorized scope. If the test contains a stale assertion, stop and
return the exact assertion. Do not edit the test without separate
authorization.

Verify that the HTML contains:

- the accepted title, purpose, preparation-chain position, information
  hierarchy, render-boundary callout, and explicit no-hypothesis-handoff
  statement;
- all seven current `tbl-*` endpoints as native `gt` tables, each with exactly
  one nonempty Quarto-owned caption and its intended notes, labels, rows, and
  ordering;
- `fig-example-days-1`, `fig-example-days-2`, and `fig-example-days-3`, each
  with an informative caption, substantive alt text, final-width sizing, and
  data drawn only from the frozen source-data CSV;
- all nine country-coded sites in the accepted order and registered colours;
- the fixed seed 20260730, stored day selection, 12,960 one-minute rows,
  1,440 local-clock minutes per site-day, and the accepted 50% and 80%
  coverage rules;
- the dynamic source-data link and every other intended reader link; and
- the active Preparation 07 navigation entry with the current profile order,
  including H06_daily in its accepted later hypothesis position.

Reject rendered R errors or warnings, raw tibble or console output, duplicate
or missing identifiers, empty link labels, hard-coded internal `.html` or
absolute-local source links, unresolved current-page fragments, links into
`_build`, or an unexpected change to any accepted input or durable artifact.

## Visual QA and table policy

After all nonvisual checks pass, serve the existing build through one
temporary static server rooted exactly at `_build/nathealth`, bound only to
`127.0.0.1` on an unused high or ephemeral port. Preflight the document root
for symlinks and stop if any resolves outside that root. Record the exact
server command, operating-system PID, address, port, document root, start time,
exact Preparation 07 URL, stop time, process termination, and listener closure.
Use only the ordinary in-app Browser. Do not use `file://`, Chrome, Computer
Use, CDP, a LAN bind, or a public tunnel.

Inspect at a typical 1,440 by 1,000 desktop/laptop viewport and at a requested
708 by 1,000 narrow viewport:

- typography, headings, callouts, wrapping, link labels, navigation, and
  page-level clipping or overflow;
- the existing left-to-right overview Mermaid diagram, including measured
  label size, clipping, overlap, and harmful compression or expansion;
- all seven native HTML tables, their captions, headers, rows, notes, long
  paths and hashes, and adjacent content; and
- all three generated example-day figures at their intended display size,
  including site labels and colours, time and melEDI axes, diary/non-wear
  annotations, captions, alt text, balance, clipping, overlap, and the paired
  source-data link.

Also inspect the durable PNG at its intended export size and use the SVG as an
identity-preserved companion. The durable PNG is the controlling visual check
for the exported 3-by-3 figure. Do not infer export quality only from the HTML
figures.

Mermaid labels must remain legible and measure at least 7 pt at both requested
viewports. Do not pre-emptively change the current `flowchart LR` declaration.
If the rendered diagram fails the threshold or has clipping or overlap, stop
and return the exact measured defect. No diagram edit is authorized here.

For native HTML tables, the controlling readability check is the typical
desktop/laptop viewport. At 708 pixels, require page integrity and a contained,
usable horizontal-scroll affordance. A dense table does not have to fit without
scrolling. If an exported table appears unexpectedly, stop. Its PNG at intended
final size would be the controlling visual artifact.

Retain desktop and narrow screenshots in the owner audit scope. Stop the
server immediately after QA, confirm no listener remains, then rehash the
source, configuration, HTML, generated figures, durable PNG/SVG, source data,
current 15-path read set, and scoped build inventory. Report every final hash,
byte count, viewport measurement, render duration, command, relevant package
and environment identity, and any transient build files touched.

Do not release a hypothesis render. Return the complete evidence for
independent harmonizer acceptance. DOC-001 remains open and all principal and
supplemental output roles remain provisional.
