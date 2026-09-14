# H03 REPORT-017 order 34a test-contract correction

Date: 2026-08-15

Status: **PASS; bounded source-only correction sealed; rendering held**

## Authority and boundary

The controlling order is
`audit/report_harmonization/owner_orders/34a_h03_final_source_test_contract_correction.md`,
SHA-256 `87ed65c8ca3a975d756244a21e09cd26148f3894cb953b9ce9e05d8e3af454fa`,
8,346 bytes. The independently accepted stopped-state input is
`audit/report_harmonization/report017_h03_order34_stopped_state_independent_acceptance.md`,
SHA-256 `58fedadec5089f0f56d3e09f015e05bd17428113092bbd31955df44bc17b0b28`,
3,575 bytes. The dispatch manifest is
`audit/report_harmonization/report017_h03_order34a_dispatch_manifest.csv`,
SHA-256 `61229c5ad91bd2664061e1009b156a23a5cea0e0a5570393bc3514031b41bbcc`,
3,596 bytes.

Only `tests/hypotheses/H03/test_h03_report017_source_harmonization.R` was
changed in the verification contract. The two QMDs, existing scientific and
render-coupled tests, artifact manifests, HTML, profile, lockfile, scripts,
models, estimates, diagnostics, tables, figures, source data, and other
hypotheses were not edited or executed.

## Test identity

| State | SHA-256 | Bytes |
|---|---|---:|
| Before order 34a | `130647380e680f372a4e97e36e744d739cc173a7b764acc2da671c1a1c3d020d` | 24,956 |
| After order 34a | `1783acab381999fb123b8a7d11873b42e8b331f0c684ad65585e69ce41febd51` | 26,503 |

## Exact linked source-data contract

The test now requires 16 extracted targets, 16 unique targets, and exact
sorted-set equality with the following set:

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

The pre-existing link-resolution pass remains in place and passed for every
target.

## Whitespace-normalized qualification proof

Before the existing fixed-string qualification loop, the corrected test
derives:

```r
companion_semantic_text <- gsub("[[:space:]]+", " ", companion_text)
```

All eight required auxiliary filenames and all four required scientific
qualifications then match as fixed strings. The retained qualifications are:

- `no random light-source slopes, participant-day effect, or AR(1) term`;
- `descriptive, model-dependent, non-causal`;
- `not a mixed model, random-intercept model, random-slope`;
- `does not replace the accepted population-mean`.

No companion wording changed.

## Exact reverse diff

Applying the following reverse diff to the post-order-34a test restores the
pre-order-34a contract:

```diff
 linked_source_data <- all_links[grepl("artifacts/11_source_data", all_links)]
-expected_linked_source_data <- sort(c(
-  "../../artifacts/11_source_data/H03/H03_reader_heterogeneity_category_figure_data.csv",
-  "../../artifacts/11_source_data/H03/H03_reader_latitude_site_support.csv",
-  "../../artifacts/11_source_data/H03/H03_reader_temporal_chest_curves.csv",
-  "../../artifacts/11_source_data/H03/H03_reader_temporal_chest_ratios.csv",
-  "../../artifacts/11_source_data/H03/H03_reader_temporal_chest_support.csv",
-  "../../artifacts/11_source_data/H03/H03_reader_temporal_near_eye_curves.csv",
-  "../../artifacts/11_source_data/H03/H03_reader_temporal_near_eye_ratios.csv",
-  "../../artifacts/11_source_data/H03/H03_reader_temporal_near_eye_support.csv",
-  "../../artifacts/11_source_data/H03/H03_reader_temporal_residual_bins.csv",
-  "../../artifacts/11_source_data/H03/H03_reader_temporal_residual_points.csv",
-  "../../artifacts/11_source_data/H03/H03_reader_temporal_zero_calibration.csv",
-  "../../../artifacts/11_source_data/H03/H03_preparation_category_support.csv",
-  "../../../artifacts/11_source_data/H03/H03_preparation_clock_category_support.csv",
-  "../../../artifacts/11_source_data/H03/H03_preparation_participant_day_support.csv",
-  "../../../artifacts/11_source_data/H03/H03_preparation_positive_response_distribution.csv",
-  "../../../artifacts/11_source_data/H03/H03_preparation_site_category_support.csv"
-))
-stopifnot(
-  length(linked_source_data) == 16L,
-  length(unique(linked_source_data)) == 16L,
-  identical(sort(linked_source_data), expected_linked_source_data)
-)
+stopifnot(length(linked_source_data) >= 20L)

 auxiliary_required_source <- c(
@@
   "does not replace the accepted population-mean"
 )
-companion_semantic_text <- gsub("[[:space:]]+", " ", companion_text)
 stopifnot(all(vapply(
   auxiliary_required_source,
-  function(value) grepl(value, companion_semantic_text, fixed = TRUE),
+  function(value) grepl(value, companion_text, fixed = TRUE),
   logical(1L)
 )))
```

The reverse target is the independently pinned pre-edit identity
`130647380e680f372a4e97e36e744d739cc173a7b764acc2da671c1a1c3d020d`,
24,956 bytes. An in-memory byte-preserving application of this reverse diff
reproduced that exact byte count and SHA-256 identity.

## R 4.6.1 verification

The corrected test parsed completely under R version 4.6.1 (2026-06-24):

```text
Rscript --vanilla -e 'invisible(parse(file =
"tests/hypotheses/H03/test_h03_report017_source_harmonization.R"))'
H03 REPORT-017 source test parse PASS under R version 4.6.1 (2026-06-24)
```

The two prescribed tests were then run once each:

| Order | Command | Wall time | Exit | Final output |
|---:|---|---:|---:|---|
| 1 | `Rscript --vanilla tests/hypotheses/H03/test_h03_participant_random_intercept_assessment.R` | 0.48 s | 0 | `H03 participant random-intercept assessment checks passed.` |
| 2 | `Rscript --vanilla tests/hypotheses/H03/test_h03_report017_source_harmonization.R` | 1.78 s | 0 | `H03 REPORT-017 source harmonization checks passed under R 4.6.1. No QMD was executed.` |

The complete corrected test verified the exact target set, qualification
phrases, structural hashes, protected identities, historical and current
manifest mismatch sets, final QMD identities, and all remaining assertions.

## Final disposition

The source-only verification status is PASS. The old order-34 manifest remains
unchanged as historical stopped-state evidence. The separate order-34a
manifest is non-circular and is the final current seal. A first in-memory
manifest helper used `vapply()`'s named result in `identical()` against an
unnamed CSV column and therefore stopped on the name attribute. The corrected
helper removed only that transient name attribute; it verified all 26 paths,
hashes, byte counts, uniqueness, and non-circularity under R 4.6.1. No project
file was changed by either helper. No H03 render is released. Independent
harmonizer acceptance is the next action.
