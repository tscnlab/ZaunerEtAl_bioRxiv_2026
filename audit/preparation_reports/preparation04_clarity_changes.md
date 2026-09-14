# Preparation 04 clarity and display record

Original rewrite date: 2026-08-01

METRIC-010 amendment date: 2026-08-11

METRIC-011 amendment date: 2026-08-12

Source: `notebooks/preparation/04_metric_derivation.qmd`

Rendered HTML:
`_build/nathealth/notebooks/preparation/04_metric_derivation.html`

## Meaning preserved

- The full-day record remains a placement-specific hybrid of worn near-eye
  or chest measurement during wake and bedside sleep-environment measurement
  during diary-defined sleep; it is not described as continuous ocular
  exposure.
- Actual UTC time still determines elapsed duration, gaps, adjacency,
  continuous periods, and dose. The local-clock plane determines clock-aligned
  bins, M10/L10, timing, interdaily stability, and the 1,440-position grid for
  current MDER.
- The 15-of-30 and 30-of-60 bin rules, zero-aware 0.1 lx offset, strict
  thresholds, 80% primary diary-period/window/relevance cutoffs, 70%/90%
  diary-period sensitivities, and 1.25 dose-correction cap are unchanged.
- Only dose may receive the approved time-sensitive correction. Current MDER
  is the arithmetic mean of viable positive finite one-minute
  melEDI/illuminance ratios and requires at least 720 of 1,440 ratios.
- M10 still tests 841 non-wrapping one-minute starts; L10 still tests 1,440
  starts with midnight wrapping; no L5 value is produced.
- Metric-specific failure still makes only that value unavailable. It does
  not remove an otherwise eligible participant-day or unrelated metrics.
- No metric value, support classification, participant, participant-day,
  time-grid row, input, manifest, model frame, or downstream result changed.

## Reader-facing changes

- Replaced the state-support, MDER-support, and metric builders and the MDER
  verifier call with direct reads of current stored outputs.
- Added a clear purpose, exact inputs, position in the Preparation 01–06
  chain, bounded-render note, hybrid-measurement warning, and accessible
  process diagram.
- Explained the producing scripts in execution order with a 38%/62%
  two-column layout, avoiding the narrow narrative column identified in
  Preparation 06 Table 13.
- Added 13 semantic `gt` tables covering exact inputs, production modules,
  scientific rules, participants, sites, participant-days, time-grid rows,
  diary-period support and MDER availability, bin support, metric availability, gaps,
  daylight-saving handling, forwarded files, file identities, and
  version-specific verification.
- Split daylight-saving counts from the gap table so neither display relies
  on compressed columns.
- Added an accessible final-size figure of current primary-dataset MDER
  availability, paired with the stored METRIC-010
  `verification_summary.csv` source data.
- Identified the eight R data files passed to Preparation 06 and applied the
  approved first-use definition of the gap-timing-unaware dataset.
- Applied PREP-003 as amended by METRIC-010: the current metric values and
  MDER were independently reconstructed and pass; FIND-044 now remains open
  only for exact reconstruction of the current diary-period support manifest.

## Verification

- Static and rendered-HTML bounded-render test: **PASS**.
- Pre-amendment final-profile page-specific read-set baseline: 109 entries;
  SHA-256
  `2ce1db192a0c7c32042e8e4477d6ee637519f09a5bb51c6300804f262ba237ac`.
- Pre-amendment post-render comparison: 109 unchanged, 0 mismatches.
- Current metric manifest SHA-256:
  `7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43`.
- Current independent MDER audit manifest SHA-256:
  `5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb`.
- Historical MDER support-gate manifest SHA-256:
  `9ca9b97dac5efd9ec4e7b43a1fb2227b7a13cf98ac4b92318606c4874f9e460b`.
- Current diary-period support manifest SHA-256:
  `755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619`.
- Pre-amendment rendered HTML SHA-256:
  `2dda2e1db895668d37a5e17a5a1ca5e97156c2f2b1ebdb7fb19b674023394fe0`.
- Rendered HTML contains 13 semantic `gt` tables, 14 resolved table/figure
  captions, one empirical image with alt text, and no unresolved table or
  figure cross-reference.
- Render context: R 4.6.1, `gt` 1.3.0, `ggplot2` 4.0.3, and Quarto 1.9.37
  using the `nathealth` profile.

## REPORT-011 figure and layout QA

- The MDER availability figure was inspected at its final 7.2-by-4.2-inch
  aspect ratio. Axis and legend text are 9 pt; the axis title is 10 pt.
- Available and unavailable days remain distinguishable by colour, direct
  counts, segment position, and a matching legend.
- There is no clipping, cropping, overlap, distorted text, awkward wrapping,
  broken unit, compressed data region, or unbalanced legend.
- Narrative-heavy tables use two broad columns. The gap and daylight-saving
  summaries are separate compact tables, preventing narrow high-content
  cells.

## Initial METRIC-010 amendment — 2026-08-11

- Explained the complete local wall-clock grid, channel-wise averaging of
  fall-back duplicates, absent spring-forward minutes, the finite and
  strictly positive minute-pair rule, and the inclusive 720/1,440 criterion.
- Stated explicitly that a failed MDER rule removes only MDER, not the day or
  another metric, and that profile-gated ratio-of-integrals records are
  historical rather than active.
- Added current primary and gap-timing-unaware availability, participants,
  means, and medians from stored METRIC-010 audit outputs.
- Added the independent verifier and audit-finalizer steps, all six stored
  audit outputs, exact manifest identities, and the stored zero-change result
  for 43 non-MDER fields at both placements.
- Focused source and rendered-HTML test: **PASS**; 13 semantic `gt` tables,
  no visible raw tibble output.
- Final METRIC-010 scoped baseline: 66 paths; SHA-256
  `8103e9b29d9523f4d0e09134b3c7831e67dff75f4cffe61f3d934846ebc063d8`;
  post-render result: 66 unchanged, 0 mismatches.
- Amended source SHA-256:
  `bfb3ec2b1f5855a6d05977730f5b7bffb96a1f4c1edbc17b4d2691d571ddf86c`;
  focused test SHA-256:
  `6f049e428ceb69040ffcfd247a405e719eab76b6ae1369b17dbd44e895a4e29a`;
  rendered HTML SHA-256:
  `451612638fc942b3d68b30dcdd0f7132a8b05e19776cf9cda895d6539767f1d8`;
  figure SHA-256:
  `423cae8946a50bd6e611ff14708b7ff0543546f3fdc9e9fa030ca917838d75ce`.

## Repaired gap-timing-unaware MDER follow-up — 2026-08-11

- Replaced the incomplete first-repin availability with the independently
  verified repaired counts: 687 available and 124 unavailable near-eye days
  among 811, and 723 available and 174 unavailable chest days among 897.
  The earlier 725/729 wording is retained only as explicitly superseded
  provenance.
- Added the repaired gap-timing-unaware means and medians: 0.7242573 and
  0.7238676 near eye, and 0.7567377 and 0.7495175 at the chest. Participant
  counts remain 137 and 152, respectively.
- Pinned the repaired prepared-data manifest
  `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935`,
  participant-day RDS
  `7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1`,
  support RDS
  `a0bc5d7ea2142709412da2253158086416ddb730b0f60ff616bba9d6ccb1edc5`,
  and independent repair-evidence manifest
  `81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018`.
- Explained from stored evidence that the repair changed MDER only: all
  25,620 non-MDER participant-day cells were exact. Failure of the support
  rule continues to remove only MDER, not the day or another metric.
- Bounded render and focused source/HTML test: **PASS**. The 93-path scoped
  read set was unchanged before and after rendering; baseline SHA-256
  `0111323dd0df3329ea5637b91f937e538fc2a49a20dbfb358664b90212e53b78`.
- Final source SHA-256:
  `117aad216c96131b41dc450f74e77ef8a3b7b5e3b9112e435100f19b0539c1de`;
  focused test SHA-256:
  `b8b40d1e60b065256d12c7f070d5751c9ff603048f743b094ec45e73b78a8033`;
  rendered HTML SHA-256:
  `71517017ed87dc6e3215058002f7effac7d870b8f1d01ed3d26a48be62c5598a`.
- The primary-dataset availability figure was scientifically unchanged and
  again passed final-size typography, clipping, overlap, wrapping, balance,
  and distinguishability QA. Its SHA-256 remains
  `423cae8946a50bd6e611ff14708b7ff0543546f3fdc9e9fa030ca917838d75ce`.

## METRIC-011 numerical-zero follow-up — 2026-08-12

- Added the active offset-geometric-mean rule: production adds 0.1 lx,
  averages on the log10 scale, transforms back, subtracts 0.1 lx, and stores
  a within-tolerance positive remainder as zero only when every finite source
  value is itself exactly zero. Missing minutes remain missing and are never
  imputed as zeros.
- Reported the source-verified tolerance
  `2.220446049250313e-14` lx and the eight primary L10 values changed from
  `4.163336342344337e-17` lx to exact zero: three near eye and five at the
  chest. Seven windows contain 600 observed zeros; the remaining chest window
  contains 547 observed zeros and 53 missing minutes.
- Stated explicitly that all 816 near-eye and 902 chest participant-days
  remain available for L10, every non-L10 scientific value and every sample
  is unchanged, and no hypothesis model was fitted or refitted.
- Added the numerical-zero finalizer and independent core verifier to the
  producing-code map. The current metric/evidence identities are kept
  separate from the six-output MDER audit tied to preceding metric manifest
  `7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43`.
- Current metric manifest SHA-256:
  `028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e`;
  METRIC-011 decision SHA-256:
  `23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797`;
  seven-file evidence manifest SHA-256:
  `a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb`.
- Focused source and rendered-HTML contract: **PASS**. The 106-path scoped
  pre-render baseline has SHA-256
  `3fed8439a84138b77300081f6bbce5f34df381b122f5c6a919587baac24ec0e4`;
  post-render verification found 106 unchanged paths and zero mismatches.
- Final source SHA-256:
  `0de19fc8bdd68ff24c35dfb621d819f3cc6c6bacc532be8fc1b8b3b3242ac668`;
  focused test SHA-256:
  `bab6b85bcd7c445c41681231ce84e1420816a7cc5887883b90e27534ae92080d`;
  rendered HTML SHA-256:
  `461e4605ff967690b6fc779a2f4381a8f19936bcd6aa48c4c091774b6437664c`.
- The MDER figure is scientifically unchanged. Direct inspection of its
  1,382 × 806 pixel render found no clipping, overlap, distortion, awkward
  wrapping, or legend imbalance; its SHA-256 remains
  `423cae8946a50bd6e611ff14708b7ff0543546f3fdc9e9fa030ca917838d75ce`.
