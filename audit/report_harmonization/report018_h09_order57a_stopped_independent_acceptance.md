# REPORT-018 H09 order 57a stopped-state independent acceptance

Date: 2026-08-22

Disposition: **ACCEPTED_HISTORICAL_MANIFEST_CLASSIFICATION_REQUIRED**

The sole order-57a H09 companion retry stopped correctly inside the immutable
Stage 3 manifest table before knitr could advance to the remaining companion
chunks, Pandoc, the semantic hook, helper execution, browser QA, or any build
mutation. The stop exposed exactly 19 accepted historical-to-live identities.
It did not expose an H09 source, scientific, page, or shared-input defect.

## Reproduced stopped state

Fresh R 4.6.1 verification reproduced:

- the owner stop record at SHA-256
  `d484752e15aee7eaf55750360e09df3958c4679c4f76dc78f20c84745afc6ada`,
  5,661 bytes;
- the owner failure verifier at SHA-256
  `2d357cc0fbf3305071c1e825911a7583165354adb3682063a2eabde66e8bc5e6`,
  17,133 bytes;
- the 17-check failure verification at SHA-256
  `1d212cbc0daa7887a73b2706b99198db49f417ef31f8d3296621294baa13947c`,
  with 17 of 17 checks passing; and
- the owner 58-row seal at SHA-256
  `89126ec7990c41ecbe8956c05b33926e29fdc0f42011b1383447beaccf2626f8`,
  with 58 of 58 paths exact, unique, and non-circular.

The three authorized provenance postimages remain exact and reverse exactly
to their accepted preimages. The current companion source is
`286c391fb228268804ba199d38bd5341509b3a66d434e30aa09fc1007a19443e`,
48,400 bytes. The immutable 108-row Stage 3 manifest remains exact at
`0103aad8bf3b2424358fc139b85b95564054745b180a80d1e12c27ff72e1bef2`,
24,678 bytes. All 851 build paths, 545 protected paths, and 16 historical
source-side support paths remain exact. No process from the failed retry
remains.

## Exact 19-row classification

The owner sealed the complete mismatch set at
`audit/hypotheses/H09/report018_order57a_companion_retry/reader_manifest_mismatches_sealed.csv`,
SHA-256
`7442ab696510b055a71018795cb5fa5366d0d67933b587fe17dafe81b09d191d`,
6,215 bytes. Independent verification requires this file to contain exactly 19
unique paths, their frozen historical SHA-256 and byte identities, their exact
current SHA-256 and byte identities, and no missing member.

Every row resolves to accepted current authority:

- the Stage 1 gate resolves through its exact current preparation-manifest
  row;
- the base-bundle audit resolves through the accepted METRIC-011 H09
  provenance-reseal manifest;
- the contract and input-audit transitions resolve through the order-57a
  authorized postimage and reverse-proof evidence;
- the Stage 2 runner, eight diagnostic/display files, figure manifest, result
  source, and result HTML resolve through the accepted order-56b display and
  result manifest;
- the profile and figure-readability decision resolve through the accepted
  H09 result-release pins; and
- the display registry resolves through its accepted result-release identity
  plus the order-57 MDER-only scope audit.

The durable classification records 19 of 19 rows as
`ACCEPTED_HISTORICAL_TO_LIVE`. The immutable manifest has exactly 87 other
live-exact rows after excluding its two explicitly mutable handoff records.
The accepted classification is therefore the closed set 87 live plus 19
historical. Any 20th mismatch, absent path, changed historical identity,
changed live identity, duplicate path, or unclassified row must fail closed.

## Complete downstream replay

The independent checker
`scripts/report_harmonization/check_report018_h09_order57a_stop_and_downstream_replay.R`
ran twice under R 4.6.1 with deterministic evidence and reported:

```text
REPORT018_H09_ORDER57A_DOWNSTREAM=PASS stop=58/58 verification=17/17 stage3=87+19 authority=19/19 chunks=22 later=3 endpoints=19+1+1 links=23/22 helper=554->555 semantic=19/102/588/690 preservation=851/545/16 R=4.6.1
```

The replay constructed the exact prospective source in temporary space,
executed all 22 R chunks including all three chunks after the stopped table,
and reproduced 19 native table endpoints, one figure endpoint, one top-down
Mermaid, 23 relative link occurrences to 22 unique resolving targets, and zero
prohibited scientific calls. The prospective QMD is exactly
`394a976e52faf002cb2034a13353a053aae8bfda8942a79c2eb007017cae014f`,
51,736 bytes, and reverses exactly to the current 48,400-byte source.

The complete prospective dedicated-helper inventory contains 554 unique
non-circular pre-render members and exactly 555 after the one target-generated
companion figure asset. A temporary semantic replay of the held HTML repaired
19 tables with 102 ID, 588 `headers`, and 690 total substitutions. Its 690-row
ledger reverses exactly to the held pre-hook HTML. All protected, build, and
historical support baselines remain exact.

## Bounded disposition

One consolidated continuation is eligible. It may edit only the Stage 3
manifest-check block in the H09 companion QMD, producing the exact prospective
source above. The new block must read and pin the sealed 19-row transition
file, preserve the Stage 3 manifest byte-for-byte, require exactly 87 live and
19 accepted historical rows, and fail on any additional mismatch.

Only after a complete pre-render replay passes may the owner make exactly one
H09 companion render retry. After a successful render, the dedicated H09
preparation-manifest helper may run exactly once, followed by the full
semantic, source, link, protected, build, visual, and teardown contract. No
blind or piecemeal retry is authorized.

No test edit, historical-manifest rewrite, broad manifest builder, result
render, model execution, scientific artifact regeneration, source-data
change, profile or lockfile change, later target, additional retry, commit,
push, upload, or publication change is authorized. The mandatory next stop is
independent H09 companion acceptance or one consolidated fail-closed return.
