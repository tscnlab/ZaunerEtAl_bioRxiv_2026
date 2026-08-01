# Preparation 06 clarity and invariant ledger

Date: 2026-08-01

Scope: `notebooks/preparation/06_model_ready_datasets.qmd`

Status: owner-approved pattern applied; final-profile render verified

## Traceable rewrite operations

| Location | Reader obstacle | Meaning-preserving operation |
|---|---|---|
| Opening | Purpose, inputs, and execution boundary were spread across implementation-led sections. | Added a direct purpose statement, exact position in the preparation chain, first-use dataset explanation, and an informational render-boundary note. |
| Entire report | Rendering called production builders and verifiers. | Replaced every producing call with direct reads of accepted RDS/CSV outputs, SHA-256 and byte-size identity checks, required-column checks, and lightweight summaries. |
| Execution chain | Script responsibilities and handoffs had to be inferred from code. | Added a Mermaid chain plus an eight-step script/module/output table in execution order. |
| Participant inputs | Raw `kable` output obscured what was standardized and what remained unavailable. | Added compact `gt` tables for seven input types, value/free-text checks, and incomplete diary intervals. |
| Prepared-data comparison | Historical scenario labels conflicted with the approved terminology. | Applied “gap-timing-unaware dataset” throughout visible text and explained its coverage and missing-gap-timing meaning at first use. Internal historical filenames remain only where exact provenance paths are required. |
| Site and temporal context | Join and daylight-saving results were implementation-led. | Added plain-language explanations and compact tables for six row-preserving joins and nine elapsed-time provenance outcomes. |
| Shared model inputs | Participant and site sample sizes were dispersed across build objects. | Added submitted-manuscript site names/order/colours, near-eye/chest samples, admissible grid rows, and participant-input availability. |
| H01 handoff | Prepared-frame counts could be mistaken for fitted-model samples. | Added separate 17-metric tables for the primary and gap-timing-unaware datasets, defined support hours, and stated that final fitted samples are checked later. |
| Figure | The older overview used reduced multi-panel source data and historical labels. | Drew one focused site-composition figure from the complete stored `categorical_levels.csv`, with all nine sites, registered colours, direct counts, horizontal facets, caption, alt text, and paired source-data link. |
| Final provenance | Durable inputs passed to later analyses were not consolidated. | Added manifest-identity, exact script/output, handoff-artifact, and environment tables. |

## Scientific and reporting invariants

- No source value, questionnaire score, metric, inclusion flag, model frame,
  or accepted analytical artifact was changed.
- No production script, hypothesis computation, model, prediction,
  autocorrelation estimate, bootstrap, simulation, or Shapley calculation was
  run.
- Normalized row counts remain 191 demographics, 186 chronotype, 184 LEBA,
  184 VLSQ-8, 1,174 exercise-diary, 30,199 light-exposure-diary, and 1,276
  sleep-diary records.
- The report retains 27 light-exposure-diary records with incomplete
  intervals and one sleep-diary record without a wake time, while stating why
  interval calculations cannot use them.
- Site context remains 618 site-dates across nine sites; all six joins retain
  their rows with zero unmatched site/date records.
- Shared inputs remain 141 near-eye participants across 816 participant-days
  and 39,168 30-minute rows, plus 154 chest participants across 902
  participant-days and 43,296 rows.
- H01 remains 17 metric contracts. Prepared frames are not described as final
  fitted-model samples, and unavailable support hours remain unavailable.
- Near-eye remains primary and chest remains complementary.
- Visible terminology uses melEDI, “period,” submitted site names, and the
  approved dataset labels.

## Mechanical checker reconciliation

The `clarify-scientific-writing` invariant checker was run against the
pre-rewrite source preserved at
`/tmp/preparation06_model_ready_datasets_original.qmd`. It reported expected
token differences because this was a complete provenance rewrite rather than
a sentence-level edit. Added numerical tokens are stored outcome counts,
layout constants, paths, and QA identifiers; removed tokens largely belonged
to production code and superseded wide displays. Added cross-references and
acronyms belong to the new Quarto structure and provenance explanations.
There were no numerical citation groups in either version, and no equation,
citation, reported estimate, uncertainty interval, or model interpretation
was introduced or changed.

Scientific quantities were independently reconciled to the accepted stored
manifests and sample-flow files in R. The page stops if any of its eight
manifest bundles changes identity.

## Figure QA under REPORT-011

The final 7.5-inch by 6.8-inch PNG was inspected at its generated size and at
the intended full-width HTML presentation. Result: PASS.

- no cropped or clipped labels, bars, counts, facets, or axes;
- no overlapping text or marks;
- no stretched, condensed, or distorted text;
- no undesirable wrapping, orphaned words, or broken units;
- 9–10 pt axis, count, and facet text remains readable at final size;
- horizontal facet strips prevent the long dataset label from compressing the
  data region;
- the data region and surrounding labels are balanced;
- bars and registered site colours remain distinguishable;
- caption, alt text, and paired source-data link are present.

## Final bounded checks and identities

- Static and rendered-HTML contract: **PASS**.
- Final-profile scoped baseline:
  `audit/preparation_reports/preparation06_final_profile_prerender_scoped_readset.csv`.
- Scoped baseline SHA-256:
  `1f579c88474e710dbe862c3b69328642f38b875dece94a7d66f43f1da4d21d98`.
- Scoped result: 131 of 131 paths unchanged, zero mismatches.
- Source QMD SHA-256:
  `9ef9cfa3c72b4a52cae7339cc56173e92d63a8343d12a490090b06e37b8a35a7`.
- Focused test SHA-256:
  `96312cc12fc4d962dc705ab4ff16548aff7c95c6ec9d7a64e1108718a31745ce`.
- Rendered HTML SHA-256:
  `295eec709d2720a3d504c0755d036265dfd618447775ee15bcf9a95a5856bb4f`.
- Rendered figure SHA-256:
  `058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da`.
