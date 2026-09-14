# REPORT-018 owner order 47a: H06 hourly provenance repin and result render

Date: 2026-08-21  
Owner: H06  
Scope: one consolidated provenance-only source transition and one hourly H06
result-page render  
Status: released after exact dispatch preflight

## Controlling acceptance

Order 47 stopped before page generation because three identities in the H06
input contract predate the accepted METRIC-011 base-model bundle. The stopped
state and scientific disposition are accepted under:

- `audit/report_harmonization/report018_h06_order47_stopped_acceptance.md`
  at SHA-256
  `1c37c4daa7d29233fcffdb798704bae6541fc8f08fe2755effef597e827b2894`,
  4,757 bytes;
- `audit/report_harmonization/report018_h06_order47_stopped_acceptance_manifest.csv`
  at SHA-256
  `0ce42ac36fcf0536f1eb2156c82668b17da7605521af3b2deea5959b89fe5bb8`,
  2,900 bytes, 18 exact unique non-circular rows; and
- `audit/decisions/preparation06_current_base_model_gate.md` at SHA-256
  `63f17f1b9b3a91d437a5964cde063770d0fb4fac3f9c81e588fc374d9cc71f04`.

The controlling decision establishes that every hourly scientific value is
unchanged and all six accepted H06 hourly frames are identical with tolerance
zero and attributes included. This order is a provenance-gate repair, not a
scientific rerun.

## Hard preflight

Before mutation, reproduce every hard path in
`audit/report_harmonization/report018_h06_order47a_dispatch_manifest.csv`.
The coordination-matrix row is dispatch-time evidence only. Stop on any other
drift, any competing Quarto render, any H06 process, any build symlink, or any
nonempty semantic-audit directory.

The exact mutable preimage is:

- `scripts/hypotheses/H06/h06_contract.R`
- SHA-256
  `9de4d56e462de9188bf1123984f3b06b3e01b01706a9618026e98f53444de2bb`
- 13,468 bytes

The result source must remain
`468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2`
and the held companion source must remain
`f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b`.
The profile must remain
`80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.

## A. Exact contract transition

Edit only `scripts/hypotheses/H06/h06_contract.R`. Replace exactly these
three SHA-256 literals and no other byte:

| Path | Old literal | New literal |
|---|---|---|
| `artifacts/06_model_data/base/metrics_glasses_one_hour_context.rds` | `27b17c0232a90b6982377b1944b30e5574a02e691217a81f671ab14e45916f67` | `7591bcfaae4b49fdde2053160848e170895092b223f96108e538066ce210a951` |
| `artifacts/06_model_data/base/metrics_chest_one_hour_context.rds` | `99885940c952c60ff6981ce029758ac43aec22c41cc27f22176fb3ab4f9c7186` | `18134eec529c36e5fd47c7b3bb1e3b909628b97986cd91eff8e59ee9b5343cbb` |
| `artifacts/12_manifests/base_model_data_artifacts.csv` | `b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09` | `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce` |

Required postimage:

- SHA-256
  `b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f`
- 13,468 bytes

Require all of the following before rendering:

1. exact forward proof that only those three complete literals changed;
2. exact reverse substitution reproducing the preimage byte-for-byte;
3. R 4.6.1 parse PASS;
4. `h06_input_contract()` returns exactly 21 unique paths;
5. every declared path exists and is a regular non-symlink;
6. all 21 current SHA-256 identities match exactly;
7. the exact three changed roles are the two hourly RDS files and current base
   manifest, with no fourth transition; and
8. the result and companion QMDs, accepted artifacts, profile, package lock,
   held companion HTML, and complete protected scientific set remain exact.

Do not run a model, builder, QMD, historically coupled H06 test, or broad
manifest builder during this gate. Do not edit the Stage 3 manifest. Record
the accepted transition as bounded order evidence only.

## B. Sole target render

If and only if section A passes completely, create one fresh absolute empty
semantic-audit directory under `/private/tmp` and run exactly once:

```sh
GT_HTML_SEMANTIC_AUDIT_DIR=<fresh-absolute-directory> quarto render notebooks/hypotheses/H06.qmd --profile nathealth
```

Use normal R 4.6.1 project-profile and renv startup with only the established
narrow access to the existing user-owned renv cache. The configured semantic
hook must run normally. Do not use `--no-execute`, bypass the profile or hook,
render the companion, render H06 daily, render another target, or run the full
project.

## C. Nonvisual acceptance

After the single render, require:

1. exit 0 and a fresh target HTML;
2. semantic-hook disposition `REPAIRED` or `ALREADY_REPAIRED`, with a retained
   external summary and reversible ledger;
3. exactly 11 native gt tables and six intended figure endpoints in accepted
   source order, with captions, notes, alt text, values, labels, source-data
   links, and accepted FDR language preserved;
4. document-wide unique IDs, every explicit `headers` token resolving exactly
   once inside its own table to the intended `th`, and zero dangling or
   unsupported ID references;
5. all accepted result/companion, Preparation 06, Supplementary information,
   deviation-page, and four DEV-anchor links resolving;
6. exactly the unbuilt H06 daily target as the one permitted held internal
   link, with every other internal reader link resolved;
7. active navigation, nine country-coded study sites, no forbidden local or
   build link, no unresolved cross-reference, and no embedded error, warning,
   or stderr node;
8. both QMDs, accepted source CSVs and durable exports, all scientific
   artifacts, profile, hook, package lock, held companion HTML, H06 daily
   sources, and every unrelated build member byte-identical;
9. build changes confined to the target H06 HTML, normal target-owned build
   copies and assets, and search/sitemap outputs; classify source-identical
   resource synchronization and mtime-only framework touches separately; and
10. exact pre-render, post-render, and post-QA protected and build inventories
   with no symlink and no unclassified change.

Do not rerun the order-46 artifact verifier, the historical Stage 3 test, the
companion test, or the pre-integration semantic transition test after the HTML
changes. Verify the actual rendered document directly.

## D. Secure loopback visual QA

After all nonvisual gates pass:

1. preflight `_build/nathealth` for symlinks and stop on any escape;
2. start one read-only static server rooted exactly at `_build/nathealth`,
   bound only to `127.0.0.1` on one unused high port;
3. open only the exact H06 result route in the in-app Browser;
4. inspect the complete page at 1440 by 1000 and 708 by 1000, plus
   200-percent-equivalent and intended final-output views;
5. inspect all 11 tables and six figures, including every repaired exported
   PNG at its intended final-size equivalent;
6. apply the accepted table policy: desktop/laptop usability is controlling;
   a narrow table may use a contained usable horizontal scroller without page
   overflow;
7. check figure and table text, axes, legends, symbols, panels, labels,
   captions, disclosures, callouts, navigation, links, clipping, overlap,
   wrapping, and page overflow; and
8. stop the server, prove no listener remains, reset the viewport, and prove
   post-QA source/profile/build/protected stability.

For HTML tables, ordinary desktop usability is the controlling check. For
exported tables or figures, the stored PNG at intended final size is the
controlling export check.

## E. Return and fail-closed boundary

Return one combined completion record and one non-circular owner evidence
manifest under `audit/hypotheses/H06/report018_order47a_result_render/`.
Record the exact source transition, commands, R and Quarto versions, semantic
summary and ledger, build/protected deltas, link and endpoint results, browser
measurements and screenshots, server lifecycle, and final identities.

If a genuinely new contract, render, semantic, link, protection, or visual
defect appears, finish every safe read-only inspection and return one
consolidated stopped-state list. Do not patch or rerender.

No QMD, test, table, figure, source CSV, model, estimate, interval, p-value,
FDR decision, diagnostic, sample, scientific artifact, Stage 3 manifest,
profile, ledger, package, lockfile, companion page, H06 daily page, later
target, commit, push, upload, or publication action is authorized. H06
companion and every later REPORT-018 render remain held pending independent
H06 result-page acceptance.
