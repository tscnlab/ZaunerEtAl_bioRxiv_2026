# H04 manuscript Figure 3 author revision completion

Date: 2026-08-31  
Status: **PASS, ISOLATED CANDIDATE ACCEPTED**

## Accepted candidate

Candidate root:

`/private/tmp/h04_manuscript_figure3_final_candidate.vfKDhx`

- PNG SHA-256: `94a694d6b022fd3019b3c7beb0b33db3b3ecce5d9f38066718f321acfc7f6733`
- SVG SHA-256: `0a9d6ce92b117bf3530a07a05d7ee0ef554a61ae6110f8361e59a46965de926a`

The accepted isolated candidate uses uppercase A-D tags on the left, aligns panel D with the plot panels, preserves every category heading, moves the unchanged support lines directly beneath each heading, places each site ratio and 95% confidence interval on one line, and wraps only the four non-reference site-average comparisons immediately before `At home`.

Original-size and 170 mm visual QA found no overlap, clipping, truncation, or missing display value. All estimates, ratios, interval endpoints, FDR decisions, sample and support counts, category and site ordering, the non-estimable cell, `1/k` weighting, source-model flag, colors, scales, and panel content remain reconciled to the frozen sources.

## Verifier continuation

The continuation verifier differs from the stopped verifier only in its fresh evidence subdirectory and the exact uppercase-S literal `Site-average estimates`. Reversing those two literals reproduced the stopped verifier byte-for-byte.

The verifier-only continuation ran exactly once under R 4.6.1 and passed all 23 gates. The candidate bytes remained identical to the hard pins before and after verification.

## Boundary

This acceptance applies only to the isolated candidate package. No canonical promotion, H04 QMD or HTML edit, Quarto run, manuscript-selection edit or render, source-data or scientific change, shared-file change, commit, push, or upload occurred.
