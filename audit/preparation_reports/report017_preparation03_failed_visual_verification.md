# REPORT-017 Preparation 03 failed narrow-visual verification

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `_build/nathealth/notebooks/preparation/03_reference_profiles.html`  
Outcome: **Desktop passed. The 708-pixel view stopped on unreadably scaled text in the horizontal Mermaid overview.**

No page source, configuration, rendered output, scientific artifact,
decision file, or production code was edited during this visual verification.
Preparation 04 was not started.

## Pre-visual verification state

The recovered focused test parsed and passed under R 4.6.1:

```text
PASS: Preparation 03 satisfies the bounded-render, version-specific verification, gt-table, figure, and provenance contract.
```

The test retained all scientific MDER behavior checks, exact decision-file
existence and SHA-256 checking, PREP-002, FIND-043, and the preceding/current
manifest separation. Its SHA-256 was
`1a506a9c486ce9891799148b4c361ee6d6c3633abe77c5c33fccff325f60a5d2`.

A read-only comparison passed all 39 scoped Preparation 03 identities before
and after visual QA.

## Secure loopback method and cleanup

One temporary server was rooted exactly at the existing `nathealth` build and
bound only to the loopback interface:

```text
python3 -u -m http.server 0 --bind 127.0.0.1 --directory /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/_build/nathealth
```

The assigned endpoint was `127.0.0.1:63198`. Requested page resources returned
HTTP 200 or 304. The browser also requested the optional `/favicon.ico`, which
returned 404 without a visible effect.

After inspection, the explicit viewport override was reset and the QA tab was
finalized with no retained tab. The server received a keyboard interrupt and
exited with status 0. A subsequent listener check returned no process on
`127.0.0.1:63198`. Source, configuration, HTML, empirical figure, and current
scientific manifest hashes and mtimes were byte-identical across loopback QA.

## Desktop result at 1440 by 1000 pixels

Desktop inspection passed:

- the document width equalled the browser client width, with no horizontal
  overflow or clipped main-content element;
- all 11 native `gt` tables fitted their 1,149-pixel containers, retained all
  nonempty headers and source notes, and used minimum 11 CSS pixel text,
  equivalent to 8.25 points;
- the pooled melEDI/illuminance SVG was displayed at 729 by 517 CSS pixels
  with readable axes, ticks, facets, legend, caption, and paired source-data
  link;
- both callouts were visible and unclipped;
- the 394-of-394 result remained explicitly assigned to the preceding
  manifest and FIND-043 remained open for the current manifest;
- the sidebar correctly marked `03 Reference profiles` active; and
- no raw console/tibble output or rendered error text was present.

The horizontal Mermaid overview had a 1,588.9297-unit view box and displayed
at 1,148.5 CSS pixels. Its scale of about 0.723 reduced the nominal 16 CSS
pixel labels to about 11.56 pixels, or 8.67 points. Desktop therefore passed
REPORT-011.

## Narrow result at 708 by 1000 pixels

The responsive prose, tables, empirical figure, callouts, links, and
navigation passed:

- document client width and scroll width both equalled 693 CSS pixels;
- all 11 tables fitted 642-pixel containers and retained minimum 8.25-point
  text, nonempty headers, and source notes;
- the empirical figure displayed at 642 by 455.4 CSS pixels, scaling its
  9-point axis and legend text to about 7.93 points and its 10-point facet
  text to about 8.81 points;
- the render-boundary and version-specific verification callouts wrapped
  without clipping;
- long SHA-256 strings wrapped without squeezing adjacent content;
- all visible links had accessible labels;
- the navigation drawer opened, showed the active Preparation 03 item, and
  closed normally; and
- no main-content element crossed the viewport boundary.

The Mermaid overview failed final-size typography. It displayed at 642 CSS
pixels while retaining the 1,588.9297-unit horizontal view box. The 0.404
scale reduced nominal 16 CSS pixel node labels to 6.46 CSS pixels, equivalent
to approximately 4.85 points. Those labels carry the central preparation
sequence and fall below REPORT-011's normal 7-point minimum.

The visible defect is confined to the Mermaid direction declaration
`flowchart LR` at source line 831. No repair was made during this failed
visual order.

## Link and site-scope notes

No internal `.qmd`, `file://`, `_build`, build-directory, or absolute-local
href occurred in the rendered page. Current-page fragments resolved, the
Preparation 02 and Preparation 04 pager targets existed, and all linked
Preparation 03 inputs, source data, manifest, and PREP-002 decision files
were present in the partial build.

As already recorded during Preparation 02 acceptance, the global sidebar
contains `supplementary_information.html`, which is absent from this partial
build because this order prohibited rendering supplementary information or
the full project. That known global-build limitation was not treated as a
Preparation 03 content defect. Preparation 03 does not display individual
site names, so country-coded site-label QA was not applicable.

## Protected identities at the stop

| File | SHA-256 |
|---|---|
| `notebooks/preparation/03_reference_profiles.qmd` | `a0d9bc85a906b6c83edd8019421b012220c11e2d72988724fd9d1439fbc57a3a` |
| `_quarto-nathealth.yml` | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| `_build/nathealth/notebooks/preparation/03_reference_profiles.html` | `262705d82ad3add77028492502f94b45d526424c25c1f5f3c8b4ac33b75b4c2c` |
| `_build/nathealth/notebooks/preparation/03_reference_profiles_files/figure-html/fig-pooled-reference-profiles-1.svg` | `b011c1ac17cc1cb05bfda58170371fa8c49813b277e0455f65373a60447a9923` |
| `artifacts/12_manifests/reference_profile_artifacts.csv` | `5e08099602682a4b951b0304764f341932ef2f03ccd4c62f32793ea82084e062` |
| `audit/decisions/mder_mean_of_viable_ratios.md` | `1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de` |
