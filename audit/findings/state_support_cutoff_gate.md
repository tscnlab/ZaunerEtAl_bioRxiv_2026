# State-duration support-cutoff author gate

Decision ID: `STATE-005`  
Status: approved  
Date: 2026-07-30

## Question

The three state-duration metrics require a metric-specific fraction of valid
MEDI minutes within their diary-defined state window. The candidate registry
was fixed at 0.70, 0.80, and 0.90 before final metric values or hypothesis
results were calculated. The cutoff changes only whether that one metric is
estimable for a participant-day; it never removes the participant-day or its
other metrics.

The gate uses:

- the canonical Rule A participant-days;
- true-UTC minute denominators projected from the diary intervals;
- waking, pre-sleep, and bedside sleep-environment domains;
- finite MEDI minutes below the 100,000-lx operating boundary and outside
  declared waking non-wear; and
- inclusive support boundaries (`support >= cutoff`).

An unresolved diary minute anywhere in the calendar-day state domain is
classified as `incomplete_state_domain`. A complete day without the target
state is classified as `no_state_window`. Neither category can be recovered
by choosing a lower support cutoff.

## Full-cohort diagnostic

The table reports retained metric instances and the percentage of all Rule A
eligible participant-days.

| Placement | Metric domain | 70% | 80% | 90% |
|---|---|---:|---:|---:|
| Near-eye source | Wake above 250 lx | 765 (94.3%) | 714 (88.0%) | 571 (70.4%) |
| Near-eye source | Pre-sleep below 10 lx | 664 (81.9%) | 645 (79.5%) | 610 (75.2%) |
| Near-eye source | Sleep environment below 1 lx | 771 (95.1%) | 771 (95.1%) | 767 (94.6%) |
| Chest source | Wake above 250 lx | 844 (94.1%) | 798 (89.0%) | 655 (73.0%) |
| Chest source | Pre-sleep below 10 lx | 753 (83.9%) | 736 (82.1%) | 704 (78.5%) |
| Chest source | Sleep environment below 1 lx | 854 (95.2%) | 854 (95.2%) | 851 (94.9%) |

At 80%, the reason-coded non-estimable counts are:

- near-eye: 40 incomplete diary domains for each state metric; 14 additional
  days without a pre-sleep window; and 57 wake plus 112 pre-sleep instances
  below the support cutoff;
- chest: 43 incomplete diary domains for each state metric; 13 additional
  days without a pre-sleep window; and 56 wake plus 105 pre-sleep instances
  below the support cutoff; and
- no sleep-environment instance with a known sleep window falls below 80%.

Moving from 70% to 80% loses 51 near-eye and 46 chest wake instances, 19
near-eye and 17 chest pre-sleep instances, and no sleep-environment
instances. Moving from 80% to 90% loses a further 143 instances in each wake
stream, 35 near-eye and 32 chest pre-sleep instances, and four near-eye plus
three chest sleep-environment instances.

Site-stratified retention and participant counts are stored in
`artifacts/05_metrics/state_support_candidate_by_site.csv`. At 80%, all sites
and all but the explicitly reason-coded participants remain represented in
each applicable placement-metric combination. Retention is lowest for the
pre-sleep metric at THUAS, where the 80% rule retains 50/78 near-eye and
64/94 chest participant-days; this heterogeneity will be carried into
site/common-sample sensitivity reporting rather than hidden.

## Approved treatment

The author approved 0.80 as the primary state-window cutoff and 0.70 and 0.90
as fixed sensitivities.

This recommendation is based on construct support rather than downstream
effect estimates:

1. it matches the already adopted 80% daily-support standard without making
   the state metric a new day-level inclusion rule;
2. a missing half-hour ordinarily remains acceptable for the long wake and
   sleep windows and often for pre-sleep, while very poorly supported short
   windows do not receive a duration estimate;
3. 70% gains relatively few pre-sleep instances and no sleep-environment
   instances compared with 80%; and
4. 90% disproportionately removes wake observations while barely changing
   sleep-environment support.

At the time of approval, no state-duration value, model, p-value, or
substantive result had been calculated with a final cutoff. The final
Preparation 04 run must record 0.80 explicitly and the sensitivity registry
must retain 0.70 and 0.90.

## Verification

The full R 4.6.1 gate produced:

- 5,124 daily diagnostic rows: three metrics for each of 811 near-eye and 897
  chest Rule A participant-days;
- 18 placement-metric-cutoff summaries;
- 153 site-stratified summaries; and
- four manifest-listed artifacts with exact bytewise SHA-256, byte-count, row,
  and column agreement.

Regression tests reject altered or incomplete candidate registries, assert
inclusive exact boundaries, require explicit complete logical diary-domain
status, validate state/domain/failure-reason consistency, and reconcile every
candidate classification to its eligible denominator.

An independent verifier that does not call the gate's support or
classification helpers reconstructed all 5,124 daily rows, 18 overall
summaries, and 153 site summaries exactly. It also verified the Rule A
settings, interval provenance, half-open true-UTC state projection, manifest
hashes and dimensions, input immutability, and absence of L5. Deliberate
cutoff-registry, completeness, count, and hash corruptions were detected under
warnings-as-errors.

Evidence:

- `scripts/pipeline/metric_derivation.R`;
- `scripts/pipeline/build_metric_derivation.R`;
- `scripts/pipeline/verify_state_support_gate_artifacts.R`;
- `tests/test_build_metric_derivation.R`;
- `tests/test_verify_state_support_gate_artifacts.R`;
- `artifacts/05_metrics/state_support_gate_daily.csv`;
- `artifacts/05_metrics/state_support_candidate_diagnostics.csv`;
- `artifacts/05_metrics/state_support_candidate_by_site.csv`; and
- `artifacts/12_manifests/state_support_gate_artifacts.csv`.
