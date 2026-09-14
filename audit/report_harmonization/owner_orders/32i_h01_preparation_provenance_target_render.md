# REPORT-017 order 32i: H01 preparation/provenance target render

Date: 2026-08-20

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

The H01 result page is independently accepted. Render only its
preparation/provenance companion and return one complete combined acceptance or
stopped-state package. Every later REPORT-017 render remains held.

## Exact preflight pins

- result-page independent acceptance:
  `audit/report_harmonization/report017_h01_order32h_result_independent_acceptance.md`,
  SHA-256 `bc4d7610f85c61bc286af17b0fb8aaab4d1011a8acc576389d200ff3f992f32a`;
- nine-row result acceptance manifest:
  `audit/report_harmonization/report017_h01_order32h_result_acceptance_manifest.csv`,
  SHA-256 `cb3a2ef312f24054acfcb13e950bd37b0b99ae2ce048a9908bc302ef7008bee6`;
- companion source:
  `audit/hypotheses/H01/H01_analysis_preparation.qmd`, SHA-256
  `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`;
- stale companion HTML:
  `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html`,
  SHA-256 `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`;
- accepted result source:
  `notebooks/hypotheses/H01.qmd`, SHA-256
  `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`;
- accepted result HTML:
  `_build/nathealth/notebooks/hypotheses/H01.html`, SHA-256
  `df78ac3c2ed91515058b6af38e01b85b4baae74118699c008a29ba4dacf4d007`;
- Nature Health profile:
  `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- preparation test:
  `tests/hypotheses/H01/test_h01_preparation_report.R`, SHA-256
  `379414830e5bcd656ac460c2ad93616ecbcab104259c56a8fcf9296da8c0f2c4`;
- preparation manifest:
  `artifacts/12_manifests/H01/H01_preparation_report_manifest.csv`, SHA-256
  `69c2215a3c789e31b4b9e820ae1a1c90485a74ec106d4c09269a71d859cdffd5`;
- H01 handoff:
  `audit/handoffs/H01_worker_handoff.md`, SHA-256
  `0de574566315d44934d3c6dd5fd91be9045e2f6b43887c9e3ad98d97caf1f19b`;
- semantic wrapper:
  `scripts/report_harmonization/post_render_gt_html_semantics.R`, SHA-256
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic engine:
  `scripts/report_harmonization/repair_gt_html_semantics.R`, SHA-256
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`.

Rehash every pin immediately before execution and stop on drift. Quarto must be
1.9.37. Use the normal project profile and R 4.6.1. Do not bypass
`.Rprofile`, `renv/activate.R`, or the semantic hook.

## Sole render command

1. Create a fresh absolute semantic-audit directory under `/private/tmp` with
   `mktemp -d`. Record its resolved path, permissions, and initial emptiness.
2. Complete a protected source/input inventory and a scoped
   `_build/nathealth` inventory before rendering.
3. Run exactly once, using only the established narrow access to the existing
   user-owned `renv` cache if normal-profile startup requires it:

   ```text
   GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render audit/hypotheses/H01/H01_analysis_preparation.qmd --profile nathealth
   ```

Do not use `--no-execute`, render the result page, render another target, or
run a full-project render.

## Required structural and scientific-preservation checks

After the render:

1. Require the post-render semantic hook to report `REPAIRED` or a justified
   already-correct/no-change disposition.
2. Run the complete H01 preparation source/HTML test under R 4.6.1.
3. Require exactly 20 native `gt` table endpoints and two figure endpoints in
   the accepted order. Preserve all captions, notes, alt text, displayed
   values, formulas, and source links.
4. Require document-wide unique IDs. Every explicit `headers` token must
   resolve exactly once to its intended `th` within its own table. Reject
   dangling or unsupported ID references.
5. Verify the reciprocal result/companion links, every deviation link and
   anchor, active navigation, country-coded study-site labels, and the absence
   of hard-coded internal HTML, `_build`, `file://`, or absolute-local reader
   links. Allow external HTTPS edit actions only as external links.
6. Require the accepted result QMD and HTML, profile, semantic wrapper and
   engine, all scientific inputs and outputs, and every protected artifact to
   remain byte-identical.
7. Classify the complete build delta. It may contain only the target companion
   HTML/QMD copy and target-owned assets, normal search/sitemap changes, and
   explicitly identified source-identical resource refreshes. Fail on any
   unclassified content change. Record byte-identical mtime-only touches
   separately.
8. Retain the external semantic-audit directory until independent harmonizer
   acceptance. Require its combined summary and reversible per-file ledger to
   match the final companion HTML and semantic counts.

No model may be fit or refit. Do not predict, simulate, bootstrap, resample,
rerun Shapley allocation, alter a p-value, regenerate a scientific artifact,
or change a sample, estimate, interval, diagnostic, sensitivity, formula,
scientific claim, package, or lockfile.

## Secure loopback visual QA

Use the approved `$quarto-authoring` loopback procedure only after all
nonvisual checks pass:

1. Recheck the rendered root for symlinks and stop if any resolves outside
   `_build/nathealth`.
2. Start one read-only static server rooted exactly at `_build/nathealth`,
   bound only to `127.0.0.1` on one unused high or ephemeral port.
3. Navigate only to the exact H01 companion route in the in-app Browser.
4. Inspect at 1440 x 1000 and 708 x 1000, plus 200% or an equivalent final-size
   review where appropriate.
5. Verify all 20 tables are usable on an ordinary desktop or laptop display.
   At narrow width, a contained and usable horizontal scroller is acceptable.
   For exported tables, preserve the controlling PNG/export checks separately
   from website-table responsiveness.
6. Verify both figures and the top-to-bottom Mermaid diagram are legible at
   final displayed size. Check headings, callouts, captions, links,
   navigation, wrapping, clipping, overlap, page overflow, and interactive
   disclosures or tabsets through their actual reader controls.
7. Stop the server immediately, prove no listener remains, reset the viewport,
   and rehash the source, profile, result HTML, target output, scoped build, and
   protected inventories.

## Return and stop rule

Return one combined package with commands, versions, timings, pre/post hashes,
semantic evidence, focused tests, build delta, loopback lifecycle, final-size
visual evidence, protected reconciliation, and a non-circular manifest. If a
genuinely new render-only defect appears, finish every safe read-only check and
return one consolidated defect list. Do not patch or rerender within this
order.

No source edit, result rerender, later target, profile or ledger edit, package
or lock change, commit, push, upload, or publication is authorized.
