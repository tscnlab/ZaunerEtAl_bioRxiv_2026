# Brown Stage 3 order 50 protected-token scope verifier correction

Date: 2026-08-21  
Disposition: `AUTHORIZED_FINAL_VERIFIER_ONLY_CONTINUATION`  
Controlling chain: REPORT-018 Brown Stage 3 order 50

## Independent stopped-state acceptance

R 4.6.1 independently reproduced the protected-token validator stop before
semantic promotion:

- the non-circular stopped-state manifest passes 10 of 10 exact and unique
  members;
- the sealed token audit contains 41 rows;
- 12 rows fail only when the paired count is compared with Stage 3 alone;
- all 41 Stage 3 plus Stage 4 counts exactly equal the sealed `post_count`;
- the Stage 3 QMD, Stage 4 QMD, raw HTML, semantic candidate, and semantic
  ledger remain exact;
- the canonical Stage 3 HTML remains the unpromoted raw render; and
- no second render or visual QA occurred.

The inventory was created by the accepted paired source-only verifier from
the concatenated Stage 3 and Stage 4 QMD text. The new Stage 3 candidate
validator incorrectly interpreted its paired `post_count` as a Stage 3-only
count. No reader-page, source, scientific, semantic, privacy, or Stage 4
defect is established.

## Complete prospective replay

A temporary copy of the current candidate validator was changed only to use
the exact concatenated Stage 3 and held Stage 4 QMD text for the 41 protected
token counts. Its output was confined to a fresh `/private/tmp` directory,
and it exited immediately after all candidate checks and before promotion.

The complete R 4.6.1 prospective result was:

`BROWN_ORDER50_PROSPECTIVE_CANDIDATE=PASS checks=25/25 promotion=0`

This replay covered the full remaining candidate path, including semantic
reversal, normalized DOM preservation, 16 native gt tables, document and
table ID references, source-derived endpoint order, captions and alt text,
source manifest, paired protected tokens, links, country-coded sites,
privacy, responsive structure, hierarchy, held Stage 4 identities, lockfile,
boundary preservation, embedded-error absence, and intermediate-file absence.

## Authorized continuation

The Brown owner may resume from the sealed post-render checkpoint under these
exact limits:

1. Preserve the complete protected-token stopped state byte-for-byte.
2. Edit only the current task-owned candidate validator. For the protected
   token contract, concatenate the immutable Stage 3 QMD text and held Stage 4
   QMD text in that order, reproduce all 41 counts, and require exact equality
   with the sealed paired `post_count` column. Retain the Stage 3 rendered-text
   counts as diagnostic evidence only.
3. Do not weaken any of the other 24 candidate gates or change the previously
   accepted endpoint-order correction.
4. Rehash the raw HTML, canonical raw HTML, candidate, ledger, both QMDs,
   Stage 4 HTML, lockfile, and both central verifier-correction authorities
   before execution.
5. Run the corrected candidate validator and conditional promotion step once.
   Do not regenerate the candidate. Promotion remains conditional on all 25
   candidate checks passing.
6. If promotion succeeds, continue only the unconsumed source, link, privacy,
   protected, visual, lifecycle, teardown, and post-QA checks from order 50.
7. Return one combined acceptance if all checks pass. Stop without correction
   if a genuinely new page, semantic, privacy, protected, or visual defect is
   found.

## Frozen identities

- Stage 3 QMD: `2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43`
- Raw and current canonical HTML:
  `ff5f95248d854d15b2be7ff8f751eb133106e966a3561e58c25ef1bd377767bb`
- Existing semantic candidate:
  `3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d`
- Existing semantic ledger:
  `828067ef5b23e9d16d420f3aec517d3688e36053095095779381edc3227d9d2e`
- Current task-owned validator:
  `441e027579f6329e7399688ddbdcbe072911cdedc562c29177f36d5de123b49a`
- Protected-token stop manifest:
  `7e657f42b674b936d982545870bf75ba5097e6adf902326bf395d3aef7a1587b`
- Held Stage 4 QMD:
  `628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475`
- Held Stage 4 HTML:
  `c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f`

No Quarto, Pandoc, candidate regeneration, source edit, scientific
computation, Stage 4 action, package or lockfile change, commit, push, or
upload is authorized. The sole order-50 render remains consumed. Stage 4
remains held pending independent Stage 3 acceptance.
