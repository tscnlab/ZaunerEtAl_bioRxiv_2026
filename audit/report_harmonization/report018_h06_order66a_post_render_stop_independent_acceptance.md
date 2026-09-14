# REPORT-018 H06 Order 66a post-render stop: independent acceptance

Date: 2026-09-02

Disposition: `ACCEPTED_VERIFIER_ONLY_STOP_AFTER_SUCCESSFUL_RENDER`

## Scope and authority

This record independently accepts the fail-closed state produced after the
sole H06 Order 66a result render. It does not yet accept the rendered page,
because secure loopback visual QA has not run. It authorizes a separately
sealed no-rerender verification and QA continuation if all current identities
remain exact.

The accepted owner record is
`audit/hypotheses/H06/employment_eligibility_sensitivity/order66a_result_render/H06_order66a_post_render_verification_fail_closed.md`,
SHA-256
`5518c7304ab65c1b750e3fe0a94f25cfc96895c034b325857517836f541589c9`.
Its 33-row non-circular manifest is SHA-256
`eee5e8cec499db98425811277ebd9bac8e11b31a2676b777a07919bd1781b471`
and reproduces 33 of 33 paths by exact SHA-256 and byte count.

## Independent R 4.6.1 replay

The durable independent checker
`scripts/report_harmonization/check_h06_order66a_post_render_stop.R` passed
under R 4.6.1 with the accepted project library. It established:

- the five and only five failed assertions in the stopped verifier;
- 1,911 document IDs, all unique in a fresh parse of the canonical HTML;
- 14 native `gt` tables and 421 table-scoped header tokens, all resolving
  exactly once to an intended `th` within their own table;
- 14 nonempty Quarto `figcaption` table captions;
- one unique external GitHub `.qmd` edit target, rendered twice for the
  responsive navigation shell, and no internal `.qmd`, local filesystem, or
  build-path reader link;
- all 21 Order 66a dispatch paths exact after classifying only the authorized
  H06 result HTML transition, including correct absolute-path handling for
  the user-owned Sass database;
- the exact six-path target-owned build delta and zero symbolic links;
- the semantic ledger's 69 ID and 355 `headers`-attribute repairs, 424 total
  substitutions, exact raw reversal, exact reapplication, and unchanged
  non-semantic DOM;
- all 46 accepted employment-eligibility sensitivity members exact; and
- all 31 accepted standalone report-finalization checks still passing.

The unchanged focused reader-source test also passed independently under
R 4.6.1 for both reader QMDs and all three stored sensitivity tables.

## Five verifier-only classifications

1. `normalized_dom_without_mutable_values()` changes its supplied `xml2`
   document by reference. The failed verifier reused that changed object for
   later checks, collapsing 69 internal table IDs into one placeholder and
   creating exactly 68 apparent duplicates. A fresh parse has no duplicate
   document ID.
2. The same by-reference mutation replaced all 355 `headers` attributes with
   one placeholder before the table-scoped audit. In a fresh parse, their 421
   individual tokens all resolve exactly once to `th` elements in the same
   table.
3. The verifier searched for a native `caption` child of each `gt` table.
   Quarto places the accepted captions in the enclosing endpoint's
   `figcaption`; all 14 are present and nonempty.
4. The internal-link hygiene predicate was applied to external links. Its
   only `.qmd` finding is the legitimate HTTPS GitHub edit link. All internal
   links satisfy the local-path and source-path prohibition.
5. The protected-path audit prefixed the project root to an already absolute
   Sass-cache path. Direct absolute-path resolution reproduces the accepted
   cache SHA-256, 36,864-byte size, ownership, and absence of WAL or SHM
   sidecars.

No source, scientific, semantic, or demonstrated reader-page defect is
present in this five-item failure set.

## Preserved state and next boundary

The canonical rendered result remains
`_build/nathealth/notebooks/hypotheses/H06.html`, SHA-256
`b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9`,
4,898,662 bytes. The result and preparation QMDs, held preparation HTML,
focused test, standalone sensitivity report and its 46-member manifest, H06
handoff, profile, lockfile, H06 daily files, manuscript, and all scientific
artifacts remain exact.

A continuation may run only corrected read-only verification against this
existing HTML, then secure loopback visual QA, teardown, post-QA identity
checks, and a final non-circular seal. It may not run Quarto, edit a source,
change scientific content, rerender the result, touch the preparation page,
or release another target.
