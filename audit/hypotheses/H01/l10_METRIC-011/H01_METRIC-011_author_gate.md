# H01 METRIC-011 bounded author gate

Date: 2026-08-12  
Status: **stopped — production-bootstrap author approval required**  
Controlling metric decision: `METRIC-011`  
Scope: primary-data darkest-10-hour mean melEDI branches only

## Outcome

The shared METRIC-011 repair normalizes eight primary darkest-10-hour mean
melEDI values from the floating-point residue
`4.163336342344337e-17 lx` to exact zero: three near-eye values and five
chest values. The fitted samples, sites, response family, formulas, and all
gap-timing-unaware scientific values are unchanged. Across the four affected
primary all-available or paired/common model frames, this produces 16 changed
fitted rows because each normalized day can also enter its paired/common
frame. The largest transformed-response change is
`2.220446049250313e-16`.

The existing Gaussian model with `log10(melEDI + 0.1)` was refitted in an
isolated output tree for exactly four primary-data targets. The largest raw
model-level p-value change is `6.231682e-13`; the largest adjusted p-value
change is below `1e-11`. No L10 support decision and no other metric's
Benjamini--Hochberg support decision changes. The revised results therefore
do not reopen the response-family decision or any scientific claim.

The four affected production-bootstrap targets cannot retain draws generated
from the pre-normalization model frames if their provenance is to match the
current inputs. A separately stored 50-successful-refit pilot passed for all
four targets with no failed or warning refits. The pilot is explicitly
**PILOT — NOT FOR INFERENCE OR MANUSCRIPT REPORTING**. No production
bootstrap has been launched and no Stage 2--4 reader report has been changed.
The separate METRIC-010 MDER author gate and all protected non-L10 artifacts
remain hash-frozen.

## Final pinned inputs

| Input | SHA-256 |
|---|---|
| METRIC-011 decision | `23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797` |
| METRIC-011 evidence manifest | `a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb` |
| H01 primary prepared-input manifest | `25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72` |
| H01 primary RDS | `0328fe1a698bc13965feb0b68b03ccf0fd20f32b55d6148635811b0d674e0a00` |
| H01 gap-timing-unaware prepared-input manifest | `e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b` |
| H01 gap-timing-unaware RDS | `3c70363fc0468202a431904aa9d9444f2858af2e3add3475a56c872b49a18bd6` |

The isolated point-fit inventory is
`audit/hypotheses/H01/l10_METRIC-011/point_refit/artifacts/12_manifests/H01_model_results_artifacts.csv`.
The 50-refit pilot inventory is
`audit/hypotheses/H01/l10_METRIC-011/bootstrap_pilot/H01_METRIC-011_bootstrap_pilot_manifest.csv`.
The complete bounded review inventory is
`audit/hypotheses/H01/l10_METRIC-011/author_gate/H01_METRIC-011_author_gate_manifest.csv`.

## Exact affected samples

Darkest-10-hour mean melEDI is a participant-day outcome, so
participant-days equal fitted observations. The metric producer does not
export exact support minutes for this outcome; support hours therefore remain
unavailable rather than being reconstructed under another definition.

| Dataset | Placement | Sample | Participants | Participant-days | Observations | Sites | Support hours |
|---|---|---|---:|---:|---:|---:|---:|
| Primary | Near eye | All available | 141 | 816 | 816 | 9 | unavailable |
| Primary | Chest | All available | 154 | 902 | 902 | 8 | unavailable |
| Primary | Near eye | Paired/common | 112 | 643 | 643 | 8 | unavailable |
| Primary | Chest | Paired/common | 112 | 643 | 643 | 8 | unavailable |

The unchanged gap-timing-unaware samples remain 141 participants and 811
participant-days near eye, 154 and 897 at the chest, and 112 participants and
640 participant-days at each placement in the paired/common sample.

## Primary near-eye point result

The photoperiod ratio is 1.088 per additional hour (95% CI 1.034 to 1.144;
term raw p = 0.001). The absolute-latitude ratio is 1.040 per 10 degrees
(95% CI 0.971 to 1.115; term raw p = 0.263).

| Model-level question | Raw p | 17-test BH q | Support |
|---|---:|---:|---|
| Overall site | <0.001 | <0.001 | supported |
| Photoperiod | <0.001 | 0.002 | supported |
| Latitude | 0.259 | 0.400 | not supported |
| Site versus linear-latitude adequacy | <0.001 | <0.001 | supported |

Because the overall site test is supported, the approved hierarchical
comparisons with the equally weighted overall site mean apply. Three
near-eye deviations remain supported within this metric:

- Izmir (TR): ratio 1.487 (95% CI 1.159 to 1.908), raw p = 0.002,
  within-metric q = 0.016;
- Kumasi (GH): ratio 0.668 (95% CI 0.509 to 0.876), raw p = 0.003,
  within-metric q = 0.016;
- Tübingen (DE): ratio 1.359 (95% CI 1.089 to 1.695), raw p = 0.007,
  within-metric q = 0.020.

The point R-squared summaries are marginal R-squared = 0.220, conditional
R-squared = 0.611, participant-associated share = 0.391, site part
R-squared = 0.137, photoperiod part R-squared = 0.034, and latitude part
R-squared = 0.005. These point summaries do not replace the required joint
bootstrap intervals, and their overlapping contributions must not be added.

## Complementary chest result

The all-available chest photoperiod ratio is 1.070 per hour (95% CI 1.019 to
1.123; term raw p = 0.006). The latitude ratio is 0.920 per 10 degrees (95%
CI 0.877 to 0.966; term raw p <0.001). Its complete 17-test q-values are
<0.001 for overall site, 0.010 for photoperiod, 0.002 for latitude, and
<0.001 for site-versus-latitude adequacy. All four support decisions are
unchanged.

## Exact paired/common placement comparison

Both primary paired/common models contain the same 112 participants, 643
participant-days/observations, and 8 sites. The near-eye photoperiod ratio is
1.097 (95% CI 1.035 to 1.162; 17-test q = 0.003), and the chest ratio is
1.083 (95% CI 1.024 to 1.145; q = 0.008). The near-eye latitude ratio is
1.003 (95% CI 0.931 to 1.081; q = 1.000), and the chest ratio is 0.931 (95%
CI 0.868 to 1.000; q = 0.102). Thus photoperiod remains supported at both
placements; latitude remains unsupported at both after multiplicity. This
matched comparison does not establish placement equivalence or
interchangeability.

## Gap-timing-unaware sensitivity

No value or fitted frame changed in the gap-timing-unaware dataset, so its
four accepted L10 fits and stored outputs were preserved exactly. The
all-available near-eye photoperiod ratio remains 1.086 (95% CI 1.032 to
1.141), and its latitude ratio remains 1.030 (95% CI 0.961 to 1.103). The
corresponding chest ratios remain 1.065 (95% CI 1.015 to 1.117) and 0.914
(95% CI 0.871 to 0.959), respectively. These values are reported here only
to show the stable sensitivity pattern; no gap fit or bootstrap was repeated.

## Diagnostics and influence

All four affected point fits converged, had positive-definite Hessians, were
non-singular, and avoided the predefined major diagnostic gate. All remain
`WARN_REVIEW`: the Gaussian residual checks show non-normal tails and
heteroscedasticity, with 1.1%--1.6% of standardized residuals exceeding an
absolute value of 3. Prediction lower bounds are respected; no verified
upper bound is available for this metric. These warning classifications and
the diagnostic plots are unchanged to numerical precision. Current
assessment: **acceptable with limitations**; METRIC-011 does not supply a
reason to replace the common response family.

Participant-deletion influence refits all succeeded. The largest absolute
DFBETA is 0.757 in the all-available near-eye model, 0.739 in its
paired/common model, 0.820 in the all-available chest model, and 0.778 in its
paired/common model. The participant and coefficient attaining each maximum
are unchanged from the accepted analysis.

Diagnostic plots are stored under
`audit/hypotheses/H01/l10_METRIC-011/point_refit/artifacts/08_diagnostics/H01/main/`.

## Pilot and projected production cost

The pilot used the production bootstrap function, four parallel workers, and
one BLAS/OpenMP thread under R 4.6.1. Each of the four targets has 50 stored,
successful joint refits. Across targets, 300 refits were attempted and
successful because the checkpointed batching implementation generated 75
successful candidates per target before retaining the declared 50. There
were zero failed refits and zero warning refits.

- observed total wall time: 73.95 seconds;
- projected four-target, 1,000-successful-refit wall time: 1,478.93 seconds
  (24.65 minutes; 0.411 hours);
- checkpoint granularity: completed run-metric target;
- pilot inference status: **PILOT — NOT FOR INFERENCE OR MANUSCRIPT
  REPORTING**.

The preview figure is
`audit/hypotheses/H01/l10_METRIC-011/bootstrap_pilot/figures/H01_METRIC-011_bootstrap_pilot_preview.png`,
with paired source data beside it. It was visually inspected at its stored
size: all four targets and six R-squared summaries are readable, with no
clipping or overlap. The intervals are pilot previews and must not be cited.

## Commands

R 4.6.1 with the activated project library was used. The point refit took 53
seconds. The pilot command was run with one BLAS/OpenMP thread and four
workers.

```sh
Rscript --vanilla scripts/hypotheses/H01/run_h01_l10_METRIC011_point.R

H01_L10_PILOT_REFITS=50 \
H01_L10_PILOT_CORES=4 \
Rscript --vanilla \
  scripts/hypotheses/H01/run_h01_l10_METRIC011_bootstrap_pilot.R

Rscript --vanilla scripts/hypotheses/H01/audit_h01_l10_METRIC011.R
Rscript --vanilla tests/hypotheses/H01/test_h01_l10_METRIC011_gate.R
```

## Author decision required

Please approve or reject this bounded production step:

1. retain the established Gaussian `log10(melEDI + 0.1)` implementation as
   acceptable with limitations for the four affected primary targets;
2. accept that METRIC-011 causes no fitted-sample, inferential-support,
   sensitivity-classification, or claim change; and
3. authorize a separately stored production bootstrap with at least 1,000
   successful joint refits for each of the four affected primary L10 targets,
   using the pilot-verified implementation and checkpoints.

If approved, only those four L10 bootstrap targets and their dependent
interval/manifests will be replaced. The 830 protected non-L10 artifacts, all
unchanged gap L10 outputs, and the separate METRIC-010 gate remain untouched.
The affected Stage 2--4 tables, figures, and prose will be merged only after
the production outputs pass their focused verifier. No central ledger or
manuscript change is authorized here.
