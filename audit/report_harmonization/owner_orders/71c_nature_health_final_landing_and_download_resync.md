# REPORT-018 owner order 71c: final landing and download resynchronization

Date: 2026-09-03

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

Status: `RELEASED_FOR_ONE_BOUNDED_NO_RENDER_EXECUTION`

## Objective

Integrate the exact accepted final Nature Health HTML and Word manuscript into
the accepted 37-route website without running Quarto, Pandoc, knitr, or any
scientific code. The completed landing page must retain the accepted navigation
shell and must preserve Supplementary Figure S6 as the direct accepted SVG.

## Accepted inputs

- Manuscript HTML:
  `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html`,
  SHA-256 `438f80545e09eb1844d15c3d4495d7d2d4dbc07bcf039f4c8e4430b18e79ee0c`,
  30,877,834 bytes.
- Word manuscript:
  `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`,
  SHA-256 `74193a7a787ea18d70933b1742e588304a6bf6050c8b43e8a0a0cc352b44a2b8`,
  28,793,619 bytes.
- Supplementary Figure S6 SVG authority:
  `manuscript/R0_NatHealth/display_assets/brown_participant_state_raincloud.svg`,
  SHA-256 `200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653`,
  108,600 bytes.
- Writer Order 71a acceptance:
  `audit/report_harmonization/report018_writer_order71a_independent_acceptance.md`.
- Writer Order 71b2d acceptance:
  `audit/report_harmonization/report018_writer_order71b2d_independent_acceptance.md`,
  SHA-256 `29d0e64e947d13a947cde77fa8fd87faada7db86f7261c074c1ff7be055442f5`.
- Current accepted landing preimage:
  `_build/nathealth/index.html`, SHA-256
  `c8abe2f9fbfcbe2fc8b4e39e149797a6dc2d74a5735337ed2399fb6e5814eb21`,
  29,023,063 bytes.
- Current downloadable DOCX preimage:
  `_build/nathealth/ZaunerEtAl2026_NatHealth_phase3_brown.docx`, SHA-256
  `6cd592391f720829ed278a35e81c854ee7fd54eca6a4a4e664faad7b37310f91`,
  28,792,333 bytes.
- Current 37-route corpus manifest:
  `audit/report_harmonization/phase4_corpus_manifest.csv`, SHA-256
  `b807197850b3d9024899da79403f3aec7d716f9be785fe1eefe6500e1ac1e55d`,
  11,479 bytes.

## Authorized execution

1. Reproduce every sealed input identity before doing any work. Stop without
   production writes if any identity differs.
2. Copy the complete accepted `_build/nathealth` tree to a fresh isolated
   candidate directory. Confirm 893 regular files and zero symlinks before the
   candidate transformation.
3. Reuse the accepted Order 70 landing transformation contract and navigation
   shell. Transform only the candidate `index.html` from the accepted final
   manuscript HTML. Copy the exact accepted Word manuscript to the candidate
   download path.
4. Do not edit or execute either manuscript QMD, Supplementary Information QMD,
   `index.qmd`, Quarto configuration, CSS, includes, analysis code, data, figure
   code, or table code.
5. Preserve all other 891 build members byte for byte. Relative to the current
   accepted build, the only authorized production changes are `index.html` and
   `ZaunerEtAl2026_NatHealth_phase3_brown.docx`.
6. Verify the candidate before promotion. Required gates include:
   - 37 HTML routes, the accepted route sequence, navbar, search, footer,
     previous and next navigation, desktop right-hand TOC, and collapsed mobile
     TOC;
   - 28 authors, 19 semantic tables, 20 figure endpoints, no duplicate IDs,
     no unresolved manuscript fragments or table-header references, and no
     broken local resources;
   - Table 3 in the exact accepted descriptive-table metric order: Duration,
     Dynamics, Exposure history, Level, Spectrum, Timing;
   - Supplementary Figure S5 as one real two-panel SVG, Supplementary Figure S6
     as an SVG MIME data resource matching the accepted SVG authority, and
     Supplementary Figure S12 without an MDER legend;
   - no page-level horizontal overflow at 1,440, 708, and 390 CSS pixels, apart
     from the accepted unchanged legacy classification on the Descriptives
     route at 708 pixels;
   - the Word download resolves and hashes exactly to
     `74193a7a787ea18d70933b1742e588304a6bf6050c8b43e8a0a0cc352b44a2b8`.
7. Promote the two authorized candidate files once after all static and browser
   checks pass. Recheck production at the same viewports.
8. Update only the `index.html` output hash in the 37-row corpus manifest, while
   preserving all source identities and every other route hash. Seal a
   non-circular completion manifest and completion record.

## Stop conditions

Stop without production writes if the accepted navigation shell cannot be
preserved, if any non-authorized build member would change, if the direct SVG
would be rasterized, if candidate validation fails, or if a bounded local
browser server cannot be started and stopped cleanly.

## Required return

Return the candidate and production landing hashes, the exact download hash,
the corpus-manifest transition, build deltas, DOM and local-reference audits,
browser QA at all required widths, process shutdown evidence, and a
non-circular completion manifest. State explicitly that Supplementary Figure
S6 remains SVG.

