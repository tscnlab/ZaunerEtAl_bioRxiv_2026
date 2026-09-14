# Single redundant page-break correction and final review

14 September 2026. Owner: Writer task 019ffb39-372e-7262-bfac-192751fd0e63.
Status: RELEASED_FOR_ONE_POSTASSEMBLY_PAGINATION_CORRECTION only after the final non-circular dispatch manifest is sealed and the coordinator sends this order once to the verified-idle Writer. The complete Order010b return has passed independent R 4.6.1 replay under `writer010b_independent_completion_disposition.md`.

## Sole finding and scope

The Writer reviewed all 103 Order010b pages. The coordinator independently rehashed all page-review entries, replayed 114/114 structural checks and inspected selected complete pages and actual browser captures. The corrected tables, full-page figure placements and S15B labels pass. Served-browser inspection establishes S11's complete subtitle and notes; no S11 source correction is needed. S2's accepted type size and native document stay unchanged. S10/S12/S17 remain closed.

The remaining defect is one standalone heading on converter page 83: `Hourly routine analyses`. Its immediately following S9 heading has an additional direct page-break-before property. The coordinator independently inspected complete pages 83/84 and the exact OOXML. Both headings have `keepNext` via their styles; the second direct break unnecessarily separates them.

This order authorizes a post-assembly package edit, not a third assembly. Do not rerun the assembler, SVG embedder, Quarto, Pandoc, native-table exporter, figure producer, HTML transformation or browser review. No scientific computation, source/prose change, new inference, live promotion, website or lockfile change.

## Frozen preimage and exact transformation

Input is `audit/manuscript_nature_health/final_format_completion_2026_09_14/deliverables/Nature_Health_manuscript_round2.docx`, SHA-256 `d6dd418054fb8287efe2a4d49fc2d4adaf5a4a56b8a6ded503645ca34c599701`.

The complete immutable Order010b manifest is `audit/manuscript_nature_health/final_format_completion_2026_09_14/completion_manifest.csv`, SHA-256 `86ba7e46cdf106090d8ceaee3109d751dddc32f0f80d62da325ce6b7698583e2`, 271 members. Its handoff is `b3f8b4cd969f67b54d99f69f1d6530fc7bbd3ec90e7c725f4a56d560b6bd5a1d`; separate seal is `bb558fe7280183cf354b574d150374b0307a31fc89572828770555bd7bda28a2`. Reproduce the dispatch and all 271 members before any document write.

Change only the `word/document.xml` member. Select the unique top-level paragraph whose full visible text is `Supplementary Figure S9. Paired sensor-position hourly associations`, immediately following `Hourly routine analyses`. Remove its one direct empty `<w:pageBreakBefore/>` element. Preserve the first heading's page-break property, both styles and keep-next properties, all run/text content, all spacing, drawing extents and every other element/attribute. Do not alter a style definition or globally remove page breaks.

The coordinator's in-memory preflight fixes these raw UTF-8 identities, excluding any newline added only for displaying a fragment:

| Component | Before SHA-256 | Required after SHA-256 | Bytes before/after |
| --- | --- | --- | --- |
| word/document.xml | cb767c3e378f5b08cb7251fbe5f3a306bfe73ac0d10ec3e3b67bafc0fdd6e393 | 98e2924ccc67952165ada5b01d1904b40eacea517908480b47faf0a0e58ffb7f | 358303 / 358283 |
| Exact selected paragraph | 836b1402a77c1d81fbd0fbdd06992a3f05398a12fc6ab9d110f67035bb295ec8 | 046cac3f3089d05dd76487e1e415e5f088d9ea88aa6df856ca3392ea8492c311 | 272 / 252 |

Use the bundled Python ZIP/XML infrastructure or an equivalent deterministic R implementation. Preserve all ZIP member names and order and all other uncompressed member bytes, including every PNG/SVG, relationship, content type, style, settings and metadata part. Require exact reverse of document.xml and the selected paragraph, not a demand that recompressed ZIP container bytes must equal a different ZIP writer's output. The original DOCX itself remains retained byte-for-byte. Use the existing protected member/drawing checks rather than silently ignoring a mismatch.

## New output and finite verification

Create only `audit/manuscript_nature_health/final_pagination_completion_2026_09_14/`, with `code/`, `deliverables/`, `evidence/` and `qa/`, plus explicitly recorded fresh scratch as needed. The complete Order010b root and all earlier packages are immutable. Produce one new `deliverables/Nature_Health_manuscript.docx` and new provenance/verification evidence. The 19 native tables, integrated HTML and table/figure assets remain referenced from the accepted Order010b package; do not duplicate or regenerate them merely for this patch.

After exact input and complete owner-seal preflight, prepare one narrowly scoped patch script and parse it before execution. Record the document-skill operation marker immediately before document-authoring if required. Run the patch once. Verify all ZIP members, exactly one XML change, exact reverse, all original visible text/runs and relationships, 54 visible drawings, all 13 top-level section starts, author/affiliation/reference/declaration contracts and unchanged 19 native documents. The accepted integrated HTML remains SHA-256 `752ee27291e7970d28fc369c1ad3c396dc8894f483aa9864e65b9edea638df17`.

Run the packaged 150dpi `render_docx.py` once for the new main DOCX, serially, using the bundled soffice override and a fresh QA directory. Retain the PDF, every page image and command logs. The helper's documented PDF/ODT fallback is allowed within that one invocation; no desktop LibreOffice or installation. Do not require a hard-coded page count: removing the otherwise blank page will likely reduce it, but actual complete layout controls.

Bundled Python is `/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3`; renderer is `/Users/zauner/.codex/plugins/cache/openai-primary-runtime/documents/26.909.12148/skills/documents/render_docx.py`; the only permitted soffice is `/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/bin/override/soffice`. Resolve the workspace dependencies and read the active document-skill instructions before use. Never substitute desktop LibreOffice.

Inspect every resulting page, including the full S9 page and its preceding/following pages. Require `Hourly routine analyses`, the S9 heading, figure and caption to form a coherent sequence without a heading-only page or new clipping. Preserve the already accepted full-page layouts and every figure/table value. Recheck the actual final document and member hashes after QA. If a converter-only discrepancy recurs, use the existing identity-bound native/browser adjudication; do not reopen S2 or redraw the closed SVGs. A focused read-only native Word check is allowed only if needed to resolve actual final pagination, with no save/field/link update.

No further patch or assembly is released by this order. Return one complete non-circular package with the exact final DOCX, member-level delta/reverse proof, full-page review, protected identities and a final status. If the one exact change does not resolve the genuine issue, preserve it and report the complete finding instead of broadening the mutation.

Final document/site promotion and download bindings still require independent coordinator acceptance. This small layout amendment does not change the accepted scientific or editorial content, S2's font-size decision, or the approved single primary-sample Table 2.
