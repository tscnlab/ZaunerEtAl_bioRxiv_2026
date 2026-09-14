# Harmonization order 08 — main hourly H06 result and preparation/provenance companion

Date: 2026-08-12  
Owner task: `019fbd4a-288b-7a72-ac70-2d17ba6d2f04`  
Controlling decisions: `REPORT-014` / `CHG-124`; `REPORT-016` / `CHG-126`; website integration `CHG-128`  
Dispatch mode: **source-only first; focused renders and display-asset refreshes require a separate Phase 4 release**

## Scientific role and exact owned documents

The accepted hourly analysis is the **main H06 result**. Harmonize it now without waiting for, reopening, or borrowing from the unfinished H06_daily complement.

| Source | SHA-256 at order preparation |
|---|---|
| `notebooks/hypotheses/H06.qmd` | `44a461a44e26413bc919268de20a218b1a272cf442177ae4a732f2805f53f18b` |
| `audit/hypotheses/H06/H06_analysis_preparation.qmd` | `a4b35a1997fdae48b2e751d31a70147bd4149354eddd2a703d6473abbc67ea97` |

Recheck both identities immediately before implementation and stop if another task has changed either source. This source-only pass covers only these two reader-facing hourly H06 QMDs. Do not read, edit, link, or otherwise depend on H06_daily Stage 2 working files. Do not edit shared Quarto configuration, central ledgers, bibliography, stored scientific results, figure assets, analysis scripts, or manuscript files.

## Result-report structure

Normalize the current mixed `#`/`##` heading levels and use the approved reader order:

1. scientific question;
2. a Quarto note callout with the exact visible title **Answer in brief**;
3. outcome, day type, activity, previous sleep, primary near-eye/complementary chest roles, and exact fitted samples;
4. common-effect model, participant-cluster-robust inference, site-interaction model, and FDR families in plain language;
5. principal result: @fig-h06-core-effects and @tbl-h06-primary-effects;
6. supporting site-specific context, required data sensitivity, chest and paired-day results, working-variance and influence checks;
7. model checks;
8. clearly labelled exploratory diary and nonlinear time-of-day analyses;
9. interpretation and limitations;
10. a concise preregistration-deviation section with the exact dynamic links below; and
11. source data, figure reproducibility, technical provenance, and the companion link.

Keep the exploratory timing displays clearly separate from the confirmatory hourly mean analysis. Move implementation/frozen/production language out of the reader flow while preserving every scientific qualification.

## Preparation/provenance companion structure

Use this approved information order:

1. purpose and reciprocal hourly H06 result link;
2. concise analysis path;
3. verified inputs, outcome/analytical unit, predictor construction, previous-night linkage, and exact samples;
4. observed response/support, site-day-activity cells, local-clock support, and true-time sequences;
5. primary common-effect and site-interaction models, estimands, HC3 uncertainty, and multiplicity;
6. model checks, influence assessment, and named sensitivities;
7. accepted exploratory nonlinear clock-time analysis and additional diary measures; and
8. code/output map, hashes, environment, and reproduction guidance in a subordinate technical-provenance section.

Replace frozen/pinned/gate/production/historical language in scientific sections with the current input or qualification. Keep exact identities and commands only where reproducibility requires them. Keep this provenance chain wholly separate from unfinished H06_daily work.

## Approved vocabulary and first-use explanations

- Define **melanopic equivalent daylight illuminance (melEDI)**, the primary near-eye sensor position, and complementary chest sensor position at first use; chest is not ocular exposure.
- Define **participant-hour** and **participant-day** wherever their denominators first matter.
- Replace “expected supported-hour near-eye melEDI” as a leading label with a plain description such as **estimated mean hourly near-eye melEDI among observed hours that met the support criteria**. Preserve the exact estimand and support rules.
- Explain the direction of each comparison: free versus work day, active versus sedentary hour/day status, and the ratio per one additional hour of previous sleep. Preserve the null ratio of 1.
- Define a **participant-cluster-robust 95% confidence interval (95% CI)** as allowing observations from the same participant to be related and using the HC3 small-sample correction. `HC3` and `95% CI` may remain thereafter.
- Introduce **false-discovery-rate (FDR) adjustment** at first use and `FDR` thereafter. Replace every reader-facing `Benjamini–Hochberg`/`BH` abbreviation in prose, captions, alt text, table labels, cell text, and notes with FDR wording. The full method name may remain only in technical reproducibility detail. Preserve the three primary, three site-interaction, and separate site-specific families exactly.
- Replace unexplained `site heterogeneity`/`site-varying model` with **predictor-by-site interaction model** or **site interaction**. First explain that the association of day type, activity, or previous sleep with hourly melEDI was allowed to differ by study site.
- Replace `equal-site` with **site-average estimate**, first explained as an average across sites that gives each site equal weight. Internal fields may remain.
- Use **model checks** as the reader umbrella term; `model diagnostics` may appear once parenthetically or in technical detail.
- Define each **sensitivity analysis** by the exact changed dataset, sample, covariance correction, site weighting, random-site specification, participant deletion, or site deletion.
- Explain the gap-timing-unaware dataset once in plain language: it applies the same general coverage rules but does not use the timing of remaining missing observations for metric-specific adjustment. The concise term may remain thereafter.
- For the paired-day analysis, say explicitly that the comparison uses the same participants and participant-days at both sensor positions but that three hourly keys differ at each placement; therefore an observation-level identity scatter is not valid. Do not claim exact common hours, equivalence, or a direct sensor-placement effect.
- Describe the exploratory time-of-day work as a **nonlinear GAM analysis** in which the associations with local clock time were allowed to bend across the day. Explain pointwise 95% CIs as applying at one displayed hour, not as simultaneous whole-curve bands.
- Explain a **symlog axis** at first use in the companion as linear from 0 to 1 lx and logarithmic above 1 lx, with labels remaining in lux.
- Every reader-facing site name must carry its ISO alpha-2 country code in prose, tables, figures, legends, captions, and alt text, using `config/site_display_registry.csv` exactly. Internal codes may remain only in code/provenance.

Use a short glossary box only if HC3, interaction, site-average, nonlinear timing, and pointwise-interval definitions cannot be carried concisely at first use.

## Dynamic links

Use only relative `.qmd` page targets:

- hourly H06 result → `[How the hourly H06 analysis was prepared](../../audit/hypotheses/H06/H06_analysis_preparation.qmd)`;
- hourly H06 companion → `[Hourly H06 results report](../../../notebooks/hypotheses/H06.qmd)`;
- where the gap/model-ready definition is currently repeated, result → `[Preparation 06](../preparation/06_model_ready_datasets.qmd)` and companion → `[Preparation 06](../../../notebooks/preparation/06_model_ready_datasets.qmd)`.

Replace current `.html` result/companion links and any other internal `.html`, `file://`, `_build`, build-directory, or absolute local page link. Preserve useful CSV/PNG source-data links.

Do **not** create a link to H06_daily. The future reciprocal link and its exact accepted source path are deferred until H06_daily has accepted Stage 3/4 reader sources. Later integration must not otherwise reopen this harmonized hourly report.

## Exact preregistration-deviation integration

`REPORT-016` is sealed and the central reader page is integrated. Add a result-section anchor such as `{#h06-preregistration-deviations}` and link each of these four current scientific deviations literally to its exact lower-case anchor:

- [`DEV-015`](../preregistration_deviations.qmd#dev-015): the accepted main H06 estimand is supported hourly geometric-mean melEDI rather than the preregistered daily metric set;
- [`DEV-030`](../preregistration_deviations.qmd#dev-030): the primary family is limited to work/free day, Active/Sedentary status, and previous-night sleep duration;
- [`DEV-031`](../preregistration_deviations.qmd#dev-031): the accepted zero-inclusive quasi-Poisson population-average model, participant-cluster HC3 inference, separate predictor-by-site models, and distinct exploratory nonlinear clock-time analysis;
- [`DEV-032`](../preregistration_deviations.qmd#dev-032): the separately declared FDR families and the boundary between average associations, interactions, and exploratory site screens.

Use the same four exact targets from the companion as `../../../notebooks/preregistration_deviations.qmd#<lower-case-id>` wherever those choices are explained. Keep the entry descriptions concise and current; do not reproduce historical machine statuses or imply that the accepted hourly analysis is unfinished. Add a reciprocal companion link to the result section, `../../../notebooks/hypotheses/H06.qmd#h06-preregistration-deviations`, where it materially aids navigation. Statistical site-specific departures from a site-average association are model estimates, not preregistration deviations.

Do not add links merely because an entry appears in the broad hypothesis crosswalk. Do not expose resolved implementation history as a current scientific deviation. Every visible stable-ID mention must be the linked literal ID, and every deviation statement in these two reader pages must point to the exact central entry. Preserve all scientific wording and numerical content except the approved plain-language contextualization.

## Exact Quarto identifier repairs

Change only the labels and any dynamic references that point to them; keep every prepared object, native `gt_tbl` pipeline, figure/table value, and Quarto caption relationship unchanged.

| Current label | Approved label |
|---|---|
| `exact-samples` | `tbl-h06-exact-samples` |
| `multiplicity-registry` | `tbl-h06-fdr-adjustment` |
| `primary-effects` | `tbl-h06-primary-effects` |
| `primary-site-heterogeneity` | `tbl-h06-primary-site-interactions` |
| `site-specific-significance-table` | `tbl-h06-site-specific-associations` |
| `gap-effect-comparisons` | `tbl-h06-gap-sensitivity-comparisons` |
| `key-sensitivities` | `tbl-h06-key-sensitivities` |
| `influence-summary` | `tbl-h06-influence-checks` |
| `core-diagnostic-summary` | `tbl-h06-model-checks` |
| `exploratory-diary-effects` | `tbl-h06-exploratory-diary-associations` |
| `figure-readability-qa` | `tbl-h06-figure-readability-checks` |
| `core-effects-figure` | `fig-h06-core-effects` |
| `primary-site-figure` | `fig-h06-primary-site-associations` |
| `paired-placement-figure` | `fig-h06-paired-placement` |
| `residual-clock-figure` | `fig-h06-residual-clock` |
| `exploratory-two-part-day-type-figure` | `fig-h06-exploratory-day-type-time` |
| `exploratory-two-part-activity-figure` | `fig-h06-exploratory-activity-time` |

Do not relabel executable code chunks that are not figure/table cross-reference targets merely to make them resemble outputs. Verify all new labels are unique project-wide and no literal old `@label` reference survives.

## Principal and supplemental outputs

The author has provisionally authorized one display-only adjustment and wants to see the focused outputs before final approval.

- **Main figure:** @fig-h06-core-effects after the identifier repair. Keep the accepted three aligned forest-plot panels, values, intervals, null line, row order, and primary/contextual distinction. Explain participant-cluster HC3 intervals once and replace technical supported-hour wording with the plain estimand description.
- **Main table:** @tbl-h06-primary-effects after the identifier repair. Keep its native `gt_tbl`, three rows, comparison directions, accepted ratios/95% CIs/p-values/FDR decisions, and common-effect model. Use a concise Quarto caption and targeted notes for comparison directions, HC3, and FDR.
- Treat all other hourly H06 outputs as supporting or supplemental. Preserve every prepared object, stable key, order, unit, value, source-data link, and Quarto-owned caption. Do not promote, remove, consolidate, substantially redesign, or recompute them.
- Apply only small source-level harmonization: terminology, typography, panel/caption/alt hierarchy, table notes/wrapping, country-coded sites, and non-colour cues. Do not regenerate PNGs now. Return a list of assets whose baked-in labels or site names require later display-only refresh from stored accepted source data.

## Scientific and computation boundary

This is display-only. Do not import, transform, join, filter, summarize, fit/refit models or GAMs, predict, simulate, bootstrap, recompute HC3, FDR families, site interactions, exploratory curves, influence checks, or sensitivities; do not rebuild shared preparation or run Quarto. Do not change data, samples, support definitions, models, estimates, intervals, p-values, model checks, sensitivities, multiplicity, or claims. Do not touch H06_daily. Do not edit stored scientific tables/figures/source data/manifests in this pass. If wording exposes a possible scientific discrepancy, stop that document and return a scoped issue.

## Evidence to return

### Source-only return

- confirmation of both pre-edit identities and post-edit SHA-256 values;
- exact source-line change map and heading normalization;
- complete old→new identifier check, project-wide uniqueness check, and no unresolved literal cross-reference;
- static checks for reciprocal/Preparation `.qmd` targets, no internal `.html`/build/absolute page links, no H06_daily link, no reader-facing `BH`, country-coded sites, interaction/site-average terminology, and no unexplained internal production terms in the main flow;
- exact occurrence inventory for `DEV-015`, `DEV-030`, `DEV-031`, and `DEV-032`; resolution of every target and the result-section anchor; confirmation that no other unlinked preregistration-deviation mention remains;
- assertions that every prepared table/figure object, key, order, unit, value, caption ownership, and stored artifact is unchanged except approved labels/notes;
- source-only evidence for @fig-h06-core-effects and @tbl-h06-primary-effects plus deferred baked-in asset labels;
- ownership evidence showing no H06_daily, non-owned QMD, shared config/ledger, bibliography, artifact, script, lockfile, or manuscript file changed.

### Focused render return after explicit compute-window release

- one bounded render for each changed hourly H06 QMD under R 4.6.1 and the Nature Health profile, serialized rather than project-wide;
- existing focused hourly H06 report/preparation structural, source-link, identifier, alt-text, native-`gt`, and manifest verifiers without analytical recomputation;
- source/HTML hashes, all repaired anchors, resolved references, semantic table counts, captions/notes/figures/alt-text checks, and no H06_daily dependency;
- reader-size previews of @fig-h06-core-effects and @tbl-h06-primary-effects at normal/narrow widths and 200% zoom;
- no-scientific-change confirmation against accepted hourly H06 stored outputs and protected identities.
