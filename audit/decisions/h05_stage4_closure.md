# H05 Stage 4 closure

Decision ID: `H05-003`

Date: 2026-08-01

Status: verified

## Decision

Accept the H05 scientific analysis-preparation and provenance companion and
close the four-stage H05 workflow. The authoritative reader-facing result is
`notebooks/hypotheses/H05.qmd`; its adjacent provenance companion is
`audit/hypotheses/H05/H05_analysis_preparation.qmd`.

Stage 3 was explicitly approved by the author under `H05-002`. Stage 4 is a
bounded documentation and provenance step rather than a new scientific gate.
Its completion therefore closes H05 without another model fit, prediction,
diagnostic calculation, leave-one-site-out run, bootstrap, or simulation.

## Verified disposition

- The primary near-eye analysis retains zero of 68 associations after one
  complete Benjamini--Hochberg correction.
- The complementary chest analysis and the gap-timing-unaware sensitivity
  likewise retain zero of 68 associations.
- The four sleep-environment cells at each all-available placement remain in
  the archived multiplicity families but are unfit for H05 inference; their
  estimates and p-values are suppressed from reader-facing result displays.
- Positive F2 estimates for time above 1,000 lx melEDI and corrected melEDI
  dose may be described only as non-multiplicity-retained estimates.

## Evidence and verification

- `audit/handoffs/H05_stage4_handoff.md`
- `audit/handoffs/H05_stage3_handoff.md`
- `artifacts/12_manifests/H05/H05_stage3_artifacts.csv`
- `artifacts/12_manifests/H05/H05_preparation_report_manifest.csv`
- `artifacts/12_manifests/H05/H05_figure_readability_qa.csv`
- `tests/hypotheses/H05/test_h05_stage2.R`
- `tests/hypotheses/H05/test_h05_stage3_reader_report.R`
- `tests/hypotheses/H05/test_h05_preparation_report.R`

The refreshed Stage 3 manifest seals 152 identities, the Stage 4 manifest seals 117
identities, all three focused tests pass under R 4.6.1, all ten reader-facing
figures pass final-size readability checks, reciprocal links resolve, and the
website source copy is byte-identical to the authoring source.

The scientific H05-owned closure is committed as
`b2f0415c54806d67e3466091ea67f33b9fed3232` (`Complete H05 light-behaviour
analysis`). The authorized display-only follow-up is committed as
`725331e2675bfcb936b0c1993727c55c3be5abe3` (`Apply H05 reporting display
rules`). The follow-up contains exactly ten H05-owned source, test, handoff,
and figure-QA files and excludes coordinator-owned ledgers, shared
configuration, and unrelated workspace changes.

`CHG-084` reconciles the central checksum snapshot to that follow-up without
reopening `H05-003`. Final non-circular identities are:

- reader-report source: `7923ec7a57b6c891dffb8d63eaeda3db86346c88c278c69a2b70ca97b7bf0cd7`;
- reader-report HTML: `d47b0e1fd61fcf42bb624c94b761e9af7d3243023bf2f84df4ac4dac5f210615`;
- figure-QA record: `a3d59c052a604f6d689c31b1d894af6b073fcae264ca75c45012961696dcf835`;
- figure-QA CSV: `70d8fc9600dc96342adfb8cb003bf30c30720b8c3d15ba7822735d5ba0c63095`;
- A4 inspection proof: `c155c5fcefb744dc51ffb1728c00fbaa61ff88dcfaf1ac3fcbbba438b4bbce71`;
- Stage 3 manifest: `f3ed8526b77c65b6738f413ecec7b3ab435bfb88117ddd963d6c040bbb6b0f9e`;
- Stage 3 handoff: `2bff53ebdc7141a70352ff34d189d35f290c35c74598a7e2c9a0002953818e25`;
- preparation-report manifest: `a7d3a70609abae04af1d00114fd913265319f5291ccbe3841b95328c002d1603`;
- Stage 4 handoff: `a6f16f88044224e9f448d3e9e63792f2a8bb09ca8d97f54686d7d9c0a92e622c`.

These identities were independently rechecked in the shared checkout after
the follow-up commit. The reconciliation changed no model, estimate,
diagnostic, sensitivity, or scientific conclusion.

## Reopen rule

Reopen H05 if a sealed scientific input or output changes, a focused verifier
fails, the accepted fixed-site or multiplicity specification changes, a
suppressed unfit model is promoted to inference, or manuscript prose exceeds
the verified observational and multiplicity-qualified scope.
