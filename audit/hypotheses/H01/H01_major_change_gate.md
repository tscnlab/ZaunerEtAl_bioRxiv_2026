# H01 response-decision gate

Date: 2026-07-30; resolved 2026-07-31  
Status: **author decisions implemented; inputs repinned; fit-stage
verification passed; production bootstrap pending**  
Runtime: R 4.6.1  
Scope: response-support diagnostics only; no effect estimate or model-level
p-value was used to choose or frame either decision

## Trigger

The first diagnostic run of the response-family package approved as `H01-005`
opened a major gate for two checks in both data scenarios and placements:

1. the pre-sleep duration can exceed the initially assumed three-hour
   interval; and
2. the submitted noon conversion for the L10 midpoint required an explicit
   common rule.

No alternative family was selected and no metric was removed from a
multiplicity family. The author resolved both issues before the complete H01
analysis was released. The resulting implementation is now checked against
the jointly repinned main and manuscript-prepared inputs.

## Gate A: pre-sleep duration estimand

The rebuilt primary near-eye frame contains 655 participant-days from 139
participants at nine sites. Sixty-one days (9.31%) have more than three hours
below 10 lx melEDI before sleep; the maximum is 5.90 h. The corresponding
chest frame contains 743 participant-days from 153 participants at eight
sites; 68 days (9.15%) exceed three hours and the maximum is 5.97 h.

This is not a duplicated-row defect. There are 148 near-eye and 147 chest
main-data calendar days with more than 180 expected pre-sleep minutes. Every
affected day is traceable to the diary-defined pre-sleep intervals occurring
on that local date. Calendar-date aggregation can therefore combine the
post-midnight remainder of one pre-sleep interval with the evening portion of
the next.

The same ceiling failure occurs in the manuscript-prepared-data sensitivity:
62/780 near-eye and 69/867 chest fitted participant-days exceed three hours,
with the same maxima. Exact support minutes are unavailable in that
sensitivity and remain reported as unavailable.

The alternatives considered were:

- redefine the analytical day or assign each complete pre-sleep interval to
  its associated attempted-sleep episode, which requires a shared
  preparation change and a complete downstream rebuild;
- retain the calendar-day cumulative estimand, explicitly amend the construct
  and remove the three-hour ceiling, then repeat outcome diagnostics before
  approving a response family; or
- exclude the metric as non-estimable for this analysis.

The author selected the calendar-day cumulative estimand. Valid values are not
capped at three or six hours. Twenty-four hours is the physical response
bound, and strictly above six hours is an audit warning. No current value
exceeds six hours, so Gate A changes no value and removes no model row. The
same rule is used for main and manuscript-prepared data and for near-eye and
chest analyses.

## Gate B: L10 midpoint response

The submitted noon conversion was reviewed against the approved 16:00
conversion:

| Scenario | Placement | Observations | Participants | Sites | Span after 16:00 conversion |
|---|---|---:|---:|---:|---:|
| Main | Near eye | 816 | 141 | 9 | 18.72 h |
| Main | Chest | 902 | 154 | 8 | 21.80 h |
| Manuscript-prepared | Near eye | 811 | 141 | 9 | 18.88 h |
| Manuscript-prepared | Chest | 897 | 154 | 8 | 21.40 h |

The L10 midpoint remains a linearly interpreted nighttime clock variable. The
conversion changes four main near-eye observations, one main chest
observation, three manuscript-prepared near-eye observations and three
manuscript-prepared chest observations relative to the noon conversion. No
observation lies exactly at 16:00.

The author approved the strict-after-16:00 conversion as primary and retained
the noon conversion as a same-row, same-model sensitivity. This is a prefit
transformation amendment, not a circular model or response-family change.
The two superseded diagnostic files are retained under `superseded/` and must
not be reported as H01 results.

## Multiplicity and reporting consequence

Both metrics remain planned members of all four 17-row model-level families.
Their earlier diagnostic tests remain invalid rather than null. The approved
implementation must rerun the complete four-family adjustment from one
17-value vector per family. The noon conversion is a sensitivity and is not
inserted into those primary families.

The decision gate is closed. The main and manuscript-prepared H01 manifests
were regenerated twice, reproduced byte-for-byte, and were repinned together.
The complete fit stage then regenerated eight analysis runs: main and
manuscript-prepared data, near eye and chest, and all-available and
paired/common-sample observations.

Across these runs, all 136 planned metric rows were retained. The 128
estimable fits completed; the eight predeclared non-estimable rows are
participant-level IS and IV in paired/common-sample analyses. All 32
multiplicity vectors contain 17 planned metric rows. Sixteen all-available
vectors contain 17 observed tests, whereas the 16 paired/common-sample vectors
contain 15 observed tests and two explicit non-estimable rows. Independent R
verification reproduced every adjusted value by applying
Benjamini--Hochberg correction to the observed vector with `n = 17`.

The fit-stage diagnostic table contains 28 `PASS`, 100 `WARN_REVIEW`, eight
`NON_ESTIMABLE`, and no `FAIL_MAJOR_GATE` rows. Warning rows remain visible
for later model-by-model review and do not authorize silent simplification.
Every primary term effect, site estimate, and site deviation has a 95%
confidence interval. The noon-conversion sensitivity also has complete 95%
confidence intervals and uses exactly the same participants,
participant-days, and model rows as the primary L10 conversion in all eight
runs.

H01 remains unreleased until the production bootstrap intervals, warning
review, sensitivity classifications, result comparisons, and final Quarto
output pass. Claim consequences remain pending those complete results.

## Reproducible evidence

- `audit/hypotheses/H01/H01_gate_a_pre_sleep_calendar_day.csv`
- `audit/hypotheses/H01/H01_shared_pre_sleep_interval_evidence.csv`
- `audit/hypotheses/H01/H01_gate_b_l10_conversion.csv`
- `audit/hypotheses/H01/H01_major_gate_provenance.csv`
- `artifacts/08_diagnostics/H01/H01_model_diagnostics.csv`
- `artifacts/09_tables/H01/H01_model_level_tests.csv`
- `artifacts/09_tables/H01/H01_l10_noon_conversion_model_tests.csv`
- `tests/hypotheses/H01/test_h01_fit_outputs.R`
- `scripts/hypotheses/H01/audit_h01_major_gates.R`

Command:

```sh
RENV_CONFIG_SANDBOX_ENABLED=FALSE \
NATHEALTH_PROJECT_ROOT=<project> \
Rscript scripts/hypotheses/H01/audit_h01_major_gates.R
```

## Reopening condition

Reopen this decision if the calendar-day construct, six-hour audit role,
strict-after-16 boundary, noon sensitivity, response family, or model rows
change. Bootstrap, warning review, sensitivity comparison, Quarto, and final
result-manifest stages still require verification before H01 is released.
