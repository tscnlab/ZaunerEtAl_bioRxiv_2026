# Nondeterministic temporal-provenance manifest metadata

Status: `repair_verified`

Date: 2026-07-30

## Finding

A clean Preparation 06 render regenerated the true-time sequence-provenance
manifest with a different SHA-256 even though its source-bin and wall-link RDS
and CSV artifacts were byte-identical. Each manifest row contained a runtime
`written_utc` value and an absolute output path.

The scientific reconstruction and independent verifier continued to pass, but
the content identity depended on execution time and checkout location. This
would prevent a clean isolated render from reproducing an identical
provenance package.

## Repair

The temporal manifest now has an exact 20-column deterministic schema. It:

- omits runtime write timestamps;
- stores output paths relative to the output project root;
- stores all analytical input and upstream-manifest paths relative to an
  explicit input root;
- fails closed when a producer or verifier path lies outside its declared
  root; and
- retains artifact hashes, byte sizes, dimensions, input and upstream
  manifest hashes, sequence contracts, producer, R version, and status.

The verifier independently reconstructs the complete schema, paths, input
hash collections, dimensions, and scientific sequence structure.

## Verification

- The production manifest has four rows, 20 columns, and SHA-256
  `37f868fb4bc9d387f7a10a32d15646f165162a7bca1daf9a6538d0485311148b`.
- Same-root regeneration and an alternate-output-root build produce that
  identical manifest.
- The four scientific artifacts remain byte-identical:
  - source-bin RDS:
    `87c05a2534479c02ed62e16bc74a4c8a6a061aff125a528e404f403b3e2ff46b`;
  - source-bin CSV:
    `88c7d2bb953a26290031e589ac4d51ca026889b0403299f8ba9db6b2f436b4b5`;
  - wall-link RDS:
    `a617893e74bbbd760950c185d0c548ff55692c52ded554a527dad2d72f2e6eb4`;
  - wall-link CSV:
    `b4e7623f2b930162f33f08f9e426e915f28226a32181c41e297e7d3eb0a25141`.
- R 4.6.1 builder, independent reconstruction, duplicate/DST/sequence tests,
  refreshed-hash corruption rejection, two-build byte stability,
  alternate-root portability, and outside-root rejection all pass.

The manifest checksum was reconciled after a later clean-render challenge;
the four scientific artifact hashes were unchanged. See
`audit/findings/temporal_manifest_hash_reconciliation.md`.

## Reopening condition

Reopen if a runtime timestamp, absolute checkout path, temporary path, random
identifier, or other execution-specific value enters a deterministic
temporal-provenance artifact or manifest.
