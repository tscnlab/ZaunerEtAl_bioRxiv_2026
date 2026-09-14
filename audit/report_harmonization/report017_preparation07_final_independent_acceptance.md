# REPORT-017 Preparation 07 final independent acceptance

Date: 2026-08-14

Outcome: **ACCEPTED.** Preparation 07 now passes source, targeted-render,
scientific-input preservation, semantic HTML, native-table, figure/source-data,
desktop, narrow, and secure-loopback checks. Preparations 01 through 07 are
therefore accepted in the REPORT-017 serial sequence. This record does not
release a hypothesis render.

## Accepted identities

| Item | SHA-256 |
|---|---|
| Preparation 07 QMD | `e5b89c62b03af2e7989f76cb9578608b92420978393a7c857fd5edcc335dbcb1` |
| Focused test | `9d3a19b7d30ee0a6d5b0b643da628e25e970b232cf2f812fae1efdb4fe8fff58` |
| Nature Health profile | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| Target HTML | `6ed53f8504f1de4db1b96e2cb1ea7babf06d0828e6ea43501eac93104c7b27b7` |
| Owner verification | `dab104081cecf7c3c0f4c952ff76800dbca13725f62e7ad7bb936a3cfbcc11c0` |
| Owner 52-entry manifest | `040c468e7c56652d0f1b6896b54c84cdab1a1f808d4553869c479f7efe4eb42a` |

The QMD retains the accepted provenance-only PREP07-PROV-001 explanation,
the vertical Mermaid repair, and the four isolated 10 pt figure-theme
settings. The focused test retains the accepted provenance, semantic, native
table, figure, site, link, and no-production-execution gates.

## Independent nonvisual verification

The owner's non-circular manifest independently verifies 52/52 current files,
hashes, and byte counts. The final semantic audit contains 24/24 PASS rows.
The post-QA protected comparison contains 38/38 unchanged paths. The post-QA
build comparison contains 817/817 unchanged rows relative to the post-render
state.

The complete independent source-and-HTML command

```text
Rscript tests/test_preparation07_report.R \
  _build/nathealth/notebooks/preparation/07_example_days.html
```

ran under R 4.6.1 with normal project startup and returned exit status 0. It
confirmed exactly seven bounded native `gt` tables, exactly three figure
endpoints, the paired source-data link, approved site labels and order,
provenance text and pins, navigation, dynamic links, and absence of raw table,
warning, error, or unresolved-reference output.

The single target render changed content only for the target HTML, its three
target-owned HTML PNGs, and the sitemap. One Bootstrap stylesheet received an
mtime-only refresh; the search index remained unchanged. No path was added or
removed. The durable showcase PNG, SVG, and paired source-data CSV remain
byte-identical. No source, test, profile, package, lockfile, data, durable
figure, artifact manifest, decision, ledger, manuscript, or hypothesis file
was edited.

## Independent visual acceptance

Representative retained desktop and 708-pixel screenshots were inspected
independently. They show readable headings, callouts, navigation, captions,
links, country-coded site labels, profile panels, units, legends, state bands,
and all seven native tables without clipping, overlap, compressed panels,
broken units, or page-level horizontal overflow.

The 50-row final-size record passes every check. At 708 pixels:

- the four repaired 10 pt figure-text roles display at 7.039 pt in each of
  the three figures;
- the vertical Mermaid's minimum effective label size is 9.211 pt, with all
  eight labels present and no overlap or clipping;
- all seven native HTML tables remain inside their 642-pixel containers with
  a minimum 8.25 pt cell font; and
- `overflow-x: auto` remains available, although none of the seven tables
  requires scrolling in the measured state.

This applies the accepted table rule. HTML tables need reasonable desktop
behavior and a contained usable narrow-screen scroll affordance. Exported
table PNGs, when present elsewhere in the corpus, are judged at their intended
export size. Preparation 07 contains no exported table PNG.

The desktop and narrow targeted screenshots confirm the same stored traces,
points, panels, daylight regions, diary-state bands, site order, captions, and
alt-text roles. The review did not recalculate or adjudicate a scientific
quantity.

## Loopback and scientific boundary

The temporary server was rooted exactly at `_build/nathealth`, bound only to
`127.0.0.1:55750`, and used only for the exact Preparation 07 route. It exited
0. A final `lsof` check returned no listener on the port. Browser QA left all
38 protected inputs and all 817 post-render build identities unchanged.

No fixed-seed selection, strict showcase verifier, builder, model, prediction,
simulation, bootstrap, Shapley analysis, scientific artifact regeneration, or
full-project render ran. The accepted provenance statement remains explicit:
the illustrative display does not enter an H01 through H11 model.

## Disposition

Preparation 07 is independently accepted. The Preparation 01 through 07
sequence is complete. The next serial action may begin only after coordinator
concurrence identifies and releases the exact first hypothesis target. DOC-001
remains open, the H06 hourly analysis remains the main H06 result, H06_daily
remains complementary, and every principal or supplemental output role remains
provisional until author visual approval.
