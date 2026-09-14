# REPORT-018 Brown Order 65c independent acceptance

Date: 2026-09-02

Owner task: `019fffdf-66d4-7802-9091-09283ad27b7f`

Status: **ACCEPTED**

## Independent result

Central harmonization independently rehashed the complete Order 65c state in
the Brown owner worktree under R 4.6.1. The 19-member final manifest is exact,
unique by path and content, and non-circular. All six completion checks pass.
Exactly nine endpoints were promoted, every promoted endpoint is byte-identical
to its sealed candidate, and no participant-raincloud PNG occurs in the
promotion map.

The historical canonical participant-raincloud PNG remains unchanged at
1,832,424 bytes and SHA-256
`f3a61b69e89b0933302694ccca4ea5ed5c4d1bb2e67d169f3e1542a644843228`.
All six source postimages remain exact. No refresh, source edit, Quarto render,
HTML change, or manuscript change was recorded.

Independent verifier output:

`BROWN_ORDER65C_ACCEPTANCE=PASS manifest=19 completion=6/6 promoted=9 raincloud_png=UNCHANGED raincloud_svg=200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653 sources=6 R=4.6.1`

## Accepted manuscript endpoint

Use the SVG from the Brown owner worktree:

`/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/stage3_cross_state_association/figures/participant_state_raincloud.svg`

Identity: 108,600 bytes, SHA-256
`200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653`.

The Writer may copy this exact SVG into manuscript-owned assets and integrate
that derivative. The historical PNG is not an accepted manuscript endpoint.

## Acceptance evidence

- Central completion checker:
  `scripts/report_harmonization/check_brown_order65c_completion.R`, 6,903
  bytes, SHA-256
  `406525e6e696b5e1c81782457485b03be90bc09ec183051983e1a3ba66899e23`.
- Owner final manifest: 3,745 bytes, SHA-256
  `01cc6565eb52a206e4b3914646f9873f291c2dfef4ac0f973ab695b0b77e5b18`.
- Owner promotion manifest: 5,088 bytes, SHA-256
  `fbfd432d07752f05c31bd9a763b7400dc2f002b8f325d2eb4946f1bd697b81d8`.
- Owner preimage manifest: 4,070 bytes, SHA-256
  `c3e8e4619e453d4685864248566ae3f5d7ec5e72af1d908fbdb2012ac3e375b3`.
- Owner completion checks: 543 bytes, SHA-256
  `0f90b00083b2008f5f9cd10cc40d32f1ada9b6c70a942b5031271363b90c5006`.
- Owner handoff: 507 bytes, SHA-256
  `2a0c9e94e08db7fc033f458f82eda9d390a7221a76701bf924abe0caa6e81d5a`.
