# H01 worker handoff

Date: 2026-08-31
Worker scope: H01 only  
Status: **METRIC-010 MDER production, focused integration, and H01 reader
reporting complete and verified; no open H01 author gate**
Primary placement: near eye  
Complementary placement: chest  
Runtime: R 4.6.1; Quarto 1.9.37

## Current closure: METRIC-010 MDER production and reader integration (2026-08-31)

The author explicitly approved the 1,000-refit MDER production bootstrap after
reviewing the separate 50-refit pilot. The production runner fitted only the
eight accepted MDER targets. The other 16 H01 metrics were not refitted, and
their fitted-model and raw-test artifacts remained frozen. Complete 17-test
family fields were recalculated only where the replaced MDER p-value enters a
family.

The current MDER estimand is the arithmetic mean of viable one-minute
melEDI-to-illuminance ratios. Both channels must be finite and strictly
positive, and at least 720 viable minute ratios are required to retain a
participant-day value. The controlling decision is
`audit/decisions/mder_mean_of_viable_ratios.md`, SHA-256
`1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de`.
The author authorization is
`audit/hypotheses/H01/mder_METRIC-010/H01_METRIC-010_production_authorization.md`,
SHA-256
`f9279a46c73b5feede48adaeee98306a4841183468688446ce91cf09045e33af`.

### Exact target samples and production execution

All MDER models are participant-day models. Participant-days therefore equal
model observations. The primary near-eye all-available model uses all nine
sites; the chest and paired/common variants contain eight sites because one
site has no estimable observations in those exact samples.

| Dataset | Placement | Sample | Participants | Participant-days | Observations | Sites |
|---|---|---|---:|---:|---:|---:|
| Primary | Near eye | All available | 137 | 702 | 702 | 9 |
| Primary | Chest | All available | 152 | 732 | 732 | 8 |
| Primary | Near eye | Paired/common | 107 | 489 | 489 | 8 |
| Primary | Chest | Paired/common | 107 | 489 | 489 | 8 |
| Gap-timing-unaware | Near eye | All available | 137 | 687 | 687 | 9 |
| Gap-timing-unaware | Chest | All available | 152 | 723 | 723 | 8 |
| Gap-timing-unaware | Near eye | Paired/common | 107 | 478 | 478 | 8 |
| Gap-timing-unaware | Chest | Paired/common | 107 | 478 | 478 | 8 |

| Production check | Verified result |
|---|---|
| Targets | 8 of 8 PASS |
| Retained successful joint refits | 1,000 per target; 8,000 total |
| Attempted refits | 12,000 |
| Successful attempts | 11,998 |
| Failed and warning attempts | 2, both excluded from retained draws |
| Failure location | Gap-timing-unaware near-eye all-available, attempts 565 and 1,456 |
| Target wall time | 320.8769 seconds summed across sequential targets |
| Command wall time | 322.3757 seconds |
| Resources | Four refit workers; one BLAS/OpenMP thread per worker |
| Checkpoints | Eight completed-target checkpoints and eight draw files |
| Retained uncertainty | 95% joint parametric percentile intervals |
| Disposition changes from accepted point gate | 0 |
| Focused production verifier | PASS |
| Integration status | `PASS_NO_NEW_AUTHOR_GATE` |

Both excluded attempts had a maximum-gradient convergence warning and failed
the convergence, Hessian, or singularity screen. Every target still supplied
1,000 successful retained joint refits. Peak memory was not instrumented per
child process. Production draws occupy 458,952 bytes. The production record
verified 1,169 canonical H01 artifacts as byte-identical before and after the
bootstrap itself.

### Current primary MDER result and downstream family fields

The complete primary near-eye families contain 17 tests each. With current
MDER, 10 metrics support an overall site association, 12 support photoperiod,
7 support latitude, and 9 support the site-versus-linear-latitude adequacy
comparison. For MDER itself:

- overall site FDR-adjusted p = 0.000635;
- photoperiod difference per hour = 0.0236, 95% CI [0.0166, 0.0307],
  FDR-adjusted p < 0.001;
- absolute-latitude difference per 10 degrees = -0.0139, 95% CI
  [-0.0237, -0.00418], FDR-adjusted p = 0.013; and
- site-versus-linear-latitude adequacy FDR-adjusted p = 0.010.

The primary near-eye full model has marginal R-squared 0.278, 95% CI
[0.213, 0.381], conditional R-squared 0.605 [0.546, 0.682], and a
participant-associated share of 0.327 [0.241, 0.400]. Model-specific part
R-squared values are 0.0957 [0.0598, 0.178] for site, 0.130 [0.0674,
0.206] for photoperiod, and 0.0274 [0.00265, 0.0686] for latitude. These
components can overlap and must not be summed.

No support, diagnostic, influence, sensitivity, placement-comparison, or
claim disposition changed relative to the accepted repaired point gate.
Consequently, the focused installer integrated the stored production
intervals without reopening a major-change gate.

### Reader-report implementation

The H01 result report now includes a 17-row publication synthesis table. It
combines, for each metric:

- the manuscript metric name and a concise definition;
- the accepted overall median and interquartile range with descriptive
  denominators;
- an accessible nine-site density thumbnail using the registered site order,
  names, and colours;
- site, photoperiod, and latitude results with 95% intervals and separately
  labelled FDR-adjusted p-values;
- marginal and conditional R-squared, participant-associated share, and
  model-specific part R-squared; and
- the exact fitted participants, participant-days, observations, and sites.

The table keeps descriptive and fitted denominators distinct. It displays
participant and participant-day labels with true subscripts, states that
participant-days equal observations for the 15 participant-day outcomes, and
states that the primary fitted models use nine sites throughout. The two
participant-level dynamics outcomes have one fitted observation per
participant and show participant-days only as contributing support. Grey
part R-squared values remain numerically visible when their corresponding
17-test FDR result is unsupported.

The report contains 37 semantic `gt` tables and 27 images. The 27 images are
the 10 accepted H01 figures plus 17 density thumbnails with labelled
`role="img"` wrappers. The preparation and provenance companion contains 20
semantic `gt` tables and two figures. The archived Stage 2 comparison now
maps the submitted ratio-of-integrals MDER identifier to the current
mean-of-viable-ratios comparison slot while explicitly stating that the two
constructs are not like-for-like.

### Verification and visual QA

Current verification passed under R 4.6.1 with `gt` 1.3.0 and Quarto 1.9.37:

- H01 contract, fit-output, modelling, response-family candidate,
  response-gate, and canonical bootstrap-output tests;
- the focused METRIC-010 production verifier;
- the complete H01 reporting-input and rendered-HTML test; and
- the full preparation-report test with 75 exact manifest identities.

Historical pre-production gate tests intentionally retain their original
frozen boundaries. They now stop on superseded MDER paths or later accepted
display transitions and are not current production verifiers. The current
METRIC-010 production test proves the isolated eight-target replacement and
the frozen non-MDER boundary.

Secure loopback review at 1,440 by 1,000 and 708 by 1,000 pixels found no
browser-console errors, page-level horizontal overflow, clipping, or missing
local assets. The synthesis table uses a contained horizontal scroller at
both widths; fitted-sample subscripts, density thumbnails, headings, and
footnotes remain readable. The result page has 37 native `gt` tables, 27
images, 17 labelled density graphics, and no cell-output error. The companion
has 20 native `gt` tables, two images with non-empty alt text, and no
cell-output error. The temporary loopback server was stopped after review.

The initial restricted render attempt could not access the existing Quarto
and Sass caches. The successful renders used the already approved narrow
cache access with the activated project library. No package, lockfile,
profile, or shared Quarto configuration changed. The current `renv.lock`
SHA-256 remains
`3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350`.

### Current identities

| Artifact | SHA-256 |
|---|---|
| MDER production manifest | `c1f334c973fd9e970ce4f3678addcbdf70d25ca653792ee6ac170b3e13da540c` |
| MDER integration summary | `35bfabc0d658f09fd3c7f0e8af12325f205792a9f2ae6f371ac1088b96a105e5` |
| MDER production-integration manifest | `78fdc14539d8c1a9cb71fbfe7da93ffa09e0b30b661dfb1810cd2eda616379e8` |
| Canonical model-results manifest | `657d96b566163fe753bfcc7ebf92df60a0e05a2915b6c9ab608e18c65c03f813` |
| Publication synthesis CSV | `7f6edc7aa24b23d9eb9076dc06073512435cc61d0bb8eed2fdd8f43ec594a354` |
| Reporting manifest | `d9be58e5ef59dace1588c2243826e40316660c739fe3e79b45bc0be6f770f2ad` |
| Stage 3 reporting manifest | `cc966393265c9d4a0aded4fbd1c59315b7edebd9be6cbf3c2d731ddddaccf979` |
| Preparation-report manifest | `7020651a6f09964fcc7350ccafcc3550e1d04d6bccc8d1b1d7418832d3c2b4ff` |
| Stage 2 comparison source | `553c9f7d0e877adb5da0133b8e18a0315f56ce1f514c4dd1d46c185e09016763` |
| Stage 2 comparison HTML | `d74f2f20bbd4fb0b8df37a09f637b7a1ccdb6a515e2ded276f61dd7ca0139840` |
| Stage 3 result source | `5e0bcf315ea113543dbcb762aaea19e4e2b0cd4bbe4f3520de04ebc19e041208` |
| Stage 3 result HTML | `72458413f3a2b025474abdff556feeb897e4a968a254e2f546565348f8a07e4a` |
| Stage 4 companion source | `c6435a5f482df40c20f3d4d6e4f77d07f2a4f0bb3f1f2687efd2ebf92829e044` |
| Stage 4 companion HTML | `9bb80c068570b168e500da0ce5905859e36543ec2c91aed423c9557aaa33aa0a` |

### Proposed coordinator-only closure entries

| Ledger class | Proposed entry |
|---|---|
| Finding | The authorized METRIC-010 production run completed eight MDER targets with 1,000 retained successful joint refits each, 11,998 successful attempts of 12,000, two excluded convergence-warning attempts, and every target audit status PASS. |
| Finding | Current primary near-eye MDER supports overall site, photoperiod, latitude, and site-versus-linear-latitude adequacy after the four separate 17-test FDR adjustments; no accepted point-gate disposition changed after production intervals were installed. |
| Decision | Close the METRIC-010 MDER production and reporting gate as `PASS_NO_NEW_AUTHOR_GATE`; retain all other 16 H01 model fits and raw tests unchanged. |
| Change log | Integrated only MDER-dependent model, uncertainty, complete-family, sensitivity, comparison, diagnostic, source-data, report, test, and manifest outputs; added the 17-row publication synthesis table and 17 registered-site density thumbnails; rerendered only the H01 result, companion, and standalone Stage 2 comparison. |
| Claim provenance | Current MDER claims use the mean-of-viable-one-minute-ratios estimand and production 95% intervals. The submitted ratio-of-integrals construct remains identified only as historical, non-like-for-like comparison context. |

Central ledgers remain coordinator-owned and were not edited here. No commit,
push, upload, dependency change, shared preparation change, manuscript edit,
or shared Quarto configuration change was made.

## Current closure: REPORT-014/017 consolidated reader rewrite (2026-08-14)

### Fail-closed source-only verification stop

The single authorized verification attempt exited with status 1 before any
of the four focused tests began. While auditing the new
`h01_support_orientation` boundary, the order-32 verifier called its recursive
R call walker on a missing argument and stopped with:

```text
Error in walk(element) : argument "element" is missing, with no default
Calls: intersect ... collect_calls -> walk -> walk -> walk -> walk -> walk
Execution halted
```

No incremental repair or second attempt was made. Consequently, the complete
reporting test, preparation source-only test, REPORT-016 test, unchanged
display-refresh test, chunk-level preservation audit, manifest reverse proof,
and final scoped diff gate remain unexecuted under this order. The QMD
rewrites and direct manifest rows below are assembled but are not accepted
until a separately authorized correction reruns the complete suite once.
The complete stopped-state evidence is retained in
`audit/hypotheses/H01/report017_order32_source_rewrite/`.

Order 32 reorganized the accepted H01 result report and its preparation and
provenance companion without executing either QMD. The principal result
figure and table now lead the results overview. Exact fitted samples,
registration records, response-family details, formulas, diagnostics, and
source-data records remain complete in later sections or disclosures. The
result report and companion retain exactly 36 tables and 10 figures, and 20
tables and two figures, respectively.

The only new result-report object is the non-mutating
`h01_support_orientation`, derived from the already loaded `exact_samples`
object. It supplies early sample-range orientation without hard-coded fitted
sample counts. No stored analysis object, estimate, interval, p-value, FDR
decision, model-check classification, sensitivity result, formula, figure,
table data source, or claim changed.

The preparation estimand wording now records RH-SCI-H01-003 exactly:

> Marginal R², conditional R², participant-associated share, and
> model-specific term part-R² values that may overlap and must not be summed

Latitude remains a term part-R² from its separate same-frame model. This is a
wording correction only and does not change any calculation.

### Source identities and direct manifest reseal

| Current dependency | Pre-order-32 SHA-256 | Order-32 SHA-256 | Bytes |
|---|---|---|---:|
| Result QMD | `31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6` | `9448eacc1345a2b0bf73c988be588308d191e42d90c49d68c7f92db36ba83eeb` | 93,260 |
| Preparation companion QMD | `962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8` | `ed12b6232ef60905b648707240309e6574e627995d0436a19f671fdc033ecc5f` | 55,827 |
| Reporting source test | `ab648ac80bc1c8a149a11bb958fd683b38722487c53179b42b215a2b000e6fd5` | `48f374cc70b69a6d96a95dc425ffd9676b2e83133a5554ae1c19eda939c0c8af` | 23,014 |
| Preparation source test | `12b04008e60cab737780947308042634ee06643dddc450502754fade11228bea` | `379414830e5bcd656ac460c2ad93616ecbcab104259c56a8fcf9296da8c0f2c4` | 10,993 |
| REPORT-016 historical/live test | `1aa2e9419fcc25fbfc759ffa0a39aa0556abff5bdc3f2c6e4f1950213bdec2e5` | `c359489b45703ae243d277817832e305716271dd54a7713620ceb4a7943d6393` | 14,658 |
| Reporting manifest | `d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079` | `dfa9e15f44f0919277264765e84b49b7be78e4822df014abed678b29a9a951b4` | 11,054 |
| Stage 3 reporting manifest | `16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e` | `e9fe8740785e9f4d29e17c4333fdc0615347299c1dabea1d62ffad1cdafd11f9` | 26,497 |
| Preparation-report manifest | `bae856c2bb75df317f476e7e993178061628c0fcdbc6795a4b88f78843f8d9d0` | `cb89845e92b39f5bab7a0524508a3f7e2ce1d19ebbc99afe12f1ebf8eb9aefb5` | 13,841 |

Only direct current dependency rows were resealed from leaves upward. Every
build-output row, profile row, scientific-artifact row, role, producer, R
version, row order, and historical REPORT-016 identity remained unchanged.
The exact row diffs and byte-for-byte reverse proofs are in
`audit/hypotheses/H01/report017_order32_source_rewrite/`.

### Source-only verification and held render boundary

The order-32 attempt record contains the exact R 4.6.1 command, runtime,
exit status, console error, identities at the stop, and the complete list of
verification gates that did not run. A separately authorized correction must
restart the complete source-only suite from the beginning. It must include the
complete reporting test, the preparation test with
`H01_PREPARATION_SOURCE_ONLY=true`, the complete REPORT-016 test, the
unchanged display-refresh test, and the structural and reverse-proof audits.

No Quarto command, fitted-model function, prediction, bootstrap, simulation,
reporting builder, or artifact-regeneration path ran. The held result HTML
remains `6e0bb1b3bc3b09ee92fd4650655521c6b8fdc01c125ff10c3df2fe733d3c62aa`;
the held companion HTML remains
`5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38`;
and `_quarto-nathealth.yml` remains
`80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3`.
Fresh rendering and visual acceptance remain a separate coordinator gate.

## Current closure: METRIC-011 production and reporting integration (2026-08-12)

The author explicitly accepted all three H01-012 dispositions. The
coordinator recorded production authorization as H01-013 / CHG-110 in
`audit/decisions/h01_metric011_l10_production_authorization.md`
(`ab0764bb55144d9c69caafc8373010f497561757ad2c576d88e32b450817ed4f`).
The bounded run replaced exactly four primary darkest-10-hour mean melEDI
bootstrap targets and no others:

| Dataset | Placement | Sample | Participants | Participant-days | Observations | Sites |
|---|---|---|---:|---:|---:|---:|
| Primary | Near eye | All available | 141 | 816 | 816 | 9 |
| Primary | Chest | All available | 154 | 902 | 902 | 8 |
| Primary | Near eye | Paired/common | 112 | 643 | 643 | 8 |
| Primary | Chest | Paired/common | 112 | 643 | 643 | 8 |

These are participant-day models, so participant-days equal fitted
observations. Exact main-data L10 derivation-support hours remain unavailable;
they were not reconstructed. The unchanged gap-timing-unaware L10 outputs
also retain unavailable support hours.

### Final inputs and environment

| Item | SHA-256 |
|---|---|
| Primary H01 RDS | `0328fe1a698bc13965feb0b68b03ccf0fd20f32b55d6148635811b0d674e0a00` |
| Primary prepared-input manifest | `25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72` |
| Gap-timing-unaware H01 RDS | `3c70363fc0468202a431904aa9d9444f2858af2e3add3475a56c872b49a18bd6` |
| Gap-timing-unaware prepared-input manifest | `e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b` |
| METRIC-011 decision | `23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797` |
| Production authorization | `ab0764bb55144d9c69caafc8373010f497561757ad2c576d88e32b450817ed4f` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

Production used R 4.6.1, `lme4` 2.0.1, `performance` 0.17.1, four R
workers, and one BLAS/OpenMP thread per worker. Reporting used Quarto 1.9.37,
`gt` 1.3.0, `knitr` 1.51, and `rmarkdown` 2.31.

### Commands, runtime, and successful refits

```sh
H01_L10_AUTHOR_APPROVAL=accepted_2026-08-12 \
R_LIBS_USER=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
H01_L10_PRODUCTION_REFITS=1000 H01_L10_PRODUCTION_CORES=4 \
OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 \
VECLIB_MAXIMUM_THREADS=1 \
Rscript --vanilla scripts/hypotheses/H01/run_h01_l10_METRIC011_bootstrap_production.R

Rscript --vanilla scripts/hypotheses/H01/integrate_h01_l10_METRIC011_production.R
Rscript --vanilla tests/hypotheses/H01/test_h01_l10_METRIC011_production.R
Rscript --vanilla scripts/hypotheses/H01/integrate_h01_l10_METRIC011_reporting.R
Rscript --vanilla tests/hypotheses/H01/test_h01_l10_METRIC011_reporting.R

quarto render audit/hypotheses/H01/02_implementation_and_v0_comparison.qmd --profile nathealth
quarto render notebooks/hypotheses/H01.qmd --profile nathealth
quarto render audit/hypotheses/H01/H01_analysis_preparation.qmd --profile nathealth
```

Each target attempted 1,500 refits, obtained 1,500 successful refits, retained
the first 1,000 joint refits for inference, and had zero failed or warning
refits. Target wall times were 39.72, 39.03, 39.81, and 39.53 seconds;
the summed target time was 158.09 seconds and the production process elapsed
160.51 seconds. The production contract identity is
`0f8bc85ec11705efebd1f3ada05f7187113ba54112b57aa481d6bf490a186e8a`.
The first attempted process, launched without the project `R_LIBS_USER`,
stopped before its first draw because workers could not load `lme4`. It did
not create a checkpoint or scientific result. The corrected environment and
incident are recorded in
`audit/hypotheses/H01/l10_METRIC-011/bootstrap_production/H01_METRIC-011_execution_incident.md`.

### Estimates, 95% intervals, and multiplicity

The numerical-zero normalization is below meaningful fitted precision. The
primary near-eye all-available L10 mean retained an equally weighted site
mean of 0.133 lx melEDI (95% CI 0.112 to 0.157). Photoperiod was a ratio of
1.09 per hour (95% CI 1.03 to 1.14); absolute latitude was 1.04 per 10 degrees
(95% CI 0.971 to 1.11). The complete vector-wide BH results were:

| Primary near-eye question | Raw p | BH-adjusted p | Support |
|---|---:|---:|---|
| Overall site | <0.001 | <0.001 | Supported |
| Photoperiod | 0.001 | 0.002 | Supported |
| Latitude | 0.259 | 0.400 | Not supported |
| Site-versus-linear-latitude adequacy | <0.001 | <0.001 | Supported |

The complementary chest equally weighted site mean was 0.102 lx melEDI
(95% CI 0.085 to 0.121). Photoperiod was 1.07 per hour (95% CI 1.02 to
1.12), and latitude was 0.920 per 10 degrees (95% CI 0.877 to 0.966).
The complete chest BH-adjusted p-values were <0.001 for site, 0.011 for
photoperiod, 0.002 for latitude, and <0.001 for adequacy. No support decision
changed relative to the accepted point baseline.

Because the overall site tests remain supported, the hierarchical emmeans
contrasts from the equally weighted overall site mean remain eligible. In the
primary near-eye analysis, Izmir was higher (ratio 1.49; 95% CI 1.16 to
1.91; within-metric adjusted p = 0.016), Kumasi was lower (0.668; 95% CI
0.509 to 0.876; adjusted p = 0.016), and Tübingen was higher (1.36; 95% CI
1.09 to 1.69; adjusted p = 0.020). At the chest, Dortmund was lower (0.723;
95% CI 0.570 to 0.917; adjusted p = 0.020), Izmir was higher (1.57; 95% CI
1.24 to 1.98; adjusted p = 0.001), and San José was higher (1.32; 95% CI
1.12 to 1.57; adjusted p = 0.005).

Production R-squared summaries also remain numerically unchanged. For the
primary near-eye L10 mean, marginal R-squared was 0.220 (95% bootstrap CI
0.158 to 0.318), conditional R-squared 0.611 (0.553 to 0.681), and the
participant-associated share 0.391 (0.304 to 0.462). At the chest these were
0.138 (0.095 to 0.231), 0.517 (0.457 to 0.589), and 0.379 (0.292 to 0.447).
The stored site, photoperiod, and latitude part-R-squared summaries remain
separate non-overlapping model comparisons and were not summed.

### Diagnostics, sensitivities, and claim disposition

All four fits converged with positive-definite Hessians and were non-singular.
All retain `WARN_REVIEW`: Shapiro p-values were below 0.001 and residual
variance ratios ranged from 7.35 to 15.4; 1.1% to 1.6% of standardized
residuals exceeded three in absolute value. The L10 response has no verified
upper physical bound, so prediction-bound status remains
`UPPER_BOUND_UNAVAILABLE`. The accepted disposition is **acceptable with
limitations** for all four targets; no common response-family replacement is
required.

Participant influence refits all passed; maximum absolute DFBETA was 0.820
across the evaluated all-available targets. Latitude leave-one-site-out
refits all passed. Primary near-eye latitude remained unsupported across the
site omissions (raw p range 0.063 to 0.992), while chest latitude was more
sample-sensitive (raw p range <0.001 to 0.165). The exact paired/common
comparison remains 112 participants and 643 participant-days/observations at
each placement. Gap-timing-unaware results and the noon-cut, exactly
identified-period, complementary chest, and other registered sensitivities
retain their accepted classifications. No sensitivity or claim disposition
changed.

### Preservation, report QA, and final identities

The focused production and reporting verifiers pass. Every one of the 830
protected non-L10, unchanged gap-L10, and METRIC-010 identities matches its
baseline. The reporting integration additionally preserves value identities
for non-L10 rows in 20 mixed tables. Its stopped type-promotion incident and
repair are documented in
`audit/hypotheses/H01/l10_METRIC-011/production_integration/reporting/H01_METRIC-011_reporting_integration_incident.md`.

The three H01 pages render under the Nature Health profile. The Stage 3 HTML
passes its structural/alt-text/source-link checks, and the Stage 4 companion
passes with 23 figures, 20 semantic `gt` tables, and 62 manifest identities.
The four regenerated Stage 3 figures pass final-size typography, clipping,
overlap, null-line alignment, legend, and accessibility review, recorded in
`H01_METRIC-011_figure_readability_qa.md`.

| Final artifact | SHA-256 |
|---|---|
| Production audit | `93e06b6462296d143d3dabfdb36a93731fd32ea6c9e89f362e6c90cd69758ca5` |
| Production runtime | `ee95a68d95ba7720920f82b944335c8b5835eaaf96a1c2ddcf3cdeee358d1c0e` |
| Production provenance | `89d548aedfe1783d08b9aeb3cd550020c6c68b0cd225c3efa90a28a7e5d0285b` |
| Production manifest | `e996dccb9556330a23c14bf2650ed7102662303dbac01a7873f5e974cc97eb57` |
| Canonical integration summary | `b60caac20771230d4e371e79158c7da2ff2c7ae64d6f21b1027c49168667fbda` |
| Canonical integration manifest | `f3755db338695515564bc3b60e4321bf4139eb0dffacab4ece7a86718cffb77d` |
| Reporting integration summary | `202a8dd7b29308d1411b3b13b15f19ebf073b1f548ffaf78c094161d294dce06` |
| Reporting integration manifest | `762794151fb5a50e3ef1964c7c05084d7a61e6c038538557b305fb3b8507633e` |
| Stage 2 reporting manifest | `79e68e3676e7862e596495584e4bd8900b9bffd7f1778a8cfcbe2eef696baa79` |
| Stage 3 reporting manifest | `12599e3b307bba9aa042697fe304e68a95cdf161fa9d297197f00abfb3bb0ada` |
| Stage 4 preparation manifest | `bae856c2bb75df317f476e7e993178061628c0fcdbc6795a4b88f78843f8d9d0` |
| Canonical model-results manifest | `eceb971726ee4a52cf4266ad1a44441c45078328c08f32c1ef1c1e83df2aee7c` |
| Stage 2 source / HTML | `c5edcecf7e6288eae47eb19b71d8e6fd7a0a072a3fd2eb34c264577f943f0eb2` / `6106275d95acf3ee8f4be9460e472b019fbbcb43d6397f2b54a43ba687c9d759` |
| Stage 3 source / HTML | `6a9c81d63e6b8b8ab67aa6886fe1bde36712f54f05b438a3298331eec92b8ed8` / `53a216ff0ae82b2e9177671d6330862832c1c5f2a9e79251e0da0acb5671260f` |
| Stage 4 source / HTML | `85d51304a3a5808efa6ec4cf7bded79a07a31ff639a6643ec49be67fb8ed6dcc` / `5857f9e0655e5c1a8530c5794008d20dcb364749a8a7c36bd3e7815c15c36d38` |

The first sandboxed Quarto attempt completed R/knitr but could not open its
generated Deno/Sass cache database. Moving that generated cache recoverably
to `/private/tmp/H01-quarto-cache-backup.Ne6oNn/project-cache` did not resolve
the sandbox restriction. All three bounded H01 renders then completed outside
the filesystem sandbox using the same project library and profile; no shared
Quarto configuration was edited.

### Proposed coordinator closure entries

| Ledger class | Proposed entry |
|---|---|
| Finding | METRIC-011 normalized eight numerical-roundoff L10 cells to exact zero; four affected primary targets completed 1,000 retained successful joint refits each with zero failed/warning refits and no support or claim change. |
| Decision | Close H01-013 after focused production, reporting, preservation, render, and manifest verifiers pass; no new author gate is required. |
| Deviation | Retain the accepted shifted-log Gaussian L10 model as acceptable with limitations; disclose residual-shape warnings and unavailable upper-bound verification without changing family. |
| Change log | Replaced only four primary L10 fit/draw/R-squared branches, recomputed complete affected BH vectors, refreshed dependent L10 comparison/results/provenance rows and figures, and preserved 830 protected artifacts. |
| Result comparison | METRIC-011 changes values only below fitted numerical precision: all site, photoperiod, latitude, adequacy, sensitivity, and claim dispositions remain unchanged. |
| Claim provenance | Existing H01 scientific claims remain supported with no wording consequence; reader reports now point to the verified METRIC-011 production outputs and retain all diagnostic limitations. |

Unresolved gates: none for METRIC-011. The separate METRIC-010 record remains
independent and was not changed by this closure. Central ledgers and manuscript
claims were not edited; the coordinator should review and apply the proposed
entries above.

## Current METRIC-010 post-repair author gate (2026-08-11)

The coordinator resolved the gap-timing-unaware MDER preparation defect and
issued final input pins. The former zero for THUAS_S002 chest on 2025-03-09 is
now reason-coded missing, 687 near-eye and 723 chest comparator days retain
MDER, and all 25,620 non-MDER participant-day cells are unchanged. The final
H01 pins are:

- primary RDS
  `2d226a48d92eec7f419e66f4011e8294557034abb4e1a6af6c055d4a0cbc7621`;
- primary manifest
  `5aa19326b2de468efb177af0d8f193253db63aade2d607f9570f5c3337e39c74`;
- gap-timing-unaware RDS
  `24948e6b138c80bf236a7c9b2b005760206d34a7318a45594ac541482408830e`;
- gap-timing-unaware manifest
  `79ee4818d7f3967827a6412f8537196e84ee7a6ccc1b8d2c5e9dd3124ed44b47`;
  and
- embedded gap scenario manifest
  `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935`.

A fresh isolated MDER-only point run completed all eight registered
scenario/placement/sample targets. The accepted 16-metric package was not
refitted or overwritten; the 830 non-MDER artifact hashes remain verified.
Exact MDER samples are:

| Dataset | Placement | Sample | Participants | Participant-days/observations | Sites |
|---|---|---|---:|---:|---:|
| Primary | Near eye | All available | 137 | 702 | 9 |
| Primary | Chest | All available | 152 | 732 | 8 |
| Primary | Near eye | Paired/common | 107 | 489 | 8 |
| Primary | Chest | Paired/common | 107 | 489 | 8 |
| Gap-timing-unaware | Near eye | All available | 137 | 687 | 9 |
| Gap-timing-unaware | Chest | All available | 152 | 723 | 8 |
| Gap-timing-unaware | Near eye | Paired/common | 107 | 478 | 8 |
| Gap-timing-unaware | Chest | Paired/common | 107 | 478 | 8 |

Primary support hours are 10,949.917 near eye, 11,145.300 at the chest,
7,665.217 for paired near eye, and 7,435.617 for paired chest. Comparator
support hours remain unavailable.

The primary near-eye equally weighted MDER is 0.726 (95% CI 0.712 to 0.740).
Photoperiod is +0.024 MDER/h (95% CI +0.017 to +0.031) and absolute latitude
is -0.014 MDER/10 degrees (95% CI -0.024 to -0.004). Complete 17-test BH
q-values are <0.001 for site, <0.001 for photoperiod, 0.013 for latitude, and
0.010 for site-versus-linear-latitude adequacy. Kumasi is +0.083 (95% CI
+0.041 to +0.126; within-MDER q = 0.001) and Munich is -0.083 (95% CI
-0.130 to -0.036; q = 0.002) relative to the equal-site mean.

Primary package support changes from 8/12/6/8 to 10/12/7/9 for
site/photoperiod/latitude/adequacy. All other raw p-values are unchanged, but
the complete site-family ranking moves calendar-day time below 10 lx melEDI
before sleep from q = 0.054 to q = 0.049. The inference change remains
material and requires author approval.

The repaired gap-timing-unaware near-eye MDER reproduces all four primary
support decisions (q <0.001, <0.001, 0.016, and 0.010). On exactly common
days, its mean differs from primary by only -0.000039 near eye and +0.000009
at the chest; the old approximately 0.010/0.015 comparison is superseded.

The exact paired/common placement display uses near eye on x, chest on y,
identity and null lines, equal geometry, component 95% intervals, and 107
participants with 489 primary or 478 comparator days at each placement.
Photoperiod is supported at both placements. Latitude is unsupported near eye
but supported at the chest in both datasets, demonstrating placement
sensitivity without constituting a direct placement-effect test.

All eight fits converge with positive-definite Hessians and no singularity or
major diagnostic failure. All remain `WARN_REVIEW` for Gaussian residual
shape and are classified acceptable with limitations. Primary results survive
omitting the highest-DFBETA participant or maximum-MDER day. Latitude is weak
after omitting Kumasi and also weak after omitting Tübingen. The chest maximum
of 3.574 and KNUST_S007 maximum absolute DFBETA of 2.62 remain visible
limitations; omission strengthens rather than creates the main chest signals.

Current evidence:

- `audit/hypotheses/H01/mder_METRIC-010/H01_METRIC-010_author_gate.md`;
- `audit/hypotheses/H01/mder_METRIC-010/point_refit_repaired_gap/`;
- `audit/hypotheses/H01/mder_METRIC-010/author_gate_post_repair/`; and
- `audit/handoffs/H01_shared_change_request.md` (resolved).

No bootstrap pilot, production bootstrap, report render, accepted-artifact
merge, central-ledger edit, or manuscript change was performed.

### Current proposed coordinator ledger updates

| Ledger class | Proposed entry |
|---|---|
| Finding | METRIC-010 changes primary H01 MDER from photoperiod-only support to site, photoperiod, latitude, and adequacy support; q <0.001, <0.001, 0.013, and 0.010. |
| Finding | Complete-vector BH recomputation moves the unchanged calendar-day pre-sleep site result from q = 0.054 to q = 0.049. |
| Finding | The repaired gap-timing-unaware sensitivity reproduces all four primary MDER support decisions; exact common-day mean differences are -0.000039 near eye and +0.000009 chest. |
| Finding | In exact paired/common samples, photoperiod support is consistent across placements, while latitude support appears at chest but not near eye; this is placement sensitivity, not a direct placement-effect test. |
| Decision | Shared-input gate resolved; retain Gaussian identity as acceptable with limitations and stop at material-inference author approval before any bootstrap pilot. |
| Deviation | Preserve all 16 non-MDER fits and accepted production draws; replace only MDER-dependent targets after explicit pilot and production approvals. |
| Change log | Repinned repaired inputs; reran eight isolated MDER point targets, complete affected BH vectors, diagnostics/influence, exact samples, common-day and paired-placement comparisons; verified 830 frozen non-MDER artifacts. |
| Result comparison | Provisional point baseline: support counts change from 8/12/6/8 to 10/12/7/9. Final interval comparison awaits approved production bootstrap. |
| Claim provenance | Existing H01 claims remain released until author approval, pilot review, production approval, and MDER-only final merge. |

## Superseded pre-repair METRIC-010 reopening (2026-08-11)

This section supersedes the closed H01 status below only for MDER-dependent
outputs. The accepted fits and artifacts for the other 16 metrics remain
frozen. No accepted H01 model bundle, production bootstrap draw, Stage 2–4
source, rendered page, central ledger, shared preparation file, or manuscript
file was overwritten.

The H01 model contract now uses the internal identifier
`mder_mean_of_viable_ratios`, while reader-facing terminology remains MDER.
The controlling construct is the arithmetic mean of viable one-minute
melEDI/illuminance ratios, using only finite, strictly positive pairs and
retaining a day at 720 or more viable minutes.

An isolated point refit was completed for all eight registered H01
scenario/placement/sample targets using the unchanged common Gaussian
identity implementation. The primary near-eye fit used 137 participants,
702 participant-days/observations, all 9 sites, and 10,949.917 h of viable
minute support. The equally weighted overall MDER was 0.726 (95% CI 0.712 to
0.740); photoperiod was +0.0236 MDER/h (95% CI +0.0166 to +0.0307), and
absolute latitude was -0.0139 MDER/10 degrees (95% CI -0.0237 to -0.0042).

The complete primary 17-test BH families provisionally support MDER for site
(q = 0.000635), photoperiod (q < 0.001), latitude (q = 0.0125), and
site-versus-linear-latitude adequacy (q = 0.00980). The changed MDER site
p-value also changes the BH rank of the unchanged pre-sleep metric, moving its
overall-site q from 0.0541 to 0.0487. Primary support counts would therefore
change from 8/12/6/8 to 10/12/7/9 for site, photoperiod, latitude, and
adequacy. This is a material inferential and claim change and requires author
approval.

All eight point fits converged without a predefined major diagnostic failure,
but all remain `WARN_REVIEW` for Gaussian residual shape. Primary MDER
support remains after omitting the highest-DFBETA participant or the maximum
MDER participant-day. Latitude leave-one-site-out results are weaker when
Kumasi or Tübingen is removed, so a universal latitude-gradient claim would
remain inappropriate. The chest maximum of 3.574 is newly identified under
METRIC-010 and has strong participant influence; the superseded
ratio-of-integrals device-day screen was not reused.

The gap-timing-unaware chest artifact retains MDER = 0 for THUAS_S002 on
2025-03-09 in both all-available and paired/common frames. A retained mean of
strictly positive minute ratios cannot equal zero. The required shared repair
and full downstream scope are documented in
`audit/handoffs/H01_shared_change_request.md`. H01 stopped without changing
the shared artifacts.

The complete evidence and decisions requested are in
`audit/hypotheses/H01/mder_METRIC-010/H01_METRIC-010_author_gate.md`. The
isolated point outputs are under
`audit/hypotheses/H01/mder_METRIC-010/point_refit/`, and the provisional
complete-family, sample, diagnostic, distribution, influence, and hash
evidence is under
`audit/hypotheses/H01/mder_METRIC-010/author_gate/`.

No METRIC-010 bootstrap pilot was launched. After the coordinator repairs and
repins the invalid gap row and the author accepts the revised point inference,
the next authorized action is a separately stored 50-successful-refit pilot
for every planned MDER bootstrap target, followed by another explicit author
approval before production.

### Proposed coordinator ledger updates

| Ledger class | Proposed entry |
|---|---|
| Finding | METRIC-010 changes primary H01 MDER support from photoperiod-only to support for site, photoperiod, latitude, and adequacy; primary site q = 0.000635, latitude q = 0.0125, adequacy q = 0.00980. |
| Finding | Complete-vector BH recomputation moves the unchanged calendar-day pre-sleep site result from q = 0.0541 to q = 0.0487. |
| Finding | The gap-timing-unaware chest artifact retains one construct-impossible zero MDER day (THUAS_S002, 2025-03-09), affecting its all-available and paired/common H01 frames. |
| Decision | Reopen H01 only for METRIC-010; stop at a shared-input repair gate and a material-inference author gate. |
| Deviation | Preserve all 16 non-MDER fits and every accepted production draw; do not update reports or claims from provisional point output. |
| Change log | Updated the H01 MDER identifier/input pins; produced eight isolated point refits, complete provisional 17-test BH vectors, exact samples, diagnostics, upper-tail and influence checks, frozen non-MDER hashes, gate evidence, and the shared-change request. |
| Result comparison | Provisional only: primary support counts change from 8/12/6/8 to 10/12/7/9 for site/photoperiod/latitude/adequacy; final comparison awaits shared repair and production bootstrap. |
| Claim provenance | Existing H01 claims remain the released version until the shared repair, author decision, pilot approval, and production update are complete. |

## Authoritative current disposition

This section supersedes every earlier gate-status or production-incomplete
statement retained later in this file as audit history. `H01-005` and
`H01-006` remain author-approved. The jointly pinned main and
manuscript-prepared manifests match the prefit checkpoint. The response
construct is calendar-day cumulative time below 10 lx melEDI before sleep,
without truncation; strictly above six hours is an audit warning only. The
primary L10 midpoint conversion subtracts 24 hours only for values strictly
after 16:00, with the noon cut retained as a same-row sensitivity.

The three-metric response-family assessment applied the same candidate
implementation and model rows in both data scenarios. It changed only time
below 10 lx melEDI before sleep, from the submitted-style Tweedie/log model to
a Gaussian identity model reported as an ordinary difference. The
submitted-style Tweedie/log family was retained for time below 1 lx melEDI
during sleep, and the shifted-log Gaussian family was retained for darkest-10-
hour mean melEDI because no common alternative improved the predeclared
diagnostic screen across scenarios and placements. This is the approved
calculation baseline; no family was switched silently.

### Post-closure reader-display revision (2026-08-03)

At the author's request, the H01 publication summary (Table 7 in the current
Nature Health page) now writes each exact fitted sample as
*n*<sub>participants</sub> = ...;
*n*<sub>participant-days</sub> = .... Its Quarto-owned caption and `gt` source
note state that *n*<sub>participant-days</sub> equals fitted observations for
the 15 participant-day metrics. They also preserve the necessary exception:
interdaily stability and intradaily variability are participant-level models
with one fitted observation per participant, while
*n*<sub>participant-days</sub> records their contributing repeated-day support.
All 17 primary near-eye
models include nine sites. This qualification is required by the stored exact
samples and prevents a false participant-days-equals-observations statement
for the two dynamics metrics.

Figures 3 and 4 retain the accepted site estimates, 95% confidence intervals,
registered site colours/order, and within-metric adjusted p-values. Their
display now distinguishes supported site contrasts redundantly: filled circles
and thicker intervals denote within-metric adjusted p < 0.050, whereas open
circles and thinner intervals denote adjusted p >= 0.050. Each site row appends
the exact fitted observation count for that metric and site as `n`; the source
CSV joins these values one-to-one from the preserved exact-by-site sample
table. The figures now have only two group-level tags: A for ratio estimands
and B for difference estimands. Within every metric facet the x range is
symmetric around the applicable null, so the ratio null at 1 and difference
null at 0 occupy the same horizontal position. The registered north-to-south
site order is retained, omitting unavailable sites without rotating the
remaining labels. Axis, site, facet, panel-title, and legend text were enlarged
slightly. Captions and alt text explain every new encoding.

REPORT-013 was assessed at this authorized figure touchpoint. The revised
Figures 3 and 4 display fitted ratios around 1 and signed differences around
0, not a non-negative, strongly right-skewed, zero-containing reader-facing
variable. The other figures regenerated by the Stage 3 reporting builder are
support, R², diagnostic-assessment, and paired-estimand displays. Therefore the
`LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)` rule is not applicable
to this revision; source values remain unchanged.

Only the reporting layer was regenerated with R 4.6.1 (`gt` 1.3.0,
`ggplot2` 4.0.3) and rendered with Quarto 1.9.37. No model, prediction,
`emmeans` result, p-value, bootstrap draw, or sensitivity calculation was
rerun. The first sandboxed render completed all 75 knitr steps but could not
open Quarto's user Sass-cache database; the identical H01-only command then
completed outside that cache restriction. Direct original-resolution review
of both revised PNGs found readable site counts, A/B group tags, legend, axes,
and metric labels; centered null lines; and no clipping or overlap. Automated
browser control again
could not claim/reload the local `file://` page under its URL policy; final
HTML structure was instead verified directly, and the author can inspect the
already-open local page.

The following checks pass without refitting:

- `tests/hypotheses/H01/test_h01_reporting_inputs.R`;
- `tests/hypotheses/H01/test_h01_preparation_report.R` (53 identities);
- `tests/hypotheses/H01/test_h01_bootstrap_outputs.R` (128 preserved targets).

| Post-closure display identity | SHA-256 |
|---|---|
| `notebooks/hypotheses/H01.qmd` | `15dad7946cb979127e19bdee302a00d599a4e609618b74786d2a3bf0c72d54ba` |
| `_build/nathealth/notebooks/hypotheses/H01.html` | `26f757f4a10dcb49e6adb9f2e49553dc478ca02adb599f4d06495ea8ae518c33` |
| Stage 3 reporting-input builder | `294789e6716910d45e9a00f4bb955d6793f12a81320e75595500465379e036be` |
| Stage 3 reporting verifier | `97ce655f305b69bbba3c80a4228e4af3f4985e1ba729c52b502ffed0c85cd189` |
| Stage 3 reporting manifest | `27c613126393a4560ed74b1bc2c592349d3345209d5b06b2625b03620c439b8d` |
| Stage 3 reporting provenance | `9463be81373ec3f6b6a973ea6481cfc8a45c5a3c7558ca0c1bf029d0c5a66a03` |
| Site-contrast table/source CSV (byte-identical) | `c8972862c2058d0cb92ff780c094e165cb914b3754157db757bbf5743782c826` |
| Near-eye site-contrast PNG | `f8503fa9cdddb864afab0d4d623941ba49d180dc83846245b5f686bcbfa37940` |
| Near-eye site-contrast SVG | `1440c3cee2d4081707bcf2e75de1ea125e206e97bb056d95d024989434daa67f` |
| Chest site-contrast PNG | `e54eb00b33529e46ccf4d782593917035162c166f0b5a1ccd0787e4bd62fce7a` |
| Chest site-contrast SVG | `e0aa673518c290c565ba492ee85c53a7c27ddab241c54007aa7e4eb4f12be772` |
| Preparation report manifest | `0d9a3db70b2caba2e37d09290c4735a677be73758f45ecbc7255f9595cb9d918` |

Proposed coordinator change-log entry: display-only H01 revision of the
publication-summary sample notation and site-contrast figures; exact sample,
model, multiplicity, sensitivity, comparison, and claim records remain
unchanged. No central scientific decision or claim-provenance update is
required.

### Analysis-preparation and provenance companion completion

The author approved the standalone results report and authorized the
analysis-preparation and provenance companion under H01-010/CHG-089. The
coordinator then completed the shared website integration under CHG-090,
placing the companion immediately after H01 in both the Nature Health render
list and sidebar. The H01 worker did not edit shared Quarto configuration.

The source at
`audit/hypotheses/H01/H01_analysis_preparation.qmd` is a scientific reader's
record of the full data-to-result chain. It documents the pinned inputs and
construct checks, 17-metric response package, eight analysis scenarios,
exact fitted samples and exclusions, response transformations and units,
exact Wilkinson formulas and model engines, estimands, four 17-test
Benjamini--Hochberg families, hierarchical site contrasts, production
bootstrap, diagnostics, influence checks, sensitivity branches, execution
order, environment, and manifest chain. It links reciprocally to the H01
results page and contains no internal workflow-stage narrative.

Rendering is intentionally bounded. It verifies current SHA-256 identities,
reads stored results, and calculates only descriptive summaries from already
prepared H01 rows. Its executable R chunks contain no call to `lm()`,
`lmer()`, `glmmTMB()`, `emmeans()`, `predict()`, `simulate()`, model-specific
H01 fit functions, or bootstrap functions. No fit, prediction, simulation,
response-family assessment, marginal mean, or bootstrap was repeated.

The integrated H01-only render completed all 53 steps and exited 0 under R
4.6.1 and Quarto 1.9.37. The final page contains 20 semantic `gt` tables, two
reader figures with captions and non-empty alt text, and an informational
execution-boundary callout. The authoring QMD and downloadable website QMD are
byte-identical. Reciprocal links resolve in both rendered pages. Each figure
has a paired full-precision source CSV; exact byte copies are available from
the page support directory and match their audited sources by SHA-256.

Both reader figures were inspected at their original rendered dimensions.
Their metric labels, axis labels, tick labels, legend, shapes, and units are
readable; no clipping, overlap, distorted text, awkward wrapping, or
legend/data imbalance was found. Browser automation cannot inspect local
`file://` pages under its URL policy, so this visual finding is limited to the
original rendered PNGs, while page structure, tables, links, captions, and
alt text were checked directly from the final HTML.

The shared REPORT-007 verifier and the H01-specific preparation test passed:
23 Quarto figure containers (20 table containers, one Mermaid diagram, and
two image figures), 20 `gt` tables, two image figures, and 53 manifest
identities. The following additional read-only H01 verifiers also passed:

- `test_h01_bootstrap_outputs.R` (128 preserved production targets);
- `test_h01_contract.R`;
- `test_h01_fit_outputs.R`;
- `test_h01_reporting_inputs.R`;
- `test_h01_response_family_candidates.R`.

The synthetic-fit unit tests were not rerun during this transition because
the authorization explicitly prohibited new model or bootstrap execution.
Their earlier passing results remain recorded below.

| Final report/provenance identity | SHA-256 |
|---|---|
| `notebooks/hypotheses/H01.qmd` | `56d506d4f772ba11ef92353122b12f077adf83323946e434ea4b3d1024b9a7e5` |
| `_build/nathealth/notebooks/hypotheses/H01.html` | `c2536fccd665a2845ab0252c1a98990423f10ddb040a59df25c2b5d02756fba1` |
| `audit/hypotheses/H01/H01_analysis_preparation.qmd` | `c6afa418af2b833e44a7bfb68544f9c6e55c7218e8d6c3a9318cd0ecac72bf1c` |
| Website-copy preparation QMD | `c6afa418af2b833e44a7bfb68544f9c6e55c7218e8d6c3a9318cd0ecac72bf1c` |
| `_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html` | `93bf0bad2763de3fe345b09f7f5867468e648a1c0ab682f65db5482e820b2fc8` |
| Preparation manifest builder | `4828bfc279758b1b240e298ecbddd1ef2aace6ad1df8db5dfece1153b2f78b8d` |
| Preparation verifier | `12b04008e60cab737780947308042634ee06643dddc450502754fade11228bea` |
| Preparation report manifest | `9fbf278548796bb418708de5117ea94ca08d754d550f9919351d24f30c2aaaa4` |
| Final worker inventory builder | `1bcfdc0eaee6a7d63e16368b87a33e3b0499789a756af1f551594d6f2d6f8a63` |
| Model-results manifest | `2cc4081ae973f7d056539f7aef45c4f3a2ec7cbaa018346fff3dba564ec356b7` |
| Fitted-sample figure source/download | `760e634fd6139b8c6561d185c95fb5c06ef5b41637c7b20f8c61b0e627ff37c7` |
| Model-frame-retention figure source/download | `28cc582f2778c849025f2ea77fee2036ce693378630d6f7e172adc0db6bb6d5b` |
| Stage 3 reporting verifier | `0acf7206aadae20d475de0ed9196255670da4f7debba72945575782bdfc29e05` |
| Coordinator-owned Nature Health profile | `4b7ce91614a6d8f76f2526ced5aed3e2064fd2a70113018057b7a11b3916c803` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

The exhaustive `artifacts/12_manifests/H01_worker_artifacts.csv` inventories
1,279 H01-owned files, including this handoff, the companion source and
website copy, page assets, tests, scripts, model outputs, tables, figures,
source data, and nested manifests. It deliberately omits its own row to avoid
a circular checksum; its final SHA-256 is therefore reported alongside this
handoff to the coordinator.

Commands used for this transition were limited to H01 rendering, manifest
assembly, and read-only verification:

```sh
quarto render notebooks/hypotheses/H01.qmd --profile nathealth
quarto render audit/hypotheses/H01/H01_analysis_preparation.qmd --profile nathealth
Rscript --vanilla scripts/hypotheses/H01/build_h01_preparation_report_manifest.R
Rscript --vanilla tests/hypotheses/H01/test_h01_preparation_report.R
Rscript --vanilla tests/hypotheses/H01/test_h01_reporting_inputs.R
Rscript --vanilla tests/hypotheses/H01/test_h01_bootstrap_outputs.R
Rscript --vanilla tests/hypotheses/H01/test_h01_contract.R
Rscript --vanilla tests/hypotheses/H01/test_h01_fit_outputs.R
Rscript --vanilla tests/hypotheses/H01/test_h01_response_family_candidates.R
```

### Stage 3 standalone results report completion

The accepted four-stage workflow has completed the author-approved standalone
results report. Stage 1 is satisfied by the approved audit and gate records.
Stage 2 is complete and its accepted comparison source and rendered page are
preserved without content changes at:

- `audit/hypotheses/H01/02_implementation_and_v0_comparison.qmd`, SHA-256
  `af6a50df9d8f384f7a07053bdb543bd9c475f8dc13736ba3cb432f693b6628b3`;
- `_build/nathealth/audit/H01/02_implementation_and_v0_comparison.html`,
  SHA-256
  `4daa424552ce83cd0a5879cae4ced62d6ca75c4703bc0a1b3be2806ff332c10e`.

The unnumbered production-bootstrap gate between Stages 2 and 3 is complete.
The Stage 3 source at `notebooks/hypotheses/H01.qmd` is now a standalone
reader-facing report. It contains no comparison with the submitted analysis,
internal gate history, discarded response-family candidates, or construction
variants. It quotes the preregistered H1 hypothesis, reports the relevant
deviations, and explains the scientific question, selected methods, results,
interpretation, limitations, and registered sensitivities in manuscript
language. Near-eye results are primary and chest results are complementary.
The first sensitivity-dataset explanation uses the approved exact term
“gap-timing-unaware dataset,” states that the general 50%-per-hour and
80%-per-day coverage rules still apply, and explains the missing-observation
timing distinction from the time-sensitive primary metric dataset; later uses
call it the primary dataset and gap-timing-unaware dataset.

Visible evaluated R cells show the exact Wilkinson formula objects supplied
to fitted and comparison models. The report gives exact fitted participants,
participant-days, observations or hours, and sites; 95% confidence intervals;
the four separate 17-test Benjamini–Hochberg families; hierarchical
site-versus-equally-weighted-overall-site `emmeans` contrasts only when the
overall site test is supported; stored production-bootstrap R² summaries;
diagnostic evidence and model-level acceptability assessments; registered
sensitivities; and a matched near-eye-versus-chest placement display. All
reader-facing p-values follow REPORT-008, and site names, order, and colours
follow DISPLAY-001 without changing model coding or inference.

The coordinator repaired the stale shared Quarto project cache recoverably at
`/private/tmp/nathealth-quarto-cache-backup.AYhadH/project-cache` and rendered
only H01 using:

```sh
env R_PROFILE_USER=/dev/null \
  R_LIBS_USER=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  RENV_PATHS_SANDBOX=/private/tmp/H01-renv-sandbox-R4.6.1 \
  NATHEALTH_PROJECT_ROOT=/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026 \
  quarto render notebooks/hypotheses/H01.qmd --profile nathealth
```

All 36 R cells and all 75 reported render steps completed, and the render
exited 0. No H01 study fit, bootstrap, prediction, simulation, response-family
selection, or other scientific calculation was repeated. The two modelling
smoke tests use only their existing small synthetic fixtures. No shared Quarto
configuration, shared preparation, dependency, manuscript, submission, or
central-ledger file was edited by the H01 worker.

The author-comment revision implements REPORT-012 with the exact
**Answer in brief** note immediately after the hypothesis and analytical
question. The former standalone “Results in brief” heading is absent. It adds
a 17-row publication summary that combines the adjusted model decisions,
photoperiod and latitude effects with 95% confidence intervals, and exact
fitted samples while retaining the detailed test and effect tables. It also
adds the requested site-by-metric matrix for the eight metrics with a
supported overall site test; cells show the site-specific difference or ratio
with 95% confidence interval and bold only the within-metric adjusted
deviations. Exact
samples are split into eight scenario/placement tabs. Formula cells now render
semantic `gt` tables directly from the exact evaluated Wilkinson objects and
do not expose transient R environments.

The final profile HTML contains 36 semantic `gt` tables with table heads and
bodies and 10 local figures with non-empty alt text; every local image
reference resolves, no cell-output error is present, and the visible page has
no Stage 2/pilot banner, prohibited historical scenario terminology, leaked
`<environment: ...>` string, or duplicate photoperiod/latitude coverage
section. The publication tables use semantic `gt` construction with
Quarto-owned captions and labels. The exact-sample and representative-
diagnostic displays use two panel tabsets instead of oversized single tables.
Automated browser control does not permit a reload of the local `file://`
page, so browser-level table appearance is not overclaimed here.

All 10 reader-facing figure PNGs were inspected directly at original
resolution. Axes, ticks, legends, facets, units, and direct labels are
readable; no clipping, cropping, distorted text, orphaned units, or colour/
order inconsistency was found. The near-eye and chest site-contrast figures
now use two facet columns, larger 9--10.5 pt plot text, and taller canvases.
The matched-placement figure is placed in the results overview and uses exact
common samples; the all-available support heatmap is explicitly not used to
infer a placement difference. Four preserved point-model diagnostic plots and
their source CSVs make representative Gaussian and Tweedie review signals
inspectable, with the formal Tweedie simulation values reported separately.
The two photoperiod/latitude coverage figures are retained with checksums and
marked `retained_not_displayed` because the section duplicates the descriptive
report. This is an acceptable REPORT-011 visual-QA result.

`tests/hypotheses/H01/test_h01_reporting_inputs.R` now enforces the accepted
Stage 3 production and presentation contract: no preview rows, at least 1,000
retained successful joint refits for every estimable target, exactly one
**Answer in brief** callout, 36 semantic tables, 10 alt-text-bearing figures,
eight sample tabs, four representative diagnostic figures, no formula-
environment leakage, and preservation-but-nondisplay of both coverage figures.
Under R 4.6.1 and the activated project library, all H01 tests pass:

- `test_h01_reporting_inputs.R`;
- `test_h01_contract.R`;
- `test_h01_fit_outputs.R`;
- `test_h01_response_family_candidates.R`;
- `test_h01_bootstrap_outputs.R`;
- `test_h01_modeling.R`;
- `test_h01_response_gate_repairs.R`.

The production-bootstrap test verifies all 128 stored canonical draw files,
their audit statuses, and all 95% intervals; it does not refit them. The
model-results manifest had one stale non-scientific code checksum for
`build_h01_worker_manifest.R`; that H01-owned provenance row was refreshed to
the current file hash and byte size, after which the production-bootstrap
verification passed. No result artifact changed.

| Current Stage 3 identity | SHA-256 |
|---|---|
| `notebooks/hypotheses/H01.qmd` | `56d506d4f772ba11ef92353122b12f077adf83323946e434ea4b3d1024b9a7e5` |
| `_build/nathealth/notebooks/hypotheses/H01.html` | `c2536fccd665a2845ab0252c1a98990423f10ddb040a59df25c2b5d02756fba1` |
| Stage 3 reporting-input builder | `79025b9f020d397f8cb31d4954c68d9a47502213bf4f86825bd159256f84a75b` |
| Stage 3 reporting manifest | `2cc5fca0091ae280db0efed955ac1f55c91056ec2933b23b346653e40819454a` |
| Stage 3 reporting provenance | `cde180c61514deed541f5a11b1bb112d43c743cb6269c5a01eacc50bab4cffc3` |
| Model-results manifest | `2cc4081ae973f7d056539f7aef45c4f3a2ec7cbaa018346fff3dba564ec356b7` |
| Stage 3 reporting test | `0acf7206aadae20d475de0ed9196255670da4f7debba72945575782bdfc29e05` |
| Main model-data manifest | `ea9d47f624a8777f8416447612bfcc2309cf2bac40fdf4fd5021c8767806dfbf` |
| Gap-timing-unaware internal model-data manifest | `cb47b3678146604aadca875a96f79909e2d73355162683ff0603f038f3b31a25` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |

### Current proposed coordinator ledger updates

| Ledger class | Proposed entry |
|---|---|
| Finding | The H01 standalone reader-facing report rendered successfully with the Nature Health profile from verified stored outputs: 36 R cells, 36 semantic `gt` tables, 10 alt-text-bearing figures, and no cell-output error. |
| Finding | Direct original-resolution QA found all 10 displayed figures acceptable under REPORT-011; the enlarged two-column site-contrast layouts, matched common-sample placement display, representative diagnostic plots, site order/colours, clipping, and units passed review. |
| Finding | The H01 analysis-preparation and provenance companion rendered from stored outputs with 20 semantic `gt` tables, two alt-text-bearing figures, exact reciprocal links, a byte-identical downloadable QMD, two byte-identical downloadable source CSVs, and 53 verified manifest identities. |
| Decision | Record H01 Stage 3 as author-approved under H01-010 and close Stage 4 as complete after applying the detailed preparation-manifest identities. |
| Decision | Adopt the exact **Answer in brief** callout as the required H01 implementation of REPORT-012; the coordinator has already recorded this as a fixed Stage 3 reporting staple. |
| Deviation | Automated browser control could not reload the local `file://` page under its navigation policy; structural HTML and direct exported-figure checks passed, and the author separately approved the final standalone results report. |
| Change log | Added the combined publication summary and significant-site-deviation matrix; split exact samples into eight tabs; reformatted visible formula objects; added four representative diagnostic plots and stored diagnostic values; moved the common-sample placement display into the overview; enlarged site-contrast typography; removed the duplicate reader-facing coverage section while retaining its artifacts and checksums; added the reciprocal analysis-preparation companion and downloadable source data; and refreshed H01 reporting and provenance manifests without study-model recomputation. |
| Result comparison | The accepted Stage 2 comparison source and HTML remain separately archived with exact hashes; the Stage 3 report intentionally contains no submitted-versus-new comparison language. |
| Claim provenance | Results claims, intervals, diagnostics, multiplicity, and sensitivities are read from verified accepted result and production-bootstrap artifacts; the companion maps those outputs to their data, code, commands, and hashes without changing any claim or manuscript file. |

This Stage 3 completion record supersedes all earlier preview-render counts,
Stage 2 main-page hashes, and open-render statements retained below as audit
history. The analysis-preparation companion above is the authoritative final
provenance record.

### Production bootstrap completion

The author approved production after the separate 50-refit COMPUTE-001 pilot.
The production wrapper ran only the eight changed targets: main and
manuscript-prepared data crossed with near eye and chest and with all-available
and paired/common samples. It reused the identical `h01_bootstrap_r2()`
implementation and canonical seeds used by the other metrics.

| Production check | Verified result |
|---|---|
| Changed targets | 8 of 8 PASS |
| Retained successful joint refits | 1,000 per target; 8,000 total |
| Attempts | 12,000 |
| Successful attempts | 11,996 |
| Failed/warning attempts | 4; each was a maximum-gradient convergence warning and was replaced by a successful attempt |
| Preserved targets | 120 draw files, all hashes unchanged |
| Complete package | 128 audit rows PASS; 128 canonical draw files |
| Interval rows | 1,208 PASS and 8 explicitly NON_ESTIMABLE participant-associated-share rows; 1,216 total |
| Runtime | 310.9 seconds wall time, four workers, one BLAS/OpenMP thread per worker |
| Checkpoints | Eight completed run-metric checkpoints |
| Gate status | No construct, clock-conversion, response-family, or bootstrap major gate reopened |

The four failed attempts occurred once in each main-data target. All four
manuscript-prepared targets completed 1,500/1,500 successful attempts. Failed
attempts remain in `H01_r2_bootstrap_failures.csv`; they are not among the
1,000 retained draws for any target.

### Accepted reporting revision: Figure S10

The author accepted progression to the next reporting stage and requested one
exception: Figure S10 must apply the submitted visual styling to the new
audited data. The exact V0 plotting code was recovered read-only from
`20ba43c:Descriptives.qmd` in repository history. The H01 reconstruction now
uses its square layout, point-plus-ridgeline geometry, black masks outside the
theoretical civil-photoperiod envelope, in-panel
legend, and white “possible photoperiods” annotation. DISPLAY-001 site names,
visible order, and colours remain exact. Following the author's next display
revision, all points use one circular symbol and the coloured observations and
density ribbons are drawn in front of the black masks. Sites sharing a colour
remain distinguishable by their fixed north-to-south placement.

This was a reporting-only change. The observed source remains 816 main
near-eye participant-days with SHA-256
`5d17eaf6ee3c1ecceca38a5d57153d1f38f0374efcf85218450990063569997f`,
and the 61-row theoretical 2025 civil-photoperiod source remains
`073fa2fdae1e4a97c76409d2fc62136dddce0f4c16359b21d855cf7bf0b36f4a`.
No model, multiplicity calculation, response-family decision, bootstrap draw,
estimate, interval, sample, or claim changed. Only the H01 reporting builder,
Figure S10 PNG/SVG, reporting provenance/manifest, H01 QMD/HTML, model-results
manifest, and this handoff were regenerated.

### Exact primary and manuscript-prepared samples

Cells show participants / participant-days / observations. Main-data support
hours are derivation support, not additional model observations. The main
M10/L10 producer did not export exact support minutes, and the
manuscript-prepared artifacts do not retain support minutes; those values
remain unavailable rather than being imputed.

| Metric | Main sample | Manuscript-prepared sample | Main support h |
|---|---:|---:|---:|
| Interdaily stability | 141 / 816 / 141 | 141 / 811 / 141 | 18,851.0 |
| Intradaily variability | 141 / 816 / 141 | 141 / 811 / 141 | 18,851.0 |
| Mean melEDI | 141 / 816 / 816 | 141 / 811 / 811 | 18,851.0 |
| Brightest 10 h mean | 141 / 816 / 816 | 141 / 811 / 811 | unavailable |
| Darkest 10 h mean | 141 / 816 / 816 | 141 / 811 / 811 | unavailable |
| Time above 1,000 lx melEDI | 141 / 816 / 816 | 141 / 811 / 811 | 18,851.0 |
| Time above 250 lx melEDI during wake | 141 / 737 / 737 | 140 / 755 / 755 | 9,174.3 |
| Time below 10 lx melEDI before sleep | 139 / 655 / 655 | 141 / 780 / 780 | 1,925.5 |
| Time below 1 lx melEDI during sleep | 141 / 778 / 778 | 141 / 790 / 790 | 6,282.5 |
| Longest continuous period above 250 lx melEDI | 141 / 816 / 816 | 141 / 811 / 811 | 18,851.0 |
| Midpoint of the brightest 10 hours | 141 / 816 / 816 | 141 / 811 / 811 | unavailable |
| Midpoint of the darkest 10 hours | 141 / 816 / 816 | 141 / 811 / 811 | unavailable |
| Mean timing of exposure above 250 lx melEDI | 141 / 742 / 742 | 141 / 778 / 778 | 17,209.6 |
| First light timing above 250 lx melEDI | 140 / 727 / 727 | 141 / 778 / 778 | 16,832.5 |
| Last light timing above 250 lx melEDI | 141 / 687 / 687 | 141 / 778 / 778 | 15,995.0 |
| melEDI dose | 141 / 761 / 761 | 141 / 811 / 811 | 17,678.8 |
| Melanopic daylight efficacy ratio | 141 / 760 / 760 | 140 / 725 / 725 | 17,656.6 |

The exact 34-row machine-readable table, including sites, analysis units,
families, transforms, and unavailability reasons, is
`artifacts/09_tables/H01/reporting/H01_reporting_exact_samples.csv`.

### Primary estimates, 95% intervals, multiplicity, and diagnostics

Photoperiod and latitude entries are the declared practical-scale effect and
95% confidence interval; `×` denotes a ratio. Four distinct vector-wide BH
families use one model-level p-value per metric and `n = 17`: overall site,
photoperiod, latitude, and same-frame site-versus-latitude adequacy.

| Metric | Photoperiod effect [95% CI] | Latitude effect [95% CI] | Site q | Photoperiod q | Latitude q | Adequacy q | Diagnostic |
|---|---:|---:|---:|---:|---:|---:|---|
| Interdaily stability | ×0.983 [0.944, 1.024] | ×1.009 [0.961, 1.060] | 0.245 | 0.401 | 0.903 | 0.189 | PASS |
| Intradaily variability | -0.019 [-0.056, 0.019] | -0.039 [-0.084, 0.005] | 0.483 | 0.327 | 0.155 | 0.723 | PASS |
| Mean melEDI | ×1.181 [1.109, 1.257] | ×1.154 [1.066, 1.248] | 0.000703 | 0.00000131 | 0.00181 | 0.0379 | WARN_REVIEW |
| Brightest 10 h mean | ×1.243 [1.133, 1.363] | ×1.238 [1.106, 1.385] | 0.0120 | 0.0000138 | 0.00140 | 0.332 | WARN_REVIEW |
| Darkest 10 h mean | ×1.088 [1.034, 1.144] | ×1.040 [0.971, 1.115] | 0.0000134 | 0.00163 | 0.400 | 0.0000275 | WARN_REVIEW |
| Time above 1,000 lx melEDI | ×1.206 [1.128, 1.288] | ×1.027 [0.942, 1.120] | 0.0773 | 0.00000131 | 0.769 | 0.0583 | PASS |
| Time above 250 lx melEDI during wake | ×1.136 [1.073, 1.202] | ×1.115 [1.035, 1.202] | 0.00865 | 0.0000541 | 0.0136 | 0.0583 | WARN_REVIEW |
| Time below 10 lx melEDI before sleep | -0.134 [-0.201, -0.066] | 0.002 [-0.085, 0.089] | 0.0541 | 0.000164 | 0.962 | 0.0468 | WARN_REVIEW |
| Time below 1 lx melEDI during sleep | ×0.987 [0.968, 1.006] | ×0.998 [0.974, 1.022] | 0.0633 | 0.227 | 0.903 | 0.0489 | WARN_REVIEW |
| Longest continuous period above 250 lx melEDI | ×1.125 [1.065, 1.187] | ×1.060 [0.992, 1.132] | 0.398 | 0.0000498 | 0.155 | 0.626 | PASS |
| Midpoint of the brightest 10 hours | 0.054 [-0.045, 0.153] | 0.189 [0.061, 0.317] | 0.000715 | 0.305 | 0.0132 | 0.0122 | WARN_REVIEW |
| Midpoint of the darkest 10 hours | -0.148 [-0.245, -0.050] | 0.121 [-0.002, 0.244] | 0.0223 | 0.00372 | 0.130 | 0.0489 | WARN_REVIEW |
| Mean timing of exposure above 250 lx melEDI | 0.121 [0.028, 0.213] | 0.335 [0.210, 0.459] | 0.00000000249 | 0.0125 | 0.00000561 | 0.0000498 | WARN_REVIEW |
| First light timing above 250 lx melEDI | -0.097 [-0.247, 0.053] | 0.020 [-0.170, 0.211] | 0.121 | 0.227 | 0.903 | 0.0844 | WARN_REVIEW |
| Last light timing above 250 lx melEDI | 0.323 [0.186, 0.460] | 0.455 [0.275, 0.636] | 0.000000143 | 0.0000138 | 0.0000137 | 0.000827 | WARN_REVIEW |
| melEDI dose | ×1.275 [1.169, 1.391] | ×1.016 [0.913, 1.131] | 0.225 | 0.00000109 | 0.903 | 0.169 | WARN_REVIEW |
| Melanopic daylight efficacy ratio | 0.014 [0.008, 0.020] | -0.005 [-0.012, 0.003] | 0.305 | 0.0000240 | 0.384 | 0.332 | WARN_REVIEW |

Supported primary metrics number 8/17 for site, 12/17 for photoperiod, 6/17
for latitude, and 8/17 for adequacy. Hierarchical equal-site `emmeans`
comparisons were produced only for the eight metrics with a supported overall
site test: 72 site-versus-equally-weighted-overall contrasts, each with a
difference or ratio, 95% confidence interval, raw p-value, and within-metric
adjusted p-value. They are in
`artifacts/09_tables/H01/reporting/H01_reporting_site_followups.csv` and Table
5 of the H01 HTML.

All 128 estimable fits converged, had positive-definite Hessians, and were
nonsingular; the eight non-estimable rows are the predeclared paired-sample
participant-level IS/IV combinations. Across all 136 run-metric rows there are
31 PASS, 97 WARN_REVIEW, 8 NON_ESTIMABLE, and no FAIL_MAJOR_GATE. The primary
run has 4 PASS and 13 WARN_REVIEW. WARN_REVIEW exposes residual-shape,
zero-mass, or unavailable-upper-bound review signals; it is not a convergence
failure and does not authorize a family switch. Four prediction-bound warnings
and 14 strong residual warnings remain disclosed across the full battery.

### R² package

Every estimable metric/run has at least 1,000 successful joint bootstrap
refits. `H01_r2_bootstrap_summaries.csv` contains marginal R², conditional R²,
participant-associated share, site part-R², photoperiod part-R², latitude-model
marginal R², latitude part-R², and unrepresented share with 95% percentile
intervals. These contributions are not added because site and photoperiod
information can overlap. Table 6 in the H01 HTML reports all 17 primary rows;
all evidence cells now read `Production: 1,000`.

For the changed pre-sleep metric in the main near-eye primary run, marginal R²
is 0.076 [0.046, 0.172], conditional R² 0.383 [0.318, 0.485], the
participant-associated share 0.307 [0.217, 0.381], site part-R² 0.054 [0.032,
0.134], photoperiod part-R² 0.049 [0.012, 0.105], latitude part-R² 0.000
[0.000, 0.017], and unrepresented share 0.617 [0.515, 0.682].

### Sensitivity classification

The battery is **qualitatively sensitive at the individual metric-family
support level**, while the broad pattern is retained. Relative to the main
near-eye primary run, eight metric-family support cells switch in the
manuscript-prepared near-eye all-available run, nine switch in the main
near-eye paired/common-sample run, and 21 switch in the complementary main
chest run. Photoperiod remains 12/17 in the primary, manuscript-prepared
near-eye, and both complementary all-available runs; site and latitude support
are more placement- and sample-sensitive. This classification prevents the
chest or prepared-data results from being described as numerically identical
confirmations.

Required auxiliary checks are complete: the noon-cut L10 fit uses identical
rows and the same Gaussian implementation; longest-period results include the
exactly-identified-only bout analysis; participant influence and leave-one-site
latitude checks remain in the H01 diagnostics; and manuscript-prepared support
hours remain unavailable. Near eye remains primary and chest complementary.

### Comparison with submitted V0 and claim implications

Relative to V0, supported primary metrics change from 7 to 8 for overall site,
11 to 12 for photoperiod, and 5 to 6 for latitude. Time above 250 lx melEDI
during wake is newly supported for site and latitude; L10 midpoint is newly
supported for photoperiod. No previously supported metric is lost in these
three submitted families. The fourth, site-versus-latitude adequacy family is
new and must not be interpreted as a residual site test after latitude
adjustment.

The submitted broad statement that site differences concentrate in level- and
timing-based outcomes remains recognizable but should be revised to include
the newly supported waking-duration metric. Photoperiod remains broadly
associated with duration, level, dose, spectrum, and selected timing metrics.
First light timing remains unsupported for site in the primary analysis. No
manuscript claim was edited; these are proposed consequences for coordinator
review.

### Historical Stage 2 commands and environment (superseded)

The following is the preserved Stage 2 execution record. Scientific
calculations used R 4.6.1 and the project library at
`renv/library/macos/R-4.6/aarch64-apple-darwin23`. Consequential versions were
lme4 2.0.1, glmmTMB 1.1.14, emmeans 2.0.3, performance 0.17.1, gt 1.3.0,
knitr 1.51, and Quarto 1.9.37. No package was installed or updated.

```sh
H01_AUTHOR_APPROVAL=approved H01_PRODUCTION_REFITS=1000 \
H01_PRODUCTION_CORES=4 OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
MKL_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 \
Rscript --vanilla \
scripts/hypotheses/H01/run_h01_response_family_bootstrap_production.R

H01_STAGE=manifest Rscript --vanilla \
scripts/hypotheses/H01/run_h01_models.R

Rscript --vanilla scripts/hypotheses/H01/build_h01_reporting_inputs.R

Rscript --vanilla tests/hypotheses/H01/test_h01_contract.R
Rscript --vanilla tests/hypotheses/H01/test_h01_modeling.R
Rscript --vanilla tests/hypotheses/H01/test_h01_response_gate_repairs.R
Rscript --vanilla tests/hypotheses/H01/test_h01_response_family_candidates.R
Rscript --vanilla tests/hypotheses/H01/test_h01_fit_outputs.R
Rscript --vanilla tests/hypotheses/H01/test_h01_bootstrap_outputs.R
Rscript --vanilla tests/hypotheses/H01/test_h01_reporting_inputs.R

quarto render notebooks/hypotheses/H01.qmd --profile nathealth --no-cache
```

At that stage, all seven H01 test scripts passed. The normal project render was blocked before
R execution by the existing shared `.quarto/project-cache`. To preserve worker
scope, that cache was not changed. The final render instead used an isolated
temporary mirror containing byte-for-byte copies of the shared Quarto profile
and configuration, executed the original H01 source against the original
audited artifacts, and copied only the resulting H01 HTML to the declared
Nature Health build path. Structural verification found 10 semantic gt tables,
7 figures with alt text, no cell-output errors, and all referenced local style
assets present. Visual inspection confirmed the Nature Health sidebar,
Bootstrap styling, Table 6 production labels, and pilot-versus-production
execution table.

### Historical Stage 2 hashes (superseded)

| Item | SHA-256 |
|---|---|
| Main model-data RDS | `018b9a50c007a850ba21d026cc7a9fd7d6906322993c98785b3dccb8f19b7475` |
| Main model-data manifest | `ea9d47f624a8777f8416447612bfcc2309cf2bac40fdf4fd5021c8767806dfbf` |
| Manuscript-prepared RDS | `c5ea147312735ccaa46ffaf642058115e8ed9d41376262e351a86b84a689e98a` |
| Manuscript-prepared manifest | `cb47b3678146604aadca875a96f79909e2d73355162683ff0603f038f3b31a25` |
| `renv.lock` | `3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350` |
| Production wrapper | `1a4840b14e716f99b6cbfce9312c36e69ebff2c018272b527a7998bc11fc5b8b` |
| Production provenance | `8a447a4fac76def658c10eb34ab8c1890806b8d8739c7f7d45bf5b743a9d1550` |
| Production runtime | `af906c4fa20ddebbe950cc66989274c6fbb18966287a70485154e25d034ec5a7` |
| Production artifact manifest | `55af5644f35c8e81eaed7bb3b4ec7486ce070c6e1012181afe1a5d5a985431ea` |
| Aggregate bootstrap audit | `dc229b82c5a27747c477c00aa7f8452d94e2e97905d1a9d54960b875a6347ac1` |
| Aggregate bootstrap failures | `3ef9b2addf8886a661f76574dfa949610f8a0e2ce8d8e45972d676ca956cc464` |
| Aggregate bootstrap summaries | `2931a04ed49fb361677fae344ce5ca528f10a8b839ecbacf7bc6bfe40c19bf2e` |
| Model-results manifest | `19aacb9604e052cbdd2d60ee6689239faf520673ca0f6b10aaf84a5492ef73ae` |
| Reporting manifest | `03f9f8eb728c43392c099e3a243d43da59f0319b1edd5ef97f0b90f17962675e` |
| Reporting provenance | `fe497366777c72a8b9a62225928ea5b20ea62b984dd7097c583004f93247f675` |
| Figure S10 PNG | `78f8e3d1ac7815c5c5ff1857da09a5733d1d3346708f6771be3e678e21644ff2` |
| Figure S10 SVG | `dca75a104718abb8d65b2be7b894a5b461528f8d5f6cefa5d90c1154d180e2ba` |
| Figure S10 observed source | `5d17eaf6ee3c1ecceca38a5d57153d1f38f0374efcf85218450990063569997f` |
| Figure S10 theoretical source | `073fa2fdae1e4a97c76409d2fc62136dddce0f4c16359b21d855cf7bf0b36f4a` |
| H01 reporting builder | `ec1b7d3e6947ad7d15661b6bb94fc24e99ad71981248a1a152f522dc981d9446` |
| H01 QMD | `af6a50df9d8f384f7a07053bdb543bd9c475f8dc13736ba3cb432f693b6628b3` |
| H01 HTML | `4daa424552ce83cd0a5879cae4ced62d6ca75c4703bc0a1b3be2806ff332c10e` |

The H01 QMD, HTML, tests, and this handoff are inventoried after finalization in
`artifacts/12_manifests/H01_worker_artifacts.csv`; its hash is reported in the
final worker completion message. Embedding that manifest hash here would
invalidate the handoff hash that the same manifest records.

### Historical Stage 2 proposed coordinator ledger updates (superseded)

| Ledger class | Proposed entry |
|---|---|
| Finding | The common response-family assessment changed only calendar-day cumulative time below 10 lx melEDI before sleep to Gaussian identity; no common candidate improved the retained families for darkest-10-hour mean or time below 1 lx melEDI during sleep. |
| Finding | The completed H01 package contains 128 passing production-bootstrap targets with 1,000 retained successful joint refits each; the eight changed targets completed with four replaced failed attempts and all 120 preserved draw hashes unchanged. |
| Finding | Primary 17-test BH support is 8 site, 12 photoperiod, 6 latitude, and 8 site-versus-latitude adequacy metrics. |
| Decision | Close the H01 response-family and production-bootstrap major-change gates; retain disclosed WARN_REVIEW diagnostics without silently changing families. |
| Deviation | The final H01 render used an isolated copy of shared Quarto configuration because the shared scratch cache blocked before R execution; shared configuration and cache were not modified. |
| Change log | Added the approved eight-target production wrapper, per-target checkpoints, full 128-target validation, production reporting table, and final manifests; after author reporting-stage acceptance, restored the submitted Figure S10 visual grammar using the audited 816-day source without changing inference. |
| Result comparison | Relative to V0, supported primary metrics are 8 versus 7 for site, 12 versus 11 for photoperiod, and 6 versus 5 for latitude; no previously supported metric is lost. |
| Claim provenance | Revise the broad H01 claim to include site and latitude support for time above 250 lx melEDI during wake and photoperiod support for L10 midpoint; preserve near eye as primary and chest as complementary. |
| Sensitivity | Classify the battery as qualitatively sensitive at the individual metric-family support level while retaining the broad site/photoperiod pattern. |

### Remaining non-gating items

- The coordinator must review and apply, reject, or amend the proposed central
  ledger entries; this worker did not edit central ledgers.
- The author-requested future Table 6 display revision remains recorded: grey
  unsupported term-specific part-R² cells and compute the reader-facing grand
  mean only among BH-supported metrics, with supported/unsupported counts.
  This is a display-only iteration and must never sum overlapping part-R²
  contributions.
- Diagnostic WARN_REVIEW rows remain available for review in Table 4 and
  `H01_model_diagnostics.csv`; they are not a reopened family gate.

## Historical audit trail retained for provenance

The dated sections below preserve earlier stops and superseded proposals. Any
statement below that a response-family gate is open, results are withheld, or
production is incomplete is superseded by the authoritative 2026-08-01
section above. The final Table 6 display note remains a pending presentation
iteration as restated above.

## Historical executive disposition

`H01-005` and `H01-006` remain author-approved. The jointly pinned main and
manuscript-prepared manifests match the prefit checkpoint, and the approved
calendar-day cumulative pre-sleep construct and strict-after-16:00 L10
conversion pass their amended gates.

The unchanged 17-response implementation was fitted across all eight declared
runs. The production bootstrap then completed with 128 cached draw files and
1,000 retained successful joint refits per estimable target. Independent R
4.6.1 validation found 128 passing bootstrap-audit rows, 1,272 complete 95%
interval rows, eight explicitly non-estimable participant-share rows, and no
reopened construct or clock-conversion gate. The completed model-results
manifest has SHA-256
`086e95b50b97304396302b7093711cc1490ee498a5e4aa83a09ac7264a896d3e`.

Required response-family review nevertheless crossed the predeclared stop
condition. The Tweedie model for time below 1 lx melEDI during sleep is
`WARN_STRONG_TWEEDIE_MISFIT` in all eight runs. In both all-available near-eye
data scenarios, simulations essentially never reproduce the observed zeros;
DHARMa uniformity and zero-mass checks fail, and the main model predicts 187
durations beyond that day's sleep-window support. A common family replacement
or explicit non-estimable disposition therefore requires author approval.

The worker opened
`audit/hypotheses/H01/H01_postbootstrap_response_family_gate.md` and stopped
before replacing a family or releasing inferential results. The same gate asks
for explicit disposition of the strong pre-sleep Tweedie warning in the main
near-eye analysis and the strong shifted-log Gaussian warnings for L10 mean
melEDI in six of eight runs. No shared preparation, central ledger, Quarto
configuration, or manuscript file was changed.

## Historical blocking evidence and preserved computation (superseded)

| Item | Verified disposition |
|---|---|
| Production target files | 128 of 128 present; each has 1,000 distinct retained joint refits |
| Successful refits | Minimum 1,491 of 1,500 attempts; 36 failed attempts across 24 targets and 25 warning attempts across 21 targets |
| Bootstrap intervals | 1,272 passing 95% interval rows; eight participant-associated-share rows explicitly non-estimable for participant-level IS/IV |
| Major construct/timing gates | None reopened; calendar-day cumulative pre-sleep and strict-after-16:00 L10 checks pass |
| Response-family gate | Open for time below 1 lx melEDI during sleep; author disposition also required for pre-sleep darkness and L10 mean melEDI warnings |
| Multiplicity | Four 17-row families retained but all inferential adjusted values withheld while the family gate is open |
| Saved computation | Unaffected bootstrap draws remain reusable; changed metrics alone require policy-compliant pilot and production refits after approval |

Exact gate evidence, samples, diagnostics, bootstrap counts, hashes, decision
options, claim consequences, and proposed ledger rows are self-contained in
`audit/hypotheses/H01/H01_postbootstrap_response_family_gate.md` and its three
CSV companions. No submitted-versus-repaired numerical conclusion or
sensitivity stability class is released while the gate is open.

## Coordinator resolution recorded 2026-07-31

The author resolved both checks in `audit/decisions/h01_gate_resolution.md`:

1. Retain the calendar-day cumulative pre-sleep duration. Do not cap valid
   values at three or six hours; use strictly above six hours only as an audit
   warning.
2. Convert the primary L10 midpoint by subtracting 24 hours only from clock
   times strictly later than 16:00. Retain the noon conversion as a same-row,
   same-model sensitivity.

The response families are unchanged. The main and manuscript-prepared data,
near-eye and chest measurements, and all-available and paired/common-sample
analyses must use the same implementation. Every numerical count, fit, and
diagnostic below this addendum describes the superseded diagnostic run and
must not be reported as a current H01 result.

Preparation 04 and Preparation 06 were rebuilt after the approved flat-zero
day exclusion. The main and manuscript-prepared H01 manifests reproduced
byte-for-byte in repeated builds and were repinned together. Gate A and Gate B
then passed their amended contracts in both datasets and placements.

## Pinned inputs and comparator identities

| Input | SHA-256 |
|---|---|
| Main H01 model data, `artifacts/06_model_data/H01.rds` | `018b9a50c007a850ba21d026cc7a9fd7d6906322993c98785b3dccb8f19b7475` |
| Main H01 manifest | `ea9d47f624a8777f8416447612bfcc2309cf2bac40fdf4fd5021c8767806dfbf` |
| Manuscript-prepared H01 model data | `c5ea147312735ccaa46ffaf642058115e8ed9d41376262e351a86b84a689e98a` |
| Manuscript-prepared H01 manifest | `cb47b3678146604aadca875a96f79909e2d73355162683ff0603f038f3b31a25` |
| State-interval manifest | `216392d001ac92a3f7313200bae0354b21315a70d7017309d022fb4d1fc6903a` |
| Approved implementation contract | `e07db16818e565aff40fa6b9f79f34a31eb943d6c393343ca96471b795bacbed` |
| Approved shared implementation | `c7d66825c359066ec6dce1a623408d532c4686fd0b77bfe1da5e392fcc7f5516` |
| Submitted near-eye result workspace | `d274865818cc4a0364dae9a444b9be44be02424daa8ad74b9452840f3115b3dc` |
| Submitted chest result workspace | `01f91db675d1aa6ae96b6aa7bbc45b2f86445e851a37020d1fe5335d802de9b5` |
| Submitted `RQ1.qmd` | `ecf2f7f7af569b4d2b3f8404e39690a1924173a02a97aa4db65233950b6f6643` |
| Submitted `RQ1_chest.qmd` | `77ee597de0fd326587a336b38d1a820f312156f8cd599aab26a34abd75f8420d` |
| Submitted fitting helper | `6cda57af0bea054b789619d110d1ae770829d919f1e1d301278008f688d68999` |
| Submitted H1 helper | `b51ae0a3c2e077761d3aa5e779c8b11eaaae74048ec2314028f10bafe5cd1d3e` |
| Submitted summary helper | `78fc0d4b8beac26a5dd9d3498c442150e7a887efce7124f22bc716701a08ebdb` |

Both H01 objects declare model implementation `new_h01_h11` and the same
approved implementation fingerprints.

## Implemented H01 code

The H01-only implementation consists of:

- `scripts/hypotheses/H01/h01_contract.R`: ordered 17-metric registry, four
  fixed 17-test families, scenario registry, pinned identities, formulas, and
  deterministic seeds;
- `scripts/hypotheses/H01/h01_modeling.R`: common transformations and model
  frames, ML comparisons, REML Gaussian estimation fits, Tweedie log models,
  equal-site `emmeans`, exact samples, diagnostics, influence checks,
  random-site descriptions, part-\(R^2\), and joint parametric bootstrap
  machinery;
- `scripts/hypotheses/H01/run_h01_models.R`: one driver for main and
  manuscript-prepared data, near eye and chest, all-available and paired
  samples, plus a hard stop before bootstrapping any run with an open major
  gate;
- `scripts/hypotheses/H01/audit_h01_major_gates.R`: outcome-support audit for
  the two failed checks;
- `scripts/hypotheses/H01/build_h01_worker_manifest.R`: exhaustive H01 output
  checksums; and
- base-R contract and modelling tests under `tests/hypotheses/H01/`.

The primary and manuscript-prepared scenarios call the identical response
transformations, formulas, fit functions, diagnostic functions, and output
functions. No package was installed or updated.

## Historical fit-stage verification (superseded by current gate addendum)

The full fit stage was rerun after the joint repinning. It produced eight
analysis runs and 136 metric rows. Of these, 128 fitted and eight
paired/common-sample participant-level IS/IV rows remained explicitly
non-estimable, as predeclared.

All 32 multiplicity vectors contain 17 planned rows. The 16 all-available
vectors contain 17 observed tests, and the 16 paired/common-sample vectors
contain 15 observed tests plus the two explicit IS/IV non-estimable rows.
Independent R verification reproduced every adjusted value using one
vector-wide BH calculation with `n = 17`.

Fit-stage diagnostics comprise 28 pass, 100 warning/review, eight
non-estimable, and no major-gate failure. The warnings remain open for
model-by-model review. All primary and noon-sensitivity term effects, site
estimates, and site deviations have 95% confidence intervals. The primary
16:00 and noon-conversion L10 analyses use identical participants,
participant-days, and observations in every run.

The fit-stage-only result manifest was
`535f033ebb68eaa9f87cd909713330b767c5287db28cb4d69c8416ec7f08db30`.
It is superseded by the completed production manifest reported above. Final
result interpretation remains withheld because the post-bootstrap
response-family gate is open.

Consequential package versions were LightLogR 0.10.3, melidosData 1.0.6,
lme4 2.0.1, glmmTMB 1.1.14, emmeans 2.0.3, performance 0.17.1,
insight 1.5.2, DHARMa 0.5.0, parameters 0.29.2, datawizard 1.3.1,
effectsize 1.0.2, broom.mixed 0.2.9.7, readr 2.2.0, dplyr 1.2.1,
tidyr 1.3.2, purrr 1.2.2, ggplot2 4.0.3, gt 1.3.0, and knitr 1.51.
`partR2` and `testthat` were not installed and were not added.

## Commands

All scientific and reporting work used R 4.6.1 and the activated project
library. The coordinator-owned ENV-001 reconciliation reports the environment
synchronized; no package was installed or updated. The current Stage 3
reporting revision used only stored accepted results:

```sh
env R_PROFILE_USER=/dev/null \
  R_LIBS_USER=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  RENV_PATHS_SANDBOX=/private/tmp/H01-renv-sandbox-R4.6.1 \
  NATHEALTH_PROJECT_ROOT=<project> \
  Rscript --vanilla \
  scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R

env R_PROFILE_USER=/dev/null \
  R_LIBS_USER=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  RENV_PATHS_SANDBOX=/private/tmp/H01-renv-sandbox-R4.6.1 \
  NATHEALTH_PROJECT_ROOT=<project> \
  quarto render notebooks/hypotheses/H01.qmd --profile nathealth

env R_PROFILE_USER=/dev/null \
  R_LIBS_USER=<project>/renv/library/macos/R-4.6/aarch64-apple-darwin23 \
  RENV_PATHS_SANDBOX=/private/tmp/H01-renv-sandbox-R4.6.1 \
  NATHEALTH_PROJECT_ROOT=<project> \
  Rscript --vanilla tests/hypotheses/H01/test_h01_reporting_inputs.R
```

The completed production command was:

```sh
RENV_CONFIG_SANDBOX_ENABLED=FALSE OMP_NUM_THREADS=1 \
OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 \
H01_STAGE=bootstrap H01_BOOTSTRAP_REFITS=1000 \
H01_BOOTSTRAP_CORES=4 \
Rscript scripts/hypotheses/H01/run_h01_models.R
```

The completed cached outputs were independently verified with:

```sh
RENV_CONFIG_SANDBOX_ENABLED=FALSE OMP_NUM_THREADS=1 \
NATHEALTH_PROJECT_ROOT=<project> \
Rscript tests/hypotheses/H01/test_h01_bootstrap_outputs.R
```

The post-bootstrap gate evidence was generated with:

```sh
RENV_CONFIG_SANDBOX_ENABLED=FALSE OMP_NUM_THREADS=1 \
NATHEALTH_PROJECT_ROOT=<project> \
Rscript \
scripts/hypotheses/H01/audit_h01_postbootstrap_response_families.R
```

The following commands document the earlier fit and gate-repair stages:

```sh
RENV_CONFIG_SANDBOX_ENABLED=FALSE OMP_NUM_THREADS=1 \
NATHEALTH_PROJECT_ROOT=<project> \
Rscript tests/hypotheses/H01/test_h01_contract.R

RENV_CONFIG_SANDBOX_ENABLED=FALSE OMP_NUM_THREADS=1 \
NATHEALTH_PROJECT_ROOT=<project> \
Rscript tests/hypotheses/H01/test_h01_modeling.R

RENV_CONFIG_SANDBOX_ENABLED=FALSE OMP_NUM_THREADS=1 \
OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 \
NATHEALTH_PROJECT_ROOT=<project> H01_STAGE=fit \
H01_SAVE_PLOTS=true \
Rscript scripts/hypotheses/H01/run_h01_models.R

RENV_CONFIG_SANDBOX_ENABLED=FALSE OMP_NUM_THREADS=1 \
NATHEALTH_PROJECT_ROOT=<project> \
Rscript scripts/hypotheses/H01/audit_h01_major_gates.R

RENV_CONFIG_SANDBOX_ENABLED=FALSE OMP_NUM_THREADS=1 \
NATHEALTH_PROJECT_ROOT=<project> H01_STAGE=bootstrap \
H01_BOOTSTRAP_REFITS=1000 \
H01_RUN_FILTER='^main__glasses__all_available$' \
Rscript scripts/hypotheses/H01/run_h01_models.R

RENV_CONFIG_SANDBOX_ENABLED=FALSE \
NATHEALTH_PROJECT_ROOT=<project> \
quarto render notebooks/hypotheses/H01.qmd --profile nathealth
```

The bootstrap command stopped before its first replicate and identified
`duration_below_10_pre_sleep` and `l10_midpoint` as the open-gate metrics.
The rendered command targeted only H01.

## Superseded diagnostic-fit samples

These are diagnostic fit frames, not released result samples. Main-data
support hours are metric derivation support rather than model observations.
The manuscript-prepared artifacts do not retain exact support minutes, so
support hours are unavailable for every sensitivity row.

| Metric | Main participants | Main participant-days | Main observations | Main support h | Sensitivity participants | Sensitivity participant-days | Sensitivity observations |
|---|---:|---:|---:|---:|---:|---:|---:|
| Interdaily stability | 141 | 811 | 141 | 18,671.02 | 141 | 811 | 141 |
| Intradaily variability | 141 | 811 | 141 | 18,671.02 | 141 | 811 | 141 |
| Daily geometric mean melEDI | 141 | 811 | 811 | 18,671.02 | 141 | 811 | 811 |
| M10 mean melEDI | 141 | 811 | 811 | unavailable | 141 | 811 | 811 |
| L10 mean melEDI | 141 | 811 | 811 | unavailable | 141 | 811 | 811 |
| Time above 1,000 lx melEDI | 141 | 811 | 811 | 18,671.02 | 141 | 811 | 811 |
| Time above 250 lx melEDI during wake | 141 | 714 | 714 | 8,883.15 | 140 | 755 | 755 |
| Time below 10 lx melEDI before sleep | 139 | 645 | 645 | 1,895.93 | 141 | 780 | 780 |
| Time below 1 lx melEDI in the sleep environment | 141 | 771 | 771 | 6,218.17 | 141 | 790 | 790 |
| Longest period above 250 lx melEDI | 141 | 811 | 811 | 18,671.02 | 141 | 811 | 811 |
| M10 midpoint | 141 | 809 | 809 | unavailable | 141 | 811 | 811 |
| L10 midpoint | 141 | 809 | 809 | unavailable | 141 | 811 | 811 |
| Mean timing above 250 lx melEDI | 141 | 714 | 714 | 16,541.78 | 141 | 778 | 778 |
| First timing above 250 lx melEDI | 140 | 717 | 717 | 16,556.38 | 141 | 778 | 778 |
| Last timing above 250 lx melEDI | 141 | 679 | 679 | 15,766.48 | 141 | 778 | 778 |
| Time-sensitive corrected melEDI dose | 141 | 736 | 736 | 17,077.45 | 141 | 811 | 811 |
| MDER | 141 | 733 | 733 | 17,007.85 | 140 | 725 | 725 |

Every row uses nine near-eye sites. Exact all-run and by-site samples,
including complementary chest and paired/common-sample frames, are retained
in `artifacts/09_tables/H01/H01_exact_samples.csv` and
`artifacts/09_tables/H01/H01_exact_samples_by_site.csv`. Paired participant
IS and IV remain non-estimable as predeclared because paired common-day
dynamics were not prepared.

## Superseded major-gate evidence

### Pre-sleep duration

| Scenario | Placement | Participants | Participant-days/observations | Sites | Days >3 h | Maximum |
|---|---|---:|---:|---:|---:|---:|
| Main | Near eye | 139 | 645 | 9 | 60 (9.30%) | 5.90 h |
| Main | Chest | 153 | 736 | 8 | 67 (9.10%) | 5.97 h |
| Manuscript-prepared | Near eye | 141 | 780 | 9 | 62 (7.95%) | 5.90 h |
| Manuscript-prepared | Chest | 154 | 867 | 8 | 69 (7.96%) | 5.97 h |

Main-data expected support exceeds three hours on 142 near-eye and 143 chest
days, up to six hours. Each affected placement-specific day contains exactly
two diary pre-sleep intervals; projected source-interval minutes exactly
match the metric denominator on all 285 rows. A shifted-log Gaussian family
would not repair this estimand mismatch.

### L10 midpoint

| Scenario | Placement | Participants | Observations | Sites | Declared transformed span | Minimum circular covering arc |
|---|---|---:|---:|---:|---:|---:|
| Main | Near eye | 141 | 809 | 9 | 20.30 h | 18.72 h |
| Main | Chest | 154 | 894 | 8 | 17.88 h | 17.88 h |
| Manuscript-prepared | Near eye | 141 | 811 | 9 | 23.87 h | 18.88 h |
| Manuscript-prepared | Chest | 154 | 897 | 8 | 20.60 h | 20.60 h |

Because every minimum circular covering arc exceeds 12 hours, moving the
linear cut cannot satisfy the approved continuous-range assumption. The
linear Gaussian point fits are invalid diagnostic probes.

## Superseded diagnostic-run status

All 68 model-level comparisons for each all-available run fitted on identical
rows and returned a comparison status of `PASS`. The final all-available
near-eye site fits converged, had positive-definite Hessians, and were not
singular for all 17 metrics in both data scenarios.

Diagnostic classifications were:

| Run | Pass | Warn/review | Fail major gate |
|---|---:|---:|---:|
| Main near eye, all available | 4 | 11 | 2 |
| Manuscript-prepared near eye, all available | 6 | 9 | 2 |
| Main chest, all available | 4 | 11 | 2 |
| Manuscript-prepared chest, all available | 3 | 12 | 2 |

The two failures in every row are the pre-sleep ceiling and L10
linearization. Other warnings include Gaussian residual-shape flags in large
samples and DHARMa distribution warnings for selected Tweedie responses.
They require review if H01 resumes but did not authorize a family switch.

The separately labelled random-site descriptions were non-estimable for
participant-level IS/IV and singular for selected daily outcomes, including
main near-eye longest period and dose. They are descriptive only and do not
alter the fixed-site or latitude comparison. Participant influence,
leave-one-site-out latitude, equal-site versus observed-weight
marginalization, exactly identified longest-period, registered-scope, paired
placement, and chest diagnostic artifacts were created, but no inferential
stability conclusion is released while the gate is open.

## Superseded diagnostic-run inferential status

No estimate, 95% confidence interval, raw p-value, adjusted p-value, site
deviation, marginal or conditional \(R^2\), participant-associated share, or
part-\(R^2\) is reportable from this checkpoint.

Diagnostic point fits and point \(R^2\) calculations are stored for
troubleshooting, but the required ≥1,000 successful joint bootstrap refits
were deliberately not run. The only bootstrap execution was an isolated
temporary smoke test of five replicates for one Gaussian and one Tweedie
metric; it is not a scientific output and is not in the project artifacts.

All four declared families retain 17 planned rows. The fit-stage table now
sets `family_status = INVALID_OPEN_MAJOR_GATE`, leaves every adjusted p-value
missing, and supports zero inferential site follow-ups. It does not shorten a
family or treat either failed metric as null. Registered-scope adjusted
p-values are likewise withheld.

## Sensitivity classification and submitted comparison

The sensitivity-battery classification is `invalid/gated`. It is not
`stable`, `quantitatively sensitive`, `qualitatively sensitive`, or
`inconclusive`, because the primary response package is invalid before a
common replacement/estimand decision.

The same-model manuscript-prepared, paired/common-sample, and complementary
chest fits confirmed that both gate failures persist. Their effects and
family results were not compared. Submitted workspaces and code were hashed
and inspected for provenance, but submitted-versus-repaired numerical result
comparison stopped with the gate. No direction, significance, magnitude, or
claim difference is asserted.

## Claim implications

- Existing submitted H01 claims remain unverified, not confirmed or
  contradicted.
- No latitude, photoperiod, site, placement, or explained-variation claim may
  be updated from the diagnostic fits.
- The pre-sleep construct is now calendar-day cumulative, but its rebuilt
  estimate and uncertainty remain pending.
- The L10 midpoint now has a primary 16:00 conversion and a noon sensitivity,
  but the rebuilt comparison remains pending.
- No manuscript prose was edited.

## Historical required resumed work (completed or superseded)

1. Obtain the author disposition for the common response family or
   non-estimable status of time below 1 lx melEDI during sleep.
2. Obtain the explicit author disposition for the pre-sleep Tweedie and L10
   mean shifted-log Gaussian warnings documented in the new gate.
3. If a family changes, apply the identical new family across main and
   manuscript-prepared data, near eye and chest, and all-available and paired
   runs; repeat required checks without changing the response construct.
4. Preserve all unaffected production draws. Before any changed target is
   rerun at production scale, complete the COMPUTE-001 pilot, preview, and
   approval sequence.
5. Recompute all four complete 17-row BH families, hierarchical site
   follow-up eligibility, comparisons, sensitivity classifications,
   publication tables/figures, H01-only render, handoff, and manifests.

## Historical post-bootstrap gate ledger proposals (superseded)

| Ledger class | Proposed entry |
|---|---|
| Finding | The approved Tweedie model for time below 1 lx melEDI during sleep fails distributional checks in both main and manuscript-prepared near-eye analyses and exceeds daily sleep support in main-data predictions. |
| Finding | The approved pre-sleep Tweedie model has a strong residual warning in the main near-eye analysis despite passing the construct, audit-threshold, and physical-bound checks. |
| Finding | The shifted-log Gaussian model for L10 mean melEDI has strong heteroscedasticity warnings in six of eight declared runs. |
| Decision | Open a post-bootstrap H01 response-family major-change gate; require a common approved replacement or non-estimable disposition before release. |
| Deviation | Preserve the completed production bootstrap but withhold all four BH families, site follow-ups, sensitivity classes, result comparison, and claim changes. |
| Change log | Added the R 4.6.1 post-bootstrap response-family audit, 24-row evidence, summary, provenance, and major-gate document without fitting a replacement. |
| Result comparison | Status `invalid/gated`; current submitted-versus-repaired numerical conclusions are not released. |
| Claim provenance | No rebuilt H01 inferential claim is authorized; submitted claims remain unverified. |

## Superseded worker proposals

These proposals document the first diagnostic stop. The coordinator has since
recorded the approved decisions as `H01-007` and `H01-008`; the rows below
must not be treated as open decisions.

| Ledger class | Proposed entry |
|---|---|
| Finding | Required H01 pre-sleep ceiling fails in both data scenarios and placements because a local date can contain two diary pre-sleep intervals. |
| Finding | Required H01 L10-midpoint linearization fails in all scenario/placement frames; no clock cut yields a covering arc below 12 h. |
| Decision | Open a post-fit major gate for one common pre-sleep estimand/response disposition. |
| Decision | Open a post-fit major gate for one common L10-midpoint circular/restriction/exclusion disposition. |
| Deviation | Production bootstrap, final multiplicity, site follow-up, comparison, and claim review halted as required; no family replacement attempted. |
| Change log | Added H01-only shared model implementation, tests, diagnostics, hard bootstrap gate, gate audit, H01 status page, and exhaustive manifests. |
| Result comparison | Status `invalid/gated`; submitted-versus-main and main-versus-manuscript-prepared effect comparisons pending gate closure. |
| Claim provenance | No rebuilt H01 claim authorized; all submitted H01 claims remain pending verification. |
| Shared-change request | Review analytical-day ownership of the pre-sleep metric; affected hypotheses H01/H05/H07/H08/H10. |

## Historical pre-Stage-3 output inventory and hashes (superseded)

`artifacts/12_manifests/H01_model_results_artifacts.csv` contains the hash of
every diagnostic model, exact frame, table, diagnostic plot, plot source-data
file, and H01 analysis script. Its completed-production SHA-256 is
`086e95b50b97304396302b7093711cc1490ee498a5e4aa83a09ac7264a896d3e`.
`artifacts/12_manifests/H01_worker_artifacts.csv` extends that inventory to
tests, H01 Quarto source and rendered HTML, gate evidence, gate documents,
shared-change request, and this handoff.

The existing H01 HTML predates the post-bootstrap response-family gate and is
not a released result. No new render or publication table was produced after
the stop condition. The coordinating task should review the proposed ledger
entries and obtain the author decisions recorded in
`audit/hypotheses/H01/H01_postbootstrap_response_family_gate.md` before
dispatching replacement-model work.

## Reporting-iteration note: Table 6 term-specific part-R² display

Author note received 2026-08-01 for the next H01 reporting iteration. The
submitted V0 Table S3 displayed site, photoperiod, and latitude part-R² only
when the corresponding term was supported. The audited table should preserve
all estimates for transparency but visually de-emphasize unsupported cells
rather than replacing them with missing values.

Implementation rule for the next Table 6 revision:

- determine support separately from the site, photoperiod, and latitude
  17-test vector-wide BH families (`q < 0.05`);
- grey the estimate and 95% confidence interval for an unsupported
  term-specific cell, while retaining its numerical value;
- do not grey conditional R², marginal R², participant-associated share, or
  residual/unrepresented share, because those columns are not term-level
  significance displays;
- for each term-specific grand-average cell, report the mean among supported
  metrics and append `(n supported / n unsupported)`;
- retain the all-metric descriptive mean in the audited reporting object for
  reproducibility, even if it is not the reader-facing grand average; and
- never sum site, photoperiod, and latitude part-R² contributions. Their
  information can overlap, and the requested grand average is a column-wise
  mean conditional on BH support, not an additive decomposition.

Reader-facing wording should call this quantity “mean part-R² among
BH-supported metrics” because conditioning on significance makes it a
selected descriptive summary rather than an unconditional average effect.
