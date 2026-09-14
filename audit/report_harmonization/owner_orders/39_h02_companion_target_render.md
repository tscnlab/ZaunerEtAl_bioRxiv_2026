# REPORT-018 order 39: H02 companion target render and integration

Date: 2026-08-20

Owner: H02 task `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`

Status: **AUTHORIZED ONCE**

The H02 result page and Supplementary information page are independently
accepted. This order releases only the H02 preparation/provenance companion.
No result rerender or later target is released.

## Controlling acceptances and exact live pins

- REPORT-018 decision:
  `audit/decisions/report_harmonization_render_completion_priority.md`,
  SHA-256
  `0cb7c62806b40c1702c7fdde994d98090f0fc820abfa32205a8e58e392681ecf`;
- scheduling addendum:
  `audit/report_harmonization/report017_render_completion_scheduling_override.md`,
  SHA-256
  `117dfedc650dc035b74978a7621cac8ef7bf14c8caf4533d0a94f7fecb1b52e0`;
- H02 source acceptance:
  `audit/report_harmonization/report017_h02_order33_source_independent_acceptance.md`,
  SHA-256
  `127a25b9d95fbb41d4506cb1ed66df775ec01e40d3d3504a5980054dd7911d24`;
- H02 result acceptance:
  `audit/report_harmonization/report018_h02_result_independent_acceptance.md`,
  SHA-256
  `13a5121a00974e7660b7b045319c945e3c84a56a7ea13b2d72e23b16d204ab4d`;
- Supplementary acceptance:
  `audit/report_harmonization/report018_supplementary_information_independent_acceptance.md`,
  SHA-256
  `2c1b25a9d96963b7e8030867117bb70b9958bc18a1918a9da7463f2245b545b2`;
- companion source:
  `audit/hypotheses/H02/H02_analysis_preparation.qmd`, SHA-256
  `92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1`,
  55,146 bytes;
- result source:
  `notebooks/hypotheses/H02.qmd`, SHA-256
  `4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d`,
  57,148 bytes;
- accepted result HTML:
  `_build/nathealth/notebooks/hypotheses/H02.html`, SHA-256
  `736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9`;
- stale companion HTML:
  `_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html`,
  SHA-256
  `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa`;
- profile: `_quarto-nathealth.yml`, SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`;
- semantic wrapper and engine: SHA-256
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`
  and
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- reader, paired-placement, and preparation tests: SHA-256
  `479a702e7c5c52cf85e8591300a30c759da945f4c65ecb28cad67bb2e6752d3f`,
  `873c43f0d863c78c22e3e0635d054f09bc521a24d618afcda134a831ac7e7d8a`,
  and
  `ead7a55246a2625b1382acc302b6004892dbf7f7830285f2bae830cb0859d3f8`;
- preparation, worker, and analysis manifests: SHA-256
  `c2e8c5a3b4fcebe53f3f813aa75fac6d3d960384333f59dd1b1501d90b08aaf7`,
  `0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331`,
  and
  `cba73edc1d4974dd9a86a03513af7491aa62e8b09dbb3606895aa3af551b3804`;
- preparation-manifest helper:
  `scripts/hypotheses/H02/build_h02_preparation_report_manifest.R`, SHA-256
  `8fb4744bce578df85ec9683ab87271bfcc0ba79fcc7d53a7d21b8b3d406c9d16`;
- H02 handoff: `audit/handoffs/H02_worker_handoff.md`, SHA-256
  `fbb74b2ed98756e1e8eb7f4b0be14cc8ec4a1873d766c1828390ebd9f5793441`;
- accepted Supplementary HTML:
  `_build/nathealth/supplementary_information.html`, SHA-256
  `a0b5d097b12ee4a7cbfbcd5cb4740f1eac81bf1c9dba1e4e00a9d5644bfec4eb`.

The dispatch preflight records 16 unique native-table endpoints, four unique
figure endpoints, 24 parseable R chunks, result-to-companion profile adjacency,
zero output-tree symlinks, the exact four deferred preparation-manifest
mismatches, and the exact seven historical worker-manifest mismatches.

## One consolidated procedural integration

Do not stop or request another classification for the integration steps in this
section. They are pre-authorized as one procedural companion order. None may
change reader language, scientific values, or accepted artifacts.

### 1. Preinventory and helper synchronization boundary

Recheck every dispatch pin, inventory protected H02 inputs and the complete
`_build/nathealth` tree, reject unsafe symlinks, and confirm no Quarto render is
active.

Edit only
`scripts/hypotheses/H02/build_h02_preparation_report_manifest.R` to add the
following deterministic synchronization, modelled on the accepted H01 helper:

1. Treat the authoring companion QMD and its existing build-side QMD as regular
   non-symlink files. Copy the authoring QMD over the build-side QMD with mode
   preservation and require exact source hash, byte, and mode preservation plus
   exact target equality.
2. Treat exactly these two accepted source CSVs as protected download sources:
   `preparation_response_distribution_positive_observations.csv`, SHA-256
   `22dff3af0f213b3ceaed0d5ca827da4184b662ff7d0366d592b6598b56e96842`,
   and `preparation_response_distribution_exact_zero_summary.csv`, SHA-256
   `f2cc126a168bf8d6db3c5b13b3c6fea83030b23e7fdebff882bea1eb390f31db`.
   Copy them only to the corresponding
   `_build/nathealth/artifacts/11_source_data/H02/` paths, preserving modes and
   requiring exact source and target hashes and bytes.
3. Add only those two build-side downloads to the preparation manifest, with a
   dedicated `preparation_page_download` role.

Change no other helper behavior. Air-format and parse only this helper. Record
an exact diff and reverse proof to its pre-edit identity.

### 2. Sole render command

Create one fresh absolute semantic-audit directory under `/private/tmp`. Run
exactly once through normal R 4.6.1 project and `renv` startup, using only the
established narrow cache access:

```text
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render audit/hypotheses/H02/H02_analysis_preparation.qmd --profile nathealth
```

Do not use `--no-execute`, preview, a full-project render, a result render, or a
second Quarto command. The page may read and format accepted artifacts only.
No fit, refit, prediction, simulation, bootstrap, dominance, Shapley, model
selection, scientific artifact regeneration, or scientific source-data write
is allowed.

### 3. Post-render synchronization and test classification

After a successful render, run the bounded preparation-manifest helper exactly
once. Require:

- build-side and authoring companion QMDs byte-identical at `92424e41...`;
- the two build-side source-data downloads byte-identical to their protected
  source CSVs;
- exactly 59 unique, live-exact preparation-manifest rows;
- all four former preparation-manifest mismatches resolved;
- accepted result source and HTML, profile, companion source, scientific
  artifacts, and every unrelated build member preserved.

Edit only the existing integration literals and mismatch-set assertions in
`tests/hypotheses/H02/test_h02_reader_report.R` and
`tests/hypotheses/H02/test_h02_preparation_report.R` so they pin the fresh
companion HTML and new 59-row preparation manifest, retain the accepted result
HTML `736dc631...`, and require zero preparation-manifest mismatches.

Keep `artifacts/12_manifests/H02/H02_worker_output_hashes.csv` byte-identical.
Both tests must retain its exact historical identity and require exactly the
following historical-to-live mismatch set, with no eleventh path:

1. `_build/nathealth/notebooks/hypotheses/H02.html`;
2. `_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html`;
3. `audit/handoffs/H02_shared_change_request.md`;
4. `audit/hypotheses/H02/H02_analysis_preparation.qmd`;
5. `notebooks/hypotheses/H02.qmd`;
6. `scripts/hypotheses/H02/build_h02_preparation_report_manifest.R`;
7. `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv`;
8. `tests/hypotheses/H02/test_h02_paired_placement_display.R`;
9. `tests/hypotheses/H02/test_h02_preparation_report.R`;
10. `tests/hypotheses/H02/test_h02_reader_report.R`.

This preserves the worker manifest as historical evidence and avoids a
self-hash cycle. Do not run `build_h02_worker_manifest.R` or any broad manifest
builder. Require exact test diffs and reverse proofs. Change no scientific,
endpoint, formula, value, link, terminology, or display assertion.

## Acceptance checks

Run the complete reader, preparation, and paired-placement tests under R 4.6.1.
Then require:

1. exactly 16 native `gt` tables, four figures, one TD Mermaid diagram, all
   captions, notes, alt text, endpoint labels, and endpoint order;
2. semantic-hook repair with document-wide unique IDs, every explicit
   `headers` token resolving exactly once to its intended header inside the
   same table, zero dangling or unsupported ID references, and reversible hook
   evidence;
3. reciprocal H02 result/companion links, active navigation, accepted
   Supplementary target, dynamic internal links and anchors, country-coded site
   names, nonempty link labels, and zero forbidden local or build links;
4. zero embedded error, warning, or stderr nodes and zero unresolved Quarto
   references;
5. exact preservation of every protected scientific input and artifact, both
   authoring QMDs, result HTML, profile, lockfile, packages, ledgers, manuscript,
   and every unrelated source;
6. a complete build-delta classification limited to companion target HTML and
   target-owned assets, the source-identical companion QMD and two downloads,
   normal search/sitemap changes, and byte-identical mtime-only framework
   touches. Stop on any unclassified content change.

Use one secure loopback server rooted exactly at `_build/nathealth`, bound only
to `127.0.0.1`, after symlink preflight. Inspect only the exact H02 companion
route at 1440 x 1000 and 708 x 1000, plus 200-percent-equivalent and intended
final-size views where appropriate. Inspect all 16 native tables, all four
figures, the TD Mermaid, headings, callouts, captions, links, navigation,
wrapping, clipping, overlap, and page overflow. Native HTML tables must be
usable at desktop size; narrow overflow may use a contained working horizontal
scroller. For exported graphical outputs, inspect the PNG versions at their
intended final size.

Stop the server, prove no listener, reset the viewport, and rehash the complete
protected and build inventories. Retain the external semantic audit until
independent acceptance.

Return one combined owner acceptance or one consolidated fail-closed defect
list. Under REPORT-018, do not stop or patch for nonblocking language, style,
test-literal, optional-link, or cosmetic observations. Record and defer them.
Stop without rerendering only for render failure, protected drift, scientific
discrepancy, missing required output, semantic invalidity, broken required
link, or a materially unusable display.

## Prohibitions

No QMD edit, result rerender, later target render, full-project render,
scientific computation, scientific artifact regeneration, profile or shared
configuration edit, ledger or manuscript edit, package or lockfile change,
commit, push, upload, publication, deletion, or broad manifest rebuild.

The H03 result and every later REPORT-018 target remain held pending independent
H02 companion acceptance.
