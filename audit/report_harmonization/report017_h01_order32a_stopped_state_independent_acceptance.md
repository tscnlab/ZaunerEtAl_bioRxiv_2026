# REPORT-017 H01 order-32a stopped-state independent acceptance

Date: 2026-08-15

Disposition: accepted as a complete fail-closed verifier stop; H01 source acceptance remains pending

## Reproduced evidence

The H01 owner preserved all 28 dispatch identities and reconstructed the exact six-file order-32 baseline at `/private/tmp/H01-order32a-baseline.A5iuk8`.

The new verifier is SHA-256 `620b2fe71fcf25c542afa9c435f925887454db895059cbd4aa8617046369ea18`, 34,808 bytes. Removing only its missing-argument guard reproduces the original verifier SHA-256 `79eef03a3978b85447e93590346a69c165e05e4bfb1e64d89dd7b44ddc1e902c`, 34,759 bytes.

The complete R 4.6.1 verifier ran exactly once. It finished in 7.13 seconds with exit status 1, passed 62 of 66 source contracts, and passed all four focused tests. The owner did not patch or rerun it.

The four recorded failures are:

1. `companion_inline_r_allow_list`;
2. `result_top_level_assignment_allow_list`;
3. `companion_top_level_assignment_allow_list`; and
4. `companion_scientific_numeric_tokens`.

The 20-row non-circular owner manifest is SHA-256 `81b1e6000219987b8fb3ca9ff721647e72438dab324d857652b1fbfa55697427`. Independent R 4.6.1 replay verified 20 unique, self-excluded rows with exact hashes and byte counts. The 28-row preflight-preservation table reports every dispatch identity as `PASS`. Scoped `git diff --check` passed.

No QMD, test, current manifest, handoff, held HTML, profile, scientific artifact, original verifier, or earlier stopped record changed. No Quarto render, QMD execution, model operation, reporting builder, or artifact generation ran.

## Independent classification

R 4.6.1 reproduced the first three failures as one zero-length type issue. The current `multiset_difference()` helper returns `NULL` when no positive multiset difference exists. The contracts correctly expect `character(0)`. This explains why printed expected and observed summaries are identical while `identical()` evaluates false.

R 4.6.1 reproduced the fourth failure as one non-scientific identifier token. The only added token is `256` inside the authorized technical-provenance label `SHA-256` in the sentence:

> The manifest registry below retains the corresponding paths and SHA-256 prefixes.

The order-32 matrix explicitly requires paths and hashes to remain in technical provenance. Normalizing that exact identifier only inside numeric-token extraction produces 39 baseline and 39 current scientific numeric tokens with exact multiset equality.

There is no reader-source or scientific discrepancy in this stopped state.

## Release boundary

One final verifier-only order may correct both classifications together, run the complete verifier once against the retained exact baseline, and seal the result. All sources and renders remain held.
