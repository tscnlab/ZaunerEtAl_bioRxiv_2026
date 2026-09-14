# REPORT-018 order 57b: H09 Stage 3 manifest transition classification and companion retry

Date: 2026-08-22

Owner: H09 owner `019fdc1b-b927-7fb1-ac61-88993c0a818a`

Status: sealed for one complete source classification, one downstream-tested
preflight, and exactly one H09 companion render retry. The H09 result and all
later REPORT-018 targets remain held.

## Authority and accepted stop

The controlling disposition is
`audit/report_harmonization/report018_h09_order57a_stopped_independent_acceptance.md`,
SHA-256
`153e753fbdc513e1c6c844b48a45a9bbd9dc261431da30c079c426f8730334f5`,
5,807 bytes.

The independent R 4.6.1 checker
`scripts/report_harmonization/check_report018_h09_order57a_stop_and_downstream_replay.R`
at SHA-256
`1c0320da38f205dafbddaa718fb709e1b6eb77c9fe939b7ce5aeddd0662f07a5`
ran twice and deterministically reported:

```text
REPORT018_H09_ORDER57A_DOWNSTREAM=PASS stop=58/58 verification=17/17 stage3=87+19 authority=19/19 chunks=22 later=3 endpoints=19+1+1 links=23/22 helper=554->555 semantic=19/102/588/690 preservation=851/545/16 R=4.6.1
```

This is a downstream-tested continuation. It is not authority to rerun the
failed order unchanged. Preserve the complete order-57 and order-57a evidence
directories byte-for-byte. Preserve every REPORT-018 H09 result, display,
scientific-scope, and historical record byte-for-byte.

## Required preflight identities

Before any edit, require all of the following exact identities:

| Path | SHA-256 | Bytes |
|---|---|---:|
| `audit/hypotheses/H09/H09_analysis_preparation.qmd` | `286c391fb228268804ba199d38bd5341509b3a66d434e30aa09fc1007a19443e` | 48,400 |
| `artifacts/12_manifests/H09/H09_stage3_artifacts.csv` | `0103aad8bf3b2424358fc139b85b95564054745b180a80d1e12c27ff72e1bef2` | 24,678 |
| `audit/hypotheses/H09/report018_order57a_companion_retry/reader_manifest_mismatches_sealed.csv` | `7442ab696510b055a71018795cb5fa5366d0d67933b587fe17dafe81b09d191d` | 6,215 |
| `audit/hypotheses/H09/report018_order57a_companion_retry/reader_manifest_live_audit_sealed.csv` | `ce02b3076d920c8417c163238143cb5d6421dd9114d4af49bf9fa72c4384c36b` | 34,794 |
| `scripts/hypotheses/H09/h09_contract.R` | `866b0f8736c8a25f50a3f1ce6e38c5d33d4666d4bf06031f0021ee1cb6d0b701` | 16,374 |
| `artifacts/06_model_data/H09/H09_input_audit.csv` | `1ea3910539378434533dcaeeaee6ab613e325468d99ffd10e02bdc868a4175ed` | 4,401 |
| `scripts/hypotheses/H09/build_h09_preparation_report_manifest.R` | `c7a320367e0115aee221a3a6ba5228a9a27ba55f734bd07881455b3159cebf56` | 9,753 |
| `tests/hypotheses/H09/test_h09_preparation_report.R` | `9a243e391de7069179fcd0ccb7cc6813a5e779b1ae1bf7fcb52706349553dfe7` | 12,824 |
| `notebooks/hypotheses/H09.qmd` | `c738a4365d01497030a260691ceff35fd5c2dab478148fd28676e27981e203c6` | 36,970 |
| `_build/nathealth/notebooks/hypotheses/H09.html` | `901fd63b45182be70ef77166c418633220a7226d86f52e14d1c79afbfc7cdd16` | 244,127 |
| `_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html` | `4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05` | 593,181 |
| `_quarto-nathealth.yml` | `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3` | 7,480 |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` | 603,493 |

Also reproduce the owner order-57a stop record, verifier, 17-check
verification, and 58-row non-circular seal at their accepted identities. Run
the independent checker above and require a complete PASS before editing.

## Sole source classification

Edit only the R body of the existing chunk
`tbl-h09-prep-reader-manifest-check` in
`audit/hypotheses/H09/H09_analysis_preparation.qmd`. Do not change its label,
caption, endpoint order, surrounding prose, or another chunk.

Use the exact replacement encoded in the `replacement` vector of the accepted
independent checker. The postimage must be exactly:

- SHA-256
  `394a976e52faf002cb2034a13353a053aae8bfda8942a79c2eb007017cae014f`;
- 51,736 bytes; and
- exactly reversible to the 48,400-byte preimage by restoring only the former
  manifest-check block.

The replacement must:

1. pin the exact sealed 19-row mismatch CSV at SHA-256 `7442ab69...` and
   6,215 bytes;
2. require exactly 19 unique transition rows and all required historical and
   current identity fields;
3. preserve the immutable 108-row Stage 3 manifest byte-for-byte;
4. exclude only the two already mutable handoff records, leaving 106 audited
   immutable rows;
5. require exactly 87 `LIVE_EXACT` and exactly 19
   `ACCEPTED_HISTORICAL_TO_LIVE` rows;
6. require exact equality between the observed non-live set and the sealed
   19-path set;
7. require every historical SHA-256 and byte count and every current SHA-256
   and byte count to match the sealed transition row; and
8. fail on any missing path, duplicate, changed identity, unclassified row,
   or 20th mismatch.

No test, manifest, contract, input audit, helper, handoff, profile, HTML,
scientific source, artifact, or other QMD may change before the render.

## Complete pre-render execution gate

Create one order-specific verifier and all working evidence under one fresh
directory in `/private/tmp`. Do not create the durable order-57b evidence
directory until after the dedicated helper has run successfully.

The verifier must first reproduce the exact dispatch seal, the complete
order-57a stopped state, all 58 owner rows, all 17 stopped checks, and the
complete 19-row transition-authority table. It must then replay the entire
prospective source, not only the corrected table:

1. purl, parse, and execute all 22 R chunks under R 4.6.1;
2. execute all three chunks after `tbl-h09-prep-reader-manifest-check`;
3. reproduce exactly 19 native table endpoints, one figure endpoint, one
   top-down Mermaid, 23 relative link occurrences, and 22 unique resolving
   relative targets;
4. preserve all formulas, sample counts, score directions, FDR families,
   diagnostic and sensitivity records, and source-data identities;
5. find no fit, refit, prediction, diagnostic recalculation, resampling,
   bootstrap, simulation, or other prohibited scientific call;
6. reproduce the prospective dedicated-helper inventory as exactly 554 unique
   non-circular pre-render members, zero current target-page assets, and
   exactly 555 expected members after the one target-generated figure;
7. reproduce the held-page semantic dry run as 19 tables, 102 ID
   substitutions, 588 `headers` substitutions, 690 total mutations, and exact
   ledger reversal; and
8. reproduce all 851 build, 545 protected, and 16 source-side support
   identities with no competing Quarto, Pandoc, helper, semantic, or loopback
   process.

Run this complete verifier once before rendering. Stop and seal on any
failure. Do not proceed on a partial PASS and do not request an enumerated
reseal or another source patch.

## Exactly one companion retry

Only after the full pre-render gate passes, create one fresh, empty, absolute
semantic-audit directory under `/private/tmp`. From the main project root, run
exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> \
quarto render audit/hypotheses/H09/H09_analysis_preparation.qmd --profile nathealth
```

Use R 4.6.1, Quarto 1.9.37, the accepted project library, normal profile,
accepted semantic hook, and the established narrow access to existing
user-owned caches. Do not alter `HOME`, redirect or reset a cache, restore or
install a package, bypass the profile, use `--no-execute`, rerender the H09
result, or render any other target. If startup or rendering fails, stop once
and seal all evidence. No second retry is authorized.

## Dedicated helper exactly once

If and only if the render and semantic hook succeed, execute exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
Rscript --vanilla scripts/hypotheses/H09/build_h09_preparation_report_manifest.R
```

The helper may synchronize only the source-identical build companion QMD and
write the current H09 preparation manifest. Require exactly 555 unique,
live-exact, non-circular rows: the independently verified 554-member
pre-render inventory plus the one target-generated companion figure asset.
The manifest must exclude itself and every order-57b evidence path. Do not run
a broad or global manifest builder and do not run the helper twice.

Preserve the historical source-side companion HTML and its 16-file support
tree byte-for-byte. They must not supply or overwrite the canonical website
output.

## Complete post-render acceptance

After the helper, create one new durable order-57b evidence directory under
`audit/hypotheses/H09/`. Rerun the same complete verifier in post-render mode
and require:

- render exit zero, one retry invocation, and no embedded error, unresolved
  reference, or raw trace;
- exactly 19 native `gt` tables, one figure, and one top-down Mermaid in the
  accepted source order;
- semantic repair of all 19 tables, unique document IDs, exact reverse and
  reapplication ledger, and every `headers` token resolving exactly once to
  an intended `th` within its own table;
- exact source, endpoint, caption, note, cell, formula, sample, diagnostic,
  sensitivity, provenance, dynamic-link, reciprocal-navigation, deviation,
  country-label, and privacy contracts;
- the accepted result source and HTML, every model and scientific artifact,
  all source data, displays, historical evidence, tests, helper, profile,
  semantic code, phase-4 manifest, handoff, lockfile, and unrelated path
  exact;
- the final 555-row H09 preparation manifest wholly live-exact; and
- every build delta target-owned, source-identical, or an expected search or
  sitemap update.

If the target-generated sample-support PNG changes from its historical
source-side identity, require the same frozen 108-row model-frame input,
geometry, values, labels, panels, colours, visible content, and at least
7-point final-size text. Record the exact transition only in order-57b
evidence. Do not edit a historical manifest or promote a durable display.

## Secure loopback QA

After all nonvisual gates pass, serve `_build/nathealth` with one read-only
server bound only to `127.0.0.1`. Inspect only the H09 companion at 1440 by
1000, 708 by 1000, and 720 by 500 as the 200-percent-equivalent view. Inspect
all 19 tables, the figure, Mermaid diagram, headings, callouts, captions,
notes, links, navigation, disclosures, and final provenance. Exercise every
required narrow table scroller and inspect the figure at 170 mm with at least
7-point essential text.

Require no page overflow, clipping, overlap, missing content, broken
interaction, or report-attributable console warning or error. Close the QA
surface, reset the viewport, stop the server, prove no listener remains, and
require post-QA build and protected inventories to match post-render exactly.

## Return and prohibitions

Return one completion record and one unique non-circular evidence manifest,
or one consolidated fail-closed record. Retain external semantic evidence
until independent acceptance.

No model, fit, prediction, estimate, interval, p-value, FDR decision,
diagnostic, sensitivity result, scientific artifact, source-data value,
durable figure, historical record, test, helper logic, profile, shared ledger,
package, lockfile, result page, later target, full-project render, second
retry, piecemeal source loop, broad manifest builder, commit, push, upload, or
publication change is authorized. The mandatory next stop is independent H09
companion acceptance.
