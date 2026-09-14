# REPORT-018 Order 70d candidate IDREF-cardinality stop

Date: 2026-09-02

Status: `FAIL_CLOSED_AFTER_CANDIDATE_TRANSFORMATION_BEFORE_BROWSER_OR_PRODUCTION`

The single authorized Order 70d candidate-mode continuation transformed the retained candidate and copied the exact corrected DOCX. Static validation then stopped on the fixed expectation `nrow(idrefs) == 2775L`.

The candidate contains 2,776 references under the implementation's complete audit vocabulary, and all 2,776 resolve uniquely. The breakdown is six `aria-labelledby`, six `aria-describedby`, one `aria-controls`, 2,762 `headers`, and one `data-bs-target` token. The 2,775 value corresponds to the standard IDREF attributes before the implementation adds its separately audited Bootstrap target. There are zero unresolved tokens, 593 IDs, and zero duplicate ID values.

The candidate build contains 893 regular files and zero symlinks. Its transformed landing page is SHA-256 `c8abe2f9fbfcbe2fc8b4e39e149797a6dc2d74a5735337ed2399fb6e5814eb21`, and its copied DOCX is the exact accepted `6cd592391f720829ed278a35e81c854ee7fd54eca6a4a4e664faad7b37310f91`.

No browser QA or promotion occurred. No production path changed. The production landing page remains SHA-256 `600b7a3d5eb244e99e841b5c4e3b6c1c7440004303fe0e9da1bc0c874add1184`, the corpus manifest remains `5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b`, and the production DOCX remains absent.

The discrepancy is validator-only and confined to whether the separately collected Bootstrap target is included in the IDREF total. Per the Order 70d stop rule, no patch, retry, browser run, promotion, render, or scope expansion was attempted pending central disposition.
