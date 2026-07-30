# Reference-profile training-site count

Finding ID: `FIND-011`  
Status: repair verified  
Severity: low; provenance metadata only  
Date: 2026-07-30

## Finding

Every fixed reference-profile row correctly stored the delimited set of sites
used to train that profile, but `training_site_count` was 48 for every row.
The intended value is the number of distinct sites represented by
`training_sites`: one for site-specific profiles, seven or eight for
leave-one-site-out profiles, and eight or nine for pooled profiles depending
on placement.

The cause was sequential evaluation inside `dplyr::mutate()`. After the
character column `training_sites` had been created, the expression
`length(training_sites)` referred to that newly created 48-row column rather
than to the local vector of distinct training sites. Forty-eight is the
number of 30-minute clock bins in each profile stratum.

## Scientific effect

None. The defect affects provenance metadata only. The training-site names,
training rows, participant-balanced medians, supported bins, reference
values, and relevance-map formulas do not use `training_site_count`.

The independent verifier reconstructs expected site membership directly from
the Preparation 02 inputs and therefore detects this defect without trusting
the stored count. Full scientific-value reconstruction is completed before
the repaired profile artifacts are accepted.

## Repair and verification

The profile learner now stores the scalar count before entering
`dplyr::mutate()` and writes it through the environment pronoun. The
low-level regression test requires:

- pooled counts equal the three synthetic input sites;
- site-specific counts equal one;
- leave-one-site-out counts equal two; and
- every stored count equals the number of delimited site identifiers.

The low-level profile suite and the independently reconstructed canonical
Preparation 03 audit pass under R 4.6.1 with warnings treated as errors. The
canonical audit completed 190 of 190 checks, including 48 independently
reconstructed profile strata and all 288 training-site metadata checks. It
also verified that scientific profile values, support, relevance-map
normalization, dose-only correction, and input immutability were unchanged.

Accepted canonical hashes:

- profile-artifact manifest:
  `47853dcaa543349d75c54a48d31d50295a5bc1c0a16bbc4bb7f2cc8946f55a3e`;
- reference profiles:
  `ddd066a1c9ee76113962c996fc43672e00cba1aad36d7ad034da40b72a434074`;
- metric-relevance maps:
  `57fbac2170c136bec52cb0dd6b9dcf012b89361368b295527c153e554755c689`.

Evidence:

- `scripts/pipeline/reference_profiles.R`;
- `scripts/pipeline/verify_reference_profile_artifacts.R`;
- `tests/test_reference_profiles.R`; and
- `tests/test_verify_reference_profile_artifacts.R`.

## Reopening condition

Reopen if any stored count disagrees with the explicit training-site set, if
the repaired rebuild changes a scientific profile value, or if a downstream
artifact retains a pre-repair profile hash.
