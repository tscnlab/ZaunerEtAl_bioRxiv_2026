# REPORT-017 owner order 22: Preparation 04 targeted render and visual QA

Date: 2026-08-13  
Coordinator decision: REPORT-017 / CHG-134  
Harmonization acceptance prerequisite: Preparation 03 accepted in
`audit/report_harmonization/report017_preparation03_independent_acceptance.md`  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/04_metric_derivation.qmd`

## Serial release

Preparation 04 is the sole active REPORT-017 render owner. Preparation 05 and
every later page remain held. Do not start another page while this order is
open.

## Required preflight identities

Recheck these identities immediately before execution and stop on drift:

- `notebooks/preparation/04_metric_derivation.qmd`:
  `86041585edfb60ba0f3137d268418e7479b369be859b41350d2347bd81e064a6`;
- `_quarto-nathealth.yml`:
  `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`;
- `tests/test_preparation04_report.R`:
  `bab6b85bcd7c445c41681231ce84e1420816a7cc5887883b90e27534ae92080d`;
- `audit/handoffs/preparation_reports_worker_handoff.md`:
  `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640`.

The currently stale target HTML is
`_build/nathealth/notebooks/preparation/04_metric_derivation.html`, SHA-256
`461e4605ff967690b6fc779a2f4381a8f19936bcd6aa48c4c091774b6437664c`.
It is a preflight reference, not an accepted render of the current source.

The preceding 106-path scientific/read-set comparison is
`audit/preparation_reports/preparation04_metric011_handoff_scoped_verification.csv`,
SHA-256
`3afef5fd699c1822f3d02745ea0e5faf36f5b78639716d8ae0b91214c5a7aea4`.
Reconcile that set to the current source and profile identities. The accepted
source-only harmonization and shared H06_daily profile placement are expected
documentation/configuration changes. Stop on any unexplained scientific,
preparation-input, decision, script, or stored-artifact drift. Seal a fresh
current preread inventory and compare it again after rendering and after
loopback QA.

The existing MDER display PNG is
`_build/nathealth/notebooks/preparation/04_metric_derivation_files/figure-html/fig-mder-availability-1.png`,
SHA-256
`423cae8946a50bd6e611ff14708b7ff0543546f3fdc9e9fa030ca917838d75ce`.
Its previous dimensions were 1,382 by 806 pixels. The plot reads the frozen
verification summary and is display-only.

## Sole render command

Run exactly once:

```text
quarto render notebooks/preparation/04_metric_derivation.qmd --profile nathealth
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

Rendering may read accepted stored outputs, perform the page's existing
bounded identity/schema checks, and format display summaries. It must not run
a preparation builder or scientific verifier, alter a metric, reconstruct
MDER, L10, or diary-period support, fit a model, predict, bootstrap, simulate,
run Shapley analysis, or overwrite an accepted analytical artifact.

Preserve every estimate, count, rule, unit, table value, sample definition,
source-data file, and scientific qualification. In particular, retain the
visible PREP-003/FIND-044 qualification that independent reconstruction is
still incomplete only for the current diary-period support manifest. It does
not apply to current MDER and is not evidence that the diary-period data or a
downstream result is wrong. Do not resolve or weaken that qualification
editorially.

## Focused post-render checks

Run the existing focused Preparation 04 test under R 4.6.1 against the new
target HTML. Also perform scoped R-source parse checks, link/anchor checks,
country-coded-site checks, and `git diff --check` for the authorized scope.
If the test contains a stale assertion, stop and return the exact assertion;
do not edit the test without separate authorization.

Verify that the HTML contains:

- the accepted title, purpose, preparation-chain position, information
  hierarchy, short glossary, and render-boundary callout;
- all 13 current `tbl-*` endpoints as native `gt` tables, each with exactly
  one nonempty Quarto-owned caption and intact source notes;
- the current MDER availability figure with its caption, substantive alt
  text, and source-data link;
- the complete current METRIC-010 and METRIC-011 wording and the visible
  PREP-003/FIND-044 qualification;
- dynamic and resolved internal links, including the Preparation 06 link and
  the PREP-003 decision link; and
- the active Preparation 04 navigation entry with the current profile order,
  including H06_daily in its already accepted later hypothesis position.

Reject rendered R errors or warnings, raw tibble/console output, duplicate or
missing identifiers, empty link labels, hard-coded internal `.html` or
absolute-local source links, unresolved current-page fragments, or links into
`_build`.

## Visual QA and table policy

After all nonvisual checks pass, serve the existing build through one
temporary static server rooted exactly at `_build/nathealth`, bound only to
`127.0.0.1` on an unused high or ephemeral port. Preflight the document root
for symlinks and stop if any resolves outside that root. Record the exact
server command, operating-system PID, address, port, document root, start
time, exact Preparation 04 URL, stop time, process termination, and listener
closure. Use only the ordinary in-app Browser. Do not use `file://`, Chrome,
Computer Use, CDP, a LAN bind, or a public tunnel.

Inspect at a typical 1440 by 1000 desktop/laptop viewport and at a requested
708 by 1000 narrow viewport:

- typography, headings, callouts, wrapping, link labels, navigation, and
  page-level clipping or overflow;
- the overview Mermaid diagram, including label legibility, clipping,
  overlap, and harmful compression or expansion;
- all native HTML tables, their captions, headers, rows, notes, and adjacent
  content; and
- the MDER figure, caption, alt text, axes, legend, counts, and source-data
  link.

For native HTML tables, the controlling readability check is the typical
desktop/laptop viewport. At 708 pixels, require page integrity and a contained,
usable horizontal-scroll affordance. A dense table does not have to fit
without scrolling. If this or another page includes an exported table, its
PNG at intended final size is the controlling visual artifact. Preparation 04
currently has native HTML tables, not an exported table PNG. Its MDER PNG is a
figure and must still pass its existing intended-final-size figure check.

Do not pre-emptively change the current left-to-right Mermaid declaration. If
the rendered diagram is unreadable or clipped at either viewport, stop and
return the exact measured defect. No diagram edit is authorized here.

Retain desktop and narrow screenshots in the owner audit scope. Stop the
server immediately after QA, confirm no listener remains, then rehash the
source, configuration, HTML, figure, protected read set, and scoped build
inventory. Report every final hash, byte count, viewport measurement, render
duration, command, package/environment identity relevant to the render, and
any transient build files touched. Do not release Preparation 05. Return the
complete evidence for independent harmonizer acceptance.
