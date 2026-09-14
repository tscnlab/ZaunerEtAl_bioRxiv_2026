# Brown adherence site day-type versus equal-site Stage 2 and Stage 3 reopening

Decision ID: `BA-015`
Change ID: `CHG-154`
Date: 2026-08-20
Status: author requested; bounded new-inference and report amendment authorized

## Decision

The author requested that `fig-main-site-free-work-contrasts` indicate which
site-specific Free-minus-Work effects differ significantly from the
state-specific equal-site Free-minus-Work effect.

The existing five orange diamonds cannot answer that question. They are the
accepted `BA-M4` tests of each site-specific Free-minus-Work effect against
zero. The `BA-M5` results test a site's adherence level against the equal-site
mean separately within Work and Free days. Neither family tests the requested
difference-in-differences.

`BA-015` and `CHG-154` therefore reopen the numerical Stage 2 boundary only for
one new response-scale contrast family, registered prospectively as `BA-M6`.
If and only if the bounded Stage 2 derivation and all prespecified checks pass,
this same authority permits one downstream Stage 3 figure and prose amendment,
one replacement targeted render, and renewed visual QA.

No model fit, refit, model selection, sample change, prediction from a live
model object, resampling, bootstrap, simulation, or change to `BA-M1` through
`BA-M5` is authorized. The new inference must use the frozen response-scale
cell estimates and covariance already stored in `boundary_estimands.rds`.

The author's prospective direction to approve Stage 3 and continue to Stage 4
authorizes this bounded work but does not accept estimates, multiplicity
results, or a rendered page that did not yet exist when the direction was
given. The amended page must return to the established explicit author gate.
Stage 4 and writer notification remain blocked.

## Read-only audit finding

Finding ID: `BA-015-AUDIT-001`
Category: model interface and reporting
Confidence: confirmed
Disposition: scope boundary, not a defect in the accepted `BA-M4` analysis

The audit confirmed:

1. `multiplicity_BA_M4.csv` contains 27 primary and 27 support-sample tests of
   each site-specific Free-minus-Work effect against zero;
2. `multiplicity_BA_M5.csv` and `compact_adherence_table_source.csv` contain
   site-minus-equal-site effects separately within each day type;
3. no frozen output contains the requested contrast of the site-specific
   Free-minus-Work effect minus the state-specific equal-site Free-minus-Work
   effect;
4. the requested point estimate can be reconciled algebraically from accepted
   components, but its standard error, confidence interval, p-value, and FDR
   result require the stored cross-cell covariance; and
5. the frozen `boundary_estimands.rds` contains both accepted samples, 54
   response-scale cells per sample, positive-definite stored `sdreport`
   objects, and finite 432 by 432 report covariance matrices. The calculation
   is therefore feasible without refitting or recompiling the model.

Changing the current diamond explanation to the requested meaning without
performing `BA-M6` would be an inferential mislabeling. The authorized path is
new bounded inference followed by an explicitly dual-coded display.

## Controlling central authority

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `audit/decisions/brown_adherence_cross_state_stage3_workday_site_and_coverage_guides_display_amendment.md` | 17,115 | `f532e6614f2ecb6ed64196d1239d77fa4ffd16a718039c100154c73d05bfef64` |
| `audit/decisions/brown_adherence_cross_state_stage3_workday_site_and_coverage_guides_display_amendment_manifest.csv` | 486 | `a045a7162c12af8a580b21643aeec7be5c57fbf19427a3d608493457fd87522a` |
| `audit/decisions/brown_adherence_cross_state_stage3_ba014_implementation_verification.md` | 6,571 | `c9fd59084044d38ef1bc579bcc3b870517a05d99f7dd1d44c4c43c7479f8735b` |
| `audit/decisions/brown_adherence_cross_state_stage3_ba014_implementation_verification_manifest.csv` | 1,057 | `ed23665f75232e7477d45356c8cf663c0054ec098daa9c0857580be137f6f837` |
| `audit/ledgers/decision_register.csv` after `BA-014` | 143,212 | `d89d551bf555696c34d90c3eb39486fafbe35c9bdbb072f7ca30fe16125f4e2d` |
| `audit/ledgers/change_log.csv` after `CHG-153` | 208,208 | `56d45faf1b5ee6b3666afafea5ac9ff6a5cdcbbd1b8d6e4acb6822e575ac8b6b` |

The continuing task must verify unique `BA-015` and `CHG-154` rows before any
new numerical calculation or author-file change.

## Frozen scientific inputs

Only the following frozen Stage 2 artifacts may provide numerical input:

| Artifact | Bytes | SHA-256 | Role |
|---|---:|---|---|
| `stage2_boundary/boundary_estimands.rds` | 679,832 | `5f2ae785bd114b3a2b26ceb3f2b82279a17bac53ae92e1df83c11354f127d002` | accepted response-scale cell estimates, cell ordering, and stored covariance for both samples |
| `stage2_boundary/model_BA-EIBB-ANY-F3-R3-Q2-Q1-D0-OPTREC.rds` | 124,780 | `535c272f70b3b0dbd7739ce23d8306c39ffcb10241d2ea0411fc628d46ededdd` | selected primary model identity and metadata only |
| `stage2_boundary/model_BA-EIBB-80-F3-R3-Q2-Q1-D0.rds` | 118,420 | `de8ad028e279465a0769cfef0a76293654cc00ae0320d81ae10de32c0a1b712a` | selected support-model identity and metadata only |
| `stage2_boundary/boundary_model_contract.R` | 13,006 | `a0c8e8c62c9ef0dd4402abca414fba2e735ca13157cec6477669ccf031fdc5dd` | accepted model contract identity |
| `stage2_boundary/endpoint_inflated_estimands.cpp` | 4,418 | `0a94e30e9b782b1f8e2afd824804bf00024f7afecde02903ec9f1f8c5f8df58b` | accepted response-scale estimator identity; do not compile or execute |
| `stage2_boundary/03_derive_estimands.R` | 29,002 | `9edbd4cb814c0e7a2cc7efc3262ad1d458b7250e81cec61a4f8a475a46646b73` | accepted contrast definitions and report ordering |
| `stage2_boundary/estimand_cell_predictions.csv` | 74,860 | `86bc7c1c043e267f888a324c174d074a1062e8c81b829416c3c8cd076d3c6d` | accepted 108 response-scale cell rows for component reconciliation |
| `stage2_boundary/estimand_equal_site_state_daytype.csv` | 2,037 | `f6006143efc93ffb962ab2b8712f28d866714e34f75b81f770e92e3d311fe11b` | accepted equal-site state-by-day-type components |
| `stage2_boundary/multiplicity_BA_M4.csv` | 13,034 | `49492492cf6d98a439ce4d9708dd8c9d8146e5ab5a5e726040702760dfefda25` | accepted site-specific Free-minus-Work components |
| `stage2_boundary/compact_adherence_table_source.csv` | 40,884 | `0c9c81ab166be1c0f581265ccb582080a9a62c64f4c1fb6891ba419bb44b23fe` | accepted `BA-M1` and `BA-M5` component reconciliation |
| `stage2_boundary/estimand_manifest.csv` | 3,856 | `8397cb29103e296d2c8b610214ec064598ecd75a933f5e17708fe3fd010676e6` | accepted estimand output identities |
| `stage2_boundary/boundary_stage2_final_manifest.csv` | 140,282 | `24e0adf52dbc516213cc40f34e27c41dc7fe531553520aae7a22397a6d5bdf97` | 378-member accepted Boundary Stage 2 package |

Paths beginning with `stage2_boundary/` are relative to
`audit/analyses/brown_adherence/`.

The two model bundles may be opened only to verify identity, selected rung
metadata, structural-gate status, and covariance dimensions. Numerical
`BA-M6` results must come from the frozen values and covariance already stored
in `boundary_estimands.rds`. If those stored objects are insufficient, stop
and return. Do not fall back to model fitting, objective reconstruction, TMB
compilation, or new prediction without new authority.

## Historical Stage 3 baseline

The following current Stage 3 package is exact historical evidence:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | 51,128 | `05e1ae2b8dd5dea5d2230f97fe8c178556588d0144899e64e368cb6754a7e042` |
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.html` | 4,772,760 | `6b2ead4747c72a793dec4912af8112b5e605682f7e2544ea9006a867b22dcf0a` |
| `workday_site_and_coverage_guides_amendment/final_manifest.csv` | 49,776 | `e54b2ebfcbacefe07d7b17f213c485dec5fb77eea0263fcd759b2f112db8a842` |
| `workday_site_and_coverage_guides_amendment/renewed_integrated_author_gate.csv` | 1,043 | `5862614f2d2cffc782eb1fee874d7d36d21033a35b9181ee78e0decd27988a26` |
| `stage3/boundary_stage3_final_manifest.csv` | 28,271 | `da25895a3e9938992d7b1f0633d6e274e691c3eb87310be565b28d465130271d` |

Paths beginning with `workday_site_and_coverage_guides_amendment/` are
relative to
`audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/`.
The `stage3/` path is relative to `audit/analyses/brown_adherence/`.

All 86 `BA-014` final-manifest members must verify. The QMD and HTML are the
only existing `BA-014` endpoints authorized to acquire new identities. The
other 84 members, the final manifest, every prior gate and handoff, and all
earlier Stage 2 and Stage 3 records remain byte-identical historical evidence.

## Exact `BA-M6` estimand

For Brown state `s`, site `j`, and response-scale cell mean
`mu[s,j,d]`, define:

```text
site_day_effect[s,j] = mu[s,j,Free] - mu[s,j,Work]

equal_site_day_effect[s] =
  (1 / 9) * sum over all nine sites k of
  (mu[s,k,Free] - mu[s,k,Work])

BA-M6[s,j] =
  site_day_effect[s,j] - equal_site_day_effect[s]
```

The equal-site term includes the indexed site and uses the accepted equal
weight of one ninth for every site. The same contrast matrix must be applied
to the first 54 `cell_mean` values and the corresponding 54 by 54 submatrix of
the stored response-scale covariance. The calculation must use the exact
state, site, and day-type order recorded by the frozen `cell_predictions`
object.

The point estimate must satisfy both independent component identities within
machine tolerance:

```text
BA-M6 = BA-M4 site Free-minus-Work - BA-M1 equal-site Free-minus-Work

BA-M6 = BA-M5 site-minus-average on Free days
        - BA-M5 site-minus-average on Work days
```

Within each state, the nine `BA-M6` point estimates must sum to zero within
machine tolerance. This expected linear dependence does not remove a site
from the reported family. All 27 site localizations remain in the family, and
no new omnibus test is authorized.

## Primary multiplicity family

Register exactly one new primary multiplicity family:

| Family | Sample | Members | Test | Adjustment |
|---|---|---:|---|---|
| `BA-M6` | `primary_any_valid` | 27 | two-sided response-scale Wald z-test of `BA-M6[s,j] = 0` | Benjamini-Hochberg across all 27 raw p-values |

For each row, record the estimate in probability units and percentage points,
standard error, two-sided 95% confidence interval, z statistic, raw p-value,
BH-adjusted p-value, exact FDR indicator, state, country-coded site, component
estimates, and contrast definition. The figure's new marker must use only
`BA-M6` adjusted p-values below 0.05.

Do not modify, merge, rerun, or reinterpret `BA-M1` through `BA-M5`. In
particular, the existing five `BA-M4` diamonds remain tests against zero and
retain their accepted 27-member FDR family.

## At-least-80-percent sensitivity

Apply the identical 27 linear contrasts to the frozen `support_80` response
scale values and covariance. Record estimates, standard errors, and 95%
confidence intervals as sensitivity results. Do not create a second FDR
family, do not adjust support-sample p-values, and do not use support results
to replace the primary `BA-M6` markers.

For every row, classify:

- whether the support estimate retains the primary direction;
- whether each interval excludes zero;
- whether interval-exclusion status is retained; and
- whether the row is fully estimable.

A primary FDR-significant localization whose support estimate changes
direction blocks an unqualified Stage 3 localization claim and must be
returned for coordinator review before rendering. A retained direction with a
changed interval-exclusion status may proceed only with an explicit
sensitivity qualification. Any non-estimable row stops the amendment. No
arbitrary magnitude threshold or support-sample significance requirement may
be introduced after seeing the results.

## Authorized Stage 2 paths and outputs

Create only the following new Stage 2 amendment root:

`audit/analyses/brown_adherence/stage2_boundary/site_free_work_vs_equal_site_amendment/`

Inside it, the continuing task may create:

- `00_preflight_ba_m6.R`;
- `01_derive_ba_m6.R`;
- `02_verify_ba_m6.R`;
- `ba_m6_family_definition.csv`;
- `ba_m6_primary_site_free_work_vs_equal_site.csv`;
- `ba_m6_support80_site_free_work_vs_equal_site.csv`;
- `ba_m6_component_reconciliation.csv`;
- `ba_m6_support_gate.csv`;
- source, package, command, runtime, identity, and preservation records;
- one technical inference handoff; and
- one non-circular Stage 2 amendment manifest.

No existing Stage 2 file may change. The derivation script must fail closed on
an input identity mismatch, report-order mismatch, missing covariance, non-PD
stored report, nonfinite variance, component reconciliation failure, family
count other than 27, site/state mismatch, or any attempt to access a participant
identifier.

Run exactly one production derivation under R 4.6.1 after a source-only
preflight. No preliminary inferential trial, retry after a numerical failure,
model fit, TMB compilation, or scientific output outside the amendment root is
authorized. A startup failure before script execution may be returned for a
separate environment disposition, not retried automatically.

## Authorized Stage 3 paths and display

Only after all Stage 2 checks pass may the continuing task:

1. update
   `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd`;
2. replace its HTML exactly once;
3. create one new Stage 3 amendment root:
   `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/`;
4. create display-building and verification R scripts, paired source data,
   PNG and SVG outputs, render and QA records, screenshots, handoff, renewed
   author gate, and one non-circular final manifest inside that root; and
5. create these reader artifacts inside the new root:
   - `source_data/main_site_free_work_forest_with_ba_m6_source.csv`;
   - `figures/main_site_free_work_forest_with_ba_m6.png`; and
   - `figures/main_site_free_work_forest_with_ba_m6.svg`.

The existing paired source, PNG, and SVG in
`site_interaction_display_amendment/` remain byte-identical historical
evidence. The new paired source must retain all 27 accepted `BA-M4` estimates,
intervals, raw and adjusted p-values, five existing significance flags, three
equal-site references, and ordering. It may add only exact keyed `BA-M6`
fields and sensitivity classifications from the new Stage 2 outputs.

The amended forest must preserve every point, interval, axis, state panel,
country-coded site, zero line, equal-site line, existing orange diamond,
color, order, dimension, and DPI. Add one distinct redundant non-color encoding
for primary `BA-M6` FDR significance, such as a dark halo or asterisk. If no
`BA-M6` row passes FDR, show no false marker and state that outcome plainly.
If a row passes both families, both encodings must remain simultaneously
legible.

The legend, caption, alt text, and surrounding prose must distinguish:

- orange filled diamonds: `BA-M4`, site-specific Free-minus-Work effect versus
  zero;
- dark halo or asterisk: `BA-M6`, that site-specific effect versus the
  state-specific equal-site Free-minus-Work effect; and
- long-dashed blue line: the equal-site Free-minus-Work estimate itself.

The points remain pooled-model site-specific Free-minus-Work estimates. Sites
are not independent replications or causal effects of location. Do not call a
site different from the equal-site effect unless its primary `BA-M6`
BH-adjusted p-value is below 0.05.

## Combined Stage 2 to Stage 3 sequence

The author's exact request authorizes the bounded numerical derivation and its
direct truthful presentation without a separate intermediate author gate. It
does not accept the results. Use this sequence:

1. preflight all central, frozen, Stage 2, and `BA-014` identities;
2. run the single `BA-M6` derivation;
3. verify all 27 primary and 27 support rows, component identities, covariance
   use, family definition, sensitivity classifications, privacy, and complete
   preservation;
4. stop and return if any Stage 2 gate fails or an unqualified claim is blocked;
5. build a temporary candidate paired source, PNG, and SVG from the sealed
   Stage 2 outputs;
6. verify exact preservation of the accepted 27-point forest plus only the
   authorized new encoding and language;
7. update the QMD and write the new Stage 3 display artifacts once;
8. run a complete source-only gate; and
9. execute exactly one replacement targeted render followed by full-page
   verification and visual QA.

No result may be inspected and used to redefine the contrast, family,
sensitivity criterion, marker, or claim gate. Return one combined stopped
package on any new issue.

## Render and QA boundary

After every numerical, display, source, privacy, and preservation gate passes,
execute exactly once from the continuing Brown worktree:

```text
RENV_PATHS_LIBRARY='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library' \
BROWN_ADHERENCE_PROJECT_ROOT='/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026' \
BROWN_ADHERENCE_AUTHOR_ROOT='/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026' \
quarto render audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd --to html
```

Use R 4.6.1, Quarto 1.9.37, the normal project profile, and narrow access to
the existing author-owned `renv` library from the outset. Do not first attempt
the render under a restricted cache boundary. Do not install packages or
modify `renv.lock`.

Post-render checks must cover the complete page plus:

- exact 27-row `BA-M4` and 27-row `BA-M6` source reconciliation;
- correct simultaneous encoding of both significance questions;
- exact equal-site references and country-coded sites;
- all captions, alt text, source links, cross-references, tables, figures,
  privacy conditions, and no-error gates;
- preservation of every earlier Stage 2, Stage 3, and `BA-014` sealed member;
- intended-size PNG and SVG parity; and
- complete loopback teardown and post-QA stability.

Apply the accepted `BA-013` method: native served-page inspection at the
available 1280 by 720 viewport, intended-size inspection of the new PNG, and
deterministic responsive structural verification at 390-pixel width. Do not
claim a mobile screenshot or use an iframe, CDP, alternate browser surface,
or policy workaround.

No second render is authorized. A render or QA failure returns one sealed
stopped state for a separate disposition.

## Mandatory author stop and prospective wording adjudication

The completed amendment must stop again at
`BA-CS-G3-INTEGRATED-REVIEW`. The renewed gate must pin the current QMD, HTML,
new `BA-M6` outputs, amended figure, paired source, all preservation records,
and final non-circular manifests.

The author's prospective direction to approve Stage 3 after this correction
is recorded as authorization to perform the work, not as post-result
acceptance. It cannot close a gate for unknown numerical results and an unseen
rendered page.

After reviewing the sealed amended report, the author must still supply the
established exact wording:

> Approve Brown cross-state integrated Stage 3 as written.

Only a later central decision may then accept the amended Stage 3 package,
authorize Stage 4, and determine writer notification. Stage 4 and Nature
Health writer task `019ffb39-372e-7262-bfac-192751fd0e63` remain blocked until
that decision.

## Reopening conditions

Return before calculation, source edit, or rendering if:

- any central, Stage 2, Stage 3, or `BA-014` identity fails;
- the stored response-scale covariance is unavailable, nonfinite, or not
  positive definite;
- either selected sample lacks the exact 54-cell ordering;
- the two component reconciliations disagree;
- any of the 27 primary or 27 support contrasts is not estimable;
- the primary family cannot be fixed at exactly 27 members before results are
  inspected;
- a primary FDR localization changes direction in the support sample and
  cannot be qualified under this contract;
- participant-level data, a model refit, TMB compilation, resampling, or new
  package installation would be required;
- an earlier sealed file other than the QMD and HTML endpoints would need
  rewriting; or
- a second render would be required.
