# LightLogR and modelling API audit

## Scope and method

This is a read-only compatibility audit. Every R code cell in the project
`.qmd` files and every `scripts/*.R` file was parsed, and its function calls
were compared with the exports and formals in the restored R 4.6.1 library.
No research data were transformed, no model was fitted, and no scientific
result was recalculated.

Environment under audit:

- LightLogR 0.10.3
- suntools 1.1.0
- R 4.6.1
- project library `renv/library/macos/R-4.6/aarch64-apple-darwin23`

## Public LightLogR API targets

The project calls the following public LightLogR functions or objects:

```text
add_Date_col
add_photoperiod
add_states
add_Time_col
aggregate_Date
aggregate_Datetime
bright_dark_period
Brown2reference
cut_Datetime
Datetime_breaks
Datetime_limits
Datetime2Time
dose
duration_above_threshold
durations
exp_zero_inflated
extract_photoperiod
filter_Date
format_coordinates
gap_handler
gg_days
gg_doubleplot
gg_overview
gg_photoperiod
gg_states
interdaily_stability
intradaily_variability
log_zero_inflated
number_states
period_above_threshold
remove_partial_data
sample_groups
sc2interval
sleep_int2Brown
timing_above_threshold
```

All targets are exported by LightLogR 0.10.3. Static comparison of supplied
named arguments with the installed formals found no invalid argument names.

The main analytical call sites are:

- state construction and alignment: `data_preparation.qmd:170-200`;
- photoperiod attachment: `data_preparation.qmd:216` and `:226`;
- hourly/daily coverage and gaps: `data_preparation.qmd:252-269`;
- IS and IV: `data_preparation.qmd:293-301`;
- participant-day metrics: `data_preparation.qmd:332-394`;
- 30-minute aggregation: `data_preparation.qmd:429-449`.

This API check does not validate the scientific admissibility of those
operations; metric validity and measurement-chain audits address that
separately.

## Required compatibility repairs

### Partial argument matching in `add_states()`

At `data_preparation.qmd:189` and `data_preparation.qmd:198`, the calls use:

```r
add_states(..., start = Interval, end = Interval)
```

In LightLogR 0.10.3 these names are resolved by partial matching to
`start.colname` and `end.colname`. With `options(warnPartialMatchArgs = TRUE)`,
both names warn. The canonical implementation should use the full argument
names.

### Pin state-interval bounds

All four state joins at `data_preparation.qmd:189-190` and `:198-199` omit the
`bounds` argument. LightLogR 0.10.2 changed the default so that starts are
inclusive and ends exclusive. The canonical implementation should specify
`bounds = "[)"` explicitly and verify observations at all sleep/wear
boundaries.

### Replace non-exported functions

The following six calls depend on non-exported LightLogR internals:

| File | Lines | Internal API |
|---|---:|---|
| `scripts/helpers.R` | 161, 166 | `datetime_to_circular()`, `circular_to_hms()` |
| `Descriptives.qmd` | 1059, 1073 | `datetime_to_circular()`, `circular_to_hms()` |
| `Descriptives.qmd` | 1236, 1250 | `datetime_to_circular()`, `circular_to_hms()` |

They should be replaced with the public `Datetime2Time(..., circular = TRUE)`
and `Circular2Time()` APIs, or with a documented and tested local vector
helper. The local `datetime_handler()` that contains two of these calls is
currently unused; it also returns `x_date_handled` at `scripts/helpers.R:171`
rather than its reconstructed datetime and must not be reused unchanged.

## LightLogR 0.10.3 assessment

Relative to 0.10.2, LightLogR 0.10.3 changes LYS timestamp-column import. The
project does not call that import path. No project API incompatibility is
therefore expected from retaining 0.10.3.

Several earlier package changes remain important enough to pin explicitly:

- `add_states()` interval bounds;
- population-variance behavior and corrected mean handling in
  `interdaily_stability()` and `intradaily_variability()`;
- gap-aware behavior in the duration and metric helpers;
- explicit use of public circular-time conversion functions.

The scientific consequences of gaps, masking, `na.rm`, and changed temporal
coverage are outside this API-only record and require the metric-validity
audit.

## suntools

There are no direct `suntools::` calls in project code. suntools is reached
through:

- LightLogR `add_photoperiod()` at `data_preparation.qmd:216` and `:226`;
- LightLogR `extract_photoperiod()` at `Descriptives.qmd:1399`.

LightLogR 0.10.3 calls the exported `suntools::crepuscule()` API with arguments
supported by suntools 1.1.0. Version 1.1.0 fixes the returned POSIXct date on
daylight-saving transitions and should not be downgraded. DST boundary checks
remain mandatory for the measurement audit.

## Modelling API targets

The following installed APIs used by the project are present and accept the
supplied arguments:

| Package | Version | Audited calls | Representative evidence |
|---|---:|---|---|
| lme4 | 2.0-1 | `lmer()`, `glmer()`, `VarCorr()` | `scripts/fitting.R:11-12,58` |
| glmmTMB | 1.1.14 | `glmmTMB()`, `tweedie()` | `scripts/fitting.R:13`; `RQ2.qmd:234-259` |
| mgcv | 1.9-4 | `bam()`, `gam()`, `s()` and AR1 arguments | `RQ1.qmd:624-653` |
| performance | 0.17.1 | `check_model()`, `r2_nakagawa()` | `scripts/fitting.R:27`; `scripts/helpers.R:245-269` |
| emmeans | 2.0.3 | `emmeans()`, `emtrends()`, `contrast()`, `joint_tests()` | `RQ2.qmd:301-317,1639-1640,1971-2017` |
| gratia | 0.11.2 | `appraise()`, `conditional_values()`, `derivatives()`, `draw()`, `partial_residuals()`, `smooth_estimates()` | `scripts/RQ2_specific.R:32-51` |
| itsadug | 2.5 | `start_value_rho()`, `acf_resid()` | `RQ1.qmd:643-656` |
| ordinal | 2025.12-29 | `clmm()` | `RQ2.qmd:1813-1819` |
| nnet | 7.3-20 | `multinom()` | `RQ2.qmd:203-213` |

No removed or deprecated supplied argument was found. Clean-session package
loading produced ordinary namespace masking only:

- nnet masks `mgcv::multinom`;
- itsadug masks `gratia::dispersion`;
- nlme masks `lme4::lmList`.

Canonical notebooks should prefer explicit namespaces where a collision is
possible. The current `multinom()` calls are intended to use nnet because nnet
is attached immediately beforehand.

## Version-sensitive output to re-baseline

- performance 0.17.1 uses simulated DHARMa residuals for overdispersion
  diagnostics in glmmTMB and mixed models. Diagnostic displays generated under
  performance 0.16.0 must not be treated as equivalent.
- gratia 0.11.2 adds or repairs derivative support for constrained
  `bs = "sz"` factor smooths, which the project uses.
- lme4 2.0-1 changes and corrects some GLMM scale and `VarCorr()` presentation.
  Models must be refitted rather than relying on serialized objects from a
  different runtime.

The manuscript currently reports LightLogR 0.10.2 and performance 0.16.0 at
`index.qmd:546`; the final Methods and software record must report the versions
actually used for the clean analysis.

## Decision

Retain LightLogR 0.10.3, suntools 1.1.0, and the installed modelling stack.
Implement the explicit API repairs only as part of the approved canonical
pipeline rebuild, with boundary-specific tests. Do not snapshot `renv.lock`
until all clean notebook runs and final renders pass.
