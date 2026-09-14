# REPORT-017 H01 order-32a four-failure disposition

Date: 2026-08-15

Status: coordinator-approved final consolidated verifier correction

## Shared cause for three empty-difference failures

`multiset_difference()` currently returns the result of `unlist(...)`. When its selected list is empty, base R returns `NULL`. The three affected contracts compare the result with an empty character vector, so `identical(NULL, character())` is false even though the printed expected and observed summaries match.

R 4.6.1 verification showed:

```text
old empty typeof NULL length 0 is.null TRUE identical.character FALSE
new empty typeof character length 0 is.null FALSE identical.character TRUE
```

Wrapping the existing `unlist(...)` result in `as.character(...)` preserves every nonempty returned value and canonicalizes only the zero-length type.

## Technical SHA label versus scientific number

The companion prose-token audit contains 41 baseline and 42 current tokens under the old broad regular expression. The exact multiset delta is one occurrence of `256`. It comes only from the approved technical label `SHA-256`, not from an estimate, interval, p-value, sample size, threshold, formula, or claim.

At the start of `extract_numeric_tokens()`, replacing exact literal `SHA-256` with `SHA` in the local audit string excludes the identifier before numeric-token extraction. It does not edit the QMD. R 4.6.1 then produces 39 versus 39 exact scientific numeric tokens.

## Final correction

Copy the order-32a verifier into a new evidence directory and make exactly these two classification changes:

1. return `as.character(unlist(...))` from `multiset_difference()`; and
2. add `text <- gsub("SHA-256", "SHA", text, fixed = TRUE)` as the first statement in `extract_numeric_tokens()`.

No source, test, manifest, historical evidence, or scientific artifact may change. Run the complete verifier once and stop after its sealed result.
