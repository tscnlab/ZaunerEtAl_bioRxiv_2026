# Preparation 07 site/daylight-context equivalence audit

- Finding ID: `PREP07-PROV-001`
- Audit date: 2026-08-14
- Status: **scientific equivalence verified; provenance-only implementation pending author approval**
- Severity: **Low**
- Confidence: **Confirmed**
- Category: **Provenance and reporting**

## Scope and audit contract

This read-only audit asks whether the frozen Preparation 07 example-day
display remains scientifically valid after the shared site/daylight-context
RDS was repinned. It does not ask whether the two compressed RDS files are
byte-identical.

The audited artifact graph is:

```text
Preparation 07 reader display
  <- frozen PNG, SVG, selected-day table, and source-data CSV
  <- prepared-day showcase manifest
  <- prepared near-eye minute data, site metadata, and site/daylight context
  <- fixed-seed selection and stored site/daylight fields
```

The controlling invariants are:

1. the historical showcase manifest must continue to identify the exact file
   from which the frozen outputs were built;
2. the fixed-seed participant-day selection must reproduce independently;
3. the 12,960 stored one-minute rows must reproduce the prepared near-eye
   measurements and masks;
4. civil dawn, civil dusk, photoperiod, and solar-depression values for all
   nine selected site-days must equal the accepted current context; and
5. a later provenance repin must not be relabelled as the original producer
   input unless the display is actually rebuilt.

## Controlling identities

| Item | SHA-256 | Role |
|---|---|---|
| `artifacts/12_manifests/prepared_day_showcase_artifacts.csv` | `c5ca66b2a6ec4fabbe57d08135db7f365bcd123365caab6c987bcb2b62f7a322` | Truthful frozen-output manifest |
| Historical `site_solar_context.rds` recorded by that manifest | `b0e8de539572ee595cc91027e7a2d919ba01237f780e50a76e5e4468d497c4bf` | Exact producer input |
| Current accepted `site_solar_context.rds` | `39ffe488de86f5d7cdc56d65c582c9de31f9054f8565936b4ec74e01491f26d0` | Later provenance repin |
| Historical and current `site_solar_context.csv` | `7dc64cc5026947ef96d6e4ab112bb767414420be97817f022082248db68d7028` | Byte-identical tabular context |
| Frozen showcase source-data CSV | `15e12011effbdf8fdbf7835be235b7b50406838278d411df023e924e81bea1e4` | Displayed minute and daylight values |
| Frozen selected-day CSV | `36490be48ae13b5da8f7534af35652b90a3ee4b4c83ab595c5deb28c1f4c5481` | Nine selected participant-days |
| Pre-`METRIC-011` snapshot used for exact comparison | `61196c6f4f2dabda5d11f75ffeda9fc31eb0c0b988c357875cb368dc9001e7cf` | Read-only retained snapshot |
| Prepared-day independent verifier | `9a39ce7ab8e99187fdf14f2b750c3e3f9aa308de127e75a4923639dfb84d49b6` | Independent reproduction code |
| `METRIC-011` finalizer | `b7c9fcdc24c0cd3eae797e42df6478ed9f838ab2064849e4cf17bada06966de0` | Enforced exact context-value preservation |

## Runtime and commands

The authoritative runtime was R 4.6.1 (2026-06-24) with the project library:

- `dplyr` 1.2.1
- `readr` 2.2.0
- `digest` 0.6.39

The first normal-profile verifier launch was interrupted before audit code ran.
It was waiting for an `renv` sandbox lock in `renv_scope_lock()`. The successful
read-only audit used R 4.6.1 with the same project library explicitly placed
first in `.libPaths()`:

```sh
Rscript --vanilla -e '
.libPaths(c(
  normalizePath("renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/verify_prepared_day_showcase_artifacts.R")
verification <- verify_prepared_day_showcase_artifacts(
  root = normalizePath(".", winslash = "/", mustWork = TRUE)
)
print(verification$checks)
'
```

The retained pre-`METRIC-011` object and current object were compared in R
after removing only data-frame-level attributes other than `names`,
`row.names`, and `class`. No column attribute was removed. Their canonical
serialized audit digest was calculated with `digest` 0.6.39:

```r
snapshot <- readRDS("tmp/l10_METRIC011_before_snapshot.rds")
old <- snapshot$objects[[
  "artifacts/06_model_data/context/site_solar_context.rds"
]]
current <- readRDS(
  "artifacts/06_model_data/context/site_solar_context.rds"
)
strip_frame_provenance <- function(data) {
  attributes(data) <- attributes(data)[
    c("names", "row.names", "class")
  ]
  data
}
identical(
  strip_frame_provenance(old),
  strip_frame_provenance(current)
)
digest::digest(
  strip_frame_provenance(current),
  algo = "sha256",
  serialize = TRUE
)
```

The selected-day comparison read the frozen source-data CSV and current
context CSV as character data, matched `site` and `local_date`, and required
exact string equality for:

- `civil_dawn_wall_minute`;
- `civil_dusk_wall_minute`;
- `photoperiod_hours`; and
- `solar_depression_deg`.

## Results

### Independent showcase verification

The independent verifier returned 17 `PASS` checks and one expected `FAIL`:

- `manifest::input_hashes`: `FAIL`, because the historical producer hash and
  current repinned RDS hash are intentionally different;
- fixed-seed selection: `PASS` for all nine sites;
- selected-day keys: `PASS`;
- eligible-day counts: `PASS`;
- complete minute grid: `PASS` for 12,960 rows, with 1,440 minutes per selected
  day;
- prepared minute, timestamp, melEDI, state, measurement-context, and non-wear
  parity: `PASS`;
- current site/daylight-context parity: `PASS`;
- settings, figure presence, artifact hashes, sizes, and table dimensions:
  `PASS`.

Thus the verifier's overall `FAIL` is attributable only to exact whole-file
input identity. It does not indicate a selected day, value, mask, figure, or
claim discrepancy.

### Full context equality

The pre-`METRIC-011` and current context objects have:

- 618 rows and 47 columns;
- zero changed columns and zero changed cells after removal of only the
  frame-level provenance attributes;
- identical `site_solar_settings`;
- identical `site_metadata_sha256`; and
- identical canonical stripped-object SHA-256
  `ce80f9418fbfe7e6a4dc774478305be41f880d666f366a491b4184d2ef2e9eaa`.

The sole observed object-level change is the `input_sha256` provenance
attribute. Six entries changed after upstream metric repinning:

- near-eye daily, 30-minute, and one-hour inputs; and
- chest daily, 30-minute, and one-hour inputs.

The manuscript-prepared participant-day input pin is unchanged. These input
identity updates explain the RDS checksum change without changing any
site/daylight value.

### Selected showcase days

For each of the nine selected site-days, the frozen source-data CSV and the
accepted current context CSV have exact character-level equality for all four
site/daylight variables used by the showcase. Every selected day has exactly
1,440 stored minutes.

### Historical chain

The historical-to-current chain is also supported by existing central
evidence:

- `CHG-100` records that all 618 by 47 site-context values remained exactly
  unchanged during the primary `METRIC-010` repin;
- `CHG-101` records the same 618 by 47 exact preservation during the
  gap-timing-unaware `METRIC-010` repair; and
- `audit/scripts/finalize_l10_METRIC_011.R`, lines 297-313, rebuilt the context
  for the later upstream pins and aborted unless the old and new context frames
  were exactly identical after removal of frame-level provenance attributes.

## Finding

| Field | Disposition |
|---|---|
| ID | `PREP07-PROV-001` |
| Severity | Low |
| Confidence | Confirmed |
| Category | Provenance and reporting |
| Evidence | Historical manifest pin differs from the current RDS pin, while the full scientific context and all selected-day values are verified equal |
| Invariant | Historical build provenance must remain truthful, and current scientific equivalence must be verified separately |
| Consequence | The current Preparation 07 same-file assertion blocks rendering, but no data, output, or scientific claim is affected |
| Remediation | Preserve the historical manifest and strict verifier; add a separately sealed equivalence check and distinguish original producer identity from accepted current equivalent identity in the reader report |
| Closure test | Source and HTML pin both hashes, consume this sealed equivalence record, retain all existing scientific and artifact checks, and complete the bounded render without rebuilding any showcase artifact |

## Disposition and implementation boundary

No prepared-day selection, data, figure, SVG, source CSV, manifest, scientific
output, or claim requires rebuilding or changing.

The historical `prepared_day_showcase_artifacts.csv` must not be rewritten to
claim that the current RDS produced the frozen artifacts. The strict historical
verifier may continue to fail its exact current-input check when run against a
later provenance-only repin. A separate reconciliation-aware report check is
the appropriate closure mechanism.

This record does not authorize source, test, manifest, render, ledger, or
artifact changes. The bounded implementation remains subject to explicit
author approval and independent source/test review before any rerender.

Structured checks are recorded in
`audit/reconciliation/preparation07/site_solar_context_equivalence_evidence.csv`.
The non-circular file seal is recorded in
`audit/reconciliation/preparation07/site_solar_context_equivalence_manifest.csv`.
