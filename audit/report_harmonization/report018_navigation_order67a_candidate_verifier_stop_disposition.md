# REPORT-018 Order 67a candidate-verifier stop disposition

Date: 2026-09-02

Status: `VERIFIER_ONLY_STOP_ACCEPTED_ONE_CONTINUATION_AUTHORIZED`

Owner: navigation integration task `01a02dde-497e-7a92-8fd8-b8cc7ff360ac`

This is a continuation under the already dispatched Order 67a. It is not a
second dispatch, does not create another render allowance, and does not widen
the shared-shell transformation.

## Independent finding

The Order 67a candidate stop is independently accepted as a verifier-only
failure. R 4.6.1 reproduces all of the following:

- the production build remains exactly the accepted 892-file baseline with
  zero symbolic links;
- the isolated candidate retains 892 files with zero symbolic links;
- its exact build delta is the 37 registered HTML routes and no other path;
- the isolated include is the authorized postimage
  `153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980`,
  1,542 bytes;
- all 37 candidate pages reproduce the accepted ordered HTML `id` sequence;
- all 37 pages reproduce the accepted duplicate-ID names and integer counts;
- the accepted legacy baseline remains exactly seven routes, 63 duplicate ID
  values, 149 extra instances, and 212 nodes carrying duplicated IDs; and
- the seven raw `identical()` failures arise only because `table()` records
  the source expression as the name of its `dimnames` list. The accepted table
  carries `accepted_ids`; the candidate table carries `candidate_ids`.

No HTML identifier, element, content, navigation behavior, semantic
relationship, scientific result, source, stylesheet, live build member,
shared include, or corpus-manifest member changed. No browser QA, promotion,
manifest reseal, Quarto command, or render occurred.

The durable independent checker
`scripts/report_harmonization/check_report018_navigation_order67a_candidate_verifier_stop.R`
passes under R 4.6.1 with:

```text
ORDER67A_CANDIDATE_STOP=VERIFIER_ONLY build=892/892 delta=37/37 id_sequences=37/37 duplicate_routes=7 values=63 extra=149 nodes=212 dimname_only=7 production=unchanged R=4.6.1
```

## One exact verifier correction

Preserve the sealed implementation
`order67a_transform_verify_promote.R` at SHA-256
`5cbbaae8a152fc4b2db38853b5258519b6646481483e6314ddede90b7abc1f16`,
65,084 bytes, and preserve the complete first candidate and stop evidence.
Create a new task-owned implementation postimage rather than modifying the
sealed file in place.

In the new copy, replace only:

```r
duplicate_multiset_exact <- identical(
  accepted_duplicate_counts,
  candidate_duplicate_counts
)
```

with:

```r
duplicate_multiset_exact <- identical(
  names(accepted_duplicate_counts),
  names(candidate_duplicate_counts)
) && identical(
  as.integer(accepted_duplicate_counts),
  as.integer(candidate_duplicate_counts)
)
```

This comparison remains fail closed on any added, removed, renamed, or
recounted duplicate ID. It ignores only the non-HTML R `dimnames` label.
Require R parse and Air checks, an exact one-hunk reverse proof to the sealed
implementation, and a new pre-execution script seal.

## Single continuation boundary

The owner may proceed once as follows:

1. Rehash the 14-row owner stop manifest and the central disposition manifest
   exactly. Re-run the independent central checker once and require its exact
   PASS contract.
2. Preserve `/private/tmp/nathealth-order67a.N5FZ0K` and its contents as
   stopped evidence. Record its complete file inventory and the 37-route
   transition set before continuing.
3. Create one new empty candidate root and one new empty recoverable backup
   root under `/private/tmp`.
4. Run the corrected task-owned implementation in `candidate` mode exactly
   once against the new roots. Require every existing Order 67a static, DOM,
   link, semantic, reversal, legacy-ID, build, stylesheet, H06, and prospective
   corpus-manifest gate to pass.
5. Perform the already authorized candidate browser QA. Only after its complete
   PASS, perform the already authorized atomic 38-path promotion, direct
   HTML-hash-only corpus reseal, production browser QA, H06 deferred QA, and
   final seal under the unchanged Order 67a contract.

The corrected implementation may be invoked in its already defined
`candidate`, `promote`, and `postflight` modes as required by that contract.
There is no Quarto or render allowance. Candidate generation is authorized
once because the first candidate run stopped before producing a promotable
verification package. Promotion remains authorized once only.

Stop and seal on any genuinely new candidate, browser, promotion, manifest,
production, H06, or teardown defect. Do not patch or retry again.

## Preserved boundaries

All Order 67a prohibitions remain in force. In particular, do not edit QMDs,
page-visible HTML content, stylesheets, profiles, tests, scientific data or
artifacts, package libraries, lockfiles, handoffs, manuscript sources, search
or sitemap assets, or ledgers. Do not run Quarto, knitr, Pandoc, a semantic
hook, report helper, analytical script, broad manifest builder, or another
target. Do not commit, push, upload, delete historical evidence, or alter a
cache.

