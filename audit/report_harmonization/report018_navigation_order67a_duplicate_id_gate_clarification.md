# REPORT-018 Order 67a duplicate-ID gate clarification

Date: 2026-09-02

Status: `NARROW_GATE_CORRECTION_WITHOUT_NEW_EXECUTION_AUTHORITY`

The Order 67a phrase “no duplicate document IDs” is an overstrict baseline
condition. The authorized mobile-TOC transformation changes only one embedded
script body and cannot change an HTML `id` attribute.

A read-only R 4.6.1 audit of all 37 accepted routes reproduces the established
legacy baseline exactly:

| Route | Duplicate ID values | Extra duplicate instances | Nodes carrying duplicated IDs |
|---|---:|---:|---:|
| Preparation 01 | 5 | 9 | 14 |
| Preparation 02 | 6 | 9 | 15 |
| Preparation 03 | 2 | 2 | 4 |
| Preparation 04 | 3 | 8 | 11 |
| Preparation 06 | 14 | 16 | 30 |
| Preparation 07 | 2 | 2 | 4 |
| Descriptives | 31 | 103 | 134 |

Across the corpus, seven routes contain 63 duplicated ID values, 149 extra
duplicate instances, and 212 nodes carrying duplicated IDs. The other 30
routes contain none. This is a pre-existing accepted-corpus limitation, not an
Order 67a finding.

The corrected gate is:

1. Before candidate generation, seal the complete per-route `(route, id,
   count)` baseline for every ID whose count exceeds one, plus the 37-route
   summary.
2. Require the candidate and promoted corpus to reproduce that complete
   multiset and summary exactly.
3. Require zero new duplicate ID values, zero added duplicate instances, zero
   removed or renamed legacy ID instances, and no change to any ID-bearing
   element outside the authorized script bytes.
4. Keep the seven legacy routes classified as preserved historical
   accessibility debt. Do not repair, rename, remove, or otherwise alter those
   IDs under Order 67a.
5. Retain all other Order 67a gates, stop rules, write boundaries, and
   prohibitions unchanged.

This clarification supplies no new file-write, render, retry, scientific, or
scope authority. It replaces only the impossible absolute duplicate-ID
condition with exact no-new-drift preservation.
