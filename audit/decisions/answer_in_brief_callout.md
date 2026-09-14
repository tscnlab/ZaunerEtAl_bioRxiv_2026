# Answer-in-brief callout

Decision ID: `REPORT-012`  
Date: 2026-08-01  
Status: approved

## Decision

Every standalone reader-facing hypothesis report contains a compact
**Answer in brief** note directly after its hypothesis-and-analytical-question
section. This applies to H01, H02, H05, and every future H03--H11 Stage 3
report.

The callout gives an ordinary scientific reader the shortest accurate account
of the accepted result before the detailed methods, tables, figures, and
diagnostics. It normally contains two to four sentences and states:

1. the primary near-eye result and whether the declared inferential rule was
   met;
2. the practical direction or magnitude with a 95% confidence interval when
   a compact consequential estimate exists;
3. whether complementary chest evidence agrees materially; and
4. whether the gap-timing-unaware or another central sensitivity changes the
   conclusion.

Only verified results already shown and sourced elsewhere in the report may
appear. The callout does not introduce a new analysis, omit multiplicity
qualification, convert an inconclusive result into evidence of no effect, or
replace the full result and diagnostic sections. When no single effect size is
scientifically valid, it summarizes the global or pattern-level conclusion
without inventing one.

Use a Quarto note callout with the visible title **Answer in brief**. Keep it
compact and in familiar manuscript language; do not mention V0, workflow
stages, internal artifact names, approvals, or construction history.

## Existing reports

H02 and H05 already satisfy the rule and are the accepted exemplars. H01
implements it at its current Stage 3 reporting touchpoint. Future Stage 3
reports must use the exact visible title **Answer in brief**. Applying the rule
does not authorize refitting, prediction, diagnostic recomputation,
resampling, simulation, or a change to an accepted claim.

## Reopening condition

Reopen this decision if the callout cannot accurately summarize a hypothesis
without materially omitting the inferential qualification, or if its content
conflicts with the verified detailed report.
