# H09 worker handoff

Date: 2026-08-12

Stage: **Stage 4 completed and verified; METRIC-011 provenance-only reseal
completed; coordinator-owned website integration requested**

Stage 1 decision: **H09-001 approved on 2026-08-07**

Stage 2 decision: **H09-002 approved as amended on 2026-08-10**

Stage 3 decision: **H09-003 approved with a predictor-definition wording
amendment on 2026-08-10**

Stage 4 status: **completed in H09-owned paths; shared Quarto profile remains
untouched and the integration request is recorded separately**

## Authorization and H09-G4

The durable Stage 1 approval record is
`audit/hypotheses/H09/H09_stage1_gate_and_stage2_transition.md`. The owner
approved H09-G1 through H09-G16 and explicitly accepted the pinned aggregate
calculated fields `msf_sc` and `meq` for H09-G4. They remain distinct MCTQ and
MEQ constructs, models, and multiplicity families. Item-level scoring
reconstruction remains unavailable and is not implied by the acceptance.

## METRIC-011 provenance-only follow-up

Shared decision `METRIC-011` is final under
`audit/decisions/l10_numerical_zero_normalization.md` (SHA-256
`23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797`).
Its seven-member evidence manifest is
`audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv`
(SHA-256
`a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb`).
Every member matched its sealed hash, byte count, `PASS` status, and R 4.6.1
record.

The eight changed primary cells are L10 **mean** melEDI values only: three
near-eye and five chest values changed from `4.163336342344337e-17` lx to
exact zero. H09 uses the registered L10 **midpoint** timing
(`l10_midpoint` / `l10_hour`), not L10 mean. A provenance-only R check
matched all 12 stored primary L10-midpoint frames and all 9,378 stored rows to
the current enriched inputs exactly, including raw and negative-hour-converted
timing values (maximum absolute difference 0 hours). All 65 scientific H09
artifacts in scope remain byte-identical to the accepted Stage 3 seal.

Only the six H09 shared/base input citations changed by METRIC-011 and the
base input-bundle citation were repinned. No H09 model was fitted or refitted;
no diagnostic, prediction, sensitivity, simulation, or bootstrap was rerun;
and no sample, result, interval, p-value, multiplicity decision, figure,
table, or claim changed. The older gap-data/gap-manifest pin drift and the
independently changed metric-display registry were recorded but deliberately
not absorbed into this bounded reseal because the METRIC-011 transition shows
the gap preparation manifest itself was unchanged.

Durable H09 record:

- `audit/hypotheses/H09/H09_METRIC-011_provenance_reseal.md`;
- `audit/hypotheses/H09/H09_METRIC-011_provenance_reseal.csv`;
- `scripts/hypotheses/H09/reseal_h09_metric011.R`;
- `tests/hypotheses/H09/test_h09_metric011_reseal.R`; and
- `artifacts/12_manifests/H09/H09_METRIC-011_provenance_reseal_manifest.csv`
  (29 records; 6,164 bytes; SHA-256
  `cb4e0701c0f642c36e138ef670af373eeeef850e538a991af32bcf7f63583cad`).

Verification command:

```sh
env R_PROFILE_USER=/dev/null \
  Rscript --vanilla tests/hypotheses/H09/test_h09_metric011_reseal.R
```

Result: `H09 METRIC-011 provenance reseal verified: 12 L10-midpoint frames,
9,378 rows, 65 unchanged scientific artifacts, and zero model or diagnostic
reruns`.

## H09-owned implementation

- `scripts/hypotheses/H09/h09_contract.R`
- `scripts/hypotheses/H09/h09_modeling.R`
- `scripts/hypotheses/H09/run_h09_stage2.R`
- `scripts/hypotheses/H09/finalize_h09_figure_qa.R`
- `tests/hypotheses/H09/test_h09_stage2.R`
- `scripts/hypotheses/H09/build_h09_stage3_manifest.R`
- `tests/hypotheses/H09/test_h09_stage3_reader_report.R`
- `scripts/hypotheses/H09/build_h09_preparation_report_manifest.R`
- `tests/hypotheses/H09/test_h09_preparation_report.R`
- `audit/hypotheses/H09/02_implementation_and_v0_comparison.qmd`
- `audit/hypotheses/H09/02_implementation_and_v0_comparison.html`
- `audit/hypotheses/H09/H09_stage2_gate_and_stage3_transition.md`
- `audit/hypotheses/H09/H09_stage3_gate_and_stage4_transition.md`
- `audit/hypotheses/H09/H09_analysis_preparation.qmd`
- `audit/hypotheses/H09/H09_analysis_preparation.html`
- `notebooks/hypotheses/H09.qmd`
- `_build/nathealth/notebooks/hypotheses/H09.html`
- `_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.qmd`
- `_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html`
- H09-only artifacts below `artifacts/06_model_data/H09` through
  `artifacts/12_manifests/H09`
- `audit/handoffs/H09_shared_change_request.md`
- `audit/handoffs/H09_worker_handoff.md`

No shared preparation code, central ledger, shared Quarto configuration,
registry, bibliography, manuscript file, lockfile, other hypothesis path, or
`manuscript/R0_NatMed/` path was modified.

## Computational record

- Runtime: R 4.6.1 with the existing project library.
- Inputs: all 16 pinned identities and applicable row contracts verified.
- Preparation bundle: PREP06-BASE-002 identity verified; the open
  PREP-003/FIND-044 reconstruction qualification is carried forward.
- Model frames: 108 immutable estimable frames.
- Stored model objects: 540 (M0/M1/M2 ML plus M1/M2 REML per frame).
- Primary diagnostic targets: 24.
- Production resampling: 0; no bootstrap, simulation, or production
  resampling gate was needed.
- Primary registered near-eye fits: 131–141 participants, 478–816
  participant-days/observations, 11,325.5–18,851.0 derivation hours, nine
  sites.
- Primary registered chest fits: 149–154 participants, 547–902
  participant-days/observations, 12,980.0–20,891.8 derivation hours, eight
  sites.

The registered fifth outcome is the exact-identifiable midpoint of the
selected longest continuous period above 250 lx melEDI. Mean timing above 250
lx melEDI is a separate adapted sensitivity outside H09-F1–F4. The approved
gap-timing-unaware artifact contains neither the registered midpoint nor its
endpoints, so the fifth cross-dataset sensitivity is explicitly
non-estimable.

## Main results

All effects are differences in local timing. MCTQ effects are per one-hour
later MSFsc; MEQ effects are per 10 points greater morning preference. Values
below use 95% Wald confidence intervals and five-outcome BH-adjusted p-values.

### Primary near eye

| Metric | MCTQ effect, h (95% CI); BH p | MEQ effect, h (95% CI); BH p |
|---|---:|---:|
| M10 midpoint | +0.205 (+0.045 to +0.366); 0.017 | −0.278 (−0.451 to −0.105); 0.002 |
| L10 midpoint | +0.276 (+0.118 to +0.435); 0.003 | −0.314 (−0.487 to −0.142); 0.001 |
| First >250 | +0.381 (+0.146 to +0.616); 0.003 | −0.444 (−0.699 to −0.189); 0.001 |
| Last >250 | −0.025 (−0.264 to +0.214); 0.811 | +0.029 (−0.236 to +0.294); 0.814 |
| Longest-period midpoint | +0.161 (−0.113 to +0.434); 0.284 | −0.228 (−0.521 to +0.064); 0.135 |

### Complementary chest

| Metric | MCTQ effect, h (95% CI); BH p | MEQ effect, h (95% CI); BH p |
|---|---:|---:|
| M10 midpoint | +0.117 (−0.038 to +0.272); 0.162 | −0.214 (−0.381 to −0.047); 0.017 |
| L10 midpoint | +0.174 (+0.022 to +0.327); 0.055 | −0.227 (−0.392 to −0.062); 0.015 |
| First >250 | +0.411 (+0.196 to +0.625); <0.001 | −0.462 (−0.696 to −0.228); <0.001 |
| Last >250 | −0.187 (−0.404 to +0.031); 0.140 | +0.176 (−0.064 to +0.416); 0.173 |
| Longest-period midpoint | +0.058 (−0.189 to +0.306); 0.608 | −0.067 (−0.339 to +0.206); 0.607 |

No site-by-MCTQ or site-by-MEQ interaction survived H09-F3/F4. The smallest
interaction BH p-value was 0.070 for near-eye longest-period/MEQ. Site-specific
slopes remain descriptive and H09-F5 was not activated.

## Multiplicity and fitted-model checks

- H09-F1 MCTQ main, H09-F2 MEQ main, H09-F3 MCTQ-by-site, and H09-F4
  MEQ-by-site remain separate five-member BH families.
- All 40 run × instrument × comparison family audits retained five registered
  members and independently reproduced `p.adjust(method = "BH", n = 5)`.
- Fixed-effect matrices were full rank and Hessians positive definite for all
  540 stored fits.
- Three ML M2 interaction fits were singular: primary chest and both
  paired-common longest-period/MEQ targets. The primary diagnostic registry
  marks chest longest-period/MEQ convergence/singularity not acceptable. The
  paired-placement display uses nonsingular additive M1 fits and does not
  interpret those paired interaction models.

## Diagnostic verdicts

The primary registry evaluates 16 domains for every metric × instrument ×
placement target. Under H09-002, 18 of 24 targets are acceptable overall; six
are not acceptable for at least one remaining declared domain.

- The author judged response/residual distributions and residual
  heteroscedasticity acceptable after visually inspecting Figures 2 and 3.
  The integrated screen's eight distribution and four heteroscedasticity
  flags remain recorded, as do the lower-level all-threshold file's 14
  distribution flags. The complete screen-to-verdict mapping is
  `H09_diagnostic_author_adjudication.csv`.
- Near-eye last-timing MCTQ and MEQ slopes are close to zero and change sign
  under participant deletion and leave-one-site-out checks. No deletion
  changes a slope by the material 0.25-hour threshold, but direction is not
  stable.
- Primary chest longest-period/MEQ has the singular interaction fit described
  above.
- All four registered longest-period placement/instrument targets have a
  not-acceptable prepared-data-sensitivity domain because the gap artifact
  cannot estimate that outcome.
- All 24 targets pass clock representation, linearity, temporal dependence,
  questionnaire/sample identity, site support, fixed rank, paired/common-key
  identity, and multiplicity checks.
- All participant-deletion refits completed. Continuous-time AR(1) corrections
  changed slopes by no more than 0.016 hours.

The report preserves the six remaining limitations next to the fitted
estimates. The diagnostic amendment changes no model, sample, estimate,
interval, p-value, multiplicity decision, or sensitivity result.

## Sensitivities and placement evidence

- Exact paired-placement keys match for all six metrics and both instruments.
  Near eye and chest are fitted separately; the display shows component 95%
  intervals. No difference interval or equivalence claim is made.
- For available outcomes, primary/gap common-key identities match exactly.
  Most estimates are stable within model uncertainty. Chest MCTQ L10 and chest
  MEQ mean timing are precision-sensitive; near-eye MEQ mean timing is also
  precision-sensitive on the exact common sample.
- Within-site photoperiod adjustment is stable for 21/24 targets. Directional
  changes are confined to the near-zero near-eye last-timing slopes; chest MEQ
  mean timing is precision-sensitive.
- Equal-weight participant summaries are stable for 20/24 targets; direction
  changes only for near-zero last-timing or chest longest-period slopes.
- All 24 continuous-time AR(1) sensitivities are stable.
- Strict >16:00 versus noon-cut L10 slopes differ by at most 0.037 hours; all
  four clock-cut checks are acceptable.
- The adapted mean-timing result is not substituted for the registered
  longest-period midpoint. Its near-eye MEQ raw p is 0.041, but it is outside
  H09-F1–F4 and does not alter the registered conclusion.

## V0 reconciliation

V0 was reproduced for all five legacy outcomes and both placements. V0 used
MCTQ only, omitted site from its reported chronotype comparison, substituted
mean timing for the registered longest-period midpoint, and adjusted scalar
p-values with `p.adjust(..., n = 5)`. The scalar call is not vector-wide BH.
Its published visual also omitted last timing and used pooled ordinary-`lm`
smooths.

The Stage 2 V0 recreation retains all five V0 outcomes, labels the pooled line
as a legacy display rather than a mixed model, corrects site display to the
submitted names/order/colours, and provides observed and prediction source
CSVs. The audited primary figure displays the declared site-adjusted mixed
model effects.

## Figures and source data

Six durable figures have PNG/PDF pairs and source CSVs:

1. primary registered effects;
2. exact paired-placement effects;
3. V0 near-eye recreation;
4. V0 chest recreation;
5. near-eye residual diagnostics; and
6. chest residual diagnostics.

The final-size PNG and rendered PDF outputs were inspected at 170 mm. Essential
text is at least 5.10 pt after the established export reduction. No clipping,
overlap, distortion, awkward line break, or excess whitespace remains. The
paired display was reduced from a square canvas to an 8 × 6 base aspect ratio;
V0 internal-code legends were removed because the submitted-name site panel
provides the mapping.

## Render and test record

Analysis command:

```sh
env R_PROFILE_USER=/dev/null Rscript scripts/hypotheses/H09/run_h09_stage2.R
```

Figure-QA command:

```sh
env R_PROFILE_USER=/dev/null Rscript scripts/hypotheses/H09/finalize_h09_figure_qa.R
```

Test command:

```sh
env R_PROFILE_USER=/dev/null Rscript tests/hypotheses/H09/test_h09_stage2.R
```

Result: `H09 Stage 2 tests passed`.

Scoped render command used the R 4.6 project library on the startup path:

```sh
env R_PROFILE_USER=/dev/null \
  R_LIBS=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  R_LIBS_USER=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  quarto render audit/hypotheses/H09/02_implementation_and_v0_comparison.qmd --to html
```

The H09-only render completed all 49 steps. Static HTML QA passed with the
amended decision callout and no render-error fragment.

- Stage 2 QMD SHA-256:
  `d05c1f69bf3a55f78bb56f7b970a711f45675b988e6351fec205adf919fcc412`
- Stage 2 HTML SHA-256:
  `955387638b350596e0296cc7ede954d3c8920b430af161b8f919fe1c637af3ef`
- Figure manifest SHA-256:
  `0ad64452efd82932b5db6782090f9b3660b31d63d115cd7d806c10597fbdf76b`

Reader-report render command:

```sh
env R_PROFILE_USER=/dev/null \
  R_LIBS=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  R_LIBS_USER=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  quarto render notebooks/hypotheses/H09.qmd --profile nathealth
```

The scoped render completed all 35 steps and produced a standalone page with
11 compact semantic tables, four accessible figures, the “Answer in brief”
callout immediately in the hypothesis section, complete source links, and no
render-error fragment.

- Reader-report QMD SHA-256:
  `bd365fb4f9e0e23fd1555e0a8db62f7d3a0ff9ad076eaaaf738ec22e698d50ff`
  (bytes: 33,345)
- Reader-report HTML SHA-256:
  `ce6c4c644af675e5feb25dcbc834b55c3ddfc87ec3dc581c95366edc0de067b1`
  (bytes: 229,798)

Reader-report manifest and test commands:

```sh
env R_PROFILE_USER=/dev/null \
  Rscript scripts/hypotheses/H09/build_h09_stage3_manifest.R
env R_PROFILE_USER=/dev/null \
  Rscript tests/hypotheses/H09/test_h09_stage3_reader_report.R
```

Results: 108 files sealed in `H09_stage3_artifacts.csv`; `H09 reader-report
tests passed`. The approved wording amendment now briefly defines
`mctq_hour_centered` and `meq_10_centered` immediately after the formula table.

## Stage 3 approval and Stage 4 completion

The owner approved the standalone report under H09-003 and requested the
predictor-definition amendment above. The approval changed no model, sample,
estimate, interval, p-value, multiplicity decision, diagnostic assessment,
sensitivity result, figure, or source-data value.

The standalone analysis-preparation and provenance companion is:

- `audit/hypotheses/H09/H09_analysis_preparation.qmd`;
- `audit/hypotheses/H09/H09_analysis_preparation.html`; and
- the byte-identical preserved website source and HTML below
  `_build/nathealth/audit/hypotheses/H09/`.

Scoped render command:

```sh
env R_PROFILE_USER=/dev/null \
  R_LIBS=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  R_LIBS_USER=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  quarto render audit/hypotheses/H09/H09_analysis_preparation.qmd --profile nathealth
```

The render completed all 47 steps. Because the coordinator-owned profile does
not yet list the preparation page, the scoped render was written beside its
source and then preserved byte-identically at its intended website path by
the manifest builder. The page contains one accessible descriptive support
figure, 19 compact semantic tables, reciprocal result/provenance links, and no
scientific refitting, prediction, simulation, bootstrap, or sensitivity
recomputation. A post-render display repair replaced two text-bearing LaTeX
blocks in “Centering and scaling” with explicit inline-code definitions; this
prevents the local HTML renderer from dropping the variable labels and changes
no scientific content.

Manifest and test commands:

```sh
env R_PROFILE_USER=/dev/null \
  Rscript --vanilla scripts/hypotheses/H09/build_h09_preparation_report_manifest.R
env R_PROFILE_USER=/dev/null \
  Rscript --vanilla tests/hypotheses/H09/test_h09_preparation_report.R
```

Results: 132 current identities sealed and `H09 preparation companion
verified`.

- Preparation QMD SHA-256:
  `4640129c38a5aabd874549ff8d5ebc74b736a16fe6f900f4654b1573b2b69f5c`
  (bytes: 43,562)
- Preparation HTML SHA-256:
  `4054dfc668365fdcb0d8cdedcb73900cbd3c471a1443fdcf37dfb4a1c9379d05`
  (bytes: 593,181)
- Preparation manifest SHA-256:
  `8e1d633262b33df64e45f0fc3fd677f4bb1e8a69120cb76a9b152509b94f0aaf`
  (bytes: 35,323)

Shared website integration is requested in
`audit/handoffs/H09_shared_change_request.md`; the H09 worker did not edit
`_quarto-nathealth.yml`.

## Proposed central-ledger entries — coordinator action only

The H09 worker has not edited any central ledger. Proposed entries:

| Proposed record | Proposed content |
|---|---|
| `H09-STAGE1` | H09-001 approved; all H09-G1–G16 accepted, including explicit H09-G4 aggregate-field acceptance |
| `H09-STAGE2` | H09-002 approved as amended; 108 frames, 540 fits, 24 diagnostic targets, zero resampling replicates; response/residual distribution and heteroscedasticity final assessments acceptable after visual review |
| `H09-RESULT-MAIN` | Near-eye M10, L10, and first-above-250 main associations supported for both MCTQ and MEQ under their five-member BH families; last and longest-period inconclusive |
| `H09-DIAGNOSTIC` | 18/24 acceptable overall; 6/24 not acceptable for influence, singularity, or unavailable longest-period gap-sensitivity domains; numeric residual screens retained under H09-002 |
| `H09-STAGE3` | H09-003 approved with the predictor-definition wording amendment; standalone reader report rendered and verified with 11 compact tables, four accessible figures, and no scientific refitting |
| `H09-PREDICTOR-CENTERING` | `mctq_hour_centered = MSFsc hours − 4.1135843`; `meq_10_centered = (MEQ − 52.8602151) / 10`; centering changes the intercept reference but not slopes, confidence intervals, or tests |
| `H09-STAGE4` | Analysis-preparation and provenance companion completed; one accessible descriptive figure, 19 compact tables, 132 current checksum identities, reciprocal links, and no scientific recomputation |
| `H09-V0` | V0 scalar adjustment and selected/site-unadjusted reporting not retained; exact recreation and audited comparison persisted |
| `H09-SAMPLE-STAGE2` | Populate exact fitted samples from `H09_model_frame_index.csv`, not Stage 1 candidate counts |
| `H09-PREP-GAP` | Registered longest-period midpoint remains unavailable in the shared gap-timing-unaware artifact; H09 sensitivity explicitly non-estimable |
| `H09-METRIC-011` | Provenance-only repin completed; eight upstream L10-mean numerical-zero changes are outside H09's L10-midpoint estimand; 12 frames/9,378 rows and 65 scientific artifacts verified unchanged; zero fits or diagnostic reruns |

Coordinator action requested: add
`audit/hypotheses/H09/H09_analysis_preparation.qmd` immediately after the H09
result in both the Nature Health render list and sidebar, with text “H09
preparation and provenance”, then perform only the affected website render and
adjacency/link verification.
