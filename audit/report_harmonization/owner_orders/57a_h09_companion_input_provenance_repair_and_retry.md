# REPORT-018 order 57a: H09 input-provenance repair and companion retry

Date: 2026-08-22

Owner: H09 owner `019fdc1b-b927-7fb1-ac61-88993c0a818a`

Status: sealed for one bounded provenance repair and exactly one H09 companion
render retry. Every later REPORT-018 target remains held.

## Authority and accepted stop

The controlling independent disposition is
`audit/report_harmonization/report018_h09_order57_stopped_independent_acceptance.md`.
The R 4.6.1 scientific-scope checker proves:

```text
REPORT018_H09_ORDER57_SCOPE=PASS stop=45/45 verification=14/14 gap_evidence=7/7 non_mder=25620 frames=40/40 frame_rows=32492 registry=MDER_only scientific=65/65 checks=20/20 R=4.6.1
```

The three blocked identities are accepted H09-equivalent provenance
transitions. The repaired shared gap artifact changes only MDER, H09 uses no
MDER metric, all 40 H09 gap frames reproduce exactly, and the display-registry
transition changes only the unused MDER row.

Preserve the complete failed order-57 directory at
`audit/hypotheses/H09/report018_order57_companion_render/` byte-for-byte. Its
45-row seal must remain 45 of 45 exact. Preserve all prior order-56 result and
display evidence as well.

## Exact preimages and authorized postimages

Only these three authoring files may be edited before the render:

| File | Required preimage | Required postimage | Bytes after |
|---|---|---|---:|
| `scripts/hypotheses/H09/h09_contract.R` | `458dc3c08f0cd74acecc790d30226d930839b3f8f252a3018085e35611de3cd1` | `866b0f8736c8a25f50a3f1ce6e38c5d33d4666d4bf06031f0021ee1cb6d0b701` | 16,374 |
| `artifacts/06_model_data/H09/H09_input_audit.csv` | `be258bf523eadc318cf8926298e83275f64b38f5c5c4d1cc499f7841c0c2cafb` | `1ea3910539378434533dcaeeaee6ab613e325468d99ffd10e02bdc868a4175ed` | 4,401 |
| `audit/hypotheses/H09/H09_analysis_preparation.qmd` | `7563a933289b1c4a2275eead58ae8cfaa6492fb0a27b7202f4a9be516eb88a46` | `286c391fb228268804ba199d38bd5341509b3a66d434e30aa09fc1007a19443e` | 48,400 |

Do not format or mechanically rewrite these files. Apply only the exact edits
below and require exact reverse proof to each preimage.

### Contract

In `h09_input_contract()`, replace only these three SHA-256 literals:

- `28266064...` with the full current gap RDS identity `7561b5dd...d932f1`;
- `af74cc9f...` with the full current gap manifest identity
  `4ed62fbe...698935`; and
- `6c0adc3c...` with the full current display-registry identity
  `c82db05a...06ed0`.

No role, path, expected row count, use description, formula, threshold, metric,
run, family, or scientific contract field may change.

### Input audit

Replace only the complete rows for `gap_timing_unaware_metrics`,
`gap_manifest`, and `metric_display_registry`. Require the current and observed
SHA-256 columns to equal the accepted current identities, the current byte
counts to be 88,248, 4,497, and 3,203, and both verification flags to remain
true. Use exactly these bounded descriptions:

- `Current MDER-repaired shared identity; all 40 H09 gap frames reproduce exactly`;
- `Current provenance for the MDER-only shared repair; H09 gap frames unchanged`;
  and
- `Current display registry; only the unused MDER row changed and all H09 rows remain exact`.

Every other row and field must remain exact.

### Companion provenance wording

Replace only the file-identity introductory paragraph, its table caption, and
its source note. The paragraph must state exactly that eleven current inputs
reproduce the accepted analysis, eight retain execution-time identities, the
three later shared transitions belong to an MDER-only repair, H09 does not use
MDER, all 40 stored H09 gap-sensitivity frames reproduce exactly, and the
historical identities remain in REPORT-018 transition evidence.

The caption must be exactly:

```text
Current reproducibility inputs for the accepted H09 analysis.
```

The source note must use one `paste()` call containing exactly:

```text
Current identities remain in artifacts/06_model_data/H09/H09_input_audit.csv.
The three execution-time identities remain in the REPORT-018 order-57 transition evidence.
```

Do not change another prose sentence, chunk, endpoint, table cell, caption,
note, link, formula, inline expression, or code path.

## Complete source and scientific preflight

Before rendering, run one R 4.6.1 order-specific verifier from temporary
working space. It must:

1. reproduce every non-matrix dispatch member, the independent stop
   acceptance, its non-circular seal, and the complete 45-row failed owner
   seal;
2. require the three exact postimage identities above and exact reversal to
   all three preimages;
3. require all 16 H09 input-audit rows to match current files, both
   verification flags true, and all eleven result-input roles current;
4. rerun
   `scripts/report_harmonization/check_report018_h09_order57_stop_and_scientific_scope.R`
   unchanged and reproduce all 20 checks, 25,620 non-MDER cells, 40 of 40
   exact complete gap frames covering 32,492 rows, the one-row MDER-only
   registry transition, 57 live-exact historical scientific members, and
   eight accepted order-56 display transitions;
5. preserve `H09_METRIC-011_excluded_shared_drift.csv` byte-for-byte as
   historical transition evidence;
6. parse all 22 R chunks, retain exactly 19 native-table endpoints, one figure
   endpoint, one top-down Mermaid, 23 relative link occurrences to 22 unique
   targets, and zero prohibited scientific-regeneration calls;
7. require the current 132-row preparation manifest to retain the exact same
   19 historical mismatch paths and its other 113 rows live-exact;
8. require the accepted result source and HTML, all models, tables,
   diagnostics, sensitivities, source data, current displays, historical
   tests, helper, profile, semantic code, handoff, phase-4 manifest, lockfile,
   historical source-side companion HTML and assets, and all unrelated paths
   exact; and
9. inventory the complete build and protected H09 scopes and confirm no
   competing Quarto, Pandoc, H09 semantic, helper, or loopback process.

This preflight performs no model fit, refit, prediction, comparison,
diagnostic recalculation, p-value or FDR calculation, resampling, bootstrap,
simulation, or scientific artifact write. Stop and seal on any mismatch.

## Exactly one companion retry

Create one fresh, empty, absolute semantic-audit directory under
`/private/tmp`. From the main project root, run exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> \
quarto render audit/hypotheses/H09/H09_analysis_preparation.qmd --profile nathealth
```

Use R 4.6.1, Quarto 1.9.37, the accepted project library, normal profile,
accepted semantic hook, and established narrow access to existing user-owned
caches. Do not alter `HOME`, redirect or reset a cache, restore or install a
package, bypass the profile, use `--no-execute`, rerender the result, render
another target, or retry again. If startup or rendering fails, stop once and
seal all evidence.

## One helper execution after successful render

If and only if the retry and semantic hook succeed, execute exactly once:

```sh
RENV_CONFIG_AUTOLOADER_ENABLED=FALSE \
R_LIBS=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
Rscript --vanilla scripts/hypotheses/H09/build_h09_preparation_report_manifest.R
```

Keep all order-57a working evidence under `/private/tmp` until the helper
finishes. The helper must run before the durable order-57a evidence directory
is created. It may change only the source-identical build companion QMD and
the truthful preparation manifest. Require exactly 496 unique, live-exact,
non-circular rows: the prior prospective 450-member inventory, the preserved
46-file failed order-57 evidence directory, and one target-owned rendered
figure asset. The manifest must exclude itself and every order-57a evidence
path. Do not rerun the helper.

Preserve the obsolete source-side companion HTML and its 16-file support tree
byte-for-byte. They are historical evidence and must not supply or overwrite
the canonical website output.

## Complete post-render acceptance

After the helper, create one new durable evidence directory under
`audit/hypotheses/H09/` and prove the complete order-57 acceptance contract:

- render exit zero with exactly one retry invocation and no embedded error,
  unresolved reference, or raw trace;
- exactly 19 native `gt` tables, one figure, and one top-down Mermaid in
  accepted source order;
- semantic repair of all 19 tables, unique document IDs, exact reverse and
  reapplication ledger, and every `headers` token resolving exactly once to
  an intended `th` inside its own table;
- all endpoints, captions, notes, cells, labels, alt text, score directions,
  sample counts, formulas, model settings, four complete five-outcome FDR
  families, diagnostics, sensitivities, provenance records, and environment
  contracts reproduced from frozen inputs;
- all 23 relative targets and required fragments resolving, including both
  dynamic result links, reciprocal navigation, DEV-037, DEV-038, DEV-039,
  and the result deviation-section anchor;
- the accepted result, all scientific and display artifacts, source data,
  historical evidence and tests, helper, profile, semantic code, phase-4
  manifest, handoff, lockfile, historical source-side support, and unrelated
  paths exact;
- the final 496-row preparation manifest wholly live-exact; and
- every build delta target-owned, source-identical, or an expected search or
  sitemap update.

If the target-generated sample-support PNG changes from the historical
source-side PNG, require the same frozen 108-row model-frame input, geometry,
values, labels, panels, colours, visible content, and at least 7-point
final-size text. Record the exact transition only in owner evidence. Do not
edit a historical manifest or promote a durable display artifact.

## Secure loopback QA

After every nonvisual gate passes, serve `_build/nathealth` through one
read-only server bound only to `127.0.0.1`. Inspect only the H09 companion at
1440 by 1000, 708 by 1000, and 720 by 500 as the 200-percent-equivalent view.
Inspect all 19 tables, the figure, Mermaid diagram, headings, callouts,
captions, notes, links, navigation, disclosures, and final provenance.
Exercise all required narrow table scrollers. Inspect the figure at 170 mm
and require at least 7-point essential text.

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
package, lockfile, result page, later target, full-project render, additional
retry, language or cosmetic loop, commit, push, upload, or publication change
is authorized. The mandatory next stop is independent H09 companion
acceptance.
