# REPORT-018 Brown order 65a continuation dispatch

Date: 2026-09-02

Destination task: `019fffdf-66d4-7802-9091-09283ad27b7f`

## Independent disposition

Central coordination independently reproduced the order-65 stop. All 28
non-circular stop-manifest rows, six applied source postimages, 32 exact
forward and reverse substitutions, ten unchanged figure endpoints, and four
protected endpoints are exact. Three legacy builders are historically not Air
0.4.1 full-file no-ops. The formatter would make broad changes outside the
authorized matrix.

Order 65a therefore prohibits broad builder formatting and replaces only the
invalid full-file formatter gate. It retains exact source-transition hunk
proofs, requires R 4.6.1 parsing of all legacy builders and both QMD chunk
inventories, and requires Air no-op checks only for new order-owned scripts
and the unchanged dedicated refresh script.

## Pre-send verification

The bounded R 4.6.1 continuation preflight returned:

`BROWN_ORDER65A_PREFLIGHT=PASS stop_manifest=28 sources=6 matrix_actions=32 assets=10 protected=4 formatter_legacy_noncanonical=3 qmd_chunks=14/19 candidates=0 qa=0 R=4.6.1`

## Dispatch controls

- Order 65 SHA-256:
  `497aa2f1ece654f908f2b58abfaf04f4887a7af0da81b183ea582fd4a8f9cef5`.
- Order 65a SHA-256:
  `9636ddd68cdedfaa42460a442e04db42aa45ce5673d68fd183b994a112018d42`.
- Continuation preflight SHA-256:
  `82a206bbedcb3ff00cb192535e93cc4a94f3b26a0e6613da44be29ad6d72f3a7`.
- Owner stop-manifest SHA-256:
  `89278456eff14714825b9499b6e11672f1bfe3f4b3e22576db2e64ffa7abcfe8`.

## Boundary

The owner may resume only the candidate-first source/display workflow. No
Quarto, Pandoc, knitr, browser server, HTML mutation, Stage 4 edit, model,
prediction, inference, resampling, source-data change, package, lockfile,
configuration, ledger, manuscript, commit, push, upload, or broad formatting
is authorized. Independent acceptance remains required before any serial
render release.
