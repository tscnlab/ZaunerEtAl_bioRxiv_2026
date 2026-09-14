# REPORT-017 Phase 4 verification: Preparation 01 order 02b

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/01_import_state_alignment.qmd`  
Branch: `rewrite/NH`

## Disposition

Preparation 01 is accepted for source, targeted render, protected-input
preservation, semantic HTML, native gt integration, links and navigation, and
desktop and narrow visual QA. `RH-VIS-001` is resolved. Preparation 02 may be
released as the next and only active serial owner.

The sole source repair was the previously approved Mermaid direction change
from `flowchart LR` to `flowchart TB`. It changed no scientific content, code
chunk, table, value, link, identifier, caption, alt text, source data, or stored
artifact.

## Source and profile gate

| Item | Immediate pre-render SHA-256 | Final SHA-256 | Result |
|---|---|---|---|
| `notebooks/preparation/01_import_state_alignment.qmd` | `93869fb2fffb17474ada3126f48ad8ce788079b151840e4b362f6a7974977872` | `93869fb2fffb17474ada3126f48ad8ce788079b151840e4b362f6a7974977872` | unchanged |
| `_quarto-nathealth.yml` | `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5` | `b9c10a09d525d7de37bb08f5160e37409e382df6be0af58698a8219783b84ed5` | unchanged |

Replacing only `flowchart TB` with `flowchart LR` in memory reproduces the
accepted order-02a source hash
`74f32890d53fb39e38126764737486327cea0826d82ea3ea8e12a9cfbf1fb85a`.
`git diff --check` passes.

The first protected read-set check used the order-02a baseline and returned one
expected mismatch, the authorized source identity, while all 148 other paths
were unchanged. A temporary order-02b baseline changed only that source hash.
Its SHA-256 was
`74e5aaa73ade27c5eeded167f077f2d51f877c5410d4e212bfb74f0d6447552e`.
Both the immediate post-render and final post-loopback R 4.6.1 checks reported
149 unchanged paths and zero mismatches.

## Targeted render

The only Quarto command was:

```text
quarto render notebooks/preparation/01_import_state_alignment.qmd --profile nathealth
```

It ran under Quarto 1.9.37 and R 4.6.1 with the normal project profile and
existing renv cache access. It processed the expected 33 steps, exited with
status 0, and took approximately 34 seconds. The dependency-discovery note was
informational. No package was installed or updated, and no builder, production
verifier, model, prediction, simulation, bootstrap, or other scientific
recomputation ran.

| Output | Pre-render SHA-256 | Post-render SHA-256 | Bytes |
|---|---|---|---:|
| `_build/nathealth/notebooks/preparation/01_import_state_alignment.html` | `03a18638500185707fa29b47981aeca4093d32f1d5efdcc8c54c5658df9c8465` | `6a312ee826c0a4944bf2d9e5c3d0d3ea09521a6e1ae26c84ac30f0493973907e` | 371,295 |
| `_build/nathealth/search.json` | `7a3b2e48bcf53bb18da7e91c35cbe8c2fa987f7b18e027ab0e52957e0ede51e3` | `7374fb9fc7e20ac83f0a70d32dfec3d3f8eb592cf7f4af19a5dc880ec9f33ddc` | 1,535,924 |
| `_build/nathealth/sitemap.xml` | `9aa9d28fa79b8529e65c4a7c7410ad13b61ddf3b6e3caff0ad5db372ebe2bebd` | `1126d501ee279da25eed02854986453631888888a2715dc1dd14d8fdd248e8b5` | 5,219 |

The build inventory remained 827 files and 294,803,640 bytes. Its aggregate
content identity changed from
`2e7413ce4ddf75b59212e76738fc80119c1f59f92541f829af5d48c4cd7b19d7`
to
`d87daa3fbd532fe94368f78d836adeb6a7082b081e91e4040d35b200cd9ad299`.
Exactly the target HTML, search index, and sitemap changed content. Quarto
transiently touched the byte-identical Bootstrap CSS. Its accepted mtime
`1786606094`, size 498,438 bytes, and SHA-256
`b3d78f1077461003efc2b21acc3f81ee6ba80468fe09df310b4c339e2e19133c`
were restored.

## Focused and semantic checks

`/usr/local/bin/Rscript tests/test_preparation01_report.R
_build/nathealth/notebooks/preparation/01_import_state_alignment.html` exited
with status 0 under R 4.6.1.

The rendered page contains the exact title, the accepted information
hierarchy, one render-boundary callout, one active Preparation 01 navigation
entry, and 14 native `gt_table` endpoints. Their body-row counts remain
9, 6, 3, 6, 9, 7, 2, 6, 9, 7, 2, 5, 5, and 5. Every table has a nonempty
caption, nonempty column labels, readable row grouping, and the accepted
values.

The page contains all nine country-coded site labels. It has no raw tibble or
kable output, error element, internal production identifier, or forbidden
reader link. The main page contains 42 nonempty links, including Quarto anchor
controls. All 32 same-page anchors resolve. The five unique internal file
targets exist. No internal rendered href contains `.qmd`, `file://`, `_build`,
or an absolute local path. The external GitHub edit link is not an internal
page link and was correctly excluded from that classification.

## Loopback lifecycle

The rerendered output was inspected through the selected in-app Browser with a
temporary static server.

| Field | Value |
|---|---|
| Command | `/usr/bin/python3 -m http.server 43129 --bind 127.0.0.1` |
| PID | `27921` |
| Address | `127.0.0.1` only |
| Port | `43129` |
| Document root | `_build/nathealth` |
| Bound-state check | `2026-08-13T12:32:44+0200` |
| Exact route | `http://127.0.0.1:43129/notebooks/preparation/01_import_state_alignment.html` |
| Teardown | `SIGINT`; process exited with status 0 |
| Listener verification | `lsof -nP -iTCP:43129 -sTCP:LISTEN` returned no rows and status 1 |

No symlink existed under the served root. The server exposed only static GET
and HEAD behavior, served no project source tree, and bound to no LAN or public
address. After teardown, the source, profile, target outputs, 827-file count,
294,803,640-byte total, and aggregate build identity were unchanged from the
post-render pre-loopback state.

## Final-size visual QA

At the 1440 by 1000 desktop viewport, the page has no horizontal overflow. The
title, sidebar, prose, links, callout, tables, references, and next-page
navigation are clear. The revised Mermaid diagram is centered at approximately
508 by 758 CSS pixels, and all node labels and arrows are readable without
clipping or overlap.

At the requested 708 by 1000 narrow viewport, the browser content width was
693 pixels and the main column was 642 pixels. The responsive navigation,
prose, callout, links, references, and next-page navigation are readable. Every
gt wrapper retains `overflow-x: auto`; all 14 tables fit the 642-pixel column in
this render and remain legible.

The revised Mermaid diagram remains approximately 508 by 758 CSS pixels and is
centered within the 642-pixel column. All seven nodes, labels, arrows, caption,
and the following section are visible in one ordinary viewport after a short
scroll. There is no clipping, overlap, document overflow, or harmful vertical
expansion. This resolves `RH-VIS-001`.

## Evidence

The screenshots and checksum records are listed in
`audit/report_harmonization/report017_preparation01_order02b_manifest.csv`.
No later preparation page was rendered or inspected during this order.

