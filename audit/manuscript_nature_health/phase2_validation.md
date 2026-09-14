# Nature Health Phase 2 manuscript validation

Date: 2026-08-13  
Status: PASS for complete narrative-draft author review  
Scope: task-owned Nature Health manuscript only

## Outcome

The complete provisional Article narrative renders successfully and passes the structural, citation, paragraph-source and protected-number checks required for the Phase 2 author-review gate. This validation does not lock the title, abstract, author list, figures, tables, declarations or submission package.

No accepted analysis, data object or shared reader report was executed or modified. Quarto execution was disabled, and only the manuscript source was rendered.

## Environment and commands

- R: 4.6.1 (2026-06-24)
- Quarto: 1.9.37
- Manuscript render:

```text
quarto render ZaunerEtAl2026_NatHealth.qmd --to html
```

- Structural and scientific-reporting validation:

```text
Rscript --vanilla tests/manuscript_nature_health/validate_phase2.R .
```

## Validation results

```text
R version: 4.6.1
Abstract: 135 words
Introduction: 406 words
Results: 1678 words in 6 sections
Discussion: 920 words and no subheadings
Main text: 3004 words
Methods: 2134 words in 14 sections
Audited paragraphs: 55
Protected-number rows: 38
Resolved citation keys: 28
Rendered HTML bytes: 1964952
Phase 2 manuscript validation: PASS
```

The main-text count covers the unheaded Introduction, Results and Discussion. It excludes the abstract, author-review callout, Methods and References, matching the journal's stated Article limit definition.

## Checks performed

- exact R 4.6.1 validation environment;
- Quarto execution disabled and no executable chunks in the manuscript;
- unheaded Introduction followed by Results, Discussion, Methods and References;
- six approved topical Results sections;
- no Discussion subheadings;
- topical Methods structure;
- abstract at or below 150 words;
- main text at or below 4,000 words;
- 55 unique paragraph identifiers matched exactly to 55 claim-audit rows;
- three provisional author-input paragraphs retained for ethics and engagement, data and code availability, and AI-assistance details;
- all protected-number rows resolved to an abstract or manuscript paragraph;
- all 28 citation keys resolved across the project and task-owned bibliographies;
- verified five-author metadata and DOI for the public wearing-position preprint;
- exact Brown numerator, denominator, percentage and interpretive strings retained;
- near-eye, chest, paired and bedside sleep-environment sample meanings retained;
- recruitment-feasibility wording retained without analytical-eligibility framing;
- no em dash, prohibited rhetorical term, internal hypothesis label or workflow identifier in the reader-facing source;
- no final figure or table cross-reference assigned before output-role approval;
- rendered HTML newer than all manuscript inputs;
- expected HTML title and section headings present;
- placement-preprint DOI present in the rendered reference list; and
- rendered citation-warning scan clear.

## Render and visual-review boundary

The manuscript-only HTML render completed successfully at:

`manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth.html`

An attempted local visual inspection through the in-app Browser could not open the `file:` URL because that browser surface blocks local-file navigation. The browser skill explicitly disallowed alternate browser surfaces or security-policy workarounds. Structural HTML checks passed, but author visual inspection of the linked local HTML remains the appropriate visual gate for this draft.

This limitation concerns visual inspection only. It does not affect citation resolution, source traceability, word counts or manuscript structure.

## SHA-256 identities

| Artifact | SHA-256 |
|---|---|
| `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth.qmd` | `c27101300061d7e75d9fa5aecd98cb4d0630db01de6e45b842d216af5eed3138` |
| `manuscript/R0_NatHealth/references_additional.bib` | `21f72db088d3463e2b3035bad05d28dc20bf61faf048531e3987c1e97845a554` |
| `manuscript/R0_NatHealth/supplementary_information_outline.qmd` | `14626f8093aac6531285404e7ab376905bd7b268057f5f0b7273a1378274c443` |
| `manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth.html` | `f7dfc612295aacdc60e8805ae446b0390eb46d560a8407d097a6f0ae636e7791` |
| `audit/manuscript_nature_health/phase2_paragraph_claim_audit.csv` | `bf89e28adcdc2aef5a3bf8619c2dd0f35633aae849c23fae9a11654d4c774773` |
| `audit/manuscript_nature_health/phase2_protected_number_audit.csv` | `ed55dd60d5f574ba8e9e907f0c08d6ffd88e610bcf1f10b3a9c9142b9fefdbe9` |
| `audit/manuscript_nature_health/phase2_clarity_changes.md` | `50a5631d25a194f64ca329e148878c08a058e8d35b8b64b427357b77a2c9a610` |
| `tests/manuscript_nature_health/validate_phase2.R` | `510340360a9c5eb6f77323969737621d186027935960a4658b984df1a80e38fa` |

## Remaining Phase 2 gate

The complete narrative draft is now ready for author review. The next substantive action is section-by-section revision from author feedback. The final title and abstract, exact display calls, declarations and journal-format integration remain deliberately provisional.
