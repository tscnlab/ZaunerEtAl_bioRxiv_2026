# H04 manuscript Figure 3 revision-2 candidate completion

Date: 2026-08-31  
Status: **PASS, candidate only**  
Candidate root: `/private/tmp/h04_manuscript_figure3_revision2_candidate.rQOxku`

## Author-requested display revision

- Panel tags are uppercase `A` through `D` and remain at the left tag edge.
- Panel D begins at the shared plot-content edge and has no visible site-column heading.
- Every category header contains one compact support line in the form `P … · D … · H …`. The prior `R`, `WH`, and repeated `S` lines are absent.
- The 66-point header gives the two-line activity titles adequate vertical space.
- The table uses the accepted H03 conventions for borderless site markers, country-coded site labels, alternating row fills, light rules, inline site ratio and 95% confidence interval, and a second FDR p-value line.
- `Other/unspecified` is added as a quiet sixth column. Its accepted additive display-only estimate is shown in the site-average row. All nine site cells contain only italic `Not estimable` because this category was excluded from the activity-by-site interaction model.
- The five named-category interaction estimates, confidence intervals, complete 44-member FDR family, 17 FDR labels, site order, and San José (CR) by Outdoors non-estimable cell are unchanged.
- Reader language uses `activity-by-site interaction model`, `site-average estimate`, and `site-specific deviation ratio`. It does not use `heterogeneity model`.

## Frozen support and estimand contract

The five-category interaction frame remains 126 participants, 724 participant-days, 16,135 unique participant-hours, 16,875 generated long rows, 16,135 effective weighted hours, nine sites, and 4,746 exact-zero participant-hours. Each multi-select participant-hour contributes `1/k` across retained categories.

The separate accepted `Other/unspecified` display support is 72 participants, 159 participant-days, and 391 unique participant-hours. Its stored additive display-only mean is 221.8 lx with a 95% confidence interval of 97.2 to 506.4 lx. Its stored ratio to At home is 2.970 with a 95% confidence interval of 1.228 to 7.182. It has no accepted ratio p-value and supplies no site-specific interaction estimate.

## Verification

The initial verifier is preserved unchanged at SHA-256 `4dbeaf5867abd0dc7a80d5d066c39891135db693c8d4c68bc3d900fdb8786c55`. It passed 19 of 22 gates and recorded three verifier-only false negatives. The failed result and pixel evidence are preserved unchanged.

The centrally authorized continuation evaluated only those three gates:

1. six SVG numeric attributes agree with the accepted `Other/unspecified` source at tolerance `1e-12`, while the display-only role and absent p-value remain exact;
2. the six rendered header strings agree exactly with rowwise scalar-formatted `P`, `D`, and `H` expectations, with one support line per header and no `R`, `WH`, or `S`; and
3. numeric channel-reduced raster comparison finds exactly 5,650 changed temporal-panel pixels, all inside all six authorized old and new uppercase-tag boxes, with every box changed.

The continuation passed 3 of 3 gates. Combined completion is 22 of 22 PASS. Its three exact in-memory substitutions reverse byte-for-byte to the sealed failed-verifier source representation.

## Visual QA

The full-resolution composite and the 170 mm at 300 dpi preview were inspected. Both passed:

- no clipping, overlap, or panel-tag collision;
- shared left alignment of temporal plots, panel-D title, and panel-D table;
- readable one-row support headers and uncramped two-line category titles;
- legible site ratios, parenthetical 95% confidence intervals, and FDR p-values;
- a visually distinct site-average row and a quiet, non-colour `Other/unspecified` cue;
- explicit, legible `Not estimable` labels for all unsupported `Other/unspecified` site cells;
- stable site-marker colours, alternating row cues, and final-size table density; and
- no change to panels A through C outside the six authorized tag boxes.

## Principal identities

- Builder: `d8436d14198b8d6905ff35968bd6af260d1d4b20687c81811f9458dc089ac1dc`
- Initial verifier: `4dbeaf5867abd0dc7a80d5d066c39891135db693c8d4c68bc3d900fdb8786c55`
- Continuation verifier: `d187320702a2900b4c5a047bf82322f0c9e860357416b9a9a08c2ebbeafd4abb`
- Candidate PNG: `f7e85d44db0d80b9102ffaac0f9a3f4c1dfdbe3c39074fdfaff333dc3039f4ec`
- Candidate SVG: `9acc8907c5244a6d4557a260058060096c7de40f05f0aea235eb6d4b0dc4869b`
- Candidate 170 mm PNG: `4734d951fd3f2e96f82998a042e953ea967c3645aac8de75d6b86c5b9488c570`
- Panel-D PNG: `51a44e36f55ead27315975f01db86a46f249eac784e2a41aeadb28d126db2164`
- Candidate output manifest: `eaa9545ff52546f18908b0446f724fe93a659cdd764b71f0919d230f011f13a2`
- Completed 22-gate results: `10ec7674e11d0a119cdad1ae489edaac5369e75669dc58c32883b83ab6512d8d`
- Continuation manifest: `c4846db7f2da51fd03daa35b9802f1f799321470b426b8a05cc0b5ccabd702ec`
- Reverse proof: `9b608548eb087ad6acc81f9f36177e0d6a6ae2562c6b8d7da374585cb1779908`

## Boundary

This is an isolated candidate. No canonical figure, Quarto source, HTML, manuscript selection, model, scientific artifact, or shared configuration was changed. No render, commit, push, or upload was performed.
