# REPORT-017 Preparation 07 figure-text stop independent acceptance

Date: 2026-08-14

Harmonization coordinator task: `019ff52e-48ac-77b3-9a0e-9a87749a3bba`

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Outcome: **ACCEPTED AS A BOUNDED STOP.** The authorized LR-to-TB Mermaid
repair is exact and resolves `RH-VIS-002`. The single repeat render and every
nonvisual gate pass. Preparation 07 is not yet accepted because the three
raster figures reduce important axis, tick, facet-strip, and legend text below
the controlling 7 pt minimum at the required 708-pixel viewport.

This new display-only finding is `RH-VIS-003`. It is not a scientific,
provenance, data, table, link, figure-content, or render-execution
discrepancy. Preparation 07 and every hypothesis render remain held.

## Reproduced identities and preservation

The controlling owner order is
`audit/report_harmonization/owner_orders/28_preparation07_mermaid_tb_repair.md`,
SHA-256
`e77a1ca23438ae126b10346ea8a00347a7068c72608a674f1bbc167149f9c6fa`.
The returned identities reproduce exactly:

- repaired QMD: `37cfe876cf687e874d44d08761cd8f5d18a7c3ad809aa99c9ee449072eb1b9c7`;
- unchanged focused test: `958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163`;
- unchanged profile: `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`;
- repeat-render HTML: `aa531fb4aef06d6ac897dfdbb9f493e83ad3d431d8e87b309cdffb31f0691401`;
- owner repeat-visual stop: `4e6936d6094939d215da1a4341b63d3a4cc2eb7a27ffd558d2fe051e788a1b2f`;
- 59-entry owner manifest: `0c8a6c9039b844eced19c55bdce539b9c94ec0c64bbeb586f6fa6ff8e197f415`.

An independent checksum replay found all 59 manifest entries present with
their exact byte counts and SHA-256 identities. Replacing only `flowchart TB`
with `flowchart LR` reconstructs the accepted pre-repair QMD identity
`ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae`.
The post-repair pre-render, post-render, and post-QA 38-path protected
inventories are byte-identical at
`cbc5b73492af6b0da0266baec59972fb5ffe7b98c6d6fd77a02e591852ff7b79`.
Relative to the accepted pre-repair inventory, the sole source difference is
the authorized Mermaid direction token.

The durable PNG, SVG, paired source-data CSV, fixed selection, historical
manifest, current site-context inputs, focused test, profile, and `renv.lock`
remain exact. The three HTML figure PNGs retain their pre-repair hashes, so no
trace, point, state band, daylight context, label text, or scientific value
changed during the diagram-only repair.

## Independent structural and visual review

The semantic evidence contains 24 checks and zero failures. The DOM contains
exactly seven native `gt` endpoints with complete Quarto-owned captions,
headers, rows, and source notes. All three figure endpoints, captions, alt
text, and source-data links pass. Country-coded sites, the approved
historical/current provenance wording, navigation, reader links, and the
absence of reader-visible warnings or errors all pass.

The screenshots and measurement CSV were independently inspected:

- at 1,440 by 1,000 pixels, the repaired TB Mermaid retains at least 12.00 pt,
  all seven tables retain at least 8.25 pt, and all three figures are readable;
- at 708 by 1,000 pixels, the TB Mermaid retains 9.21 pt with no clipping,
  overlap, or harmful expansion, resolving `RH-VIS-002`;
- the seven HTML tables remain usable at 8.25 pt without page-level overflow;
- the three 9.5-inch raster plots display at 642 CSS pixels, scaling their
  9 pt axis, tick, and legend text to 6.336 pt and their 9.5 pt facet-strip and
  legend-title text to 6.688 pt;
- the 10 pt axis titles retain 7.039 pt and pass;
- the undersized labels are visible but carry necessary panel and scale
  information, so the page fails the explicit final-display threshold.

The narrow evidence is
`audit/preparation_reports/report017_preparation07_mermaid_narrow_figures_1_2.png`,
SHA-256
`0461659696f253e9316bd620498528b0cc115b13e6455fdf784d0a573fcf974f`.
The measurements are
`audit/preparation_reports/report017_preparation07_mermaid_repeat_visual_metrics.csv`,
SHA-256
`7515390ca2d05bc9190ecdaaff7debbce9d97d7bc483befa499a522cbc33ba40`.

## Loopback teardown and bounded repair proposal

The temporary server was rooted exactly at `_build/nathealth`, bound only to
`127.0.0.1:52814`, and used only for Preparation 07. PID 13992 exited normally.
The recorded and independently repeated post-stop checks found no listener.

The smallest source-only display repair is confined to the shared
`make_showcase_plot()` theme in the Preparation 07 QMD:

- `legend.title`: 9.5 pt to 10 pt;
- `legend.text`: 9 pt to 10 pt;
- `strip.text`: 9.5 pt to 10 pt;
- `axis.text`: 9 pt to 10 pt.

At the observed 642-pixel display width, 10 pt maps to 7.039 pt and therefore
meets the threshold. The already passing 10 pt axis titles should remain
unchanged. All plot data, mappings, transformations, breaks, labels, layers,
panel order, colours, dimensions, DPI, captions, alt text, and source-data
links must remain unchanged.

This repair would intentionally regenerate only the three target-owned HTML
figure PNGs during one separately authorized Preparation 07 render. It must
not modify the durable showcase PNG or SVG, source-data CSV, fixed selection,
scientific inputs, results, test, profile, or any other source. Exact
pre/post chunk comparison, accepted numeric-token protection outside the four
theme-size literals, focused R 4.6.1 checks, figure-content identity checks,
and complete desktop plus 708-pixel secure-loopback QA are required. A
separate coordinator authorization is required before editing or rendering.

