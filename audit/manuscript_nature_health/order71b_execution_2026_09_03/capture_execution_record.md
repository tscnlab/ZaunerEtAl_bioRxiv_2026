# Order 71b1 Word capture execution record

Date: 2026-09-03

Status: PASS

## Locked inputs

- Accepted manuscript source remained locked at SHA-256 `a527b6cb9ba689ab15370a05776280c632073ef27b79320a271feca96b27c69f`.
- Accepted self-contained HTML reproduced SHA-256 `438f80545e09eb1844d15c3d4495d7d2d4dbc07bcf039f4c8e4430b18e79ee0c`.
- Frozen capture script reproduced SHA-256 `9a38f12b93bd03f3332de2f3c862bedbd035659bd762b386b98166800a04af07`.
- The temporary serving directory contained one regular file and no symbolic links. Its served copy reproduced the accepted HTML SHA-256 under R 4.6.1.
- The historical capture directory retained all 49 image identities recorded in its accepted validation file.

## Exact successful commands

Loopback server:

```text
/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 -m http.server 8876 --bind 127.0.0.1 --directory /private/tmp/nathealth_order71b1_capture.38O676
```

Sole capture invocation:

```text
/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node scripts/manuscript_nature_health/capture_word_tables.mjs http://127.0.0.1:8876/ZaunerEtAl2026_NatHealth_phase3_brown.html audit/manuscript_nature_health/order71b_execution_2026_09_03/word_capture
```

The loopback server was stopped immediately after the successful capture. One earlier sandboxed server start was denied before binding the port and did not serve or capture any content.

## Capture gates

- Exactly 19 table selector entries and 17 figure entries were captured.
- The manifests enumerate 32 table PNGs and 17 figure PNGs.
- Every PNG decoded under R 4.6.1, was nonblank, had positive dimensions, and matched the dimensions implied by the frozen capture manifest.
- Supplementary Figures S5, S6 and S12 point to the exact accepted source identities required by the continuation.
- All four Table 3 parts were inspected at original resolution. They show all 17 metrics in the accepted descriptive order, with no clipped, blank, duplicated, missing or stale row and no broken density thumbnail.
- `table3_metric_order.csv` independently confirms the accepted 23-row table structure, the 17-metric order and the four complete contiguous capture ranges.

## Sealed evidence identities

- Table PNG manifest: SHA-256 `6c7093de3f83be5e95fc6ddb299c6b05b1bde4935fff871abe6a1b3008e40b39`, 18,198 bytes.
- Figure PNG manifest: SHA-256 `923410142cc15e5e655757e76200e78067cdec91bad5e545c31ccba9577118b6`, 7,156 bytes.
- Complete 51-member manifest: SHA-256 `1845665c21882e98f135b9932ef00bd53969bd8d9fd0afdb5a50b6fb0eec7ebe`, 14,994 bytes.
- Table 3 order record: SHA-256 `cd88eede1e6e66c3dd4ffd3ff00924a2c653af8b4f58fe5742a65069a7cc3889`, 983 bytes.
- Capture validation: SHA-256 `3229d9ddab1edce40db0d65a72724a1bc56a6273e6587b0ef939b113e6e9dfad`, 1,066 bytes.
- Reproducible R validator: SHA-256 `d053ce1e4c1f67af4aa9535d495f5da2c28d4537e972d9fc3eb906c61a29614d`, 10,373 bytes.

No QMD, accepted HTML, canonical DOCX, website, scientific artifact, prior capture, package state or lockfile was changed.
