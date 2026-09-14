# REPORT-014 order 26b: Preparation 07 visible-flat test repair

Date: 2026-08-14  
Owner task: `019fbd2a-3d80-7ed0-b93e-96457a9e7f26`  
Scope: two focused-test search-target substitutions  
Render status: **held**

## Authority

The author approved this exact bounded test-only repair with the response:

> Approve the Preparation 07 test-only visible_flat repair.

The preceding stop is sealed in:

- `audit/preparation_reports/report014_preparation07_test_classification_failed_focused_test_verification.md`,
  SHA-256
  `8c784d8e424304b980e73a64088a96b49e0e61e6a20a69b573f00f73e3c34369`;
- `audit/preparation_reports/report014_preparation07_test_classification_failed_focused_test_manifest.csv`,
  SHA-256
  `9e26c5e2022cfd71e7be5f4e3f59745e45db8e65fe53f33de8d42c7bdc72f3b2`.

## Exact pins and editable scope

Stop if either current identity differs:

- `notebooks/preparation/07_example_days.qmd`:
  `ded8765f342c5e80ac9f0633b2c4c761dc1860e49af1bb125e0b260ae2b460ae`;
- `tests/test_preparation07_report.R`:
  `a22182cb9b15e96d5c9e8dd66e98c486345d996c947ca757044f0bdbe0a96457`.

Edit only `tests/test_preparation07_report.R`. Owner-owned completion evidence
may be added under `audit/preparation_reports/`, and the owner handoff may be
updated after completion.

Do not edit the QMD, stale HTML, configuration, data, artifacts, manifests,
audit report/evidence/seal, strict verifier, production code, ledgers,
lockfile, or another source/test.

## Exact two-line repair

In the existing combined figure/source-data assertion, preserve both required
fixed strings exactly:

- `figure source-data CSV`
- `split into three three-panel figures`

Change only their search target from unflattened `visible` to the existing
whitespace-normalized `visible_flat` object. Do not change the error message,
either required phrase, or another assertion.

The accepted QMD already contains both reader statements. The second phrase
is split only by a source newline between `three-panel` and `figures`. A
read-only R 4.6.1 in-memory simulation of exactly these two substitutions
passes the complete source-only focused test with no later failure.

## Verification and return

Run only:

1. R 4.6.1 parsing of the focused test;
2. `Rscript tests/test_preparation07_report.R` with no HTML argument;
3. an exact zero-context diff and reverse-substitution check for the focused
   test;
4. `git diff --check` for the focused test; and
5. the protected-identity check covering the QMD, stale HTML, configuration,
   strict verifier, historical manifest, sealed audit inputs, scientific and
   display artifacts, previous stop records, and `renv.lock`.

Return the exact test pre/post SHA-256 values, unchanged QMD identity, focused
test output, exact two-line diff, reverse-substitution evidence, protected
identities, and a durable non-circular completion record.

Do not execute a QMD chunk, run Quarto/knitr, run the strict verifier, open or
compare scientific RDS values, rebuild an artifact, or render. Preparation 07
and every later REPORT-017 target remain held pending independent source/test
acceptance and a separate render release.
