# Direct CSV-to-RDS checks for manuscript-prepared sensitivity data

Finding ID: `FIND-035`  
Status: repair verified  
Date: 2026-07-30

## Finding

The first verifier reconstructed and checked the authoritative RDS objects and
checked every output file against the output inventory. It did not directly
compare each reader-facing CSV with the corresponding RDS table.

An independent test changed one participant-day value in a CSV and then
updated that CSV's checksum and byte count in the same unpinned output
inventory. The verifier still returned `PASS` because the changed CSV was
never compared with the independently reconstructed RDS content.

Ordinary production CSV and RDS values were scientifically equivalent but not
byte-exact after serialization:

- the largest numerical difference was \(2.91 \times 10^{-11}\);
- local-clock key timestamps matched exactly; and
- dawn and dusk timestamps differed by less than one second because the CSV
  representation did not retain the full fractional-second precision.

## Required repair

The verifier must compare every paired CSV directly with its authoritative RDS
table. The comparison must:

- require identical rows, columns, keys and missing-value positions;
- compare categorical and identifier fields exactly;
- compare numerical and subsecond time fields with a small, declared
  serialization tolerance;
- report that tolerance in the verification result; and
- fail when a CSV value and its inventory entry are altered together.

The tolerance applies only to writing and reading a display CSV. It must not
be used to accept a difference between scientific RDS objects or reconstructed
source values.

## Verification

All five CSV/RDS pairs now receive a direct column-by-column comparison.
Identifiers, categories, keys and missing-value positions must match exactly.
Numerical text uses absolute and relative tolerances of \(10^{-12}\), and
timestamps written without fractional seconds must differ by less than one
second. A regression test changes one CSV value and updates the same output
inventory's checksum and byte count; verification still fails because the CSV
no longer agrees with its RDS authority. Production, isolated-build and
deterministic-regeneration tests pass under R 4.6.1.

## Reopening condition

Reopen if a paired CSV lacks a direct RDS comparison, if the tolerance is
broadened without justification, or if a CSV-plus-inventory alteration can
pass verification.
