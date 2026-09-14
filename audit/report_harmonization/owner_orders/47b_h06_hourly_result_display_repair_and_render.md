# REPORT-018 owner order 47b: H06 result display repair and render

Date: 2026-08-21  
Owner: H06  
Scope: one exact reader-table execution repair and one result-page render  
Status: released after exact dispatch preflight

## Controlling stopped-state acceptance

Order 47a completed the accepted three-literal provenance transition and then
stopped at cell 40 of 41 on one invalid display expression. The controlling
acceptance is:

- `audit/report_harmonization/report018_h06_order47a_stopped_acceptance.md`
  at SHA-256
  `26fd6a86cde8f035cdf867353a044de9a4ad3b3bce5bf3afce6d04eab14979e6`,
  5,025 bytes; and
- `audit/report_harmonization/report018_h06_order47a_stopped_acceptance_manifest.csv`
  at SHA-256
  `85ab9a20b9e7bd4180b900fab10255e0fe1527f72aae936ec910120e25e3c565`,
  3,263 bytes, with 20 exact unique non-circular rows.

The accepted current contract is
`b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f`
at 13,468 bytes and must not change.

## Hard preflight

Reproduce every hard row in
`audit/report_harmonization/report018_h06_order47b_dispatch_manifest.csv`
before mutation. Treat the coordination matrix as dispatch-time evidence only.
Stop on any other drift, competing render, build symlink, nonempty fresh
semantic directory, or mismatch in the retained order-47a evidence.

The exact mutable result-source preimage is:

- `notebooks/hypotheses/H06.qmd`
- SHA-256
  `468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2`
- 60,677 bytes

The stale target HTML is
`ff3518c09a4322dc8a2c23a961f2ef3ffc8d124843874547a40415c8330fd555`
at 6,109,797 bytes. The held companion QMD and HTML must remain
`f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`
and `222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae`.

## A. Exact source repair

In the `tbl-h06-figure-readability-checks` chunk only, change:

```r
reader_figure_qa |>
  dplyr::select(
```

to:

```r
reader_figure_qa |>
  dplyr::transmute(
```

Change no other byte. The required postimage is:

- SHA-256
  `2e88ad6b3a4aaffd2dfbf429a77c5d0865256554bb9b7799648fe63b976f1526`
- 60,680 bytes

Before rendering, require:

1. an exact one-token forward diff and reverse substitution to the preimage;
2. R 4.6.1 parse PASS for all result R chunks and inline expressions;
3. every chunk label and table/figure endpoint remains present exactly once
   and in the accepted order;
4. a complete-source scan finds zero remaining `dplyr::if_else()` expressions
   nested inside `dplyr::select()`;
5. read-only reconstruction of the exact six-row `reader_figure_qa` object
   from the three accepted figure-QA CSVs;
6. the repaired transformation returns exactly six rows and seven columns,
   preserves figure order and every numeric value, and maps all six accepted
   PASS statuses to `Verified`; and
7. the accepted contract, companion source and HTML, artifacts, source CSVs,
   profile, package lock, H06 daily sources, and complete protected set remain
   exact.

Do not create or edit a test, manifest, builder, or display artifact. Do not
run a historically coupled H06 test or any scientific model.

## B. Sole target render

If and only if section A passes, create a fresh absolute empty semantic-audit
directory under `/private/tmp` and run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

Use normal R 4.6.1 project-profile and renv startup with only the established
narrow access to the existing user-owned renv cache. The configured semantic
hook must run normally. Do not use `--no-execute`, bypass the profile or hook,
render the companion, render H06 daily, render another target, or run the full
project.

## C. Complete acceptance package

Apply every nonvisual and visual gate from order 47a to the fresh result page.
At minimum require:

- exit 0 and retained reversible semantic-hook evidence;
- exactly 11 native gt tables and six figure endpoints;
- unique document IDs and every explicit `headers` token resolving exactly
  once to the intended header in its own table;
- all accepted result/companion, Preparation 06, Supplementary information,
  deviation-page, and four DEV-anchor links resolving;
- exactly the held H06 daily target as the one permitted unresolved internal
  reader link and no other missing internal target;
- active navigation, nine country-coded sites, no forbidden local/build link,
  and no embedded error, warning, stderr, or unresolved cross-reference;
- all scientific and protected identities exact except the authorized result
  QMD transition and declared target build outputs;
- all build changes classified, with no symlink or unclassified delta; and
- secure loopback QA rooted exactly at `_build/nathealth`, bound only to
  `127.0.0.1`, at 1440 by 1000, 708 by 1000, 200-percent-equivalent, and
  intended final-output sizes.

Inspect all 11 tables and all six figures. For HTML tables, ordinary desktop
usability is controlling and a narrow table may use a contained horizontal
scroller. For exported outputs, the stored PNG at intended final size is the
controlling check. Inspect labels, values, typography, axes, legends, symbols,
panels, captions, disclosures, links, navigation, wrapping, clipping, overlap,
and page overflow. Stop the server and prove no listener and no post-QA drift.

Do not rerun the order-46 artifact verifier, historical Stage 3 test,
companion test, or pre-integration semantic transition test after rendering.
Verify the actual rendered page directly.

## D. Return and prohibitions

Return one combined completion or stopped record and one non-circular owner
manifest under `audit/hypotheses/H06/report018_order47b_result_render/`.
Record source diff and reverse proof, commands and versions, semantic summary
and ledger, endpoints, links, protected/build deltas, browser screenshots and
measurements, server lifecycle, and final identities.

If a genuinely new source, render, semantic, link, protection, or visual defect
appears, complete safe read-only inspection and stop once. Do not patch or
rerender.

No additional source cleanup, scientific computation, model, inference,
source-data change, table or figure regeneration, manifest or test edit,
contract change, profile, package, lockfile, ledger, companion render, H06
daily render, later target, full-project render, commit, push, upload, or
publication action is authorized. The H06 companion and every later serial
target remain held pending independent H06 result-page acceptance.
