# REPORT-017 order 34a: H03 final source-test contract correction

Date: 2026-08-15

Owner task: `019fbe52-c067-7521-b2cf-379c88ef1e78`

Controlling reader-harmonization decisions: REPORT-014 and REPORT-017

Status: released after a complete independent replay of the source-only test

## Purpose

Order 34 assembled the complete H03 result and preparation/provenance rewrite
and stopped at the first assertion in its new source-only test. Independent
review continued through the complete test on a temporary copy and found two
classification issues in total. Apply both together, then run one complete
source-only verification sequence. Do not edit either H03 QMD and do not
render.

Independent acceptance:
`audit/report_harmonization/report017_h03_order34_stopped_state_independent_acceptance.md`,
SHA-256 `58fedadec5089f0f56d3e09f015e05bd17428113092bbd31955df44bc17b0b28`,
3,575 bytes.

## Required preflight identities

Stop without editing if any hard pin differs:

| Path | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/hypotheses/H03.qmd` | `45ea5a009efd3b451c392dfc23bef584c7b16e087bf4093780b051cfde42ae41` | 68,198 |
| `audit/hypotheses/H03/H03_analysis_preparation.qmd` | `59270288388e48ceef880ffa4a2ba0e87b8deeb9a8046b49510c4e525ff8c131` | 75,638 |
| `tests/hypotheses/H03/test_h03_report017_source_harmonization.R` | `130647380e680f372a4e97e36e744d739cc173a7b764acc2da671c1a1c3d020d` | 24,956 |
| `tests/hypotheses/H03/test_h03_participant_random_intercept_assessment.R` | `30fa488114886eb4e9feeccc55f6f752e229585bfc1f2eb5b5a85bfba582bfc8` | 7,568 |
| `tests/hypotheses/H03/test_h03_stage3_reader_report.R` | `0af80c8dfede663d724c488f5b7947ca8635a944d789f7a552f6e932999bd3ef` | 18,080 |
| `tests/hypotheses/H03/test_h03_preparation_report.R` | `bddaa2393ead9317c5f526a00f75d2fd86e0e7efeaf84dcd2737e61b149a058a` | 8,412 |
| `tests/hypotheses/H03/test_h03_stage2.R` | `a174e3fe2a1a7832a5f6e8e8a98a3da8d88d85bd30e22917e554ae658f7ce596` | 19,424 |
| `audit/hypotheses/H03/report017_order34/H03_order34_execution_record.md` | `4dd0383d50a2bd0e04f438c3d27acc728f065b42610fd07a0c119dd698122582` | 3,319 |
| `audit/hypotheses/H03/report017_order34/H03_order34_source_manifest.csv` | `155084278391e9720e1bbc5d04d158f753d1f9182cb33238751277ee75b722fe` | 15,925 |
| `audit/handoffs/H03_worker_handoff.md` | `4d9e00d53b63ca8a69629bf73d90fbcd2710d8866bc24d338921d291343f7c43` | 28,615 |
| `artifacts/12_manifests/H03/H03_stage3_artifacts.csv` | `5f4f10528f1c49d52518a6dde36d6ce0ffd71869cab9bcde382bf9c9edce3170` | 83,962 |
| `artifacts/12_manifests/H03/H03_preparation_report_manifest.csv` | `5235b02c6c542a010336eca9569b77b269deb673d4659d794393d2427146393a` | 81,124 |
| `_build/nathealth/notebooks/hypotheses/H03.html` | `68aa07eb7470286d0d6da76114ce7bf346ee635974fe7403c1860ad4560c3d25` | 330,938 |
| `_build/nathealth/audit/hypotheses/H03/H03_analysis_preparation.html` | `813492b5b1941716c1996f8a0c1b88c658e6eefb52e2569be62744fe965308bf` | 900,339 |
| `_quarto-nathealth.yml` | `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3` | 7,480 |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` | 603,493 |

The dispatch-time coordination-matrix identity is evidence only, not an owner
hard pin while disjoint source-only hypothesis orders run in parallel.

## Exact correction 1: source-data targets

In `tests/hypotheses/H03/test_h03_report017_source_harmonization.R`, replace
the arbitrary `length(linked_source_data) >= 20L` assertion with a fail-closed
exact membership contract.

Require exactly these 16 unique link targets and no others:

```text
../../artifacts/11_source_data/H03/H03_reader_heterogeneity_category_figure_data.csv
../../artifacts/11_source_data/H03/H03_reader_latitude_site_support.csv
../../artifacts/11_source_data/H03/H03_reader_temporal_chest_curves.csv
../../artifacts/11_source_data/H03/H03_reader_temporal_chest_ratios.csv
../../artifacts/11_source_data/H03/H03_reader_temporal_chest_support.csv
../../artifacts/11_source_data/H03/H03_reader_temporal_near_eye_curves.csv
../../artifacts/11_source_data/H03/H03_reader_temporal_near_eye_ratios.csv
../../artifacts/11_source_data/H03/H03_reader_temporal_near_eye_support.csv
../../artifacts/11_source_data/H03/H03_reader_temporal_residual_bins.csv
../../artifacts/11_source_data/H03/H03_reader_temporal_residual_points.csv
../../artifacts/11_source_data/H03/H03_reader_temporal_zero_calibration.csv
../../../artifacts/11_source_data/H03/H03_preparation_category_support.csv
../../../artifacts/11_source_data/H03/H03_preparation_clock_category_support.csv
../../../artifacts/11_source_data/H03/H03_preparation_participant_day_support.csv
../../../artifacts/11_source_data/H03/H03_preparation_positive_response_distribution.csv
../../../artifacts/11_source_data/H03/H03_preparation_site_category_support.csv
```

Retain the existing link-resolution pass. Also require the extracted target
count to be 16 and the unique count to be 16 before exact sorted-set equality.
Do not change a QMD link or source-data file.

## Exact correction 2: wrapped qualification phrases

The companion contains both required scientific qualifications, but each is
wrapped across source lines. Before the existing `auxiliary_required_source`
fixed-string loop, derive a companion semantic string by replacing one or more
whitespace characters with a single space. Apply the existing qualification
loop to that normalized string.

Do not change the required phrases or remove an item from the vector. In
particular, retain exact requirements for:

- `no random light-source slopes, participant-day effect, or AR(1) term`;
- `descriptive, model-dependent, non-causal`;
- `not a mixed model, random-intercept model, random-slope`;
- `does not replace the accepted population-mean`;
- all eight auxiliary script/output filenames.

No scientific wording in either QMD may change.

## Files that may change

- `tests/hypotheses/H03/test_h03_report017_source_harmonization.R`;
- directly dependent current files under
  `audit/hypotheses/H03/report017_order34/` needed to replace the stopped
  execution status with the passing source-only seal;
- `audit/handoffs/H03_worker_handoff.md`;
- one new non-circular order-34a correction record and manifest under the H03
  evidence directory.

Do not edit either QMD, any existing H03 scientific or render-coupled test,
either current H03 artifact manifest, any HTML/build path, shared profile,
central or harmonizer record, scientific artifact, script, source-data file,
package file, lockfile, or another hypothesis.

## One complete verification sequence

1. Recheck every hard pin.
2. Apply both test changes before execution.
3. Parse the corrected test completely under R 4.6.1.
4. Run the unchanged auxiliary participant random-intercept test once.
5. Run the complete corrected REPORT-017 source-harmonization test once.
6. Require both tests to pass. The second must reach its final success message.
7. Verify the exact 16-target set, both wrapped qualification phrases, all
   structural hashes, protected identities, historical/current manifest
   mismatch sets, final QMD hashes, and all remaining assertions.
8. Run scoped `git diff --check`.
9. If everything passes, perform only the bounded non-analytical source seal.

If any new assertion fails, do not patch or rerun. Seal the full stopped state
once and return the complete remaining defect list.

## Required return

Return exact pre/post test identities and an exact reverse diff; R 4.6.1 parse
and command evidence; both complete test outcomes and runtimes; the exact
16-target set; the whitespace-normalized qualification proof; preservation of
both QMDs, five existing tests, both artifact manifests, stored HTML, profile,
lockfile, scientific artifacts, and other hypotheses; final execution, handoff,
correction-record, and non-circular manifest identities; and scoped diff-check
evidence.

Stop for independent harmonizer acceptance. No H03 render is released.

## Prohibitions

No Quarto, QMD execution, model fit or refit, prediction, simulation,
bootstrap, Shapley allocation, p-value calculation, scientific summarization,
figure or table regeneration, broad manifest builder, shared configuration,
central ledger, harmonizer-global edit, package or lockfile change, commit,
push, upload, or work on another hypothesis.
