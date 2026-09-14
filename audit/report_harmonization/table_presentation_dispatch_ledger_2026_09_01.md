# Reader-table presentation dispatch ledger

Date: 2026-09-01

Status: **ALL INTENDED OWNER DISPATCHES HAVE SOURCE-ONLY RETURNS**

This ledger records task-visible dispatch and return evidence for the approved
reader-table convergence. The common contract is a 12 px primary native `gt`
body/header base, deliberately smaller secondary notes and annotations, and
table-local horizontal overflow where needed. The work was source-only. No
QMD was executed and no report was rendered as part of these owner turns.

## Classification

1. Executable order actually sent and source-only return received.
2. Executable order sent and still active.
3. Deliberately no change required, with checked reason.
4. Missed or queue-only, followed by a newly issued executable order.

After correcting the initially queue-only H03 and H11 communications, every
intended owner below is in classification 1. There are no remaining entries in
classifications 2, 3, or 4.

## Owner receipts and postimages

| Owner | Task ID | Classification | Authoritative source postimage | Return evidence |
|---|---|---:|---|---|
| Descriptives | `019fb87f-41b5-75c1-bc11-aa7fa233ef89` | 1 | `scripts/descriptives/build_publication_tables.R` `d944e4b4343b98f27a02beb50219f197007cd6c5cb6eecb5ed6f71b14d4ab886`; `notebooks/descriptives.qmd` `c17fef3ca932fa8cf195f6ae6604e822e3b46235cefd6a081d4eef69b88546bc` | Eight endpoints, seven native paths, 12 px base, local overflow, R 4.6.1 parse and static contract passed. |
| H01 | `019fb4ce-d84c-73d1-be48-dc244be5b5f0` | 1 | `notebooks/hypotheses/H01.qmd` `4618b80ed84518d94b8e8fe8b80db1fc43d272c2781c5294b3cc48b019348d43` | Exact reverse to `92d7795d5f64e451d3633e5987f6365ebf7ccb6b1bc24b469d064847b0c97e0a`; 38 R chunks parsed; diff check passed. |
| H02 | `019fb4d0-9d07-75a2-bb73-71cd6b2d0e44` | 1 | `notebooks/hypotheses/H02.qmd` `b50b55eebb75f120928707821dc3b8e8d6f16905418c56d8d689744926ff3de8` | Exact reverse to `4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d`; local overflow explicit; diff check passed. |
| H03 | `019fbe52-c067-7521-b2cf-62d9398d173b` | 1 | `notebooks/hypotheses/H03.qmd` `27c1fea54e5f32570613df80768d1fb5b668f3033aee90069820e951001c2513` | Initial turn did not execute the table order. A concrete follow-up was sent. Exact reverse to `45ea5a009efd3b451c392dfc23bef584c7b16e087bf4093780b051cfde42ae41`; R 4.6.1 parse and diff checks passed. |
| H04 | `019febf4-4868-72f3-bd97-31a85e86f8f0` | 1 | `notebooks/hypotheses/H04.qmd` `243896d4c22f68d23027f77f3721882e0a3d55274e67014e75d6ff55e2e243af` | The 12 px table pass first produced `cf1c65c7e6fd8db2c024ac4353849a0ae4eae2b2151f672d5076e183fec37016` with exact reverse to `f8adb6d78be041ce296dd7e89eb92769b128631c1b4227ce5d8ab3d526daf1d5`. The accepted revision 3 display successor uses `Other` at reader boundaries while preserving frozen internal keys and values. |
| H05 | `019fba35-6fd8-73c3-970f-e41f8b759bb6` | 1 | `notebooks/hypotheses/H05.qmd` `f748873f5f68198665fc3cb3d7047f586c619408f86e5e22bd9814593f9f2780` | All 19 tables resolve to 12 px; 39 R chunks parsed; exact reverse to `ad8f68bd58e015575b55284463f5535bf2a0b56219330d68e77795bd312bb37c`; diff check passed. |
| H06 main | `019fbd4a-288b-7a72-ac70-2d17ba6d2f04` | 1 | `notebooks/hypotheses/H06.qmd` `013496ae4ac5db1e069af98bea87af6c202714ed97d40cf1f7f64e6637239f5a` | Helper default and site-specific table base set to 12 px; exact reverse to `d65c197cb37db32101d8a43fcdc80198ab599a95cb73259abd187c9b2b58d350`; diff check passed. |
| H06 daily | `019fec6a-20d3-7710-ab9b-a035e0874182` | 1 | `notebooks/hypotheses/H06_daily.qmd` `ddf7e8af287831b80243b4d35e83546fa6ee8f7f3794c9874d4712648b3eb2e7` | Primary matrix base set to 12 px; exact reverse to `d90c4ced3f40456b3d9998022c9317a64ff6812597111d3d8c01b40cf8429139`; R 4.6.1 static parse and diff checks passed. |
| H07 | `019fbe52-6781-7c32-bdcf-379c88ef1e78` | 1 | `notebooks/hypotheses/H07.qmd` `c2d24ee7199fc8399e7edfa1192a21de7c31bd7854a89d356386c5e669ff55ca` | Helper default and sole 11 px diagnostic call set to 12 px; exact reverse to `d8dda5ff845749b762701729e79d72e94b5a8aee78488d1a3aca4a2056555064`; diff check passed. |
| H08 | `019fbdb6-b6a8-7e53-8e84-7a2967af9ea5` | 1 | `notebooks/hypotheses/H08.qmd` `56cdd3382ff933f20706d50e75af00160ebdc3c503307f9fdf02fb7c2ae6e859` | All native tables use 12 px and local overflow; exact reverse to `27654dcd9034eebe74223dacdc5631ad8c7350aae97acf0e2adb319bb7c943b1`; R 4.6.1 parse, scope, and diff checks passed. |
| H09 | `019fdc1b-b927-7fb1-ac61-88993c0a818a` | 1 | `notebooks/hypotheses/H09.qmd` `ae5b23d11e2c623b7150df7fe14292df4380e6417028630c30a30ae7dff1b34c` | All reader tables use 12 px and local overflow; secondary notes remain 9 px; R 4.6.1 with `gt` 1.3.0 confirmed the overflow contract. |
| H10 | `019fdc1b-b77b-7972-aed0-784da328e115` | 1 | `notebooks/hypotheses/H10.qmd` `0b2daad24e16ad62a87c2b74d5989cb2ff3738dca47d5dd3fda0af366e93c855` | All 12 native tables use 12 px and local overflow; exact reverse to `cfff1ac01ff4ab1666c99d4b413410a65ce7b88f0193d0adbbd79cf7f3f021c2`; 24 R chunks parsed. |
| H11 | `019fba59-0f3c-74a0-ab3d-58d389365ad1` | 1 | `notebooks/hypotheses/H11.qmd` `ea9ac2edb470f956cf854430b865e8adbf98b07d8e6ac307484c9e5ccc0c38de` | Initial message was queue-only. Executable order then applied the 12 px helper/calls and local overflow. Exact reverse to `7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867`; 26 R chunks parsed; diff check passed. |
| Brown Stage 3 | `019fffdf-66d4-7802-9091-09283ad27b7f` | 1 | Worktree `audit/analyses/brown_adherence/13_cross_state_association_results_amendment.qmd` `cca627a3f9a60f5c4b7d04112145c865c4035646b60668f9be765298682b12af` | All 16 reader-table call sites use the 12 px default; exact source comparison to `ea8f639a5b58ef591bf4716928ef32db4de68b30e157e2670867a5c0ee2d9c05`; R 4.6.1 extracted source parsed. |
| Brown Stage 4 | `019fffdf-66d4-7802-9091-09283ad27b7f` | 1 | Worktree `audit/analyses/brown_adherence/14_cross_state_association_preparation_and_provenance.qmd` `577121dbca925e26d47307cd66ff6b02a15e9295b0ad46064accfd8f6b69106d` | All 17 provenance-table call sites use a 12 px base; exact source comparison to `8fc81d9b28b60a3ab28315b6e83f884e55d2f8cbcb7cb374312414b1922c9c92`; R 4.6.1 extracted source parsed. |

Brown Stage 3 and Stage 4 remain in the owner’s separate Codex worktree at
`/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026`. Their accepted
HTMLs were deliberately not regenerated.

## Harmonizer-owned Table 3 mirror

The accepted Table 3 endpoint and preview are also source-converged:

- candidate HTML:
  `081d0278badfb1f40d29ffd4cb8ac18b5a285f049323f9c5c2142eede7f727e0`
- standalone preview HTML:
  `427a5826534ad3471000e920f361bf06b500b9bfc19234bda07aadda42550f07`
- both selection QMDs:
  `ee5f0844a404e95b858a7b175f8a1e1c72aca6b74891110e60c9c8b34f616d70`

The exact reader-facing MDER source note is:

> The MDER uses the mean of viable minute-level ratios in both the descriptive
> summary and geographic-association model cells.

The Table 3 wording forward contract and exact reverse proof passed under R
4.6.1. The detailed Table 3 geometry and wording record is
`audit/report_harmonization/table3_quarto_inclusion_geometry_correction_2026_09_01.md`.

## Render boundary

All source postimages are ready for the coordinator’s one serial render and
reseal pass. This ledger does not claim that the hypothesis HTMLs or Brown
HTMLs correspond to the new source identities. Their prior rendered artifacts
remain stale by design until that controlled pass.

## Selection-document integration repair

The source-only selection integration replay subsequently sealed 20 selected
`gt` fragments. Sixteen were already repaired and four required deterministic
ID and `headers` namespacing. The four repairs made 259 substitutions and each
reversed exactly to its preimage. The current 33-row selected-asset manifest,
all refreshed inventories, and the no-execute temporary render passed the
39-check combined-document gate. The detailed postimages and commands are in
`audit/report_harmonization/selection_integration_repair_and_release_2026_09_01.md`.
