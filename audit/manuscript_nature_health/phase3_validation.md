# Nature Health manuscript Phase 3 validation

Date: 2026-08-14

Result: **PASS**

## Post-validation source status

After this validated render, the author clarified that the protocol-development trial participants constitute the Tübingen cohort in the present analysis rather than a separate pilot sample. The approved source-only correction now reports that their feedback informed procedural refinements before implementation at the remaining sites and cites the published protocol. The Phase 3 QMD and paragraph claim audit have therefore changed since the validated identities below, while the HTML intentionally remains unchanged. The full validation must be rerun when the accepted Brown-adherence results and approved figures are integrated.

## Render scope

- Source: `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3.qmd`
- Output: `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3.html`
- Command: `quarto render ZaunerEtAl2026_NatHealth_phase3.qmd --to html`
- Working directory: `manuscript/R0_NatHealth/`
- Quarto: 1.9.37
- Pandoc: 3.8.3
- Execution: disabled in the task-owned manuscript configuration

This was an isolated manuscript-only render. It did not use the shared Nature Health reader profile, run a full-project render or enter the REPORT-017 serial render queue.

## R validation

- R version: 4.6.1
- Command: `Rscript --vanilla tests/manuscript_nature_health/validate_phase3.R <repository-root>`
- Result: `Phase 3 manuscript validation: PASS`

| Component | Validated count |
|---|---:|
| Abstract | 145 words |
| Introduction | 480 words |
| Results | 2,715 words in 6 sections |
| Discussion | 1,196 words with no subheadings |
| Introduction, Results and Discussion | 4,391 words |
| Methods | 2,726 words in 14 sections |
| Audited manuscript paragraphs | 69 |
| Protected-number rows | 54 |
| Resolved citation keys | 90 |
| Original references retained | 83 of 98 |
| Original references dropped with reasons | 15 of 98 |
| Verified ethics-site records | 9 |
| Health-evidence candidates | 11 |
| Canonical health-evidence records | 9 |
| Rendered HTML size | 2,064,749 bytes |

The 4,391-word main-text count is within the author-approved ceiling of 4,400 words. The reference count was not capped at 60 because the author explicitly authorised reuse of the legacy references without that constraint.

## Checks passed

- Nature Health Article order: unheaded Introduction, Results, Discussion, Methods and References.
- Exactly six approved conceptual Results sections and no Discussion subheadings.
- Execution-disabled Quarto source with no executable code blocks.
- All paragraph identifiers map one-to-one to the Phase 3 claim-source audit.
- All 54 protected-number rows resolve to the abstract or their audited paragraph.
- The confirmed title-page metadata contains all 28 authors in legacy order, 14 affiliation entries, the available ORCIDs and corresponding-author metadata.
- All 90 cited keys resolve across the root and task-local bibliographies without duplicate keys.
- The crosswalk accounts for all 98 original Nature Medicine references: 83 retained and 15 dropped with a non-empty, source-specific reason. Seven current sources are new.
- The nine-row ethics matrix covers every study site and preserves Dortmund's use of the TUM multicentre approval for BAuA.
- The ethics paragraph now states the author-confirmed absence of participant or community co-design without relabelling recruitment, consent or participation as engagement.
- Separate Data and Code availability sections retain the author-confirmed current MeLiDos and analysis repositories, while leaving final archive-version reconciliation open.
- Acknowledgements, funding, contribution roles and competing interests are carried forward from the original submission with paragraph-level provenance. Duplicate initials in two contribution roles were removed, and final all-author approval remains pending.
- The title renders as *The multiscale architecture of personal light exposure*, and the manuscript uses multisite, cross-site or the exact nine-site, seven-country scope instead of an unqualified international headline.
- The Free-versus-Work result distinguishes the supported common-site additive ratio of 1.45 from the inconclusive interaction-model equal-site average of 1.15.
- The owner-approved exploratory light-source assessment reports marginal and conditional model-based R², a 0.080 participant-intercept increment, a hierarchy-respecting marginal-R² allocation, the population-mean within/between sensitivity and the retained lag-one and zero-mass qualifications. It explicitly excludes random slopes, causal shares and individual prediction.
- The sealed exploratory activity assessment at commit `2c8c097` reports both positions, a 0.092 participant-intercept increment, and the hierarchy-respecting marginal-R² allocation. It remains restricted to five named activities, uses exact fractional weights, excludes Other-only hours, and does not represent raw response variance, causal importance, participant-specific activity slopes or individual prediction. Residual correlation and zero-mass mismatch remain explicit.
- Corrected Huss reference title renders without the malformed command.
- Placement-preprint and cardiovascular-study DOIs render and resolve in the local bibliography output.
- Required roster, recommendation, temporal-architecture, effect-size, interaction, sex-and-gender, placement, recruitment and evidence-boundary statements are present.
- Health-evidence discovery contains 11 candidate rows, 9 deduplicated canonical records, 7 direct empirical and 2 contextual records, plus one linked preprint version and one correction record.
- Health evidence-matrix and discovery bibliography keys match one-to-one.
- No em dash occurs in manuscript prose. The official punctuation of the Huss title is retained only as bibliographic metadata.
- No internal hypothesis labels, workflow identifiers, prohibited rhetorical term, reader-facing `BH` abbreviation, repeated interval jargon or incorrect recruitment-eligibility wording occurs in the manuscript.
- Every reader-facing study-site use carries the applicable country code, excluding institutional and questionnaire names that contain `Munich`.
- No provisional Quarto figure or table number was locked.
- No citation-warning marker or unresolved cross-reference marker was found in the rendered HTML.

## Preservation check

The Phase 2 source and render retain their previously recorded SHA-256 identities:

- `ZaunerEtAl2026_NatHealth.qmd`: `c27101300061d7e75d9fa5aecd98cb4d0630db01de6e45b842d216af5eed3138`
- `_output/ZaunerEtAl2026_NatHealth.html`: `f7dfc612295aacdc60e8805ae446b0390eb46d560a8407d097a6f0ae636e7791`

## Remaining author and integration work

This pass validates the revised author-review draft, not a final submission manuscript. The author list, affiliations, repositories, acknowledgements, funding, contribution roles, competing interests and absence of participant or community co-design are now populated from the confirmed original-submission record. The Brown recommendation-adherence model, figure selection and numbering, final analysis archive, final AI-assistance wording and final all-author approval remain open. The author-directed sequence is to integrate the accepted Brown results and approved figures, return the manuscript for a lead-author write-over, and perform the final overview only after that rewritten manuscript is handed back. The coordinator confirmed that the manuscript's sex-and-gender wording is evidence-supported; the related shared-reader correction remains outside this manuscript task.
