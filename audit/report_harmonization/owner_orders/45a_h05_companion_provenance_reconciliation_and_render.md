# REPORT-018 owner order 45a: H05 companion provenance reconciliation and render

Date: 2026-08-20

Owner: H05 worker `019fba35-6fd8-73c3-970f-e41f8b759bb6`

Status: **released for one bounded provenance repair and one companion render**

## Authority

Order 45 stopped before rendering content because its input-identity table
compared a truthful historical H05 producer pin with an accepted newer shared
source. Independent stopped-state acceptance is
`audit/report_harmonization/report018_h05_order45_provenance_stop_independent_acceptance.md`,
SHA-256
`880776c10c51f527a06fae589ab6ce82b5729df7cb90a1e52a743b0b5522b1c4`.
Its 11-row non-circular manifest is SHA-256
`deeb2013cdfd431b9f94e5e9c9bef32594dc0b1a6626907f1caa5f5dd089d78d`
and passes 11/11 exact, unique rows under R 4.6.1.

The R 4.6.1 diagnosis reproduces exactly one mismatch among 17 named inputs:

- historical H05 producer pin for `scripts/hypotheses/H01/h01_contract.R`:
  `9151f2ca8ef549d16df1465768ed5b33c0aa33b37dc315a13e06d795ba20de2e`;
- accepted current H01 contract:
  `dfa35f7c8a1ca8a1f2132c6930a8ac219c461ffac769a7423bf85522430da81a`;
- current size: 10,553 bytes.

The H01 METRIC-011 gate and production tests explicitly preserve those two
identities as historical and current. A read-only R 4.6.1 comparison confirms
that the current H01 contract and the stored H05 metric registry are exact for
all 17 rows across the six model-defining fields `metric_order`, `metric_id`,
`analysis_unit`, `response_family`, `response_transform`, and `effect_scale`.
The two registries differ only in two diagnostic-note display strings outside
that accepted H05 model-defining comparison.

This is a provenance and render gate correction. No scientific decision or
result change is authorized.

## Hard preflight pins

Require exact identities before editing:

- companion QMD:
  `0a5296442b46c8b9e43773d97eb979ffbbf3512faabe6f4399da2214d38cb81c`,
  75,630 bytes;
- H05 input audit:
  `cc0ec125ca692c277e2e2b8820afa79a9023ab5177d16ac5bccb492b6386c14e`,
  4,445 bytes;
- stored H05 metric registry:
  `artifacts/06_model_data/H05/H05_metric_registry.csv` at its current exact
  dispatch identity;
- current H01 contract:
  `dfa35f7c8a1ca8a1f2132c6930a8ac219c461ffac769a7423bf85522430da81a`,
  10,553 bytes;
- current H01 modeling source:
  `a8879209e0d7c42f2e0de0d459e3cfbf7218cec27afd8f39a50c846ed43f9388`;
- H05 contract:
  `scripts/hypotheses/H05/h05_contract.R` at its current exact dispatch
  identity;
- stale companion HTML:
  `c44f4f77f4e2295f6b265ed9505c3c560361a7280562dd9ce1afce73149d5866`,
  839,152 bytes;
- stale website companion QMD:
  `f8087740def5e4e75e5bf5eff82d9f58acf1865954a16919719a7280f3447bfc`,
  72,797 bytes;
- accepted result QMD and HTML:
  `7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0`
  and
  `a088e105be1987508280e91b938142773c8fb9275f1e924ac1ec9958a9b199f1`;
- unchanged helper:
  `722659aaf622c6f841c52de1cb08720da1cf8177b9906c0afcddb1d903ea0b96`;
- unchanged preparation test:
  `ec738f56fb8b3cf94755fd5055d128d1a22bcc31a435554568aaa15acf78890e`;
- current 141-row preparation manifest:
  `bd4ae8ac8516e961d1c4a37b1c18d3262376cd27ba0ed9611b7b60d167059c36`;
- profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper and repair engine:
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`
  and
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- `renv.lock`:
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`;
- order-45 pre-render and post-failure build inventories, both:
  `9fbb5e75e5f0d6d361e6aa402d92721457dd2bfb83d9b0fa13556081e2931cb9`;
- order-45 pre-render and post-failure protected inventories, both:
  `31fe584aeefd13698453a4ecb2e4eb420b2ef184844b8ad634c8787dcd37e8d0`.

The abandoned order-45 semantic directory must remain empty and all order-45
records must remain byte-identical.

## Sole source repair

Edit only the executable input-identity table chunk in
`audit/hypotheses/H05/H05_analysis_preparation.qmd`.

1. Define the exact historical and current H01 contract SHA-256 values above.
2. Load the current H01 contract functions into a local environment without
   mutating project state.
3. Compare the current H01 metric registry with the already loaded stored H05
   metric registry across exactly the six established H05 model-defining
   fields and all 17 rows. Fail unless they are exact after ignoring only data
   frame attributes.
4. Continue to mark a row `PASS` only when its current hash equals its stored
   expected hash.
5. Mark exactly the `h01_contract_source` row as
   `PASS_ACCEPTED_TRANSITION` only when its stored expected hash is the exact
   historical identity, its current hash is the exact accepted identity, and
   the six-field registry comparison passes.
6. Fail unless the other 16 rows are exact, exactly one accepted transition
   is present, and no other mismatch exists.
7. Display the transition as `Accepted transition` and add one concise source
   note explaining that the historical producer pin is preserved while the
   accepted current contract passed the exact H05 registry comparison.

Preserve every other QMD byte, chunk, assignment, formula, value, endpoint,
caption, alt text, link, table, figure, Mermaid node, and prose statement.
Require exact reverse proof to the pre-edit QMD. Require all 22 table and three
figure endpoint labels once, one top-down Mermaid, all executable chunks to
parse, and zero new scientific fit, prediction, simulation, bootstrap,
resampling, or write calls.

Do not edit `H05_input_audit.csv`, `h01_contract.R`, `h05_contract.R`, the
stored H05 registry, any model, result, scientific artifact, test, helper,
profile, package, or lockfile.

## Pre-render verification

Run one R 4.6.1 source-only check of the exact 17-row identity classification
and six-field registry equality. Require 16 direct passes, one exact accepted
transition, and zero failures. Record R and consequential package versions.

Reinventory the complete build and protected H05 set and require zero
symlinks. The coordination-matrix identity is dispatch-time evidence, not a
mutable owner hard pin.

## Sole render and bounded integration

Create a fresh absolute empty mode-0700 semantic-audit directory under
`/private/tmp`. Run exactly once:

`GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-directory> quarto render audit/hypotheses/H05/H05_analysis_preparation.qmd --profile nathealth`

Use normal R 4.6.1 project and renv startup with the established narrow cache
access. Do not reuse either order-45 temporary directory. Do not render the
result, another page, or the full project.

If and only if render and semantic repair pass, run the unchanged helper once:

`Rscript --vanilla scripts/hypotheses/H05/build_h05_preparation_report_manifest.R`

Require the website QMD to be byte-identical to the repaired authoring QMD and
the rebuilt H05 preparation manifest to contain unique, live-exact rows.

Then run the unchanged preparation test once:

`Rscript --vanilla tests/hypotheses/H05/test_h05_preparation_report.R`

The test must pass. Do not patch or rerender on a failure.

## Static and visual acceptance

Require semantic disposition `REPAIRED` or a proven already-repaired state,
exactly 22 native gt tables, three figures, and one top-down Mermaid, complete
captions and alt text, zero duplicate IDs, all explicit header-ID tokens
resolving inside their tables, zero unsupported ID refs, exact semantic-ledger
reversal, reciprocal and internal links, active navigation, country-coded
sites, zero embedded errors, a classified build delta, and preservation of the
accepted result plus every H05 scientific artifact.

After nonvisual gates pass, serve only `_build/nathealth` read-only on
`127.0.0.1`. Inspect the exact H05 companion route at 1440 by 1000, 708 by
1000, and a 200-percent-equivalent viewport. Inspect all 22 tables, all three
figures, the Mermaid, disclosures, callouts, headings, captions, links, and
navigation. Apply the accepted desktop-first and contained narrow-scroll
table policy. Stored PNG or SVG outputs control exported final-size figure
acceptance.

Stop the server, prove no listener remains, reset the viewport, close QA tabs,
and prove post-QA build and protected stability.

Return one combined acceptance or one genuinely new fail-closed defect list.
Do not open a language, style, historical-test, optional-link, or cosmetic
cleanup loop. No later target is released before H05 companion acceptance.

