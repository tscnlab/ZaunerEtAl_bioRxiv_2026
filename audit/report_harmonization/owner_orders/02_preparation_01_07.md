# Harmonization order 02 — Preparation 01–07

Date: 2026-08-12  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Controlling decisions: `REPORT-014` / `CHG-124`  
Dispatch mode: **source-only first; focused renders held until the coordinator clears the H06_daily Stage 2 compute window**

## Exact owned documents and dispatch identities

| Source | SHA-256 at order preparation |
|---|---|
| `notebooks/preparation/01_import_state_alignment.qmd` | `4708b90ba3dd56c21fad10d02be6a884890b668662f62631d762de1375b4f6c2` |
| `notebooks/preparation/02_coverage_sample_flow.qmd` | `50c069f8e987087e89c09f4397d197a5754a9de067c955ae9e338a6beeafbfad` |
| `notebooks/preparation/03_reference_profiles.qmd` | `d63499f95a39e3fbc335aef3a5f98439f14c24a27406e15a49c99ef79fb4119d` |
| `notebooks/preparation/04_metric_derivation.qmd` | `0de19fc8bdd68ff24c35dfb621d819f3cc6c6bacc532be8fc1b8b3b3242ac668` |
| `notebooks/preparation/05_model_input_acquisition.qmd` | `ee1910eacbd23329d651a160450d02041cbd175869a56963ac14caef24e7d95e` |
| `notebooks/preparation/06_model_ready_datasets.qmd` | `434b5e7ae4839b248b457253bb581ba867cbaa933dda0ba568a47645c092358b` |
| `notebooks/preparation/07_example_days.qmd` | `2285e7d173fb504b7ec47c247b4c8ad48bd0ec5304cacd60f022075a95d13a09` |

Recheck these identities immediately before implementation and stop if another task has changed a source. Associated Preparation-owned focused tests and manifests may be updated only where necessary to verify display-only source changes. Do not edit shared Quarto configuration, central ledgers, bibliography, hypothesis pages, or manuscript files.

## Shared preparation-page structure

Use this approved information order, allowing a short page-specific departure where a section truly has no content:

1. why this preparation step matters;
2. inputs and relevant definitions;
3. processing decisions in scientific order;
4. resulting data and exact sample/support consequences;
5. limitations or unresolved qualifications;
6. material links to adjacent preparation pages and exact deviations; and
7. technical provenance, hashes, and verifier evidence at the end or behind an audit/technical details section.

Keep the preparation sequence scientifically detailed, but remove stage/gate/worker/task/coordinator language, internal `METRIC-*`, `FIND-*`, `REPORT-*`, `CHG-*`, and `ENV-*` labels, repair chronology, test mechanics, hashes, and manifest prose from the main reader flow. Do not remove a technical detail that defines the data or supports a qualification; explain its scientific meaning first and move only the implementation trail.

## Document-specific requirements

- **Preparation 01:** explain import, time alignment, dual clock roles, state masks, and the resulting aligned records in reader order. Add a short how-to-read box only if timestamp/state terminology remains dense.
- **Preparation 02:** explain coverage, exclusions, gap handling, and sample flow in plain terms while retaining every exact denominator. Use one sample-flow table as the visual anchor if it already fits the stored evidence.
- **Preparation 03:** explain reference profiles before implementation detail. Keep this exact qualification visible and current: “Independent reconstruction of the current reference-profile input remains incomplete.” Do not resolve or weaken it. Move file-level provenance to restrained technical detail.
- **Preparation 04:** define the metric families and specialist terms before derivation detail. Keep this exact qualification visible: “Independent reconstruction of current diary-period support remains incomplete.” Do not resolve or weaken it. Add the approved short glossary box before the first dense metric display, limited to metric support, M10/L10, MDER, and transformed/back-transformed quantities.
- **Preparation 05:** lead with what inputs were acquired and why. Retain privacy, access, and immutable-release constraints, while moving repository/commit/acquisition mechanics to technical provenance.
- **Preparation 06:** make the model-ready chain and its exact sample consequences the main narrative. Preserve current metric definitions/exclusions and both Preparation 03/04-derived qualifications where they materially carry forward.
- **Preparation 07:** make the example days and how-to-read guidance primary. Explain shaded states, placements, and metrics in accessible language; move seeds, export mechanics, verifier names, and production detail out of the main flow.

## Approved vocabulary

- Use `nonlinear GAM analysis` only where a GAM is actually involved; first explain that the named association can bend rather than follow a straight line, then `GAM` may remain.
- Explain each transformed scale and what back-transformation returns to the original/practical unit; `back-transformed` may remain after that explanation.
- Explain autocorrelation before using `AR(1)` alone.
- Use `95% confidence interval (95% CI)` first and `95% CI` later.
- Use `false-discovery-rate (FDR) adjustment` first and `FDR` later; never reader-facing `BH`.
- Define sensitivity analyses by the exact changed dataset, sample, metric definition, or model choice.
- Use `same participants and participant-days at both sensor positions` before any shorter matched/common-sample label.
- Use `model checks` as the reader umbrella term.
- Every reader-facing site name must carry its ISO alpha-2 country code in prose, tables, figures, legends, captions, and alt text, following `config/site_display_registry.csv` exactly.

## Dynamic links

Use only relative `.qmd` page targets:

- Preparation 01 → `[Preparation 02](02_coverage_sample_flow.qmd)`;
- Preparation 02 → `[Preparation 03](03_reference_profiles.qmd)` and `[Preparation 04](04_metric_derivation.qmd)`;
- Preparation 03 → `[Preparation 04](04_metric_derivation.qmd)`;
- Preparation 04 → `[Preparation 06](06_model_ready_datasets.qmd)`;
- Preparation 05 → `[Preparation 06](06_model_ready_datasets.qmd)`;
- Preparation 06 → `[Preparation 07](07_example_days.qmd)` where the visual examples materially aid understanding.

Do not introduce `.html`, `file://`, `_build`, or absolute-path page links. Deviation-link work is centrally blocked in this source-only pass. Preparation 06 currently names `DEV-056`; preserve and report that location without editing the mention. A separate follow-up will supply the exact dynamic link after the sealed reader-disposition overlay and deviation QMD exist. If another preregistration-deviation statement is found, return its location and central ID; never invent, infer, or insert an ID or anchor now.

## Tables and figures

The current preparation tables are already native `gt`. Preserve their prepared rows, values, units, order, keys, and Quarto identifiers. Apply only the approved shared table hierarchy: one Quarto-owned title, genuine spanners, unit-bearing labels, restrained footnotes/source notes, accessible structure, and wrapping before type reduction. Do not convert a table to raw HTML or an image.

Preparation outputs are explanatory/supporting rather than principal manuscript outputs. Do not promote, remove, substantially redesign, or recompute a figure/table. Standardize only typography, panel labels, caption/alt-text conventions, country-coded site names, spacing, and accessible source-data links. Preserve the accepted Preparation 07 example-day panel content and all sample/support displays.

## Scientific and computation boundary

This is display-only. Do not import, transform, join, filter, summarize, rebuild, or validate scientific data beyond the existing report’s bounded display checks. Do not rerun shared preparation, metrics, models, prediction, simulation, bootstrap, Shapley work, or a full-project render. Do not change sample flow, denominators, state precedence, gap handling, metric definitions, values, models, estimates, intervals, p-values, diagnostics, sensitivities, or claims. If wording exposes a scientific discrepancy—especially around the Preparation 03/04 qualifications—stop that document and return the scoped issue.

## Evidence to return

### Source-only return

- pre-edit identity confirmation and post-edit SHA-256 for all seven sources;
- exact source-line change map to this order, including any justified structural departure;
- static checks for dynamic `.qmd` targets, no internal `.html`/build paths, country-coded site names, no reader-facing `BH`, and no unexplained internal production terminology in the main flow;
- confirmation that every existing table/figure data object, key, row order, unit, label ID, and stored artifact remains unchanged;
- explicit confirmation that the Preparation 03 and 04 qualifications remain visible and unweakened;
- ownership check showing no non-owned source, shared configuration/ledger, scientific artifact, or lockfile changed.

### Focused render return after explicit compute-window release

- one bounded render command/result per changed source under R 4.6.1 and the Nature Health profile, serialized rather than project-wide;
- the existing focused Preparation 01–07 structural/tests and manifest checks relevant to each changed page;
- source and targeted HTML SHA-256 identities, link/anchor results, native-`gt` counts, figure/caption/alt-text checks, and no-render-error evidence;
- focused previews only for materially changed table/figure presentation, with clipping, wrapping, hierarchy, and country-coded labels checked at reader size;
- no-scientific-change comparison against the accepted pre-edit source/artifact manifests.
