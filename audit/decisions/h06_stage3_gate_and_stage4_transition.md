# H06 Stage 3 gate and Stage 4 transition

Decision ID: `H06-004`  
Date: 2026-08-11  
Status: approved

## Author decision

The author explicitly approved the standalone H06 reader-facing report and
requested only the final display-only table change that is now sealed. All
nine site labels/cells are bold and all nine site markers are filled with
their submitted-manuscript site colour solely for identification. Marker fill
does not encode significance. The reference-profile adjusted p-values remain
visible; all nine equal 0.738.

## Accepted identities

- reader source: `notebooks/hypotheses/H06.qmd`, SHA-256
  `c860c794ae36dcd7057ed358b4c6338112c12d5789a1e0f73b39a5acae008202`;
- reader CSS: `notebooks/hypotheses/H06.css`, SHA-256
  `20eb8615bf40acf6cb36a3ca43a360d9cc943fd2a79299520e9d864406a359af`;
- rendered HTML: `_build/nathealth/notebooks/hypotheses/H06.html`, SHA-256
  `f4f61f376780dfbfa1e42d6ebf1281115dd9d46cc48a34edc24df58fbc5979e9`;
- Stage 3 test: `tests/hypotheses/H06/test_h06_stage3.R`,
  SHA-256
  `a6e3e307b023588b475587876be86eeb9c0f7b9d9d1597df946dd112458940aa`;
- 301-entry Stage 3 manifest:
  `artifacts/12_manifests/H06/H06_stage3_artifacts.csv`, SHA-256
  `d77054228581a2700f80f0c571536ae2799a7e5ac0f6869d189767e0dfe3bb21`;
- worker handoff: `audit/handoffs/H06_worker_handoff.md`, SHA-256
  `bf61851538d8c54a05cc85a10faef6a5ef49b0af2a0c80cc2a72872fbec023bf`.

The worker reports that R 4.6.1 purl/parse, the narrow Nature Health render,
rendered-table XML assertions, all five focused H06 suites, and scoped diff
checks pass. The final table change did not alter any model, frame, estimate,
interval, diagnostic, sensitivity, figure, source dataset, or scientific
claim.

## Shared-input transition

The coordinator's later `CHG-101` provenance repin changes the shared
base-model manifest identity but not the accepted H06 hourly frames. The
independent H06 invariance check again compared all six accepted hourly frames
with tolerance zero and attributes included and returned `PASS`; its evidence
SHA-256 remains
`75794d5dc13392a05cd81ac57456bd03ccc5f12713f8f774db72f2bfab44de4f`.
H06 Stage 3 therefore remains scientifically accepted. Stage 4 must cite the
current base manifest
`b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09`
and describe the transition as provenance-only.

## Stage 4 authorization

Stage 4 is authorized at
`audit/hypotheses/H06/H06_analysis_preparation.qmd`. It must follow
`REPORT-007`: explain the result-producing data and code chain for an ordinary
scientific reader, use bounded file-identity checks and lightweight
descriptions only, and must not refit models, regenerate predictions, rerun
diagnostics, or recompute sensitivities. It must link reciprocally to the
accepted H06 result page and stop for author approval before final closure.

## Reopening condition

Reopen H06-G3 if an accepted Stage 3 identity changes; a focused verifier
fails; the report's model, estimate, interval, diagnostic, sensitivity, or
claim changes; the six hourly frames cease to be exactly invariant; or Stage
4 identifies a discrepancy rather than a provenance-only transition.
