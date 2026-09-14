# H11 REPORT-016 hourly-outcome disposition

Date: 2026-08-12  
Issue: `RH-SCI-002`  
Status: **resolved without scientific recomputation**

## Exact disposition

**(c) The registered-hourly sensitivity is outside/superseded by the accepted
H11 analysis.** The hourly geometric-mean outcome remains visible as the
preregistered specification. It was not fitted in H11, but it is also not an
outstanding requirement after the author-approved H02 inheritance and final H11
acceptance.

This is not disposition (a): the Stage 2 registry and fit manifests contain no
hourly H11 fit. It is not disposition (b): the final accepted H11 handoff closes
scientific computation, and the authoritative REPORT-016 overlay classifies
`DEV-042` as `approved_implemented_verified` rather than as a current open
qualification. `DEV-003` remains the overlay's current open qualification.

## Evidence chain

| Evidence | What it establishes |
|---|---|
| `audit/evidence/preregistration_contract.md` | H11 registered hourly geometric-mean melEDI. |
| `audit/decisions/h02_final_analysis.md` and `audit/handoffs/H02_worker_handoff.md` | H02 accepted the zero-aware transformed 30-minute arithmetic-mean outcome and closed without an unresolved H02 scientific gate. |
| `audit/hypotheses/H11/01_audit_and_plan.qmd` and `01_author_decision.md` | The historical H11 proposal named an hourly sensitivity; this reviewed proposal is preserved. |
| `artifacts/06_model_data/H11/stage2/deferred_analysis_registry.csv` | Stage 2 did not fit the hourly scenario and retained it in the historical deferred registry. |
| `artifacts/06_model_data/H11/stage2/formula_and_fit_manifest.csv` and Stage 3/activity formula registries | Accepted fits cover the primary, gap-timing-unaware, and activity-context analyses; no registered-hourly run is present. |
| `audit/hypotheses/H11/05_stage3_gate_and_stage4_transition.md` and `audit/handoffs/H11_worker_handoff.md` | The author accepted the H11 reader result and the handoff closed further H11 scientific computation. |
| `audit/decisions/deviation_reader_disposition_reconciliation.md` and `audit/ledgers/deviation_reader_dispositions.csv` | REPORT-016 is the authoritative current overlay and marks `DEV-042` implemented/verified; only `DEV-003` is a current open qualification. |

## Reader correction

The row-level reconciliation is stored in
`06_report016_hourly_outcome_reconciliation.csv`. Only the current result QMD,
current preparation/provenance QMD, and current H11 handoff were clarified.
Historical Stage 1 and Stage 2 sources and the frozen deferred registry were
not edited. No dynamic preregistration-deviation link was added.

Their preserved identities are:

| Historical artifact | SHA-256 |
|---|---|
| `01_audit_and_plan.qmd` | `69ac3795cf61a5f3241cbbc5af7582dc0cffc8b40715be8f9b76ad138b3c6b25` |
| `01_author_decision.md` | `d4f259f1002d04a29458dc38b52ec6af0a91a3e0707ae668d6b0b6fc042cd2f4` |
| `02_implementation_and_v0_comparison.qmd` | `31e82c5b4523a01f6cfc8a1ebb6dfe7482e82a99347865be636d7f6c7963cfec` |
| `deferred_analysis_registry.csv` | `aea7b8b02d71586babdc9466ba1ada07e6d394bcfb35dea93b14264752ec8b42` |

## Identity and no-scientific-change record

Before this correction:

| Artifact | SHA-256 |
|---|---|
| `notebooks/hypotheses/H11.qmd` | `e4f13510317e62888f7fd785bacd8bd20ad9f3e90d24fa7bc9dc59e7215ec2e7` |
| `audit/hypotheses/H11/H11_analysis_preparation.qmd` | `a2d25df408b7282691342a19b030427c2fea6111a04719ffb8c6e382bab92def` |
| `audit/handoffs/H11_worker_handoff.md` | `dff84d35975f658834149d31bb486590ab425aa6298183213944adffa4c06262` |

After this correction:

| Artifact | SHA-256 |
|---|---|
| `notebooks/hypotheses/H11.qmd` | `6d8efe39896812437037ee60675f95fb71fd8f74f3eaf0e65b151f27f0822dbd` |
| `audit/hypotheses/H11/H11_analysis_preparation.qmd` | `fc7781c887ba4470b1bb660143f5df207e780efd257ca268138dae2d35d42e7f` |
| `audit/handoffs/H11_worker_handoff.md` | `5f01ac88745d55d749854b41d22ce3bd0afe43f42dbbaded98da7a61e1b53289` |
| `06_report016_hourly_outcome_reconciliation.csv` | `7dc4ab4a68f21a7274562a06b19bedc904605dc8ab0d721d1b70f6c87b80a64b` |

The scientific baseline manifests remain byte-identical:

| Manifest | SHA-256 | Verified immutable rows |
|---|---|---:|
| `H11_stage2_output_hashes.csv` | `a3cb30de615c615cfbfd6bfb1b7994634b1721915ed446eee5e00157638d44a2` | 81 Stage 2 model/data/diagnostic/table/figure/source-data files |
| `H11_stage3_artifact_manifest.csv` | `2f55cef62117af71beab6e320fac842489b24be149209ea60a1d54cbd172f645` | 42 accepted reader-artifact files |
| `H11_activity_context_output_hashes.csv` | `6960448adc102d29ff48c06d07eb53cdb97a1bba89ea7dce73f779d5c5a4eecc` | 48 activity-context scientific files |

`tests/hypotheses/H11/test_h11_report016_hourly_disposition.R` verifies these
identities under R 4.6.1, asserts the revised disposition and preserved
historical wording, confirms that no registered-hourly fit exists, and fails if
a dynamic deviations-page link has been added. No fit, refit, prediction,
bootstrap, simulation, robust test, diagnostic calculation, or sensitivity was
run.

## Verification environment and command

- R 4.6.1;
- `digest` 0.6.39 for SHA-256 verification;
- `knitr` 1.51 for non-executing extraction and parsing of both QMDs; and
- Quarto 1.9.37 identified, but no render was run because the harmonization
  order keeps focused rendering behind its separate compute-window release.

The successful bounded check was:

```sh
R_PROFILE_USER=/dev/null \
R_LIBS_USER=renv/library/macos/R-4.6/aarch64-apple-darwin23 \
Rscript tests/hypotheses/H11/test_h11_report016_hourly_disposition.R
```
