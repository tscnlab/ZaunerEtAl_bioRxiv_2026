# REPORT-018 Brown Order 65c SVG-only promotion dispatch

Date: 2026-09-02

Destination task: `019fffdf-66d4-7802-9091-09283ad27b7f`

## Author disposition

The author selected the validated participant-raincloud SVG. The historical
canonical participant-raincloud PNG must remain byte-identical and the failed
candidate PNG remains evidence only. No decoded-pixel waiver is granted.

Order 65b is accepted as a safe stopped package for this bounded disposition.
Its 48-member non-circular manifest is exact. The gate is 16 of 17, with the
participant-raincloud PNG decoded-pixel text-band comparison as the sole
failure. The validated participant-raincloud SVG and the other eight selected
endpoints passed their applicable gates.

## Pre-send verification

The bounded R 4.6.1 preflight returned:

`BROWN_ORDER65C_PREFLIGHT=PASS stop_manifest=48 duplicates=20 gate=16/17 candidates=10 promotion_set=9 canonical=10 sources=6 raincloud_png=UNCHANGED raincloud_svg=200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653 R=4.6.1`

The preflight script parses under R 4.6.1 and is an Air 0.4.1 no-op.

## Dispatch controls

- Order 65c SHA-256:
  `7501583354b606dc187e5f3642e1b5ab43444b239764d6f8eb92766b881f9b6c`.
- Order 65c preflight SHA-256:
  `c2a6a89d09f517378b2065a00cc79f6cfbaaaca1ead57b31716377f3454e8dab`.
- Non-circular 14-row dispatch manifest SHA-256:
  `5d969a69e2eb28877ebfe99ef643670b7cadfbc2af0ea414a7e70d388368a38e`.
- Order 65b stopped manifest SHA-256:
  `695fd5c42669cbb34e3be3fee797525a459459d2415c683d4d17816eb7d8f583`.
- Historical canonical participant-raincloud PNG SHA-256:
  `f3a61b69e89b0933302694ccca4ea5ed5c4d1bb2e67d169f3e1542a644843228`.
- Selected participant-raincloud SVG postimage SHA-256:
  `200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653`.

## Boundary

Promote exactly nine sealed candidate endpoints with no refresh or render.
Exclude `participant_state_raincloud.png` from every write operation. Preserve
all prior evidence and source postimages. Do not edit the Stage 3 QMD, which
continues to reference the historical PNG.

No source edit, Quarto, Pandoc, knitr, browser, HTML, Stage 4, manuscript,
model, prediction, inference, resampling, source-data, package, lockfile,
configuration, ledger, commit, push, upload, or broad-formatting action is
authorized. Independent central acceptance is required before the Writer may
integrate the canonical participant-raincloud SVG.
