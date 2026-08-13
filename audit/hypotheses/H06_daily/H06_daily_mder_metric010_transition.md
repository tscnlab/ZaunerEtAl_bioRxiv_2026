# H06_daily METRIC-010 transition

- Date: 2026-08-11
- Scope: MDER only
- Upstream hold: **released under the corrected primary and gap METRIC-010
  artifacts**
- Primary gate: **H06-D-G2-MDER — author approved on 2026-08-11**
- Corrected gap gate: **H06-D-G2-MDER-GAP — author approved on 2026-08-11**
- Work boundary: **corrected MDER branch closed and frozen; no additional MDER
  fitting authorized**

## Earlier primary approval remains in force

The author approved H06-D-G2-MDER after reviewing the replacement primary
mean-of-viable-ratios result. That approval retains:

1. Gaussian identity as the selected model with mandatory Student-t
   sensitivity and an explicit heavy-tail limitation;
2. the influence-limited primary claim dispositions;
3. singularly flagged daily AR(1) fits as temporal-stability sensitivities
   only;
4. raw-slot-only reporting with no Benjamini--Hochberg decision until all 15
   metric slots are available; and
5. the primary metric definition and support rule.

The then-disclosed one-zero gap qualification was not a scientific acceptance
of that value. It is now superseded by the coordinator's corrected shared gap
rebuild; no estimate or conclusion from that old comparator is retained.

## Current controlling replacement

Daily MDER is the arithmetic mean of one-minute melEDI/illuminance ratios for
minutes where both channels are finite and strictly positive. Preparation uses
a complete 1,440-minute local wall-clock grid, averages fall-back duplicate
minutes channel-wise before forming the ratio, leaves spring-forward absent
minutes missing, and retains MDER with at least 720 viable ratios. There is no
time-profile weighting, gating, scaling, or ratio of daily integrals.

The current task-local contract pins:

- controlling decision SHA-256
  `1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de`;
- metric manifest
  `7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43`;
- independent MDER audit manifest
  `5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb`;
- base-model manifest
  `b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09`;
- base input bundle
  `168f25e18b6e494aa7a0272923041ad8249e25adb9ff3742d22e2f4cacf1bdf8`;
- gap-preparation manifest
  `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935`;
- independent H01 gap manifest
  `79ee4818d7f3967827a6412f8537196e84ee7a6ccc1b8d2c5e9dd3124ed44b47`;
  and
- independent repair-evidence manifest
  `81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018`.

All 16 direct task inputs pass their pinned identities.

## Bounded corrected-gap execution

H06_daily did not rebuild or alter shared preparation. The static audit
reconciled the repaired gap participant-day values against the exact
minute-support object, including viable-minute counts and failure reasons.
Availability is 687 of 811 near-eye days from 137 participants and 723 of 897
chest days from 152 participants. All retained values are finite and strictly
positive; the previous THUAS chest zero is now missing under the no-viable-ratio
rule.

Exactly 24 repair-dependent frames were refreshed:

- 18 gap frames across placements, sample roles, and predictors; and
- six primary--gap common-sample frames whose membership necessarily changes
  with gap MDER availability.

The 12 primary all-available or placement-paired frames are object-identical to
their pre-refresh copies. Primary estimates, tests, model diagnostics, AR
counterparts, site heterogeneity rows, participant/site deletion results,
claim verdicts, and unaffected model serializations passed 12 frozen-content
preservation checks. No primary all-available, placement-paired, or deletion
model was refitted; the six primary--gap common-sample fits were necessarily
updated.

## Corrected gap result

The selected repaired near-eye Gaussian estimates are:

| Contrast | Estimate (95% CI) | Exact sample |
|---|---:|---:|
| Free day minus Work day | -0.0016 (-0.0140 to 0.0108) | 664 days / 136 participants / 9 sites |
| Active minus Sedentary | 0.0090 (-0.0066 to 0.0246) | 630 / 133 / 9 |
| +1 h previous-night sleep | 0.0018 (-0.0028 to 0.0065) | 664 / 136 / 9 |

All three selected intervals include zero. Student-t shifts are 0.111, 0.543,
and 0.651 Gaussian standard errors. The Student-t sleep interval is 0.000003
to 0.006710, only just above zero, while the selected Gaussian interval
includes zero; this is retained as an explicit tail-model sensitivity.

Raw common-association p-values are 0.804, 0.245, and 0.470. Raw site-
heterogeneity p-values are 0.005, 0.046, and 0.808. Each affected family still
contains only the MDER slot of 15 required metric slots, so every adjusted
p-value and adjusted decision remains missing. The nominal heterogeneity
signals are not promoted to findings.

All repaired gap selected and Student-t fits pass the numerical, spread,
extreme-residual, bound, and sensitivity rules, with the explicit Gaussian
heavy-tail limitation. The actual-date AR(1) counterparts shift estimates by
0.019--0.061 Gaussian standard errors and retain the structured-covariance
singularity flag; they remain stability sensitivities only. The exact gap
sleep random-site/random-slope benchmark is singular at a random-site
correlation of 1.000 and is non-estimable without post hoc simplification.

The targeted refresh completed in 11.7 seconds with no bootstrap, simulation,
or resampling. The pre-refresh production output manifest was reconstructed
byte-for-byte and is retained with dedicated refresh provenance manifests.

## H06-D-G2-MDER-GAP author-approved closure

After reviewing the report
`audit/hypotheses/H06_daily/05_mder_metric010_amendment.qmd` and its rendered
HTML, the author approved on 2026-08-11:

1. corrected gap availability and fitted samples;
2. the selected estimates and heavy-tail limitation;
3. the near-zero Student-t sleep lower bound as sensitivity, not a finding;
4. raw heterogeneity slots without BH decisions;
5. singular AR and registered-benchmark dispositions; and
6. the verified frozen-primary preservation boundary.

This approval closes and freezes the corrected MDER-specific branch. It does
not authorize another model fit, the remaining daily-metric production grid,
Stage 3/4, site integration, manuscript edits, commits, uploads, or shared-file
changes. The separate non-MDER H06-D-G2P-AR repair gate and L10 classification
hold remain unchanged.
