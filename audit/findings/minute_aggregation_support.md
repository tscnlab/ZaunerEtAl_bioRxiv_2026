# Native-epoch support within one-minute means

Finding ID: `FIND-014`  
Decision ID: `PREP-001`  
Status: full-source support audit verified; sensitivity implementation pending  
Audit date: 2026-07-30

## Question

Preparation 01 requires every expected native observation for a signal to be
finite before exposing its one-minute arithmetic mean. This audit asked
whether a lean alternative requiring at least 50% of the expected native
observations would recover enough information to justify changing the primary
rule or retaining a sensitivity.

The within-minute rule is distinct from the accepted primary coverage rule:
at least 50% valid MEDI minutes within a wall-clock hour and at least 80% of
the full 1,440-minute hybrid day after the hourly screen.

## Verified aggregation boundary

The native-epoch-to-minute conversion occurs in Preparation 01 after source
validation and true-UTC/pseudo-local timestamp annotation, and before diary
and wear-state joins, invalid-nonwear masking, the melanopic EDI operating
range rule, or Preparation 02 coverage.

Of 300 site-participant-placement streams:

- 298 use a 10-second epoch and expect 6 observations per minute;
- one RISE glasses stream uses a 1-second epoch and expects 60 observations
  per minute; and
- one FUSPCEU glasses stream already uses a 60-second epoch and expects one
  observation per minute.

All represented real-minute rows contain their complete timestamp schedule.
The partial cases below therefore reflect non-finite signal values within an
otherwise represented minute, not absent timestamp slots.

## Full-source support counts

The read-only audit used R 4.6.1 and the canonical Preparation 01 one-minute
artifacts. Counts are signal-specific because MEDI and LIGHT can be finite on
different native observations.

| Placement | Signal | Represented minutes | All expected finite | At least 50% but less than 100% | More than 0 but less than 50% | Zero finite |
|---|---:|---:|---:|---:|---:|---:|
| chest | MEDI | 1,798,560 | 1,546,130 | 727 | 159 | 251,544 |
| chest | LIGHT | 1,798,560 | 1,546,130 | 727 | 159 | 251,544 |
| glasses | MEDI | 1,635,960 | 1,400,723 | 2,314 | 236 | 232,687 |
| glasses | LIGHT | 1,635,960 | 1,400,736 | 2,387 | 155 | 232,682 |

A 50%-within-minute rule would add 727 chest minutes per signal, 2,314
glasses MEDI minutes, and 2,387 glasses LIGHT minutes. These additions are
0.040%, 0.141%, and 0.146% of represented rows, respectively, or 0.047%,
0.165%, and 0.170% relative to the strict finite-minute counts.

The difference is localized: KNUST contributes 93.0% of the recoverable chest
minutes and 98.2% of the recoverable glasses minutes. At KNUST the relaxed
rule would add approximately 0.48% and 1.6%, respectively, relative to its
strict finite-minute support.

## Decision

The complete-native-epoch rule remains primary. The recoverable fraction is
too small overall to justify changing the primary minute definition, and the
strict rule gives every reported minute an unambiguous complete-epoch
interpretation.

A fixed sensitivity will require at least 50% of expected finite native
observations within a minute, use the same arithmetic mean of the finite
values, and leave the accepted hourly and daily coverage thresholds
unchanged. Because the recoverable minutes are concentrated at one site, the
sensitivity must report site-specific support as well as overall result
stability.

## Provenance

- R: 4.6.1
- dplyr: 1.2.1
- tidyr: 1.3.2
- readr: 2.2.0
- openssl: 2.4.2
- lubridate: 1.9.5
- Import manifest SHA-256:
  `ab9a81d14932690ac0011fa11049ae97ab1c953d45295545b06b70e0389ffb57`
- Stream-epoch audit SHA-256:
  `fd0f532edfc0979b6aaed82589aa5b59c7ed494f83c655f1d662fcaefeb5156f`
- Aggregation implementation SHA-256:
  `4f8bb6a218c1fda6ba8affc15e76ea06ddca5d29c7e94788c159b9118d0ab67e`
- Preparation 01 builder SHA-256:
  `cfc3109c9511c2e31ba0c33d594963a14fe4a611d212df6d01c93d5def2280ae`

All 17 canonical one-minute RDS bytewise SHA-256 values independently matched
their manifest during the audit.
