# REPORT-018 H06_daily order 48a render startup stop

Date: 2026-08-21

Status: `FAIL_CLOSED_PROFILE_STARTUP_LOOP`

The complete pre-render gate passed, and the six validated display files were promoted once with recoverable preimages. The sole authorized normal-profile Quarto invocation then entered an R startup loop before knitr.

Exact command: `GT_HTML_SEMANTIC_AUDIT_DIR=/private/tmp/H06_daily-order48a-semantic.T6899t quarto render notebooks/hypotheses/H06_daily.qmd --profile nathealth`.

Observed elapsed time: approximately 12 minutes; the R child was observed active for 11 minutes 33 seconds at the final stack sample and was interrupted immediately afterward.

The sealed stack sample places the R child in `R_LoadProfile`; `do_dircreate -> mkdir` occupied 656 of 708 sampled main-thread observations. Stack SHA-256: `c31dbd454c9ec8887728d49ec9019231ffbd6a0752c54eced6ef191525e4341a`.

No knitr, Pandoc, semantic-hook, or new-HTML artifact occurred. The semantic directory is empty and the stopped HTML remains exact at `15c537269ac0be96ce06c6b574946dc0b98d46afe36c3c696f804a216a7d0c76`.

The 846 build members and 3,369 protected members from the pre-render inventories are byte-identical. All six promoted display identities remain exact. Quarto, Deno, and R process IDs 5083, 5097, and 5106 were terminated and a read-only process check returned no rows.

No retry, profile bypass, patch, or further mutation was performed. A separate environment-only restart amendment is required.
