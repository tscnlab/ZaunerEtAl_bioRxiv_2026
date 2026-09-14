# Preparation 07 provenance-only implementation approval package

Date: 2026-08-14  
Finding: `PREP07-PROV-001`  
Status: **scientific equivalence verified; bounded implementation author-approved**

## Decision requested

Approve or revise one bounded documentation repair for Preparation 07. The
repair would preserve the truthful historical producer identity of the frozen
example-day display while separately verifying that the accepted current
site/daylight-context file contains the same scientific values.

The package initially authorized neither implementation nor rerender. The
author approval recorded below releases only the bounded source/test
implementation. It does not release a rerender.

## Author approval

On 2026-08-14, the author approved the bounded implementation with the exact
response:

> Approve the PREP07-PROV-001 provenance-only implementation.

This approval releases a source-only owner order. It does not release a
Quarto render. Preparation 07 and all later renders remain held until the
source/test revision is independently accepted and a separate serial render
order is issued.

## Controlling audit verdict

The R 4.6.1 read-only audit is sealed in:

- `audit/reconciliation/preparation07/site_solar_context_equivalence_audit.md`,
  SHA-256
  `870cbb5d5f9414f61ee7db05b61a12eb51d56c9273e9ae7dfd05094984c47164`;
- `audit/reconciliation/preparation07/site_solar_context_equivalence_evidence.csv`,
  SHA-256
  `0757fc175c44fd33e9d8b06e4f9352699c18bfe50bbcf1c65d141f3f36a1cb97`;
- `audit/reconciliation/preparation07/site_solar_context_equivalence_manifest.csv`,
  SHA-256
  `01a07b87799faeb8291bb6187ced96ab7abdcf2399ee77c5dcfd19d608b1194c`.

The non-circular seal verifies both report and evidence identities and byte
counts. The finding is Low severity, Confirmed, and limited to provenance and
reporting.

The frozen showcase manifest correctly records historical producer input
SHA-256
`b0e8de539572ee595cc91027e7a2d919ba01237f780e50a76e5e4468d497c4bf`.
The accepted current RDS has SHA-256
`39ffe488de86f5d7cdc56d65c582c9de31f9054f8565936b4ec74e01491f26d0`.
The different compressed-file identities are expected because file-level
provenance attributes were repinned.

The audit verified:

- 17 independent showcase checks pass and only the strict
  `manifest::input_hashes` check fails;
- the historical and current context CSV are byte-identical at SHA-256
  `7dc64cc5026947ef96d6e4ab112bb767414420be97817f022082248db68d7028`;
- all 618 rows, 47 columns, and scientific cells in the historical and current
  RDS are exact after removing only frame-level provenance attributes;
- all four site/daylight fields are exact for all nine selected site-days;
- the fixed selection, 12,960 stored minutes, masks, figures, and artifact
  identities remain valid; and
- no estimate, sample, scientific output, display value, or claim changes.

## Proposed reader-facing repair

Retain the existing Preparation 07 structure, seven table endpoints, three
HTML figures, durable PNG and SVG, and fixed source-data CSV.

In the technical-provenance section, revise the existing input-identity table
and current-bundle checks so they distinguish:

1. the exact historical site/daylight-context file used to build the frozen
   display; and
2. the accepted current site/daylight-context file whose scientific values
   are independently verified as equivalent.

Proposed visible explanation:

> The stored example-day display was created from an earlier version of the
> site/daylight-context file. The accepted current file contains the same
> site/daylight values used here; only file-level provenance metadata changed.

The reader table may use a concise status such as **Equivalent values,
different file version**. Exact hashes remain available in the technical
provenance table. No internal finding, change, gate, or task ID should appear
in the ordinary reader explanation.

## Proposed source and test behavior

Only these owner-controlled files would change:

- `notebooks/preparation/07_example_days.qmd`, currently SHA-256
  `2293d2520dabaacc7394a39c00b5ac62911da1d34fb489ecf4bf232c55a2998f`;
- `tests/test_preparation07_report.R`, currently SHA-256
  `be2505e1960ffb6ebbe1bdbc675fdd2da37e036a1eeb797e5c709f32f191fd2f`.

The QMD would:

- pin and read the sealed audit report, evidence CSV, and non-circular seal;
- continue to require exact equality for the prepared-minute and site-metadata
  inputs;
- require the historical showcase pin to remain exactly `b0e8de53...`;
- require the accepted current RDS pin to remain exactly `39ffe488...`;
- require every applicable equivalence evidence row to have its sealed
  successful disposition;
- replace only the stale requirement that the historical and current RDS
  hashes be identical;
- update the existing `tbl-example-day-inputs` and
  `tbl-example-day-current-checks` displays rather than adding a new table
  endpoint; and
- retain all artifact, dimension, selection, seed, minute-grid, site-order,
  colour, figure, and no-hypothesis-handoff checks.

The focused test would add reconciliation-aware source and HTML assertions for
both hashes, all three sealed audit paths, the visible explanation, and the
successful report status. It must retain all existing no-builder, no-verifier,
no-writer, no-model, seven-native-table, three-figure, country-code,
source-data, terminology, and rendered-error checks.

The strict historical verifier
`scripts/pipeline/verify_prepared_day_showcase_artifacts.R` remains unchanged.
Its exact input-hash failure against a later provenance-only repin remains
truthful and must not be suppressed or reclassified inside that verifier.

## Explicitly protected files and outputs

Do not edit, rebuild, regenerate, or relabel:

- `artifacts/12_manifests/prepared_day_showcase_artifacts.csv`;
- `artifacts/06_model_data/context/site_solar_context.rds`;
- `artifacts/06_model_data/context/site_solar_context.csv`;
- `artifacts/08_diagnostics/prepared_day_showcase/selected_days.csv`;
- `artifacts/08_diagnostics/prepared_day_showcase/eligible_day_counts.csv`;
- `artifacts/08_diagnostics/prepared_day_showcase/selection_settings.csv`;
- `artifacts/11_source_data/prepared_day_showcase.csv`;
- `artifacts/10_figures/prepared_day_showcase.png`;
- `artifacts/10_figures/prepared_day_showcase.svg`;
- `scripts/pipeline/prepared_day_showcase.R`;
- `scripts/pipeline/verify_prepared_day_showcase_artifacts.R`;
- shared configuration, central ledgers, scientific outputs, and manuscript
  files.

## Verification and serial-render gate

After author approval, the current scientific owner would receive one
source-only order. It would require exact pre/post hashes, a zero-context diff,
R 4.6.1 parsing and focused tests, preservation of all scientific tokens and
executable behavior outside the approved assertion/display strings, and a
fresh protected inventory. No render would occur during that source-only
step.

Only after independent source/test acceptance would a separately released
single targeted render be allowed. It would resume the existing REPORT-017
Preparation 07 contract:

- one normal-profile Quarto target render only;
- seven native `gt` endpoints and three stored-data figures;
- unchanged durable PNG, SVG, source CSV, selection, and manifest;
- dynamic-link, navigation, country-code, semantic HTML, and no-error checks;
- secure loopback QA at 1,440 by 1,000 and 708 by 1,000;
- LR Mermaid labels measured against the 7 pt floor without pre-emptive edit;
- native HTML tables checked at ordinary desktop size, with contained usable
  horizontal scrolling accepted at 708 pixels; and
- complete server teardown and final protected-identity proof.

All hypothesis renders remain held until Preparation 07 is independently
accepted. DOC-001 remains open, and principal and supplemental output roles
remain provisional.

## Approval wording

To authorize the bounded implementation, reply:

> Approve the PREP07-PROV-001 provenance-only implementation.

Any revision to the visible explanation, table status, or verification scope
should be stated before approval.
