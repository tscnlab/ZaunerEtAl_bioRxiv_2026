# Nature Health manuscript production lifecycle

Date: 2026-09-02

## Scope

This record covers the bounded production of the author-reviewed Nature Health manuscript from the frozen Quarto source. It does not authorize or record any scientific refitting, data transformation, full-project render, submission, upload, or change to accepted report sources.

## Frozen manuscript inputs

- Quarto source: `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd`, SHA-256 `9853f0bd462c8c6ed0e74dae8a7bae9a570fdc8ba6f13644dfbc0d88109657d0`.
- manuscript profile: `manuscript/R0_NatHealth/_quarto.yml`, SHA-256 `2aa2911f13d4532aa8ce98e38363a5c92b1d2bdc025b3c8bba49950077e76b33`.
- merged bibliography: `manuscript/R0_NatHealth/references_merged.bib`, SHA-256 `4972d8011fd9ccd2067e5e583a9bbc8846a825218ca7b4b574bcc6bd4bea1c06`.
- manuscript display stylesheet: `manuscript/R0_NatHealth/manuscript_displays.css`, SHA-256 `5974136901a8325e831e932a3999382532acfcf94508f428b23bc8f5de3ffc98`.

The R 4.6.1 source validator passed before and after production with a 150-word abstract, exactly 4,500 words across the Introduction, Results and Discussion, 114 bibliography entries, 91 resolved citation keys, 31 internal link targets, and 519 protected ordered numeric tokens.

## Quarto render

One manuscript-only Quarto render was run from `manuscript/R0_NatHealth/`. The raw outputs were preserved before any bounded format repair:

- raw HTML: `failed_render_ZaunerEtAl2026_NatHealth_phase3_brown.html`, SHA-256 `c9156f078af52713a71a58adda545e03687a8b206d164d4d548b93ebae9732ee`;
- raw DOCX: `raw_quarto_ZaunerEtAl2026_NatHealth_phase3_brown.docx`, SHA-256 `b8eeca31794e06c7c2ec2d6a474ae812b77b2b8c2dcadf7d341e3b6178430cdd`.

The raw HTML reproduced Quarto's known duplicate internal `gt` identifiers. Under Order 68a, a no-rerender semantic repair changed identifiers and matching references only. The repair ledger is `semantic_repair_ledger.csv`, SHA-256 `225b5d37818850dca9b6cb5dcf39d78e5fd76c1e79745bbf09f981a70a980287`. The corrected verifier passed.

## HTML completion

The canonical HTML is `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html`, SHA-256 `8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac`.

Browser QA covered desktop, intermediate, phone, and a 200% zoom-equivalent viewport. It confirmed 19 visible tables, 20 loaded figures with captions and alt text, 204 resolved internal links, 86 citation links, 91 reference entries, no unresolved links, no console-error markers, and no page-level horizontal overflow. It also directly checked the author's requested left-aligned Table 1 caption, wider explanatory column in Supplementary Table S2, and smaller displayed Supplementary Figure S3.

## Word completion

Because native `gt` to Word conversion did not preserve the approved table styling reliably, the canonical HTML tables were captured once as 32 high-resolution PNG parts covering all 19 tables. Seventeen supplementary figures were captured from the same HTML. Exact selector, order, file-count, dimension, checksum, and nonblank-image checks passed. This choice preserves the visual table hierarchy, colours, widths, and base text size in Word, while the HTML remains the accessible semantic-table version.

The Word postprocessor replaced native tables with these images, applied portrait or landscape sections according to display needs, retained captions and alt text, and kept figures and tables at the end of the manuscript. The first 82-page candidate was fully inspected. A genuine readability issue was found only for the tall Supplementary Figure S8. Under the coordinator's bounded continuation, the same source bitmap was displayed across two portrait pages using exact OOXML crops. Panels A to C appear on the first page and panel D plus the unchanged full caption on the continued page. No Quarto rerender or image recapture occurred.

The canonical DOCX is `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.docx`, SHA-256 `07ff074d4bd4124656063f69a2437b4c646a8240ad771ce94d30339f41d0604c`.

The final structural audit passed with 27 sections, 13 landscape ranges, 53 inline images, zero native tables, complete alt text, exact S8 crop rectangles, and all required headings and captions. LibreOffice rendered the document to 83 pages. Fifty-one pages are portrait and 32 are landscape. Eighty-one pages remained byte-identical to the fully reviewed first candidate. The two new S8 pages were inspected at full resolution, and focused checks also confirmed the final S17, Table S15, and robustness pages.

## Final stability boundary

All 37 rendered HTML routes in `audit/report_harmonization/phase4_corpus_manifest.csv` still match their accepted hashes. Sixteen shared source files have later edits in the active shared checkout. These are recorded as informational drift only because the frozen manuscript integration used the accepted rendered HTML corpus, which remains unchanged. No later shared source was silently substituted into the manuscript render.

There are no symlinks under the manuscript directory or final evidence directory. The bounded loopback server was stopped after QA. No repository-wide render was run.
