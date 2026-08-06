# H11 activity-context results and Stage 3 revision

Date: 2026-08-06  
Branch: `rewrite/NH`  
Status: **implemented and ready for author review**

## Author-requested changes

The Stage 3 reader report was revised to implement two author requests:

1. The two-test BH level/shape decomposition is now described as a secondary
   attribution analysis that could not cleanly resolve the supported global
   curve into independently supported level and shape components. It is not
   described as invalidating or reversing the separate global curve test.
2. The recorded hourly activity context was added in an exploratory
   same-sample sensitivity to test whether the estimated sex-specific curve
   attenuated after adjustment.

The previously approved pointwise 95% confidence-interval rule remains in
force. The activity-adjusted effect-size gate required raw global *p* < 0.050;
it remained closed at both placements, so no effect-size bootstrap was run.

## Activity mapping and model comparison

Only diary hours with exactly one selected activity were eligible. Multi-label,
zero-label, all-missing, and exactly-one unspecified-other hours were excluded.
Retained categories were home (reference), sleep, road or vehicle, indoor work,
and outdoor activity. A 30-minute exposure row was attached only when it lay
wholly within a unique diary hour. `AR.start` was recalculated after filtering.

Within each placement, the same activity-complete observations were used for:

- the accepted H11 temporal formula without activity; and
- the same formula plus a treatment-coded activity main effect and
  activity-specific cyclic temporal deviations.

A placement-specific rho estimated from the preliminary activity-adjusted
model was held fixed in both final same-sample fits. All models used Gaussian
identity-link `bam`, fREML, `discrete = TRUE`, the inherited participant/day,
site, clock-time, and autocorrelation-boundary structure, and participant-
cluster robust global curve inference. Exact formulas are stored in
`artifacts/06_model_data/H11/stage3/H11_reader_activity_formula_registry.csv`.

## Exact samples

| Placement | Participants | Female | Male | Participant-days | 30-minute observations | Sites |
|---|---:|---:|---:|---:|---:|---:|
| Near eye | 126 | 71 | 55 | 724 | 30,499 | 9 |
| Chest | 150 | 83 | 67 | 875 | 36,711 | 8 |

## Global complete-curve results

| Placement | Analysis | F | Fractional numerator df | Denominator df | Raw p | One-test BH p | Decision |
|---|---|---:|---:|---:|---:|---:|---|
| Near eye | Accepted all-available | 20.946 | 9.692 | 131 | 0.028 | 0.028 | supported |
| Near eye | Activity-complete, unadjusted | 13.619 | 9.195 | 116 | 0.160 | 0.160 | not supported in exploratory model |
| Near eye | Same sample, activity-adjusted | 9.025 | 8.476 | 117 | 0.364 | 0.364 | not supported in exploratory model |
| Chest | Accepted all-available | 4.876 | 1.003 | 152 | 0.029 | 0.029 | supported |
| Chest | Activity-complete, unadjusted | 5.095 | 1.001 | 148 | 0.025 | 0.025 | supported in exploratory model |
| Chest | Same sample, activity-adjusted | 3.903 | 1.003 | 148 | 0.050 | 0.050 | not supported in exploratory model |

The chest adjusted full-precision raw *p*-value is 0.05021431625; significance
was decided before display formatting. For near eye, the common-sample
unadjusted result was already unsupported before activity entered the model,
so the change cannot be attributed to activity. At chest, the same-sample
threshold crossing is compatible with modest attenuation but does not identify
mediation or a behavioural mechanism.

The activity-adjusted near-eye minimum Female-to-Male shifted ratio is 0.729
(pointwise 95% CI 0.488–1.090) at 08:15. The adjusted chest ratio is
approximately 0.826 (0.682–1.000); its full-precision upper endpoint is
1.000034. No adjusted pointwise interval excludes one at either placement.

## Diagnostics

All four common-sample fits are **acceptable with specified limitations**.
They converged without serious warnings, cyclic sex curves close at midnight,
the inherited site sum-to-zero constraint holds, and no severe basis-dimension
flag was found. Final boundary-aware lag-1 correlations were 0.144 and 0.084
near eye and 0.131 and 0.075 at chest for the unadjusted and adjusted fits.
Maximum participant covariance-meat shares were 4.55%, 3.17%, 7.79%, and
5.68%, respectively.

## Display revision

The four melEDI curve figures now use
`LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)`, linear from 0 to 1 lx
and base-10 logarithmic above 1 lx, with original-unit breaks and untransformed
source data. The new activity comparison figure and all six existing reader
figures were checked on a seven-page A4 physical-size proof made from the
actual exported assets. All seven pass REPORT-011; the QA-only proof is outside
the final figure directory.

## Reader deliverables

- source: `notebooks/hypotheses/H11.qmd`;
- render: `_build/nathealth/notebooks/hypotheses/H11.html`;
- activity reader tables: `artifacts/09_tables/H11/stage3/`;
- activity source curves: `artifacts/11_source_data/H11/stage3/`;
- reader figures: `artifacts/10_figures/H11/stage3/`;
- figure QA: `audit/hypotheses/H11/03_figure_readability_qa.md`;
- authoritative activity manifest:
  `artifacts/12_manifests/H11/H11_activity_context_output_hashes.csv`.

## Gate

The revised Stage 3 report is ready for author review. No later-stage shared
integration, manuscript edit, central-ledger edit, commit, or push is
authorized by this record.
