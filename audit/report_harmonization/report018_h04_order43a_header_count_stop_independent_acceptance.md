# REPORT-018 H04 order 43a header-count stop: independent acceptance

Date: 2026-08-20

Disposition: **ACCEPTED AS A STATIC-CHECKER COUNT-DEFINITION STOP.** No H04
document or table-semantics defect is established.

## Independent verification

The order-43a owner package is exact, unique, and non-circular. The temporary
Ruby 2.6 verifier contains only the authorized compatibility changes and
reverses byte-for-byte to the original order-43 verifier. It parsed under
Ruby 2.6.10 and was invoked exactly once. No render, helper, R test, semantic
hook, server, or project mutation occurred.

The single verifier stopped because it compared two different counts:

- the semantic hook summary and ledger record 1,146 `headers` attribute
  rewrites; and
- the final DOM contains those same 1,146 `headers` attributes, whose
  whitespace-separated values contain 1,968 individual header-ID tokens.

Independent parsing of all 37 native gt tables finds 1,968 header-ID tokens,
275 distinct referenced IDs, and zero tokens that fail to resolve exactly once
to a `th` element inside their own table. The final HTML has zero duplicate
document IDs. The count evidence is sealed in
`audit/report_harmonization/report018_h04_order43a_header_count_audit.csv`.

The verifier's line-125 requirement `header_tokens == 1146` therefore compares
the DOM token count to the semantic hook's attribute-mutation count. This is a
QA-harness classification error, not a weakening opportunity and not an
accessibility failure.

## Disposition

One final no-rerender continuation may copy the accepted Ruby 2.6 verifier and
change only the token-count expectation from 1,146 to 1,968 in its assertion
and static summary, plus clarify its terminal status message to report both
1,146 attributes and 1,968 tokens. The separate semantic-summary assertion for
1,146 must remain unchanged. All resolution and fail-closed checks must remain
unchanged.

The corrected verifier may run exactly once. Secure-loopback visual QA may
start only after it passes every remaining static gate. No Quarto command,
source or HTML edit, helper or R test execution, scientific computation,
artifact regeneration, profile or ledger edit, package or lockfile change,
commit, push, upload, deletion, or later-target release is authorized.
