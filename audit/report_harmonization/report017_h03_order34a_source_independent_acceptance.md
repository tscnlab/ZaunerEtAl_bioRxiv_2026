# REPORT-017 H03 order 34a source independent acceptance

Date: 2026-08-15

## Disposition

H03 order 34a is independently accepted for source-only harmonization. The result QMD, preparation/provenance companion, and H03-AUX-001 participant random-intercept synchronization are coherent and scientifically separated from the population-mean Mundlak-style sensitivity. No scientific discrepancy is open. H03 rendering remains held.

## Accepted identities

- result QMD: SHA-256 `45ea5a009efd3b451c392dfc23bef584c7b16e087bf4093780b051cfde42ae41`;
- preparation/provenance companion: SHA-256 `59270288388e48ceef880ffa4a2ba0e87b8deeb9a8046b49510c4e525ff8c131`;
- source-only test: SHA-256 `1783acab381999fb123b8a7d11873b42e8b331f0c684ad65585e69ce41febd51`, 26,503 bytes;
- H03 handoff: SHA-256 `49beea589f5709e598975703f2bed4337e203c40a1ec64d4e218be4eda4a6a48`;
- order34a correction record: SHA-256 `ccb5b015e6a5bbd0e7fc8d1ecc39457d499210cf554f77737c0a44b3bdb1201e`;
- final 26-row non-circular source manifest: SHA-256 `81c4fe09be66071130cbffe5bad5058b540f9c60b347124eca8fffb085ab098d`.

The pre-order test identity `130647380e680f372a4e97e36e744d739cc173a7b764acc2da671c1a1c3d020d`, 24,956 bytes, is exactly reconstructable by the recorded reverse diff. The original order-34 stopped manifest remains unchanged at SHA-256 `155084278391e9720e1bbc5d04d158f753d1f9182cb33238751277ee75b722fe`.

## Independent R 4.6.1 verification

The following completed successfully in order:

1. `tests/hypotheses/H03/test_h03_participant_random_intercept_assessment.R` passed against the accepted stored auxiliary outputs without refitting.
2. `tests/hypotheses/H03/test_h03_report017_source_harmonization.R` reached its final success message and confirmed that no QMD was executed.
3. All 26 current-manifest paths, SHA-256 values, and byte counts matched; paths were unique and the manifest did not contain itself.
4. Scoped `git diff --check` passed.

The source test requires exact membership of all 16 linked source-data targets and resolves them. It uses whitespace-normalized source only for four already present wrapped qualification phrases. All other endpoint, formula, numeric-token, artifact, link, anchor, site-name, vocabulary, no-scientific-call, and protected-identity gates remain in force.

## Output role and hold

`tbl-h03-participant-random-intercept` remains catalogued as `supplement: detailed result or context`. `fig-h03-primary-estimates` and `tbl-h03-primary-results` remain the provisional principal H03 outputs. Their roles and appearance remain provisional until the later focused render and author visual review.

No Quarto render, QMD execution, model computation, artifact regeneration, shared-profile edit, central-ledger edit, commit, or push occurred during this acceptance.
