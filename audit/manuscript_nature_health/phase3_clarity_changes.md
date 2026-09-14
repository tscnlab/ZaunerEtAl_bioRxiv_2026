# Phase 3 scientific-clarity record

Date: 2026-08-14

The active `clarify-scientific-writing` workflow was applied to the integrated author-review revision after the evidentiary changes had been mapped. It did not adjudicate scientific support or generate numerical results. Those decisions came from the accepted reports, handoffs, author feedback and the bounded health-evidence discovery package.

## Source preservation

- The complete Phase 2 Quarto source and rendered HTML were preserved unchanged.
- The revision was created as the sibling source `ZaunerEtAl2026_NatHealth_phase3.qmd`.
- Accepted analyses, reports, ledgers, the Nature Medicine submission and the root bibliography were not edited.
- The malformed Huss title was repaired through a task-local bibliography entry rather than a shared-file edit.

## Main clarity interventions

1. The Introduction now proceeds from physiology and recommendations to population-health relevance, then to the missing multisite ocular-exposure baseline and the study aim.
2. The known existence of a daily rhythm is separated from the new contribution: its cross-site amplitude and its nested time, site, person, day and immediate-context architecture.
3. The Results treat metrics as exposure streams with distinct meanings: level, bright and dark duration, timing, dose, spectral composition, regularity and fragmentation.
4. Qualifiers are placed next to the estimand they constrain. Repeated technical exposition about interval types was removed.
5. Geographic results now say which metric streams varied, how many tests met the FDR criterion, how large selected associations were and how site contributions compared with participant-associated contributions.
6. Immediate-context sections use the supported interaction-model estimates and lead with practical melanopic EDI contrasts before model-fit allocation.
7. The main hourly and complementary participant-day analyses are distinguished in reader-facing language, with the daily mean contrast used to explain weighting and temporal composition.
8. Biological-sex wording now distinguishes the all-available profile from the activity-complete restriction and adjustment. It does not imply that the near-eye difference survived activity restriction or that activity explains a mechanism.
9. The Discussion connects the exposure baseline to observational population evidence while separating exposure context from individual adherence, disease risk and causality.
10. The Methods restore concrete protocol, measurement, questionnaire, preprocessing, metric and modelling information that had been compressed in the earlier draft.
11. The title now names the multiscale contribution without implying global representativeness. Reader-facing scope is expressed as multisite, cross-site or the exact nine-site, seven-country design.
12. The Free-versus-Work paragraph now keeps the common-site additive association distinct from the inconclusive equal-site average after allowing the association to vary by site.
13. Ethics wording now enumerates the verified local approvals, including BAuA's use of the TUM multicentre approval. The separate engagement statement remains unresolved.
14. The bibliography now restores directly relevant legacy context, data and methods sources, while the 15 remaining omissions are individually documented.
15. The exploratory light-source and activity assessments now answer the participant-variation question without displacing the primary population-mean analyses. They distinguish the participant-intercept increment from the fixed-effect allocation, state that no participant-specific category slopes were fitted and keep residual dependence and zero-mass mismatch visible. The activity Results replace the older quasi-deviance allocation with the sealed weighted mixed-model decomposition so readers are not asked to compare unlike allocation denominators.
16. The unresolved engagement placeholder now states the author-confirmed fact that no participant or community co-design occurred. It explicitly distinguishes co-design from recruitment, informed consent and study participation.
17. The complete legacy author and declaration material is restored as structured Quarto metadata and separate end-matter sections. Data and Code availability are separated as required, while final archive reconciliation, expanded AI disclosure and all-author approval remain visible future gates.

## Protected scientific meanings

- Near-eye measurement is closer to the incident ocular field during wear but is not a retinal measurement.
- Chest measurement is complementary non-ocular evidence. It is not a pooled extension of the ocular sample and is not universally convertible to near-eye exposure.
- During reported sleep, both devices describe the bedside sleep environment.
- Brown comparisons are pooled valid-minute context fractions or modelled context estimates. They are not participant-level adherence, biological response or clinical risk estimates.
- Conditional Shapley allocation is in-sample model-fit credit. It is not response variance explained, causal importance or out-of-sample predictive importance.
- The photoperiod transition is a descriptive change to a sustained near-flat fitted tail. It is not a physiological or environmental ceiling.
- Non-retained, exploratory, sensitivity and non-estimable findings remain labelled and are not converted into evidence of absence.
- Hourly and daily routine analyses have different outcomes, weighting and model structures. Neither substitutes for the other.
- Biological sex was analysed. Gender was recorded separately but was not analysed.

## Style reconciliation

- No em dash occurs in manuscript prose.
- The official punctuation in a cited article title is retained as bibliographic metadata.
- The term `destiny` is absent.
- Internal hypothesis labels, workflow identifiers and stage terminology are absent from the scientific narrative.
- Site names carry country codes in reader-facing prose.
- FDR is used reader-facing. The full Benjamini-Hochberg procedure name appears only in Methods for reproducibility.

The paragraph-level claim audit and protected-number audit were updated before rendering. Their exact reconciliation is tested by `tests/manuscript_nature_health/validate_phase3.R`.
