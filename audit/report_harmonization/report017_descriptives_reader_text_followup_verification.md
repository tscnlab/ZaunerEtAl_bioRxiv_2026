# REPORT-017 Descriptives reader-text follow-up verification

Date: 2026-08-13  
Scope: reader-visible table text only  
Status: **source correction independently verified; render still blocked**

## Accepted change

The Descriptives owner changed only five reader-visible literals in
`scripts/descriptives/build_publication_tables.R`:

1. `Near-eye is the primary placement` became
   `Near eye is the primary placement`;
2. `near-eye only` became `near eye only`;
3. `Employment categories reproduce the submitted grouping:` became
   `Employment categories:`;
4. `Metric descriptive summary (near-eye)` became
   `Metric descriptive summary (near eye)`; and
5. `Near-eye participant and participant-day sample sizes` became
   `Near eye participant and participant-day sample sizes`.

The script identity changed from
`ca9295db766fb1726201392377eaa0136bd27fad7fa00dd3dd8dff44dfd825c3`
at 28,228 bytes to
`3b75ff59af4ddb0d8f74c905f60e06539c2a8490cf29f4fa44ac74c524895834`
at 28,195 bytes.

The normalization literals `Near-eye ` and `near-eye ` at source lines 54 to
55 and the internal `near-eye-metric-summary` identifier remain unchanged.
No variable, key, row, column, value, denominator, function call, or table
logic changed.

## Independent checks

- Reversing the five literal substitutions in the current byte stream
  reconstructs the accepted pre-edit SHA-256 exactly.
- Each new literal occurs once and each superseded reader literal occurs zero
  times.
- `submitted grouping` and `near-eye only` have zero remaining occurrences in
  the formatter.
- R 4.6.1 parses the script successfully with `--no-init-file`,
  `--no-site-file`, and `--no-environ`.
- `git diff --check` passes for the script.
- The harmonization-worker protected artifact subset remains 101 files and
  104,084,718 bytes, with the unchanged sorted SHA-256-list digest
  `853c3c08ee9eb3484d16a9c2bdf1da591a335083e8a5d5f0bbaca4a12a9e015e`.
- The accepted QMD, stale HTML, `renv.lock`, participant table CSV and PNG,
  metric table CSV, and recommendation table CSV retain the identities in the
  companion manifest.

The stored participant-table PNG was not regenerated and therefore remains a
pre-correction preview. The eventual accepted reader table must be verified
from the fresh native-`gt` HTML render. Principal-output visual approval remains
provisional.

## Render gate

No Quarto command or normal project-profile R command ran for this follow-up.
The serial queue remains held by
`report017_environment_startup_repair_request.md`. After that startup gate
passes, the fresh Descriptives render must satisfy
`tests/report_harmonization/test_descriptives_render.R`, including the native
metric and recommendation tables and the absence of the superseded reader
terms in rendered main content.

