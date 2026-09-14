# REPORT-017 H01 order 32g stopped-state independent acceptance

## Disposition

The order 32g stopped state is independently accepted. Candidate generation,
all six durable display-file replacements, the dedicated display test, and the
preservation checks completed successfully. The first failing focused test is
a provenance-classification mismatch, not a scientific, plotting, or rendered-
page defect. No Quarto render or semantic-hook execution occurred.

The historical display test is recoverable exactly. The two recorded order 32g
source edits were reversed deterministically under R 4.6.1, reproducing the
immutable core-manifest identity
`121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb`
and 6,747 bytes. This permits a strict historical mapping rather than a
whitelist or a weakened manifest gate.

## Accepted stopped-state authority

- Owner record:
  `audit/hypotheses/H01/report017_order32g_continuation/order32g_stopped_state.md`,
  SHA-256
  `6012e1c2d6c5b664bc17968172e196ff80f9567553d099690afcb4402414bb90`,
  4,310 bytes.
- Owner non-circular manifest:
  `audit/hypotheses/H01/report017_order32g_continuation/order32g_stopped_state_manifest.csv`,
  SHA-256
  `05b44c9e852334e191a766ef784767f3197c603a5713e30f55e852a0580b9443`,
  12,740 bytes. All 63 rows reproduce their hashes and byte counts.
- Core-manifest mismatch audit:
  `f007b7a3bfec93310d37b72e24bf12936047113af08a200938c561101645d124`.
- Current-manifest mismatch audit:
  `11852b1ac43eefd816f2551388dc7cc6e342ca71fb8a8321cd9de5a38b6e1165`.

All retained temporary evidence remains present with the accepted membership:
12 files in order 32e, 16 files in order 32f, 3 quarantine files, and 38 files
in order 32g.

## Exact historical recovery

- Recovery implementation:
  `scripts/report_harmonization/reconstruct_h01_order32g_historical_display_test.R`,
  SHA-256
  `f53ef754f3ccdf700ed6987d9947a669d45df08a841dc1107bc69a20dd1f0680`,
  4,581 bytes.
- Durable recovered test:
  `audit/report_harmonization/report017_h01_order32g_historical_test_recovery/H01_stage3_model_support_display_refresh_pre32g.R`,
  SHA-256
  `121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb`,
  6,747 bytes.
- Current transition-aware test:
  `tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R`,
  SHA-256
  `dcd3e62574a493d18733a9cb50eb6eb9d7493f8ac7bbb27918dc6535dcd1a603`,
  8,224 bytes.

The reconstruction checks the current identity, reverses only the two exact
recorded patches, and fails unless the historical hash and byte count are
reproduced. A temporary copy of the current display test was then changed only
to resolve the core-manifest test row through the durable recovered file. The
complete display-refresh test passed with its 136-cell, PNG/SVG, builder, and
current-display contracts intact.

## Full downstream audit before continuation

The current manifests have exactly the expected stopped-state differences:

- reporting manifest: zero mismatches;
- Stage 3 manifest: eight mismatches, comprising the six display files, the
  builder, and the current display test;
- worker manifest: eleven mismatches, comprising the same eight current paths,
  the current REPORT-016 test, and the two already classified historical HTML
  and profile rows.

Read-only temporary simulations were used to avoid another single-assertion
loop:

1. Updating the eight Stage 3 direct rows made the complete H01 reporting test
   pass.
2. Mapping the immutable core-manifest display-test row to the exact recovered
   file made the complete display-refresh test pass.
3. Expanding the REPORT-016 live transition classifier from the two Figure 1
   files to the exact six authorized Figure 1, Figure 5, and Figure 6 files,
   while retaining all historical rows, made the complete REPORT-016 test
   pass. The six live identities are independently pinned by the accepted
   order 32g stop manifest, and the check fails on a seventh mismatch.
4. The H01 preparation test passes in its explicit source-only mode. Once the
   Stage 3 manifest is resealed, its single direct row in the preparation
   manifest must be updated before the worker-manifest row for that preparation
   manifest is updated.
5. The dedicated order 32g display test passes under R 4.6.1 with all three
   geometries, all 30 paired labels, zero collisions, and the accepted minimum
   final typography.

No scientific value, source row, model, fit, estimate, interval, p-value,
diagnostic, QMD, HTML, profile, package, or lockfile was changed by this
independent audit.

## Required single continuation

The next owner order should remain consolidated:

1. Retain the immutable core manifest and every prior stop record unchanged.
2. Update only the current display test to route its one historical self-row
   to the exact recovered test file.
3. Update only the REPORT-016 transition classifier to recognize the exact six
   authorized historical-to-live figure transitions, pinning the live side to
   the accepted order 32g stopped-state manifest and failing on any seventh
   mismatch.
4. Reseal direct dependencies from leaves upward: current tests and display
   implementation, the eight existing Stage 3 rows plus bounded new order 32g
   evidence rows required by the manifest convention, the one Stage 3 row in
   the preparation manifest, and then the exact corresponding worker-manifest
   rows. Keep the reporting manifest unchanged and keep historical HTML/profile
   rows classified as historical rather than rewriting them.
5. Run the complete display-refresh, order 32g, REPORT-016, reporting, and
   preparation source-only tests, exact manifest audits, reverse proofs,
   protected identities, parse, Air, and scoped diff checks.
6. If all source and manifest checks pass, continue within the same order to
   exactly one H01 result render, semantic-hook verification, complete link and
   structure checks, and secure loopback QA. Stop once with a combined defect
   list if a genuinely new issue remains.

The H01 companion and every later REPORT-017 render remain held.
