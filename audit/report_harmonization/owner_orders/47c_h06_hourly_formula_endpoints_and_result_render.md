# REPORT-018 owner order 47c: H06 formula endpoints and result render

Date: 2026-08-21  
Owner: H06  
Scope: two exact Quarto table endpoints and one result-page render  
Status: released after exact dispatch preflight

## Controlling acceptance

Order 47b completed all 41 H06 cells and stopped only because two existing
native formula tables lacked Quarto `tbl-*` endpoints. The controlling
acceptance is:

- `audit/report_harmonization/report018_h06_order47b_stopped_acceptance.md`
  at SHA-256
  `3436599fac32997968063ae8d92e4e8afd8d224556a080f411b3e0eaff44f89c`,
  6,466 bytes; and
- `audit/report_harmonization/report018_h06_order47b_stopped_acceptance_manifest.csv`
  at SHA-256
  `ebc8ad67bb1f4794250783236e051a0157ab8dc21c8393c7535d92a92ab8b725`,
  3,545 bytes, with 22 exact unique non-circular rows.

The accepted current result source is
`2e88ad6b3a4aaffd2dfbf429a77c5d0865256554bb9b7799648fe63b976f1526`
at 60,680 bytes. The accepted current contract is
`b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f`
at 13,468 bytes.

## Hard preflight

Reproduce every hard row in
`audit/report_harmonization/report018_h06_order47c_dispatch_manifest.csv`
before mutation. The coordination matrix is dispatch-time evidence only.
Require no competing render, no build symlink, and a fresh absolute empty
semantic-audit directory. Stop on any unclassified drift.

The fresh but semantically unrepaired result HTML is
`dc62f37001c2d7e9f5a2daa9167023e006aafecc72c2d0137925093e573027c1`
at 4,862,444 bytes. It contains exactly 13 native gt tables, of which exactly
two lack a Quarto table endpoint. It is preflight evidence, not an accepted
final page.

## A. Exact endpoint repair

Edit only `notebooks/hypotheses/H06.qmd` and make exactly these two metadata
transitions.

First transition:

```yaml
#| label: exploratory-two-part-formulas
```

becomes:

```yaml
#| label: tbl-h06-exploratory-two-part-formulas
#| tbl-cap: "Exploratory two-part formulas."
```

Second transition:

```yaml
#| label: exact-confirmatory-formulas
```

becomes:

```yaml
#| label: tbl-h06-exact-confirmatory-formulas
#| tbl-cap: "Exact evaluated Wilkinson formulas."
```

Change no executable R expression and no other byte. Required postimage:

- SHA-256
  `d65c197cb37db32101d8a43fcdc80198ab599a95cb73259abd187c9b2b58d350`
- 60,791 bytes

Before rendering, require:

1. exact two-transition forward evidence and exact reverse reconstruction to
   the accepted source preimage;
2. all 20 result R chunks and inline expressions parse under R 4.6.1;
3. exactly 13 unique `tbl-*` labels and six unique `fig-*` labels in accepted
   source order;
4. every native gt-producing result chunk has exactly one `tbl-*` endpoint and
   one Quarto-owned caption;
5. the two formula-table executable bodies, values, roles, formula strings,
   source notes, and positions are byte-identical after excluding the approved
   chunk metadata lines;
6. no source cross-reference or reader link targets either retired ordinary
   chunk label;
7. the repaired figure-QA transformation and accepted contract remain intact;
   and
8. the companion, H06 daily sources, accepted source CSVs and figures, profile,
   hook, package lock, and complete protected set remain exact.

The controlling page inventory is now 13 native tables plus six figures. This
supersedes the earlier incomplete 11-table metadata. Do not edit a test,
manifest, global table catalog, output catalog, or navigation file. Final
harmonizer-wide count reconciliation is deferred to the REPORT-018 integrated
corpus audit after serial rendering.

## B. Sole target render

If and only if section A passes completely, run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

Use normal R 4.6.1 project-profile and renv startup with only the established
narrow access to the existing user-owned renv cache. The configured semantic
hook must run normally. Do not use `--no-execute`, bypass the profile or hook,
render the companion, render H06 daily, render another target, or run the full
project.

## C. Nonvisual acceptance

Require all of the following against the fresh post-hook page:

1. Quarto exits 0 and the hook reports `REPAIRED` or `ALREADY_REPAIRED`;
2. the retained external audit contains a combined summary and reversible
   ledger for exactly 13 native tables;
3. exact hook reversal reconstructs the pre-hook HTML and reapplication
   reconstructs the accepted final HTML;
4. document-wide IDs are unique, every explicit `headers` token resolves
   exactly once inside its own table to the intended `th`, and no unsupported
   ID reference remains;
5. exactly 13 table and six figure endpoints are unique and ordered, with all
   values, formula strings, captions, source notes, alt text, source-data
   links, FDR wording, and styles present;
6. all result/companion, Preparation 06, Supplementary information,
   deviation-page, and four DEV-anchor links resolve;
7. exactly the held H06 daily target may remain deferred, with no other missing
   internal reader target;
8. active navigation, nine country-coded study sites, no forbidden local or
   build link, no unresolved cross-reference, and no embedded error, warning,
   or stderr node;
9. the source QMD, contract, companion QMD/HTML, source CSVs, durable figures
   and tables, scientific artifacts, profile, hook, package lock, H06 daily
   sources, and every unrelated build member are exact outside the authorized
   source and declared target-render deltas; and
10. every build change is classified, with no symlink, missing member, or
    unclassified content delta.

The previously recorded Pandoc resource-fetch warnings for the existing H06
and H05 companion links and optional `Datatype.woff2` font may recur. Under
REPORT-018 they are nonblocking only if both companion links resolve in the
retained site, the final H06 page contains no embedded warning or error, and no
additional warning appears. Record them without opening a link, font, CSS, or
language cleanup loop.

## D. Secure loopback visual QA

After all nonvisual gates pass, use the approved read-only loopback process:

1. preflight `_build/nathealth` for symlinks;
2. serve exactly that root on `127.0.0.1` using one unused high port;
3. inspect only the exact H06 result route in the in-app Browser;
4. inspect the complete page at 1440 by 1000 and 708 by 1000, plus
   200-percent-equivalent and intended final-output views;
5. inspect all 13 native tables and all six figures, including both newly
   captioned formula tables and all repaired stored PNGs;
6. apply the accepted table policy: desktop usability is controlling, while a
   narrow table may use a contained usable horizontal scroller;
7. check table and figure typography, formula wrapping, axes, legends, labels,
   symbols, panels, captions, disclosures, callouts, navigation, links,
   clipping, overlap, and page overflow; and
8. stop the server, prove no listener remains, reset the viewport, and prove
   post-QA source/profile/build/protected stability.

For exported outputs, the stored PNG at intended final size is the controlling
check. For HTML-native tables, ordinary desktop and contained narrow behavior
are controlling.

## E. Return and prohibitions

Return one combined completion or stopped record and one non-circular owner
manifest under `audit/hypotheses/H06/report018_order47c_result_render/`.
Record exact source transitions, commands and versions, semantic summary and
ledger, endpoints, links, warnings, build/protected deltas, browser screenshots
and measurements, server lifecycle, and final identities.

If a genuinely new source, render, semantic, link, protection, or visual defect
appears, complete safe read-only inspection and stop once. Do not patch or
rerender.

No other source cleanup, language harmonization, model, inference, scientific
calculation, source-data change, table or figure regeneration, test or
manifest edit, catalog edit, contract change, profile, package, lockfile,
ledger, companion render, H06 daily render, later target, full-project render,
commit, push, upload, or publication action is authorized. The H06 companion
and every later serial target remain held pending independent H06 result-page
acceptance.
