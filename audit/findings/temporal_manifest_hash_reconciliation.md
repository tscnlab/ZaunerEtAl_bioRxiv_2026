# Temporal-provenance manifest checksum reconciliation

Status: `audit_record_reconciled`

Date: 2026-07-30

## Finding

The clean Preparation 06 render reproduced all four elapsed-time provenance
artifacts at their recorded byte hashes, but the four-row manifest had
SHA-256
`37f868fb4bc9d387f7a10a32d15646f165162a7bca1daf9a6538d0485311148b`
rather than the previously recorded expected value
`4627501e20a944d537d2f5cc2ba49ac895ed6b9e89e1ff101c03241c43e0515a`.

The independent Preparation 06 HTML verifier therefore stopped as intended.
No expected checksum was changed until the manifest itself and the underlying
scientific artifacts had been investigated.

## Checks

The four scientific artifacts retained their recorded hashes:

- true-UTC source-bin RDS:
  `87c05a2534479c02ed62e16bc74a4c8a6a061aff125a528e404f403b3e2ff46b`;
- true-UTC source-bin CSV:
  `88c7d2bb953a26290031e589ac4d51ca026889b0403299f8ba9db6b2f436b4b5`;
- wall-outcome-link RDS:
  `a617893e74bbbd760950c185d0c548ff55692c52ded554a527dad2d72f2e6eb4`;
- wall-outcome-link CSV:
  `b4e7623f2b930162f33f08f9e426e915f28226a32181c41e297e7d3eb0a25141`.

The R 4.6.1 independent verifier passed the full reconstruction: 122,982
true-UTC source bins, 122,976 local-clock outcomes, six fall-back
participant-days, four spring-forward participant-days, 118,635
sequence-eligible bins, and 2,583 sequence starts.

The complete builder/verifier test then:

- rebuilt the artifacts in an isolated directory;
- independently verified that build;
- reproduced the same scientific and manifest bytes in a second build;
- reproduced the same bytes under a different output root;
- rejected paths outside the declared provenance roots; and
- rejected a deliberately corrupted sequence even after its file hashes were
  refreshed.

The deterministic current manifest hash in every tested root is
`37f868fb4bc9d387f7a10a32d15646f165162a7bca1daf9a6538d0485311148b`.
The former expected checksum was therefore a stale audit-record value, not the
identity of the current verified 20-column manifest.

## Resolution

The expected manifest checksum in the current verifier and audit reports is
reconciled to
`37f868fb4bc9d387f7a10a32d15646f165162a7bca1daf9a6538d0485311148b`.
No source bin, local-clock outcome, sequence field, count, exposure value,
model input, or scientific result changed.

Reopen if any scientific artifact hash changes, the manifest ceases to be
byte-stable across repeated or relocated builds, or the independent
reconstruction fails.

## Subsequent verified upstream regeneration

The approved numerical roundoff repair for darkest 10-hour mean melEDI later
regenerated the metric manifest. The temporal manifest records that upstream
identity and therefore changed to
`d05f8cf2ba7f5be01ae2fa5eb9c27350da2f84ed07508a731e243f1db23e1bb6`.
All four temporal scientific artifacts retained the hashes listed above, and
the independent full reconstruction passed again. This is an expected
upstream-fingerprint transition, not a change to a source bin, wall link,
sequence or exposure value.
