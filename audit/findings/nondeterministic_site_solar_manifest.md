# Nondeterministic site/solar-context manifest metadata

Status: `repair_verified`

Date: 2026-07-30

## Finding

A clean Preparation 06 render regenerated the site/solar-context manifest with
a different SHA-256 even though the site/solar RDS, durable CSV, and join audit
were byte-identical. The manifest copied each writer's runtime `written_utc`
value and stored absolute project paths. The timestamp made content identity
depend on execution time; the absolute paths made it depend on the local
checkout location.

Because the base-model input bundle correctly pins the site/solar manifest,
this provenance-only change reopened the base and pre-analysis comparison
gates. No site, date, solar event, metric value, row, key, participant,
participant-day, or model-facing value changed.

## Repair

The site/solar manifest now has an exact 24-column deterministic schema. It:

- omits runtime write timestamps;
- records output, metric-input, and site-metadata paths relative to their
  declared roots;
- rejects any path outside its declared root instead of silently preserving an
  absolute path; and
- retains artifact hashes, byte sizes, dimensions, input hashes, site/date
  domain, solar definitions, package versions, producer, R version, and
  status.

The independent verifier reconstructs the expected relative paths and exact
schema without calling the producer.

## Verification

- Two consecutive R 4.6.1 production builds produce site/solar manifest
  SHA-256
  `0f685d7c7d6ee01acd97f9440670763689ba9c0b12e9b5dc7b2b58bdc31196c9`.
- The canonical context RDS remains byte-identical at SHA-256
  `3a6b119fe82f95089aa19fe6e369e3a071699774566551b063e7207911b63efa`.
- The context still contains 616 site-dates across nine sites, including four
  observed DST-transition dates; all six metric-domain joins have zero
  unmatched rows.
- The rebuilt base layer has input-bundle SHA-256
  `7a4540dceca5469c608633ef35923b0af0b841c2f5bba4dc0450c0632f258702`
  and manifest SHA-256
  `68d3512c83c5aed0f505522b06f8be346aa9da60a9c5a4ebc7fb71648076574a`.
  All 20 base artifacts other than provenance remain byte-identical.
- The pre-analysis comparison manifest is
  `d62dc8ae0182bcf0c40eb75f070b3c7c9244f499731b611831916c614249856e`.
  All 12 scientific tables and figures remain byte-identical; only its three
  provenance/reporting artifacts changed.
- Builder, independent verifier, two-build stability, alternate-root, and
  tamper-rejection tests pass.

## Reopening condition

Reopen if runtime metadata, an absolute checkout path, a random identifier, or
another execution-specific value enters a deterministic site/solar artifact
or manifest.
