# H05 METRIC-010 repaired-gap reseal closure

Decision ID: `H05-004`  
Date: 2026-08-11  
Status: verified

## Decision

Accept the bounded H05 integration of the repaired gap-timing-unaware MDER
artifact and retain the existing four-stage H05 closure. No new author gate is
required because the corrected comparator does not change any
multiplicity-retained result, accepted conclusion, or manuscript-facing claim.

## Scientific result

The repair replaces only the four gap-timing-unaware MDER frames and their
four-factor model bundles. The corrected fitted samples are:

- near eye: 687 participant-days from 137 participants at nine sites;
- chest: 723 participant-days from 152 participants at eight sites; and
- exact paired/common: 478 participant-days from 107 participants at eight
  sites at both placements.

All three declared 68-test families retain zero associations. The repaired
gap near-eye MDER estimates for factors F2--F5 are +0.00409, -0.00333,
-0.0105, and -0.0202, with BH-adjusted p-values 0.766, 0.788, 0.398, and
0.107. The existing H05 conclusion therefore remains unchanged.

## Preservation boundary

The H05 task refitted only 16 core gap MDER cells and ran 44 bounded gap MDER
day- or participant-deletion refits. It did not refit a primary model, a
non-MDER model, leave-one-site-out or random-site sensitivities, a bootstrap,
or a simulation. All 132 non-target frames, 200 non-target inferential
bundles, and primary MDER outputs remain frozen.

Replacing the four MDER p-values in the complete H05-F3 vector necessarily
changes 27 non-MDER adjusted p-values and 26 ranks. All 64 non-MDER raw tests,
model fits, estimates, intervals, diagnostics, and sensitivities remain
unchanged. These are family-wide multiplicity consequences, not new
non-MDER results.

## Verification

Fresh R 4.6.1 checks independently confirmed:

- all 16 gap-reseal reconciliation rows are `PASS`;
- all 44 repaired-gap influence refits complete;
- Stage 2, Stage 3, and Stage 4 focused tests pass;
- the Stage 2, Stage 3, and Stage 4 manifests contain 67, 165, and 129
  non-circular identities, respectively; and
- the Stage 4 website source copy is byte-identical to the authoring source.

Accepted identities:

| Artifact | SHA-256 |
|---|---|
| Gap reseal script | `9e360f56a87c58bccf66b9cdf16f527e6edf69f21113ac284ca2afb84826734c` |
| Gap reconciliation | `0211e9524837c860007f02824084bc6564972a952e09507cbfa5f0dcb01976ca` |
| Gap influence refits | `63b86698a31437e8f90bb2aec45dc949d40670eebf7966a6c65fa40a9e0cd9e5` |
| Stage 2 manifest | `b09869afe6431ea27c189151535a7d605b2cca944c69184cd3f970e76f156d1f` |
| Stage 2 handoff | `1cfd54a9580fdd93bd324e6e422a8af45b98d728fd9084679365441aadc38b6f` |
| Stage 3 source | `342c5cf2f00141de355ec1fad2b5a3443bc9af383afe6d909ed3daf8a7f69e0a` |
| Stage 3 HTML | `6941fb0874af3ab4febe64dec2e28978e3954c081f609a9318646bd75e62f367` |
| Stage 3 manifest | `1522951144720bc2fb2c13ceb18cc25c7ad3c7e43af5f735fb5684c16e68bead` |
| Stage 3 handoff | `dd79a4ec1959a4924d77d5ee59ebc0e86d202e920641fd16c5af5a383ae16021` |
| Stage 4 source and website copy | `ac8fb91708c6b6d9fbc4dfb9b49f1c966e8a5f03848390727eeda5e337d45e44` |
| Stage 4 HTML | `c95ce926f047e69e7a9887825188c05b359c92aec9a935f1fa4bcb2a16fc6912` |
| Stage 4 manifest | `50b9e4a3455e0640b414edc873c6a263893fa7a61a991155850a24784d50ec71` |
| Stage 4 handoff | `e64d547cfa3a71cbdc26863e03acaa53f7b1a14b9fdcb9020abb3c06f7eb22f2` |

## Reopening condition

Reopen if a sealed H05 identity changes, a focused verifier fails, the
repaired gap MDER sample or model changes, a non-MDER raw test or fit changes,
or any of the three complete 68-test families gains a retained association.
