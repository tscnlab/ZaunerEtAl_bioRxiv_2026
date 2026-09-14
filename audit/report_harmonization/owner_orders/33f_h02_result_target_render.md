# REPORT-017 order 33f: H02 result target render

Date: 2026-08-20

Owner: H02 task `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`

H01 result and companion integration is independently accepted, and the
shared serial render gate is clear. Render only the H02 result page and return
one complete acceptance package or one consolidated fail-closed defect list.
The H02 companion and every later REPORT-017 render remain held.

## Controlling acceptance and exact preflight pins

The controlling source-only package is:

- independent H02 source acceptance:
  `audit/report_harmonization/report017_h02_order33_source_independent_acceptance.md`,
  SHA-256
  `127a25b9d95fbb41d4506cb1ed66df775ec01e40d3d3504a5980054dd7911d24`;
- 15-row H02 source acceptance manifest:
  `audit/report_harmonization/report017_h02_order33_source_acceptance_manifest.csv`,
  SHA-256
  `9bb334b78d36cbbfbd7bb53702166abcdac54b8b613a1d3262e49bc15fe0562a`.

Recheck every following hard pin immediately before execution and stop on any
drift:

- result QMD: `notebooks/hypotheses/H02.qmd`, SHA-256
  `4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d`;
- reader test: `tests/hypotheses/H02/test_h02_reader_report.R`, SHA-256
  `0b044d2995645f6cfa50e28e2bdf330b8801002761a84520b169a1a3eb6771db`;
- paired-placement test:
  `tests/hypotheses/H02/test_h02_paired_placement_display.R`, SHA-256
  `873c43f0d863c78c22e3e0635d054f09bc521a24d618afcda134a831ac7e7d8a`;
- preparation test:
  `tests/hypotheses/H02/test_h02_preparation_report.R`, SHA-256
  `ead7a55246a2625b1382acc302b6004892dbf7f7830285f2bae830cb0859d3f8`;
- Nature Health profile: `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- post-render semantic wrapper:
  `scripts/report_harmonization/post_render_gt_html_semantics.R`, SHA-256
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- semantic repair engine:
  `scripts/report_harmonization/repair_gt_html_semantics.R`, SHA-256
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- stale result HTML: `_build/nathealth/notebooks/hypotheses/H02.html`,
  SHA-256
  `df73f2f87d6d3bdc9acd44493a113e18b510884f0ecb8e2214b39dc3d71cb164`;
- held companion source:
  `audit/hypotheses/H02/H02_analysis_preparation.qmd`, SHA-256
  `92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1`;
- held companion HTML:
  `_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html`,
  SHA-256
  `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa`;
- H02 handoff: `audit/handoffs/H02_worker_handoff.md`, SHA-256
  `fbb74b2ed98756e1e8eb7f4b0be14cc8ec4a1873d766c1828390ebd9f5793441`;
- worker manifest:
  `artifacts/12_manifests/H02/H02_worker_output_hashes.csv`, SHA-256
  `0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331`;
- analysis manifest:
  `artifacts/12_manifests/H02/H02_analysis_manifest.csv`, SHA-256
  `cba73edc1d4974dd9a86a03513af7491aa62e8b09dbb3606895aa3af551b3804`;
- preparation manifest:
  `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv`,
  SHA-256
  `c2e8c5a3b4fcebe53f3f813aa75fac6d3d960384333f59dd1b1501d90b08aaf7`.

Quarto must be 1.9.37 and R must be 4.6.1. Use the normal project profile and
`renv` startup. Do not bypass `.Rprofile`, `renv/activate.R`, or the configured
post-render semantic hook. Use only the established narrow access to the
existing user-owned `renv` cache if startup requires it.

## Pre-render inventories and sole command

Before rendering:

1. Confirm that no Quarto render is active in this project.
2. Inventory both QMDs, every accepted H02 scientific input and artifact, all
   three current H02 manifests, the tests, handoff, profile, wrapper, engine,
   lockfile, held companion HTML, stale result HTML, and scoped
   `_build/nathealth` contents.
3. Preflight `_build/nathealth` for symlinks and fail if any resolves outside
   that directory.
4. Create one fresh absolute semantic-audit directory under `/private/tmp`
   with `mktemp -d`. Record its resolved path, permissions, and initial
   emptiness.

Run exactly one target render:

```text
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H02.qmd --profile nathealth
```

The sole Quarto command is `quarto render notebooks/hypotheses/H02.qmd
--profile nathealth`. Do not use `--no-execute`, render the companion, render
another page, or run a full-project render.

## Structural, semantic, and preservation checks

After the render:

1. Require the complete H02 reader and paired-placement tests to pass under
   R 4.6.1. Retain the source-only preparation test pin without rendering the
   companion.
2. Require exactly 15 native `gt` table endpoints and five figure endpoints in
   the accepted source order. Preserve every caption, note, alt text, displayed
   value, source-data link, and endpoint identity.
3. Require exactly 22 result-source links to 18 unique central deviation
   anchors. Verify every linked anchor, reciprocal companion link, dynamic QMD
   target, navigation entry, and country-coded study-site label.
4. Reject unresolved cross-references, forbidden local or build links, raw
   errors, warnings, stderr nodes, or missing target-owned source data. Classify
   external HTTPS edit actions as external before internal-link resolution.
5. Require the semantic hook to report `REPAIRED` or a justified
   already-correct/no-change disposition. The final document must have unique
   IDs. Every explicit `headers` token must resolve exactly once to the
   intended header in its own table, with no dangling or unsupported ID
   reference.
6. Retain the fresh external semantic-audit directory until independent
   harmonizer acceptance. Record the combined summary and per-file reversible
   ledger. Reverse the durable result HTML through that ledger and require the
   reconstructed hash to equal the hook's pre-repair hash. Verify visible
   text, table structure, endpoint order, captions, notes, links, and styles
   across the hook boundary.
7. Rehash the complete protected inventory. Both authoring QMDs, every test,
   all three H02 manifests, handoff, held companion HTML, profile, wrapper,
   engine, lockfile, ledgers, manuscript files, source data, models, estimates,
   intervals, p-values, diagnostics, dominance outputs, figures, and other
   scientific artifacts must remain byte-identical.
8. Classify the complete build delta. Only target-owned H02 result outputs and
   normal target-render search or sitemap changes may change. Record
   source-identical resource refreshes and byte-identical mtime-only touches
   separately. Fail on every unclassified content change.

No model may be fit or refit. Do not predict, bootstrap, simulate, resample,
rerun Shapley or dominance analysis, calculate a new p-value, regenerate a
scientific artifact, or change a sample, formula, estimate, interval,
diagnostic, sensitivity, or scientific claim.

## Secure loopback visual QA

Use the approved `$quarto-authoring` loopback procedure only after all
nonvisual checks pass:

1. Serve only `_build/nathealth` from one temporary read-only static server
   bound to `127.0.0.1` on one unused high or ephemeral port.
2. Navigate only to the exact H02 result route in the in-app Browser.
3. Inspect the complete page at 1440 x 1000 and 708 x 1000, plus a
   200-percent-equivalent detailed view.
4. Inspect all five figures at website final display size and at their intended
   exported final-size equivalent. Inspect the provisional principal figure
   and table particularly closely. Check axes, labels, legends, symbols,
   panels, captions, alt text, clipping, overlap, and text size.
5. Verify all 15 HTML tables are usable on an ordinary desktop or laptop
   display. At narrow width, a contained and usable horizontal scroller is
   acceptable. When a table has a separate exported PNG, its export remains
   the controlling final-output visual check and must be inspected separately.
6. Exercise disclosures, tabsets, and navigation through their visible reader
   controls. Check headings, callouts, links, wrapping, page-level overflow,
   and the full reader flow.
7. Stop the server immediately after QA. Prove that neither its process nor a
   listener remains, reset the viewport, and rehash all source, profile,
   target, held companion, build, and protected inventories.

## One-return rule and prohibitions

Return one complete package with commands, R and Quarto versions, timings,
pre/post identities, semantic mutation and reversal evidence, focused tests,
endpoint and link audits, build delta, protected reconciliation, loopback
lifecycle, screenshots and measurements, final-size QA, and a non-circular
manifest.

If a genuinely new source, scientific, semantic, link, build, or visual defect
appears, finish every safe read-only inspection and return one consolidated
fail-closed defect list. Do not patch or rerender within this order.

Forbidden actions include any source edit, model or scientific computation,
artifact regeneration, companion render, later target render, full-project
render, broad manifest builder, package or lockfile change, profile, ledger,
or manuscript edit, deletion, commit, push, upload, or publication.
