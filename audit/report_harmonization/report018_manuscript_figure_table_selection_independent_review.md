# REPORT-018 Nature Health figure and table selection independent review

Date: 2026-08-31

Status: `STOPPED_VISUAL_ONLY`

## Independent disposition

The current selection source, generated assets, target HTML, scientific selection boundaries, and structural contracts independently reproduce. The package is not yet accepted as a complete reader-facing planning page because the current HTML has document-level horizontal overflow at both required narrow widths.

No planning-package file, hypothesis source, scientific artifact, accepted reader report, model, manuscript source, or production figure was changed by this review.

## Reproduced current identities

- `audit/manuscript_nature_health/manuscript_figure_table_selection.qmd`: SHA-256 `7bf0c39745e6828201e955514712faea0a26031edb26606f165830ca04cb66ee`, 48,022 bytes.
- `audit/manuscript_nature_health/manuscript_figure_table_selection.html`: SHA-256 `4639b6f27608cb818bb4125851d7b297b64fa8e1d7f1fcabd463bb5c1e0d73d1`, 27,417,440 bytes.
- `scripts/report_harmonization/build_manuscript_figure_table_selection.R`: SHA-256 `52fcf891e153c45587e247c658f906b6e586a9082db4ecde6a8363ebb256e40f`, 64,834 bytes.
- `scripts/report_harmonization/check_manuscript_figure_table_selection.R`: SHA-256 `5a308c34057d12abe181e028555291437c781fa6108fb60298a6a157f8246cd9`, 15,285 bytes.
- Current 31-row asset manifest: SHA-256 `a6cb974b2393f55827fd98b7c153bedefb592fed9fb179f815540674b71a8647`.
- Current 20-row semantic summary: SHA-256 `d5d87330b0234ed444a01c30466985a91d23381053338b29eed56c5f149aebef`.
- Current 1,174-row semantic ledger: SHA-256 `c2fe2c0678e6cfc7d2fd22ab4a866cb0e678cff3731641536d7d28fc936ce153`.
- Current 32-check record: SHA-256 `6d1fde7fc15627e82ed0d43359e319ea913e126b0ba6b559e51499324e22de4e`.

## Byte-exact replay

The complete builder was run under R 4.6.1 in `/private/tmp/nathealth-selection-independent.QC73Ub`, against read-only links to the held scientific inputs. It returned 13 outputs, 22 tables, 13 figures, 31 assets, and 1,174 semantic substitutions. Every generated package member was byte-identical to the held package.

The single selection target was rendered in that temporary tree with a fresh writable Deno and XDG cache. The rendered HTML was byte-identical to the held HTML. The complete checker then passed 32 of 32 checks, including 26 tables, 19 native `gt` tables, 40 embedded images, and 3,909 resolved header tokens.

## Scientific and selection findings

- The main display sequence is exactly Figures 1 through 4 followed by Tables 1 through 3.
- Supplementary Table S2 contains exactly 13 populated accepted counts. Each value is a direct nonmissing scalar from `audit/descriptives/sample_count_contract.csv`; no new sample count was derived.
- The H01 MDER row is correctly fail-closed. The descriptive distribution uses the accepted mean of viable minute-level ratios, while all eight H01 model cells remain visibly pending because the accepted H01 model used the superseded ratio-of-integrals definition.
- The four Brown cross-window results remain in a separate Supplementary block. The within-participant claims remain withheld, and the between-participant results retain their limitations and noncausal wording.
- Production repairs listed by the selection package remain owner-gated. This review does not authorize any Brown, H03, H04, H06_daily, H09, H10, H01, manuscript, or reader-report edit or render.

## Historical record classification

The root 37-row package manifest and the two prose QA files are earlier package snapshots, not current acceptance evidence. The root manifest is only 24 of 37 live-exact. The two prose QA records describe earlier table, image, and HTML states. They remain byte-identical historical evidence and were not rewritten.

## Blocking visual finding

Desktop inspection at 1440 by 1000 pixels passed with no page overflow, 40 of 40 images complete, a fixed right table of contents, and no browser console warning or error.

At 708 by 1000 pixels, the document content width was 693 pixels and the document scroll width was 797 pixels, producing 104 pixels of document-level horizontal overflow. At 390 by 844 pixels, the corresponding widths were 375 and 797 pixels, producing 422 pixels of overflow. The initial display-order table, the unwrapped Brown main Table 2, and the unwrapped Supplementary Table S9 are not contained within local horizontal scrollers. Other wide `gt` previews already use local `overflow-x: auto` containers.

This is a planning-page presentation defect only. It does not change any selected result or scientific value. It blocks final page-level acceptance.

## Required bounded recovery

A future owner order may make only the following planning-page changes:

1. Contain the three unwrapped wide tables in local horizontal scrollers using the same accessible pattern already used for the accepted table previews.
2. Preserve every table value, label, display order, caption, link, scientific boundary, selected asset identity, and H01 MDER gate.
3. Render only `manuscript_figure_table_selection.qmd` once in a temporary or task-owned evidence boundary.
4. Repeat the complete 32-check suite and browser QA at 1440 by 1000, 708 by 1000, and 390 by 844 pixels, requiring zero document-level horizontal overflow and working local table scrolling.
5. Reseal a current non-circular package manifest and a current QA record. Preserve the three historical records above as historical evidence.

Until that bounded recovery is independently accepted, production owner repairs may remain queued for coordination but must not be dispatched on the authority of this planning-page review.

## Loopback teardown

The independently rendered HTML was served as the sole file from `127.0.0.1:53762`. The QA tab was closed, the viewport override was reset, the server was stopped, and `lsof` found no listener on the port. The held package identities remained exact after QA.
