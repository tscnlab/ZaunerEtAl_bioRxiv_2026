# Brown adherence cross-state integrated Stage 3 acceptance and Stage 4 transition

Decision ID: `BA-016`  
Change ID: `CHG-155`  
Date: 2026-08-21  
Status: author approved; integrated Stage 3 accepted; bounded Stage 4 authorized

## Author decision and gate closure

The author supplied the exact required wording:

> Approve Brown cross-state integrated Stage 3 as written

This closes `BA-CS-G3-INTEGRATED-REVIEW`. The accepted package includes the
main endpoint-inflated Brown recommendation analysis, its exact sample and
diagnostic qualifications, the separate exploratory cross-state association,
the anonymous participant-state display, the Work-day and Free-minus-Work site
displays, and the final `BA-M6` site-versus-equal-site inference amendment.

`BA-016` and `CHG-155` are the controlling central records for the Stage 3
acceptance and the bounded Stage 4 transition. They do not alter any accepted
model, estimate, interval, multiplicity family, sample, sensitivity result, or
scientific claim.

## Accepted integrated Stage 3 package

The following identities are authoritative:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | 52,506 | `80bd2167095dfcf025de7f79baa495c111641cbd02622345e9c5641225aa0997` |
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html` | 4,808,772 | `9a4f89f2291eaa8926a429a1e12acdc4d7de8d9ca47d37db5801fbd4d5b35fe0` |
| `stage2_boundary/site_free_work_vs_equal_site_amendment/stage2_ba_m6_final_manifest.csv` | 21,499 | `86cbf5d807a2727715b269208bca5177aa38223f1e79163419a2a905f0eb76ea` |
| `stage3_cross_state_association/cross_state_stage3_final_manifest.csv` | 23,655 | `911ca3dfeb362d2bb26fabe1e0b4fc98d270339aac7833b33faf9c2a613674df` |
| `site_free_work_vs_equal_site_inference_amendment/00_build_ba_m6_display.R` | 17,802 | `b361b4492f5f2203ef117d8186163047140eab2fe6ea6d981dcd051500151404` |
| `site_free_work_vs_equal_site_inference_amendment/source_data/main_site_free_work_forest_with_ba_m6_source.csv` | 19,620 | `4c2d18282cd222930f91edac6606fd0a98ee313c975728a0cfe372ded565c1fc` |
| `site_free_work_vs_equal_site_inference_amendment/figures/main_site_free_work_forest_with_ba_m6.png` | 350,620 | `c2c58e3c8119457975d57e94b062ddba41ca828ad4326b1e1e6ac19bb7f1151a` |
| `site_free_work_vs_equal_site_inference_amendment/figures/main_site_free_work_forest_with_ba_m6.svg` | 32,059 | `126acff6b1794864fc5b5797915046f884cc0890d445adc2aa437058f6d90fe0` |
| `fallback_candidate_recovery/fallback_recovery_handoff.md` | 2,012 | `d6a41b2988269a1af064b58130f6de8b54d00b787ba32d904e281fb6d145fd0e` |
| `fallback_candidate_recovery/renewed_author_gate.md` | 377 | `e1347a11e65ecc78ab6da59f2fa2771728b1e796588b87342c113cf75ddb2616` |
| `fallback_candidate_recovery/final_manifest.csv` | 44,950 | `69033a670469ba3c511afdd0dce0caa9cf55bc946af548d795584043442e3a21` |
| `fallback_candidate_recovery/finalization_checks.csv` | 926 | `f8e9ff1e8476362de589bd91ed7b66e58a816f2be5667f32061f793361850e56` |
| `fallback_candidate_recovery/intended_size_figure_qa.csv` | 1,251 | `5f7246771fdd906a8a1017f8058eec96cc476f1d5f7a3256632129732ec10dd4` |
| `renv.lock` | 603,493 | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

Paths beginning with `stage2_boundary/` are relative to
`audit/analyses/brown_adherence/`. Paths beginning with
`stage3_cross_state_association/` or
`site_free_work_vs_equal_site_inference_amendment/` are relative to
`audit/analyses/brown_adherence/` and
`audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/`,
respectively. Paths beginning with `fallback_candidate_recovery/` are
relative to the accepted figure recovery root:

`audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/plot_note_clipping_recovery/`

The accepted fallback manifest contains 76 unique, non-circular members. R
4.6.1 rehashed all 76 paths, byte counts, and SHA-256 identities exactly.
Stored gates pass at 19 of 19 fallback-source checks, 27 of 27 candidate
checks, 24 of 24 post-canonical checks, 28 of 28 replacement-render checks,
24 of 24 native visual checks, 10 of 10 deterministic 390-pixel checks, 10 of
10 intended-size figure checks, and 21 of 21 finalization checks. The single
replacement render used R 4.6.1 and Quarto 1.9.37. The loopback server was
stopped, no listener remained, and the temporary served copy was removed.

## Accepted scientific disposition

The accepted `BA-003` and `BA-004` endpoint-inflated Brown recommendation
analysis remains the main Brown analysis. The cross-state association remains
a separate exploratory extension.

The main analysis retains its selected `F3/R3/Q2/Q1/D0` endpoint-inflated
beta-binomial model, the accepted any-valid primary sample, the identical
at-least-80-percent claim gate, the `BA-M1` through `BA-M5` families, the
point-only random-effect and R-squared/Shapley summaries, the separate chest
context, and every accepted diagnostic and interpretive limitation.

The new `BA-M6` family contains exactly 27 primary response-scale tests of a
site-specific Free-minus-Work effect against the state-specific equal-site
Free-minus-Work effect. Exactly three rows pass the 27-member BH family:

| Brown state | Site | Difference from equal-site effect, percentage points | BH-adjusted p-value |
|---|---|---:|---:|
| Wake | Dortmund (DE) | +15.000 | 0.003920 |
| Wake | Madrid (ES) | -9.205 | 0.042309 |
| Sleep | Kumasi (GH) | +6.257 | 0.000389 |

All three directions are retained in the identical at-least-80-percent
sensitivity. The orange diamonds in the accepted forest remain the separate
`BA-M4` tests against zero. The black asterisks encode `BA-M6`. These two
families must not be conflated.

For the cross-state association, the selected exploratory model remains
`F3/R3/Q2/Q1/D0`. The within-participant day-level claim remains withheld
because temporal dependence is unresolved. The between-participant inverse
associations may be reported only with their accepted limitations. The
139-profile, 417-point raincloud remains descriptive. It does not create
participant rankings, stable traits, causal claims, or participant disclosure.

## Stage 4 purpose

Stage 4 creates a separate preparation and provenance companion. It documents
how the accepted main and exploratory Brown results were constructed and
verified. It must not refit, reinterpret, or extend either analysis.

Stage 4 must describe, using only frozen accepted records:

1. the inclusive Brown thresholds, state definitions, valid-minute
   numerator and denominator, any-valid primary sample, and identical
   at-least-80-percent gate;
2. the main linkage-C construction and the actual-date, UTC-timestamp
   association overlay, including the Wake-anchor day-type rule;
3. exact sample flow for the main model, the pairwise Sleep and Pre-sleep
   association samples, and the 139 complete anonymous participant profiles;
4. the selected main and cross-state model structures, endpoint-inflation
   components, retained participant intercepts, and recorded fallback rungs;
5. diagnostics, calibration, temporal limitations, bounded sensitivity and
   influence checks, and the precise reasons the day-level claim is withheld;
6. multiplicity provenance for `BA-M1` through `BA-M6` and `BA-CS-M1`, with
   each family kept separate and no recalculation;
7. the stored-covariance derivation and component reconciliation for
   `BA-M6`, without opening or executing a live model fit;
8. the display and paired-source provenance, privacy protection, scripts,
   manifests, environment, package versions, and render checks; and
9. a dynamic relative link to the accepted Stage 3 reader report.

The report must distinguish the main Brown analysis from the exploratory
cross-state extension throughout. It must use plain language in the reader
flow and place internal IDs, model-rung history, file hashes, and production
mechanics in clearly labelled technical sections.

## Exact Stage 4 write boundary

The continuing Brown-adherence task may create or update only:

- `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd`;
- its one targeted standalone render,
  `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.html`;
- new Stage 4 source-only checks, tables, manifests, QA evidence, and a Stage 4
  handoff under
  `audit/analyses/brown_adherence/stage4_cross_state_association/`.

The Stage 4 root may contain R scripts that read accepted CSV, RDS, QMD, HTML,
manifest, and audit records only to verify identity, assemble provenance
tables, and reproduce already frozen sample-flow or diagnostic rows. It may
not contain a model fit, prediction, new contrast, p-value, confidence
interval, FDR calculation, resampling, simulation, participant deletion, or
new scientific artifact.

The accepted Stage 3 QMD, HTML, paired sources, displays, builders, manifests,
gates, and handoffs remain byte-identical. Stage 4 must link back to Stage 3.
The reciprocal Stage 3-to-Stage 4 navigation link is deferred to a later
coordinator-owned shared integration gate, after Stage 4 acceptance. The
continuing task may not edit the accepted Stage 3 source to add that link.

No shared Quarto profile, navigation file, supplementary page, manuscript,
central ledger, other Brown stage, hypothesis file, package, or lockfile is
inside the Stage 4 write boundary. Commit, push, upload, package installation,
and full-project render remain unauthorized.

## Preservation pins and preflight

Before any Stage 4 write, the continuing task must verify:

1. this decision and unique `BA-016` and `CHG-155` ledger rows;
2. all 76 members of the accepted fallback final manifest;
3. all 48 members of the `BA-M6` Stage 2 amendment manifest;
4. all 378 members of the accepted Boundary Stage 2 manifest;
5. all 162 members of the accepted cross-state Stage 2 manifest;
6. all 82 members of the accepted main Brown Stage 3 manifest;
7. all 54 members of the sealed pre-integration cross-state Stage 3 manifest;
8. the current QMD, HTML, builder, paired source, PNG, SVG, renewed author
   gate, handoff, and `renv.lock` identities listed above; and
9. the absence of every authorized Stage 4 path before first creation.

Stop on any unexplained mismatch. Do not repair, reseal, overwrite, or
regenerate an accepted earlier-stage artifact merely to make the Stage 4 page
render.

## Render, verification, and QA boundary

After source-only and protected-identity checks pass, exactly one targeted
render is authorized:

```text
RENV_PATHS_LIBRARY='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library' \
BROWN_ADHERENCE_PROJECT_ROOT='/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026' \
BROWN_ADHERENCE_AUTHOR_ROOT='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026' \
quarto render audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd --to html
```

Use normal R 4.6.1 project startup with the established narrow access to the
existing author-owned renv library. A restricted startup loop before QMD
execution must be stopped and returned for environment recovery. It must not
be retried automatically.

Stage 4 verification must include source and HTML contracts, exact manifest
rehashing, dynamic-link and anchor resolution, no embedded errors or warnings,
native semantic table structure, country-coded sites, protected-identity
reconciliation, and a non-circular final manifest. Run one secure server bound
only to `127.0.0.1`. Inspect the served page at the native 1280 by 720 browser
viewport and record deterministic responsive checks at 390-pixel width. This
authorization does not claim a mobile screenshot or emulated viewport. Check
all native tables at desktop size and for contained narrow overflow. Inspect
any exported figure at its intended final size. Stop the server, prove no
listener remains, remove the temporary served copy, and rehash all protected
paths after QA.

## Writer notification

Central Stage 3 acceptance authorizes immediate notification of the Nature
Health manuscript writer task `019ffb39-372e-7262-bfac-192751fd0e63` with:

- this controlling decision and change identity;
- the accepted Stage 3 QMD, HTML, and manifest identities;
- the split main-versus-exploratory scientific disposition;
- the exact cross-state and `BA-M6` findings and limitations; and
- a statement that Stage 4 provenance work is authorized but not yet complete.

The author additionally directs that writer task to update the Nature Health manuscript
from the accepted Brown adherence analysis. The writer may edit
only its manuscript-owned paths under its existing manuscript workflow and
must retain the accepted main-versus-exploratory hierarchy and every claim
qualification in this decision. This does not authorize the Brown task to edit
manuscript files or any shared reader report. After Stage 4 acceptance, send a
provenance-only follow-up with its final companion and manifest identities.

## Mandatory Stage 4 stop

Stop at `BA-CS-G4-REVIEW` after the Stage 4 QMD, one targeted HTML, native
tables, checks, final manifest, handoff, loopback QA, teardown, and post-QA
preservation record are complete. Stage 4 is not centrally accepted and shared
navigation is not authorized until the completed package is independently
verified and the author approves or explicitly accepts that gate.

## Reopening condition

Return to the coordinator before continuing if any preservation pin fails, a
required provenance statement cannot be supported from frozen accepted
records, a new scientific calculation or interpretation is needed, the exact
write boundary is insufficient, the sole render is consumed without a sealed
passing page, privacy cannot be preserved, an accepted Stage 3 file would need
editing, or shared integration is required before `BA-CS-G4-REVIEW` closes.
