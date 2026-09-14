# H02 order 33f result-render execution record

Date: 2026-08-20

Disposition: **FAIL CLOSED AFTER ONE SUCCESSFUL TARGET RENDER**

## Authorized execution

The sole render command was executed exactly once:

```text
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H02-order33f-semantics.Cux4Wg quarto render notebooks/hypotheses/H02.qmd --profile nathealth
```

The command used Quarto 1.9.37, R 4.6.1, the normal project `.Rprofile`, and
the activated project `renv` library. Knitr completed all 45 cells and Quarto
returned exit status 0. The output contained dependency-discovery notes only.
No package was installed or updated. No model was fit or refit, and no
prediction, bootstrap, simulation, resampling, Shapley, or dominance
calculation was run.

The final result target is
`_build/nathealth/notebooks/hypotheses/H02.html`, SHA-256
`736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9`,
296,427 bytes. The execution wrapper did not persist a command-level start
timestamp, so a full wall-clock duration is not reconstructed. The durable
filesystem timing evidence records a 40.768069-second interval from the first
target-resource write to the final HTML write. Exact available timestamps and
the two focused-test durations are in `render_timing_evidence.csv`.

## Semantic hook and structural audit

The post-render hook reported `REPAIRED`:

- pre-repair HTML: SHA-256
  `9c3d2c9fe062756cd2a3454522bf440cc12153999621557a61eb19fa073a8e84`,
  284,147 bytes;
- final HTML: SHA-256
  `736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9`,
  296,427 bytes;
- 15 tables, 152 IDs, 253 `headers` tokens, and 405 substitutions.

The retained 405-row ledger reverses the final HTML exactly to the recorded
pre-repair SHA-256 and byte count. The normalized document structure and
visible text are identical across the hook boundary.

The static rendered-page audit found:

- 15 of 15 native `gt` table endpoints passed;
- five of five figure endpoints passed;
- zero duplicate IDs;
- 530 of 530 table-header references passed;
- 552 of 552 document ID references passed;
- 22 of 22 preregistration links resolved to 18 unique anchors;
- nine of nine country-coded study-site labels passed;
- 99 of 100 reader links passed.

The audit-only semantic script first stopped on an empty second argument to
`as.numeric()`. Only that evidence script was corrected. Its next execution
completed the semantic reversal and structural outputs, then stopped on the
one broken local build link described below. No authoring source, scientific
artifact, or rendered output was changed by this harness correction.

## Preservation and build delta

All 210 protected paths are byte-identical to the pre-render inventory. Both
H02 QMDs, all tests, the three current H02 manifests, handoff, held companion
HTML, profile, semantic wrapper and engine, lockfile, source data, models,
estimates, intervals, diagnostics, figures, and scientific artifacts are
preserved.

The scoped build changed in 21 classified ways, all allowed by the target
render contract: one result HTML, two normal site-index files, four
source-identical resource copies, two created target-resource directories,
one byte-identical target-resource refresh, one byte-identical shared-asset
touch, and ten directory modification-time touches. There are no symlinks and
no unclassified content changes. Post-render and post-inspection build
inventories are byte-identical.

## Focused tests and consolidated defects

The paired-placement test passed. The complete reader test stopped at its
first post-render historical-mismatch assertion. Read-only inspection shows
that three assertions in its opening contract are stale after the authorized
target render:

1. The preparation-manifest mismatch set now correctly also contains the
   rendered H02 HTML.
2. The worker-manifest mismatch set now correctly also contains the rendered
   H02 HTML.
3. The test still requires the pre-render stale HTML SHA-256 rather than the
   new target SHA-256.

The rendered page also contains a visible `Supplementary information` link to
`../../supplementary_information.html`, but that target is absent from the
current `_build/nathealth` tree.

These are recorded as `H02-33F-D1` and `H02-33F-D2` in
`consolidated_defects.csv`. They do not alter any scientific result, but both
block order-33f acceptance under its stated verification contract.

## Visual gate and teardown

The loopback server, in-app browser, and visual QA were not started because
the nonvisual reader-test and link-integrity gates did not pass. Narrow
read-only process searches found no active Quarto render, Pandoc process, H02
semantic process, or HTTP static server. The external semantic-audit directory
is intentionally retained for independent acceptance.

No source patch, rerender, companion render, later-target render, commit,
push, upload, or publication was performed.
