# REPORT-017 H01 order 31h independent stopped-state acceptance

Date: 2026-08-14

Status: **The authorized two-image transition classification and direct
manifest reseals are independently accepted. The complete order remains
stopped at a separate historical reconciliation-manifest gate. No H01 rerender
is released.**

## Accepted order 31h work

The H01 owner implemented the exact fail-closed classification for the two
model-support images accepted under order 31f. The frozen REPORT-016 inventory
still records the historical PNG and SVG identities, while the test requires
the exact approved live identities and the accepted order31f core manifest.
Any third mismatch fails.

The accepted positive preregistration-link contract remains intact:

- 40 exact relative `.qmd` targets;
- 36 unique lower-case anchors; and
- every linked anchor declared exactly once in the central deviation page.

The Stage 3 manifest now has 108 rows. All 108 current paths, hashes, and byte
counts are exact. Its change is limited to the three authorized identity
updates and 13 closed-allowlist additions.

The worker manifest now has 1,644 rows. Exactly 1,638 are live-exact. Its six
older recorded identities are the already documented H01 HTML, Nature Health
profile, reporting manifest, result QMD, companion QMD, and reporting test.
They predate accepted REPORT-014 or REPORT-017 transitions and were not changed
by order 31h. No seventh worker-manifest mismatch exists.

The current accepted identities are:

- REPORT-016 test:
  `b0c41cef4a0f373b5ae4da8bcac987493f4d3d46618fd217c964945f5ed8b620`;
- Stage 3 manifest:
  `16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e`;
- worker manifest:
  `9a369002e9ebfdc9d99ba08c1bb86b2588d6308b7e844b36fea6336f95e47328`;
- immutable reporting manifest:
  `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079`.

The intermediate reseal summary records an earlier worker-manifest state. It
is execution history, not the final worker-manifest identity. The final
48-row owner seal and current file both establish `9a369002...` as controlling.

## Independent replay

An independent R 4.6.1 read-only replay verified:

- 108 of 108 Stage 3 manifest rows exact;
- 1,638 of 1,644 worker rows exact, with the six expected historical rows and
  no additional mismatch;
- 48 of 48 non-circular owner-manifest entries exact;
- exact test and two-manifest reverse reconstructions to the dispatch pins;
- all seven files under `audit/hypotheses/H01/report016/` byte-identical before
  and after the owner work;
- the exact two-image historical-to-live transition;
- 40 dynamic preregistration links and 36 resolving anchors; and
- the current result QMD, companion QMD, HTML, builder, PNG, SVG, profile, and
  central deviation-page pins.

R parsing and scoped `git diff --check` pass. No Quarto render, model fit,
prediction, bootstrap, resampling, scientific artifact regeneration, profile
edit, package or lockfile change, commit, or push occurred.

## Legitimate remaining stop

`audit/hypotheses/H01/report016/H01_REPORT016_reconciliation_manifest.csv`
is an unchanged historical manifest sealed during the earlier deviation
reconciliation. Eight of its 15 rows remain live-exact. Seven correctly retain
older identities for files that were subsequently changed by accepted
reporting work:

| Path | Historical identity prefix | Accepted live identity prefix |
|---|---|---|
| Stage 3 reporting manifest | `476fa10d` | `16e752b5` |
| reporting manifest | `4d39e9b1` | `d0ed8e0c` |
| H01 result QMD | `8c7ca4e7` | `31c477fa` |
| H01 companion QMD | `685641fc` | `962b2866` |
| H01 result HTML | `53a216ff` | `6e0bb1b3` |
| Stage 3 reporting builder | `eca3e1e8` | `35443e52` |
| REPORT-016 focused test | `55c89eb0` | `b0c41cef` |

The historical manifest must not be rewritten to claim that these newer files
existed during the original reconciliation. The current test still treats all
15 historical rows as if they must equal the live files, so it stops before
the order31f display test and complete H01 reporting test can run.

## Smallest safe next gate

A separate coordinator-approved test-only order is required. It should:

1. preserve the historical reconciliation manifest byte-for-byte;
2. retain exact live equality for its eight unchanged rows;
3. require exact set equality for the seven historical transitions above,
   including both their frozen identities and their accepted live identities;
4. fail on a missing row, extra row, or eighth mismatch;
5. resolve the focused test's post-edit identity through its exact current
   worker-manifest row, avoiding an impossible self-hash literal inside the
   test itself;
6. update only the directly dependent worker-manifest test row and bounded new
   evidence; and
7. rerun the complete REPORT-016 test, order31f display-refresh test, and H01
   reporting test under R 4.6.1 before any render release.

No QMD, historical manifest, Stage 3 manifest, reporting manifest, builder,
image, HTML, scientific artifact, profile, or hook should change in that gate.

## Identity seal

The non-circular 23-entry independent manifest is
`audit/report_harmonization/report017_h01_order31h_stopped_state_independent_manifest.csv`,
SHA-256
`d46a834c95075ad93bcef4be16b9c8ab69eed028e3d4b99ecd03c1aa1dcd1b66`.

H01 remains the sole active serial document set. Its result rerender,
companion, H02, the queued H03 synchronization, and all later REPORT-017
targets remain held.
