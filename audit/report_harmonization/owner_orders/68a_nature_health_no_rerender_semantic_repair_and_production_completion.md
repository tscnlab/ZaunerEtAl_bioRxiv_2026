# REPORT-018 owner order 68a: Nature Health no-rerender semantic repair and production completion

Date: 2026-09-02

Owner: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_FOR_ONE_NO_RERENDER_CONTINUATION`

## Authority and disposition

Order 68 completed its sole nested Quarto render successfully. The raw HTML and raw DOCX are preserved at their canonical endpoints and as byte-identical evidence copies. The writer stopped before semantic promotion, serving, capture, Word postprocessing, or browser QA because the raw HTML reused eight internal `gt` IDs across two embedded tables.

Independent R 4.6.1 audit accepts this as the same raw-render semantic condition already handled in the accepted 2026-09-01 manuscript package. The condition does not affect visible text, table structure or values, figures, citations, links, source, or science. A second Quarto render is prohibited.

This order authorizes only:

1. preservation and exact two-hunk correction of the task-owned final-HTML verifier;
2. one candidate-first execution of the already accepted mixed-`gt` semantic repair;
3. exact validation and one canonical HTML promotion;
4. continuation of the still-unconsumed HTML browser QA, display capture, Word postprocessing, DOCX QA, and final sealing stages already specified in Order 68.

## Controlling independent evidence

- independent disposition: `audit/report_harmonization/report018_order68_raw_semantic_stop_independent_acceptance.md`
  - SHA-256 `d349ff17de984bbb1140995c2e170a2a1f20c71bc825685203f32b000a2c1b84`
  - 3,836 bytes
- 16-row non-circular acceptance seal: `audit/report_harmonization/report018_order68_raw_semantic_stop_independent_acceptance_manifest.csv`
  - SHA-256 `0200d9480a4df536e741f05b205722c60907111aa9484e5e5bda58e8ff76bde1`
  - 2,953 bytes
- independent checker: `scripts/report_harmonization/check_report018_order68_raw_semantic_stop.R`
  - SHA-256 `b442ff754810d156f704843d0c3d1565782a39d8ee5e411399a320323d24c9f9`
  - 15,194 bytes
- 21-row independent check table: `audit/report_harmonization/report018_order68_raw_semantic_stop_checks.csv`
  - SHA-256 `0f3e557eef242b45674e93e8a3651b7f20d299ad1d6ffd3e39d01440ae477969`
  - 2,759 bytes

## Required preflight identities

Reproduce these immediately before any edit or candidate generation:

- raw canonical HTML and evidence copy:
  - SHA-256 `c9156f078af52713a71a58adda545e03687a8b206d164d4d548b93ebae9732ee`
  - 30,864,003 bytes each
  - `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html`
  - `audit/manuscript_nature_health/final_production_render_2026_09_02/failed_render_ZaunerEtAl2026_NatHealth_phase3_brown.html`
- raw canonical DOCX and evidence copy:
  - SHA-256 `b8eeca31794e06c7c2ec2d6a474ae812b77b2b8c2dcadf7d341e3b6178430cdd`
  - 9,872,181 bytes each
  - `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`
  - `audit/manuscript_nature_health/final_production_render_2026_09_02/raw_quarto_ZaunerEtAl2026_NatHealth_phase3_brown.docx`
- HTML preimage: SHA-256 `498bc0ad5e9d08841f48411e290ae7ec8912a7af89c8fa8397c44d3f46864d99`, 30,528,489 bytes
- DOCX preimage: SHA-256 `d3ffb9abb583d91d4dffffea69fce870987b59494c76c462f9dfa53b1bf53a02`, 52,450 bytes
- accepted repair wrapper: `audit/manuscript_nature_health/final_serial_render_2026_09_01/repair_mixed_gt_semantics.R`
  - SHA-256 `30fe707420758a2f0207c4601bb8343e3d63ae2b1bf6965aa05469283af8f0b1`
  - 7,275 bytes
- accepted semantic engine: `scripts/report_harmonization/repair_gt_html_semantics.R`
  - SHA-256 `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`
  - 17,747 bytes
- stopped verifier: `audit/manuscript_nature_health/final_production_render_2026_09_02/verify_final_html.R`
  - SHA-256 `285c0edaa3b98eb7fffa298b4f50fd76fb47daa266f156b0407730d28ea1804c`
  - 6,522 bytes

Also rehash every stable, non-output member of the Order 68 dispatch manifest. Reproduce the two output preimages from the retained evidence copies instead of requiring the now-rendered canonical endpoints to match their pre-render hashes. Require the manuscript QMD, nested profile, bibliography, CSS, source validator, capture implementation, Word postprocessor, `.Rprofile`, `renv.lock`, accepted navigation corpus, root website, and 37-route corpus manifest to remain at the exact Order 68 identities.

Run the central independent checker once and require its exact PASS token:

`REPORT018_ORDER68_RAW_SEMANTIC_STOP=PASS checks=21 duplicate_ids=8 candidate=8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac ledger=191 figures=20 tables=19 headers=2762 fragments=124 prospective_validator=7054f6da946edf858813378017dd606283dbdf0816e2bc41a8f7237fd681c55c R=4.6.1`

Use a narrow read-only process inventory. Require no competing process associated with this repository's R, Quarto, Pandoc, semantic repair, manuscript render, table capture, Word conversion, or loopback QA. Leave unrelated work outside this repository untouched.

## Exact task-verifier correction

Before changing the task-owned verifier, retain a byte-identical durable copy of its stopped SHA-256 `285c0eda...` state within the existing Order 68 evidence root.

Apply exactly two hunks to `verify_final_html.R`:

1. Replace the `figure`-element-only selector with selection of all nodes carrying an ID, followed by filtering against the existing exact `expected_figures` vector. Preserve the vector and require exact DOM order. This recognizes the three main Quarto `div` figure endpoints and 17 supplementary `figure` endpoints without admitting any unlisted endpoint.
2. Replace the assertion that the self-contained HTML has zero script and stylesheet resource attributes with an assertion that every nonempty such URI starts with `data:`. Preserve the existing image requirement that every image starts with `data:image/`.

Do not change any other line. The required postimage is:

- SHA-256 `7054f6da946edf858813378017dd606283dbdf0816e2bc41a8f7237fd681c55c`
- 6,657 bytes

Require R 4.6.1 parse PASS, Air 0.4.1 PASS, an exact two-hunk diff, and reverse substitution to the stopped SHA-256 `285c0eda...` file.

## One semantic candidate and one HTML promotion

Create one new semantic candidate and ledger in the existing Order 68 evidence root. Run the unchanged accepted repair wrapper exactly once against the raw canonical HTML. It must target only:

- `tbl-plan-h01-metric-synthesis-candidate`; and
- `tbl-plan-person-level-synthesis-gt-candidate`.

Require the exact deterministic outputs:

- candidate HTML SHA-256 `8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac`, 30,881,505 bytes;
- ledger SHA-256 `225b5d37818850dca9b6cb5dcf39d78e5fd76c1e79745bbf09f981a70a980287`, 70,290 bytes;
- 191 rows, with 47 `id` and 144 `headers` substitutions; and
- exact reverse to raw HTML SHA-256 `c9156f078af52713a71a58adda545e03687a8b206d164d4d548b93ebae9732ee`.

Require the normalized non-`id` and non-`headers` DOM to remain identical. Require zero duplicate document IDs, 19 native `gt` tables, 2,762 within-table header tokens resolving exactly once, 20 exact figure endpoints in source order, 124 resolved internal-fragment links, embedded images, and only `data:` script and stylesheet resources.

Run the corrected final-HTML verifier once against the candidate and require:

`FINAL_HTML_STRUCTURE=PASS tables=19 figures=20 authors=28 ids=582 header_tokens=2762 internal_fragments=124 bytes=30881505 R=4.6.1`

Only after all checks pass, replace the canonical HTML once with the exact candidate bytes. Keep the raw HTML evidence copy and ledger. Rehash the canonical HTML to the exact candidate identity. Do not rerun Quarto and do not regenerate the candidate.

## Resume the unconsumed production stages

After canonical HTML promotion, continue the unchanged downstream contract from Order 68:

1. run the strict source validator only if its post-render invocation has not already been durably recorded; otherwise preserve and rehash its existing PASS evidence;
2. require zero symlinks below `manuscript/R0_NatHealth/_output`;
3. serve only that output directory on one unused high port bound to `127.0.0.1`;
4. inspect the exact manuscript route at 1,440 by 1,000, 708 by 1,000, 390 by 844, and a 200-percent-equivalent view;
5. inspect every main and supplementary table and figure, wide-table scrolling, citations, internal links, and end matter, rejecting any page overflow, clipping, overlap, missing content, broken link, or page-attributable console error;
6. run the frozen Node capture implementation exactly once to capture all 19 accepted tables and all 17 supplementary figures into the task-owned evidence root;
7. require the exact selector set, nonblank images, and preserved visible table text and order;
8. run the frozen Word postprocessor exactly once from the preserved raw Quarto DOCX and accepted capture manifests to one candidate final DOCX outside the canonical output path;
9. require 27 bounded sections, 13 landscape table ranges, 52 drawings, zero native `gt` tables, zero one-cell float wrappers, all three main and 17 supplementary figures exactly once and in topic order, landscape substantive tables, portrait figures, and captions kept with displays;
10. promote the candidate DOCX once only after structural PASS; and
11. render the final DOCX to page images and inspect every page, preserving a page-level QA ledger and sufficient screenshots or contact sheets for independent review.

The expected 82-page count may change only if the complete page audit proves a content-preserving pagination difference. Reject blank defect pages, orphaned headings or captions, clipped or overlapping content, missing glyphs, split display-caption pairs, illegible tables, unexpected page orientation, duplicated or missing figures, or topic-order defects.

## Final stability and mandatory stop

Close the browser surface, stop the loopback server, and prove no listener remains. Rehash all frozen inputs, the raw HTML and DOCX evidence, final HTML and DOCX, semantic candidate and ledger, verifier preimage and postimage, capture manifests, conversion scripts, browser evidence, page QA, navigation corpus, and root website. The accepted 37-route `_build/nathealth` corpus and manifest must remain byte-identical.

Write one completion record and one unique, non-circular final evidence manifest excluding itself. Return exact hashes and byte counts for the final HTML, final DOCX, raw DOCX, semantic ledger, corrected verifier, capture manifests, HTML visual QA, DOCX page QA, lifecycle record, completion record, and final evidence manifest.

Stop once on any genuinely new semantic, table, figure, citation, link, capture, Word-layout, environment, process, or preservation defect. Do not patch, recapture, reconvert, or rerun any failed stage inside this order. Do not run Quarto, Pandoc, an analysis, a scientific builder, a root website render, a standalone supplement render, a full-project render, a second HTML repair, or a second Word postprocessing attempt. Do not edit source, claims, values, bibliography, CSS, profile, package state, lockfile, `_build/nathealth`, or the 37-route corpus manifest. Do not commit, push, upload, submit, or contact the journal.

The next gate is independent acceptance of the paired final manuscript HTML and DOCX, or independent disposition of one genuinely new fail-closed condition.
