# H01 response-gate resolution

Date: 2026-07-31
Status: approved; implementation, repinning, and fit-stage verification
complete; production bootstrap pending
Decision IDs: `H01-007`, `H01-008`

## Gate A: time below 10 lx melEDI before sleep

The H01 outcome is the cumulative time below 10 lx melEDI across every
diary-defined pre-sleep interval that falls on the same local calendar date.
A calendar date can contain the post-midnight remainder of one pre-sleep
interval and the evening portion of the next. The value can therefore exceed
three hours without being duplicated or invalid.

The approved implementation:

- retains the calendar-day cumulative construct in the main and
  manuscript-prepared data and at both sensor positions;
- does not cap, truncate, replace, or exclude a valid value at three or six
  hours;
- uses 24 hours only as the physical calendar-day response bound; and
- treats values strictly above six hours as an audit warning that must be
  investigated before interpretation.

The six-hour threshold is a quality-control threshold, not the outcome
definition. The observed maxima before the present rebuild were 5.90 hours
near eye and 5.97 hours at the chest.

## Gate B: midpoint of the darkest 10 hours

The input remains local clock minutes. For the primary H01 response, convert
to decimal hours and subtract 24 hours only when the clock time is strictly
later than 16:00. A value exactly at 16:00 remains 16. This is a prefit
linearization of a nighttime clock variable; it is not a circular model, a
new outcome, or a different response family.

The noon conversion is retained as a named sensitivity. It must use the same
model rows, formulas, error distribution, link, contrasts, placements, and
data scenarios as the primary conversion. It does not enter the four primary
17-test Benjamini--Hochberg families.

## Required rebuild and verification

Both decisions are implemented in the shared H01 model functions so that the
same code is used for:

- main and manuscript-prepared data;
- near-eye and chest measurements; and
- all-available and paired/common-sample analyses.

After the revised Preparation 04 and 06 inputs pass independent verification,
the H01 input manifests, model outputs, diagnostics, source data, and output
manifest must be regenerated and re-pinned together. The checks must show:

- no pre-sleep value was truncated;
- no fitted pre-sleep value exceeds the 24-hour physical bound;
- any value strictly above six hours is reported as an audit warning;
- the primary L10 transformation uses the strict-after-16 rule, including the
  exact-16 boundary case;
- the noon sensitivity uses identical rows and model structure; and
- all previously open response diagnostics are rerun before H01 inference is
  released.

Any change to either construct, threshold role, clock cut, or sensitivity
membership reopens this decision.

## Completed verification

The shared preparation and H01 inputs were rebuilt and independently checked
before model fitting. The jointly pinned H01 input manifests are:

- main data:
  `ea9d47f624a8777f8416447612bfcc2309cf2bac40fdf4fd5021c8767806dfbf`;
- manuscript-prepared data:
  `cb47b3678146604aadca875a96f79909e2d73355162683ff0603f038f3b31a25`.

Gate A passes in both datasets and placements: no fitted value exceeds six
hours, no value was capped or truncated, and the calendar-day cumulative
construct is unchanged. Gate B passes in all eight analysis runs: the
strict-after-16 conversion is primary, the noon conversion uses identical
participants and participant-days, and it remains outside the four primary
BH families.

The fit stage produced 32 complete 17-row BH vectors. All-available analyses
have 17 observed tests per vector; paired/common-sample analyses retain 17
planned rows but have 15 observed tests because paired participant-level IS
and IV are explicitly non-estimable. R independently reproduced all adjusted
values with `p.adjust(..., method = "BH", n = 17)`. No fitted response produced
a major-gate failure. Production bootstrap intervals and the substantive
review of diagnostic warnings remain required before H01 is released.
