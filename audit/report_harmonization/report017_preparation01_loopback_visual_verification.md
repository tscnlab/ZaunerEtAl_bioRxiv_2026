# REPORT-017 Phase 4 loopback visual QA: Preparation 01

Date: 2026-08-13  
Target: `notebooks/preparation/01_import_state_alignment.qmd`  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Review surface: the selected in-app Browser at a bounded HTTP loopback origin

## Disposition

The loopback pilot succeeded as a secure visual-inspection surface. Desktop
layout passes. Narrow-width layout passes for navigation, prose, callouts,
links, and all 14 native gt tables, but the horizontal Mermaid overview is not
readable at its final narrow display size. This is the bounded display finding
`RH-VIS-001`.

Preparation 01 is therefore not yet visually accepted, and Preparation 02
remains unreleased. This is a display-only finding, not a scientific
discrepancy. No source, configuration, rendered output, scientific artifact,
or stored input was edited during this pilot.

## Preflight identities

| Item | Preflight SHA-256 | Post-inspection SHA-256 | Result |
|---|---|---|---|
| `notebooks/preparation/01_import_state_alignment.qmd` | `74f32890d53fb39e38126764737486327cea0826d82ea3ea8e12a9cfbf1fb85a` | `74f32890d53fb39e38126764737486327cea0826d82ea3ea8e12a9cfbf1fb85a` | unchanged |
| `_quarto-nathealth.yml` | `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5` | `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5` | unchanged |
| `_build/nathealth/notebooks/preparation/01_import_state_alignment.html` | `03a18638500185707fa29b47981aeca4093d32f1d5efdcc8c54c5658df9c8465` | `03a18638500185707fa29b47981aeca4093d32f1d5efdcc8c54c5658df9c8465` | unchanged |
| `_build/nathealth/search.json` | `7a3b2e48bcf53bb18da7e91c35cbe8c2fa987f7b18e027ab0e52957e0ede51e3` | `7a3b2e48bcf53bb18da7e91c35cbe8c2fa987f7b18e027ab0e52957e0ede51e3` | unchanged |
| `_build/nathealth/sitemap.xml` | `9aa9d28fa79b8529e65c4a7c7410ad13b61ddf3b6e3caff0ad5db372ebe2bebd` | `9aa9d28fa79b8529e65c4a7c7410ad13b61ddf3b6e3caff0ad5db372ebe2bebd` | unchanged |
| Scoped `_build/nathealth` inventory | `2e7413ce4ddf75b59212e76738fc80119c1f59f92541f829af5d48c4cd7b19d7` | `2e7413ce4ddf75b59212e76738fc80119c1f59f92541f829af5d48c4cd7b19d7` | 827 files and 294,803,640 bytes unchanged |

The preflight found no symlinks under `_build/nathealth`. Therefore no served
path could escape the approved document root through a symlink.

## Bounded server lifecycle

| Field | Recorded value |
|---|---|
| Command | `/usr/bin/python3 -m http.server 43127 --bind 127.0.0.1` |
| PID | `20567` |
| Address | `127.0.0.1` only |
| Port | `43127` |
| Document root | `_build/nathealth` |
| Launch preflight | `2026-08-13T12:14:03+0200` |
| Bound-state timestamp | `2026-08-13T12:14:44+0200`, from the first successful logged `HEAD` request |
| Exact target URL | `http://127.0.0.1:43127/notebooks/preparation/01_import_state_alignment.html` |
| Teardown | `SIGINT` through the owning execution session; process exited with status 0 |
| Listener verification | `lsof -nP -iTCP:43127 -sTCP:LISTEN` returned no rows and status 1 at `2026-08-13T12:22:23+0200` |

The server exposed only static `GET` and `HEAD` responses. It had no upload or
write endpoint, did not bind to a LAN or public address, and did not serve the
project root. Browser navigation remained on the exact target route. Required
site assets were loaded from the same loopback origin.

## Desktop inspection

Viewport: 1440 by 1000 CSS pixels.

The page title, subtitle, 12-section information hierarchy, active sidebar
entry, links, Mermaid overview, callout, references, and next-page navigation
are visible without overlap or clipping. The document and main content have no
horizontal overflow. All 14 gt tables fit the main column, retain nonempty
captions and column labels, and remain readable. The densest participant and
validation tables retain clear row grouping, numeric alignment, and source-path
wrapping.

The initial full-page screenshot was compressed by the browser's full-page
capture compositor even though DOM geometry was correct. It is retained only
as a diagnostic artifact. Ordinary viewport screenshots rendered correctly and
are the controlling visual evidence.

## Narrow inspection

Requested viewport: 708 by 1000 CSS pixels. The browser content area was 693
pixels wide after its scrollbar, and the main content column was 642 pixels
wide.

The responsive header, breadcrumb, title, prose, callout, links, references,
and next-page navigation are readable. There is no document-level horizontal
overflow. Every gt wrapper reports `overflow-x: auto`, and all 14 tables fit the
642-pixel main column without requiring scroll in this render. The source-file,
participant, validation, artifact, and environment tables remain legible. No
text, table, or callout extends beyond the viewport.

## RH-VIS-001: narrow Mermaid readability

The opening Mermaid diagram uses `flowchart LR`. Its view box is approximately
1619 by 222 units, but the narrow page scales it to 642 by 88 CSS pixels. The
nominal 16-pixel node labels are consequently displayed at roughly 6.3 pixels.
The labels are visibly too small for normal reading even though the diagram is
not clipped.

Bounded owner repair:

1. In `notebooks/preparation/01_import_state_alignment.qmd`, change only the
   Mermaid direction at the current source line 608 from `flowchart LR` to
   `flowchart TB`.
2. Preserve every node label, edge, figure identifier, caption, alt text, and
   surrounding scientific prose byte-for-byte.
3. Do not change data, code chunks, tables, values, links, configuration, or
   stored artifacts.
4. Return the pre/post source identity and a one-line reverse-substitution
   check. Do not render until a bounded Preparation 01 rerender is released.

After that source-only repair, Preparation 01 needs one fresh targeted profile
render and the same desktop and narrow loopback check. Preparation 02 remains
held until the revised Preparation 01 page passes.

## Evidence files

- `report017_preparation01_loopback_desktop_top.png`
- `report017_preparation01_loopback_desktop_tables_01.png`
- `report017_preparation01_loopback_desktop_tables_08_09.png`
- `report017_preparation01_loopback_desktop_callout_checks.png`
- `report017_preparation01_loopback_desktop_bottom.png`
- `report017_preparation01_loopback_narrow_top.png`
- `report017_preparation01_loopback_narrow_tables_01_02.png`
- `report017_preparation01_loopback_narrow_tables_08_09.png`
- `report017_preparation01_loopback_narrow_callout_checks.png`
- `report017_preparation01_loopback_narrow_bottom.png`
- `report017_preparation01_loopback_desktop.png`, diagnostic compositor artifact only

The non-circular evidence manifest is
`audit/report_harmonization/report017_preparation01_loopback_visual_manifest.csv`.

