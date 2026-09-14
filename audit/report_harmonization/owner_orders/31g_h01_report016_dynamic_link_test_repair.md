# REPORT-017 order 31g: H01 REPORT-016 dynamic-link test repair

Date: 2026-08-14

Owner task: `019fb4ce-d84c-73d1-be48-dc244be5b5f0`

Status: **Released for one bounded test-only repair after the complete order
31f stopped state. No QMD, image, builder, manifest content beyond directly
dependent order-31f evidence, HTML, profile, or Quarto render is authorized.**

## Authority and exact preflight

The coordinator independently confirmed that the current H01 source contains
40 exact dynamic links to 36 unique registration anchors, while the unchanged
REPORT-016 test still forbids every `preregistration_deviations.qmd` link. The
complete order 31f stopped state was independently accepted before this order
was issued.

Stop on any preflight drift from these identities:

- H01 QMD:
  `notebooks/hypotheses/H01.qmd`, SHA-256
  `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6`;
- REPORT-016 test:
  `tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`,
  SHA-256
  `55c89eb03f9510ea3bce937a26da04d552d9eb4d6c2f87aec34884af69715765`;
- central deviation page:
  `notebooks/preregistration_deviations.qmd`, SHA-256
  `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d`;
- builder:
  `scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R`, SHA-256
  `35443e52e2b554afb5cc2a6a8a88ba1a2b847fdac5f8ae5974005a336debbdc7`;
- refreshed PNG:
  `2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b`;
- refreshed SVG:
  `602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966`;
- focused display test:
  `121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb`;
- stopped H01 HTML:
  `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa`;
- Stage 3 manifest:
  `08da3090e895f8d99f3a4a32eddb2a3c9d8582076ed2fe69d1b5795a8415a54f`;
- worker manifest:
  `51288b656723bc7d29027b3bd5877fa7f18837135d6f7fe1d6c0b96bbe312006`;
- reporting manifest:
  `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`;
- order 31f controlled-stop narrative:
  `833c331a715f77894d606a8f5fc1564465aee15cf18f628211bf0f527d3e577c`;
- order 31f owner manifest:
  `6b5eb3c49cf2bb647a60b325bd3aab733896f237d0347cca435de60fc1c7ec16`;
  and
- order 31f protected reconciliation:
  `922d2a69502f72057d0ebed0e40cbc0c7f5568726a10f7af6387ccb9f7f74442`.

## Sole test edit

Edit only
`tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R`.
Replace only the stale negative assertion that forbids
`preregistration_deviations.qmd` with a fail-closed positive source-link
contract. The replacement must require all of the following:

1. Every matched target has the exact relative prefix
   `../preregistration_deviations.qmd#` followed by its anchor. Do not accept
   an HTML target, an absolute path, a build path, or another relative route.
2. The H01 QMD contains exactly 40 such link-target occurrences.
3. Those occurrences contain exactly 36 unique anchors.
4. Every anchor is already in lower-case form.
5. Every unique anchor is declared exactly once in
   `notebooks/preregistration_deviations.qmd`.

Implement the smallest clear R assertion inside the existing test. Do not
change another existing assertion, message, data check, mapping check,
historical REPORT-016 check, transition classification, scientific-artifact
protection, or manifest gate.

Require an exact one-hunk test diff and an in-memory reverse reconstruction
that reproduces the pre-edit test identity. Parse the revised test under R
4.6.1 before execution.

## Directly dependent evidence only

Reseal only current order 31f worker or display-refresh evidence that directly
pins the changed REPORT-016 test. Preserve every unrelated row and all
historical records. Do not edit the current Stage 3, worker, or reporting
manifests unless the focused test proves that one of those exact current
manifests directly pins the revised test and the coordinator's bounded
transition contract requires the pin. If a broader manifest change appears
necessary, stop and return it rather than expanding scope.

Any resealed order 31f evidence must retain the accepted artifact outcome:
136 cells, the exact title-only builder change, 5,697 PNG pixels in the
authorized region, one SVG title line, 1,663 protected paths, exactly three
authorized display changes, ten historical REPORT-016 paths unchanged, and
the stopped H01 HTML unchanged.

## Required R 4.6.1 checks

Run only:

- parsing of the revised REPORT-016 test;
- the complete focused REPORT-016 test;
- the order 31f focused display test only if it directly pins the revised
  test or resealed evidence;
- an independent 40-occurrence, 36-anchor link contract;
- exact test reverse and scoped diff checks;
- exact directly dependent evidence-manifest checks; and
- the existing protected-identity comparison.

The complete REPORT-016 test must preserve all corrected deviation rows,
central-ID mappings, historical evidence, and scientific-artifact gates. Use
R 4.6.1 and the synchronized project library. Record the exact commands,
runtime, exit status, changed-file list, pre/post identities and byte counts,
and non-circular evidence manifest.

## Prohibited actions and return gate

Do not edit any QMD, PNG, SVG, builder, source CSV, model, estimate, interval,
p-value, FDR decision, diagnostic, scientific artifact, durable HTML, profile,
semantic hook, package, lockfile, central ledger, manuscript file, or another
test. Do not render Quarto, fit or refit, predict, simulate, bootstrap,
resample, commit, push, or release another REPORT-017 target.

Stop for independent harmonizer acceptance. Return the revised test identity,
the exact reverse proof, all directly resealed evidence identities, the R
4.6.1 outputs, and proof that the complete order 31f scientific and display
outcome remains unchanged.
