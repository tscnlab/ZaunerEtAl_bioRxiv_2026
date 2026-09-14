# Preregistration-deviation page generation and focused-render verification

Date: 2026-08-12  
Controlling decisions: REPORT-016 / CHG-126  
Status: **generated and focused-render verified; inbound owner links and shared navigation remain pending**

## Source authority and execution boundary

The page was generated deterministically from:

- the preserved historical `audit/ledgers/deviation_register.csv`;
- the reconciled `audit/ledgers/deviation_hypothesis_crosswalk.csv`; and
- the authoritative current overlay `audit/ledgers/deviation_reader_dispositions.csv`.

The overlay identity matched the sealed REPORT-016 SHA-256 value
`0ae6f9d0ea161759d1a514c3c8ca7ac6869f5cf7634e7af8198224fa8b5cac6d`.
The existing R 4.6.1 disposition validator passed with 86 stable IDs, 43
current source locators, and the exact 60/1/19/6 reader-section split.

No data preparation, model fitting, prediction, simulation, bootstrap,
Shapley analysis, sensitivity analysis, or scientific output was run. The QMD
contains no executable analysis chunks, and the focused render used
`--no-execute`.

## Generation and source checks

Generator:

```text
NATHEALTH_PROJECT_ROOT=. Rscript --vanilla \
  scripts/report_harmonization/generate_preregistration_deviations.R
```

Focused contract:

```text
NATHEALTH_PROJECT_ROOT=. Rscript --vanilla \
  tests/report_harmonization/test_preregistration_deviations.R
```

Result under R 4.6.1:

- 86 unique stable IDs and exact lower-case explicit anchors;
- four visible sections containing 60 current scientific deviations, one
  current qualification, 19 resolved implementation-history records, and six
  technical-provenance records;
- every entry contains topic, plain current disposition, preserved registered
  or expected statement, current analysis, rationale, affected hypotheses,
  interpretive consequence, related IDs, and current source locators;
- no underscore-delimited machine status appears in reader prose;
- all source QMD links and related-record anchors resolve;
- no hard-coded source `.html`, `file://`, `_build`, or absolute local link;
- every displayed study-site name carries its country code; and
- a fresh temporary generation is line-identical to the checked source.

## Focused render

Quarto 1.9.37 rendered a staging copy of the exact generated QMD with its
relative QMD targets exposed at the same project-relative paths:

```text
quarto render notebooks/preregistration_deviations.qmd \
  --to html --no-execute
```

The output and support files were copied without modification into the owned
`audit/report_harmonization/deviation_render/` directory. The render contains
all 86 unique entry anchors plus the required section anchors. A 1440 x 1800
headless-Chrome screenshot confirms clean title, introductory hierarchy,
callouts, body typography, margins, and first-viewport wrapping without
overlap or clipping.

## Identities

- generated QMD: `b542018a0e127b280fc5a106928d8689307c420f2e62913f4047d5c4c292bc6d`
- generator: `3cac351d6d29e96a67fb3a0f630ceac3bc51ef9dc738b56236ce2091a49cf95a`
- focused test: `65fbff3ff6075b751f909af6fdf8c9844ba8248f0efc9c33bb26ca009fed8be5`
- focused HTML: `5fe5a5e9c9d68229252437e6f96d75bbe1a1a15a154c669f3a3c907d9945d9a8`
- visual preview: `733b624d6bfc182240d126880d36754792e06c5f685aa6dc5600830a2ecb2a0f`

All rendered support-file identities are listed in
`audit/report_harmonization/deviation_render_manifest.csv`.

## Remaining gate

DOC-001 remains pending. The page itself and its anchors pass, but exact
inbound links from every reader-facing deviation mention and shared Nature
Health navigation must be implemented and verified before documentation
closure is requested.
