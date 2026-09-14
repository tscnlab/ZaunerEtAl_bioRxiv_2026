# Navigation production promotion release

Date: 2026-08-24

Status: **RELEASED FOR ONE EXISTING-CANDIDATE PROMOTION AND ONE NAVIGATION-SPECIFIC RESEAL**

The authoritative R 4.6.1 production-boundary run passed all eight gates before any production mutation. It verified 40/40 candidate promotion members, 11/11 candidate checks, 37/37 accepted HTML preimages, 1,180/1,180 accepted build members, the 24/24 H09 source/display seal, the exact authorized protected delta, zero symlinks, zero conflicting render/build processes, and zero navigation loopback listeners.

## Promotion-script disposition

The shared promotion script already contains the intended two-argument call `readr::write_csv(drift, file.path(...))`. The malformed three-argument form is absent. No corrective edit was necessary. The released script is pinned at:

- `scripts/report_harmonization/promote_navigation_candidate_once.R`
- SHA-256 `d96b8601b3b67fa4ed97c84ebc241e6ffbffd1a118839d2d0353bc5efa405d06`
- 8,567 bytes

The production-boundary checker verifies that identity explicitly before permitting a seal.

## Exact held concurrent state

The authorized H09 package remains exactly six added and two changed protected paths, with live H09 source SHA-256 `9db9671d61b39a81fa83b234e08832cef516ee91688ac8bc4150385629648df9`. Three exact non-corpus external transitions are frozen in `navigation_external_protected_checkpoint.csv`: the manuscript-selection builder, its paired verifier, and the navigation postflight checker. Any additional added, removed, or changed protected path stops the promotion or postflight.

The postflight deliberately retains `protected_inventory_pre.csv` as the historical baseline. It classifies only the exact eight-path H09 allowlist, the three-row external checkpoint, and the single navigation Phase 4 manifest transition. Replacing that baseline with the production inventory is neither required nor authorized.

## Authorized execution

The navigation owner may now:

1. execute `scripts/report_harmonization/promote_navigation_candidate_once.R` exactly once against the already accepted candidate root `/private/tmp/nathealth-navigation-integration-6e1e958a273`;
2. promote exactly 37 HTML shells and three navigation assets from `candidate_promotion_manifest.csv`, SHA-256 `7ad23be76994e4189c9c589fe0403231f087395eaf37e3815ad5686dd21adbf2`;
3. execute the existing navigation-only manifest resealer exactly once;
4. run the accepted postflight and bounded loopback browser QA; and
5. return one non-circular acceptance or one fail-closed stopped-state seal.

No Quarto render, QMD execution, scientific computation, model or artifact change, manuscript-content edit, selection-document rewrite, broad manifest builder, commit, push, upload, or publication is authorized. The H04, Brown, and H06_daily display requests remain queued and cannot mutate the navigation promotion window.

Any failed pre-promotion boundary, unexpected path, semantic defect, browser defect, or postflight mismatch stops without candidate regeneration or a second promotion attempt.
