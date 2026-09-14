# REPORT-018 H06 order 47d test-stop no-rerender concurrence

Date: 2026-08-21

Disposition: `CONCUR_NO_RERENDER_AFTER_DURABLE_STOP_SEAL`

## Finding

The unchanged H06 preparation test stops on one classification-stale source assertion:

```r
grepl("../../../notebooks/hypotheses/H06.html", qmd, fixed = TRUE)
```

The accepted companion source contains exactly three dynamic links to `../../../notebooks/hypotheses/H06.qmd`, including one link to `#h06-preregistration-deviations`, and contains no hard-coded internal result-HTML link. The fresh rendered page correctly resolves those source links to the accepted H06 result HTML and its registered anchor.

This is a test classification mismatch. It is not a source, scientific, semantic, navigation, or rendered-page defect.

## Independently reproduced post-render state

The central checker is `scripts/report_harmonization/check_h06_order47d_test_stop_concurrence.R`, SHA-256 `6cf58b221ae52a1641e1030a88859aeb31f4d9043aa38a5b1b9547e40d26dac8`, 13,214 bytes.

It ran under R 4.6.1 and verified:

1. Twelve post-render authority and integration pins are exact, including the accepted result, companion source, fresh companion HTML, unchanged test/helper/contract/profile, rebuilt manifest, and external semantic evidence.
2. The authoring and build companion QMDs are byte-identical at `f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`.
3. The fresh companion HTML is `f9a4f51db555454a2e7cd0ea70895978b71016e6bd2c7310ae5033ad3c7ed378`, 851,041 bytes.
4. The dedicated helper output is a unique, non-circular, live-exact 411-row manifest at `a3bd413daf9e154d78f32e49caea0697303c8d86ce387892ab081b06ae8b6bbc`, 103,739 bytes.
5. The source contains exactly three dynamic result-QMD links and zero hard-coded result-HTML links. The unchanged test contains exactly one stale result-HTML literal.
6. The HTML contains exactly 30 native gt tables, three figure endpoints with nonempty alt text, and one top-down `flowchart TD` Mermaid.
7. The semantic evidence reports `REPAIRED` with 169 ID substitutions, 816 `headers` substitutions, and 985 total reversible substitutions. All 1,142 table-header tokens resolve exactly once within their own table to a `th` element, and document IDs are unique.
8. Internal links and the result anchor resolve, the H06 preparation navigation entry is active, all nine country-coded study sites are present, and no forbidden local/build link, embedded problem node, unresolved cross-reference, or build symlink is present.
9. Air formatting and scoped diff checks pass.

No source, test, helper, manifest, profile, HTML, scientific artifact, or build output was changed during central verification.

## Authorized continuation

After the owner first seals the current stopped state durably, the H06 owner may resume once without a rerender and without editing or executing the stale test. The stop seal must pin the fresh HTML, unchanged source/test/helper/profile/result, 411-row manifest, and the semantic summary and ledger, either at their current absolute evidence paths or as byte-identical durable copies.

The continuation may only:

1. verify the three dynamic source links and their rendered result/anchor targets;
2. complete the 30-table, three-figure, TD-Mermaid, semantic, caption, alt-text, source-data, navigation, country-label, no-error, protected-identity, and build-delta checks against the existing HTML;
3. perform the already authorized secure-loopback desktop, 708-pixel, 200-percent-equivalent, and exported-output QA;
4. stop the listener, prove teardown and post-QA stability; and
5. return one non-circular acceptance or one consolidated genuine page-defect stop.

The unchanged preparation test remains historical evidence and is deferred. It must not be edited or rerun in this continuation.

No Quarto render, QMD execution, source/helper/test/manifest/profile edit, scientific computation, artifact regeneration, result-page change, H06 daily render, later render, full-project render, package or lock change, commit, push, or upload is authorized.

There is no central blocking finding. H06 daily and all later renders remain held until independent H06 companion acceptance.
