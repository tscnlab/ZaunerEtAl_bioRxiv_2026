# Sensor-placement decision

Decision ID: `PLACEMENT-001`  
Status: approved for implementation  
Decision date: 2026-07-29  
Scope: primary exposure construct, sample use, placement comparisons, and manuscript reporting  
Primary evidence: [`../evidence/placement_paper_reading_notes.md`](../evidence/placement_paper_reading_notes.md)  
Companion source: <https://github.com/tscnlab/ZaunerDeVriesEtAl_JExpoSciEnvironEpidemiol_2026>  
Audited PDF SHA-256: `9cf8309c753d6ad753ac1d772927996d1035f59dadfa3b62523a810897ca67e3`

## Decision

Simple pooling of glasses- and chest-position observations with only a fixed
`position` term is rejected.

Near-eye measurements remain the primary basis for ocular light-exposure
estimands. Chest measurements will be used as structured complementary
evidence, prioritising paired/common-sample comparisons and preserving
participant and participant-day dependence.

The project-defined L10 metric is retained, subject to the same coverage,
gap-handling, state, and interpretability criteria applied to every other
metric.

## Rationale

The two positions cannot be assumed to measure the ocular-exposure construct
interchangeably. The companion placement manuscript reports:

- nominal placement differences for 19 of 54 metrics;
- nominal site-by-placement differences for 12 of 54 metrics;
- context-, participant-, and participant-day-dependent variability;
- relatively greater robustness for timing metrics; and
- less robust level and temporal-dynamics metrics.

Those p-values are exploratory and unadjusted. They are used here to reject an
unsupported invariance assumption, not as confirmatory tests and not as part
of this study's preregistered multiplicity families.

Placement availability is also site-confounded: Tübingen has no chest
measurements and Costa Rica has sparse glasses measurements. Adding a single
position coefficient would not, by itself, identify site and placement
effects or convert chest observations into additional independent near-eye
observations.

## Implementation constraints

1. The primary analysis must use near-eye data and report its own participant,
   participant-day, and observation flow.
2. Chest results must be labelled complementary or sensitivity evidence, not
   a larger primary ocular sample.
3. Direct position comparisons should use paired/common samples where
   possible and explicitly model participant and participant-day pairing.
4. Relevant position-by-site, position-by-context, or
   position-by-predictor heterogeneity must be checked when a placement
   comparison is reported.
5. Primary glasses estimates and complementary chest estimates must be shown
   on practical scales with intervals and scenario-specific sample flow.
6. No universal chest-to-glasses correction, latent calibration, or
   measurement-error model will be introduced under this decision.
7. Sleep-period values must be described as bedside sleep-environment
   measurements, because devices are not worn at their nominal glasses and
   chest positions during sleep.
8. L10 remains eligible only if the metric-validity audit confirms that its
   temporal window, coverage, and gap handling preserve its intended meaning.

## Reopening conditions

This decision may be reopened only as a major gate if all of the following are
available before examining pooled conclusions:

- a clearly defined common construct and unit for both positions;
- a defensible outcome-specific equivalence margin;
- paired evidence that excludes practically material level, timing, context,
  and site-dependent bias;
- comparable coverage and missingness;
- identifiable site and placement effects;
- a model that represents participant and participant-day pairing and
  relevant placement interactions; and
- agreement between pooled and glasses-only estimates on an explicit common
  sample.

Absent those conditions, pooling remains rejected.

## Publication handling

No public preprint was found at the last check on 2026-07-29. Until a public
version is verified, the companion manuscript will be disclosed as related
submitted/unpublished work in the cover letter and will not receive a
numbered placeholder citation.

