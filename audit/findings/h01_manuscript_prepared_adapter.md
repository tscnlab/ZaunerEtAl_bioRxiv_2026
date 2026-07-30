# Same-model H01 adapter for the manuscript-prepared-data sensitivity

Finding ID: `FIND-036`  
Status: repair verified  
Date: 2026-07-30

## Finding

The first manuscript-prepared-data artifacts correctly declared
`new_h01_h11` as their intended model implementation, but the production H01
builder was still hard-coded to the main data. A synthetic input-swap test
showed that the reusable row builder could accept another dataset, but no
production adapter, scenario-specific H01 artifact or independent verifier
proved that the same implementation was actually used.

The manuscript-prepared metrics also required two explicit interface rules:

- their five timing outcomes were stored as decimal clock hours rather than
  clock minutes; and
- 62 darkest-10-hour midpoints were already negative because they had been
  moved to the nighttime scale.

Passing those negative values directly to the shared H01 model code would
apply the nighttime transformation twice. The retained manuscript-prepared
artifacts also do not contain the exact minute support used to calculate every
metric.

## Repair

A production adapter now:

- reads only the independently verified manuscript-prepared artifacts;
- retains the scenario-specific dose and MDER definitions and labels;
- restores negative darkest-10-hour midpoints to the ordinary 24-hour clock,
  converts all timing outcomes to clock minutes, and leaves the shared model
  code to apply its nighttime transformation once;
- records metric-support hours as unavailable rather than zero;
- gives near-eye and chest data their correct measurement-construct labels;
- sends both data scenarios through the same H01 row, sample-flow and
  exclusion functions; and
- writes the sensitivity under a separate scenario directory without
  modifying the main H01 artifact.

The main and sensitivity contracts have the same implementation fingerprint,
`e07db16818e565aff40fa6b9f79f34a31eb943d6c393343ca96471b795bacbed`,
and the same shared-code hash,
`c7d66825c359066ec6dce1a623408d532c4686fd0b77bfe1da5e392fcc7f5516`.
Their data-scenario identifiers remain different.

## Verification

R 4.6.1 verification confirms:

- 45,410 H01 rows in each scenario interface;
- 12,447 all-available near-eye rows and 13,763 all-available chest rows;
- 640 paired participant-days, producing 9,600 daily metric rows per
  placement;
- exactly 29 near-eye and 33 chest darkest-10-hour midpoints restored from
  the negative nighttime scale;
- no wrapping of another timing metric;
- deterministic isolated rebuilding;
- rejection of undeclared output files;
- direct CSV-to-RDS parity;
- rejection of coordinated RDS, CSV and output-inventory tampering through an
  independent rebuild; and
- byte identity of the main H01 artifacts during sensitivity builds.

The final main H01 manifest SHA-256 is
`48f7cb7a9539bd1a35237275187a76528f1daacfc9abe368cbc4bc1397ed0375`.
The final sensitivity manifest SHA-256 is
`672312ba62871317b0910fbd781f7f6db92e6718fed26961e17a986a5eb989f5`.

## Remaining limitation and reopening condition

These are prepared model frames, not fitted-model samples. Every later fit
must store its exact analysis frame and reconcile observations, participants,
participant-days or contributing days, and sites after transformation and
missing-value handling. Reopen if either implementation fingerprint changes,
if a scenario-specific model rule is introduced, if timing units change, or
if exact support records become available and are incorporated.
