# REPORT-018 H04 order 43 static-verifier stop: independent acceptance

Date: 2026-08-20

Disposition: **ACCEPTED AS A QA-HARNESS COMPATIBILITY STOP.** The H04
companion render and bounded integration outputs are preserved, but companion
acceptance remains pending static and visual QA.

## Independent verification

The order-43 owner return is internally consistent:

- the sole H04 companion render exited 0 under R 4.6.1 and Quarto 1.9.37;
- the semantic hook returned `REPAIRED` for 37 native gt tables, 288 IDs,
  1,146 `headers` associations, and 1,434 reversible substitutions;
- the fresh companion HTML is
  `e5f0861ef1b1e4accf4e6a924155c6ec5ce77a9c9865d6dc7bf5427e3de860ea`,
  1,226,014 bytes;
- the unchanged H04 preparation-manifest helper ran once, synchronized the
  website QMD byte-for-byte to the accepted authoring QMD, and produced a
  276-row unique live-exact preparation manifest at
  `f2d251b50e9fa61caa978d7ce155a6743f09f2667b0f827ffcbfc281b2ac706e`;
- the unchanged full H04 preparation test ran once and passed; and
- the accepted H04 result HTML remains byte-identical at
  `da5f7f7195da843e46014d4796d35381f74d223ba79c37bb78fb8ce6dfa67c9f`.

The independent static verifier then stopped at its first Ruby-runtime
incompatibility. The installed system Ruby is 2.6.10. The verifier uses
`Array#tally`, which is unavailable in Ruby 2.6. Inspection also identifies one
later use of `Enumerable#filter_map`, which is likewise unavailable in Ruby
2.6. Both constructs are QA-harness implementation details. They do not alter
or evaluate scientific values and do not establish a document defect.

The original verifier remains
`/private/tmp/h04_order43_static.rb`, SHA-256
`acbc9a68152f8099f8a303ddd0f3ff577ed77c992bf2e0bdfb357340e2934acd`,
15,785 bytes. The order-43 stop record and its non-circular evidence manifest
remain exact. The semantic ledger and summary remain retained under
`/private/tmp/H04-order43-semantic.9Pplpd`.

## Disposition

One no-rerender continuation may copy the verifier and change only the two
Ruby-version-incompatible constructs to semantically equivalent Ruby 2.6
forms. It must preserve the original verifier and all order-43 evidence,
execute the corrected static verifier exactly once, and proceed to secure
loopback visual QA only if the complete static gate passes.

No Quarto command, helper execution, R test execution, QMD or HTML edit,
scientific computation, artifact regeneration, profile or ledger edit,
package or lockfile change, commit, push, upload, deletion, or later render is
authorized by this acceptance. H05 and every later render remain held.
