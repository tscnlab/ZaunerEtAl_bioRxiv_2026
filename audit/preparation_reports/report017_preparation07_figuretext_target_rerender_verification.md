# REPORT-017 Preparation 07 figure-text target rerender verification

Date: 2026-08-14

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Target: `_build/nathealth/notebooks/preparation/07_example_days.html`

Outcome: **PASS.** The single authorized Preparation 07 target render,
focused source/HTML test, protected-input gate, semantic audit, native-table
audit, and desktop and narrow visual QA all pass. The repaired 10 pt figure
text remains at or above 7 pt at its final 708-pixel display width. The TB
Mermaid remains above 7 pt. The loopback server was fully stopped and no
listener remains.

No source, test, profile, data, durable figure, source-data, manifest,
decision, ledger, lockfile, manuscript, or hypothesis file was edited during
this order. No fixed-seed selection, strict showcase verifier, model,
prediction, simulation, bootstrap, Shapley calculation, or other scientific
computation ran. Every hypothesis render remains held.

## Authority and preflight

The controlling order is
`audit/report_harmonization/owner_orders/29b_preparation07_figure_text_target_rerender.md`,
SHA-256
`48124c9ce1c29a7d0c960a5e278eb7902c5362f50bd9aa415cd19de2a6e7e537`.
All immediate pins matched before execution:

| Item | SHA-256 |
|---|---|
| Preparation 07 QMD | `e5b89c62b03af2e7989f76cb9578608b92420978393a7c857fd5edcc335dbcb1` |
| Focused test | `9d3a19b7d30ee0a6d5b0b643da628e25e970b232cf2f812fae1efdb4fe8fff58` |
| Nature Health profile | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| Stopped HTML | `aa531fb4aef06d6ac897dfdbb9f493e83ad3d431d8e87b309cdffb31f0691401` |
| Independent source/test acceptance | `242210e5a723b127a1013596c16d88747c4248673e7cb8a142fcf017c9e5a3b3` |
| Independent acceptance manifest | `b100420011df99c1e67593c3c78af87c2ef2e54b9cef361dba6bccc38cd656bd` |

The independent manifest replayed 16/16 entries exactly and is non-circular.
The accepted 38-path protected inventory matched 38/38 paths. The current
build inventory matched all 817 earlier paths by bytes, SHA-256, and mtime.
The build root contained no symbolic links.

Static inspection found exactly 11 bounded R chunks and no executable
builder, strict verifier, model, prediction, resampling, simulation, network,
or writer call. The three figure chunks read the frozen paired source-data
CSV and call the accepted display function only.

## Environment and single render

Normal project startup reported:

- Quarto 1.9.37;
- R 4.6.1;
- the repository root as the active renv project;
- the first library at
  `renv/library/macos/R-4.6/aarch64-apple-darwin23`;
- renv 1.2.3, knitr 1.51, rmarkdown 2.31, gt 1.3.0, xml2 1.6.0,
  digest 0.6.39, dplyr 1.2.1, readr 2.2.0, scales 1.4.0, tibble 3.3.1,
  tidyr 1.3.2, and ggplot2 4.0.3.

Exactly one Quarto command ran:

```text
quarto render notebooks/preparation/07_example_days.qmd --profile nathealth
```

It used normal `.Rprofile` and `renv/activate.R` startup with the approved
narrow access to the existing user-owned renv cache. The immediate pin probe
was recorded at `2026-08-14T13:29:57+02:00`. All 25 knitr stages completed,
the command exited 0, and the measured command time was approximately 36.98
seconds. The output mtime is `2026-08-14T13:30:53+02:00`. The only extra
output was renv's established informational dependency-discovery note. No
package was installed or updated.

The final HTML is 297,095 bytes with SHA-256
`6ed53f8504f1de4db1b96e2cb1ea7babf06d0828e6ea43501eac93104c7b27b7`.

## Focused and semantic checks

The complete source/HTML command ran under R 4.6.1:

```text
Rscript tests/test_preparation07_report.R \
  _build/nathealth/notebooks/preparation/07_example_days.html
```

It exited 0 after 17.53 seconds with the bounded-render, fixed-input,
gt-table, accessible-figure, site-display, and provenance PASS message.

The final semantic audit passed 24/24 checks. It verifies:

- exactly seven native `gt` table endpoints, each with one nonempty
  Quarto-owned caption, nonempty headers and rows, and the intended source
  note;
- exactly three figure endpoints with existing images, substantive alt text,
  nonempty captions, and the paired source-data link;
- the title and heading hierarchy, render-boundary callout, approved
  historical/current site-context explanation, and distinct file identities;
- all nine submitted country-coded site names in order;
- nonempty reader links, active Preparation 07 navigation, H06_daily
  navigation, and resolved internal links and fragments, with only the known
  shared unreleased supplementary-navigation endpoint isolated;
- no hard-coded QMD, `file://`, `_build`, or absolute local reader link;
- no raw tibble, rendered error, warning, unresolved reference, terminal
  table renderer, or visible internal workflow code.

The semantic, native-table, and link records have SHA-256 values:

- `5cd0ce50defa82768af8de6da9f58fc5b23e3b8cab24136e6caec4e7f834238c`;
- `4a00379bfb704c048fd5aa512d837a4f7e576af5aa8d50b57a44305965087a50`;
  and
- `1701fb57752200117ae9f2a9f28287738a762cbc3342c4e0058efb3859e87adf`.

The in-app Browser console contained zero warning or error entries.

## Figures and frozen source-data preservation

The three HTML figure PNGs were refreshed by the target render from the same
frozen `artifacts/11_source_data/prepared_day_showcase.csv`. The QMD change
was limited to four accepted theme text-size literals. Plot data, mappings,
transformations, layers, panel and site order, scales, labels, colours,
dimensions, captions, alt text, and source-data path remain unchanged.

| HTML figure | Pixels | Bytes | SHA-256 |
|---|---:|---:|---|
| `fig-example-days-1-1.png` | 2850 x 1260 | 430,601 | `cf90ecd8ca094b2a21cb931ffa88c81110ab61f7783d55bb5b126b708d796187` |
| `fig-example-days-2-1.png` | 2850 x 1110 | 354,386 | `daf8d9761bf7d96fbe65b441500390053205fb219059fbe28e74b9945cde7874` |
| `fig-example-days-3-1.png` | 2850 x 1110 | 348,918 | `51d5352df7388d9177f201a19feba23341d1c4fb2146f86e15a052530efcea4a` |

The durable showcase PNG, SVG, and paired source-data CSV remain
byte-identical at:

- `a35e8189bdbdb450411bfe7f71d52964c17e45a7a26fdb44e82776d201b00ff3`;
- `5ad003220cb1d5a1d2b223af206f4a1e608b4e1fa0e695d656989dde62b0ea4a`;
  and
- `15e12011effbdf8fdbf7835be235b7b50406838278d411df023e924e81bea1e4`.

The visual comparison confirms the same traces, points, panels, state bands,
daylight regions, dashed contextual steps, labels, colours, and submitted
site order. No data pattern or scientific value was adjudicated or
recomputed.

## Protected inputs and exact build delta

The pre-render, post-render, and post-QA protected inventories are
byte-identical at SHA-256
`e4db74bb377e76115637c285971ae4449e5e2517341ad9b6cccafb35e26485fd`.
All 38 protected paths remained exact at both gates.

The build root retained 817 regular files and no symbolic links. Its
pre-render inventory is
`9ab3459065c543e0531d26e00d5bf5b21c0d9aea46191c4e1573a92542aff641`.
The post-render and post-QA inventories are byte- and mtime-identical at
`f9aed45fe5e11df781ff1ac4f47dd1938f95bc8f58b13ed8a5dcc9753238f059`.

The six-row render delta, SHA-256
`dc11671776490ee3496c1e43991da252a02c47cfb6ee3f5658d7e52bdad15e7f`,
contains only:

- content changes to the target HTML, its three target-owned figure PNGs,
  and `sitemap.xml`;
- an mtime-only refresh of
  `site_libs/bootstrap/bootstrap-a2a938b4dd5711f7a799c87bd16ba44c.min.css`;
- no added or removed path.

`search.json` remained byte- and mtime-identical at SHA-256
`e88ef9a266bf6f9ec8eb3627b8f82caec69e7c6b9742529d0a23a04931317bb0`.
Browser QA changed no build byte or mtime. The 817-row post-QA comparison has
SHA-256
`b47ca1aae973b5f2cb00ab3934f1a532843910221d7380236865efb7dc41dc23`.

## Desktop and narrow visual QA

One in-app Browser tab inspected only the exact Preparation 07 loopback URL.
The final-size measurement record has 50/50 PASS rows and SHA-256
`71598b18b38fc0d7b30646188979c1642603bbd603be9a2a165321e5ce3ddb61`.

At 1,440 x 1,000 pixels:

- the document client and scroll widths were both 1,425 pixels;
- the main content width was 1,148.5 pixels;
- all four 10 pt figure-text roles displayed at 12.593 pt in all three
  figures;
- the TB Mermaid displayed at 836.40 x 605.99 pixels and its minimum
  effective label size was 12.000 pt;
- all eight Mermaid labels were present, with zero clipped labels and zero
  overlaps;
- all seven native tables fit their 1,148.5-pixel containers and retained a
  minimum 8.25 pt cell font.

At 708 x 1,000 pixels:

- the document client and scroll widths were both 693 pixels, so there was no
  page-level horizontal overflow;
- the main content and all three figures displayed at 642 pixels wide;
- legend title, legend text, facet-strip text, and axis text displayed at
  7.039 pt in every figure;
- the TB Mermaid displayed at 642 x 465.15 pixels and its minimum effective
  label size was 9.211 pt;
- all eight Mermaid labels were present, with zero clipping and zero overlap;
- all seven tables remained contained at 642 pixels, retained a minimum 8.25
  pt cell font, and kept `overflow-x: auto` available. No table required
  scrolling in the measured state.

The raster-text calculation is `10 pt x displayed width / (9.5 in x 96 CSS
pixels per inch)`. Mermaid text uses the displayed SVG width relative to its
view box. Screenshot review confirmed readable labels, ticks, legends, panel
headings, captions, units, traces, points, state bands, and daylight regions.
No clipping, overlap, compressed panel, broken unit, awkward figure label,
indistinguishable mark, harmful Mermaid expansion, or page-level overflow was
found. Headings, callouts, navigation, breadcrumbs, and links remained usable.

Thirteen retained browser screenshots are indexed in
`audit/preparation_reports/report017_preparation07_figuretext_screenshot_manifest.csv`,
SHA-256
`7f9b44a918dfa88e26f0e4228c4db0b33fb6d3ee002269b8810acc8e05d72342`.
The desktop and narrow raw measurement JSON files have SHA-256 values
`31f8ce66424d2569da4180d0790f99491be43a6ad2b12332663134a5a9c96459`
and
`fd8c831f92883a226c005f83ec89b914f84e5d935c93ed752be62a9234619b41`.

## Loopback lifecycle and teardown

The sole temporary server command was:

```text
python3 -u -m http.server 0 --bind 127.0.0.1 \
  --directory _build/nathealth
```

- document root:
  `/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/_build/nathealth`;
- address and port: `127.0.0.1:55750`;
- PID: `20018`;
- process start: `2026-08-14T13:33:32+02:00`;
- listener confirmation: `2026-08-14T13:33:43+02:00`;
- exact URL:
  `http://127.0.0.1:55750/notebooks/preparation/07_example_days.html`;
- first page GET: `2026-08-14T13:33:55+02:00`, HTTP 200;
- browser finalization: `2026-08-14T13:38:14.054+02:00`;
- stop confirmation: `2026-08-14T13:38:24+02:00`;
- server exit status: 0.

All required page and asset requests returned HTTP 200. The optional favicon
returned 404. After teardown,
`lsof -nP -iTCP:55750 -sTCP:LISTEN` exited 1 with empty output, the expected
no-match result proving no listener remained. The 16-row lifecycle record has
SHA-256
`5995cba59ed61b3e0b57e834b449c77504931f14a8993115975eb13d7e9d58f7`.

## Disposition

Order 29b is complete and passes the owner verification contract. Preparation
07 is preserved for independent final acceptance. This record does not
release a hypothesis render.
