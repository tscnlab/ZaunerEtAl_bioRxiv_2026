# REPORT-017 H01 order 31f stopped-state independent acceptance

Date: 2026-08-14

Status: **Accepted as a complete controlled stop. The display artifact repair
passed, but the current manifests remain deliberately unreconciled and no
Quarto rerender is released.**

## Accepted stopped state

Independent hash checks reproduced the owner return:

- builder:
  `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R`, SHA-256
  `35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7`;
- principal PNG:
  `artifacts/10_figures/H01/stage3/H01_stage3_model_support.png`, SHA-256
  `2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b`;
- principal SVG:
  `artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg`, SHA-256
  `602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966`;
- dedicated refresh script, SHA-256
  `f87486c0975dc560887c92e98f9423baaa56a926a3d6533e6197b625e23c4353`;
- focused display test, SHA-256
  `121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb`;
- controlled-stop CSV, SHA-256
  `600db525f30427d4157cee2151eb7b74594c5d9e0541f2233c0ab87f1ecef1c3`;
- controlled-stop narrative, SHA-256
  `833c331a715f77894d606a8f5fc1564465aee15cf18f628211bf0f527d3e577c`;
- 50-row non-circular owner manifest, SHA-256
  `6b5eb3c49cf2bb647a60b325bd3aab733896f237d0347cca435de60fc1c7ec16`;
- 1,663-row protected reconciliation, SHA-256
  `922d2a69502f72057d0ebed0e40cbc0c7f5568726a10f7af6387ccb9f7f74442`;
  and
- unchanged stopped H01 HTML, SHA-256
  `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa`.

The accepted H01 reader QMD remains SHA-256
`31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`.
The unchanged REPORT-016 test remains SHA-256
`55c89eb03f9510ea3bce937a26da04d552d9eb4d6c2f87aec34884af69715765`.
The current Stage 3, worker, and reporting manifests remain at the intentional
pre-refresh identities `08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f`,
`51288b656723bc7d29027b3bd5877fa7f18837135d6f7fe1d6c0b96bbe312006`,
and `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`.

## Independent verification

The normal project profile used R 4.6.1. The first restricted execution was
stopped during the already documented renv transient-lock retry. The accepted
narrow access to the existing user-owned renv cache was then used. The focused
display test passed and independently confirmed:

- 136 frozen plotted cells and unchanged support states;
- exact reverse substitution of `FDR-adjusted result` to the pre-repair
  builder identity;
- a 3,360 by 2,368 PNG at 320 dpi;
- exactly 5,697 changed pixels, confined to the accepted legend-title region;
  and
- one changed SVG title line with every other SVG line unchanged.

A separate R 4.6.1 structural replay verified all 50 owner-manifest paths and
byte counts, all 1,663 protected paths, exactly the builder, PNG, and SVG as
changed, ten historical REPORT-016 paths unchanged, and the current dynamic
registration-link state of 40 occurrences and 36 unique lower-case anchors.
Every one of those 36 anchors is declared exactly once in
`notebooks/preregistration_deviations.qmd`.

## Controlled follow-up

The sole remaining blocker is the stale negative source assertion at line 198
of `tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`.
It contradicts the accepted dynamic registration links and is a test
classification defect, not a report or scientific defect. The coordinator has
authorized a separate test-only follow-up after this stopped-state acceptance.
No manifest reseal, durable HTML update, Quarto render, profile edit, or later
REPORT-017 release is authorized by this record.
