# REPORT-017 Preparation 05 independent acceptance

Date: 2026-08-13  
Harmonization task: `019ff52e-48ac-77b3-9a0e-9a87749a3bba`  
Document owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Target: `notebooks/preparation/05_model_input_acquisition.qmd`  
Disposition: **ACCEPTED. Preparation 05 passes the source, focused target-render, protected-input, semantic HTML, dynamic-link, navigation, desktop, narrow-layout, native-table, and visual contracts. Preparation 06 may be requested as the sole next REPORT-017 render owner, but remains held until explicit coordinator concurrence.**

This independent review used the authorized `$quarto-authoring` and
`$create-gt-tables` workflows. It did not rerender the page, execute an
acquisition or scientific builder, modify a reader source, regenerate an
artifact, or start another browser server.

## Accepted identities

- Reader source:
  `184c40b45f349dc7129a86a2e8a0cf57665df7f9a82a4183ea1128b09954ad1d`
- Nature Health profile:
  `5ccd16b064bfddd4777dd169720d89d42603bc1e2ddc8d6b0cb83c4cdefe3565`
- Focused test:
  `c7a38c0b8c66b52776f307640198586a7ed22b95fd87c7c3f123a38e8594b7c2`
- Target HTML:
  `53486a2922558b5cf1d550b942533408741d443bee50669da8be0a1bc07e5b91`
- Owner final record:
  `cf93864a0ed9eff7473d80b49c4cef001407d74840fc7a94605c061e0695abe2`
- Owner final manifest:
  `f26b7ad5c68162a88f4b76804ddec051a6841fee108b72cb296ecc61d3f4fc9e`

The non-circular 27-entry independent manifest is
`audit/report_harmonization/report017_preparation05_independent_acceptance_manifest.csv`,
SHA-256
`61bbb144e277fb51528ad7f3993c9254837664c264076174696346584e481ddf`.
R 4.6.1 independently verified all 27 file paths, SHA-256 values, and byte
counts.

## Focused and protected verification

The focused command was independently rerun with the normal project startup
and the approved narrow access to the existing user-owned renv cache:

```text
Rscript tests/test_preparation05_report.R _build/nathealth/notebooks/preparation/05_model_input_acquisition.html
```

It completed under R 4.6.1 and passed:

```text
PASS: Preparation 05 satisfies the bounded-render, fixed-source, gt-table, site-display, and provenance contract.
```

The normal startup reported the known 15-second dependency-discovery note. It
did not change the assertion result, install or update a package, edit
`renv.lock`, or alter a protected file.

The final scoped comparison contains 128 paths. Independent R 4.6.1 checking
confirmed all 128 as byte-identical after rendering and after visual QA. No
acquisition input, fixed local file, registry, manifest, object or column
audit, production script, test, shared configuration, or preparation artifact
drifted. The evidence file is
`audit/preparation_reports/report017_preparation05_final_scoped_verification.csv`,
SHA-256
`051589c54aae26087bdc7d6e822d1c676b429983fb3daa3631ed306bef49abcf`.

The owner's 38-entry manifest and this task's 27-entry independent manifest
both verify. Two preliminary independent R harness attempts were corrected
without touching project files. The first used `digest()` on path strings
instead of file contents; file-content mode then verified every hash. The
second applied the internal-QMD rule to Quarto's external GitHub edit link;
scoping the rule to local links then passed. These were audit-harness issues,
not source, render, or document defects.

## Semantic HTML, native tables, and links

Independent R DOM checking confirmed nine unique `tbl-*` endpoints. Every
endpoint contains exactly one native `gt` table, one nonempty Quarto-owned
caption, nonempty headers, and body rows. Eight endpoints contain their
intended source note. `tbl-acquisition-outcomes` intentionally has no source
note, matching the accepted source. No `gt`-owned competing caption is present.

The accepted 9-site by 7-modality grid, 63 of 63 acquisition outcome, 963
recorded source columns, 62 reused files, one downloaded file, nine reused
sleep diaries, fixed release identities, and the scoped Munich (DE)
exercise-diary correction are present. Site names appear with country codes in
the registered order and colours: Borås (SE), Delft (NL), Dortmund (DE),
Tübingen (DE), Munich (DE), Madrid (ES), Izmir (TR), San José (CR), and Kumasi
(GH).

All five local links in the main content resolve, including Preparation 06 and
the two detailed provenance records. Every current-page fragment resolves.
There is no internal `.qmd`, `file://`, `_build`, build-directory, or
absolute-local href, raw console or tibble output, rendered R error, duplicate
table endpoint, empty caption, or unexpected empirical figure. Preparation 05
is active in navigation, and both H06 complementary daily pages remain in their
accepted later hypothesis position.

The shared `supplementary_information.html` navigation target remains unbuilt
because order 23 authorized only Preparation 05. This is an excluded shared
navigation endpoint, not a Preparation 05 main-link failure. It remains part
of the later integrated link audit, and DOC-001 remains open.

## Independent visual review

The owner used the authorized read-only secure-loopback surface. The server
was rooted exactly at `_build/nathealth`, bound only to
`127.0.0.1:52074`, and recorded as OS PID 68759. It ran from
`2026-08-13T16:49:14+02:00` through
`2026-08-13T16:54:53+02:00`, exited with status 0, and left no listener. An
independent `lsof` check also returned the expected no-match status for port
52074.

The retained overview, navigation, and table screenshots were independently
inspected at original resolution.

At the requested 1440 by 1000 desktop viewport:

- the document client and scroll widths both equal 1,425 pixels, so there is
  no page-level horizontal overflow;
- the left-to-right overview is balanced, with all labels and edges legible at
  the recorded 12-point effective size;
- all nine native HTML tables fit their 1,148.5-pixel containers with intact
  captions, headings, rows, source-note roles, long identifiers, country-coded
  site labels, and a recorded minimum cell size of 8.25 points; and
- headings, prose, the render-boundary callout, links, and navigation show no
  clipping, overlap, or harmful wrapping.

At the requested 708 by 1000 narrow viewport:

- the document client and scroll widths both equal 693 pixels, while the main
  content remains inside its 642-pixel container;
- the overview displays at 642 by 199.91 pixels, with approximately 7.23-point
  effective labels, above the approved 7-point threshold, and no clipping or
  overlap;
- all nine native HTML tables fit the 642-pixel content width, retain at least
  8.25-point cell text, and wrap long values cleanly without requiring
  horizontal scrolling; and
- the callout, main links, previous and next links, and collapsible navigation
  remain usable.

This behavior passes
`audit/report_harmonization/phase4_table_visual_qa_policy.md`, SHA-256
`589efda97afe0b5d23f0a490dd446b051326ec8f3f7d7cad6d3363b51b4197c2`.
Preparation 05 contains native HTML tables only and no exported table PNG or
empirical reader-facing figure.

## Build preservation and final disposition

The targeted render changed the target HTML, `search.json`, and `sitemap.xml`.
One shared Bootstrap CSS file received an mtime-only touch while retaining
identical bytes and SHA-256. The post-render and post-QA 829-file build
inventories are byte-identical, so browser QA changed no build output. The
source, profile, focused test, handoff, and protected inputs retain their
accepted identities.

Preparation 05 is independently accepted. No scientific discrepancy or
reader-facing display defect was exposed. Preparation 06 may be requested as
the sole next REPORT-017 render owner, subject to explicit coordinator
concurrence. It has not been released or rendered by this acceptance. The
principal and supplemental manuscript-output shortlist remains provisional
and is not affected by this preparation-page acceptance.
