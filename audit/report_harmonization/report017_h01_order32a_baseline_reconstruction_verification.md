# REPORT-017 H01 order-32a baseline reconstruction verification

Date: 2026-08-15

## Scope

This structural check reconstructed the six exact comparison files needed by the H01 order-32 verifier. It did not read or calculate a scientific result, edit an H01 owner file, execute R or Quarto, or alter a rendered artifact.

The reverse series was derived from 30 chronological, non-truncated file-change records in the H01 task's completed order-32 turn. The provenance table preserves each event ID and target path. The series is applied only to temporary copies in reverse chronological order.

## Command and result

```sh
baseline_check_dir=$(mktemp -d /private/tmp/H01-order32a-baseline-check.XXXXXX)
sh scripts/report_harmonization/reconstruct_h01_order32_baseline.sh . "$baseline_check_dir"
```

Resolved trial directory: `/private/tmp/H01-order32a-baseline-check.i3nvP5`

Exit status: 0

All six reconstructed hashes and byte counts matched the accepted order-32 preflight pins. No unexpected file was present in the reconstructed directory.

## Sealed inputs

- Reconstruction script: SHA-256 `c3c7ea4348d18fa93cc8d0e74656a22dcc9fe5f52836a9ab1e1f331969ddc0c6`, 4,465 bytes.
- Event provenance: SHA-256 `4a1673870de79905f7f85cfca314444432a63c929e74bb344620d6b758cd2326`, 2,688 bytes.
- Reverse series order: SHA-256 `a8ca8df587c85eeea80a0485c3235c4a90eb4b6349776fee65b6254b4840df5c`, 351 bytes.
- Non-circular 33-row bundle manifest: SHA-256 `f2abc82cd0b705d6524fdb4b34d9b31d1a4034a351784295e66050132d34a544`, 5,821 bytes.

`git diff --check` passed for the reconstruction script, patch bundle, and manifest.

## Disposition

The lost temporary baseline is fully recoverable without modifying the shared checkout or weakening the verifier's pre/post comparisons. The owner retry must create a new fresh temporary directory and independently reproduce all six identities before its single complete verifier execution.
