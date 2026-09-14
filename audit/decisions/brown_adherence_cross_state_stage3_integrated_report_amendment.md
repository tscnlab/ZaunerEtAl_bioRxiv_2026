# Brown adherence cross-state Stage 3 integrated-report amendment

Decision ID: `BA-010`  
Change ID: `CHG-149`  
Date: 2026-08-20  
Status: author requested; bounded Stage 3 report integration authorized

## Decision and gate status

The author initially directed the completed cross-state Stage 3 package toward
Stage 4, then identified a consequential reader-report omission before any
Stage 4 work began:

> What I am missing from the stage 3 report is the overall boundary inflated
> model that was approved.

The sealed cross-state report presents the exploratory association extension
and links to `07_results.qmd`, but it does not place the approved main Brown
endpoint-inflated model and its results on the same reader page. This is a
stored-output report-integration omission. It is not a request to reopen a
model, change an estimand, recalculate inference, or replace the accepted main
analysis.

`BA-010` and `CHG-149` therefore pause the requested Stage 4 transition and
authorize one bounded Stage 3 integrated-report amendment. The existing
cross-state Stage 3 source, HTML, gate, handoff, checks, and 54-member final
manifest remain historical evidence of the package reviewed by the author.
They are not the final integrated reader page.

The new mandatory author stop is `BA-CS-G3-INTEGRATED-REVIEW`. Stage 4,
writer notification, shared integration, manuscript edits, commit, push, and
upload remain unauthorized.

## Preserved central authority

The amendment remains subordinate to the following central decisions:

| Authority | SHA-256 |
|---|---|
| `audit/decisions/brown_adherence_boundary_stage2_acceptance_stage3_transition.md` (`BA-003`) | `9fd1c581fcde89a8845c2fabfc47b946e2368da49ca78f2f29c1212bc80de7f7` |
| `audit/decisions/brown_adherence_stage3_random_effect_display_amendment.md` (`BA-004`) | `6d17a696ea2e2ff8920a7ed3abbfa7cc8d76f3d9c4f85285024b737ca6d6da4b` |
| `audit/decisions/brown_adherence_cross_state_association_stage2_acceptance_stage3_transition.md` (`BA-008`) | `b2723f82f38c2a5ad8f8035d86be5fc062d92f5ece160284357ebf42f9449665` |
| `audit/decisions/brown_adherence_cross_state_stage3_replacement_render_authorization.md` (`BA-009`) | `aab6482f6b9b6dd5ab425507ffba131869ce4284d8c3a483b30e5b2146cd5349` |
| `audit/decisions/brown_adherence_cross_state_stage3_replacement_render_authorization_manifest.csv` | `ad4b2190d77029931c9bdd25cbe0eafadaba948dcca2dff65c250274a45a27f1` |

Before implementation, the continuing Brown task must verify these
authorities and the unique `BA-003`, `BA-004`, `BA-008`, `BA-009`, `BA-010`,
`CHG-141`, `CHG-142`, `CHG-147`, `CHG-148`, and `CHG-149` ledger rows.

## Frozen main Brown package

The approved endpoint-inflated Brown model remains the main analysis. These
files are read-only inputs to the integrated page:

| Frozen artifact | Members | Bytes | SHA-256 |
|---|---:|---:|---|
| `audit/analyses/brown_adherence/07_results.qmd` | 1 | 29,588 | `a1c9b4662038c584d6338d0b38378ae572f27fc4ef84fa558557ff9137640cef` |
| `audit/analyses/brown_adherence/07_results.html` | 1 | 1,374,116 | `06edb255a521cc285832dc31846de39878648856bde7ee9cbb6959f83db629c8` |
| `audit/analyses/brown_adherence/stage2_boundary/boundary_stage2_final_manifest.csv` | 378 | 140,282 | `24e0adf52dbc516213cc40f34e27c41dc7fe531553520aae7a22397a6d5bdf97` |
| `audit/analyses/brown_adherence/stage3/boundary_stage3_final_manifest.csv` | 82 | 28,271 | `da25895a3e9938992d7b1f0633d6e274e691c3eb87310be565b28d465130271d` |

All 378 Boundary Stage 2 members and all 82 main Stage 3 members must remain
byte-identical. In particular, the integrated page may read, but may not
rewrite, these accepted display inputs:

| Main-analysis stored output | SHA-256 |
|---|---|
| `stage3/source_data/table_sample_summary_source.csv` | `eb7e95f229c27323fc89eb0aa35fe1ea01c7652338f944e6701b3ee8f3c39ad8` |
| `stage3/source_data/figure_adherence_levels_source.csv` | `9ced51f1d81f9709275fe0bb32c8a73b8ee6a38ff221f0ee2e865cdd294b1ac6` |
| `stage3/source_data/table_compact_adherence_primary.csv` | `294a741e23b4ec8182a225debe1c782a202d960d959d0d10183fbca7473b88c0` |
| `stage3/source_data/table_endpoint_calibration_source.csv` | `0b98dcffccd0836e09b907623b8a76accf5416cebb34975ebbe0ea75046f9795` |
| `stage3/source_data/table_coverage_gate_source.csv` | `330a9cec5af528dd1501e38ad49de683a7a47327f59122fcba8b0afc5f40acdf` |
| `stage3/source_data/table_random_effects_source.csv` | `a4bb594759ad3dbec60a14e5c1717a42fb979462fb81134b5ca371872034ea9c` |
| `stage3/source_data/table_random_effect_r2_partition_source.csv` | `66fcdac9d545cae15b6bbd3c3e8105135b505a4d91bad046df79ed1bb2661985` |
| `stage3/source_data/table_r2_decomposition_source.csv` | `e792e41564ebce02faadcf74a7877340bf5674b023087176d5955e67779e5d8a` |
| `stage3/source_data/table_shapley_global_source.csv` | `93905082f9fcbd25aeca256794c5fa138c9cbd187084900f063e0457b53b131a` |
| `stage3/source_data/table_shapley_within_state_source.csv` | `5f10e30dd4220ec2e75d78ae88c6804f08b3028089ffd7d40de9c88b2935a49b` |
| `stage3/source_data/table_placement_source.csv` | `9fdc843aa35f097cbfe1a50136088c89aa87191aa8225ea0a390798fb049dac4` |
| `stage3/figures/adherence_levels.png` | `94e1de12e9dfc9d8c696ebf49b4fb3c0d59b4ca89af323f9c30670d7ed099d1f` |
| `stage3/figures/adherence_levels.svg` | `6dbcb16c7969386b76dd6093105a2a919a210290610a7c7872527dcc635ae2c5` |
| `stage3/figures/coverage_sensitivity.png` | `f4113b56986b5467691c0a8a2a7cc6147583e66c21c2b2480ef93c16a8686a9a` |
| `stage3/figures/coverage_sensitivity.svg` | `7cb9290d20994e2aa434c7cc81c3346ec5f31ea2cef434c86194726020913415` |

Paths in this table are relative to
`audit/analyses/brown_adherence/`. The complete frozen manifests, not only
the listed reader inputs, remain controlling.

## Frozen cross-state package

The following sealed package is the historical pre-integration Stage 3
baseline:

| Frozen artifact | Members | Bytes | SHA-256 |
|---|---:|---:|---|
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | 1 | 21,736 | `3771dfb0da51e4eb63ae26711bbaccc1d11d0459675674ca06f0a40d6c2a2ae1` |
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html` | 1 | 3,711,469 | `f1f6bd9383b00d683033b5b7ac531cb85d70a001b31e9905ea6d6933cb7d88e2` |
| `audit/analyses/brown_adherence/stage2_cross_state_association/cross_state_stage2_final_manifest.csv` | 162 | 62,199 | `ec4549c2aaa07145efbc620ede805f735d3c95e7f047a09707d3eac0ba1fb38b` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/cross_state_stage3_final_manifest.csv` | 54 | 23,655 | `911ca3dfeb362d2bb26fabe1e0b4fc98d270339aac7833b33faf9c2a613674df` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/stage3_handoff.md` | 1 | 6,093 | `30498612274368971410161a9995647015592d509e294c454a7287702f12b1d4` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/cross_state_stage3_author_gate.csv` | 1 | 1,087 | `90f6bd4aa5e61ad50dc065de22b0fb690559961e` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/stage3_finalization_checks.csv` | 1 | 2,525 | `7f035f83f68130b891e06d3e17a7fa4c48c167743102f970cfc26f77a5b3043d` |

All 162 cross-state Stage 2 members and all 54 sealed cross-state Stage 3
members must verify immediately before the source amendment. The old QMD and
HTML hashes remain in the historical manifest and amendment evidence. The
current QMD and HTML are the only two sealed endpoints authorized to receive
new identities.

The 139-profile, 417-point raincloud, its privacy-safe source data, all four
`BA-CS-M1` estimates, all confidence intervals and FDR results, all selected
samples, and every diagnostic and sensitivity disposition remain unchanged.

## Exact authorized paths

The continuing Brown task may:

1. update only
   `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd`;
2. replace exactly once
   `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html`;
3. create new amendment-only scripts, checks, manifests, source-diff records,
   visual-QA records, a handoff, and an author gate only under
   `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/`.

No existing file under `stage3/`, `stage2_boundary/`,
`stage2_cross_state_association/`, or `stage3_cross_state_association/`
outside the new amendment subdirectory may change. In particular, do not
rewrite either historical final manifest, either historical gate or handoff,
the raincloud, any paired source CSV, any accepted table or figure, or any
existing verifier.

No shared configuration, central ledger, manuscript, H01 through H11 source,
package, lockfile, commit, push, upload, or full-project render is authorized.

## Integrated reader-page order

The amended report must form one coherent reader page in this order:

1. **Main Brown question and model.** State that the main analysis models
   daily Brown-recommendation adherence across Wake, Pre-sleep, and Sleep by
   day type and site using the accepted endpoint-inflated beta-binomial
   `F3/R3/Q2/Q1/D0` structure with its retained participant intercept.
2. **Exact main-analysis samples.** Show the accepted any-valid and at-least-
   80-percent samples and define adherence as the proportion of valid minutes
   meeting the state-specific recommendation on a valid state period.
3. **Main state, day-type, and site results.** Present the accepted compact
   result table, Free-minus-Work effects with 95% confidence intervals and
   FDR-adjusted results, the accepted State by Site by Day-type interaction,
   and the qualified site-localization interpretation. The accepted main
   adherence figure may be reused directly without regeneration.
4. **Calibration and coverage gate.** Show the accepted endpoint-calibration
   disposition, distinguish it from the overall-adherence limitation, and
   show that the at-least-80-percent gate preserves all three main
   conclusions. The existing coverage figure may be reused directly.
5. **Random effect and descriptive decomposition.** Show the sole retained
   participant-intercept SD for both samples, the full fixed, participant,
   and observation/distribution R2 partition, and the accepted point-only
   global and within-state Shapley summaries. State that there is no second
   retained random effect to allocate and that all decomposition is
   descriptive and non-causal.
6. **Chest placement and main-analysis limitations.** Keep chest results
   separate, complementary, and non-ocular for sleep. Preserve temporal,
   valid-minute, endpoint-model, observational, site, and placement
   limitations.
7. **Separate cross-state extension.** Introduce the extension as exploratory
   and subordinate to the main model. Preserve its exact samples, selected
   model, four-member family, withheld day-level claim, limited inverse
   between-participant associations, at-least-80-percent check, bounded
   stability qualifications, point-only Wake-cycle groups, and anonymous
   139-profile raincloud.
8. **Integrated interpretation.** End with a concise synthesis that does not
   treat overlapping MeLiDos analyses as independent replication and does not
   convert either analysis into a causal, ranking, stable-trait, or typology
   claim.

The main analysis must be visibly primary. A link to `07_results.qmd` may
remain as provenance or further detail, but it cannot substitute for the
required main-model results on this page.

## Source-only and display contract

The amendment may read the frozen CSV and RDS files and may perform only
deterministic reader formatting, ordering, rounding under existing display
rules, and native `gt` construction. It may reuse the accepted figures by
path. It may not fit or refit a model, load a model for estimation, calculate
or recalculate a prediction, p-value, confidence interval, FDR result,
diagnostic, R2, Shapley value, sample membership, or scientific summary, nor
regenerate a scientific or display artifact.

Every displayed numeric and categorical value must trace to an exact frozen
source row. The amendment evidence must include a row-level provenance map
from each integrated main-model table, figure, and claim to the corresponding
frozen Stage 2 or Stage 3 path and SHA-256. The current and historical QMD
must also have a bounded source diff showing that the change is confined to
stored-output integration, reader explanation, native table construction,
cross-references, and amendment-only checks.

All new Quarto labels and captions must be unique within the amended page.
Every substantive table must be a native `gt` endpoint. Figures must retain
their accepted caption, alt-text meaning, dimensions, source links, and
scientific content. The main-model and cross-state sections must use distinct
headings and plain language that prevents readers from conflating their
estimands.

## One replacement render and verification

After source-only verification passes, the task may execute exactly once:

```text
quarto render audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd --to html
```

Use R 4.6.1, Quarto 1.9.37, and the normal project profile. If sandboxed
`renv` activation requires cache access, use only the established narrow
access to the existing user-owned `renv` cache. Do not bypass `renv`, modify
`renv.lock`, install a package, or change a library.

Before and after the render, require:

1. exact verification of the four frozen manifests: 378 of 378, 82 of 82,
   162 of 162, and 54 of 54 members;
2. exact preservation of all frozen files except the authorized QMD and its
   replaced HTML;
3. exact row-level reproduction of every main-model and cross-state value,
   label, interval, FDR result, diagnostic disposition, sample count, R2 and
   Shapley value displayed on the integrated page;
4. no model fitting, prediction, inferential computation, resampling,
   simulation, artifact regeneration, new participant identifier, hard
   tertile, rank, or stable-trait language;
5. complete source and HTML checks for the required section order, unique
   labels, single captions, native `gt` endpoints, linked paired sources,
   accessible figures, privacy, and absence of errors or broken internal
   links;
6. a new non-circular integrated final manifest, a new integrated handoff,
   and a new integrated author-gate file under the authorized amendment
   subdirectory;
7. secure loopback visual QA at 1440 by 1000 and 390 by 844, with desktop
   table usability, contained narrow-table scrolling, readable figures at
   final display size, complete page flow, and no clipping, overlap, broken
   image, or document-level overflow; and
8. complete loopback teardown, proof of no remaining listener, and post-QA
   identity stability.

Stop and return a single sealed failed state if any new scientific
calculation is needed, a protected identity changes, a required main result
cannot be reproduced from frozen output, a source value disagrees across the
two packages, privacy is weakened, rendering fails, or the final page has a
material semantic, link, or display defect. No second replacement render is
authorized.

## Mandatory author stop and writer notification

The amended package must stop at `BA-CS-G3-INTEGRATED-REVIEW`. The new gate
must record the amended QMD, replaced HTML, integrated final manifest,
integrated handoff, all check records, preserved historical identities, and
the exact author decision requested:

> Approve Brown cross-state integrated Stage 3 as written.

The prior message to continue to Stage 4 is superseded by the author's
omission finding. Stage 4 remains paused. The Nature Health writer task
`019ffb39-372e-7262-bfac-192751fd0e63` must not be notified until the author
explicitly accepts the integrated Stage 3 package. After that acceptance, the
coordinator may issue a separate central closure and writer-notification
authority containing the final hashes and concise scientific summary.

## Reopening condition

Return to the coordinator before implementation or rendering if any frozen
manifest member fails, the integrated page would require new scientific
computation or artifact regeneration, an accepted main or cross-state result
conflicts, an existing sealed evidence file would need rewriting, the exact
authorized path boundary is insufficient, or a second render would be
required.
