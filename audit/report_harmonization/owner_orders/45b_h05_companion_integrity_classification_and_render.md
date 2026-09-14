# REPORT-018 owner order 45b: H05 companion integrity classification and render

Date: 2026-08-20

Owner: H05 worker `019fba35-6fd8-73c3-970f-e41f8b759bb6`

Status: **released for one exact integrity-row repair and one companion render**

## Authority

Order 45a implemented and verified the accepted historical-to-current H01
contract transition. Its sole render then stopped at the next integrity table
because that table still required all 17 verification codes to be the literal
value `PASS`. Independent acceptance is
`audit/report_harmonization/report018_h05_order45a_integrity_stop_independent_acceptance.md`,
SHA-256
`99693e99720d3ac4725a254e1ca570eb8a76f39e50f607d3c4d7ebcb2232f9df`.
Its 14-row non-circular manifest is SHA-256
`b52430af06c5b9d4f7607e3b28c45d082fa38e099fa4d6b746d9929bab5293cd`.

Finding H05-45A-INT-001 is a low-severity provenance/render-gate
classification defect. The preceding chunk already proves 16 direct `PASS`
rows, one exact `PASS_ACCEPTED_TRANSITION`, the historical and current H01
contract pins, and exact 17-row by six-field metric-registry equality. No
scientific discrepancy is open.

## Hard preflight pins

Require exact identities before editing:

- repaired companion QMD:
  `cce35a2631206945b23144abc6cba44d7297237fc60c716d0d0e3949d128ee57`,
  77,741 bytes;
- exact pre-order-45a companion snapshot:
  `0a5296442b46c8b9e43773d97eb979ffbbf3512faabe6f4399da2214d38cb81c`,
  75,630 bytes;
- order-45a stopped record:
  `7f474471b2c221e8e66f8b67e5cbfb1b583b30da8e158de78daeb53aa65ba07b`;
- order-45a 25-row owner manifest:
  `643931c04ff3b8ce421f36aa65c72a5ba1968c74fa45889a133afe9b7ec1bc27`;
- order-45a pre/post build inventories, both:
  `e938b4ff1649943491dfaf1391c618578cc00842f6e70ccce7ef616e7a613070`;
- order-45a pre/post protected inventories, both:
  `7f6cb9560ab8778d573c4e87d9040e26983230487e808d98e3969ec9050e999c`;
- H05 input audit:
  `cc0ec125ca692c277e2e2b8820afa79a9023ab5177d16ac5bccb492b6386c14e`;
- current H01 contract:
  `dfa35f7c8a1ca8a1f2132c6930a8ac219c461ffac769a7423bf85522430da81a`;
- accepted result QMD and HTML:
  `7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0`
  and
  `a088e105be1987508280e91b938142773c8fb9275f1e924ac1ec9958a9b199f1`;
- stale companion HTML and website QMD:
  `c44f4f77f4e2295f6b265ed9505c3c560361a7280562dd9ce1afce73149d5866`
  and
  `f8087740def5e4e75e5bf5eff82d9f58acf1865954a16919719a7280f3447bfc`;
- unchanged helper:
  `722659aaf622c6f841c52de1cb08720da1cf8177b9906c0afcddb1d903ea0b96`;
- unchanged preparation test:
  `ec738f56fb8b3cf94755fd5055d128d1a22bcc31a435554568aaa15acf78890e`;
- current preparation manifest:
  `bd4ae8ac8516e961d1c4a37b1c18d3262376cd27ba0ed9611b7b60d167059c36`;
- profile:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper and engine:
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`
  and
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- `renv.lock`:
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

The order-45 and order-45a semantic directories and all prior evidence remain
immutable. The coordination-matrix identity is dispatch-time evidence, not a
mutable owner hard pin.

## Sole source repair

Edit only the `Current result-input identities` row inside
`tbl-h05-prep-integrity-checks` in
`audit/hypotheses/H05/H05_analysis_preparation.qmd`.

Replace its four values so that:

1. `Expected` is exactly `17 accepted inputs`;
2. `Observed` counts codes in exactly
   `c("PASS", "PASS_ACCEPTED_TRANSITION")` and reports `accepted inputs`;
3. `Status` is `PASS` only if every verification code belongs to that exact
   two-value set, otherwise `FAIL`;
4. every preceding 16-plus-one exact transition condition stays unchanged.

Preserve every other QMD byte, assignment, formula, value, endpoint, caption,
alt text, link, table, figure, Mermaid node, and prose statement. Require exact
reverse proof to the pre-edit QMD SHA-256 `cce35a2631206945b23144abc6cba44d7297237fc60c716d0d0e3949d128ee57`.
Require all 27 R chunks to parse, all 22 table and three figure endpoints once,
one top-down Mermaid, 17 accepted input rows, all nine integrity rows passing,
and zero new fit, prediction, simulation, bootstrap, resampling, or write calls.

## Sole render and bounded integration

Reinventory the complete build and protected H05 set and require zero
symlinks. Create a fresh absolute empty mode-0700 semantic-audit directory
under `/private/tmp`. Run exactly once:

`GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-directory> quarto render audit/hypotheses/H05/H05_analysis_preparation.qmd --profile nathealth`

Use normal R 4.6.1 project and renv startup with the established narrow cache
access. Do not reuse a prior semantic directory. Do not render the result,
another page, or the full project.

If and only if render and semantic repair pass, run the unchanged helper once:

`Rscript --vanilla scripts/hypotheses/H05/build_h05_preparation_report_manifest.R`

Require the website QMD to be byte-identical to the repaired authoring QMD and
the rebuilt H05 preparation manifest to have unique, live-exact rows. Then run
the unchanged preparation test once:

`Rscript --vanilla tests/hypotheses/H05/test_h05_preparation_report.R`

Do not patch or rerender on any new failure.

## Static and visual acceptance

Require semantic disposition `REPAIRED` or a proven already-repaired state,
exactly 22 native gt tables, three figures, and one top-down Mermaid, complete
captions and alt text, zero duplicate IDs, all table header references
resolving once inside their own table, zero unsupported ID references, exact
semantic-ledger reversal, reciprocal and internal links, active navigation,
country-coded sites, zero embedded errors, a classified build delta, and
preservation of the accepted result plus every H05 scientific artifact.

After nonvisual gates pass, serve only `_build/nathealth` read-only on
`127.0.0.1`. Inspect only the exact H05 companion route at 1440 by 1000, 708
by 1000, and a 200-percent-equivalent viewport. Inspect all 22 tables, all
three figures, the Mermaid, disclosures, callouts, headings, captions, links,
and navigation. Apply the accepted desktop-first and contained narrow-scroll
table policy. Stored PNG or SVG outputs control exported final-size figure
acceptance.

Stop the server, prove no listener remains, reset the viewport, close QA tabs,
and prove post-QA build and protected stability.

Return one combined acceptance or one genuinely new fail-closed defect list.
Do not open a language, style, historical-test, optional-link, or cosmetic
cleanup loop. No later target is released before H05 companion acceptance.

## Prohibitions

No model fit or refit, inference, source-data change, scientific artifact
regeneration, result-page render, later render, full-project render, helper or
test edit, profile, package, lockfile, ledger, or manuscript change, broad
manifest builder, deletion, commit, push, upload, or publication is
authorized.

