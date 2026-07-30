# Nondeterministic normalization-manifest timestamp

Status: `repair_verified`

Date: 2026-07-30

## Finding

A clean Preparation 06 render regenerated the model-input normalization
manifest with a new SHA-256 even though all 15 normalized RDS and audit CSV
artifacts remained byte-identical. The only unstable content was
`written_utc`, copied from each file writer's runtime metadata into the
content-addressed manifest.

Because the base-model input bundle correctly included the normalization
manifest hash, this runtime timestamp also changed the base manifest and
caused the pinned pre-analysis comparison gate to fail closed. No data value,
row, key, sample count, variable, metric, or model-ready outcome changed.

## Repair

`written_utc` was removed from the deterministic normalization-manifest
contract. The manifest continues to record each artifact's:

- path and artifact type;
- SHA-256 and byte size;
- rows and columns;
- exact acquisition-manifest SHA-256;
- producer; and
- R version.

Runtime timestamps remain available in the writer's transient return metadata
and execution logs, where they do not affect content identity.

## Verification

- Two consecutive R 4.6.1 normalization builds produce the identical manifest
  SHA-256
  `e3d484711abb54f69d63ff302e5a0329efda3fd0a8c85feaf9cc4f850005c9ab`.
- All 15 normalized artifact hashes equal their pre-repair values.
- The base-model layer verifies with input-bundle SHA-256
  `7a4540dceca5469c608633ef35923b0af0b841c2f5bba4dc0450c0632f258702`
  and manifest SHA-256
  `68d3512c83c5aed0f505522b06f8be346aa9da60a9c5a4ebc7fb71648076574a`
  after the analogous site/solar-manifest repair.
- The pre-analysis comparison independently verifies under the new pins. All
  12 scientific table and figure artifacts are byte-identical to the reviewed
  pre-repair build; only its three provenance/reporting artifacts changed.
- The H03/H04 diary-category support audit reproduces all counts and output
  table hashes under the stable normalization manifest.

## Reopening condition

Reopen if a runtime timestamp, random identifier, absolute temporary path, or
other execution-specific value is introduced into a content-addressed
manifest or deterministic output.
