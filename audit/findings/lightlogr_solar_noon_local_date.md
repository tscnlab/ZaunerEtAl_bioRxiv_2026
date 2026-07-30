# Solar-noon local-date handling in LightLogR 0.10.3

## Finding

`LightLogR::solar_noon()` can fail to preserve the requested site-local
calendar date west of UTC when its `dates` input is a `Date`. With
LightLogR 0.10.3 and suntools 1.1.0, requesting solar noon for the UCR
coordinates on 2024-06-15 in `America/Costa_Rica` returned
2024-06-14 11:36:39.711617 local time. Calling
`suntools::solarnoon()` with an
explicit 2024-06-15 00:00:00 local datetime returned
2024-06-15 11:36:52.567345 local time.

The cause is visible in the installed wrapper: it supplies
`as.POSIXct(dates, tz = tz)` to suntools. Conversion of a `Date` follows its
UTC-midnight instant before the requested display zone is applied
(2024-06-14 18:00:00 at UCR), whereas conversion of an explicit local
date-time string establishes the intended site-local day.

## Disposition in Preparation 05

- Civil dawn, civil dusk, and photoperiod continue to use
  `LightLogR::photoperiod()` with latitude-longitude input and a solar
  depression of 6 degrees. That wrapper constructs explicit local date
  strings and preserved all tested dates.
- Solar noon is calculated directly with `suntools::solarnoon()` after
  constructing midnight separately in each site's Olson time zone.
- Solar noon is labelled `contextual_metadata_only`; this repair does not add
  a predictor, outcome, estimand, or hypothesis.
- All event instants are POSIXct values stored in true UTC. Separate local
  labels, scalar wall-clock minutes in `[0, 1440)`, UTC offsets, and DST flags
  retain the local-clock plane without representing it as an absolute
  instant.

## Verification

`tests/test_site_solar_context.R` checks the nine pinned site-coordinate and
time-zone records, ordinary dates at all sites, European spring-forward and
fall-back dates, exact equality of dawn/dusk with
`LightLogR::photoperiod()`, exact equality of all three events with direct
suntools calculations, the corrected UCR local date, and tolerance of
non-structural provenance attributes inherited from metric RDS inputs.

An independent R verification also evaluated the union of all canonical
near-eye and chest participant-day dates: 616 unique site-date rows spanning
2023-08-15 through 2025-10-19. It reproduced every event instant, local label,
wall minute, UTC offset, DST flag, photoperiod, and local-day duration directly
from the pinned metadata and package calls. The domain included four observed
DST-transition dates (two 23-hour and two 25-hour local days).

The focused test passed under R 4.6.1 with LightLogR 0.10.3 and
suntools 1.1.0:

```text
Rscript --vanilla tests/test_site_solar_context.R
Site solar-context tests passed
```
