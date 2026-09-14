# H04 REPORT-014/017 order 35 stopped source-only audit

Date: 2026-08-14  
Order: `audit/report_harmonization/owner_orders/35_h04_consolidated_reader_and_companion_rewrite.md`  
Order SHA-256: `e34cb4dbf6fce4416792d2a648c8c4b1987e190996154c8bde106c21352ca291`  
State: **stopped after the single authorized source-only suite**

## Outcome

The consolidated result and companion source rewrite was assembled without
rendering or scientific execution. The new source-only test recorded 37
checks: 35 passed and two failed. Order 35 requires a stop after any unexpected
failure, with no piecemeal patch-and-rerun loop. The QMDs and test therefore
remain exactly as exercised by that one suite.

No failure identified a change to a scientific formula, value, model role,
stored result, endpoint, link target, or protected scientific artifact. Both
failures are defects in expectations encoded in the new test.

## Combined defect list

### ORDER35-STOP-001: truncated expected chunk hash

The `companion_chunk_allowlist` check contains a 48-character expected value
for `tbl-h04-prep-output-map`:

`04088ce197cc7462de74c50b72cb0f0b5e5f34a4705c7181`

The actual SHA-256 of the complete changed chunk body is:

`04088ce197cc7462de74c50b72cb6c5b291c3b8ba4cb0f0b5e5f34a4705c7181`

The missing 16 characters are `6c5b291c3b8ba4cb`. The other nine allowed
display-only chunk hashes match their complete expected SHA-256 values. The
changed-label set is exactly the ten-item allowlist. This is a test-literal
defect, not unapproved source drift.

### ORDER35-STOP-002: incorrect untracked-HTML expectations

The `untracked_audit_html_preserved` check encodes two hashes that are not the
accepted identities in the preserved Stage 3 manifest. The current files are
untracked and were not edited by this order. Their current identities are:

| Path | Current and Stage 3 manifest SHA-256 | Bytes | Modification time |
|---|---:|---:|---|
| `audit/hypotheses/H04/01_audit_and_plan.html` | `59afbcd101e77ceadd7a720ef5e7bceebc22650d3e5d4b623a463d25f8bb2a4b` | 2,098,178 | 2026-08-10 20:47:41 +0200 |
| `audit/hypotheses/H04/02_implementation_and_v0_comparison.html` | `2e8bcaa35974c7aef36b1cfa9b942a4d7e1baca9cfacc2edb57365bf43aab636` | 4,644,570 | 2026-08-11 09:26:15 +0200 |

Those hashes and byte counts are the exact entries in the byte-preserved
`artifacts/12_manifests/H04/H04_stage3_artifacts.csv`. The new test instead
uses `59afbca62bfaa069b11d0d50bc1a4bf63dc0e114c5c248c0029301917a3a08e6`
and `2e8bca31c0186e29174528de419d178d42672459f323c28f31e8c722c039f335`.
Neither value is supplied by order 35. This is a test-pin defect, not evidence
that either excluded HTML page was touched.

## Passing preservation evidence

The generated audit CSV records passing checks for all of the following:

- exact result endpoints, 17 tables and seven figures, in the approved order;
- exact companion endpoints, 37 tables and four figures;
- parsing of every R chunk without execution;
- preservation of all result chunk bodies and the complete chunk-label sets;
- inline R, top-level assignments, formulas, artifact references, Markdown
  targets, and scientific numeric tokens under the explicit glossary-only
  allowlist;
- main-first hierarchy, the five disclosures, lightbox, reciprocal dynamic
  QMD links, the participant-random-intercept anchor, the five registration
  links, and resolution of all relative targets;
- approved vocabulary, country-coded study sites, glossary, display mappings,
  and the separate primary, Mundlak, random-intercept, and temporal roles;
- absence of scientific fitting, prediction, simulation, resampling, Shapley,
  builder, or project-write calls in either QMD;
- all 30 protected controlling-package identities and all seven accepted
  participant-random-intercept artifact identities; and
- the frozen stored-figure hashes and known baked labels pending the later
  bounded label refresh.

## Frozen source state

| Source | Pre-order SHA-256 | Exercised stopped-state SHA-256 |
|---|---:|---:|
| `notebooks/hypotheses/H04.qmd` | `cd58c2ff5708fd3c74336656056dc1459f59772e55a31abd6f90bd25ad11e6ac` | `63e815683e1e81dadd480aeb230c7913de7726aa9242f5ce89ec4a0e7e90471c` |
| `audit/hypotheses/H04/H04_analysis_preparation.qmd` | `28e44e527f1048cdd2b56cf2d7d7ed4b6a1faea5b8cd2c6765068fb2bf994d3d` | `52160297aaaa65f9cc0e36839adb0fcbe86e55631c847476b5006f03d657e9da` |
| `tests/hypotheses/H04/test_h04_report017_source_harmonization.R` | new | `02e7494ad081f6395fe19ceca2ed3ded1fe8bc3e8dbaf550e3279f3406ac427f` |

The exact source patch is
`audit/hypotheses/H04/report017_order35/H04_order35_exact_source_diff.patch`.
No Quarto command, QMD execution, model fit, prediction, simulation,
bootstrap, Shapley rerun, artifact regeneration, commit, or push occurred.
Both existing rendered HTML reports remain stale context and must not be
described as renders of the revised sources.

## Release status

H04's accepted scientific closure is unchanged. REPORT-017 rendering remains
held. A later owner instruction is required before correcting the two test
expectations or repeating the source-only suite.
