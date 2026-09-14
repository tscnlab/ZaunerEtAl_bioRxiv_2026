# Order 71b focused implementation diff and reversal proof

Date: 2026-09-03

Status: PASS before candidate creation

## Focused changes

1. In `manuscript/R0_NatHealth/_quarto.yml`, the nested DOCX format alone now runs `../../_extensions/kapsner/authors-block/authors-block.lua`. No HTML setting changed.
2. In `scripts/manuscript_nature_health/prepare_word_manuscript.py`, one fail-closed helper locates the exact 14-affiliation paragraph, exact correspondence paragraph, unique ISO date and unique style-independent `Abstract` paragraph. It requires the raw blocks to follow Abstract, moves only the two existing author-block elements to the consecutive order Date, Affiliations, Correspondence, Abstract, and verifies unchanged XML, text, styles, relationships and body-child order. The helper is called exactly once. Its audit result is added to the existing terminal JSON.

No QMD, scientific text, display, caption, accepted HTML, website, canonical DOCX, analysis artifact, package state or lockfile changed.

## Preimage and implementation identities

| File | Locked preimage SHA-256 | Implemented SHA-256 | Preimage bytes | Implemented bytes |
|---|---|---|---:|---:|
| `manuscript/R0_NatHealth/_quarto.yml` | `c7c3fc8a96f1e65914cfb88c8d4de2bf8bcacb75fcf37902b262c79d2becae24` | `3ed50e7dc3339bd42fc19393f10480baf733f485a65f34c03980fe4d466c5cf0` | 482 | 561 |
| `scripts/manuscript_nature_health/prepare_word_manuscript.py` | `05ed9ca826757c643970a6d201fbcc15cfc83648d2ebdc8d44f707d85f214727` | `1a2b8091b34cd0fa88dcf6143cf336c52b531773e66e1578ac818fddfba97adf` | 31,160 | 38,747 |

## Reversal and dry-run checks

- `verify_implementation_reversal.py` removes only the two focused additions in memory and reproduces both exact locked preimage identities and byte counts.
- The nested YAML parsed under R 4.6.1 with the filter present only for DOCX.
- The helper was imported without bytecode output and exercised in memory against the sealed isolated raw-filter evidence. It found the raw indices Date 2, Abstract 3, Affiliations 5 and Correspondence 6, then produced the consecutive final indices Date 2, Affiliations 3, Correspondence 4 and Abstract 5 while retaining body-child count and 127 document relationships.

The first DOCX render and first DOCX postprocessing operation had not run when this proof was sealed.
