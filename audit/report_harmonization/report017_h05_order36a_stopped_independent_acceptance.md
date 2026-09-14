# REPORT-017 H05 order-36a stopped-state independent acceptance

Date: 2026-08-20

Status: STOPPED STATE ACCEPTED. No H05 source or scientific defect was found.

## Independently verified completion boundary

The H05 owner preserved and verified the seven-file durable snapshot, changed
only the authorized assignment walker, parsed and reverse-verified that change,
and invoked the complete source-only verifier exactly once under R 4.6.1.

The repaired verifier is
`tests/hypotheses/H05/test_h05_report017_source_harmonization.R`, SHA-256
`a39c924b5ed35eb7ed20093574b766d23ab5e7abd001e32b6792f452bde080da`,
60,058 bytes. The result QMD remains `7c20e166...`, the companion QMD remains
`0a529644...`, and the handoff remains `71a8d466...`.

The verifier evaluated all 54 gates, passed 48, wrote its complete bounded
evidence, and exited 1. The generated 135-row order-36 source manifest is
unique, non-circular, and live-exact at SHA-256
`70ed24b61d942b4e5d8e97539fb40ce5cf93fcb21b3d06323cb53c435b619b60`.
The owner stopped correctly without another patch or retry. The handoff's
prospective PASS sentence remains provisional.

The order-36a stopped record is
`audit/hypotheses/H05/report017_order36a_assignment_walker/order36a_stopped_state.md`,
SHA-256 `36c4242f14c520db7c4a71e0f8dad07455fddaafbf995af5399e68c2f652ceb2`.
Its 34-row non-circular manifest is SHA-256
`ea41cbcdbd0f3ee6a57835898d25d3ec54694672a5bfb19f3e11ca51f50a4433`.

## Complete failure classification

Five failures compare correctly ordered endpoint vectors carrying names from
the named chunk list with unnamed expected vectors. The printed observed
values and order are exact:

- 30 result table endpoints;
- seven result figure endpoints;
- the first result figure and first two continued table parts;
- 22 companion table endpoints; and
- three companion figure endpoints.

R's `identical()` treats vector names as part of the object, so all five checks
fail despite exact endpoint content. Removing names from the two extracted
chunk-label vectors before endpoint subsetting is the smallest fail-closed
classification repair.

The sixth failure checks one required sentence against unnormalized source
prose. The sentence is present exactly, but the source wraps between
`confidence` and `intervals`. An independent R 4.6.1 replay confirms that the
literal does not match the raw line break and does match after the same
whitespace normalization already used by the immediately preceding scope
sentence.

All 48 other gates pass, including chunk parsing, formulas, inline R,
scientific numeric tokens, assignments, endpoint-label preservation,
scientific boundaries, vocabulary, links, country-coded sites, no scientific
or project write calls, existing tests and manifests, stale HTML context,
figures, source data, protected scientific inventory, exact diffs, reverse
proofs, handoff contract, and non-circular manifest path set.

These are six verifier classifications with two shared causes. They are not
reader-source, endpoint, model, sample, estimate, result, or scientific
discrepancies.

## One final continuation

Preserve the complete failed order-36 evidence before it is overwritten.
Then change only two verifier classifications in one pass:

1. remove names from `result_labels` and `companion_labels` immediately after
   `chunk_labels()` returns them, which fixes all five endpoint comparisons;
2. run the p-value suppression phrase against the same whitespace-normalized
   visible prose used by the scope phrase.

After exact diff, reverse, parse, and structural evidence, invoke the complete
verifier exactly once. On PASS, seal the source package and accept the existing
handoff. On any new failure, do not patch or retry. No QMD, handoff, existing
test or manifest, HTML, scientific artifact, shared file, render, commit, or
push may change.
