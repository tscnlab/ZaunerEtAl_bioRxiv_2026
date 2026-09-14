# Phase 2 scientific-clarity and invariant audit

Date: 2026-08-13  
Scope: complete Nature Health narrative draft  
Skill: `$clarify-scientific-writing`

## Purpose

The Nature Health draft is a newly organized manuscript built from the previous Nature Medicine submission and the complete accepted analysis corpus. It is not a sentence-by-sentence copy edit. This record distinguishes authorized reconstruction from accidental changes to scientific content.

The clarity pass applied four rules throughout:

1. define ocular light exposure and melanopic EDI for research-educated readers outside the immediate methods community;
2. lead each paragraph with its scientific function and remove workflow-centered sequencing;
3. preserve the distinction among main, complementary, exploratory, sensitivity, non-estimable and diagnostic evidence; and
4. preserve numerical values, inferential scope, uncertainty and measurement-position meaning through the claim and protected-number audits.

## Mechanical invariant check

Plain text was extracted without scientific computation:

- original: complete `manuscript/R0_NatMed/ZaunerEtAl2026_NatMed.docx`;
- revised: complete `manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth.qmd`.

The checker was run as:

```text
python3 /Users/zauner/.codex/skills/clarify-scientific-writing/scripts/check_invariants.py \
  /private/tmp/NatMed_original_plain.txt \
  /private/tmp/NatHealth_revised_plain.txt \
  --json
```

The checker correctly reported differences. Its own caution applies: this is a mechanical token comparison, and every difference requires reconciliation.

| Category | Original occurrences | Revised occurrences | Distinct removed tokens | Distinct added tokens | Disposition |
|---|---:|---:|---:|---:|---|
| Numbers | 919 | 136 | 440 | 62 | Expected reconstruction; reconciled paragraph by paragraph in the protected-number audit |
| Number-unit pairs | 143 | 54 | 81 | 19 | Expected reconstruction; accepted current units and values checked separately |
| Citation and cross-reference keys | 0 | 39 | 0 | 28 | Expected format migration from DOCX numeric citations to traceable Quarto citation keys |
| Numeric citation groups | 0 | 0 | 0 | 0 | No difference |
| Acronyms | 478 | 34 | 132 | 3 | Expected compression and terminology revision; added terms are CI, HC3 and fREML |
| Math spans | 0 | 0 | 0 | 0 | No difference |
| Explicit protected literals | 0 | 0 | 0 | 0 | No external protect-file was used because the accepted source corpus, not the legacy manuscript, controls Phase 2 values |

## Reconciliation

The large token difference is expected for four reasons.

First, the original DOCX includes legacy tables, figures, references and hypothesis-sequenced results that are not the current accepted scientific record. Second, the Nature Health draft integrates accepted analyses that postdate that submission. Third, the journal architecture requires a shorter conceptual Results narrative and moves complete detail to Methods and Supplementary Information. Fourth, the Quarto source uses citation keys rather than the DOCX's rendered numeric citations.

The differences were reconciled as follows:

- Every scientific paragraph has an entry in `phase2_paragraph_claim_audit.csv` with its exact accepted sources and required qualification.
- Every paragraph containing a substantive scientific number has an entry in `phase2_protected_number_audit.csv`.
- Current sample sizes, recommendation-context fractions, estimates, intervals, adjusted p values, thresholds, support rules and model constants were taken from accepted current reports or source tables, not copied from the legacy submission.
- Legacy-only values were omitted when they belonged to superseded analyses, legacy displays or the old hypothesis-by-hypothesis narrative. Their omission is intentional and does not make them evidence for the new paper.
- Main hourly routine evidence and complementary daily evidence remain separate.
- Near-eye, chest, paired and bedside sleep-environment meanings remain separate.
- Null, unsupported and non-estimable results are not collapsed into one category.
- The working title is conceptual. It makes no first, largest or global priority claim.

## Material clarity changes

- Reframed the paper around an international, multiscale architecture of personal ocular light exposure rather than the registered hypothesis order.
- Made the Brown recommendation contexts the principal health-relevant baseline while explicitly excluding participant-level adherence and health-effect claims.
- Defined melanopic EDI at first use and reduced unexplained specialist shorthand.
- Replaced causal or overly broad language with observational terms such as association, context, fitted difference and exposure baseline.
- Separated site and photoperiod context from immediate light-source, activity and routine associations.
- Integrated broad unsupported families, selective person-level findings and non-estimable cells into the main scientific story.
- Explained that chest sensing has both a paired analytical role and an author-confirmed recruitment-feasibility role, without enlarging the ocular-exposure sample.
- Cited the public wearing-position preprint as overlapping related work and not independent replication.
- Preserved method detail required to reproduce the accepted estimands while removing audit and workflow terminology from reader-facing prose.

## Outcome

The mechanical checker is not expected to pass as an equality test because the authorized task is a new manuscript. The scientifically controlling checks are the paragraph claim map, the protected-number audit, citation resolution and the R structural validator. No accepted scientific analysis was rerun or modified during this clarity pass.
