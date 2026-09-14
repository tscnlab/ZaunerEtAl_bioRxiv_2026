# REPORT-018 H05 order 45 stopped state

Date: 2026-08-20

Status: **stopped fail-closed before the first rendered table**

## Authorized execution

Order 45 is
`audit/report_harmonization/owner_orders/45_h05_companion_report018_render.md`,
SHA-256
`cea62287b1b6d6ce8375bae9aa6ed7cfda7a77c0e14c399e53bd12d43d007175`.
Its 26-row dispatch manifest is
`audit/report_harmonization/report018_h05_companion_order45_dispatch_manifest.csv`,
SHA-256
`2cee7fb4956382e81c466dad0f71853119b93967e6f807db2eeff278061bbdbf`.
R 4.6.1 verified all 26 rows exact, unique, and non-circular before execution.

The pre-render build inventory contained 836 files and zero symlinks. The
protected inventory contained 146 exact live paths. The fresh mode-0700
semantic-audit directory was
`/private/tmp/H05-order45-semantics.LsNvqo`, created at
2026-08-20T21:56:41+0200, and was empty before execution.

The sole authorized command was run once through the normal project profile:

`GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H05-order45-semantics.LsNvqo quarto render audit/hypotheses/H05/H05_analysis_preparation.qmd --profile nathealth`

Quarto reached knitr under R 4.6.1 after normal renv dependency discovery. It
stopped at cell 6 of 57, `tbl-h05-prep-input-identities`, with exit status 1:

`all(verified_inputs$Verification_code == "PASS") is not TRUE`

No retry, patch, helper execution, test execution, semantic repair, server, or
browser QA followed.

## Exact diagnosis

An R 4.6.1 read-only replay evaluated the 17 named result-input identities.
Sixteen match their frozen expected SHA-256 values. The sole mismatch is:

- input role: `h01_contract_source`;
- path: `scripts/hypotheses/H01/h01_contract.R`;
- frozen H05 producer identity:
  `9151f2ca8ef549d16df1465768ed5b33c0aa33b37dc315a13e06d795ba20de2e`;
- accepted current source identity:
  `dfa35f7c8a1ca8a1f2132c6930a8ac219c461ffac769a7423bf85522430da81a`;
- current size: 10,553 bytes.

The current H01 METRIC-011 gate and production tests explicitly preserve the
first identity as historical execution evidence and require the second as the
accepted live source. The H05 source-only order and H05 result integration
already accepted this shared-source transition outside the H05-owned
scientific artifacts. The stopped companion still applies a strict
current-file equality test to the historical H05 producer pin. This is a
provenance-classification mismatch. No H05 data, model, estimate, interval,
p-value, multiplicity result, diagnostic, table, figure, or scientific claim
changed during order 45.

## Preservation

The semantic-audit directory remains empty. The stale companion HTML and
website QMD remain respectively:

- `c44f4f77f4e2295f6b265ed9505c3c560361a7280562dd9ce1afce73149d5866`,
  839,152 bytes;
- `f8087740def5e4e75e5bf5eff82d9f58acf1865954a16919719a7280f3447bfc`,
  72,797 bytes.

The accepted H05 result HTML remains
`a088e105be1987508280e91b938142773c8fb9275f1e924ac1ec9958a9b199f1`,
640,855 bytes. The authoring companion and result QMDs, profile, helper, test,
preparation manifest, semantic tools, lockfile, and scientific artifacts retain
their dispatch identities.

The post-failure build inventory is byte-for-byte identical to the pre-render
inventory at SHA-256
`9fbb5e75e5f0d6d361e6aa402d92721457dd2bfb83d9b0fa13556081e2931cb9`.
The post-failure protected inventory is byte-for-byte identical to the
pre-render inventory at SHA-256
`31fe584aeefd13698453a4ecb2e4eb420b2ef184844b8ad634c8787dcd37e8d0`.

No Quarto, Pandoc, H05 knitr, semantic-hook, or HTTP-server process remains.

## Required disposition

A separate bounded provenance-only continuation is required. It must preserve
the historical H05 producer identity, pin the accepted current H01 contract
identity, fail on any other input mismatch, and verify H05-relevant registry
equivalence without refitting or changing a scientific artifact. Only after
independent acceptance may one new H05 companion render be released.

