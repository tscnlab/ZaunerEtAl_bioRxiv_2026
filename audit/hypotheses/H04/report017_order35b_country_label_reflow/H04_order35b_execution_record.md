# H04 REPORT-014/017 order 35b execution record

Date: 2026-08-20

Order: `audit/report_harmonization/owner_orders/35b_h04_country_label_source_reflow.md`

Order SHA-256: `eef9e794836a06d1d92d8cac10f8dbe9cbe6023afc444e3deabeac291c9253c3`

Disposition: **PASS**

## Preflight and source change

R 4.6.1 with `digest` 0.6.39 verified all 15 unique dispatch-manifest
rows before mutation. Exactly two source line boundaries were moved:

- `Delft` and `(NL)` are now contiguous as `Delft (NL)` in the result QMD;
- `Munich` and `(DE)` are now contiguous as `Munich (DE)` in the companion
  QMD.

No non-whitespace character changed. The result source is now SHA-256
`f8adb6d78be041ce296dd7e89eb92769b128631c1b4227ce5d8ab3d526daf1d5`,
83,285 bytes. The companion source is now SHA-256
`efdb5be8dc194695f40c50249fab14905ec337bc63079ae589557de860188474`,
91,202 bytes.

The source contract contains 19/19 PASS checks. It proves that both complete
non-whitespace byte sequences and token sequences are unchanged; every R
chunk body, chunk label, and inline-R expression is byte-identical; the QMD
diff contains exactly two zero-context hunks; and reverse substitution
reconstructs both dispatched QMD hashes and byte counts exactly. The complete
37-gate source test additionally protects endpoints and order, captions, alt
text, links, formulas, numeric tokens, assignments, artifact references,
source-data references, model roles, and protected artifacts.

## One-time test sequence

The following unchanged tests were run once, in order:

```text
Rscript --vanilla tests/hypotheses/H04/test_h04_participant_random_intercept_assessment.R
H04_ORDER35_AUDIT_CSV=audit/hypotheses/H04/report017_order35b_country_label_reflow/H04_order35b_source_test_audit.csv Rscript --vanilla tests/hypotheses/H04/test_h04_report017_source_harmonization.R
Rscript --vanilla tests/report_harmonization/test_country_coded_site_names.R
```

| Test | Exit | Wall time | Result |
|---|---:|---:|---|
| Participant random-intercept assessment | 0 | 3.415861208 s | Passed using accepted stored artifacts |
| Complete H04 source harmonization | 0 | 0.879504209 s | 37/37 PASS, no R warning |
| Global country-coded-site contract | 0 | 9.048375042 s | Passed for 37 reader-facing QMDs, zero findings |

The exact command and output summaries are in
`H04_order35b_test_execution.csv`. The 37-row source audit is
`H04_order35b_source_test_audit.csv`.

## Handoff and protected history

The owner handoff was changed only by appending the bounded order-35b note.
The preceding 30,132 bytes are byte-identical to the dispatched handoff. The
current handoff is SHA-256
`99de6fd036b7e7c52a55406615642024092e3177317255101c4a5db1ff391036`,
31,926 bytes. Its exact one-hunk diff and reverse proof reconstruct the
dispatched SHA-256
`1961b349d527b3c945d0d299a27f46603a674843629a918461ea2a504023b50a`.

The protected-identity audit contains 30/30 PASS rows. It verifies the full
15-row order-35b dispatch after the three authorized current-source updates
and independently rechecks the 15 non-source rows of the accepted order-35a
history. All order-35 and order-35a evidence remains byte-identical.

The scoped command

```text
git diff --check -- notebooks/hypotheses/H04.qmd audit/hypotheses/H04/H04_analysis_preparation.qmd audit/handoffs/H04_worker_handoff.md
```

exited 0 with no diagnostic.

## Boundary

No QMD was executed. No scientific wording, value, formula, code chunk, test,
artifact, source data, existing manifest, historical evidence, HTML, build
copy, profile, configuration, ledger, package, or lockfile was changed. No
Quarto command, model fit, prediction, simulation, bootstrap, Shapley
allocation, artifact regeneration, render, commit, push, or upload occurred.
Every H04 render remains held, and H01 remains the sole active integration
path.
