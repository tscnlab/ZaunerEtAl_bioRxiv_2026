# Brown Stage 3 order 50 endpoint-order verifier correction

Date: 2026-08-21  
Disposition: `AUTHORIZED_VERIFIER_ONLY_CONTINUATION`  
Controlling chain: REPORT-018 Brown Stage 3 order 50

## Independent finding

Order 50 consumed its sole authorized render successfully and stopped before
semantic promotion in a new task-owned candidate validator. The validator
treated row order in the sealed source-only endpoint inventory as rendered
document order.

R 4.6.1 independently established that the five expected figure endpoint sets
are identical and complete. The endpoint inventory records this row order:

1. `fig-main-adherence-levels`
2. `fig-main-coverage-sensitivity`
3. `fig-main-site-workday-adherence`
4. `fig-main-site-free-work-contrasts`
5. `fig-participant-state-raincloud`

The immutable accepted QMD and the rendered DOM both record this document
order:

1. `fig-main-adherence-levels`
2. `fig-main-site-workday-adherence`
3. `fig-main-site-free-work-contrasts`
4. `fig-main-coverage-sensitivity`
5. `fig-participant-state-raincloud`

Every endpoint is present exactly once as a rendered endpoint. No source,
page, semantic, privacy, or scientific defect is established. This is a
task-owned verifier classification defect.

## Authorized continuation

The Brown owner may resume from the durable post-render state under these
exact limits:

1. Preserve the failed validator and its output as evidence.
2. Edit only the new task-owned candidate validator. Keep the sealed endpoint
   inventory as the authoritative endpoint set, but derive expected figure
   order from the immutable accepted QMD by locating each expected endpoint
   literal, requiring all positions to be positive and unique, and sorting by
   those positions.
3. Require exact set equality and exact equality between the source-derived
   order and rendered DOM order. Do not weaken table, caption, alt-text,
   semantic, link, privacy, protected-identity, or preservation gates.
4. Rehash the existing raw HTML, candidate, ledger, QMD, and held Stage 4
   endpoints before execution. Do not regenerate the semantic candidate.
5. Run the corrected candidate validation and promotion step once. Promotion
   remains conditional on every candidate gate passing.
6. If it passes, continue the unconsumed source, link, privacy, protected,
   visual, lifecycle, teardown, and post-QA checks from order 50 and return one
   combined acceptance.
7. If any genuinely new failure appears, stop and seal it without correction.

## Frozen identities

- Stage 3 QMD: `2b3de9594e748f34753a03e8f0e8925e8aae8918d000cb2680392e98b7b49a43`
- Raw and current canonical HTML:
  `ff5f95248d854d15b2be7ff8f751eb133106e966a3561e58c25ef1bd377767bb`
- Existing semantic candidate:
  `3ab7bdd7b86d513d66528b57cab1410de3c48902ce1386d17bca876d63a0926d`
- Existing semantic ledger:
  `828067ef5b23e9d16d420f3aec517d3688e36053095095779381edc3227d9d2e`
- Held Stage 4 QMD:
  `628b3f4dc54180180477d248cbb329a5fba6c92dc01190452efda47a80ff3475`
- Held Stage 4 HTML:
  `c32f4a20da7533e1ae722b0bbad6b4e822889ac14bbbddf0ef0303a8ea1e9f3f`

No Quarto, Pandoc, candidate regeneration, source edit, scientific
computation, Stage 4 action, package or lockfile change, commit, push, or
upload is authorized. The sole order-50 render remains consumed. Stage 4
remains held pending independent Stage 3 acceptance.
