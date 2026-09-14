# H01 METRIC-010 production-bootstrap authorization

Date: 2026-08-31  
Status: **AUTHOR APPROVED 1,000-REFIT MDER PRODUCTION BOOTSTRAP**

## Author instruction

After reviewing the completed METRIC-010 pilot gate, the author replied:

> **approve the 1,000-refit MDER production bootstrap**

This authorizes exactly 1,000 successful joint parametric bootstrap refits for
each of the eight already accepted MDER targets. The targets are the primary
and gap-timing-unaware datasets, near-eye and chest placements, and
all-available and paired/common samples.

## Accepted pilot evidence

- Pilot review:
  `audit/hypotheses/H01/mder_METRIC-010/bootstrap_pilot/H01_METRIC-010_bootstrap_pilot_review.md`,
  SHA-256 `a0bdccd82e51fc1d8dac7c4b651a33c0e493fb3c3959f6d839407e7d74ba93da`.
- Pilot manifest:
  `audit/hypotheses/H01/mder_METRIC-010/bootstrap_pilot/H01_METRIC-010_bootstrap_pilot_manifest.csv`,
  SHA-256 `deeb5dab9a5b63163f932dfdf4e23cc74ebc6848bd6d4ef8335d921ddd0c8764`.
- Pilot audit:
  `audit/hypotheses/H01/mder_METRIC-010/bootstrap_pilot/diagnostics/H01_METRIC-010_bootstrap_pilot_audit.csv`,
  SHA-256 `790c0c7ed6d285b3a4ef4be7d5610f3db02c03aab394051d86d1303758055a97`.
- Pilot provenance:
  `audit/hypotheses/H01/mder_METRIC-010/bootstrap_pilot/diagnostics/H01_METRIC-010_bootstrap_pilot_provenance.csv`,
  SHA-256 `e16914696a81278195ed01cca175df04884673c3c9e6ee7b5695aa4aa87211d9`.
- Focused verifier:
  `tests/hypotheses/H01/test_h01_mder_METRIC010_pilot.R`, SHA-256
  `ced93b500a1fedf0ab44d557be4447b4932c1c28ec83be2bc3c6f51cbd2827c0`,
  passed under R 4.6.1.

The pilot completed all eight targets with 50 used successful joint refits per
target, zero failures, zero warning refits, and an estimated production runtime
of 4.41 to 6.89 minutes with four refit workers.

## Boundary

This authorization does not permit any non-MDER refit. Completed target draws
must be checkpointed and preserved. If production verification fails, or if a
support, diagnostic, sensitivity, or claim disposition differs from the
accepted point gate, integration must stop for a new author decision.

No commit, push, upload, package change, shared-configuration change, central
ledger edit, or manuscript edit is authorized.
