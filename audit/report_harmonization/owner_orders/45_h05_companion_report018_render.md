# REPORT-018 owner order 45: H05 preparation and provenance companion render

Date: 2026-08-20

Owner: H05 worker `019fba35-6fd8-73c3-970f-e41f8b759bb6`

Status: **released as the sole serial render target**

## Authority and scheduling

The H05 result page is independently accepted in
`audit/report_harmonization/report018_h05_result_independent_acceptance.md`,
SHA-256
`a77defa5342ed410e8e0e8041f60463b4fdf4cc1019303e1afe80ab83b73284b`.
Its 20-row non-circular acceptance manifest is SHA-256
`f90ebba9b9d80c72b1b26813301b34ccb591e60c36deab6ed9fc6dfb67691e74`
and passes 20/20 exact, unique rows under R 4.6.1. The accepted result HTML is
`a088e105be1987508280e91b938142773c8fb9275f1e924ac1ec9958a9b199f1`.

H05 source-only order 36 is independently accepted at SHA-256
`07ae1d95e8374c9b29659e9fc760d392047b229252320e2767d7d68404ea07ec`.
No H05 scientific discrepancy is open.

REPORT-018 releases only the H05 preparation and provenance companion. Every
later render remains held. This is render-completion integration of accepted
source. Do not open a language, style, optional-link, historical-test, or
cosmetic cleanup loop.

## Hard preflight pins

Stop before execution if any owner-scoped pin differs:

- companion QMD
  `audit/hypotheses/H05/H05_analysis_preparation.qmd`:
  `0a5296442b46c8b9e43773d97eb979ffbbf3512faabe6f4399da2214d38cb81c`,
  75,630 bytes;
- held stale companion HTML
  `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.html`:
  `c44f4f77f4e2295f6b265ed9505c3c560361a7280562dd9ce1afce73149d5866`,
  839,152 bytes;
- accepted result QMD `notebooks/hypotheses/H05.qmd`:
  `7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0`,
  74,309 bytes;
- accepted result HTML `_build/nathealth/notebooks/hypotheses/H05.html`:
  `a088e105be1987508280e91b938142773c8fb9275f1e924ac1ec9958a9b199f1`,
  640,855 bytes;
- current stale website companion QMD copy:
  `f8087740def5e4e75e5bf5eff82d9f58acf1865954a16919719a7280f3447bfc`,
  72,797 bytes;
- preparation-manifest helper
  `scripts/hypotheses/H05/build_h05_preparation_report_manifest.R`:
  `722659aaf622c6f841c52de1cb08720da1cf8177b9906c0afcddb1d903ea0b96`,
  8,729 bytes;
- preparation test `tests/hypotheses/H05/test_h05_preparation_report.R`:
  `ec738f56fb8b3cf94755fd5055d128d1a22bcc31a435554568aaa15acf78890e`,
  15,264 bytes;
- current preparation manifest
  `artifacts/12_manifests/H05/H05_preparation_report_manifest.csv`:
  `bd4ae8ac8516e961d1c4a37b1c18d3262376cd27ba0ed9611b7b60d167059c36`,
  34,048 bytes and 141 unique rows;
- final source verifier:
  `ba09ce33344d6c1ab959c1395d7ab7cd52abc3d7312586e705924a018b1cf179`;
- source manifest:
  `3c7e2379ce890b424dea10fe3764fd725b8ca7916bf48214541621320c467be0`;
- stage-3 reader test:
  `982162ccbd55def924beff3fbb0e98d31a94884aeb8cc683f817189e1171d4f4`;
- stage-3 manifest:
  `9dabc70a0ab6554a0b4d9dbc175cd4009b1f57a57c975cb4677b45ead2620100`;
- H05 handoff `audit/handoffs/H05_stage4_handoff.md`:
  `71a8d4664504da7b6e621d5b24aa699df793ee120373ae28aeb75d1c980246da`,
  19,132 bytes;
- profile `_quarto-nathealth.yml`:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper:
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic repair engine:
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- `renv.lock`:
  `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`;
- shared site display registry:
  `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809`;
- preparation provenance contract:
  `6afff45a29a0bb96a49dbf46e611fce15dfd1618b4699da40d4b1f15cdbed026`;
- shared path helper:
  `ad7ec3eb6fe76b0b47498d3efa0ae247ac0da3b9cd43a7d3731ea102d3bedc6c`.

The current 141-row preparation manifest has exactly five historical-to-live
differences: the accepted companion source, accepted result source and HTML,
accepted profile, and accepted shared H01 contract. These are expected before
the bounded helper rebuild. No missing manifest path is accepted.

The companion source contains exactly 22 unique native-table endpoints, three
unique figure endpoints, and one top-down Mermaid. Static review finds no
model-fitting, prediction, simulation, bootstrap, scientific write, or
artifact-regeneration call. Reinventory the complete build and H05 protected
set and require zero build symlinks before execution.

The coordination-matrix identity is dispatch-time evidence, not a mutable
owner hard pin.

## Sole render

Create one fresh absolute empty semantic-audit directory under `/private/tmp`
with mode 0700. Run exactly once:

`GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-directory> quarto render audit/hypotheses/H05/H05_analysis_preparation.qmd --profile nathealth`

Use normal R 4.6.1 project and renv startup with the established narrow access
to the existing user-owned renv cache. Preserve `.Rprofile`,
`renv/activate.R`, and the configured semantic hook. Do not run a preliminary
render, startup probe, result render, another target, or the full project.

The page may read and display accepted stored artifacts. It must not fit or
refit a model, predict, simulate, bootstrap, resample, recompute multiplicity,
regenerate a scientific artifact, or change a scientific value.

## Bounded companion integration

If and only if the render exits 0 and the semantic hook succeeds, run the
unchanged helper exactly once under R 4.6.1:

`Rscript --vanilla scripts/hypotheses/H05/build_h05_preparation_report_manifest.R`

The helper may only copy the accepted authoring companion QMD byte-for-byte to
the existing website QMD path and rebuild
`artifacts/12_manifests/H05/H05_preparation_report_manifest.csv`. Require the
website QMD to equal the authoring QMD exactly. Require one unique live-exact
manifest row for every declared path. Record the exact new row count and
identity. No broad or shared manifest builder is authorized.

Then run exactly once:

`Rscript --vanilla tests/hypotheses/H05/test_h05_preparation_report.R`

The complete test must pass against the fresh companion HTML,
source-identical website QMD, accepted result page, and rebuilt manifest. Do
not edit the helper, test, QMD, HTML, or manifest manually. Under REPORT-018,
a stale non-scientific literal may be recorded for later corpus review, but
must not trigger a patch or rerender inside this order. A scientific,
endpoint, semantic, link, manifest-identity, or rendered-content failure is
blocking.

## Static acceptance

Require:

- semantic disposition `REPAIRED` or a proven already-repaired state;
- exactly 22 native gt tables, three figures, and one top-down Mermaid in the
  accepted source order, with all captions and figure alt text present;
- zero duplicate document IDs, every explicit `headers` token resolving once
  to the intended header within its own table, and zero unsupported ID refs;
- reciprocal result and companion links, deviation anchors, active
  navigation, country-coded sites, source-data links, and zero unresolved
  required internal reader links;
- zero embedded error, warning, or stderr nodes;
- exact semantic-ledger reversal to the hook's pre-repair HTML identity;
- accepted result QMD and HTML, both authoring QMDs, profile, semantic tools,
  helper and test sources, handoff, and all scientific artifacts unchanged;
  and
- every build delta classified as target companion HTML, source-identical
  website QMD, target-owned page assets, normal search or sitemap output, or
  the explicitly rebuilt H05 preparation manifest. Fail on any unclassified
  content change.

## Secure-loopback visual QA

After nonvisual gates pass, preflight zero symlinks and start one read-only
static server rooted exactly at `_build/nathealth`, bound only to
`127.0.0.1`. Inspect only
`audit/hypotheses/H05/H05_analysis_preparation.html` at 1440 by 1000, 708 by
1000, and a 200-percent-equivalent viewport.

Inspect all 22 tables, all three figures, the top-down Mermaid, callouts,
disclosures, headings, captions, alt text, links, and navigation. HTML tables
must be usable at a typical desktop or laptop width. Narrow tables may use
contained horizontal scrolling. Stored PNG or SVG outputs control exported
final-size figure acceptance. Check typography, labels, legends, axes,
wrapping, clipping, overlap, and page overflow.

Stop the server, prove no listener remains, reset the viewport, close QA tabs,
and prove post-QA source, profile, accepted result, protected, and complete
build stability.

## Return and prohibitions

Return one companion acceptance package or one combined fail-closed defect
list. Do not patch or rerender inside this order. No result rerender, later
render, source edit, model execution, scientific artifact change, profile,
package, lockfile, ledger, manuscript, broad-manifest, commit, push, upload,
deletion, or publication action is authorized.

