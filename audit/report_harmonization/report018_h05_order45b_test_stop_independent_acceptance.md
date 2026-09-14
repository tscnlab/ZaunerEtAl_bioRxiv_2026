# REPORT-018 H05 order 45b test-stop independent acceptance

Date: 2026-08-20

Disposition: **fresh companion integration accepted for no-rerender visual finalization**

Independent R 4.6.1 verification reproduces:

- owner stopped record SHA-256
  `a7c6839c4cec431dd6a956a82aff7548bf50e0c61ccac4b82999a8348e7864d6`;
- 41-row non-circular owner manifest SHA-256
  `33f0fe8bb0de17b0ccf9c89d216fe8b5b273337e965888302fce4e4799af239c`,
  41/41 exact and unique;
- repaired companion QMD SHA-256
  `843f60f890daac0e41c6655bc365ab0325e3f582e011610469a799946b2f2811`;
- fresh companion HTML SHA-256
  `856dbd21920b65dce6437172022d0e6130410d9e357259a4d50aa1f6fe2461d8`;
- live-exact 142-row preparation manifest SHA-256
  `49ab691f8d86852ec034ed49ffa773032c3acdf3312d7fef5de7849c9ff07d80`.

The one render completed all 57 knitr cells and Pandoc under R 4.6.1 and
Quarto 1.9.37. The semantic hook repaired 22 tables through 253 ID and 970
header substitutions, 1,223 total. Its exact reverse recovers pre-semantic
SHA-256
`0c0517a89cf3cf22d5fe976d7c804b102a39e6e20ff0395327022e02e56e87ac`,
and reapplication recovers the accepted final HTML byte-for-byte.

Independent static checks pass for 22 native gt tables, three figures, one
top-down Mermaid, all captions and alt text, unique document IDs, 1,925 table
header tokens, 26 document ID references, every internal link and anchor,
active navigation, all nine country-coded sites, and zero embedded execution
errors or warnings. The 836-file build has zero symlinks and only the bounded
target HTML, source-identical website QMD, search, and sitemap content changes.
The accepted H05 result and every scientific artifact are unchanged.

Finding H05-45B-TEST-001 is accepted as a nonblocking stale source-test
contract under REPORT-018. The shared verifier and H05 test require the
literal `.html` path in QMD source. The accepted dynamic `.qmd` link is correct,
renders to the result HTML, and resolves. No reader-facing defect or scientific
discrepancy exists. The shared test cleanup is deferred and neither test nor
source will be edited in the render-completion queue.

The project navigation, reader-link, and country-site tests pass for all 37
reader sources. The navigation test refreshed the harmonizer-owned corpus
manifest to SHA-256
`73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334`.
This is recorded as harmonizer test setup, not an H05 owner mutation.

One no-rerender continuation may now perform the deferred secure-loopback
visual QA against the existing accepted HTML, then prove post-QA build and
protected stability. It must not edit or rerun the stale test, rerender any
page, or modify source, output, science, profile, package, lockfile, ledger, or
manuscript content.

