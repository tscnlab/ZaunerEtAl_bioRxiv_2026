# H06_daily remaining non-L10 production authorization

Decision ID: `H06-D-013`  
Change ID: `CHG-123`  
Date: 2026-08-12  
Status: author approved; Stage 2 production authorized

## Author decision and boundary

The author authorizes the complete remaining non-L10 H06_daily Stage 2
production grid. The four repaired timing outcomes use the participant-cluster
HC3 route accepted under `H06-D-011`; the other nine outcomes use their
previously approved metric-specific routes. All diagnostic qualifications are
retained. L10, MDER, the temporal GAMM, the pre-sleep no-nugget sensitivity,
and the selected main hourly H06 analysis remain frozen.

This decision authorizes Stage 2 production and its task-owned implementation
report only. It does not authorize Stage 3, Stage 4, website integration,
shared edits, a main-H06 change, commit, or push. The mandatory next stop is
the H06_daily Stage 2 author gate.

## Current authoritative input pins

Every pin below was reverified immediately before this authorization. Any
mismatch stops execution before fitting.

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

The current state-support reconstruction qualification in `PREP06-BASE-002`
must remain visible as a provenance limitation. It is not evidence that the
current data are analytically wrong.

## Exact production inventory

The controlling inventory is
`artifacts/06_model_data/H06_daily/H06_daily_non_l10_pilot_frame_inventory.csv`,
SHA-256
`639eaa04595f5fc83ef9633da4b66bd14123480a1322c43e5e6ac4d80eb40bce`.
It contains 468 prespecified frames:

- 13 unfinished non-L10 registry slots: 1, 2, and 4--14;
- three predictors: Work versus Free day, Active versus Sedentary, and
  previous-night sleep duration;
- two prepared datasets: primary and gap-timing-unaware;
- near-eye and chest placements; and
- twelve fixed scenario roles: primary near-eye all-available, chest
  all-available context, paired/common near-eye and chest, their
  gap-timing-unaware counterparts, and primary-versus-gap dataset-common
  frames at each placement.

Before fitting, rebuild every frame from the pinned current sources and prove
its key, row order, response, predictor, site, participant, sample counts,
missingness, contrasts, transform, and serialized object identity against the
468-row inventory. Do not update a pin to accommodate a mismatch.

Primary near-eye all-available frames supply primary tests. Gap-timing-unaware
near-eye all-available frames supply separately adjusted sensitivity tests.
Chest, paired/common, and dataset-common roles supply estimates, pointwise 95%
confidence intervals, diagnostics, and comparisons only; they do not create
additional discovery screens.

## Model routes

### Previously approved routes for nine outcomes

Use the exact frozen-frame hierarchy:

```r
response_value ~ site + (1 | participant_key)
response_value ~ site + predictor + (1 | participant_key)
response_value ~ site * predictor + (1 | participant_key)
```

Site uses sum-to-zero contrasts. The reduced-versus-additive comparison tests
the overall association; additive-versus-predictor-by-site tests whether the
association differs by site. Gaussian comparisons use ML and final estimates
use REML. Tweedie-log comparisons use the same likelihood family and exact
frame. The exact registered random-site/random-slope model remains a visible
benchmark only when its design is estimable and its fit converges without
singularity.

The approved outcome routes are fixed:

- Gaussian on `log10(outcome + 0.1)` for slots 1, 2, 8, and 14;
- Tweedie with log link for slots 4, 5, and 7;
- Gaussian identity for slot 6; and
- Gaussian clock-hour response for slot 11.

Retain the prespecified convergence, singularity, distributional, zero-mass,
bounds, residual, actual-date gap-aware AR-trigger, response-family,
registered-benchmark, participant-deletion, and site-deletion checks. A
sensitivity model never silently replaces the approved route.

### Participant-cluster HC3 route for four repaired timing outcomes

For slots 9, 10, 12, and 13, use the accepted participant-day timing response
and fixed-site linear hierarchy uniformly in every authorized frame:

```r
response_value ~ site
response_value ~ site + predictor
response_value ~ site * predictor
```

Calculate covariance exactly as:

```r
sandwich::vcovCL(
  model,
  cluster = ~ participant_key,
  type = "HC3",
  cadjust = TRUE,
  fix = FALSE
)
```

Use cluster-minus-one t/F reference distributions and pointwise 95%
confidence intervals. The predictor block supplies the association test; the
predictor-by-site block supplies the site-interaction test. No random-intercept
or likelihood-ratio result may be substituted for this route.

Retain, without dilution, the two major limitations: the 1.23-HC3-SE
Student-t shift for first timing Work versus Free day and the 1.26-HC3-SE
no-nugget AR shift for L10-midpoint activity. Retain the three unresolved
additive AR checks, the failure of every pilot AR structure to meet the
descriptive lag rule, and the sensitivity-dependent timing site interactions.
Student-t and no-nugget AR analyses remain diagnostics, not replacement
estimands. A significant production test cannot remove these qualifications.

If an authorized production frame fails rank, covariance, estimability, or
diagnostic requirements, record the declared non-estimable or qualified
result. Do not select a different model by predictor, site, p-value, or desired
direction.

## Frozen outcomes and preservation contract

- Slot 3, L10 mean melEDI, remains a named missing test under the accepted
  two-part component-failure disposition. The shifted-log pilot remains
  stopped diagnostic history.
- Slot 15, MDER, retains its accepted `METRIC-010` raw tests, models,
  estimates, intervals, diagnostics, sensitivities, and claims byte-for-byte.
- The accepted temporal GAMM, pre-sleep no-nugget sensitivity, all historical
  pilots, and main hourly H06 remain frozen.

The task-owned pre-production preservation pins are:

| Item | SHA-256 |
|---|---|
| Non-L10 pilot input manifest | `38e5b87564b7b234de85b5af5fa4e30edc389c4f83b87f6a9d7ddf119d225aec` |
| Non-L10 pilot output manifest | `cdb39a93ef7fc48ab9bf5bc3919b7b777de36a830a5326ce1e803fa0a8f0c10e` |
| Non-L10 preservation record | `c716a55da1d6f0c3add00f8f8e6cb42f425431e024108b14ac7b369a02c94c99` |
| Timing-repair input manifest | `05d9fc2e99206ae293d24534f279fb835ad1062f683610701e770db73fbbc8e5` |
| Timing-repair output manifest | `43e83b27e2261cadf9fc9a558c7cbd8b540799df761a51dd9fc1910582ccc90e` |
| Timing-repair preservation record | `b49fe6f4d37cf3d6e85b9a6a95f55e1e6605c6b66fc3862d7522b8ec7ef430d8` |
| Timing-route acceptance manifest | `6285cb23d026ad199d9d6b6b4321f41fdeed4e6ae00978f84b71f8abd0a1d5bc` |
| H06-D-012 closure | `a8e502ca17f9b37bd00c32a0f7e4188d6d14a80b832aa8d7f27964d089fa1bbc` |
| H06_daily timing-route acceptance addendum | `f599037964d636d44c3b736bcf715ec2eff125de59466e6cbd248e75bef99067` |

The 571-row timing-repair preservation record contains 119 MDER, 209 L10, 37
pre-sleep, and 160 temporal-branch identities, all byte-identical at
authorization. Create a new immutable pre-production baseline that includes
those 571 paths, the no-refit closure files, every historical H06_daily pilot,
and all new controlling decisions. Rehash it before fitting and after every
production phase. Production outputs must use new H06_daily-owned paths and
must never overwrite historical artifacts.

Main hourly H06 is separately frozen at these current identities:

| Main-H06 item | SHA-256 |
|---|---|
| `notebooks/hypotheses/H06.qmd` | `44a461a44e26413bc919268de20a218b1a272cf442177ae4a732f2805f53f18b` |
| `audit/hypotheses/H06/H06_analysis_preparation.qmd` | `a4b35a1997fdae48b2e751d31a70147bd4149354eddd2a703d6473abbc67ea97` |
| `artifacts/12_manifests/H06/H06_stage3_artifacts.csv` | `d77054228581a2700f80f0c571536ae2799a7e5ac0f6869d189767e0dfe3bb21` |
| `artifacts/12_manifests/H06/H06_preparation_report_manifest.csv` | `db976477b9cdbce2a6d4575e382b2f04062e8834c086f1d82cb25d7e8a2176e4` |
| `audit/handoffs/H06_worker_handoff.md` | `5080334fa1f1ac82c60359111b5aa44065cdf2075e3a7a672fd9c225e3ba3829` |

Any main-H06 mismatch or task-owned edit stops production.

## Multiplicity contract

Assemble exactly twelve dataset-qualified FDR families:

- for the primary dataset: association and site-interaction families for each
  of the three predictors; and
- for the gap-timing-unaware dataset: separate association and
  site-interaction families for each predictor.

Each family retains all 15 named registry slots in fixed order. Slot 3 is a
named `NA`; slot 15 uses the frozen MDER raw p-value. The 13 production tests
fill only slots 1, 2, and 4--14. Apply the existing Benjamini--Hochberg method
at full precision to the complete named vector; do not drop an unavailable
slot or form a smaller family. Recalculation may change only mathematically
dependent adjusted p-values, ranks, and adjusted decisions. It may not change
the frozen L10 or MDER raw result, model, estimate, interval, diagnostic,
sensitivity, or claim. Complementary/paired/common roles receive no
additional p-value screen.

## Diagnostics, influence, and failure handling

Run the complete prespecified diagnostic and influence battery for every
estimable production route, including participant- and site-deletion analyses,
with checkpointed serial execution. Preserve raw full-precision diagnostic
and inferential outputs. No bootstrap or simulation is authorized.

Use the approved failure contract: preserve the slot and record
`NON_ESTIMABLE`, `NOT_ACCEPTABLE`, or the applicable qualified status rather
than silently changing family, transform, random structure, covariance,
temporal rule, sample, or multiplicity denominator. Stop early if failures are
systemic, a frozen identity changes, or the observed runtime materially
exceeds the verified bounded projection without a reliable checkpoint.

## Compute coordination

The verified pilot projects approximately 1.9 minutes for the base grid and
30.5 minutes for 66,664 participant/site deletion refits, before triggered AR
checks, diagnostics, and reporting. The earlier timing-repair pilot is also
bounded. At authorization, no other project task is running a
computation-heavy scientific fit or resampling job; the active harmonization
task is documentation-only and main H06 is frozen. H06_daily is therefore
cleared to launch one serial checkpointed production batch now. Recheck task
state immediately before launch and do not overlap a newly started heavy job.

No further runtime pilot is required. An unexpected projected or observed
runtime above one hour, repeated checkpoint failure, or systemic model failure
triggers a stop and coordinator report rather than unreviewed continuation.

## Stage 2 deliverables and mandatory stop

Complete the H06_daily Stage 2 implementation and V0 comparison from the
sealed production outputs. Report exact fitted participants, participant-days,
sites, estimates, pointwise 95% confidence intervals, full FDR families,
diagnostics with explicit acceptable/not-acceptable assessments, influence
results, near-eye primary results, chest and paired/common complementary
evidence, primary-versus-gap sensitivities, and every retained limitation.

Create new H06_daily-owned scripts, artifacts, manifests, tests, and a Stage 2
author-facing report. Do not overwrite the historical pilot reports. After
focused R 4.6.1 verification, stop at `H06-D-G2` and request explicit author
approval. Stage 3 and Stage 4 remain blocked even if Stage 2 completes without
new problems.

## Reopening condition

Reopen if an input or preservation identity changes; a frame, formula,
transform, covariance, family, multiplicity, diagnostic, influence, sample,
or reporting role differs from this contract; a frozen result changes beyond
mathematically dependent FDR fields; the runtime or failure gate triggers; or
the author changes the primary/complementary role.
