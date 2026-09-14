# H04 manuscript Figure 3 author revision

Date: 2026-08-31  
Status: **FAIL-CLOSED AFTER THE SOLE RELEASED VERIFIER INVOCATION**

## Candidate

The final isolated candidate is stored at:

`/private/tmp/h04_manuscript_figure3_final_candidate.vfKDhx`

The candidate implements the authorized display-only revision:

- uppercase A, B, C, and D tags at the left of their panels;
- panel D aligned with the plot-panel left edge;
- unchanged category headings with the unchanged three support lines moved directly beneath them;
- every site ratio followed on the same line by its 95% confidence interval in parentheses;
- the four non-reference site-average comparisons wrapped immediately before `At home`; and
- a caption that explains the 95% confidence intervals and uses bold uppercase panel references.

Original-size and 170 mm visual QA passed with no overlap, clipping, truncation, or missing display value. The preceding overlapping revision remains unchanged at `/private/tmp/h04_manuscript_figure3_author_revision.v6H83P`.

## Verifier result

The namespace-safe verifier was invoked exactly once under R 4.6.1. It recorded 22 passing gates and one failing gate. All frozen-input, output-identity, source-value, frame, category, site, interval, FDR, estimability, temporal SVG, decoded-pixel, uppercase-tag, panel-D geometry, and dimension gates passed.

`reader_language_and_frame_note` failed only because its exact case-sensitive token is `site-average estimates`, whereas the candidate visibly contains the sentence-initial form `Site-average estimates`. Static decomposition confirms that every other constituent condition passes, including all seven frame tokens, the activity-by-site interaction-model wording, `1/k`, all four bold uppercase caption tags, the 95% confidence-interval explanation, and the exclusion of `heterogeneity model` and internal H04 labels.

No candidate or verifier patch and no second invocation were made after this result. Formal acceptance is withheld pending a central verifier-only continuation that treats this capitalization difference correctly.

## Preservation boundary

No canonical artifact, H04 QMD or HTML, Quarto target, manuscript selection, source data, scientific calculation, shared manifest, configuration, ledger, commit, push, or upload was changed or executed.
