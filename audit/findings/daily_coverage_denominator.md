# Daily 80% coverage denominator

Finding ID: `DEV-055`  
Decision ID: `COVERAGE-001`  
Status: `approved`  
Diagnostic date: 2026-07-30

## Conflict

The signed preregistration excludes participant-days below 80% valid wear
time with sleep excluded from that daily denominator. Canonical Preparation 02
currently applies the inclusive 50% hourly gate and then divides eligible
finite MEDI wall minutes by a fixed 1,440-minute day. Diary-defined bedside
sleep measurements therefore contribute to whether a day is retained.

This is a conflict between the literal preregistration wording and the
intended whole-cycle coverage construct, not evidence that sleep should be
excluded from the primary denominator. The intended question is whether more
than 80% of the complete 24-hour cycle is observed. That cycle deliberately
combines worn near-eye measurements during wake with bedside measurements
during diary-defined sleep. The latter describe the bedside sleep environment,
not ocular exposure, and that practical limitation must remain explicit.

## Cutoff-neutral diagnostic

The verified diagnostic compared three fixed rules before any rebuilt
hypothesis results were inspected:

| Rule | Hourly gate | Daily 80% denominator |
|---|---|---|
| A: current | Finite wall-mean MEDI / 60 wall minutes | Finite MEDI in eligible hours / 1,440 wall minutes |
| B: preregistration-minimal | Unchanged from A | Finite non-sleep MEDI in eligible hours / expected non-sleep minutes |
| C: wake-aware | Finite non-sleep MEDI / expected non-sleep minutes in the hour | Finite non-sleep MEDI in wake-eligible hours / expected non-sleep minutes |

Only explicit diary state `sleep` is excluded. Missing or unknown diary state
remains expected support and therefore cannot make a denominator easier.
Repeated fall-back wall minutes contribute fractional non-sleep expected and
valid mass based on both true-UTC instances. All thresholds remain inclusive
at 0.50 and 0.80.

Rule A is delegated to the canonical coverage implementation and must
reproduce it exactly. This assertion passed.

## Verified full-cohort results

| Placement | Rule | Eligible participants | Eligible participant-days |
|---|---|---:|---:|
| Near-eye | A: current | 141 | 811 |
| Near-eye | B: preregistration-minimal | 141 | 758 |
| Near-eye | C: wake-aware | 141 | 757 |
| Chest | A: current | 154 | 897 |
| Chest | B: preregistration-minimal | 154 | 838 |
| Chest | C: wake-aware | 154 | 837 |

Relative to A:

- B changes 55 near-eye days from eligible to ineligible and 2 in the reverse
  direction, for a net change of -53; chest changes 60 and 1 respectively,
  for a net change of -59.
- C changes 56 near-eye days from eligible to ineligible and 2 in the reverse
  direction, for a net change of -54; chest changes 61 and 1 respectively,
  for a net change of -60.
- No placement loses an eligible participant entirely.
- Changes occur across sites rather than in one isolated cohort.

The days retained by A but rejected by C are not half-hour-gap cases. Their
missing waking support is at least 159 minutes. Median missing waking support
is 212.5 minutes near-eye and 217 minutes chest; the interquartile ranges are
200–242.5 and 202–248 minutes, respectively. Median failed waking hours are
three in both placements.

B and C differ for only one paired BAUA participant-day. B yields 81.7%
daily non-sleep support under the existing hourly rule, whereas C yields
79.5% after making the boundary-hour gate wake-aware; the difference is 22
valid waking minutes.

## Approved decision

Rule A remains the primary base eligibility rule. It directly operationalizes
the intended question: is more than 80% of the complete 24-hour hybrid cycle
observed? It also retains the canonical primary sample of 811 near-eye and 897
chest participant-days. This choice is not presented as literal adherence to
the signed preregistration: the preregistration says to exclude sleep from the
daily denominator, whereas Rule A includes valid bedside sleep-environment
measurements in both support and the fixed 1,440-minute denominator. The
conflict is retained as the explicit preregistration deviation `DEV-055`.

Rules B and C are fixed, declared sensitivity scenarios:

- Rule B tests the most literal daily sleep-excluded interpretation while
  retaining the existing all-minute hourly gate.
- Rule C tests a fully wake-aware interpretation by excluding diary sleep from
  both the hourly and daily support denominators.

Neither sensitivity may be tuned after inspecting hypothesis results. Each
must report scenario-specific participant and participant-day flow, alongside
common-sample comparisons with Rule A. A qualitative conclusion change,
material estimate change, or unexpected site/placement-specific exclusion
pattern reopens the affected hypothesis before its result or claim is closed.

The decision was made after inspecting inclusion counts but before refitting
the hypothesis models. It rests on the intended measurement construct and the
predeclared support rules, not on which denominator produces preferred
inferential results. Rule B's and Rule C's lower day counts therefore remain
diagnostic consequences to report, not the reason for dismissing those
scenarios.

## Provenance and verification

- R: 4.6.1
- Near-eye aligned input SHA-256:
  `d50fb7054d133503965760f633aed7caf42a52e0cbda09cf7d27cd91983d8d59`
- Chest aligned input SHA-256:
  `be0f7189375a15de597242903254209e10dfe216ee724f3b741dd26886284f8b`
- Detailed diagnostic:
  `artifacts/08_diagnostics/daily_coverage_rule_comparison/daily_coverage_rule_detail.rds`
- Identifier-free counts and transitions:
  `artifacts/08_diagnostics/daily_coverage_rule_comparison/`
- Artifact-manifest SHA-256 verification: 5/5 pass
- Input rehash verification: 2/2 pass
- Synthetic edge cases: mixed-state fall-back, full-sleep hour, unknown state,
  exact 0.50/0.80 boundaries, no-sleep equivalence, identifier separation,
  and bytewise manifest checks all pass with warnings treated as errors
