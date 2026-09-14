# REPORT-017 Preparation 05 verification

Date: 2026-08-13  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `_build/nathealth/notebooks/preparation/05_model_input_acquisition.html`  
Outcome: **PASS**

Preparation 05 passed its bounded target render, focused R test, 128-path
preservation gate, semantic HTML audit, and desktop and narrow visual QA.
Preparation 06 was not started.

## Durable release and immediate preflight

The controlling order was read completely before execution. Its initial
dispatch identity was
`fb37c2403d6b53e10aad70526600d66223e8432e299a56429ce2740cdd35c9cf`.
During the post-render audit, the coordinator corrected only its table-note
metadata. The final order identity is
`572280f2b39959ff3a2a859588bf3965e576ef69e892f0a99745514b8e489531`.
The correction records the accepted source contract: nine native `gt`
endpoints have nine Quarto captions, while eight endpoints have source notes;
`tbl-acquisition-outcomes` intentionally has none. No source, render, test,
scientific boundary, or accepted value changed with that metadata repair.

The exact immediate pre-render pins all passed:

| Path | Bytes | SHA-256 |
|---|---:|---|
| `notebooks/preparation/05_model_input_acquisition.qmd` | 32,178 | `184c40b45f349dc7129a86a2e8a0cf57665df7f9a82a4183ea1128b09954ad1d` |
| `_quarto-nathealth.yml` | 7,404 | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| `tests/test_preparation05_report.R` | 7,430 | `c7a38c0b8c66b52776f307640198586a7ed22b95fd87c7c3f123a38e8594b7c2` |
| `audit/handoffs/preparation_reports_worker_handoff.md` | 31,435 | `ae882eb5a3079851d29367ad1883c7a4115edaf8774e3271d69ecf7e90dc4640` |
| stale target HTML | 282,942 | `1e3cddd7e66168159e5fb97564aa3fa274fb760571265bd0c6eb84597b72291d` |

The fresh preread reconciliation contains 128 paths. Relative to the older
final-profile baseline, 120 paths were byte-identical. The other eight were
the explicitly accepted Preparation 05 source, current profile, and six
reporting-era documentation identities. There was no unexplained drift. The
sealed preread file is
`audit/preparation_reports/report017_preparation05_prerender_scoped_readset.csv`
(SHA-256
`e7d2e6ae5441e4d66baf40d9a3cb12fb6d0dab1471c5da65bf6be0edd24c1772`).
It covers all acquisition data, registries, manifests, local fixed files,
production scripts, tests, and preparation artifacts read or described by
the page.

Static inspection found 10 bounded R chunks and nine `tbl-*` chunks. All
nine table chunks format accepted stored summaries with `gt`. No chunk calls
an acquisition builder, production verifier, network function, data writer,
normalization routine, model, prediction, resampling procedure, simulation,
or other hypothesis computation.

## Single targeted render and focused test

Exactly one Quarto command ran:

```text
quarto render notebooks/preparation/05_model_input_acquisition.qmd --profile nathealth
```

It used Quarto 1.9.37, R 4.6.1, the normal project `.Rprofile`,
`renv/activate.R`, and the project library
`renv/library/macos/R-4.6/aarch64-apple-darwin23`. The relevant installed
versions were renv 1.2.3, knitr 1.51, rmarkdown 2.31, gt 1.3.0, digest 0.6.39,
dplyr 1.2.1, readr 2.2.0, scales 1.4.0, tibble 3.3.1, and tidyr 1.3.2.
The already approved narrow permission allowed only transient access to the
existing user-owned R 4.6 renv cache. No package was installed or updated,
and `renv.lock` was not edited.

The observed command duration was 51.17 seconds. The immediate guard window
ran from `2026-08-13T14:33:16Z` through `2026-08-13T14:34:30Z`; the target
HTML mtime is `2026-08-13T14:34:10Z`. The command completed all 23 knitr
stages with exit status 0. The normal renv startup emitted its known
15-second dependency-discovery note, not an execution warning or failure.

The focused command was:

```text
Rscript tests/test_preparation05_report.R _build/nathealth/notebooks/preparation/05_model_input_acquisition.html
```

It used the same normal R 4.6.1 project startup, completed with exit status 0
in 16.16 seconds, and returned:

```text
PASS: Preparation 05 satisfies the bounded-render, fixed-source, gt-table, site-display, and provenance contract.
```

The QMD's extracted R chunks also parsed successfully under R 4.6.1.

## Protected-input and build preservation

All 128 accepted preread identities were exact immediately after rendering
and again after browser QA. The post-render comparison is
`audit/preparation_reports/report017_preparation05_postrender_scoped_verification.csv`
(SHA-256
`49f4a2b43b5621c0085fe997a2dca76e565960b0347871e4ab66610b4c62c379`).
The final comparison is
`audit/preparation_reports/report017_preparation05_final_scoped_verification.csv`
(SHA-256
`051589c54aae26087bdc7d6e822d1c676b429983fb3daa3631ed306bef49abcf`).
There was no change to an acquisition input, local fixed file, registry,
manifest, stored object or column audit, production script, test, shared
configuration, or preparation artifact.

The complete build contained 829 files before and after rendering. Four
entries changed during the target render:

- the target HTML changed from 282,942 to 287,308 bytes and from SHA-256
  `1e3cddd7e66168159e5fb97564aa3fa274fb760571265bd0c6eb84597b72291d`
  to `53486a2922558b5cf1d550b942533408741d443bee50669da8be0a1bc07e5b91`;
- `search.json` changed to SHA-256
  `2aa91f42bd4c2ea5598d3600f8967254514fc2e4bf4b8bcc4f5872d00e0ff698`;
- `sitemap.xml` changed to SHA-256
  `bd9e99a9b748b2e067aeb889960f4fa3b13dd77a94e2f903d7d1e4b412f4d9a3`;
  and
- `bootstrap-a2a938b4dd5711f7a799c87bd16ba44c.min.css` received only a
  transient mtime touch. Its 498,438 bytes and SHA-256
  `b3d78f1077461003efc2b21acc3f81ee6ba80468fe09df310b4c339e2e19133c`
  were unchanged. No restoration was required.

The browser QA changed neither content nor mtime in any of the 829 build
files. The post-render and post-QA build inventories are byte-identical at
SHA-256
`2278813dbe0365d533ee3a37ff7e6b0546f346408dbd3657d11a446b51ddee73`.

## Semantic HTML verification

The final DOM contains nine unique native `gt` table endpoints, one native
table and one nonempty Quarto caption at each endpoint. Eight tables retain
their intended source note, while `tbl-acquisition-outcomes` retains its
intended no-note role. The table audit is
`audit/preparation_reports/report017_preparation05_semantic_table_audit.csv`
(SHA-256
`39944ace58b9d00a1af1b6c5805d5f465b1f0863bb9b69deeae1cb81125008f3`).

The accepted title, purpose, preparation-chain position, render-boundary
callout, 9 by 7 modality grid, 63 of 63 acquisition outcome, 963-column
structural audit, fixed release identities, nine reused sleep diaries, 62
reused files, one downloaded file, and the Munich (DE) exercise-diary
exception are present. Site names appear in submitted order and colours as
Borås (SE), Delft (NL), Dortmund (DE), Tübingen (DE), Munich (DE), Madrid
(ES), Izmir (TR), San José (CR), and Kumasi (GH).

All five local links in main content resolve, including Preparation 06 and
the two detailed `.md` provenance records copied into the build. Every
current-page fragment resolves. Preparation 05 is the active navigation item,
and H06_daily appears in its accepted later hypothesis position. No internal
`.qmd`, `file://`, `_build`, build-directory, or absolute-local href appears.
The shared `supplementary_information.html` navigation target is absent
because this order forbids rendering that shared page; it is recorded as an
excluded shared-navigation endpoint, not a Preparation 05 main-link failure.

There is no rendered R error or warning container, raw tibble or console
output, duplicate table endpoint, empty reader-facing link label, unexpected
empirical figure, or unresolved current-page cross-reference. The browser
recorded zero console warnings or errors. The full semantic result is stored
in `audit/preparation_reports/report017_preparation05_semantic_checks.csv`
(SHA-256
`b5b86ea6bae501991b77d820488acfa7d8cfca25696646bbb93cfaa6b16d7a4d`).

Several early read-only semantic-harness drafts stopped on harness assumptions
about inline escaping, caption selectors, class-token matching, available
xml2 helpers, source-code anchor labels, and shared navigation scope. None
executed a page chunk or changed a source, output, input, or artifact. The
corrected final R audit passed with exit status 0.

## Final-size visual QA

At 1440 by 1000 pixels:

- document client width and scroll width both equalled 1,425 CSS pixels;
- the main column was 1,148.5 pixels wide and contained all page elements;
- the left-to-right Mermaid displayed at 1,066.164 by 332 CSS pixels, so its
  nominal 16-pixel labels remained 12 points;
- all nine native tables fitted their 1,148.5-pixel containers and used at
  least 11 CSS pixels, or 8.25 points, for cell text; and
- headings, callout, site colours, long release identities, paths, captions,
  notes, adjacent prose, and links showed no clipping, overlap, distortion,
  awkward wrapping, or unbalanced whitespace.

At 708 by 1000 pixels:

- document client width and scroll width both equalled 693 CSS pixels, while
  the main column remained within its 642-pixel container;
- the Mermaid displayed at 642 by 199.914 CSS pixels from its 1,066.164 by
  332 view box. Its scale was 0.602159, leaving effective label text at
  approximately 7.226 points, above the 7-point threshold;
- all nine native tables fitted exactly within the 642-pixel content width,
  wrapped long values without clipping, and retained at least 8.25-point cell
  text. No table needed horizontal scrolling, and no page-level overflow was
  present;
- the render-boundary callout fitted its 636-pixel content width exactly; and
- the collapsible sidebar opened to 448.422 pixels, remained scrollable, and
  displayed Preparation 05 as the active item. Breadcrumbs, search, code
  control, main links, previous/next navigation, and provenance links remained
  usable.

The exact measurements are stored in
`audit/preparation_reports/report017_preparation05_visual_metrics.csv`
(SHA-256
`4bf886df9c150642f934ab28e45deb1e8249711d2837046fbc04dc297cd95c1b`).
Representative desktop, narrow, navigation, and table screenshots are stored
under `audit/preparation_reports/report017_preparation05_*.png` and pinned in
the non-circular manifest.

## Secure loopback method and teardown

The build root contained no symbolic link. One temporary read-only static
server used the existing `_build/nathealth` directory and bound only to the
loopback interface:

```text
python3 -u -m http.server 0 --bind 127.0.0.1 --directory _build/nathealth
```

- Document root:
  `/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/_build/nathealth`
- Address: `127.0.0.1:52074`
- Target URL:
  `http://127.0.0.1:52074/notebooks/preparation/05_model_input_acquisition.html`
- Operating-system PID: `68759`
- Process start: `2026-08-13T16:49:14+02:00`
- Stop confirmation: `2026-08-13T16:54:53+02:00`
- Process exit status: `0`

The page and all required assets returned HTTP 200. The browser's optional
`/favicon.ico` request returned 404 and had no page effect. No non-GET request
occurred. The requested viewport override was reset and the QA tab was
finalized before teardown. After the keyboard interrupt,
`lsof -nP -iTCP:52074 -sTCP:LISTEN` returned exit status 1 with empty output,
the expected no-match PASS proving that no listener remained.

## Final identities

| Path | Bytes | SHA-256 |
|---|---:|---|
| `notebooks/preparation/05_model_input_acquisition.qmd` | 32,178 | `184c40b45f349dc7129a86a2e8a0cf57665df7f9a82a4183ea1128b09954ad1d` |
| `_quarto-nathealth.yml` | 7,404 | `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565` |
| `tests/test_preparation05_report.R` | 7,430 | `c7a38c0b8c66b52776f307640198586a7ed22b95fd87c7c3f123a38e8594b7c2` |
| `_build/nathealth/notebooks/preparation/05_model_input_acquisition.html` | 287,308 | `53486a2922558b5cf1d550b942533408741d443bee50669da8be0a1bc07e5b91` |
| `_build/nathealth/search.json` | 1,578,779 | `2aa91f42bd4c2ea5598d3600f8967254514fc2e4bf4b8bcc4f5872d00e0ff698` |
| `_build/nathealth/sitemap.xml` | 5,219 | `bd9e99a9b748b2e067aeb889960f4fa3b13dd77a94e2f903d7d1e4b412f4d9a3` |

`git diff --check` passed for the Preparation 05 source, focused test,
profile, and owner audit scope. The target source, test, profile, handoff, and
all 128 protected inputs retain their accepted identities. No source edit,
acquisition action, scientific recomputation, hypothesis execution, package
change, or full-project render occurred. Preparation 06 remains held.
