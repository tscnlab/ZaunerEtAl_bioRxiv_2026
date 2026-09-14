# REPORT-018 H11 Order 61 rendered integration stop

Date: 2026-08-22

Status: `FAIL_CLOSED_AFTER_SINGLE_RENDER_AND_SINGLE_TEST`

## Disposition

The sole authorized H11 companion render completed with exit status 0. The
dedicated preparation-manifest helper then completed once and wrote a live,
exact, unique, non-circular 283-row manifest. The corrected preparation test
was executed once and failed. Order 61 prohibits a retry or an unsealed source,
test, or shared-contract repair, so no visual QA was started.

The exact failing assertion was:

```text
Error: The preparation source does not link to its result HTML.
Execution halted
```

This is a contract inconsistency. The accepted preparation source contains two
dynamic links to `../../../notebooks/hypotheses/H11.qmd` and no hard-coded H11
result-HTML link. The exact Order 61 test correction therefore passes its
direct QMD-target assertion. The unchanged shared function
`verify_hypothesis_preparation_companion()` independently constructs and
requires `../../../notebooks/hypotheses/H11.html`, then stops when that literal
is absent from the QMD source. The central prospective preflight did not expose
this because its static replay replaced the generic verifier call with a
bounded result list.

## Completed one-attempt state

- Companion source remained exact at
  `3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816`,
  54,527 bytes.
- Source-identical build QMD is exact at the same identity.
- Canonical companion HTML is
  `58518d708e4feb6145bd8eb773b6b9ae4937afdf4a9e44e19d4215d9ca86162c`,
  771,221 bytes.
- Semantic repair completed for 26 native `gt` tables, 179 document IDs, and
  801 scoped header tokens. The raw-render identity was
  `da67448e631d633fca44b88b4cf66a9660dfbb3c66d9bc503b83a6597da9a319`,
  739,884 bytes.
- The rendered HTML has one main document region, 26 native `gt` tables, three
  figure images with nonempty alt text, 29 nonempty captions including the 26
  table captions, one top-down Mermaid diagram, and zero error or warning
  nodes.
- The dedicated helper wrote the exact 283-row live manifest at
  `3dbd92632afd32d392ef7ed456dc6f61d32e58ec73b03bd8d8e3451dfcb1afe8`,
  73,184 bytes. Its sole added provenance path is the accepted REPORT-016 H11
  test.
- The preparation test remains at the mandated postimage
  `4c31cb4120fdb0530609906df707c161b875c0859a917de61f3baa1050d24180`,
  10,561 bytes. Its one-line diff, R 4.6.1 parse, scoped whitespace check, and
  raw-byte reversal to the sealed preimage all pass.
- Air 0.4.1 reports the same pre-existing whole-file formatting changes for
  both the sealed preimage and required postimage. The authorized target line
  is absent from that formatter diff. No formatting mutation was applied.

## Preservation and lifecycle

All 193 scientific assets are byte-identical. The accepted result QMD and
HTML, both accepted H11 result tests, Stage 3 manifest, handoff, profile,
lockfile, coordination matrix, and held sensitivity QMD and HTML retain their
fixed identities. The user-owned Sass cache retains all 25 exact file
identities and ownership records. There are zero symlinks below
`_build/nathealth`.

The render changed only the canonical companion HTML, the source-identical
build companion QMD, `search.json`, and `sitemap.xml`. The authorized test and
direct preparation manifest also changed to their specified post-render
states. No source-side companion HTML or support directory exists. No H11,
Quarto, Pandoc, semantic-audit, helper, or loopback process remains.

## Required next authority

A separately sealed coordinator-owned order must reconcile the shared generic
companion verifier with the accepted dynamic QMD source-link contract, or
explicitly authorize a different source-link contract and exact downstream
test identities. The shared verifier, preparation source, and test must not be
changed under this stopped order. The companion visual QA, independent
result-and-companion acceptance, sensitivity battery, and all later targets
remain held.

