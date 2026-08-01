# Preparation-report rewrite plan

Date: 2026-08-01

Branch: `rewrite/NH`

Status: Preparation 06 showcase approved; scoped continuation authorized for Preparations 01–05 and 07

## Scope and governing boundary

The seven preparation reports will be rewritten as scientific preparation and
provenance companions. A reader should be able to follow the data-to-analysis
chain without knowing the repository's audit workflow or internal task history.
The recognizable Preparation 01–07 sequence and each page's scientific purpose
will be retained.

Rendering may perform only bounded file-identity and schema checks and
lightweight descriptive summaries read from stored preparation artifacts. It
must not import source data from the network, rebuild preparation artifacts,
derive metrics, construct model frames, fit models, regenerate predictions, or
write scientific outputs. `notebooks/placement_decision.qmd`,
`notebooks/descriptives.qmd`, all H01–H11 files, shared Quarto configuration,
central ledgers, manuscript files, and `renv.lock` are read-only for this task.

No physical `AGENTS.md` file was present in the checkout or its MeLiDos parent
directories when inspected. The complete `AGENTS.md` instructions embedded in
the delegated task are therefore the governing project instructions.

## Authorized specialist guidance

- `$quarto-authoring`: bounded knitr execution, cross-references, informational
  callouts, figures, `gt` tables, Mermaid diagrams, and narrow HTML rendering.
- `$clarify-scientific-writing`: traceable rewrite for scientifically
  knowledgeable readers outside the immediate specialty, using minimum
  sufficient explanation and an invariant ledger.
- `$create-gt-tables`: semantic, compact, accessible `gt` tables built only as
  a presentation layer over stored outputs.

## Computational environment

- R: 4.6.1 (2026-06-24)
- Project library:
  `renv/library/macos/R-4.6/aarch64-apple-darwin23`
- Quarto CLI: 1.9.37
- `gt`: 1.3.0
- `knitr`: 1.51
- `dplyr`: 1.2.1
- `readr`: 2.2.0
- `ggplot2`: 4.0.3
- `digest`: 0.6.39

The ordinary project R startup was blocked by an `renv` sandbox lock held by
another process in the shared checkout. Bounded inspection and later rendering
therefore use the same R 4.6.1 project library with
`RENV_CONFIG_SANDBOX_ENABLED=FALSE`; no package is installed or updated and no
`renv::status()` call is permitted.

## Protected-file checksum baselines

The baseline was created before any authoring source was edited:

- inventory:
  `audit/preparation_reports/preparation_report_protected_baseline.csv`;
- inventory SHA-256:
  `7b6650477e6221091be2d9839840adaccaadb2a31f6297874455c86b08d556d3`;
- protected files: 2,094;
- protected bytes: 5,593,443,736;
- algorithm: SHA-256 over file bytes;
- coverage: every existing file under `artifacts/`, all H01–H11 notebook
  sources, all `scripts/hypotheses/`, all `scripts/pipeline/`, all
  `audit/hypotheses/`, hypothesis tests, the shared hypothesis-companion test,
  and H01–H11 handoffs.

At every handoff, each baseline path must still exist with the same byte size
and SHA-256 value. Any mismatch is a blocking failure. New preparation-report
documentation or display-only files do not weaken this comparison because all
pre-existing protected paths remain checked individually.

The whole-checkout gate was subsequently found to be overbroad for a shared
checkout in which hypothesis and descriptive tasks legitimately continue in
parallel. The original inventory and all mismatch evidence are preserved, but
the coordinator authorized a page-specific stable-input gate for continuation.
The new foundational baseline is
`audit/preparation_reports/preparation_reports_scoped_continuation_baseline.csv`
(13 paths; SHA-256
`35835f8cc46fd0790f9d0d9c6d3d0fa6550a9b84c4b68cf25954f548f7b82691`).
Each page-specific pre-render baseline adds its own Quarto source, every file
read, all manifest-listed accepted preparation artifacts it reports, all
described production scripts/modules, and any additional registry or contract.
Only changes inside that exact read set block the page. Unrelated H01–H11,
descriptive, and coordinator-ledger updates are recorded as excluded concurrent
work. The full decision is in
`audit/preparation_reports/scoped_readset_decision.md`.

## Current report inventory and bounded-render replacement

| Page | Current executable behavior | Main reader-facing weakness | Bounded replacement |
|---|---|---|---|
| Preparation 01 | Calls `build_import_alignment()` and can rewrite imported and aligned data, state intervals, audits, and manifests. | The scientific rules are present, but the page asks readers to infer outcomes from long `kable` tables and build objects. | Read `import_alignment_artifacts.csv`, `state_interval_artifacts.csv`, and the stored audits under `artifacts/02_aligned/`; show source identity, one-minute aggregation, state alignment, sample counts, checks, and exact handoff files. |
| Preparation 02 | Calls `build_coverage_sample_flow()` and can rewrite coverage data and sample-flow artifacts. | The page is detailed but implementation-led, and it mixes the rationale, rule definitions, and raw output tables. | Read `coverage_artifacts.csv`, `coverage_settings.csv`, daily/hourly coverage, gap runs, and `sample_flow.csv`; show the 50%-per-hour and 80%-per-day rules, all-zero screen, retained participants/days/minutes, missingness, checks, and handoff paths. |
| Preparation 03 | Calls `build_reference_profiles()` and can relearn and overwrite all reference profiles and relevance maps. | The rationale is strong, but the page renders the production build and exposes several dense support summaries without a concise execution map. | Read `reference_profile_artifacts.csv` and stored settings, provenance, support, exceedance-distribution, and relevance-map tables; explain what was learned, why participant balancing matters, support failures, validations, and exact outputs without learning a profile. |
| Preparation 04 | Calls the state-support and MDER support builders and then `build_metric_derivation()`, which can rewrite metric artifacts. | The source is very long, combines approved decisions with result-producing calls, and relies on wide `kable` tables. | Read `state_support_gate_artifacts.csv`, `mder_support_gate_artifacts.csv`, `metric_artifacts.csv`, and stored settings/admissibility/support/gap files; separate metric definitions, time/state handling, retained counts, unavailable values, validations, and outputs. |
| Preparation 05 | All R chunks have `eval: false`; rendering displays no current acquisition results. | The page is safe but cannot show that 63 expected sources, object checks, column checks, and pinned identities passed. | Read `model_input_acquisition.csv`, `pinned_downloads.csv`, and the stored object/column audits; explain the network-only acquisition step, exact source identities, checks, and local files without downloading anything. |
| Preparation 06 | Calls nine production builders or builder-linked verification workflows: normalization, the predefined comparison dataset, site/solar context, temporal provenance, base data, H01 primary frames, H01 comparison frames, and the pre-analysis comparison. | Rendering can rebuild accepted data. Visible prose and tables use forbidden historical scenario labels, many tables are raw and excessively wide, and the two figures lack alt text. | Replace every builder/verifier with direct reads, manifest identity checks, schema checks, and lightweight summaries. Use the approved dataset terminology, semantic `gt` tables, one site-composition plot from stored figure source data, a Mermaid chain, and exact script/output paths. |
| Preparation 07 | Reads stored showcase files but calls a verifier that reproduces fixed-seed selection and other checks. | The page is comparatively reader-focused but lacks an explicit render boundary, script/output map, `gt` tables, and a concise explanation of which checks are read versus calculated. | Read the fixed selection, source data, and manifest directly; show the existing accessible figure, site/day selection, stored checks, and producing scripts without rerunning selection or preparation. |

## Preparation 06 showcase contract

### Scientific purpose and position in the chain

Preparation 06 receives the fixed files acquired in Preparation 05 and the
accepted metric outputs from Preparation 04. It harmonizes questionnaire and
diary structures, attaches participant and site context, preserves both local
clock time and actual elapsed time, and stores shared and hypothesis-specific
inputs. It hands those stored inputs to the hypothesis analyses; it does not
fit a model.

### Stored inputs read during rendering

- `artifacts/12_manifests/model_input_normalization.csv`
- `artifacts/12_manifests/manuscript_prepared_data_artifacts.csv`
- `artifacts/12_manifests/site_solar_context_artifacts.csv`
- `artifacts/06_model_data/temporal_provenance/artifact_manifest.csv`
- `artifacts/12_manifests/base_model_data_artifacts.csv`
- `artifacts/12_manifests/H01_model_data_artifacts.csv`
- `artifacts/12_manifests/H01_manuscript_prepared_data_artifacts.csv`
- `artifacts/12_manifests/preanalysis_comparison_artifacts.csv`
- selected stored RDS/CSV files named by those manifests;
- `config/site_display_registry.csv` and
  `config/metric_display_registry.csv` for visible labels and ordering.

### Execution order to explain

1. `scripts/pipeline/build_model_input_normalization.R` standardizes data
   structures while preserving source values; it writes normalized modality
   files and audits.
2. `scripts/pipeline/build_manuscript_prepared_data.R` assembles the predefined
   gap-timing-unaware dataset and its correction/crosswalk records separately
   from the primary dataset.
3. `scripts/pipeline/build_site_solar_context.R` attaches verified site/date
   daylight context and checks every many-to-one join.
4. `scripts/pipeline/build_temporal_sequence_provenance.R` links shared
   local-clock outcomes to true elapsed-time intervals without changing light
   values.
5. `scripts/pipeline/build_base_model_data.R` joins metrics, participant
   information, and site context while retaining rows and recording data
   availability.
6. `scripts/pipeline/build_h01_model_data.R` creates the first approved
   hypothesis-specific frames and metric-specific inclusion records.
7. `scripts/pipeline/build_h01_manuscript_prepared_data.R` applies the same
   H01 implementation contract to the gap-timing-unaware dataset.
8. `scripts/pipeline/build_preanalysis_comparison.R` creates the stored,
   descriptive comparison tables and figure source data.

Each script's function module, inputs, rationale for separation, and exact
output directory will be shown in a compact table. None is sourced or called
when the page renders.

### Meaning invariants for the rewrite

- No source value, score, metric, inclusion flag, sample, model frame, or
  artifact changes.
- The normalized input files retain 191 demographic rows, 186 chronotype rows,
  184 LEBA rows, 184 VLSQ-8 rows, 1,174 exercise-diary rows, 30,199
  light-exposure-diary rows, and 1,276 sleep-diary rows.
- Twenty-seven light-exposure-diary records lack a complete interval (one RISE
  and 26 THUAS); one MPI sleep-diary record lacks a wake time. They remain in
  their prepared files but are unavailable to calculations requiring a
  complete interval.
- The stored daylight context contains 618 site-date combinations across nine
  sites; all six main metric-file joins retained their rows with no unmatched
  site/date records.
- Local wall-clock time remains the time-of-day coordinate; UTC remains the
  elapsed-time and sequence coordinate. Autumn repeated intervals and spring
  missing intervals retain their recorded provenance.
- Shared primary near-eye data contain 141 participants, 816
  participant-days, and 39,168 30-minute grid rows; complementary chest data
  contain 154 participants, 902 participant-days, and 43,296 30-minute grid
  rows.
- H01 contains 17 metric contracts. Prepared-frame counts are not described as
  exact fitted-model samples. Valid measurement hours are derivation support,
  not independent model observations.
- Exact metric-support hours unavailable from retained gap-timing-unaware
  artifacts remain explicitly unavailable rather than being reported as zero
  or reconstructed.
- The gap-timing-unaware dataset still passed the general 50%-per-hour and
  80%-per-day coverage rules; its name means that the timing of remaining
  missing observations was not used for an additional metric-specific
  adjustment. At this first explanation only, the primary dataset may be
  described as something that could be interpreted as a time-sensitive
  primary metric dataset. Thereafter it is simply the primary dataset.
- Near-eye remains primary; chest remains complementary and is never pooled
  with near-eye data.
- Reader-facing text uses `melEDI`, “period” rather than “bout”, submitted
  site names/order/colours, and no forbidden historical scenario names.

### Reader-facing displays

- informational note describing what rendering calculates and what it reads;
- Mermaid data-to-analysis chain with alt text and caption;
- manifest/identity check table;
- normalized questionnaire and diary outcome table;
- site/daylight join and temporal-provenance tables;
- exact primary and complementary samples by submitted site name;
- primary versus gap-timing-unaware H01 prepared-frame sample table;
- script/module/output map;
- stored-artifact handoff table;
- a site-composition plot built only from the complete level-count source
  `artifacts/08_diagnostics/preanalysis_comparison/categorical_levels.csv`,
  with approved dataset labels, registered site colours, an informative
  caption and alt text, and a visible link to that exact source-data CSV.

The complete level-count source is used because the older
`figure_categorical_distribution_data.csv` was deliberately reduced for its
multi-panel overview and omits the smallest near-eye site. The complete stored
file contains all nine sites and requires no regenerated data or changed
scientific value.

All tables will be `gt_tbl` objects. Quarto owns each `tbl-*` caption and no
duplicate `gt` caption will be added.

## Focused verification before rendering

The Preparation 06 structural test will fail if any executable R chunk
contains a builder, a production verifier, file writing, directory creation,
download/network code, model fitting, prediction, autocorrelation estimation,
resampling, simulation, or Shapley computation. It will also check:

- note-callout semantics for the render boundary;
- required first-use and later-use dataset terminology;
- absence of forbidden reader-facing scenario/workflow labels;
- required script and exact artifact paths;
- `gt` table labels/captions;
- figure caption, alt text, registered site display inputs, and paired source
  CSV link;
- absence of `knitr::kable()` and raw console/tibble dumps;
- no writes from the rendered source; and
- unchanged protected-file hashes after the render.

Only after this static contract passes may the single page be rendered with:

```text
RENV_CONFIG_SANDBOX_ENABLED=FALSE quarto --profile nathealth render notebooks/preparation/06_model_ready_datasets.qmd --to html
```

The HTML will then receive structural checks and browser/screenshot visual
inspection. Word and the full project are out of scope.

## Owner-review and continuation gate

After Preparation 06 passes its focused tests, visual inspection, and protected
checksum comparison, work stops. Preparations 01–05 and 07 will not be edited
until the owner explicitly approves the Preparation 06 HTML pattern in this
task.

The owner approved the Preparation 06 presentation pattern after requesting a
two-column repair to Table 13. The repaired page passed its focused structural
test. The coordinator then authorized sequential continuation under the scoped
stable-input gate described above; no downstream hypothesis result is required
by the remaining preparation reports.
