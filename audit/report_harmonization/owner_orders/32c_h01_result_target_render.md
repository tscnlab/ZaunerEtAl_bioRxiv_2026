# REPORT-017 order 32c: H01 result target render

Date: 2026-08-15

Owner: H01 task `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: **Released for exactly one fresh H01 result-page target render. The
H01 preparation/provenance companion and every later REPORT-017 target remain
held.**

## Authority and purpose

The consolidated H01 source package is independently accepted under
`audit/report_harmonization/report017_h01_order32_source_independent_acceptance.md`,
SHA-256
`6ffd7fa5b3c052e1d3188b41ba89b36ac1e013aabe1e8c6ea0b0a05db01767c6`,
with the 25-row non-circular acceptance manifest at SHA-256
`a883692b38702797eb41b4aec35187da658b069fd39b24cb36fc04e94359dc51`.

This order integrates only the H01 result page through the accepted Nature
Health profile and configured post-render native-gt semantic hook. It does not
release the companion or another target.

## Exact preflight pins

Stop before rendering if any identity differs:

- result QMD `notebooks/hypotheses/H01.qmd`:
  `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb`;
- frozen companion QMD
  `audit/hypotheses/H01/H01_analysis_preparation.qmd`:
  `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f`;
- Nature Health profile `_quarto-nathealth.yml`:
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- post-render wrapper
  `scripts/report_harmonization/post_render_gt_html_semantics.R`:
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`;
- native-gt semantic engine
  `scripts/report_harmonization/repair_gt_html_semantics.R`:
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- accepted post-render transition test
  `tests/report_harmonization/test_post_render_gt_html_semantics.R`:
  `696e3308275d366dcc4aefb8e60c36d7c4c42d02a88402e3d06717b6383d0fae`;
- independent source acceptance:
  `6ffd7fa5b3c052e1d3188b41ba89b36ac1e013aabe1e8c6ea0b0a05db01767c6`;
- its 25-row manifest:
  `a883692b38702797eb41b4aec35187da658b069fd39b24cb36fc04e94359dc51`;
- stale result HTML
  `_build/nathealth/notebooks/hypotheses/H01.html`:
  `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa`;
- frozen stale companion HTML
  `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html`:
  `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`.

Audit all 25 rows in the accepted source manifest before execution. The stale
result HTML is expected to change only through this render. Every other row,
including the companion HTML, must remain exact.

Before execution, create and seal:

1. a complete protected-input inventory covering the accepted H01 scientific
   inputs, artifacts, source, tests, current manifests, handoff, profile, hook,
   engine, and source-acceptance evidence; and
2. a complete `_build/nathealth` inventory with SHA-256, byte count, and mtime.

Stop on any unclassified preflight drift.

## Sole execution

Run exactly once from the project root:

```sh
quarto render notebooks/hypotheses/H01.qmd --profile nathealth
```

Use the normal project profile and R 4.6.1 startup. If required, use only the
already accepted narrowly elevated access to the existing user-owned renv
cache. Do not bypass `.Rprofile`, `renv/activate.R`, or the configured
post-render hook. Do not use `--no-execute`.

Record the exact command, start and end time, runtime, exit status, complete
Quarto output, Quarto version, R version, consequential package versions, and
the hook disposition for the H01 HTML. Require normal successful hook
completion. Do not run a second render.

## Protected and build-output verification

After the render:

- prove that the result QMD, frozen companion QMD and HTML, profile, wrapper,
  engine, accepted tests, current manifests, handoff, source-acceptance records,
  and complete H01 protected scientific set are byte-identical;
- prove that no model, fit, prediction, simulation, bootstrap, resampling,
  Shapley analysis, scientific artifact, or source-data regeneration occurred;
- inventory every build change and require the only content-changing build
  outputs to be the target H01 HTML and the normal bounded `search.json` and
  `sitemap.xml` updates;
- classify any byte-identical mtime-only asset touch separately; and
- preserve every other build member, especially the companion HTML.

Run the complete H01 reporting test in its fresh-render branch and the focused
navigation, reader-link, deviation-link, country-code, and native-gt semantic
contracts. Do not edit or rerun
`tests/report_harmonization/test_post_render_gt_html_semantics.R`, which is the
accepted pre-integration transition test and intentionally pins the earlier
HTML state.

## Semantic and reader contract

Require the fresh result HTML to contain exactly:

- 36 native `gt` tables;
- ten intended figure endpoints;
- 40 links to 36 unique preregistration-deviation anchors; and
- one occurrence of every declared reader-facing endpoint and anchor.

Verify all accepted table values, row and column order, captions, source notes,
styles, figure captions, alt text, source-data links, dynamic internal targets,
navigation, country-coded site names, and external-link classification.

The configured semantic hook must leave:

- zero duplicate document IDs;
- every explicit `headers` token resolving exactly once to the intended `th`
  within its own table;
- zero dangling or unsupported ID references; and
- no change to visible table text, values, order, captions, notes, styles,
  links, or Quarto table endpoints.

Verify that `fig-h01-model-support` and
`tbl-h01-primary-publication-summary` are the first result figure and table.
They must retain the accepted FDR wording. Verify zero unresolved
cross-references, raw error nodes, warning nodes, or stderr output.

The unbuilt Supplementary information target remains the known shared
DOC-001 hold. External HTTPS GitHub edit actions are external links and are
not internal-link defects.

## Complete secure-loopback visual QA

After all nonvisual checks pass, use the active `$quarto-authoring` secure
loopback procedure:

1. Recheck the scoped build inventory and preflight `_build/nathealth` for
   symlinks. Stop if any symlink resolves outside that directory.
2. Start one temporary read-only static HTTP server with document root exactly
   `_build/nathealth`, bound only to `127.0.0.1` on one unused high or
   OS-selected port. Expose no write or upload endpoint.
3. Record the exact server command, PID, address, port, document root, start
   time, and exact H01 result URL.
4. Use only the in-app Browser and inspect the exact result route at 1440 by
   1000 and 708 by 1000. Also inspect the principal figure and table at 200%.
5. Inspect all ten figures at final display size and inspect the exported
   principal figure at its intended final-size equivalent. Check typography,
   legends, panel labels, captions, clipping, overlap, overflow, callouts,
   links, and navigation.
6. Apply the accepted table policy: tables must work reasonably at a typical
   desktop or laptop width; narrow tables may use a contained, visible, usable
   horizontal scroller. For exported tables, inspect the PNG export rather
   than treating the HTML layout as the export acceptance surface.
7. Stop the server immediately after QA and prove that no listener remains on
   the port.
8. Rehash the complete build and protected inventories and prove no post-QA
   drift.

Retain desktop, narrow, and focused principal-output screenshots plus measured
final-size evidence in H01-owned audit paths.

## Consolidated stop rule and return

If startup, rendering, hook execution, protected identities, semantics, links,
or visual QA exposes any defect, do not patch or rerender. Continue the
complete result-page inspection wherever safely possible, then seal one
combined stopped-state defect list with all observed issues, identities, and
unexecuted gates. Return it once for disposition.

On PASS, return:

- exact preflight and post-render identities;
- complete render and hook output;
- final H01 HTML identity and exact build delta;
- protected-inventory reconciliation and scientific no-change evidence;
- all semantic, table, figure, navigation, link, country-code, and deviation
  checks;
- desktop, narrow, 200%, and final-size visual evidence;
- secure-loopback startup and teardown evidence; and
- a non-circular owner verification manifest.

No source, test, scientific artifact, profile, package, lockfile, shared
ledger, manuscript, commit, push, upload, companion render, later target, or
full-project render is authorized.
