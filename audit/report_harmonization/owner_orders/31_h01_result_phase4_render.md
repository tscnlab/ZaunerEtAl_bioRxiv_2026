# REPORT-017 order 31: H01 result target render and visual QA

Date: 2026-08-14  
Owner task: `019fb4ce-d84c-73d1-be48-dc244be5b5f0`  
Coordinator decision: REPORT-017 / CHG-134  
Scope: one normal-profile H01 result render and bounded secure-loopback QA

## Sole active target

The coordinator has released exactly this target:

```text
notebooks/hypotheses/H01.qmd
```

The H01 analysis-preparation companion and every later hypothesis target
remain held. Do not render either one. Stop before execution if any accepted
pin below has drifted:

| Item | SHA-256 |
|---|---|
| H01 result QMD | `5a3f1a03c5c83fba24f59d85d5fb949dd73162d9df9f33fde1a14a17aadda7a9` |
| H01 companion QMD | `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8` |
| H01 reporting manifest | `54b9b062a949c7aa0c4949a068670cd8b65ef65c8d785aeb71ba4167057aa676` |
| H01 Stage 3 manifest | `684046903baae35c8cf624bd3d0b317f0bdd5a31daf548d520a5ca759d7b43d8` |
| H01 focused test | `6e7b4de5a6580d95c81656f953e24a65743c6af5bf940eb1ce3ef628fc041f83` |
| Nature Health profile | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| Existing result HTML, pre-render reference only | `53a216ff0ae82b2e9177671d6330862832c1c5f2a9e79251e0da0acb5671260f` |
| Existing companion HTML, protected | `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38` |

Order 30 is independently accepted under
`audit/report_harmonization/report017_h01_order30_prerender_seal_independent_acceptance.md`
at SHA-256
`a735a9f2feb1d2480484bbf5e8130a84e138737b0e3e13d2efc24bc5aeb6e6e9`.

## Pre-render preservation gate

Before rendering:

1. Reproduce every pin above and verify the 49-row and 95-row H01 manifests
   against current paths, hashes, and byte counts.
2. Reconcile the same 1,215-path protected H01 set used in order 30. Record a
   fresh pre-render inventory. The result and companion QMDs, manifests,
   focused test, scientific tables, source data, models, diagnostics, durable
   figures, provenance, and companion HTML must be protected against change.
3. Record a complete `_build/nathealth` inventory before rendering. Audit
   symlinks and stop if any symlink resolves outside `_build/nathealth`.
4. Parse every H01 R chunk without execution and confirm the page contains no
   model fit, refit, prediction, simulation, bootstrap, reporting-input
   builder, artifact writer, package installation, or scientific-regeneration
   call. The accepted chunks may read stored outputs and construct display
   tables only.
5. Confirm that the exact result source declares 36 `tbl-h01-*` endpoints and
   10 `fig-h01-*` endpoints, including `fig-h01-model-support` and
   `tbl-h01-primary-publication-summary`.

Stop and return any additional stale pin, missing artifact, scientific
discrepancy, unsafe symlink, or unexpected executable call.

## Sole render command

Use the normal project profile, `.Rprofile`, and `renv/activate.R`, with the
already approved narrow access needed for transient writes to the existing
user-owned renv cache. Run exactly once:

```text
quarto render notebooks/hypotheses/H01.qmd --profile nathealth
```

Record Quarto, R, `renv`, `gt`, `knitr`, and `rmarkdown` versions, the exact
command, start and end times, wall time, exit status, warnings, and errors.
Do not bypass the profile, install or update a package, edit `renv.lock`, run a
builder or scientific verifier that refits anything, render another target,
or run a full-project render.

## Post-render source and scientific preservation

After the render and again after browser QA:

1. Rehash the full protected H01 set. All protected source, model, result,
   interval, p-value, diagnostic, sensitivity, table, figure, source-data,
   manifest, test, profile, and companion identities must remain exact.
2. Prove that the H01 companion HTML remains
   `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`.
3. Record the fresh result HTML hash and byte count and a complete build delta.
   Explain every changed build path. Target HTML and ordinary Quarto website
   metadata may refresh; no other reader page or durable scientific artifact
   may change. Restore only an automatically touched but byte-identical mtime
   when needed to preserve the bounded build record.
4. Run the complete normal-profile focused test:

   ```text
   Rscript tests/hypotheses/H01/test_h01_reporting_inputs.R
   ```

   It must pass against the fresh HTML without rebuilding inputs or fitting a
   model.

## Semantic HTML and link checks

The fresh result HTML must contain:

- exactly 36 native `gt` tables, each with one Quarto-owned caption and
  nonempty table head and body;
- exactly 10 labelled figure endpoints with nonempty captions and alt text;
- no raw data frame, tibble, console dump, unresolved reference, duplicate
  identifier, warning element, error element, or leaked internal object;
- the accepted Answer-in-brief hierarchy and primary near-eye,
  complementary chest, matched-sample, model-check, sensitivity,
  interpretation, limitation, registration-record, source-data, and
  technical sections;
- resolved links to the H01 companion, Preparation 04, Preparation 06, every
  exact preregistration-deviation anchor, and all displayed source-data files;
- correct active H01 navigation and no exposed `.qmd`, `file://`, `_build`,
  absolute local, or unresolved target in rendered reader links; and
- country-coded study-site labels, FDR rather than BH in compact display
  contexts, and no reader-facing internal workflow terminology.

Also run the current reader-link, navigation, and country-coded-site
structural contracts without editing their sources.

## Secure loopback visual QA

After all nonvisual checks pass:

1. Preflight `_build/nathealth` again for unsafe symlinks.
2. Start one temporary read-only static HTTP server with document root exactly
   `_build/nathealth`, bound only to `127.0.0.1` on one unused high or
   OS-selected port. Expose no upload or write endpoint.
3. Record the exact command, PID, address, port, root, start time, and exact
   route `/notebooks/hypotheses/H01.html`.
4. Use only the supported in-app Browser at 1440 x 1000 and 708 x 1000. Do
   not use Chrome, Computer Use, CDP, raw browser commands, another browser,
   a public tunnel, or a `file://` workaround.
5. Inspect the full page for hierarchy, typography, wrapping, clipping,
   overlap, page-level horizontal overflow, callouts, navigation, link labels,
   tabsets, captions, footnotes, source notes, and units.
6. Audit all 36 HTML tables with DOM measurements. They must work reasonably
   at desktop size. At 708 pixels, a contained, clearly usable horizontal
   scroller is acceptable for a genuinely wide table, but page-level overflow,
   clipped headers, unreadable type, or hidden scroll affordance is not.
   Retain screenshots of the principal table and every distinct wide-table
   behavior.
7. Give `tbl-h01-primary-publication-summary` focused desktop, narrow, and
   200% zoom review. Confirm readable metric labels, exact sample notation,
   FDR and 95% CI headings, p-value display, caption, footnote/source-note
   hierarchy, and any contained scrolling.
8. Inspect all 10 figures at their final page size and retain representative
   screenshots. Give `fig-h01-model-support` focused desktop, narrow, and 200%
   review. Confirm legible metric and family labels, check/dash redundancy,
   panel distinction, colour contrast, caption, alt-text agreement, and no
   clipping. Inspect the original stored PNGs where page scaling could conceal
   a defect. No figure may be regenerated by this order.
9. Confirm the site-contrast, R-squared, matched-placement, model-check, and
   four diagnostic figures retain readable labels, country codes where sites
   appear, null lines, units, legends, and scientifically correct captions.
10. Record final-size font and container measurements where practical. Use
    7 pt as the minimum legibility threshold for figure text at the narrow
    final size, unless an established page-specific contract is stricter.

The main figure and main table roles and appearance remain provisional until
the author sees this focused render. A visual PASS integrates the page but
does not constitute final principal-output approval.

## Teardown and return

Stop the loopback server immediately after QA. Record termination status and
prove that no listener remains on the port. Rehash the protected source,
profile, target HTML, companion HTML, and complete scoped build inventory.
Browser QA must not change any byte or retained mtime.

Return a durable owner verification record, non-circular manifest, semantic
and link audits, protected and build inventories/comparisons, viewport
metrics, screenshot manifest, retained screenshots, exact render evidence,
and server lifecycle record. Run scoped `git diff --check`.

Stop without editing or rerendering if any display defect, scientific drift,
test failure, missing output, unresolved link, or preservation mismatch
appears. Return the bounded finding for separate disposition. The H01
companion and every later hypothesis render remain held until independent
acceptance and coordinator release.
