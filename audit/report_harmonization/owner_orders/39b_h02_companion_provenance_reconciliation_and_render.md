# REPORT-018 order 39b: H02 companion provenance reconciliation and render

Date: 2026-08-20

Owner: H02 task `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44`

Status: **AUTHORIZED ONCE AS ONE CONSOLIDATED CONTINUATION**

Order 39a proved that normal renv startup succeeds with the established narrow
cache permission. It then stopped at the H02 input validator on four identities
that predate orders 39 and 39a. Independent R 4.6.1 reconciliation proves that
the current 30-minute inputs reconstruct all four frozen H02 main model frames
exactly. This order applies the provenance-only live-contract update and then
finishes the H02 companion render and integration in one pass.

Do not split this order into separate source, test, manifest, render, or visual
cycles. Use one combined fail-closed return only for a genuinely new defect.

## Controlling reconciliation

- reconciliation record:
  `audit/report_harmonization/report018_h02_order39a_input_reconciliation.md`,
  SHA-256
  `07d8c15833396cbcd86475358ab487a54210115ad5139f8bf7af1ddf4705a277`,
  6,690 bytes;
- structured evidence:
  `audit/report_harmonization/report018_h02_order39a_input_reconciliation_evidence.csv`,
  SHA-256
  `26c2922147bb0a0ef5ad6b34ce513a364823c3951dccaba2e525779e91261797`,
  2,978 bytes;
- non-circular 27-row manifest:
  `audit/report_harmonization/report018_h02_order39a_input_reconciliation_manifest.csv`,
  SHA-256
  `8aaf2725ec885dffd16a7c6061eec4716b636be9bd726dde2b1beebc68bfd82a`,
  3,463 bytes, R 4.6.1 audit 27/27 exact and unique;
- accepted METRIC-011 decision and invariance summary: SHA-256
  `23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797`
  and
  `34ddcd418be07d50484bad2b62411e6c8961788af0b45d0ff436708ed3d0c213`;
- accepted order-00b index transition verification: SHA-256
  `14be1395553e08e61697d231f62b6c5d27d31a8a0efa4c85dd299a5623eb1687`.

The order-39a and order-39 records and both empty semantic directories remain
historical stopped-state evidence. Do not modify or remove them.

## Hard preflight pins

- current H02 contract:
  `scripts/hypotheses/H02/h02_contract.R`, SHA-256
  `76a72eb8a164f93756796ac593c76c09d5aff983167861ae39efac45974ee025`,
  11,946 bytes;
- unchanged contract test:
  `tests/hypotheses/H02/test_h02_contract.R`, SHA-256
  `0211746b1f1b45968d847f440081885110ae1740ca66641062d250dd211243d5`,
  4,418 bytes;
- authorized unexecuted preparation helper:
  `scripts/hypotheses/H02/build_h02_preparation_report_manifest.R`, SHA-256
  `3e69748ad3b3ef3dde7dcd0dc3c913d21971c1c5ef5098e44452d3f2f37111b1`,
  10,401 bytes;
- companion source and stale HTML: SHA-256
  `92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1`
  and
  `d02a0963d657ab5044ef30b5c081d627f8cb64d5781c7edc1d95d2d58c055dfa`;
- result source and accepted HTML: SHA-256
  `4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d`
  and
  `736dc6311e53f2b70349326ce0845cc35d23e3b68c000a300833952e81190dd9`;
- current preparation and historical worker manifests: SHA-256
  `c2e8c5a3b4fcebe53f3f813aa75fac6d3d960384333f59dd1b1501d90b08aaf7`
  and
  `0f3a96ab08f7fed2b59eb4a45f203297483919b3067bee560c9e239693242331`;
- current reader, preparation, paired-placement, and contract tests: SHA-256
  `479a702e7c5c52cf85e8591300a30c759da945f4c65ecb28cad67bb2e6752d3f`,
  `ead7a55246a2625b1382acc302b6004892dbf7f7830285f2bae830cb0859d3f8`,
  `873c43f0d863c78c22e3e0635d054f09bc521a24d618afcda134a831ac7e7d8a`,
  and
  `0211746b1f1b45968d847f440081885110ae1740ca66641062d250dd211243d5`;
- profile, semantic wrapper, and semantic engine: SHA-256
  `80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`,
  `28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205`,
  and
  `7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1`;
- current live near-eye input, chest input, base manifest, and index: SHA-256
  `85a927003c54821ae9ed5d9b4266e07f75488c743b570ec67b48a14ecfa88920`,
  `b2c0290c3eff5ef5ae5e92af6d8c693043f3ad0409392e80652e97ffcac8ef15`,
  `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce`,
  and
  `86766c377e7ee1dcfea6b1ada8704b04320bbc231630c4044cd9c9d93aa0bf80`;
- historical H02 fit-time input record:
  `artifacts/06_model_data/H02/input_hashes.csv`, SHA-256
  `aa1c2c9b63cbe080ced3862de904921c0c6112ed5050844294b4138a63317548`;
- frozen all-available and paired-common model frames: SHA-256
  `8420e7a5c1d1b89eda29807abf1c339c5d3b43095ae5d297ebed85f13f6de11e`,
  `5826c426d127c096a381e4b894c514b95552672fa12b59b28d6fd26c9b655c90`,
  `4c69dc4219220662628377fe2d9e71195f65080409c300eedd48be64464238b1`,
  and
  `a5ab949b605e7fb0730baea601b2fedecd469231435e97a34199ea4873a71c67`.

The dispatch-time coordination-matrix identity is coordination evidence, not a
hard execution pin. All owner-scoped and stable shared pins above are hard.

## A. Four-literal live-contract repair

Edit only `scripts/hypotheses/H02/h02_contract.R`. Replace exactly:

1. `afa5a23308744ae495ef07a521c99e11bd7296aa855c5cb773f71f2b68eeb8e5`
   with
   `85a927003c54821ae9ed5d9b4266e07f75488c743b570ec67b48a14ecfa88920`;
2. `01a4a85e5ead5b30219f969c64d50b94a2bebf84b60cc4006badbc3c3c9513a2`
   with
   `b2c0290c3eff5ef5ae5e92af6d8c693043f3ad0409392e80652e97ffcac8ef15`;
3. `142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4`
   with
   `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce`;
4. `aa24170aa24cb6a39f2a1e3cf6d33ead9d1a20c6cfe2860674d20802ca28ec9e`
   with
   `86766c377e7ee1dcfea6b1ada8704b04320bbc231630c4044cd9c9d93aa0bf80`.

Change no path, role, function, formula, parameter, value, or other byte. The
required post-edit contract is SHA-256
`48fef63abda50e1189b019254d56d588d539c40a984fde66502ec468878c72f0`,
11,946 bytes. Require exact four-substitution reverse proof to the pre-edit
identity, R 4.6.1 parse, and scoped diff check.

Do not edit `tests/hypotheses/H02/test_h02_contract.R`. Run that complete test
once after the repair. It must pass against the current inputs and all frozen
H02 model frames.

Preserve `artifacts/06_model_data/H02/input_hashes.csv`, the figure-replication
input records, and every fitted model, model frame, prediction, diagnostic,
table, figure, source-data file, scientific manifest, and historical report
byte-for-byte. They remain truthful fit-time provenance.

## B. One companion target render

After the contract test passes, recheck the protected set and complete
`_build/nathealth` inventory. Require the two earlier semantic directories to
remain empty and the existing build to match the order-39 preinventory exactly.

Create one fresh empty absolute semantic-audit directory under `/private/tmp`.
Run exactly one command through the normal R 4.6.1 project profile and renv,
using the established narrow permission for transient writes to the existing
user-owned renv cache:

```text
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render audit/hypotheses/H02/H02_analysis_preparation.qmd --profile nathealth
```

Do not bypass `.Rprofile`, `renv/activate.R`, or the semantic hook. Do not use
`--no-execute`, preview, a result render, another target, or a full-project
render. This is the only render attempt in order 39b.

## C. Existing post-render integration

After exit 0 and a valid semantic-hook record, run the unchanged authorized
helper exactly once. Require:

- the build-side and authoring companion QMDs to be byte-identical at
  `92424e41...` and 55,146 bytes;
- the two source-data downloads to be byte-identical to their protected source
  CSVs;
- exactly 59 unique and live-exact preparation-manifest rows;
- the updated live H02 contract row to carry the exact post-edit identity;
- all prior preparation-manifest mismatches to be resolved.

Apply the already authorized companion-integration literal and mismatch-set
changes only in `tests/hypotheses/H02/test_h02_reader_report.R` and
`tests/hypotheses/H02/test_h02_preparation_report.R`. Pin the fresh companion
HTML and new preparation manifest, preserve the accepted result HTML, and
require zero preparation-manifest mismatches.

Keep `artifacts/12_manifests/H02/H02_worker_output_hashes.csv` byte-identical.
Both tests must require exactly the following 11 historical-to-live worker
mismatches, with no twelfth path:

1. `_build/nathealth/notebooks/hypotheses/H02.html`;
2. `_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html`;
3. `audit/handoffs/H02_shared_change_request.md`;
4. `audit/hypotheses/H02/H02_analysis_preparation.qmd`;
5. `notebooks/hypotheses/H02.qmd`;
6. `scripts/hypotheses/H02/build_h02_preparation_report_manifest.R`;
7. `scripts/hypotheses/H02/h02_contract.R`;
8. `artifacts/12_manifests/H02/H02_preparation_report_manifest.csv`;
9. `tests/hypotheses/H02/test_h02_paired_placement_display.R`;
10. `tests/hypotheses/H02/test_h02_preparation_report.R`;
11. `tests/hypotheses/H02/test_h02_reader_report.R`.

Require exact test diffs and reverse proofs. Do not run
`build_h02_worker_manifest.R` or any broad manifest builder. Preserve the H02
handoff byte-identical as historical analysis-time documentation; the new
reconciliation record is the controlling live-input supplement.

## D. Complete acceptance

Run the complete contract, reader, preparation, and paired-placement tests
under R 4.6.1. Then require all order-39 acceptance contracts:

1. exactly 16 native `gt` tables, four figures, one TD Mermaid, and all
   captions, notes, alt text, labels, and endpoint order;
2. valid semantic-hook repair, document-wide unique IDs, every explicit
   `headers` token resolving once to its intended header in the same table,
   zero dangling or unsupported ID references, and reversible hook evidence;
3. reciprocal H02 result/companion links, active navigation, accepted
   Supplementary target, deviation links and anchors, country-coded sites,
   nonempty labels, and zero forbidden local or build links;
4. zero embedded error, warning, or stderr nodes and zero unresolved Quarto
   references;
5. exact preservation of accepted result source and HTML, both authoring QMDs,
   all historical H02 scientific inputs and artifacts, profile, packages,
   lockfile, ledgers, manuscript, and unrelated sources;
6. complete build-delta classification limited to the companion HTML and
   target-owned assets, source-identical companion QMD and two downloads,
   normal search and sitemap changes, and separately classified byte-identical
   mtime-only framework touches.

Use one secure loopback server rooted exactly at `_build/nathealth`, bound only
to `127.0.0.1`, after symlink preflight. Inspect the exact H02 companion route
at 1440 x 1000 and 708 x 1000, plus 200-percent-equivalent and intended final
sizes. Inspect all 16 tables, four figures, the TD Mermaid, headings, callouts,
captions, links, navigation, wrapping, clipping, overlap, and page overflow.
HTML tables must be usable at desktop size; narrow overflow may use a contained
working horizontal scroller. For exported graphical outputs, inspect the PNGs
at intended final size.

Stop the server, prove no listener remains, reset the viewport, and rehash the
complete protected and build inventories. Retain the external semantic audit
until independent acceptance.

Under REPORT-018, record and defer nonblocking language, style, optional-link,
test-literal, or cosmetic observations. Do not patch or rerender for them.
Return one combined acceptance package or one combined fail-closed state for a
new render, protection, scientific, semantic, required-link, missing-output, or
material usability defect.

## Prohibitions

No QMD edit, result rerender, later target render, full-project render, model
fit or refit, prediction, bootstrap, simulation, resampling, dominance or
Shapley recomputation, scientific artifact regeneration, full builder, profile
or shared configuration edit, ledger or manuscript edit, package or lockfile
change, cache deletion, commit, push, upload, or publication.

The H03 result and every later REPORT-018 target remain held pending
independent H02 companion acceptance.
