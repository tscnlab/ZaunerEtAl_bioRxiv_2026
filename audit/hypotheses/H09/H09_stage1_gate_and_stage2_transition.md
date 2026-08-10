# H09 Stage 1 gate and Stage 2 transition

Decision ID: `H09-001`
Date: 2026-08-07
Status: **approved**

## Evidence approved

The owner approved the complete H09 Stage 1 package in the H09 task after
review of:

- `audit/hypotheses/H09/01_audit_and_plan.qmd`, SHA-256
  `e6ff16937c01e37b5e7b0b43269c7860344bbd4abd11b2c060f53c52fbe7a892`;
- `audit/hypotheses/H09/01_audit_and_plan.html`, SHA-256
  `aa833ff2c8aabaf9cecf9cb71872c2e06d9f9e29e62283f74fa62e8f679c79c3`;
- the V0 reconstruction, prepared-input audit, candidate samples, model
  formulas, diagnostics, sensitivities, multiplicity families, and output
  contract displayed there; and
- H09-G1 through H09-G16 as displayed in the rendered Stage 1 report.

## Explicit H09-G4 resolution

The owner explicitly accepts the pinned upstream aggregate calculated fields
for both chronotype instruments:

- MCTQ corrected midsleep on free days, field `msf_sc`; and
- MEQ score, field `meq`.

These accepted fields remain distinct constructs, predictors, models, and
multiplicity families. The acceptance permits H09 fitting without item-level
questionnaire reconstruction. It does not establish item-level scoring
provenance, validate an unobserved questionnaire version or missing-item rule,
or permit either registered instrument to be omitted.

## Approved Stage 2 contract

1. MCTQ and MEQ are analysed separately across the five registered timing
   outcomes. Near-eye all-available data are primary and chest all-available
   data are complementary.
2. The fifth primary outcome is the exact-identifiable midpoint of the
   selected longest continuous period above 250 lx melEDI. Mean timing above
   250 lx melEDI remains a separately labelled adapted sensitivity; the two
   estimands are not interchangeable.
3. H09 may construct the registered midpoint in H09-owned code from the
   approved Preparation 06 selected-period onset, offset, time-zone, and
   exact-identifiability fields. It must not create or alter a shared metric,
   crosswalk, registry, or preparation artifact.
4. The current Preparation 06 base-model inputs are governed by
   `PREP06-BASE-002`. H09 must verify the pinned current identities before
   fitting and carry the open `PREP-003`/`FIND-044` reconstruction limitation
   without implying that all current metrics were independently reconstructed.
5. The gap-timing-unaware artifact lacks the registered midpoint and its
   endpoints. That fifth sensitivity member remains unavailable unless a
   coordinator-owned artifact is supplied; H09 must not fabricate it. The
   four available registered members remain in five-member families with the
   non-estimable member explicit, while the adapted mean-timing outcome is
   reported separately.
6. Primary association tests compare site-only M0 with site-plus-chronotype
   M1 on one fixed model frame; reported main estimates come from the declared
   site-adjusted M1. M1-versus-M2 interaction tests address site heterogeneity
   separately. Explicit sum contrasts and the approved fixed centring/scaling
   are required.
7. H09-F1 (MCTQ main), H09-F2 (MEQ main), H09-F3 (MCTQ-by-site), and H09-F4
   (MEQ-by-site) are separate five-member Benjamini-Hochberg families.
   Site-specific trends remain descriptive; H09-F5 is not activated.
8. Linear clock treatment, the strict greater-than-16:00 negative-hour L10
   conversion, photoperiod sensitivity, participant-summary sensitivity,
   continuous-time AR(1) sensitivity, participant influence, leave-one-site-
   out checks, exact paired/common samples, and diagnostic release gates
   follow the displayed Stage 1 specification.
9. Near-eye and chest are not pooled. Placement evidence does not establish
   equivalence without a prespecified defensible margin.
10. Stage 2 reports exact fitted samples, 95% confidence intervals, complete
    vector-wide multiplicity, interpreted acceptable/not-acceptable
    diagnostics, the gap-timing-unaware sensitivity, V0 comparisons, paired
    source-data CSVs, and final-size figure inspection.
11. No temperature or unsupported predictor may be introduced. No production
    resampling may run without the approved 50- or 100-replicate pilot gate.
12. Stage 2 stops for explicit owner approval before Stage 3.

## Reopening condition

Reopen the H09 Stage 1 gate if the chronotype constructs, fifth primary
outcome, exact-period rule, clock representation, site or participant
structure, placement hierarchy, model comparison, multiplicity family,
diagnostic release rule, or sensitivity role changes, or if the approved
contract cannot be fitted and interpreted without a scientific amendment.
