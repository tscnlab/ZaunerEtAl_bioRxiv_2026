# Brown recommendation adherence Boundary Stage 2 acceptance and Stage 3 transition

Decision ID: `BA-003`  
Change ID: `CHG-141`  
Date: 2026-08-15  
Status: author approved; bounded Stage 3 authorized

## Author decision and current status

The author explicitly approved the complete Boundary Stage 2 package:

> **Approve Brown adherence Boundary Stage 2 as written.**

This accepts the selected endpoint-inflated beta-binomial model, the distinct
acceptability assessments for overall adherence and endpoint probabilities,
the complete `BA-M1` through `BA-M5` results, the mandatory at-least-80%
claim gate, the bounded diagnostics and sensitivities, the compact-table
contract, and the point-only R² and Shapley decomposition.

Brown recommendation adherence remains a standalone exploratory analysis. It
does not become an H01 through H11 hypothesis, replace an accepted hypothesis
result, or alter any multiplicity family outside this analysis. The central
`hypothesis_stage_gates.csv` therefore remains unchanged. This decision,
`BA-003`, and `CHG-141` are the central records for closing
`BA-BS2-REVIEW` and opening the bounded Stage 3 reader-report phase.

## Accepted Boundary Stage 2 identities

| Accepted artifact | SHA-256 |
|---|---|
| `audit/analyses/brown_adherence/06_boundary_process_implementation_and_reconciliation.qmd` | `bebb606563c17c0cd8488dfd53fd743dd66aa08815d29a5696d6e800d31bc4b4` |
| `audit/analyses/brown_adherence/06_boundary_process_implementation_and_reconciliation.html` | `a042d010ae80e18e63770a71d9f53f2fba79e554db32b329ad8232e7e89c3434` |
| `audit/analyses/brown_adherence/stage2_boundary/boundary_stage2_author_gate.csv` | `6c31b3ff2cfc001d434471ebe26f98b177f611081c6fba77edad52be5801b2bd` |
| `audit/analyses/brown_adherence/stage2_boundary/boundary_stage2_handoff.md` | `fec8fa8f7123c23c18396ab78452bad0762a2b971fa33c138252d0c667c012ae` |
| `audit/analyses/brown_adherence/stage2_boundary/boundary_stage2_final_manifest.csv` | `24e0adf52dbc516213cc40f34e27c41dc7fe531553520aae7a22397a6d5bdf97` |

Independent R 4.6.1 verification matched all 378 entries in the final
manifest, all 24 focused report checks, all 19 R² and Shapley checks, all five
complete multiplicity families, and all three at-least-80% claim-gate
contrasts. It also confirmed that the planned Stage 3 and Stage 4 sources,
outputs, and directories do not yet exist.

## Accepted scientific disposition

The accepted primary artifact is
`BA-EIBB-ANY-F3-R3-Q2-Q1-D0-OPTREC`, the approved
`F3/R3/Q2/Q1/D0` endpoint-inflated beta-binomial structure after the recorded
BFGS confirmation of the original optimizer result. Its fit assessment is
`acceptable_with_cautions`.

The accepted release boundary is:

- overall adherence is `acceptable_with_limitations`, chiefly because the
  actual-date temporal sensitivity did not fully resolve residual dependence;
- endpoint probabilities are `acceptable` for the five applicable endpoint
  components, with Wake extra all-yes mass remaining fixed at zero under the
  accepted construct;
- the identical at-least-80% analysis passes the mandatory claim gate for all
  three Free-minus-Work contrasts;
- `BA-M1` through `BA-M5` remain the complete, separately adjusted families,
  with the compact table and `BA-M4` localization retaining their accepted
  roles; and
- the response-scale marginal and conditional R², random-effect increment,
  and Shapley allocations remain descriptive point summaries without
  confidence intervals, p-values, or causal interpretation.

These qualifications must remain visible in Stage 3. Stage 3 may summarize
the accepted results but may not change the model, estimand, sample, threshold,
linkage, placement role, multiplicity, diagnostic disposition, sensitivity
classification, or claim gate.

## Required preservation pins

Before Stage 3 work begins, the Brown-adherence owner must match:

1. this decision and the current `BA-003` and `CHG-141` ledger rows;
2. every accepted Boundary Stage 2 identity listed above;
3. all 378 live members of
   `boundary_stage2_final_manifest.csv` against their recorded SHA-256 and
   byte counts;
4. the selected any-valid model gate and artifact identities, the identical
   at-least-80% model gate and artifact identities, the five multiplicity
   vectors, the three-row claim-gate file, the diagnostic assessment, and the
   R²/Shapley validation and quadrature files; and
5. all accepted Stage 1, historical Stage 2, shared scientific input, and
   environment pins already protected by `BA-002`.

Stop on any mismatch. Stage 3 must not repair or reseal an accepted Stage 2
file merely to make a reader report render.

## Authorized Stage 3 paths and scope

The continuing Brown-adherence task may create or update only:

- `audit/analyses/brown_adherence/07_results.qmd`;
- its targeted render
  `audit/analyses/brown_adherence/07_results.html`;
- new task-owned display code, source data, figures, tables, tests, manifests,
  visual-QA records, and the Stage 3 handoff under
  `audit/analyses/brown_adherence/stage3/`; and
- `audit/handoffs/brown_adherence_strategy_handoff.md` solely to record the
  Stage 3 state and returned identities.

Stage 3 is a stored-output-only reader report. It may transform frozen Stage 2
reporting CSVs into reader-facing tables and figures, but it may not fit or
refit a model, calculate a new inferential statistic, rerun prediction,
simulate, resample, repeat deletion or influence fits, alter FDR adjustment,
or regenerate any accepted Stage 2 scientific artifact.

The report must include:

1. a plain-language question and an answer-in-brief callout;
2. a concise explanation that adherence is the proportion of valid minutes
   meeting the state-specific Brown recommendation on an otherwise valid day;
3. exact any-valid sample counts and the distinct at-least-80% claim-gate
   sample;
4. the accepted Free-minus-Work results in percentage points with 95%
   confidence intervals and FDR-adjusted results;
5. the accepted site interaction and localization findings without presenting
   site-specific associations as causal or independent replications;
6. endpoint-process calibration and the separate overall-adherence limitation;
7. the at-least-80% stability result;
8. the separate complementary chest placement assessment without pooling and
   without an ocular interpretation of sleep-environment exposure;
9. the point-only R² and Shapley summary, explicitly labelled descriptive and
   non-causal; and
10. a restrained limitations section covering temporal dependence,
    observational interpretation, valid-minute support, endpoint-model
    cautions, placement scope, and the exploratory status of the analysis.

Use native `gt` tables, accessible figures with paired source data, dynamic
relative `.qmd` links, country-coded site labels, practical units, and 95%
confidence intervals. The report should not expose model-rung history, gate
IDs, artifact mechanics, or other production terminology in its main reader
flow. Internal identifiers may appear only in a clearly separated
reproducibility note when needed to identify the accepted source.

One targeted render of `07_results.qmd`, its focused R 4.6.1 source and HTML
checks, protected-identity verification, and secure loopback visual QA are
authorized. No full-project render or shared profile integration is
authorized.

## Mandatory Stage 3 stop and writer notification

Stop at `BA-BS3-REVIEW` after the Stage 3 source, targeted HTML, tables,
figures, source data, tests, manifest, and visual QA are complete. No Stage 3
result is author accepted until the author explicitly approves that gate.

At the completed Stage 3 gate, notify the Nature Health manuscript writer task
`019ffb39-372e-7262-bfac-192751fd0e63` with the exact report and manifest
identities and a concise scientific summary. The notification must state that
the package is pending Stage 3 author approval and must not yet be integrated
as accepted manuscript evidence. After author acceptance, send the writer a
second message identifying the controlling acceptance decision and the final
scientific status.

Stage 4, shared Quarto integration, manuscript edits, commit, push, upload,
package installation, and any new scientific computation remain unauthorized.

## Reopening condition

Reopen `BA-003` before further work if a protected identity changes, a reader
display cannot be produced without changing accepted scientific content, the
author revises the Stage 2 disposition, or the Stage 3 report would require a
new estimate, model, diagnostic, sensitivity, or claim.
