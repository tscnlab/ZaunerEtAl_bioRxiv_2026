# Author-approved title and framing checkpoint

Date: 2026-09-11. Task: Nature Health manuscript writer, same shared checkout.

## Authority and scope

The author approved the PI title and the accompanying manuscript-framing suggestions, rejected the less technical replacement abstract, and allowed lighter language within the existing abstract, explicitly suggesting day length instead of civil-photoperiod.

The coordinator acknowledged this as a bounded source-only editorial update. This checkpoint does not release a render, Word save, display repair, analysis change or Brown-linkage update. Historical proposals remain historical. In particular, neither the 134-word nor the later 139-word replacement abstract was substituted.

The approved title is **The health-relevant architecture of the everyday light exposome**.

Current manuscript source: `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd`.

- Before SHA-256: `bda9f4ad9c974c6e23cc358d687cc05848df06b5c614f6f564c07c46dee71d09`.
- Completed source checkpoint SHA-256: `c6beb79ca34128c0b69d882c1e3ea332cb88664ce9a3c0883b39d1569db0a0d0`.
- Local immutable copies: `source_before.qmd` and `source_after.qmd`.
- Focused comparison: `focused_source.diff`, SHA-256 `2eb983656e10693af42c9f8b073db74c0976208539efbedfb0fb8eba1515d68d`.

## Material-change ledger

| Location | Action | Reader obstacle and editorial operation | Preserved scope and evidence |
|---|---|---|---|
| Title | Author-approved replacement | Connect the multiscale study to its health-relevant everyday light-exposome component. | No measured health outcome, lifetime coverage, global representativeness or causal-health claim is added. |
| Abstract | Tighten | Replace only the sentence about site, civil-photoperiod and person-level associations with: “Associations with site, day length and personal characteristics differed across exposure measures.” | All numerical details, the full-model R² denominator, separate fitted-hourly-pattern denominator, sample/placement distinctions and other sentences remain exact. The replacement abstract was rejected and not used. |
| P-I02 | Add bridge; tighten | Identify time-resolved ocular melanopic light as the everyday exposome component examined here. Shorten the following wrist/bedside sentence without removing its proxy limitation. | The life-course definition, all cited population-health literature, association language and the wrist/bedside proxy boundary remain. This does not claim life-course measurement. Existing paragraph authority: NH-P3-002; existing exposome references `vineis2018` and `vermeulen2020`. |
| P-I04 | Add bridge; consolidate | Explain architecture across time, sites, people, days and immediate settings, and its recommendation-based benchmark. Consolidate the preceding repeated component list into temporal, environmental, routine and selected person-level contributions. | The nine-site/seven-country scope, harmonised protocol citations, near-eye versus complementary non-ocular chest interpretation, recruitment role, non-global scope and future harmonised sampling across locations, photoperiods, latitudes and climates remain. Existing authority: NH-P3-004. |
| P-D01 | Add bridge; tighten | Describe the advance as a multiscale account of an everyday exposome component, while tightening repeated introductory and synthesis wording. | The expected rhythm, amplitude, immediate-setting organisation, model-specific rankings and explicit qualitative rather than single quantitative synthesis are retained. Existing authority: NH-P3-027. |
| P-D09 | Add bridge; tighten | Relate the nine-site reference to the everyday light exposome and recommendation-based monitoring. Remove surplus transitional words. | Within-site people/day variation, future-cohort information, geographic limits, prospective health linkage, intervention/longitudinal requirements and the final environmental-health relevance remain. Existing authority: NH-P3-036. |
| P-M14 | Add bridge | Add the parenthesis “day length including civil twilight” after civil photoperiod, connecting the accessible abstract wording to the operational quantity. | This is a definition gloss only, not a change from civil dawn/dusk to sunrise/sunset or a different exposure variable. The rest of the paragraph is byte-identical. |
| P-D08 | Retain | Preserve the complete limitation paragraph unchanged. | “Finally, no health outcome was measured.” remains exact, together with all other limitations and citations. |

The definition gloss follows the existing site/solar-context implementation and its documented display definition. Read-only source inspection found “civil dawn to civil dusk at solar altitude -6 degrees” in `scripts/pipeline/prepared_day_showcase.R`, line 890, SHA-256 `d77ca354f9bc927c293a5160194c481343f8e14cfc014a9e6985f70694db1ba0`. Related implementation: `scripts/pipeline/site_solar_context.R`, SHA-256 `553632348d8681d99962024d465c4ad85ac2686742caa1d80c36a6633328829f`. Neither script was run or changed. This is a terminology lookup, not an analytical verification.

## Preservation and length checks

The source-only structural check passed 25/25 checks. The clarity checker reports no protected-token differences: all 609 numeric tokens, 196 number-unit pairs, 130 citation/cross-reference tokens and 194 acronym tokens match. Ordered numbers and citation/cross-reference tokens also match, not merely their counts.

Every Results paragraph is unchanged. The Brown Methods paragraphs and model-scale definitions in P-M13 and P-M16 are unchanged. No figure, table, caption, image include, bibliography, author, affiliation, declaration, section heading or other out-of-scope source byte was altered. The only front-matter change is the title. All paragraph identifiers and their order are retained. No em dash was added.

The abstract is 149 words, compared with 147 before. All original numerical findings remain. Introduction, Results and Discussion remain at 4,500 words under the existing project convention, which excludes citation keys and Markdown display-call links. A conservative count retaining visible display-call labels is 4,551 both before and after. The framing additions were offset by meaning-preserving tightening within the four authorised Introduction/Discussion paragraphs; no other section was shortened. This records the counting convention explicitly rather than treating it as a journal-certified word count.

The bibliography, reference Word document, production HTML and DOCX, stopped Order72d Word candidate and stopped-manifest identities were checked and remain exact. Existing Word/HTML files do not yet contain this editorial checkpoint.

## Reproduction

This was a non-analytical source-editing and structural-check operation. No R model, scientific table, estimate, interval, p-value, diagnostic, Shapley allocation or participant data was recalculated.

Run the focused read-only check from the repository root:

```sh
/Users/zauner/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 tests/manuscript_nature_health/verify_title_framing_2026_09_11.py
```

Its recorded output is `structural_validation.json`. Python is used only for text, token and checksum inspection, not scientific computation. The completed verification script is SHA-256 `b566f525915f8d31a162abc2a064c4f05726c98d347a4a9f7911561386f3e664`.

Active skills used: `clarify-scientific-writing` for the minimal rewrite and invariant check; `quarto-authoring` for applying approved changes to the source. The author explicitly approved changing the QMD; the unmodified preimage is retained. The render requirement remains deferred under the coordinated display hold.

Unresolved author questions for this source-only change: none. Display/Word repairs and the Brown-linkage work retain their separate existing boundaries.
