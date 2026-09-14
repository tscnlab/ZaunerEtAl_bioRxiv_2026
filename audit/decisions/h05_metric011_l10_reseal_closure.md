# H05 METRIC-011 primary-L10 reseal closure

Decision ID: `H05-005`  
Date: 2026-08-12  
Status: verified

## Decision

Accept the bounded H05 integration of the source-verified numerical-zero
normalization for primary L10 mean melEDI and retain the existing four-stage
H05 closure. No new author gate is required because the correction changes no
sample, multiplicity rank, retained association, accepted conclusion, or
reader-facing claim.

This decision supplements `H05-003` and `H05-004`; it does not reopen their
accepted scientific or reporting contracts.

## Scientific result

`METRIC-011` normalizes three primary near-eye and five primary chest
participant-day L10 values from `4.163336342344337e-17` lx to exact zero after
the shared source-window verification established that they are floating-point
remnants of all-zero source windows. The affected all-available and
paired/common frames contain the same participants, participant-days, sites,
and non-value fields as before.

The bounded reseal updates 16 factor-model cells derived from four primary L10
frames. Seven inferential raw p-values and two BH-adjusted p-values change at
full precision, but no family rank changes and the adjusted changes are below
three-decimal display precision. Each of the three complete 68-test H05
families continues to retain zero associations.

## Preservation boundary

The H05 task refreshed only the four primary L10 frames and their dependent
factor-model cells, eight inferential bundles, eight random-site sensitivities,
and 36 primary L10 leave-one-site-out refits. It did not refit a gap-timing-
unaware L10 model, a non-L10 model, any accepted `METRIC-010` MDER result, a
bootstrap, or a simulation.

All 22 preservation checks pass. Raw p-value changes occur only in the
explicitly permitted primary L10 rows; all non-L10 raw tests and all gap L10
fits remain frozen. The two dependent BH adjustments change without changing
rank or retention status.

## Independent verification

Fresh R 4.6.1 verification independently confirmed:

- all 29 rows of the H05 `METRIC-011` artifact-update manifest are `PASS` and
  match the current file SHA-256 identities;
- all 22 reconciliation rows preserve their frozen digests;
- the four frame-audit rows contain exactly three near-eye and five chest
  numerical-zero corrections in each applicable sample scenario, with all
  non-value fields identical;
- the BH audit contains seven raw-p changes, two adjusted-p changes, and zero
  rank changes, with raw changes confined to permitted L10 rows;
- the Stage 2, Stage 3, and Stage 4 focused tests pass; and
- the Stage 2, Stage 3, and Stage 4 manifests contain 77, 177, and 141
  verified non-circular identities, respectively, including a byte-identical
  Stage 4 website source copy.

Accepted identities:

| Artifact | SHA-256 |
|---|---|
| Stage 2 manifest | `09363abf0557646870d0752f08b00f42013deec471a1ea97067c2333a1a811cc` |
| Stage 2 handoff | `db5f7e47cf75bd53dc0f5489303baca46b0b3b253a8f4802e67a5629711edfb2` |
| Stage 3 source | `3aab2f527d1024a05422bba061e9f8f27a5c9a2a316e439b7c6f535627ca476c` |
| Stage 3 HTML | `58be9b4da8bb67a4322af7096472de1bf97c47d17c79f39078692577a2788b96` |
| Stage 3 manifest | `9dabc70a0ab6554a0b4d9dbc175cd4009b1f57a57c975cb4677b45ead2620100` |
| Stage 3 handoff | `883d6303f01ea29e0e5ac8945befb650468f6681873bbb13fc3b7ed4abcc7849` |
| Stage 4 source and website copy | `f8087740def5e4e75e5bf5eff82d9f58acf1865954a16919719a7280f3447bfc` |
| Stage 4 HTML | `c44f4f77f4e2295f6b265ed9505c3c560361a7280562dd9ce1afce73149d5866` |
| Stage 4 manifest | `bd4ae8ac8516e961d1c4a37b1c18d3262376cd27ba0ed9611b7b60d167059c36` |
| Stage 4 handoff | `896205d9b7f0403e7cb70023ebb392526e58a30825c4d2b151488098602018b4` |
| METRIC-011 artifact-update manifest | `37974044361e8301c2750361c7080b8b12630c4ceb6a0208518b100e99aa690f` |
| METRIC-011 reconciliation | `fc55f42f90b5b1269b88ee7fbfdd5409afa6f13876c3c2e271e757edc42536f9` |

## Result effect

The H05 result remains zero of 68 BH-retained associations in the primary
near-eye family, the complementary chest family, and the gap-timing-unaware
family. Existing model qualifications, figures, tables, prose, and claim
dispositions remain controlling after their bounded provenance refresh.

## Reopening condition

Reopen if a sealed H05 identity changes, a focused verifier fails, a corrected
L10 frame changes beyond the eight source-verified numerical zeros, a protected
non-L10 or gap L10 raw result changes, a family rank or retention decision
changes, or a reader-facing claim exceeds the verified scope.
