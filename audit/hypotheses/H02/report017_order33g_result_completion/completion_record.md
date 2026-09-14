# H02 order 33g result completion

Date: 2026-08-20

Status: **PASS, ready for independent acceptance**

## Scope and environment

This completion used R 4.6.1 and the existing synchronized project library. It edited only `tests/hypotheses/H02/test_h02_reader_report.R` and created new evidence under this order-33g directory. No Quarto command, model fit, prediction, bootstrap, simulation, Shapley or dominance computation, preparation-test execution, QMD edit, HTML edit, profile edit, or build regeneration occurred.

The sole test transition is exact:

- final reader-test SHA-256: `479a702e7c5c52cf85e8591300a30c759da945f4c65ecb28cad67bb2e6752d3f`, 16,545 bytes;
- reverse-substituted SHA-256: `0b044d2995645f6cfa50e28e2bdf330b8801002761a84520b169a1a3eb6771db`, 16,044 bytes;
- nine authorized transformations, with every other byte preserved.

The accepted result source remains `4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d`. The fresh result HTML remains `736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9`, 296,427 bytes. The held companion source remains `92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1`, and the held companion HTML remains `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa`.

## Commands and tests

The only project tests executed were:

```text
Rscript --vanilla tests/hypotheses/H02/test_h02_reader_report.R
Rscript --vanilla tests/hypotheses/H02/test_h02_paired_placement_display.R
```

Both exited 0. The reader test reported `All H02 reader-report tests passed`; the paired-placement test reported `All H02 paired-placement display tests passed`.

`tests/hypotheses/H02/test_h02_preparation_report.R` was not executed and remains byte-identical at SHA-256 `ead7a55246a2625b1382acc302b6004892dbf7f7830285f2bae830cb0859d3f8`.

## Nonvisual contracts

All checks passed against the unchanged fresh HTML:

- 15 native gt tables and five figure endpoints occur in the accepted order;
- every endpoint has exactly one nonempty caption;
- document IDs are unique;
- all 530 table-header references and all 552 document ID references resolve;
- 22 preregistration links resolve to 18 accepted anchors;
- all nine country-coded site labels pass;
- all five figure sources and alt texts pass;
- the semantic ledger reverses the final HTML to `9c3d2c9fe062756cd2a3454522bf440cc12153999621557a61eb19fa073a8e84`, 284,147 bytes, with identical normalized DOM and visible text;
- the retained 210-path protected reconciliation remains exact;
- there is no unresolved cross-reference, rendered warning, rendered error, or stderr marker.

Exactly one internal reader link is unresolved: `../../supplementary_information.html`, labelled `Supplementary information`. It is the accepted shared DOC-001 hold. No second unresolved link or forbidden internal target occurs.

## Visual QA

A read-only static server was rooted exactly at `_build/nathealth` and bound only to `127.0.0.1:50880`. The exact page inspected was `http://127.0.0.1:50880/notebooks/hypotheses/H02.html`.

The page passed at 1440 x 1000, 708 x 1000, and the 720 x 500 200-percent-equivalent viewport. At every size:

- page width did not overflow;
- all 15 tables remained usable and within the page;
- all five figure endpoints remained contained and unclipped;
- prose, captions, axes, labels, legends, symbols, panels, callouts, and navigation remained legible;
- no browser console warning or error occurred.

All five stored PNG figure sources were also inspected directly at their intended output size. The three disclosure controls opened successfully. The two model-check disclosures exposed their diagnostic figures, and the registration-topic disclosure exposed its linked content.

The temporary browser tab was closed, the viewport was reset, and the server was stopped immediately after QA. `lsof` found no listener on port 50880 and `ps` found no process 67689. The only HTTP 404 was an optional browser request for `favicon.ico`; it produced no console warning or report defect.

## Stability and held state

Previsual and postvisual accepted-path inventories are byte-identical at SHA-256 `9fbf8ebdd1c0de12bfb8d4345a86bafdb55c9d2233001c924c6236cf9b60b87a`, with 218 rows. Previsual and postvisual build inventories are byte-identical at SHA-256 `a5c0dcbedd6f01d6f0daf0296e5a960be0b93561017e1915549d7da6def9512a`, with 1,124 rows and no symlinks.

The held preparation manifest has exactly its four authorized current mismatches: the fresh H02 result HTML, profile, companion QMD, and result QMD. This state is deferred to the later companion render.

The first postvisual evidence-harness comparison stopped because R's `identical()` distinguished in-memory empty strings from the same fields read back as CSV `NA`, even though both pre/post CSV pairs were already byte-identical. Only the new evidence harness was corrected to compare exact file hashes. The final postvisual run passed 42/42 dispatch rows, 218/218 accepted paths, all 1,124 build members, zero symlinks, and the expected four held companion mismatches.

The owner-scoped `git diff --check` passed. A global check reported only pre-existing trailing whitespace in unrelated shared audit files, which was left untouched.

## Conclusion

No new H02 render-blocking, semantic, link, protection, or visual defect was found. Order 33g is complete and ready for independent acceptance. The next shared target remains coordinator-owned.
