# REPORT-018 Order 69 reference-DOCX Word correction dispatch

Date: 2026-09-02

Recipient: Nature Health Writer task `019ffb39-372e-7262-bfac-192751fd0e63`

Status: `SEALED_FOR_SINGLE_DISPATCH`

Order 69 authorizes exactly one nested-profile `reference-doc` addition, one
focused repair of the accepted Word postprocessor's final-section geometry,
one DOCX-only manuscript render, one postprocessing pass, and complete
structural and page-by-page DOCX verification. It does not authorize HTML or
website rendering, scientific execution, display recapture, or any write below
`_build/nathealth`.

- controlling order:
  `audit/report_harmonization/owner_orders/69_nature_health_reference_doc_word_only_correction.md`
  - SHA-256 `6d0a9dd39dd969f99fc97853aaf0070da0a42739c50d092c777a4bcbbbdd051e`
  - 12,869 bytes
- non-circular dispatch manifest:
  `audit/report_harmonization/report018_order69_reference_doc_word_dispatch_manifest.csv`
  - SHA-256 `8e1f2cddb0741afe0ffdd9037b79d957e2b0bb372cd1370994efa2ad06a54244`
  - 3,627 bytes
  - R 4.6.1 verification: 24/24 exact, unique, and non-circular

The Writer was already active tracing the author-requested V0 Word behaviour.
This dispatch supplies the exact bounded authority and frozen identities for
that work. It does not authorize a duplicate render if a DOCX-only render has
already begun. The Writer must reconcile its current state against the order,
continue only if no render has started, and otherwise stop and report the exact
state for disposition.

Order 70 website integration remains held until Order 69 is independently
accepted.
