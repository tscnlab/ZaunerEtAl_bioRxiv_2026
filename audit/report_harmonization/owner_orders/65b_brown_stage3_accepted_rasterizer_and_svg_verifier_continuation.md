# Owner order 65b: Brown accepted-rasterizer and SVG-verifier continuation

Date: 2026-09-02

Workflow: `REPORT-018`

Status: **FINAL BOUNDED CONTINUATION ORDER**

Owner task: `019fffdf-66d4-7802-9091-09283ad27b7f`

## Independent disposition

Central coordination independently reproduced the complete Order 65a stopped
state under R 4.6.1. The 29-row final manifest is exact, unique, and
non-circular at SHA-256
`1d83387068ccc8753e27f33f849fef413444bcfec46acf580fa4eac51724b9fd`.
The candidate gate contains 17 checks, of which exactly 14 pass. The only
failed checks are:

1. `SVG_TEXT_ONLY_TRANSITIONS`;
2. `DECODED_PIXEL_TEXT_BANDS`; and
3. `ACCEPTED_RASTERIZER_VERSION`.

No durable figure was promoted. The six live source postimages, ten durable
figure endpoints, both Brown HTML files, Stage 4, source data, protected
values, and all scientific results remain unchanged.

The two causes are independently established:

- Order 65a used the default R 4.6 user library, which supplies `ragg` 1.5.0.
  The accepted project library supplies `ragg` 1.5.2. Four PNG candidates
  differ from their accepted baselines only inside the authorized text bands,
  but the alpha-rich participant raincloud has broad raster differences when
  generated with `ragg` 1.5.0.
- The SVG verifier retained source-line names from `vapply()`. The payloads,
  line counts, differing-line counts, and non-text structures are exact. All
  five comparisons pass after removing only those irrelevant name
  attributes with `unname()`.

This continuation corrects only the execution library and the verifier-only
name-attribute comparison. It does not authorize a scientific, source,
layout, typography, or design change.

## Evidence that must remain byte-identical

Preserve the complete Order 65 and Order 65a evidence directories, including
all candidate files, byte-for-byte:

- `audit/analyses/brown_adherence/language_harmonization/window_label_repair/`
- `audit/analyses/brown_adherence/language_harmonization/window_label_repair_order65a/`

The controlling Order 65a identities are:

| Evidence | SHA-256 |
|---|---|
| `final_manifest.csv` | `1d83387068ccc8753e27f33f849fef413444bcfec46acf580fa4eac51724b9fd` |
| `01_verify_candidates.R` | `5a3e328deaee6b690774b0afa63b155c29dce03e2fa153412a4f37e020b396fa` |
| `candidate_gate_checks.csv` | `fe55c546d246ead3049a0eb67488af16d50541471ce58aacb074cd4410c88d31` |
| `candidate_inventory.csv` | `50704d6a9e4a0d45e0394a37e928a36c25c475920ea304bbef9a74b69e545601` |
| `svg_structure_checks.csv` | `4f9c5ac397436278033fba27696b204ee80736ce96ab5b3ff05b9097a93d7d09` |
| `png_pixel_checks.csv` | `c49573b58774fa3abd9239c977398ac944440d8bdd4a206fe8f074571d852d5c` |
| `package_versions.csv` | `109216e152ec8c26bfdb14a8db7c6011654c138b9bbf02301d4fdd2bdaa35505` |
| `owner_handoff.md` | `48aa0c138bb61bcd63b512711dbc08813a53c794944d6b83c785499da1281c53` |

Do not reuse, overwrite, delete, patch, or reseal any Order 65a candidate or
evidence file. Put every new script, candidate, check, and return record in:

`audit/analyses/brown_adherence/language_harmonization/window_label_repair_order65b/`

## Source boundary

Preserve the six live Order 65 source postimages exactly. Do not reapply,
revert, broaden, or reformat any source substitution:

| Target | Bytes | SHA-256 |
|---|---:|---|
| `audit/analyses/brown_adherence/07_results.qmd` | 29,578 | `d941731ae4cef7e4d903c9968407694bd3554ff805a1d26a04e9daaee1bb3aaa` |
| `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` | 56,230 | `9a6f2402f57640fb19319845b7d25f0ade1697dfab0ff262bf6dc5a47b97654e` |
| `audit/analyses/brown_adherence/stage3/01_build_stage3_displays.R` | 21,156 | `9746ab27c8fc268e040b6045b8939feec6e057e291e0dac08ecf1d137e02ef27` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/workday_site_and_coverage_guides_amendment/01_build_displays.R` | 16,195 | `e7a06c8cf645d900d72a769cdf5a8163c7471879c70646393ab7c96ceef731e0` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/integrated_report_amendment/site_free_work_vs_equal_site_inference_amendment/00_build_ba_m6_display.R` | 18,033 | `fa12843257bf43136286e783ece85802ded974a9f4fa1350a2108b6dbb3ab0e3` |
| `audit/analyses/brown_adherence/stage3_cross_state_association/01_build_stage3_outputs.R` | 20,831 | `86b019d44d313ad7a9da80bdb3ca34f0f7c8ff5f6259c1724daadaeb5d21c160` |

The dedicated refresh script remains fixed at:

`audit/analyses/brown_adherence/language_harmonization/window_label_repair/01_refresh_window_label_figures.R`

SHA-256:
`d9cf082cdd2ec09bb1b5b60133cf5ce928962f4fbb41a52097859150b5939bc5`.

## Exact accepted execution environment

Use `Rscript --vanilla` under R 4.6.1. Set `R_LIBS_USER` to exactly:

`/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23`

Do not activate `renv` and do not use the default user library. Before any
mutation or candidate generation, run:

```sh
R_LIBS_USER=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
Rscript --vanilla \
  /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/scripts/report_harmonization/check_brown_order65b_environment_preflight.R \
  /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
  /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026
```

Require `BROWN_ORDER65B_PREFLIGHT=PASS`. The preflight must reproduce the
complete Order 65a stopped package, its exact 14/17 gate, the accepted library
path and `ragg` 1.5.2, all six source postimages, zero prior promotions, and
all five corrected SVG classifications.

Also record a process check showing that no owner-started Quarto, Pandoc,
knitr, browser-server, or competing Brown refresh process remains. A process
owned by another task is not authority to interrupt it. Stop if serial
execution cannot be established.

## Verifier-only correction

Copy the exact Order 65a verifier
`window_label_repair_order65a/01_verify_candidates.R` into the new Order 65b
evidence root. Change only the comparisons of named vectors so that irrelevant
source-line names are removed before `identical()` is evaluated:

- apply `unname()` to both comparisons of `old_payload` with `expected$old`;
- apply `unname()` to both comparisons of `new_payload` with `expected$new`;
- apply `unname()` to the old `text_structure` `vapply()` result; and
- apply `unname()` to the new `text_structure` `vapply()` result.

These are exactly six `unname()` wrappers. No other verifier token, check,
threshold, expected value, path, or branch may change. Require an exact
forward diff and exact reverse proof against the pinned Order 65a verifier.
The corrected verifier must parse under R 4.6.1 and be an Air 0.4.1 no-op.

Copy the Order 65a promotion script into the new evidence root byte-for-byte.
Do not execute it unless the complete corrected gate passes.

## Fresh candidate generation and complete gate

After the preflight and process gate pass:

1. Create one fresh candidate directory under the Order 65b evidence root.
   It must be absent or empty before generation.
2. Run the unchanged dedicated five-display refresh exactly once under the
   accepted project library with `BROWN_ADHERENCE_PROJECT_ROOT` set to the
   Brown worktree. Do not reuse the Order 65a candidates.
3. Record R 4.6.1, `ragg` 1.5.2, all consequential package versions, and their
   resolved library paths.
4. Require exactly five PNG and five SVG candidates.
5. Run the corrected complete 17-check gate. It must cover the frozen sources,
   internal keys, source-to-display mappings, scientific values, intervals,
   markers, site and panel order, privacy, file set, evidence copies, SVG
   text-only transitions, PNG dimensions and DPI, decoded-pixel text bands,
   typography at 170 mm, original-size visual review, displayed window labels,
   and accepted rasterizer version.
6. Require `17/17 PASS`. Any newly exposed failure stops this continuation.

## Promotion and return boundary

Only after `17/17 PASS`, run the unchanged promotion logic once. Promote
exactly the five PNG/SVG pairs enumerated by Order 65. Require every durable
postimage to be byte-identical to its accepted Order 65b candidate. Preserve
recoverable copies of all ten preimages and exact forward and reverse proofs.

Seal a new non-circular source/display return containing the preflight,
environment, process, verifier-diff, source, mapping, privacy, SVG, PNG,
typography, visual-QA, candidate, promotion, and completion evidence. Return
the ten promoted endpoint identities and the anonymous participant-raincloud
PNG/SVG identities explicitly for Writer integration. Independent central
acceptance remains required before any render release.

## Prohibitions and stop rule

No Quarto, Pandoc, knitr, HTML, Stage 4, manuscript, model, prediction,
inference, resampling, source-data, package, lockfile, configuration, ledger,
commit, push, upload, or broad-formatting action is authorized.

Stop once on any new failure. Do not patch and retry within this continuation.
