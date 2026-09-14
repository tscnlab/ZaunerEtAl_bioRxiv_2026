# REPORT-017 Preparation 03 independent acceptance

Date: 2026-08-13  
Harmonization task: `019ff52e-48ac-77b3-9a0e-9a87749a3bba`  
Document owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/03_reference_profiles.qmd`  
Disposition: **ACCEPTED. Preparation 03 passes the source, focused target-render, protected-input, semantic HTML, link, navigation, desktop, narrow-layout, and table-visual contracts. Preparation 04 may be released as the sole next REPORT-017 render owner.**

This acceptance used the authorized `$quarto-authoring` workflow and the secure
loopback visual-inspection process. It did not render a page, execute a Quarto
or knitr document, modify a scientific object, regenerate an artifact, or edit
another owner's source.

## Accepted identities

- Reader source: `4ec7a6880591157eefe969e85d7b2adf7c22690fafaf434f715af944a7906504`
- Nature Health profile: `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`
- Focused test: `1a506a9c486ce9891799148b4c361ee6d6c3633abe77c5c33fccff325f60a5d2`
- Target HTML: `43d8260933342e9cc511fed115672e5fd1065b76a6a5c6fcf136964f2735f77d`
- Pooled-profile SVG: `b011c1ac17cc1cb05bfda58170371fa8c49813b277e0455f65373a60447a9923`
- Current scientific artifact manifest: `5e08099602682a4b951b0304764f341932ef2f03ccd4c62f32793ea82084e062`
- Controlling MDER decision: `1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de`

The non-circular 15-entry acceptance manifest is
`report017_preparation03_independent_acceptance_manifest.csv`, SHA-256
`18688f79b718b4fc47fa550c12cbe48a53abb570cf051953d50fb84935178963`.
An initial validation invocation used `identical()` on a named calculated
vector and the unnamed CSV column and therefore stopped on an attribute-only
comparison. The corrected element-wise validation showed that all 15 file
hashes and byte counts match. This was a checker representation issue, not a
source, render, or manifest discrepancy.

## Exact reader-only repair

The accepted source differs from the previously released source only by the
authorized Mermaid declaration:

```diff
-flowchart LR
+flowchart TB
```

Changing only `TB` back to `LR` reproduces the released pre-repair SHA-256
`a0d9bc85a906b6c83edd8019421b012220c11e2d72988724fd9d1439fbc57a3a`.
Every node, edge, label, figure identifier, caption, alt text, table endpoint,
R expression, scientific statement, and visible PREP-002/FIND-043
qualification is preserved.

## Focused nonvisual verification

The owner record
`audit/preparation_reports/report017_preparation03_diagram_verification.md`,
SHA-256
`9af83cf5bfd0c4b1bbe034dc76419adfd3a587c3fbce55045f85110efd338601`,
and its manifest, SHA-256
`d15d1df84fba3d8fc8d1e28caec416a5f548f14a7fd84639eecb303eacb21e08`,
were reviewed completely.

The focused R 4.6.1 command was independently rerun with the normal project
profile:

```text
/usr/local/bin/Rscript tests/test_preparation03_report.R _build/nathealth/notebooks/preparation/03_reference_profiles.html
```

It passed the bounded-render, version-specific verification, native `gt`,
figure, and provenance contract. The test retains exact decision-file
existence and SHA-256 pinning, the current MDER wording, PREP-002, FIND-043,
and the distinction between the preceding and current manifests. It does not
require internal decision identifiers or paths to be exposed to readers.

The owner's final 39-path protected comparison passed 39 of 39 identities.
Its evidence file is
`report017_preparation03_diagram_final_scoped_verification.csv`, SHA-256
`473c4440e43a3897d2e24d8c5f37ade38146073ce56ca81ba5325a5a31d2efa0`.
No scientific input, metric value, table value, empirical figure value,
decision file, profile configuration, or unrelated build output drifted.

## Independent secure-loopback lifecycle

Before serving the page, the accepted source, configuration, target HTML, and
scoped build inventory were rechecked. No symlink was present below
`_build/nathealth`, so no served path could resolve outside the authorized
document root.

The exact server command was:

```text
python3 -u -m http.server 0 --bind 127.0.0.1 --directory /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/_build/nathealth
```

- Start time: `2026-08-13T13:05:15Z`
- Operating-system PID: `47170`
- Bound address: `127.0.0.1`
- Selected port: `64090`
- Document root: `_build/nathealth`
- Exact target URL: `http://127.0.0.1:64090/notebooks/preparation/03_reference_profiles.html`
- Browser surface: the ordinary supported in-app Browser only
- Stop time: `2026-08-13T13:06:34Z`

The server exposed only static GET/HEAD behavior and no upload or write
endpoint. Inspection stayed on the exact target page and its local assets.
The first interrupt did not end the background process, so the exact PID was
then terminated with `SIGTERM`. The resulting process status was 143. A port
listener check and PID check both confirmed complete teardown. No listener
remained on port 64090.

The complete build-tree content digest was calculated before and after QA
with:

```text
find _build/nathealth -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256
```

Both digests were
`b587172f339c0e07d6ae2ebe4e03eafe6042e974ed5aa211a1896d6c0629e76f`.
The source, configuration, target HTML, and focused-test hashes also remained
exact after teardown.

## Visual acceptance

The controlling table policy is
`audit/report_harmonization/phase4_table_visual_qa_policy.md`, SHA-256
`589efda97afe0b5d23f0a490dd446b051326ec8f3f7d7cad6d3363b51b4197c2`.

For native HTML tables, the controlling readability check is a typical
desktop or laptop viewport. A narrow viewport checks page integrity and a
contained, usable horizontal-scroll affordance. It does not require a dense
table to fit without scrolling. For exported tables, the controlling visual
artifact is the PNG inspected at its intended final size. Preparation 03 has
11 native HTML tables and no exported table PNG endpoint, so the PNG-specific
table check is not applicable to this page.

### Desktop, requested 1440 by 1000 pixels

- Browser content dimensions were 1,425 by 990 pixels.
- Document client width and scroll width were both 1,425 pixels, with no
  page-level horizontal overflow.
- All 11 native `gt` tables fitted their desktop containers. Captions,
  headings, rows, and source notes were intact. The minimum table text was
  11 CSS pixels.
- The top-to-bottom Mermaid overview displayed at 541.1094 by 782 pixels with
  16 CSS pixel labels. Its nodes, edges, and labels were legible, unclipped,
  and non-overlapping.
- Both callouts, the version-specific qualification, the pooled-profile
  figure, link labels, and navigation were readable and correctly placed.

The retained screenshot is
`audit/report_harmonization/report017_preparation03_independent_desktop.png`,
1,425 by 990 pixels, SHA-256
`205c1f30f184afc2b5f2acfa4f0aa1df2000da2b215d660bc5330c1991b27f11`.

### Narrow, requested 708 by 1000 pixels

- Browser content dimensions were 693 by 979 pixels.
- Document client width and scroll width were both 693 pixels, with no
  page-level horizontal overflow.
- Every native table remained inside a 642-pixel wrapper with computed
  `overflow-x: auto`. None currently required scrolling, but the required
  contained overflow behavior was present.
- The Mermaid overview retained its natural 541.1094-pixel width and 16 CSS
  pixel labels. No node, edge, label, or following content was clipped or
  overlapped.
- Callouts, long hashes, figure content, captions, links, and navigation
  wrapped or reflowed cleanly.

The retained screenshot is
`audit/report_harmonization/report017_preparation03_independent_narrow.png`,
693 by 979 pixels, SHA-256
`a0df328061908337d5bdf5b0ded9b11c96d9e5c4d83a584e4a5e717b78a4150a`.

## Final disposition

Preparation 03 is independently accepted. RH-VIS-001 is resolved by the
bounded top-to-bottom diagram repair. No scientific or provenance discrepancy
was exposed. Preparation 04 may now be released as the only active
REPORT-017 render owner, subject to the coordinator's serial authorization.
