# REPORT-018 H06_daily order 48b post-render verifier stop

Date: 2026-08-21

Status: **FAIL_CLOSED_VERIFIER_CARDINALITY_BUG_AFTER_SUCCESSFUL_RENDER**

## Verdict

The sole environment-startup retry succeeded. The unchanged H06_daily result
target completed knitr, Pandoc, and the configured semantic hook under the
normal `nathealth` profile. The hook reported `REPAIRED` for all 14 native gt
tables and wrote durable reversal evidence.

The accepted post-render verifier then stopped before page reconciliation and
visual QA with:

```text
Error: The rendered document has no unique main element.
```

This is a verifier-only cardinality defect, not a page defect. Both the
pre-hook and post-hook documents contain exactly one
`main#quarto-document-content` according to `rvest::html_elements()` and the
equivalent XPath query. The verifier instead applies `length()` to the single
`xml_node` returned by `rvest::html_element()`. In this document that length is
two because the node has two child elements. The failing condition is at
`tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R:1212`.

No verifier patch, second render, profile bypass, page QA, loopback server, or
browser inspection was performed. The rendered HTML and semantic evidence are
preserved for central disposition.

## Exact execution boundary

The one authorized elevated invocation was:

```text
GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H06_daily-order48b-semantic.SbpRAI quarto render notebooks/hypotheses/H06_daily.qmd --profile nathealth
```

It exited 0 after approximately 108.71 wall-clock seconds across the command
session. The fresh semantic directory was empty before execution and had mode
0700. The normal `.Rprofile`, `renv/activate.R`, R 4.6.1, Quarto 1.9.37,
project profile, and configured hook were retained.

The post-render verifier invocation was:

```text
NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 ORDER48A_VERIFY_PHASE=postrender GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H06_daily-order48b-semantic.SbpRAI R --vanilla --slave -f tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R
```

It exited 1 at the main-element cardinality assertion. The semantic reverse
and forward checks had already passed exactly before that assertion.

## Preserved state

- Final HTML SHA-256:
  `74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c`
  (11,946,551 bytes).
- Pre-hook HTML SHA-256:
  `460c888a361a0d5f74219b5c19b1e7a2c274aa6580397c89545727a735133bbb`
  (11,916,054 bytes).
- Semantic disposition: `REPAIRED`, with 14 tables, 113 ID repairs, 705
  `headers` repairs, and 818 total substitutions.
- Semantic ledger SHA-256:
  `09fde59b3495da6e3bac7b6e0d389d09fa7ded61c5a5c72283913945e4ea310e`.
- Semantic summary SHA-256:
  `bafde8ff09dda671e725d72adfa458f58bd599cba41a6881ed5a75862c9a917a`.
- Semantic reversal audit SHA-256:
  `ad34e4bd128448d90354bdb65d527a0681648d71f6c53c578804b4993fc85e2c`.
- The six promoted display files and unchanged Figure 5 retain their accepted
  identities.
- A live 3,369-row protected-member recheck found 3,368 unchanged members and
  exactly one authorized change, the result HTML. There were zero unexpected
  protected changes.
- The earlier failed semantic directory
  `/private/tmp/H06_daily-order48a-semantic.T6899t` remains present and empty.
- The Quarto, Pandoc, and semantic-hook processes are absent after completion.
  No loopback listener was started.

## Required next disposition

Remain stopped. A central amendment is required before correcting the verifier
cardinality assertion or continuing the post-render and visual acceptance
checks. The preserved HTML must not be rerendered merely to repair this
verifier-only defect.
