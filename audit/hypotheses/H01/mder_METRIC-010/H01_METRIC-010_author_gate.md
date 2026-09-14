# H01 METRIC-010 post-repair author gate

Date: 2026-08-11  
Status: **stopped — material-inference author approval required**  
Controlling metric decision: `METRIC-010`  
Scope: MDER-dependent H01 outputs only

## Outcome

The coordinator repaired and independently verified the shared
gap-timing-unaware MDER preparation. The previously retained zero is now a
reason-coded missing MDER, every retained value is finite and strictly
positive, and all 25,620 non-MDER participant-day cells are unchanged. The
shared-input stop is therefore resolved.

The H01 worker then ran a fresh isolated point refit for the eight registered
MDER scenario/placement/sample targets using the common Gaussian identity
implementation. No accepted H01 model, bootstrap draw, report, or claim was
overwritten. The other 16 metrics were not refitted, and 830 accepted
non-MDER artifacts remain guarded by their existing hashes.

The primary near-eye inference changes materially. Revised MDER is supported
after the applicable complete 17-test Benjamini--Hochberg adjustment for
overall site, photoperiod, latitude, and site-versus-linear-latitude
adequacy. Its changed site p-value also changes the rank of one unchanged
non-MDER result: calendar-day time below 10 lx melEDI before sleep moves from
q = 0.054 to q = 0.049 for overall site.

No production bootstrap or bootstrap pilot has been launched. Stage 2--4 H01
sources and accepted reporting artifacts remain unchanged pending author
approval of this point-result baseline.

## Final pinned inputs

| Input | SHA-256 |
|---|---|
| METRIC-010 decision | `1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de` |
| Primary metric manifest | `7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43` |
| Independent MDER audit manifest | `5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb` |
| Current base-model manifest | `b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09` |
| Current base input bundle | `168f25e18b6e494aa7a0272923041ad8249e25adb9ff3742d22e2f4cacf1bdf8` |
| Gap repair evidence manifest | `81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018` |
| Preanalysis manifest | `f90ea36334b59821101ef36de50d5d84dcfc6e8bee23f1f918be10fb2247724e` |
| H01 primary RDS | `2d226a48d92eec7f419e66f4011e8294557034abb4e1a6af6c055d4a0cbc7621` |
| H01 primary prepared-input manifest | `5aa19326b2de468efb177af0d8f193253db63aade2d607f9570f5c3337e39c74` |
| H01 gap-timing-unaware RDS | `24948e6b138c80bf236a7c9b2b005760206d34a7318a45594ac541482408830e` |
| H01 gap-timing-unaware prepared-input manifest | `79ee4818d7f3967827a6412f8537196e84ee7a6ccc1b8d2c5e9dd3124ed44b47` |
| Embedded gap scenario input manifest | `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935` |

The isolated point-fit inventory is
`audit/hypotheses/H01/mder_METRIC-010/point_refit_repaired_gap/artifacts/12_manifests/H01_model_results_artifacts.csv`.
The complete post-repair review inventory is
`audit/hypotheses/H01/mder_METRIC-010/author_gate_post_repair/H01_METRIC-010_author_gate_manifest.csv`.

## Exact fitted MDER samples

| Dataset | Placement | Sample | Participants | Participant-days | Observations | Sites | Support hours |
|---|---|---|---:|---:|---:|---:|---:|
| Primary | Near eye | All available | 137 | 702 | 702 | 9 | 10,949.917 |
| Primary | Chest | All available | 152 | 732 | 732 | 8 | 11,145.300 |
| Primary | Near eye | Paired/common | 107 | 489 | 489 | 8 | 7,665.217 |
| Primary | Chest | Paired/common | 107 | 489 | 489 | 8 | 7,435.617 |
| Gap-timing-unaware | Near eye | All available | 137 | 687 | 687 | 9 | unavailable |
| Gap-timing-unaware | Chest | All available | 152 | 723 | 723 | 8 | unavailable |
| Gap-timing-unaware | Near eye | Paired/common | 107 | 478 | 478 | 8 | unavailable |
| Gap-timing-unaware | Chest | Paired/common | 107 | 478 | 478 | 8 | unavailable |

MDER is a participant-day outcome, so participant-days equal fitted
observations. Gap-timing-unaware support hours remain unavailable as required;
they were not reconstructed from a different support definition.

## Primary near-eye point result

The equally weighted overall site mean was 0.726 (95% CI 0.712 to 0.740).
The photoperiod effect was +0.024 MDER per hour (95% CI +0.017 to +0.031),
and the absolute-latitude effect was -0.014 MDER per 10 degrees (95% CI
-0.024 to -0.004).

| Model-level question | Raw p | 17-test BH q | Superseded q | Revised support |
|---|---:|---:|---:|---|
| Overall site | <0.001 | <0.001 | 0.305 | supported |
| Photoperiod | <0.001 | <0.001 | <0.001 | supported |
| Latitude | 0.005 | 0.013 | 0.384 | supported |
| Site versus linear latitude adequacy | 0.003 | 0.010 | 0.332 | supported |

Because the overall site test is supported, the approved hierarchical
equal-site-mean contrasts apply. Two site deviations survive the within-MDER
BH adjustment:

- Kumasi (GH): +0.083 (95% CI +0.041 to +0.126), raw p <0.001,
  within-MDER q = 0.001;
- Munich (DE): -0.083 (95% CI -0.130 to -0.036), raw p <0.001,
  within-MDER q = 0.002.

Across the primary near-eye 17-metric package, supported model counts change
from 8 to 10 for overall site, remain 12 for photoperiod, change from 6 to 7
for latitude, and change from 8 to 9 for adequacy.

The point R-squared summaries are marginal R-squared = 0.278, conditional
R-squared = 0.605, participant-associated share = 0.327, site part R-squared
= 0.096, photoperiod part R-squared = 0.130, and latitude part R-squared =
0.027. These are point summaries only. They do not replace the required joint
bootstrap intervals and must not be added as overlapping contributions.

## Gap-timing-unaware sensitivity

On exactly common participant-days, the repaired gap-timing-unaware and
primary MDER means differ by -0.000039 near eye (687 days) and +0.000009 at
the chest (723 days). The formerly reported differences of approximately
0.010 and 0.015 came from the stale relabelled comparator and are superseded.

The all-available gap-timing-unaware near-eye fit gives an equally weighted
mean of 0.726, photoperiod +0.024 MDER per hour (95% CI +0.017 to +0.031),
and latitude -0.014 per 10 degrees (95% CI -0.024 to -0.004). Its complete
17-test q-values are <0.001 for site, <0.001 for photoperiod, 0.016 for
latitude, and 0.010 for adequacy. Thus all four primary MDER support decisions
are reproduced.

The complementary all-available chest fit is also stable across datasets.
In the repaired gap-timing-unaware fit, site is supported (q = 0.022),
photoperiod is not (q = 0.061), latitude is supported (q = 0.006), and
site-versus-latitude adequacy is not (q = 0.251).

Evidence is in
`H01_METRIC-010_gap_primary_common_day_comparison.csv`, the complete family
table, and the provisional effect and marginalization tables.

## Exact paired/common placement comparison

The primary paired/common MDER models use the same 107 participants, 489
participant-days/observations, and 8 sites at both placements. The repaired
gap-timing-unaware comparison uses the same 107 participants, 478 days, and
8 sites at both placements.

In the primary paired sample, photoperiod is +0.021 near eye (95% CI +0.013
to +0.029) and +0.028 at the chest (95% CI +0.020 to +0.036); both complete
family results are supported. Latitude is -0.008 near eye (95% CI -0.019 to
+0.002; q = 0.245) and -0.014 at the chest (95% CI -0.024 to -0.003;
q = 0.037). The gap-timing-unaware paired sample gives the same qualitative
placement pattern. This is evidence that the MDER latitude result is
placement-sensitive; it is not a direct test of a sensor-placement effect and
does not establish equivalence or interchangeability.

The source table is
`H01_METRIC-010_paired_placement_point_comparison.csv`; the point-estimate
display is `H01_METRIC-010_paired_placement_point_comparison.png`. Near eye is
on the horizontal axis, chest on the vertical axis, component 95% intervals
are shown, the dashed line is identity, dotted lines are the null, and the
axes use equal geometry. The figure was visually checked at its final size:
labels, ticks, intervals, legend, and panel titles are readable with no
clipping or overlap.

## Multiplicity consequence outside MDER

All raw p-values for the other 16 metrics are unchanged. Replacing the MDER
p-value in the complete site family changes the BH rank and moves
calendar-day time below 10 lx melEDI before sleep from q = 0.054 to q =
0.049. This is a vector-wide multiplicity consequence, not a refit or
numerical change to that metric.

The full 8-run, 4-family comparison is stored in
`H01_METRIC-010_complete_BH_impact.csv`; revised complete provisional families
are in `H01_METRIC-010_provisional_model_level_tests.csv`.

## Distribution, diagnostics, and influence

All eight point fits converged, had positive-definite Hessians, were
non-singular, and avoided the predefined major diagnostic gate. All eight are
`WARN_REVIEW`, rather than `PASS`, because Gaussian residual-shape checks flag
non-normality and heteroscedasticity. The residual-versus-fitted and Q--Q
plots show that these warnings are driven mainly by a small upper tail. The
common Gaussian identity family has not been replaced. Current assessment:
**acceptable with limitations**.

The primary near-eye distribution has mean 0.724, median 0.724, 95th
percentile 0.901, and maximum 1.857. Its largest candidate participant
influence is RISE_S001 (maximum absolute DFBETA 1.05). Omitting that
participant or only its maximum-MDER day retains support for all four MDER
questions. Latitude is nevertheless site-sensitive: its leave-one-site-out
fit is weak after omitting Kumasi and also weak after omitting Tübingen. This
precludes a universal latitude-gradient claim.

The primary chest distribution has mean 0.757, median 0.749, 95th percentile
0.959, and maximum 3.574. The maximum belongs to KNUST_S007; the
participant-level maximum absolute DFBETA is 2.62. Removing that participant
strengthens rather than creates the site, photoperiod, and latitude signals,
but the influence remains scientifically visible.

No superseded 70/80/90 profile-support sensitivity or ratio-of-integrals
device-day upper-tail screen was reused. The revised distribution histogram,
upper-tail table, influence refits, leave-one-site-out results, and all eight
diagnostic plots are inventoried in the post-repair author-gate manifest.
REPORT-013 is not applicable to the MDER histograms because retained MDER is
strictly positive rather than zero-containing; source values remain
untransformed.

## Commands

R 4.6.1 with one BLAS/OpenMP thread and the activated project library was
used.

```sh
H01_OUTPUT_ROOT=audit/hypotheses/H01/mder_METRIC-010/point_refit_repaired_gap \
H01_STAGE=fit \
H01_METRIC_FILTER='^mder_mean_of_viable_ratios$' \
H01_SAVE_PLOTS=true \
Rscript --vanilla scripts/hypotheses/H01/run_h01_models.R

H01_MDER_POINT_ROOT=audit/hypotheses/H01/mder_METRIC-010/point_refit_repaired_gap \
Rscript --vanilla scripts/hypotheses/H01/audit_h01_mder_METRIC010.R

Rscript --vanilla tests/hypotheses/H01/test_h01_contract.R
Rscript --vanilla tests/hypotheses/H01/test_h01_mder_METRIC010_gate.R
```

## Author decision required

Please approve or reject the following point-result baseline:

1. retain the common Gaussian identity response family as acceptable with
   limitations for all eight MDER scenarios;
2. accept the material primary MDER and complete-family multiplicity changes
   above, including the q = 0.049 pre-sleep site consequence;
3. accept the gap-timing-unaware and paired-placement sensitivity
   interpretation; and
4. if accepted, authorize a separately stored 50-successful-refit
   production-code pilot for every planned MDER bootstrap target, labelled
   `PILOT — NOT FOR INFERENCE OR MANUSCRIPT REPORTING`.

After the pilot, runtime, failures/warnings, resource use, checkpoint status,
and preview tables/figures will be shown for a separate explicit production
approval. Only after production approval may the MDER production bootstrap
targets be replaced and the affected Stage 2--4 material be refreshed.

No production bootstrap, central-ledger update, manuscript claim change, or
accepted report update is authorized at this gate.
