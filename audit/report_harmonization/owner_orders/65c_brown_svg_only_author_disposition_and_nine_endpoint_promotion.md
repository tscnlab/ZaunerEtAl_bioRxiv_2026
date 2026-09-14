# Owner order 65c: Brown SVG-only author disposition and nine-endpoint promotion

Date: 2026-09-02

Workflow: `REPORT-018`

Status: **FINAL NO-REFRESH PROMOTION ORDER**

Owner task: `019fffdf-66d4-7802-9091-09283ad27b7f`

## Author decision and controlling disposition

The author explicitly chose the validated participant-raincloud SVG. The
historical participant-raincloud PNG must remain unchanged. No decoded-pixel
waiver is granted.

Central coordination accepts the Order 65b stopped state as a safe,
unpromoted candidate package. The stopped package has 48 exact members with
unique paths and a non-circular manifest at SHA-256
`695fd5c42669cbb34e3be3fee797525a459459d2415c683d4d17816eb7d8f583`.
Twenty rows transparently share content with another candidate copy, as
required by the Order 65b generated-candidate and evidence-copy topology.

The corrected gate is 16 of 17. Every scientific, source, mapping, privacy,
candidate, SVG, dimensions/DPI, typography, visual, semantic, and environment
check passes. The sole failure is the decoded-pixel text-band comparison for
the participant-raincloud PNG. The author decision resolves this without a
waiver by excluding that candidate PNG from promotion and using only the
validated SVG for manuscript integration.

## Frozen evidence

Preserve every file and candidate in the Order 65, 65a, and 65b evidence
roots byte-for-byte. In particular:

| Order 65b evidence | SHA-256 |
|---|---|
| `stop_manifest.csv` | `695fd5c42669cbb34e3be3fee797525a459459d2415c683d4d17816eb7d8f583` |
| `stop_checks.csv` | `cf3fd975ee168603b96f6e33e069c8d1064ccf26c4d7eaab67434cb16517ad8f` |
| `candidate_gate_checks.csv` | `3a841b8d75bef207b12ca2ecc85103ef307e255842199b12a0ee71bb5c21b38e` |
| `candidate_cross_environment_comparison.csv` | `d45611eef2d95a17201ed7b94808dc1c3287c4741b6f3358f8294235351ff81d` |
| `canonical_endpoint_preservation.csv` | `4843878ecd377ba6acb16451477d6a3ee8a0f7f3c15249abf86049c13f29b196` |
| `source_preservation.csv` | `3db30ab34c5012d8b1cb219e24089a17aab463970dbcfdb199e9541e04510102` |
| `order65b_stop_summary.md` | `70c0ed9d393e514f3c014e4d1bbbc19f1848e0dc95386f0ebc3e3e6d511ec5f4` |
| `order65b_owner_handoff.md` | `db6ff147ec298be9379b0ff71e1d6252c8765221e7644978a3a2e7b85089329a` |

Use only the already sealed candidate files in:

`audit/analyses/brown_adherence/language_harmonization/window_label_repair_order65b/candidate_files/`

Do not regenerate, copy, rewrite, or reseal those candidates. Put every new
script, preimage, proof, and completion record in the fresh evidence root:

`audit/analyses/brown_adherence/language_harmonization/window_label_repair_order65c/`

## Required preflight

Before creating the Order 65c evidence root or changing any endpoint, run:

```sh
Rscript --vanilla \
  /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/scripts/report_harmonization/check_brown_order65c_svg_only_preflight.R \
  /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
  /Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026
```

Require `BROWN_ORDER65C_PREFLIGHT=PASS`. The preflight must reproduce all 48
stopped members, the exact 16-of-17 gate with only the raincloud-PNG pixel
failure, all ten sealed candidates, all ten unchanged canonical endpoints,
all six unchanged source postimages, and the author-selected nine-endpoint
promotion set. It must also prove that the historical canonical raincloud PNG
is still SHA-256
`f3a61b69e89b0933302694ccca4ea5ed5c4d1bb2e67d169f3e1542a644843228`.

Record a process check proving that no owner-started Quarto, Pandoc, knitr,
browser-server, Brown refresh, or competing Brown promotion process remains.
Do not interrupt another task's process. Stop if serial execution cannot be
established.

## Exact promotion set

Promote exactly these nine sealed candidates to their existing canonical
paths:

| Candidate file | Required postimage SHA-256 |
|---|---|
| `adherence_levels.png` | `8f2a6188347e6c9b54f40decd1f0af65991015bb50fb8c8c3cee7fbeb5bbf455` |
| `adherence_levels.svg` | `85ca30f887e9bc8f2d5c4d3bada3358b75ccb97b356c029636eab2ee85e5189a` |
| `main_coverage_sensitivity_guides.png` | `c82c85feaa5cb37e7768e5224f338831b8a58a3e532886cddebb30af73077f4a` |
| `main_coverage_sensitivity_guides.svg` | `d32d5a055604150132c500bb9209e1e490a5b7485a34e3a61f6e64fb2e2af8ba` |
| `main_site_free_work_forest_with_ba_m6.png` | `fbfb79f4edade635abcb08cdf37b677db3ca664d7909f96e47aa374a115435e3` |
| `main_site_free_work_forest_with_ba_m6.svg` | `4fd10a2906d3d5e819773c1c7b196c5ec3d505875de238247f15e4c5cae1ea9e` |
| `main_site_workday_adherence_forest.png` | `edee20e442b245ad66f7488a0ee6cb3b6813bff5184fd8f2dcba97f4f8401b8e` |
| `main_site_workday_adherence_forest.svg` | `49d6fb6fb9eac4470c12d5758b64d61d96ece9ae4ca5844fe4ec7e6859c3da05` |
| `participant_state_raincloud.svg` | `200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653` |

The canonical targets are the nine matching paths recorded in
`canonical_endpoint_preservation.csv`. Exclude
`participant_state_raincloud.png` from every promotion vector, loop, and
write operation.

## Historical PNG preservation

The canonical historical PNG must remain byte-identical at:

`audit/analyses/brown_adherence/stage3_cross_state_association/figures/participant_state_raincloud.png`

Required identity: 1,832,424 bytes, SHA-256
`f3a61b69e89b0933302694ccca4ea5ed5c4d1bb2e67d169f3e1542a644843228`.

The excluded candidate PNG at SHA-256
`119295eccb6f8b3354278223e37fb9f20db800509fdbd83a61399f092fa3cdd0`
remains frozen evidence only. Do not promote, delete, or alter it.

## Promotion implementation and proof

Create one new Order 65c R 4.6.1 promotion script. It must:

1. pin the full Order 65b stop manifest and all author-selected candidate and
   canonical preimage identities before any write;
2. define an exact nine-row candidate-to-target map that excludes the
   raincloud PNG;
3. capture recoverable copies of the nine canonical preimages in the new
   evidence root before promotion;
4. stage each candidate beside its target, verify the staged hash, and use one
   atomic rename per target;
5. recover the affected target from its captured preimage and stop if any
   staging or promotion check fails;
6. rehash all nine canonical postimages and require exact candidate identity;
7. rehash the historical canonical raincloud PNG and require its pinned
   identity;
8. prove that exactly nine and never ten endpoints were promoted; and
9. write a non-circular promotion manifest, preimage manifest, execution
   record, completion record, and owner handoff.

The new script must parse under R 4.6.1 and be an Air 0.4.1 no-op before it is
executed. Do not copy or execute the ten-endpoint Order 65b promotion script.

## Manuscript endpoint

After successful promotion, the accepted manuscript endpoint for the
participant raincloud is:

`audit/analyses/brown_adherence/stage3_cross_state_association/figures/participant_state_raincloud.svg`

It must reproduce SHA-256
`200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653`.

Send that exact path and identity to Writer task
`019ffb39-372e-7262-bfac-192751fd0e63` after promotion. The Writer may then
integrate the canonical SVG into manuscript-owned source.

Do not edit the Stage 3 QMD in this order. Its current PNG reference and the
accepted HTML remain unchanged. Any future Brown reader-page switch to SVG
requires a separate bounded source and render order.

## Prohibitions and stop rule

No refresh, source edit, Quarto, Pandoc, knitr, browser, HTML, Stage 4,
manuscript, model, prediction, inference, resampling, source-data, package,
lockfile, configuration, ledger, commit, push, upload, or broad-formatting
action is authorized.

Stop once on any preflight, process, script, preimage, staging, promotion,
postimage, preservation, or manifest mismatch. Do not patch and retry within
this order.
