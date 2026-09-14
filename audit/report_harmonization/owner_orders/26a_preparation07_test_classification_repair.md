# REPORT-014 order 26a: Preparation 07 test-classification repair

Date: 2026-08-14  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Scope: one focused-test-only repair  
Render status: **held**

## Authority

The coordinator independently classified four literals in the existing
Preparation 07 prose-only test loop as stale test classifications, not reader
source or scientific defects. The exact bounded repair requested by the
harmonization coordinator is approved.

The preceding source-only stop is sealed in:

- `audit/preparation_reports/report014_preparation07_provenance_failed_focused_test_verification.md`,
  SHA-256
  `9de292ad59a9b0b8b00f60810fe1d54993a903a3dfa585fb0ac37c91043d3808`;
- `audit/preparation_reports/report014_preparation07_provenance_failed_focused_test_manifest.csv`,
  SHA-256
  `80bb383ebd86fbc67753cf749da493ab2ac5166241b4a80ae1041e62820015a5`.

## Exact pins and editable scope

Stop if either current identity differs:

- `notebooks/preparation/07_example_days.qmd`:
  `ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae`;
- `tests/test_preparation07_report.R`:
  `707139e3c19e3ed10308a04876e6c2c2b08cf03a5f5c1faf16d4739d18220bcd`.

Edit only `tests/test_preparation07_report.R`. Owner-owned stop-completion
records may be added under `audit/preparation_reports/`, and the owner handoff
may be updated after completion.

Do not edit the QMD, stale HTML, configuration, data, artifacts, manifests,
audit report/evidence/seal, strict verifier, production code, ledgers,
lockfile, or another source/test.

## Exact test repair

In the existing prose-only token loop, remove only these four literals:

1. `None of the Preparation 07`
2. `does not rerun the fixed-seed selection`
3. `does not rerun`
4. `20260730`

Add explicit semantic assertions using `visible_flat` for all three accepted
reader statements:

- `none enters an H01–H11 model`
- `selection was not repeated`
- `does not repeat the selection`

Retain or add an explicit `full`-source assertion for fixed seed `20260730`.
Retain the existing optional rendered-HTML assertion for `20260730`.

Retain an explicit `full`-source assertion that the independent verifier is
not rerun during rendering. This may target the current exact full-source
phrasing, but it must not require that chunk-supplied reader text occur in the
prose-only `visible` object.

Retain every other test contract unchanged, including:

- all forbidden builder, production-verifier, writer, model, prediction,
  resampling, simulation, and scientific-regeneration patterns;
- the sealed provenance paths, identities, 17-row evidence contract, and
  two-entry seal;
- exactly seven native `gt` tables and three figures;
- country-coded site names, site order/colours, source-data, dynamic-link, and
  rendered-error assertions; and
- all other reader statements in the existing prose-only loop.

## Verification and return

Run only:

1. R 4.6.1 parsing of the focused test;
2. the source-only command `Rscript tests/test_preparation07_report.R` with no
   HTML argument;
3. an exact diff and reverse-substitution check for the focused test;
4. `git diff --check` for the focused test; and
5. the existing protected-identity check, including the QMD, stale HTML,
   configuration, strict verifier, historical manifest, sealed audit inputs,
   scientific/display artifacts, and `renv.lock`.

Return the exact test pre/post SHA-256 values, QMD identity, focused-test
output, zero-context diff, reverse-substitution evidence, protected identities,
and a durable non-circular completion record.

Do not execute a QMD chunk, run Quarto/knitr, run the strict verifier, open or
compare scientific RDS values, rebuild an artifact, or render. Preparation 07
and every later REPORT-017 target remain held pending independent acceptance.
