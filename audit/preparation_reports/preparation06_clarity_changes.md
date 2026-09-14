# Preparation 06 clarity and invariant ledger

Original rewrite date: 2026-08-01

METRIC-010 amendment date: 2026-08-11

METRIC-011 amendment date: 2026-08-12

Scope: `notebooks/preparation/06_model_ready_datasets.qmd`

Status: owner-approved pattern applied; final-profile render verified

## Traceable rewrite operations

| Location | Reader obstacle | Meaning-preserving operation |
|---|---|---|
| Opening | Purpose, inputs, and execution boundary were spread across implementation-led sections. | Added a direct purpose statement, exact position in the preparation chain, first-use dataset explanation, and an informational render-boundary note. |
| Entire report | Rendering called production builders and verifiers. | Replaced every producing call with direct reads of accepted RDS/CSV outputs, SHA-256 and byte-size identity checks, required-column checks, and lightweight summaries. |
| Execution chain | Script responsibilities and handoffs had to be inferred from code. | Added a Mermaid chain plus a 13-step script/module/output table in execution order, including current MDER production, independent verification, amendment-audit finalization, repaired gap-timing-unaware MDER evidence, and the stored downstream repin record. |
| Participant inputs | Raw `kable` output obscured what was standardized and what remained unavailable. | Added compact `gt` tables for seven input types, value/free-text checks, and incomplete diary intervals. |
| Prepared-data comparison | Historical scenario labels conflicted with the approved terminology. | Applied “gap-timing-unaware dataset” throughout visible text and explained its coverage and missing-gap-timing meaning at first use. Internal historical filenames remain only where exact provenance paths are required. |
| Site and temporal context | Join and daylight-saving results were implementation-led. | Added plain-language explanations and compact tables for six row-preserving joins and nine elapsed-time provenance outcomes. |
| Shared model inputs | Participant and site sample sizes were dispersed across build objects. | Added submitted-manuscript site names/order/colours, near-eye/chest samples, admissible grid rows, and participant-input availability. |
| Active MDER | The shared input report did not expose the refreshed estimand, availability, or exact controlling identities. | Added the minute-pair rule, complete local-clock support, inclusive 720-minute boundary, metric-only failure, current primary/comparator summaries, independent audit evidence, and exact manifest/bundle identities. |
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
- Current MDER is available for 702 of 816 near-eye participant-days from 137
  participants (mean 0.7238529; median 0.7239000) and 732 of 902 chest
  participant-days from 152 participants (mean 0.7565438; median 0.7494261).
- The amendment changed zero cells in 43 shared non-MDER fields at both
  placements. The 618-by-47 site-context values remained exactly unchanged.
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
manifest bundles, the current metric manifest, or the stored MDER audit
outputs changes identity.

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
- Pre-amendment final-profile scoped baseline:
  `audit/preparation_reports/preparation06_final_profile_prerender_scoped_readset.csv`.
- Pre-amendment scoped baseline SHA-256:
  `1f579c88474e710dbe862c3b69328642f38b875dece94a7d66f43f1da4d21d98`.
- Pre-amendment scoped result: 131 of 131 paths unchanged, zero mismatches.
- Pre-amendment source QMD SHA-256:
  `9ef9cfa3c72b4a52cae7339cc56173e92d63a8343d12a490090b06e37b8a35a7`.
- Pre-amendment focused test SHA-256:
  `96312cc12fc4d962dc705ab4ff16548aff7c95c6ec9d7a64e1108718a31745ce`.
- Pre-amendment rendered HTML SHA-256:
  `295eec709d2720a3d504c0755d036265dfd618447775ee15bcf9a95a5856bb4f`.
- Rendered figure SHA-256:
  `058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da`.

## Repaired gap-timing-unaware MDER follow-up — 2026-08-11

- Replaced the incomplete first-repin MDER availability with 687 available
  and 124 unavailable near-eye days among 811, and 723 available and 174
  unavailable chest days among 897. The earlier 725/729 record is labeled
  explicitly as superseded.
- Added current repaired means and medians (near eye: 0.7242573 and
  0.7238676; chest: 0.7567377 and 0.7495175) and retained the verified 137
  and 152 participant counts.
- Pinned the repaired gap manifest, participant-day RDS, support RDS, and
  seven-file independent repair-evidence bundle. Pinned the refreshed base,
  site-context, H01, and pre-analysis manifests plus the stored downstream
  rebuild evidence that records their execution order.
- Reported the exact invariance results read from stored evidence: all 25,620
  non-MDER participant-day cells and all 618 × 47 site/daylight context
  values were unchanged. No downstream hypothesis result is read by the
  page.
- Retained the approved two-column execution-map layout (38% producing code,
  62% explanatory narrative). Final HTML inspection found and corrected two
  missing stage labels introduced by the added provenance rows; a regression
  check now rejects unlabeled rows.
- Bounded render and focused source/HTML test: **PASS**. The final 157-path
  read set was unchanged before and after the corrected render; baseline
  SHA-256
  `89d328b95417e71ca989b21de2a90b2dcd4afe2c7d2f28ae3b856b50a13de8e8`.
- Final source SHA-256:
  `8b32ad4b3fcc9feb14993a33832819828426382bffd4ea0c34d1e2b8de85d4c1`;
  focused test SHA-256:
  `ee0b3fd709afbcd2c66e15dd1faa3bc0ce7a10857596ac8a96d8ac4cae848396`;
  rendered HTML SHA-256:
  `0430d346db5acf488b49b80324af090272cae4fefced444f385100bc092bb9e7`.
- The site-composition figure was scientifically unchanged and again passed
  final-size QA for typography, clipping, overlap, wrapping, balance, and
  distinguishability. Its SHA-256 remains
  `058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da`.

## Initial METRIC-010 amendment — 2026-08-11

- The first amendment pass pinned the eight Preparation 06 manifest files to their exact approved
  SHA-256 identities before checking every listed member.
- Added the current metric manifest
  `7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43`,
  independent MDER audit manifest
  `5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb`,
  current base manifest
  `6cfbfb18a2f6b1e31613e3fba803c3fbf64eb63e37155ae4fffd437a213b3ad0`,
  and base input bundle
  `1161f46fb0c63e0b578a2f2435cd5c8a4ffd566a4ec910be87c8bc7fb54b58df`.
- Explained the active one-minute-ratio estimand and kept the historical
  ratio-of-integrals/profile gate visibly separate.
- Added two compact `gt` tables for current MDER availability and exact
  provenance. Paths contain explicit wrap points and hashes contain invisible
  wrap opportunities; the existing 38%/62% execution-map repair remains in
  place.
- Focused source and rendered-HTML test: **PASS**; 17 semantic `gt` tables,
  no visible raw tibble output.
- Final METRIC-010 scoped baseline: 141 paths; SHA-256
  `5c1da24014311d43a1d39bbb3f1dbb9c6795ea75fe893126822e9791efefdccc`;
  post-render result: 141 unchanged, 0 mismatches.
- Amended source SHA-256:
  `6380855ab9342fe4fa34872b402c00b69a074541ed5f19bd2865db3496d8e110`;
  focused test SHA-256:
  `ca5ad601332cc6664de053538969a822cba79dbf5df2eea562ff920cf673af44`;
  rendered HTML SHA-256:
  `c5a0bd6c9701027b7832653f9c77450e9dd1fafdf93b3f4ec51ce967030640c8`.
- The site-composition figure was unchanged and again passed final-size QA;
  its SHA-256 remains
  `058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da`.

## METRIC-011 numerical-zero follow-up — 2026-08-12

- Added a plain-language L10 handoff section explaining the 0.1 lx offset
  geometric mean, the source-verified numerical tolerance, the requirement
  that every finite source minute be exactly zero, and the separation of
  missing minutes from zeros.
- Added a compact three-column result table (15%/18%/67%) and a two-column
  provenance table (32%/68%). Long paths contain explicit wrap points and
  hashes contain invisible wrap opportunities. The established script map
  remains a two-column 38%/62% display, avoiding a narrow narrative column.
- Reported exactly eight changed primary L10 cells: three near eye and five at
  the chest. Seven windows contain 600 observed zeros; one chest window
  contains 547 observed zeros and 53 missing minutes. All 816 near-eye and
  902 chest participant-days remain in the shared inputs.
- Stated that every non-L10 scientific value, every sample definition, every
  30-minute and hourly value, and all gap-timing-unaware scientific values are
  unchanged. H01 primary preparation inherits only the eight L10 values; its
  sample and contract do not change. Gap-timing-unaware H01 science is
  unchanged, and no hypothesis model was fitted or refitted.
- Expanded the execution map to 14 steps. The final row names
  `audit/scripts/finalize_l10_METRIC_011.R`, the independent core and MDER
  verifiers it called, the seven-file evidence bundle, and the dependent
  preparation manifests it resealed. The earlier MDER downstream-repin bundle
  is explicitly version-bound rather than presented as current identity
  evidence.
- Pinned current identities: metric manifest
  `028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e`;
  site/context manifest
  `c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518`;
  base manifest
  `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce`;
  base input bundle
  `e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916`;
  near-eye/chest shared RDS files
  `013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a`
  and
  `497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057`.
- Pinned the current H01 primary, H01 gap-timing-unaware, and preanalysis
  manifests as
  `25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72`,
  `e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b`,
  and
  `f3c4bfbf120d2023c045b44e3c7c04c58bce1f8d11621956bca1e5ede90c5623`.
- Focused source and rendered-HTML contract: **PASS**. The 168-path scoped
  pre-render baseline has SHA-256
  `f03f6a9e7eccba3b4cbdbd8dc494b44b48adb583c73f5d9fa93556412260fe30`;
  the immediate pre-render and post-render checks each found 168 unchanged
  paths and zero mismatches.
- Final source SHA-256:
  `434b5e7ae4839b248b457253bb581ba867cbaa933dda0ba568a47645c092358b`;
  focused test SHA-256:
  `e4b02061832be158372b54e1c473e0f221ab84cdd0aa7fb38e7d41cfb82f6f51`;
  rendered HTML SHA-256:
  `8211aff02f0f886211347e1d363d721036bb08017bc06b773dacfd36320cd401`.
- Direct inspection of the unchanged 2,160 × 1,958 pixel site-composition
  figure found no clipping, overlap, distorted text, awkward wrapping,
  compressed data region, or indistinguishable bars. Its SHA-256 remains
  `058a7d41c484827dd70cf1fc88cece25d225e6715993529165d6ac0b603a59da`.
- Automated visual inspection of the local HTML was blocked by the browser's
  `file://` safety policy. Final HTML inspection nevertheless confirmed the
  intended column groups, explicit path wrapping, resolved stage labels, and
  absence of raw tibble output; the focused HTML test rejects missing labels
  and required tables.
