# Hypothesis analysis-preparation and provenance companions

Decision ID: `REPORT-007`
Date: 2026-08-01
Status: approved

## Decision

Stage 4 of every completed hypothesis analysis is a scientific
analysis-preparation and provenance companion at
`audit/hypotheses/Hxx/Hxx_analysis_preparation.qmd`. The companion sits
immediately after `notebooks/hypotheses/Hxx.qmd` in the Nature Health website
and links reciprocally with that results report.

“Stage 4” and “Step 4” are workflow shorthand only. Neither label appears in
the companion's reader-facing title, prose, diagram, caption, table, callout,
or navigation. The page is not an internal task report.

The revised H02 companion is the accepted exemplar:

- source:
  `audit/hypotheses/H02/H02_analysis_preparation.qmd`;
- source SHA-256:
  `2085fa99e6a17a188578a42c6adceed35bf4913a99de0953ce779b81f33a464c`;
- result companion:
  `notebooks/hypotheses/H02.qmd`;
- focused structural test:
  `tests/hypotheses/H02/test_h02_preparation_report.R`.

## Reader and purpose

The companion is written for a scientific reader who knows the research
question but does not know the audit workflow. It uses the same specific,
plain scientific language as the accepted H02 results report.

It explains:

1. which data and code produced the reported result;
2. why each analytical operation was needed;
3. what each operation contributed; and
4. what evidence shows that it behaved as intended.

It does not mention coordinator or worker roles, task ownership, approvals,
gates, step numbers, migration history, or discarded construction variants
that are irrelevant to scientific interpretation. Necessary technical terms
are explained on first use without replacing precise scientific language.

The predefined data-preparation sensitivity follows `REPORT-010`: call it the
**gap-timing-unaware dataset**, explain at first use that the general
50%-per-hour and 80%-per-day coverage rules still apply but that the timing of
remaining gaps is not used for an additional metric-specific adjustment, and
then use that term consistently. At that first explanation only, the primary
dataset may be described as something that could be interpreted as a
time-sensitive primary metric dataset. Thereafter it remains simply **the
primary dataset**.

## Required analytical chain

The page starts with the verified base or handoff data and identifies every
exact analytical input. It then explains, in analytical order:

- input identity, schema, content, key, and value checks;
- model-frame and sample construction;
- exclusions, support, missingness, and coverage rules;
- transformations and units;
- temporal ordering and sequence boundaries where relevant;
- model construction and the central model settings;
- estimands, contrasts, multiplicity, uncertainty, and inference;
- convergence, distributional, residual, temporal, and other applicable
  diagnostics;
- influence checks;
- registered sensitivity branches; and
- the provenance of reported figures, tables, source data, and claims.

The page names the hypothesis-specific scripts or modules in execution order.
For each, it explains what the script does, why that work is separate, what it
reads, and what it produces. It points to stored models, predictions,
resampling outputs, figures, tables, diagnostics, source data, and manifests
rather than implying that these are recreated during page rendering.

Exact participants, participant-days, observations or hours, sites, and
relevant per-site or category-specific samples are reported. Useful compact
tables and plots describe input distributions, support, missingness or
coverage, and intermediate quantities needed to understand the chain. A
Mermaid data-to-result diagram is used when it makes the sequence materially
easier to understand.

## Execution boundary

Rendering may perform only:

- bounded file-identity and schema checks; and
- lightweight descriptive calculations from the hypothesis-specific model
  frames.

Rendering must not refit a model, re-estimate autocorrelation, regenerate
model predictions, rerun a bootstrap or simulation, recompute a Shapley or
other model-performance analysis, or repeat another expensive scientific
calculation.

An informational note—not a warning, important, caution, or danger callout—
states which quantities are calculated during rendering and which are read
from stored outputs. Externally generated results need not be recomputed, but
the page names their producing scripts and exact output locations.

## Displays and accessibility

- Reader-facing tables use `gt` and are split into conceptually coherent,
  readable pieces rather than made excessively wide or multi-page.
- Axes use scientifically appropriate scales. Under `REPORT-013`, plots of
  non-negative, strongly right-skewed values with meaningful exact zeros use
  `LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)`; this is the default
  for melEDI plots containing zero. Labels and breaks remain in original units.
- A discrete mass such as exact zeros is reported separately when combining
  it with a continuous distribution would compress the latter. The page must
  state explicitly whether those observations remained in the fitted model.
- Every figure has an informative caption and non-empty alt text.
- Every durable plot has paired source-data CSV files containing the exact
  transformed data used by its layers.
- Every figure follows `REPORT-011`: unless a narrower placement is specified,
  typography is assessed at a 170-mm display width. An A4 page may be used as
  a QA simulation only; the final asset is tightly bounded to the figure and
  is not saved on an A4 canvas. The QA record includes base design dimensions,
  literal export scale, exported dimensions, intended display width, display
  reduction factor, smallest essential nominal text, and effective final text. The
  export-scale setting changes the device dimensions and does not multiply
  theme fonts or graphical marks. Content and canvas dimensions are
  proportionate, and post-adjustment visual QA checks clipping, overlap, text
  distortion, line wrapping, legend layout, and remaining data-region size.
  Browser pixels or a native-size preview alone are not a pass.

## Website and source identity

The coordinator adds a companion to `_quarto-nathealth.yml` only after its
source exists. It appears immediately after the corresponding results page in
both the render list and the “Hypothesis analyses” navigation. The two pages
contain reciprocal HTML links and previous/next navigation resolves between
them.

The authoring QMD remains available beside the website HTML. The QMD copy in
`_build/nathealth/` must be byte-identical to the authoring source.
Hypothesis-specific manifests and handoffs record:

- authoring source and website source copy;
- rendered HTML;
- figures and paired source data;
- scripts and stored scientific outputs;
- manifests and environment identity; and
- SHA-256 checksums and byte sizes.

The final worker inventory excludes itself and any other identity that would
create a circular checksum chain.

## Required structural verification

Each hypothesis adds a focused test that verifies at least:

- forbidden workflow terminology is absent from the reader-facing source and
  output;
- the execution-boundary callout has informational note semantics;
- result/preparation links, sidebar order, and previous/next navigation;
- source and website-copy byte identity;
- figure captions, alt text, and paired source data;
- compact `gt` table presence;
- absence of hypothesis-specific model-fitting, prediction, autocorrelation,
  resampling, simulation, or Shapley calls from executable render chunks; and
- manifest coverage, existence, byte sizes, and hashes.

The reusable verifier in
`scripts/pipeline/hypothesis_preparation_provenance_contract.R` supplies the
common checks. Each hypothesis extends it with its own expensive function
names, required figures, required tables, and scientific sample assertions.

## Ownership and closure

Hypothesis tasks own their hypothesis-specific companion source, tests,
artifacts, manifests, and handoff. They do not edit shared Quarto
configuration or central ledgers. The coordinator owns website integration
and the central record. After website rendering, the hypothesis task refreshes
its non-circular manifests, tests, and handoff around the final website
identities.

This documentation closure does not reopen accepted inference unless it
exposes a substantive discrepancy.

## Reopening condition

Reopen this reporting contract if a companion becomes an internal task report,
performs scientific model computation during rendering, loses source-copy or
output provenance, omits model-specific sample information, uses inaccessible
figures or tables, or no longer appears beside its results report.
