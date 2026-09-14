# REPORT-017 Preparation 07 narrow-visual stop

Date: 2026-08-14

Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`

Target: `_build/nathealth/notebooks/preparation/07_example_days.html`

Outcome: **STOP. The one authorized target render, focused tests, protected
gate, semantic audit, desktop layout, native tables, and desktop figures pass.
At the required 708-pixel viewport, the unchanged left-to-right Mermaid scales
its important labels to approximately 5.03 pt, below the explicit 7 pt
minimum.**

No source, test, configuration, scientific input, accepted artifact, decision,
ledger, lockfile, or handoff was edited. No second render was attempted. No
hypothesis target was rendered.

## Authority and preflight

The controlling order was
`audit/report_harmonization/owner_orders/27_preparation07_phase4_render.md`,
SHA-256
`0f0d5570f964d64cdd58897e4e45a5fb96c18f08486b2e29031bb5b1f69fd560`.
All immediate release pins matched:

| Path | Bytes | SHA-256 |
|---|---:|---|
| `notebooks/preparation/07_example_days.qmd` | 39,361 | `ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae` |
| `tests/test_preparation07_report.R` | 11,897 | `958cc944987ffdb062452a06a9ec173af2f78dfa53f962399f53016f9d4ba163` |
| `_quarto-nathealth.yml` | 7,404 | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| Independent acceptance record | 5,580 | `3708afb4f5600b6c021a93579179a5bf164f5d7b7bcfca0a0c26d1f6b52ca7ce` |
| Independent acceptance manifest | 2,355 | `96481a17ec91de252cbca671cb876466529ace7f8df747b462634985c634c164` |
| Sealed equivalence audit | 9,342 | `870cbb5d5f9414f61ee7db05b61a12eb51d56c9273e9ae7dfd05094984c47164` |
| Sealed equivalence evidence | 4,824 | `0757fc175c44fd33e9d8b06e4f9352699c18bfe50bbcf1c65d141f3f36a1cb97` |
| Sealed equivalence manifest | 538 | `01a07b87799faeb8291bb6187ced96ab7abdcf2399ee77c5dcfd19d608b1194c` |
| Stale target HTML | 271,468 | `e37609f5adab0a5b57ce96d0229e4bac07dae3c713fe28aca3da68066ba12bdc` |

The build root contained 829 regular files and no symbolic links. The fresh
pre-render inventory is
`audit/preparation_reports/report017_preparation07_prerender_build_inventory.csv`,
SHA-256
`26fb203b29f411309b5a08341aeedaf17ec7aeec236d2722b59870eeda0ae8ec`.
The 38-path protected inventory is
`audit/preparation_reports/report017_preparation07_prerender_protected_inventory.csv`,
SHA-256
`5b9cf24c75a593d0d7a46530904c965a92476333bd19dea619ad348538c94949`.
It includes every accepted Preparation 07 scientific/display input, source,
test, profile, strict verifier, historical manifest, sealed audit input,
previous stop record, reporting decision, and `renv.lock`.

The source-only focused test ran before rendering under R 4.6.1 and passed. It
statically parsed all 11 QMD R chunks and enforced the forbidden builder,
verifier, writer, model, prediction, resampling, simulation, and regeneration
patterns. No QMD chunk was evaluated by the test.

## Environment and single render

The environment probe confirmed:

- Quarto 1.9.37 at `/usr/local/bin/quarto`;
- R 4.6.1;
- the normal project at the repository root;
- the project library at
  `renv/library/macos/R-4.6/aarch64-apple-darwin23`; and
- renv 1.2.3, knitr 1.51, rmarkdown 2.31, gt 1.3.0, xml2 1.6.0,
  digest 0.6.39, dplyr 1.2.1, readr 2.2.0, scales 1.4.0, tibble 3.3.1,
  and tidyr 1.3.2.

Exactly one Quarto command ran:

```text
quarto render notebooks/preparation/07_example_days.qmd --profile nathealth
```

It used normal `.Rprofile` and `renv/activate.R` startup with the previously
approved narrow access to the existing user-owned R 4.6 renv cache. The final
guard passed at `2026-08-14T12:09:18+02:00`. The tool-observed command duration
was 40.07 seconds, all 25 knitr stages completed, and the command exited 0.
The target HTML mtime is `2026-08-14T12:10:11+02:00`. The only message outside
normal render progress was renv's established informational dependency-
discovery note. No package was installed or updated, and `renv.lock` remained
exact.

The new target HTML is 297,095 bytes with SHA-256
`9c05cd46796d853dad10e5f3058231946f0c1df3a4678d6272d6aa8141fe47db`.
The post-render focused command was:

```text
Rscript tests/test_preparation07_report.R _build/nathealth/notebooks/preparation/07_example_days.html
```

It exited 0 under R 4.6.1 and returned:

```text
PASS: Preparation 07 satisfies the bounded-render, fixed-input, gt-table, accessible-figure, site-display, and provenance contract.
```

## Protected inputs and build delta

All 38 protected identities were exact immediately after rendering and after
browser QA. The three protected inventories are byte-identical at SHA-256
`5b9cf24c75a593d0d7a46530904c965a92476333bd19dea619ad348538c94949`.
The scientific RDS files were hashed as bytes only and were not opened or
compared during these preservation checks.

The render changed content in exactly the target HTML, `search.json`, and
`sitemap.xml`. It refreshed only mtimes for the three generated HTML figure
PNGs and the shared Bootstrap stylesheet; their bytes and SHA-256 identities
were unchanged. Quarto also removed 12 obsolete target-local dependency files
from `07_example_days_files/libs/`. The new HTML contains no reference to that
old directory and instead loaded all current shared `site_libs` assets with
HTTP 200 responses. The target-local output directory now contains only the
three referenced figure PNGs. Thus the removal is normal target-owned cleanup,
not a missing-asset or protected-input failure.

The complete 19-row build delta is
`audit/preparation_reports/report017_preparation07_postrender_build_delta.csv`,
SHA-256
`580966255826a0b104a38e4d43be9a7939a7386584173c605badce0940f41a4d`.
The post-render build has 817 regular files and SHA-256 inventory
`f181e470d5e7fa699c12de3b96bf96e68da63282bd5af201e8dc21bb43b4ba0b`.
Browser QA changed neither content nor mtime in any build file, so the
post-render and post-QA inventories are byte-identical.

The three generated HTML figure PNGs remain:

| Figure | Bytes | SHA-256 |
|---|---:|---|
| Example days 1 to 3 | 434,021 | `ad6ee88b1df7a0b2f17d513825d74887cc009b74317ae23d43bb16a14c2d9ad8` |
| Example days 4 to 6 | 352,019 | `837d65b0f35f490e2c76ac4e170ebd633a349c4aff821fe82eae2be7ebb6b53d` |
| Example days 7 to 9 | 347,347 | `fd6f1cb73718674fdb6544e89bb684be0723bb33378709c399c4b161e1ec5629` |

The durable showcase PNG remains
`a35e8189bdbdb450411bfe7f71d52964c17e45a7a26fdb44e82776d201b00ff3`,
and the durable SVG remains
`5ad003220cb1d5a1d2b223af206f4a1e608b4e1fa0e695d656989dde62b0ea4a`.

## Semantic HTML and native-table audit

The final R 4.6.1 semantic harness passed all 24 checks. The DOM contains
exactly seven native `gt` table endpoints. Each endpoint has one native table,
one nonempty Quarto-owned caption, nonempty headers, body rows, and its
intended source note. The table audit is
`audit/preparation_reports/report017_preparation07_semantic_table_audit.csv`,
SHA-256
`4a00379bfb704c048fd5aa512d837a4f7e576af5aa8d50b57a44305965087a50`.

All three figure endpoints have a single image, substantive alt text,
nonempty caption, and an existing source file. The Mermaid endpoint and
caption are present. The approved site/daylight explanation appears in full.
The historical `b0e8de53...` and current `39ffe488...` hashes both render in
the technical input table with the plain disposition `Equivalent values,
different file version`; they are not presented as identical files.

All nine country-coded site names occur in submitted order. The paired
figure-source CSV resolves. Preparation 07 is the active sidebar item and both
H06_daily navigation entries are present. All seven main-content links and all
released navigation links resolve with nonempty labels. The one unavailable
shared navigation endpoint is `supplementary_information.html`; it is isolated
as the known unreleased shared page and was not rendered because order 27
forbids another target or full-project render.

There is no internal QMD, `file://`, `_build`, build-directory, or absolute
local reader link; no hard-coded internal HTML link in source; no terminal
table renderer; no raw tibble or console output; no unresolved cross-reference;
no reader-visible internal workflow code; and no rendered warning or error
node. Browser warning/error logs were empty. The semantic check file is
`audit/preparation_reports/report017_preparation07_semantic_checks.csv`,
SHA-256
`5cd0ce50defa82768af8de6da9f58fc5b23e3b8cab24136e6caec4e7f834238c`.

The initial temporary semantic harness stopped before inspection because one
R regex string was under-escaped. Its corrected first pass then exposed only
harness assumptions about zero-width hash separators, hidden source-code
anchors, external GitHub edit links, the unreleased supplementary target, and
the active sidebar label. A second pass retained only the stale active-label
selector. The final selector targeted the active Preparation 07 href and all
24 checks passed. These were temporary audit-harness issues, not source,
output, link, or scientific drift.

## Desktop visual QA

At 1,440 by 1,000 pixels:

- the document client width and scroll width were both 1,425 CSS pixels;
- the main column was 1,148.5 pixels wide;
- all seven native tables fitted their containers, required no horizontal
  scrolling, and retained a minimum 8.25 pt cell font;
- the LR Mermaid displayed at 1,148.5 by 262.52 pixels from a
  1,531.16 by 350 view box;
- its eight nonempty 16-pixel labels retained a minimum effective size of
  9.001 pt, with zero clipped or overlapping labels; and
- all three figures displayed at 1,148.5 pixels wide with readable site,
  participant, date, axis, state-band, daylight-context, and legend text,
  distinguishable traces and points, and no clipping, distortion, or broken
  units.

The desktop visual result is PASS. Representative evidence includes:

- `report017_preparation07_desktop_full.png`;
- `report017_preparation07_desktop_mermaid.png`; and
- `report017_preparation07_desktop_figure1.png` through
  `report017_preparation07_desktop_figure3.png`.

## Narrow visual failure

At 708 by 1,000 pixels, page integrity and native tables pass:

- document client width and scroll width were both 693 CSS pixels, so there
  was no page-level horizontal overflow;
- the main column and render-boundary callout remained within 642 pixels;
- all seven native tables fitted their 642-pixel containers, required no
  horizontal scrolling, and retained a minimum 8.25 pt cell font; and
- all three image endpoints loaded without a broken image.

The unchanged LR Mermaid fails the controlling typography gate. It displayed
at 642 by 146.75 pixels from the same 1,531.16 by 350 view box, a scale of
0.419286. Its eight important 16-pixel labels therefore displayed at only
5.031 pt. The labels remained inside the SVG and had zero detected overlap,
but they are visibly too small and fall well below the required 7 pt minimum.

The defect is visible in
`audit/preparation_reports/report017_preparation07_failed_narrow_viewport.png`,
SHA-256
`a01341a3232828298c462798ed0e96582bf745297d928d3543edd91d4cd6e87a`.
The exact measurements are in
`audit/preparation_reports/report017_preparation07_failed_visual_metrics.csv`,
SHA-256
`2658cc22046f42c42d58cc77560cd74b354848205cdac5f2af4fa5683b071360`.

Order 27 requires a stop on this failure and does not authorize source editing
or another render. The source remains unchanged with `flowchart LR` at
`notebooks/preparation/07_example_days.qmd:664`. No repair was attempted. The
narrow review ended at this gate, so a later released rerender must repeat the
complete narrow visual inspection after any approved bounded correction.

## Secure loopback lifecycle and teardown

The initial restricted-sandbox server attempt at
`2026-08-14T12:18:48+02:00` failed with `PermissionError` before binding and
created no listener. The already authorized narrow loopback permission was
then used for the same command:

```text
python3 -u -m http.server 0 --bind 127.0.0.1 --directory _build/nathealth
```

- document root:
  `/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/_build/nathealth`;
- address: `127.0.0.1:51011`;
- PID: `8466`;
- exact listener-confirmation time: `2026-08-14T12:19:04+02:00`;
- target URL:
  `http://127.0.0.1:51011/notebooks/preparation/07_example_days.html`;
- first page GET: `2026-08-14T12:20:08+02:00`;
- stop confirmation: `2026-08-14T12:24:58+02:00`; and
- server exit status: 0.

The exact process-start instant after the sandbox retry was not separately
recorded, so it is not reconstructed. All page and required asset requests
returned HTTP 200; only the optional favicon returned 404. The browser viewport
override was reset and the QA tab was finalized before teardown. After the
keyboard interrupt, `lsof -nP -iTCP:51011 -sTCP:LISTEN` returned exit status 1
with empty output, the expected no-match result proving that no listener
remained. The lifecycle CSV is
`audit/preparation_reports/report017_preparation07_loopback_lifecycle.csv`,
SHA-256
`8576173b7e143fa8c2df173dd39b3916514ea40dee18d7335a98b4e27eb500cf`.

`git diff --check` passes for the accepted source, test, and owner evidence.
No preparation input, scientific value, fixed selection, durable artifact,
model result, source, test, configuration, decision, ledger, lockfile, or
hypothesis output changed. Preparation 07 remains stopped at the bounded
Mermaid display repair boundary, and every hypothesis render remains held.
