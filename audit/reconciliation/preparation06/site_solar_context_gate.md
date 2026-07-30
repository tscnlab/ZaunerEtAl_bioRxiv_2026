# Preparation 06 site/solar-context gate

Status: **PASS**  
Verified: 2026-07-30  
Authoritative runtime: R 4.6.1

## Scope

This gate verifies the main-analysis environmental context for the exact union of
near-eye and chest metric dates. It keeps true UTC event instants separate from
site-local labels and wall-clock coordinates and treats solar noon as
contextual metadata only.

## Verified inputs and definitions

- Pinned nine-site metadata SHA-256:
  `8aa5492ea357fa2e91b5d5fa3c9fd990ba82149632962320b4834e4e5693291b`
- Metric-artifact manifest SHA-256:
  `944f395e00735e6f8200798d4cde387454441d39b9defda68f583bd8778cd34b`
- Date domain: typed union of the near-eye and chest participant-day keys
- Civil-twilight boundary: solar altitude -6 degrees
- LightLogR: 0.10.3
- suntools: 1.1.0

## Verified outputs

The context contains 616 unique site-dates across all nine sites and spans four
observed DST-transition dates. All six daily, 30-minute, and one-hour
placement-domain joins have zero unmatched rows. The current context RDS
SHA-256 is
`4789e13ef14952ace91c45887e3276d87bac779e0cb26a8f2c3b9c36f0a0b1f4`.

The three-row deterministic manifest has SHA-256
`727f48016f430d1d48f1fe091c47bc7721011d72786fc691f3ca0d25a0a8386b`.
It contains no runtime timestamp or absolute path.

## Independent verification

- Direct LightLogR and suntools reconstruction matches every requested event
  and photoperiod value.
- The corrected site-local solar-noon date is retained west of UTC.
- Builder, independent verifier, two-build byte-stability, alternate-root,
  incomplete-domain rejection, and artifact/role tamper tests pass under
  R 4.6.1.
- The provenance repair leaves every scientific context artifact and every
  downstream model-facing RDS byte-identical.

## Reopening conditions

Reopen if coordinates, time zones, site-date domain, metric keys,
solar-depression definition, package versions, event-time representation,
site/solar producer, or deterministic-manifest schema changes.
