# REPORT-018 H01 METRIC-010 final independent acceptance

Date: 2026-08-31  
Status: **INDEPENDENTLY ACCEPTED**

## Disposition

The completed H01 METRIC-010 production, canonical integration, result report,
and preparation/provenance companion are independently accepted. The stable
H01 result source authorized for downstream manuscript-selection work is:

`notebooks/hypotheses/H01.qmd`

SHA-256:
`5e0bcf315ea113543dbcb762aaea19e4e2b0cd4bbe4f3520de04ebc19e041208`

The accepted current MDER estimand is the arithmetic mean of viable one-minute
melEDI-to-illuminance ratios. The archived Stage 2 comparison explicitly
classifies the submitted ratio-of-integrals result and the current MDER result
as related but different estimands, not as a like-for-like refit of an
unchanged outcome.

## Independent verification

Fresh R 4.6.1 checks reproduced:

- the 2,456-row H01 worker manifest with 2,456 unique paths, no self-row, and
  exact live SHA-256 and byte identities for every member;
- all eight MDER production targets with 1,000 retained successful joint
  bootstrap refits per target;
- the frozen non-MDER model and raw-test boundary;
- all four current 17-test multiplicity families;
- current model, confidence-interval, diagnostic, and canonical bootstrap
  contracts;
- the result report with its current reporting-input and HTML structure
  contract; and
- the preparation report with 23 figures, 20 native `gt` tables, and 75 exact
  manifest identities.

The following current tests each exited zero under the project R 4.6.1
library:

1. `test_h01_contract.R`
2. `test_h01_modeling.R`
3. `test_h01_response_gate_repairs.R`
4. `test_h01_response_family_candidates.R`
5. `test_h01_fit_outputs.R`
6. `test_h01_bootstrap_outputs.R`
7. `test_h01_mder_METRIC010_production.R`
8. `test_h01_reporting_inputs.R`
9. `test_h01_preparation_report.R`

The result and companion source, HTML, manifests, handoff, decision, and
verification tests are pinned in the accompanying non-circular acceptance
manifest. No model, data, report, figure, package, lockfile, or author source
was modified during this independent audit.

## Downstream authority

The manuscript-selection builder may now use the accepted H01 result QMD at
the exact SHA-256 above. Any later H01 source transition requires a new
explicit pin before regeneration. This acceptance does not authorize a new
H01 render or scientific recomputation.
