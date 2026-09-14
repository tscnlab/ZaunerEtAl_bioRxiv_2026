# H06_daily remaining non-L10 grid reopening

Decision ID: `H06-D-007`  
Change ID: `CHG-117`  
Date: 2026-08-12  
Status: approved for static verification and bounded production-code pilot

## Author authorization and role

The author explicitly directed the H06_daily task to resume the remaining
non-L10 daily-metric analysis grid and subsequently selected the hourly H06
analysis as primary, with H06_daily retained as complementary evidence.

This reopens only the unfinished part of H06_daily Stage 2. It does not reopen
either accepted L10 route, the completed MDER branch, the main hourly H06
analysis, shared preparation, Stage 3, Stage 4, website integration, or final
publication files.

## Exact scientific scope

The unfinished grid contains the following 13 registry slots:

1. daily geometric mean melEDI;
2. M10 mean melEDI;
4. duration above 1,000 lx melEDI;
5. duration above 250 lx melEDI while awake;
6. duration below 10 lx melEDI before sleep;
7. duration below 1 lx melEDI in the sleep environment;
8. longest continuous period above 250 lx melEDI;
9. M10 midpoint;
10. L10 midpoint;
11. mean timing above 250 lx melEDI;
12. first timing above 250 lx melEDI;
13. last timing above 250 lx melEDI; and
14. time-sensitive melEDI dose.

For each outcome, the three approved predictors remain separate: free versus
work day, Active versus Sedentary, and previous-night sleep duration. The
fixed-site hierarchy, sum-to-zero contrasts, equal-site reader
marginalization, participant random intercept, reduced-versus-additive
association test, additive-versus-predictor-by-site heterogeneity test,
registered random-site benchmark, response-family checks, actual-date AR
trigger, influence checks, and registered sensitivities remain exactly as
approved in H06-D-G1.

The scenario hierarchy is unchanged:

- primary near-eye all-available frames provide the primary tests and
  estimates;
- gap-timing-unaware near-eye all-available frames provide separately adjusted
  sensitivity tests and estimates;
- all-available chest and paired/common near-eye and chest frames provide
  complementary estimates, 95% confidence intervals, diagnostics, and
  matched-placement comparisons only, with no additional discovery screen;
- primary-versus-gap comparisons on common participant-day keys are
  sensitivities, not extra multiplicity families.

## Explicit exclusions and frozen results

- Slot 3, L10 mean melEDI, remains
  `NON_ESTIMABLE_COMPONENT_FAILURE` under the accepted two-part route, with raw
  and adjusted p-values missing. The stopped shifted-log pilot remains
  diagnostic history only. Neither L10 route may be fit or repurposed.
- Slot 15, MDER, retains the accepted `METRIC-010` models, raw tests,
  diagnostics, sensitivities, frames, and claims byte-for-byte. It is not
  refitted.
- The accepted pre-sleep no-nugget object remains frozen as a temporal-
  stability sensitivity. It may be cited or exactly reused only after an
  identity check; no duplicate no-nugget fit is authorized.
- The accepted 30-minute temporal H06_daily analysis is outside this grid and
  remains frozen.
- No main-H06 path, shared preparation file, central ledger, Quarto profile,
  manuscript file, package lock, or other hypothesis may be edited by the
  H06_daily task.

Existing task-owned pilot or model objects may be reused only when an R 4.6.1
check proves exact equality of source frame, response, formula, design matrix,
contrasts, family, optimizer, software identity, warnings, convergence, and
serialized object. Otherwise production fits are new H06_daily-owned outputs;
historical files are never overwritten.

## Current upstream pins

The new H06_daily input contract must pin these current identities before any
fit:

| Input | SHA-256 |
|---|---|
| `audit/decisions/preparation06_current_base_model_gate.md` | `63f17f1b9b3a91d437a5964cde063770d0fb4fac3f9c81e588fc374d9cc71f04` |
| `artifacts/12_manifests/metric_artifacts.csv` | `028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e` |
| `artifacts/12_manifests/base_model_data_artifacts.csv` | `8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce` |
| `artifacts/12_manifests/site_solar_context_artifacts.csv` | `c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518` |
| `artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds` | `b469fa8f0a743de1cbb1075f78879b84ab602c74cc44fb97da45dee596681f42` |
| `artifacts/06_model_data/base/metrics_chest_participant_day_enriched.rds` | `10aebeb5dabb53e8f3ee0747b62c31707da344e11b7068261c2ada2a0b7badc9` |
| `artifacts/06_model_data/normalized_inputs/exercisediary.rds` | `5bffe44cdd9c65f3d1dc20575d10b3f0a403577f3cf9109e83cfea95a2ae7107` |
| `artifacts/06_model_data/normalized_inputs/sleepdiaries.rds` | `110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15` |
| `artifacts/12_manifests/manuscript_prepared_data_artifacts.csv` | `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935` |
| `artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds` | `7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1` |
| `audit/decisions/mder_mean_of_viable_ratios.md` | `1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de` |
| `audit/decisions/l10_numerical_zero_normalization.md` | `23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797` |
| `config/site_display_registry.csv` | `3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809` |

The remaining current state-support reconstruction qualification in
`PREP06-BASE-002` must be carried as a provenance limitation; it is not
evidence that the data are wrong. Any mismatch in a pin, row count, key,
metric value, or frame invariant stops work before fitting.

## Multiplicity contract

The completed grid will contain twelve named 15-slot BH families:

- three predictor-specific association families and three predictor-specific
  site-heterogeneity families for the primary dataset; and
- the corresponding six separately adjusted families for the
  gap-timing-unaware dataset.

Registry order and `n = 15` are fixed. Slot 3 remains named `NA`; slot 15 uses
the frozen MDER raw test. The 13 new raw tests fill only their own slots.
Completing a family necessarily permits recalculation of BH-adjusted p-values,
ranks, and adjusted decisions across all 15 positions, including the derived
MDER adjusted field. It does not permit a change to an MDER raw p-value, model,
estimate, interval, diagnostic, or claim. Complementary chest and
paired/common results have no inferential p-value screen.

## Bounded pilot and runtime gate

The project has no active computation-heavy scientific job: the H01 production
bootstrap has completed, H05 is idle, and main H06 is frozen. H06_daily may
therefore begin the following serial bounded work:

1. build a new current-source input and preservation manifest;
2. prove in R that all non-L10 source columns and any reused representative
   pilot frames are invariant after `METRIC-010` and `METRIC-011`;
3. retain the earlier Gaussian-offset, Tweedie-log, and identity-Gaussian
   production-code pilot evidence only where exact reuse verification passes;
4. run a bounded clock-family pilot across the five timing outcomes and three
   approved predictors on primary near-eye frames, including the ordinary and
   strict-after-16:00 unwraps, using the exact proposed production hierarchy
   and diagnostic code; and
5. after an acceptable candidate model exists, run exactly 50 representative
   participant/site deletion refits across the consequential family classes,
   recording failures, warnings, checkpoint behavior, wall time, and the
   projected full Stage 2 runtime.

No bootstrap or simulation is authorized. The clock-family and 50-refit pilot
must write new H06_daily-owned manifests and must not modify historical pilot
artifacts.

Stop at `H06-D-G2P-NONL10` with the exact frame inventory, pilot diagnostics,
failure dispositions, affected model count, empirical runtime, projected full
runtime, and preservation audit. Full remaining-grid production requires
explicit author approval at that gate even if the projection is short.

## Later gates and report split

After an approved production run, H06_daily stops at its Stage 2 author gate.
Only an accepted Stage 2 result may proceed to the separate complementary
Stage 3 report specified by `H06-007`; Stage 4 remains blocked until Stage 3
is explicitly approved. This decision authorizes neither report now.

## Reopening condition

Reopen if a current input identity changes, a non-L10 invariance check fails,
the proposed response family or temporal rule fails, the model hierarchy or
multiplicity family changes, a frozen L10/MDER/main-H06 artifact changes, or
the author changes the primary/complementary role.
