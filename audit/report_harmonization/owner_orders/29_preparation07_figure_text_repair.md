# REPORT-017 owner order 29: Preparation 07 figure-text repair and repeat render

Date: 2026-08-14

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Target source: `notebooks/preparation/07_example_days.qmd`

Target output: `_build/nathealth/notebooks/preparation/07_example_days.html`

## Authority and starting pins

The coordinator approved `RH-VIS-003` as a bounded display-only source
repair. The accepted starting identities are:

| Path or record | SHA-256 |
|---|---|
| repaired Preparation 07 QMD | `37cfe876cf687e874d44d08761cd8f5d18a7c3ad809aa99c9ee449072eb1b9c7` |
| focused test | `958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163` |
| Nature Health profile | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| stopped HTML | `aa531fb4aef06d6ac897dfdbb9f493e83ad3d431d8e87b309cdffb31f0691401` |
| owner repeat-visual stop | `4e6936d6094939d215da1a4341b63d3a4cc2eb7a27ffd558d2fe051e788a1b2f` |
| owner 59-entry manifest | `0c8a6c9039b844eced19c55bdce539b9c94ec0c64bbeb586f6fa6ff8e197f415` |
| independent figure-text stop acceptance | `759496e47503a8b70e7b015cca0f572047d7efacb35aa689e3d70f0c0ca269d9` |
| independent 16-entry acceptance manifest | `2d4f21b2e7cfc2266d96ece77baf021f503fea5918caa7d8eb9560893436c80d` |

Both manifests have been independently verified in full. The repaired TB
Mermaid now passes at desktop and 708 pixels. The sole remaining defect is
the shared `make_showcase_plot()` theme: 9 pt text displays at 6.336 pt and
9.5 pt text at 6.688 pt in the measured 642-pixel narrow figure width. The
existing 10 pt axis-title text displays at 7.039 pt and passes.

## Exact four-literal repair

After rechecking every starting pin, change only these four size literals
inside `make_showcase_plot()`:

```diff
-      legend.title = ggplot2::element_text(size = 9.5),
-      legend.text = ggplot2::element_text(size = 9),
+      legend.title = ggplot2::element_text(size = 10),
+      legend.text = ggplot2::element_text(size = 10),
@@
-        size = 9.5,
+        size = 10,
@@
-      axis.text = ggplot2::element_text(size = 9),
+      axis.text = ggplot2::element_text(size = 10),
```

Leave `axis.title = ggplot2::element_text(size = 10)` unchanged. Preserve
every other numeric token and all plot data, mappings, transformations,
breaks, labels, layers, site and panel order, colours, dimensions, DPI,
captions, alt text, source-data links, table endpoints, Mermaid content,
surrounding prose, test, profile, and scientific identity.

Before rendering:

1. prove that reversing only these four size substitutions reconstructs QMD
   SHA-256
   `37cfe876cf687e874d44d08761cd8f5d18a7c3ad809aa99c9ee449072eb1b9c7`;
2. compare numeric-token sequences before and after while normalizing only the
   four authorized size literals, and prove every other numeric token exact;
3. prove the exact source diff is confined to those four literals;
4. run `git diff --check`; and
5. rerun the source-only focused test under R 4.6.1 without evaluating QMD
   chunks.

Stop on any additional difference.

## Single render and preservation boundary

Recheck the repaired source, unchanged focused test and profile, protected
paths, frozen source CSV, durable PNG/SVG, and build-root symlink preflight.
Run exactly one command with the established narrow access to the existing
user-owned renv cache:

```text
quarto render notebooks/preparation/07_example_days.qmd --profile nathealth
```

Use normal `.Rprofile` and `renv/activate.R`. Do not install or update a
package, edit `renv.lock`, bypass the project profile, run another target or a
full render, execute the strict showcase verifier or selection builder, fit a
model, predict, resample, simulate, or regenerate a durable scientific
artifact.

The three target-owned HTML figure PNGs may refresh only through this target
render from the same frozen paired source CSV. Their traces, points, panel
order, scale, transformations, state bands, daylight context, labels,
colours, and scientific values must be unchanged. Only the four authorized
theme text sizes may differ visually. The durable showcase PNG and SVG and
paired source CSV must remain byte-identical.

## Required verification and visual QA

Repeat the complete Preparation 07 acceptance suite:

- R 4.6.1 focused source/HTML test;
- protected-input and exact target-owned build-delta checks;
- 24 semantic checks;
- exactly seven native `gt` tables with Quarto-owned captions, headers, rows,
  source notes, and reasonable desktop/narrow usability;
- exactly three figure endpoints with captions, substantive alt text, paired
  source data, and figure-content preservation;
- the approved provenance wording and distinct historical/current hashes;
- country-coded site names, active navigation, reader links, and absence of
  warnings, errors, unresolved references, or internal workflow language;
- durable PNG/SVG/source-data byte invariance; and
- repaired TB Mermaid preservation.

Start one temporary read-only HTTP server rooted exactly at
`_build/nathealth`, bound only to `127.0.0.1` on an unused high or OS-selected
port. Navigate only to the exact Preparation 07 page in the supported in-app
Browser. Inspect at 1,440 by 1,000 pixels and 708 by 1,000 pixels.

At both widths inspect typography, page wrapping, callouts, navigation,
clipping, overflow, all seven tables, the TB diagram, and all three figures.
At 708 pixels specifically verify that:

- the 10 pt axis, tick, legend, strip, and legend-title text reaches at least
  7 pt at the actual display width;
- every necessary plot label, tick, legend item, panel heading, trace, point,
  state band, daylight region, caption, and unit is readable;
- no new overlap, clipping, crowding, harmful height expansion, or page-level
  overflow appears; and
- the TB Mermaid remains at least 7 pt without clipping or overlap.

Stop on any remaining or new defect. Do not infer or make another repair.
Stop the server immediately after QA and prove no listener remains.

## Return evidence

Return the pre/post QMD identities, exact four-literal and reverse-substitution
proof, numeric-token comparison, target HTML identity, command/runtime/version
evidence, protected and build inventories, focused/semantic/native-table/
figure/link results, desktop and narrow screenshots and measurements, server
lifecycle and teardown, and a non-circular manifest.

No hypothesis render is released. Every hypothesis target remains held until
Preparation 07 receives independent final acceptance and the coordinator
separately releases the next serial target.

