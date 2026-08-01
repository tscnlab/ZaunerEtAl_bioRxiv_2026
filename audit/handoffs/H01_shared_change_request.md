# H01 shared-change requests

Current overall status: **resolved — the coordinator repaired the shared
Quarto project cache and the H01 Stage 3 Nature Health profile render and
H01-owned verification now pass.**

## Resolved request: pre-sleep analytical-day definition

Date: 2026-07-30; resolved 2026-07-31  
Status: **resolved by `H01-007`; shared rebuild, repinning, and H01 fit-stage
verification complete**  
Requester: H01 hypothesis worker  
Owner for review: coordinating Nature Health retargeting task

## Question that required a decision

Resolve the mismatch between:

- the approved H01 construct, “time below 10 lx melEDI in the three hours
  before sleep,” with a required three-hour ceiling; and
- the current shared participant-day producer, which aggregates every
  pre-sleep minute occurring on a local calendar date.

The shared implementation is internally consistent, but a local calendar
date can contain the post-midnight portion of one three-hour pre-sleep
interval and the evening portion of the next. The resulting daily domain can
legitimately contain up to six hours under the implemented calendar-day
aggregation, which is not the prefit H01 estimand.

## Exact evidence

For main data:

- near eye: 142 participant-days have 181–360 expected pre-sleep minutes;
- chest: 143 participant-days have 181–360 expected pre-sleep minutes;
- every affected placement-specific day contains two distinct source
  pre-sleep intervals; and
- for every affected day, the sum of projected source-interval minutes
  exactly matches `metric_support_expected_minutes`.

The fitted pre-sleep outcomes exceed three hours on 60/645 near-eye and
67/736 chest participant-days. The maximum qualifying duration is 5.90 h
near eye and 5.97 h at the chest.

Evidence and provenance:

- `audit/hypotheses/H01/H01_shared_pre_sleep_interval_evidence.csv`
- `audit/hypotheses/H01/superseded/H01_pre_sleep_three_hour_diagnostic.csv`
- `audit/hypotheses/H01/H01_major_gate_provenance.csv`
- `scripts/hypotheses/H01/audit_h01_major_gates.R`

## Alternatives considered

1. Define an episode-anchored analytical day and assign each complete
   pre-sleep interval to its associated attempted-sleep episode.
2. Retain local-calendar-date aggregation but rename the estimand as
   cumulative exposure across all pre-sleep intervals on that date and remove
   the three-hour ceiling.
3. Exclude the metric where the registered construct cannot be represented.

The author selected alternative 2. The outcome is now explicitly the
calendar-day cumulative time below 10 lx melEDI across all diary-defined
pre-sleep intervals on that date. Valid values are not capped or truncated.
Values strictly above six hours trigger an audit warning, not exclusion or
replacement. The full decision is recorded in
`audit/decisions/h01_gate_resolution.md`.

## Affected downstream hypotheses

A change to this shared daily metric reopens every planned analysis that uses
pre-sleep duration below 10 lx melEDI:

- H01;
- H05;
- H07;
- H08; and
- H10.

The L10-midpoint response gate documented in
`audit/hypotheses/H01/H01_major_change_gate.md` additionally affects response
modelling in H01, H05, H09, and H10, but it does not by itself establish a
shared metric-derivation defect. If its resolution changes the metric rather
than only the response model, those same hypotheses require rebuilt
model-data artifacts.

## Required downstream action

The coordinating task updated the decision and central audit ledgers, rebuilt
Preparations 04 and 06, verified both H01 data scenarios, and repinned the main
and manuscript-prepared manifests together. H01 then reran the full fit stage,
all four 17-row model-test families, fitted-model diagnostics, confidence
intervals, exact sample reports, and the same-row noon sensitivity from those
new identities. No earlier fitted result or partial multiplicity adjustment
was carried forward. Production bootstrap intervals, diagnostic-warning
review, result comparisons, and final claim review remain open.

## Earlier Quarto resource-discovery issue (historical)

Date identified: 2026-08-01  
Status: **superseded by the current, separately reproduced Quarto issue below**

The authorized hypothesis-only render command

```sh
quarto render notebooks/hypotheses/H01.qmd --profile nathealth
```

stops during shared project resource discovery, before the H01 document is
executed, because the configured or discovered path
`audit/hypotheses/H11/01_audit_and_plan_files` does not exist. This is not an
H01 analytical or document error, and H01 has not created the missing H11
path or changed shared Quarto configuration.

The H01 document has instead been rendered for review through an isolated
temporary H01-only wrapper outside the repository that mirrors the Nature
Health HTML options and consumes the same H01 source and artifacts. That
preview is suitable for layout and structural review, but it does not close
the required `--profile nathealth` render check.

### Affected downstream work

- the final H01 Nature Health profile render;
- H11 resource discovery; and
- any full or hypothesis-only Nature Health render that traverses the same
  shared project resource graph.

### Requested coordinator action

Resolve the stale or missing H11 resource reference in coordinator-owned
project state, then rerun the exact H01 profile command above. No analytical
refit is required solely for this render-discovery repair.

## Current shared-change request: Stage 3 Quarto render infrastructure

Date identified and reproduced: 2026-08-01  
Resolved: 2026-08-01  
Status: **resolved; coordinator-owned shared project repair completed and
H01 verification passed**  
Requester: H01 hypothesis worker  
Scope: rendering only; no scientific model, bootstrap, prediction, or
source-data calculation needs to be repeated

### Resolution

The coordinator confirmed that no Quarto or Pandoc process was active, then
moved the stale shared project cache recoverably to:

```text
/private/tmp/nathealth-quarto-cache-backup.AYhadH/project-cache
```

The coordinator then ran only the H01 Nature Health profile render with R
startup isolated from the user profile, the activated R 4.6.1 project
library, and the temporary renv sandbox:

```sh
env R_PROFILE_USER=/dev/null \
  R_LIBS_USER=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  RENV_PATHS_SANDBOX=/private/tmp/H01-renv-sandbox-R4.6.1 \
  NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
  quarto render notebooks/hypotheses/H01.qmd --profile nathealth
```

All 55 cells completed, the render exited 0, and a clean project cache was
regenerated. The resulting Stage 3 HTML has SHA-256
`10f2701f0b446fcc698c843787ff6130ff34147e4eea9ea540b8498966a7c2a8`;
the rendered QMD source identity is
`69368994f996d75fa24980ec7c6fc71366f21d8aaf8cca6f4a2cd51dbce39ed6`.
The page contains 23 semantic `gt` tables and eight local figures, has no
cell-output errors, and every figure has non-empty alt text. The H01 reporting
test was updated from its obsolete Stage 2 pilot contract to the accepted
Stage 3 production contract and passes. The H01 worker made no shared Quarto,
dependency, preparation, manuscript, or central-ledger change.

### What passes

- The bounded, source-aware environment check passes:

  ```sh
  Rscript --vanilla scripts/environment/run_renv_status_safe.R \
    /Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
    60 true
  ```

  It reports `Timeout-controlled renv status passed`.
- R 4.6.1 starts with the activated project library when its renv sandbox is
  redirected to an H01-safe temporary directory.
- With that redirect, all 55 executable cells in
  `notebooks/hypotheses/H01.qmd` completed and `H01.knit.md` was written.
  This establishes that the Stage 3 R source and its stored reporting inputs
  are executable. The cells read verified fitted and bootstrap outputs; they
  do not refit the scientific models.
- The H01 reporting-input builder and the source-only chunk check pass. The
  reporting manifest contains the accepted, stored outputs and does not call
  for a bootstrap rerun.

### Reproduced failure sequence

The installed versions are Quarto 1.9.37, R 4.6.1, knitr 1.51, and gt 1.3.0.

1. The ordinary hypothesis-only profile render spent more than 40 minutes in
   R startup/renv activation. A process sample remained in `R_LoadProfile`
   while renv repeatedly attempted to create or inspect its default macOS
   sandbox below:

   ```text
   /Users/zauner/Library/Caches/org.R-project.R/R/renv/sandbox/macos/R-4.6/aarch64-apple-darwin23/46003b10
   ```

   That location is outside the H01 worker's writable project and temporary
   roots. Redirecting only `RENV_PATHS_SANDBOX` to
   `/private/tmp/H01-renv-sandbox-R4.6.1` allows R startup to complete.

2. With the renv sandbox redirected, all H01 chunks completed, but Quarto then
   failed while opening its macOS Sass cache with:

   ```text
   ERROR: unable to open database file
   Deno.openKv ... sassCache
   ```

   Quarto 1.9.37 derives this database from the macOS user-cache location
   `~/Library/Caches/quarto/sass/sass.kv`, which is also outside the H01
   worker's writable roots. `XDG_CACHE_HOME` does not redirect this particular
   Quarto path on macOS, and the H01 worker did not repurpose `HOME`.

3. Repeating the narrow render with approved access to the macOS cache moved
   past the Sass-cache failure but stopped immediately during shared project
   input/resource discovery:

   ```text
   NotFound: No such file or directory (os error 2): stat
   '/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/site_libs'
   ```

   The stack was in Quarto's `projectInputFilesInternal`/glob expansion. No
   root `site_libs` directory currently exists. In contrast,
   `_build/nathealth/site_libs` and `.quarto/_freeze/site_libs` do exist, and
   none of `_quarto.yml`, `_quarto-nathealth.yml`, or `_quarto-website.yml`
   explicitly declares `site_libs`. The shared `.quarto/project-cache`
   therefore appears to contain or derive stale shared resource state. The
   H01 worker did not create a root `site_libs`, delete or rewrite shared
   `.quarto` state, or edit shared Quarto configuration.

### Consequence for the current report

The consequence described here is resolved. At identification time,
`_build/nathealth/notebooks/hypotheses/H01.html` was still the accepted Stage
2 comparison page with SHA-256
`4daa424552ce83cd0a5879cae4ced62d6ca75c4703bc0a1b3be2806ff332c10e`.
It has now been replaced by the successfully rendered Stage 3 standalone
results report with SHA-256
`10f2701f0b446fcc698c843787ff6130ff34147e4eea9ea540b8498966a7c2a8`.

### Affected downstream hypotheses

H01 is no longer blocked. At identification, the possible shared blast radius
included **H01, H02, H03, H04, H05, H06, H07, H08, H09, H10, and H11** because
all use the same profile and project scratch. Only H01 was reproduced before
the repair and only H01 was rendered and verified as part of this request;
the resolved record therefore does not assert independent render verification
for the other hypotheses.

### Requested coordinator action

All requested actions are complete: the stale project cache was removed
recoverably, the coordinator-approved isolated render environment was used,
only H01 was rendered, the render log and HTML identity were returned, and the
H01 worker completed structural and direct figure verification. No full-project
render or scientific recomputation was performed.

### Current H01 evidence hashes

| Evidence | SHA-256 |
|---|---|
| Stage 3 QMD source | `69368994f996d75fa24980ec7c6fc71366f21d8aaf8cca6f4a2cd51dbce39ed6` |
| Stage 3 reporting-input builder | `fa197828f3e3af9408d478120a14f58bc16bcd3183009d45ce843f928c86da2b` |
| Stage 3 reporting manifest | `99a9bec92891bc83ca751d85128bf1b9fdde68fcfd24badc9943e8c7cccc459e` |
| Stage 3 reporting provenance | `399d9059977dea270529c429c67bc420bff60ff432b33d298bb2fbe5c0aed00f` |
| Near-eye photoperiod/latitude PNG | `0bf40dbcfb09009d1cfaa48915860f8aacd89982ff347175d4fdcc309a7a88a7` |
| Chest photoperiod/latitude PNG | `2d7a52fa342f4e7ea395a406e236951521a38e5ca481798a3289b62f2165edcd` |
| Main H01 model-data manifest | `ea9d47f624a8777f8416447612bfcc2309cf2bac40fdf4fd5021c8767806dfbf` |
| Gap-timing-unaware internal model-data manifest | `cb47b3678146604aadca875a96f79909e2d73355162683ff0603f038f3b31a25` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

No shared preparation file, central ledger, shared Quarto configuration,
shared Quarto scratch/cache, manuscript file, or dependency record was changed
by the H01 worker while investigating this issue.
