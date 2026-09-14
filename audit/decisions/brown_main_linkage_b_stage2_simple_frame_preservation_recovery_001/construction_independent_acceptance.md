# Construction recovery: independent acceptance

Date: 2026-09-12. Parent:
`BA-018-SIMPLE-FRAME-PRESERVATION-RECOVERY-001`.
Status: construction accepted; remaining approved sensitivities active.
This is not acceptance of the complete statistical analysis.

Both uniquely registered recovery jobs exited 0 without timeout and reaped
their children. The source-metadata fixture passed 26/26; the original
constructor fixture remains 25/25. Production reconciliation passes eight
memberships, 45/45 design ranks and all seven construction checks.

The six-member production manifest is exact, unique and non-circular. All
four CSVs are byte-identical to the previous independent full construction
replay. The two RDS files use the unchanged production runtime's xz compression,
whereas the temporary audit used default gzip. Their complete decompressed
serialized payloads are byte-identical. No deserialization, fit, inference,
diagnostic draw or construction rerun was needed for this comparison.

The first independent checkpoint applied a too-strict compressed-byte
comparison and stopped. That attempt and its comparison remain retained under
`/private/tmp/ba018-simple-frame-recovery.ODnixS/construction_checkpoint_001/`.
The exact runtime contract establishes the xz-versus-gzip distinction. The
second checkpoint checks the declared file signatures and full decompressed
serialization, not approximate object equality or ignored attributes.

Definitive independent evidence:
`/private/tmp/ba018-simple-frame-recovery.ODnixS/construction_checkpoint_002/manifest.csv`,
SHA-256 `0c499debd52ec762ad6ffd055dbbcfe31a17590759654fdaa6ca7ddd27589392`.

The construction finish record reports the exact v2 driver and v5 supervisor.
Its elapsed 1.9178922080027405 seconds follows the fixture's recorded time;
the 0.611-second audit charge was included once. Cumulative time at this
checkpoint is approximately 110.264 seconds. Both jobs added zero fits and
zero diagnostic draws. The author reported 750 attempted and 500 logical
draws unchanged at the checkpoint.

Continue the already approved finite sensitivities under the same release.
Primary models, estimands, completed diagnostics, package 004, failed histories,
the Pre-sleep qualification and all scientific limits remain protected.
Later analysis/report phases retain independent acceptance boundaries under
the author's standing completion instruction.
