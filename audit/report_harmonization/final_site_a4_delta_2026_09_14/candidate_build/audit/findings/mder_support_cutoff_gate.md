# MDER support-cutoff author gate

Decision ID: `METRIC-003`  
Status: approved; canonical Preparation 04 rerun pending  
Date: 2026-07-30

## Question

The melanopic daylight efficacy ratio (MDER) is retained as the ratio of
MEDI and photopic-illuminance integrals over identical paired valid minutes.
The metric therefore needs enough support for the common paired domain and
for the time-of-day pattern of each signal. The candidate registry was fixed
at 0.70, 0.80, and 0.90 before any repaired MDER value or downstream
hypothesis result was calculated.

For each otherwise eligible Rule A participant-day, the gate evaluates:

- ordinary paired-minute coverage;
- profile-weighted support from the fixed pooled MEDI profile;
- profile-weighted support from the fixed pooled `LIGHT` profile; and
- whether the paired `LIGHT` integral is positive.

A candidate retains MDER only when all three support measures are at least
the candidate cutoff and the paired `LIGHT` integral is positive. Failure is
metric-specific: MDER becomes `NA` with one reason code, while the
participant-day and its other metrics remain available.

The profiles diagnose whether paired missingness is concentrated at
time-of-day bins that matter for either signal. They do not scale, weight, or
otherwise alter the MDER numerator, denominator, or ratio.

## Full-cohort diagnostic

| Placement | Eligible days | 70% retained | 80% retained | 90% retained |
|---|---:|---:|---:|---:|
| Near-eye source | 811 | 790 | 733 | 601 |
| Chest source | 897 | 874 | 825 | 691 |

At the approved 0.80 cutoff, the gate retains:

- 733 of 811 near-eye participant-days, representing all 141 participants
  and all nine near-eye sites; and
- 825 of 897 chest participant-days, representing all 154 participants and
  all eight chest sites.

For each placement, two participant-days have a non-positive paired `LIGHT`
integral. They are the same two dates for participant `IZTECH_S009`
(18 and 19 March 2025) and cannot be recovered by lowering the support
cutoff. Among positive-denominator days, failure of any one of the three
support requirements remains reason-coded rather than being treated as
zero exposure.

Moving from 70% to 80% removes 57 additional near-eye and 49 additional
chest MDER instances without removing a participant or site. Moving from
80% to 90% removes a further 132 near-eye and 134 chest instances and leaves
139 near-eye and 152 chest participants represented. The 90% rule therefore
has a substantially larger denominator cost, whereas the 70% rule admits
days with materially less support in at least one signal-specific temporal
profile.

## Approved treatment

The author approved:

1. 0.80 as the primary cutoff for **each** of ordinary paired coverage,
   fixed MEDI-profile support, and fixed `LIGHT`-profile support;
2. 0.70 and 0.90 as fixed MDER-specific sensitivity scenarios;
3. a positive paired `LIGHT` integral as a separate denominator requirement;
4. metric-specific, reason-coded `NA` when any requirement fails, without
   deleting the participant-day; and
5. no MDER scaling, inverse-coverage correction, or profile weighting of the
   value itself.

This choice matches the approved 80% support standard while respecting that
MDER requires a common two-signal domain. It was made from construct and
support diagnostics, not from repaired ratios, p-values, effect estimates, or
preferred downstream conclusions. The gate deliberately calculated no MDER
ratio value.

The canonical Preparation 04 run must record `METRIC-003` and apply 0.80 to
all three support measures. The 0.70 and 0.90 scenarios must be namespaced,
report their own and common-sample flows, and must not overwrite the primary
artifacts.

## Verification

The full R 4.6.1 gate produced:

- 1,708 participant-day diagnostic rows;
- six placement-by-cutoff summaries;
- 51 site-by-placement-by-cutoff summaries;
- 885 participant-by-placement-by-cutoff summaries; and
- five checksummed data artifacts plus their manifest.

An independent verifier reconstructed all 2,650 diagnostic and summary rows
exactly (2,650/2,650), verified the fixed cutoff registry, profile and
coverage provenance, dimensions, hashes, and input immutability, and
confirmed that neither a ratio nor a scaled or weighted ratio was calculated.
Deliberate manifest, value, classification, and candidate-registry
corruptions were detected.

The accepted artifact-manifest SHA-256 is:

`c4ecfab41892e44b38dd78097277ccef5f94a379b44c7b309de281e9215a7b3c`.

Evidence:

- `scripts/pipeline/mder_support_gate.R`;
- `scripts/pipeline/build_mder_support_gate.R`;
- `scripts/pipeline/verify_mder_support_gate_artifacts.R`;
- `tests/test_mder_support_gate.R`;
- `tests/test_verify_mder_support_gate_artifacts.R`;
- `artifacts/08_diagnostics/mder_support_gate/mder_support_gate_daily.csv`;
- `artifacts/08_diagnostics/mder_support_gate/mder_support_candidate_summary.csv`;
- `artifacts/08_diagnostics/mder_support_gate/mder_support_candidate_by_site.csv`;
- `artifacts/08_diagnostics/mder_support_gate/mder_support_candidate_by_participant.csv`;
- `artifacts/08_diagnostics/mder_support_gate/mder_support_gate_inputs.csv`; and
- `artifacts/12_manifests/mder_support_gate_artifacts.csv`.

## Reopening condition

Reopen `METRIC-003` if the MDER estimand, paired-signal mask, fixed profiles,
support definition, or candidate registry changes; if the canonical metric
run fails to reproduce the gate classifications; or if a 0.70/0.90
sensitivity materially changes an estimate or substantive conclusion.
