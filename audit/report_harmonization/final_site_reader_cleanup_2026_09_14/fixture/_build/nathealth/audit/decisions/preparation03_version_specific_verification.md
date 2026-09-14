# Preparation 03 version-specific verification reporting

Decision ID: `PREP-002`  
Date: 2026-08-01  
Status: approved

## Evidence

The complete independent Preparation 03 reconstruction recorded in
`audit/findings/threshold_timing_zero_relevance_map.md` passed 394 of 394
checks against reference-profile manifest SHA-256
`c8e02302521360d3a5cb18f49e0a97aed4a1f0ea64343ead68bde274cddce10d`.

After the approved exact-all-zero melEDI day exclusion changed the
Preparation 02 inputs, Preparation 03 was rebuilt. The current
`artifacts/12_manifests/reference_profile_artifacts.csv` has SHA-256
`5e08099602682a4b951b0304764f341932ef2f03ccd4c62f32793ea82084e062`.
The project contains current file-identity and stored-support checks, but no
stored independent-reconstruction record that ties the 394 checks to this
later manifest.

## Decision

The Preparation 03 reader-facing rewrite may continue without rerunning any
scientific computation. It must:

1. identify the current manifest and the checks that are demonstrably current;
2. state explicitly that the 394-of-394 independent reconstruction applied to
   the preceding manifest, if that result is useful context;
3. not describe the current reference-profile artifacts as having passed that
   complete reconstruction; and
4. retain current-manifest independent verification as an open audit item.

This provenance gap is not evidence that a current artifact or downstream
result is incorrect. Equally, file fingerprints, successful downstream reads,
and stored support summaries cannot be substituted for an independent
reconstruction of the scientific values.

The documentation worker must not run
`verify_reference_profile_artifacts()`, rebuild profiles, or alter any
preparation artifact under this authorization. A current-manifest independent
verification can be scheduled separately as scientific audit work and, if it
passes, the report may then be updated to state that result.

## Reopening condition

Reopen if the current reference-profile manifest changes, a current-manifest
independent verifier record is found or produced, or any verification reports
a discrepancy in profile values, support, linkage, or artifact identity.
