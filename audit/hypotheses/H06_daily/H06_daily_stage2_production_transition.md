# H06_daily Stage 2 production transition

- Gate: `H06-D-G2`
- Controlling authorization: `H06-D-013 / CHG-123`
- Date: 2026-08-12
- Status: complete; stopped for explicit author review

## Scientific role and completed scope

The hourly H06 analysis remains the frozen primary H06 analysis. This completed
H06_daily grid is complementary, preregistration-oriented participant-day
evidence. It is neither a replacement for the hourly analysis nor an
equivalence or replication analysis.

Production completed the 13 authorized non-L10 slots (1, 2, and 4--14), three
approved predictors, and twelve prespecified dataset/placement/sample roles.
All 468 fitted frames were rebuilt from the sealed current sources and matched
their frozen object identities. Timing slots 9, 10, 12, and 13 used the accepted
fixed-site `lm` route with participant-cluster HC3 covariance. The other
non-L10 slots used their approved mixed-model routes. L10 slot 3, MDER slot 15,
the temporal branch, the accepted pre-sleep no-nugget sensitivity, and main H06
were not refitted or altered.

The serial production run completed:

- 468 base cells;
- 66,664 prespecified participant/site deletion refits, of which 46 were
  non-estimable (0.069%);
- 63 triggered Tweedie AR diagnostics;
- 29 Student-t tail sensitivities;
- 18 exact-period sensitivities;
- 468 effects and 936 raw association/heterogeneity tests; and
- 468 explicit diagnostic assessments.

The forced-restart continuation resumed from 33,794 preserved influence
refits. Its initial and completion health checks found no repeated checkpoint
failure and verified all 34 input pins, five frozen main-H06 pins, and all 634
protected historical identities. A no-refit provenance repair corrected the
influence index's stale hash field after proving that all 468 influence objects
were internally valid and byte-identical; no scientific object was changed.

## Multiplicity and frozen slots

Exactly twelve dataset-qualified 15-slot Benjamini--Hochberg families were
assembled: primary and gap-timing-unaware datasets by three predictors by
association/site-heterogeneity tests. Each family uses
`stats::p.adjust(method = "BH", n = 15)`.

- L10 remains the named slot 3 with raw and adjusted p-values missing under the
  accepted component-failure disposition.
- MDER remains the frozen slot 15. Its raw tests, fitted models, effects,
  intervals, diagnostics, sensitivities, and claims are unchanged; only the
  mathematically dependent family-wide BH fields were recomputed.
- Chest and paired/common analyses remain estimation-only and do not create
  additional multiplicity families.

Across the twelve families, 80 slots have BH q < 0.05. Sixty-seven of these
cannot support an unqualified claim because the corresponding diagnostic gate
is not acceptable. Two are frozen MDER slots and retain their existing
limitations. Eleven are diagnostically eligible or eligible only with an
explicit limitation.

## Primary near-eye result disposition

Among the 39 non-L10 primary near-eye cells, four are acceptable, four are
acceptable with an explicit limitation, and 31 are not acceptable. Therefore,
the numerical estimates and pointwise 95% confidence intervals remain visible,
but a small raw or adjusted p-value never overrides a failed diagnostic gate.

Five primary association slots combine BH q < 0.05 with an acceptable or
explicitly limited diagnostic disposition:

1. Each additional hour of previous-night sleep is associated with 0.111 h
   less time below 10 lx melEDI before sleep (95% CI -0.160 to -0.062 h;
   q < 0.001; acceptable).
2. Each additional hour of previous-night sleep is associated with a 1.08-fold
   fitted duration below 1 lx melEDI during sleep (95% CI 1.07 to 1.09;
   q < 0.001), with an explicit diagnostic limitation.
3. Each additional hour of previous-night sleep is associated with 0.127 h
   later mean timing above 250 lx melEDI (95% CI 0.044 to 0.210 h; q = 0.004;
   acceptable).
4. Free days versus work days are associated with a 0.671-fold fitted melEDI
   dose (95% CI 0.559 to 0.805; q < 0.001), with an explicit diagnostic
   limitation.
5. Each additional hour of previous-night sleep is associated with a
   0.906-fold fitted melEDI dose (95% CI 0.849 to 0.967; q = 0.004;
   acceptable).

These are observational associations with recorded contexts, not causal
effects or health outcomes. The sleep-duration coefficient is centered at
8 hours but, under the approved single predictor, combines within-person and
between-person information.

The primary work/free-day melEDI-dose site-heterogeneity slot also has
q < 0.001 but requires an explicit diagnostic limitation. Timing
predictor-by-site results retain the H06-D-011 sensitivity-dependent
qualification and cannot support unqualified heterogeneity claims.

## Diagnostic limitations retained

- The accepted timing HC3 route retains the named Student-t and AR limitations,
  three unresolved additive AR checks, and the absence of a timing AR structure
  meeting the descriptive post-AR lag rule.
- Influence classifications across all 468 cells are 270 stable, 128
  substantial limitation, 46 unstable, and 24 with at least one unresolved
  non-estimable deletion refit.
- Tweedie simulation diagnostics were not run because H06-D-013 explicitly
  prohibited simulation; this remains visible in every applicable assessment.
- Continuous-period, distributional, bounds, temporal, and registered
  random-site benchmark dispositions remain metric- and frame-specific.

## V0 comparison

V0 used a different outcome construction, joint predictor formula, weighting,
and multiplicity implementation. The current participant-day estimates cannot
be mapped coefficient-for-coefficient to V0 or to the approved hourly H06
analysis. V0 significance labels, hourly ratios, site contrasts, and
"unique-variance" claims are not carried forward.

## Mandatory stop

The task is stopped at `H06-D-G2`. The author must explicitly decide whether to
accept the complete Stage 2 implementation and its qualified claim set. Stage 3
reader-report authoring and Stage 4 preparation/provenance authoring remain
separate and unauthorized. REPORT-016/CHG-126 remains independent and has not
been consumed. No shared file, main-H06 file, commit, or push is authorized.
