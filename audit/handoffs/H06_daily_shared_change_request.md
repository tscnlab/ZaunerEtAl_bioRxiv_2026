# H06 daily shared change requests and upstream qualifications

- Date: 2026-08-12
- Owner requested: coordinating preparation/normalization task
- H06_daily status: **MDER/base/gap and METRIC-011 deliveries received and
  implemented in bounded task-owned amendments; no shared file changed**

## Upstream change acknowledged

The author has reopened the MDER definition and rejected use of the current
ratio-of-integrals artifact for H06_daily inference or reporting. The
coordinator is replacing it with the arithmetic mean of viable positive finite
one-minute melEDI/illuminance ratios, excluding a pair when either channel is
zero or non-finite and requiring viable ratios for at least 50% of expected
day minutes.

## Requested coordinator deliverables

Please provide:

1. the replacement shared metric/model-data manifest and immutable artifact
   hashes;
2. the replacement field/metric identifier, reader-facing name, units, and
   exact expected-minute denominator;
3. explicit confirmation of placement handling, missing-value coding, finite
   and positivity checks, and that exactly 50% support is retained;
4. updated metric-level and model-data sample identities needed to reconstruct
   near-eye, chest, paired/common, and declared sensitivity frames; and
5. targeted repinning instructions for H06_daily-owned contracts and input
   manifests, including whether the superseded ratio-of-integrals field will
   be removed or retained under a clearly deprecated identifier.

H06_daily will not change shared preparation code, regenerate the metric, or
repin itself before those instructions arrive. Once supplied, the worker will
perform a fresh MDER-only audit before fitting and will not transfer the prior
candidate samples, response-family decision, estimates, multiplicity result,
or conclusions.

## 2026-08-11 delivery and release

The coordinator supplied all requested controlling identities and targeted
repinning instructions. H06_daily verified 13 of 13 direct input hashes,
reconstructed the replacement metric contract without recalculating the
metric, and completed the bounded MDER-only analysis in task-owned paths. The
original hold is released under
`audit/hypotheses/H06_daily/H06_daily_mder_metric010_transition.md`.

The current primary values and support match the independent audit. No shared
preparation change is requested for the primary METRIC-010 route.

At that gate, one upstream qualification remained: the frozen
gap-timing-unaware chest source
contains one exact zero among 1,454 finite near-eye/chest comparator values,
despite the shared positive-viable-ratio label. H06_daily retained that value
unchanged on the identity scale, did not repair or log-transform it, and
labelled the comparator accordingly. The coordinator may clarify this shared
comparator provenance in a later bounded preparation update; it does not block
the primary MDER result.

## 2026-08-11 corrected gap delivery and resolution

The coordinator subsequently supplied the fully rebuilt current primary and
gap artifacts under the approved momentary-ratio rule, including the current
base/gap manifests, independent H01 gap manifest, support object, and repair
evidence. H06_daily pinned and verified all 16 direct inputs. The corrected gap
availability is 687/811 days from 137 participants near eye and 723/897 days
from 152 participants at the chest. There are no finite nonpositive retained
values; the former THUAS chest zero is now missing with failure reason
`no_viable_momentary_ratio`.

This delivery closes the one-zero comparator qualification and the MDER-specific
base/gap drift request above. H06_daily refreshed only 18 gap frames and six
primary--gap common-sample frames. Twelve primary all-available or
placement-paired frames and every unaffected primary production result passed
frozen-content preservation checks. No shared preparation file was changed by
H06_daily.

The author approved the corrected gap result at **H06-D-G2-MDER-GAP** on
2026-08-11. The L10 numerical-zero implementation request below remains open
and scientifically separate.

## 2026-08-11 temporal-pilot provenance qualification

During the corrected, MDER-independent temporal report render, the frozen
H06_daily pilot input manifest detected exactly one upstream mismatch. The
shared `artifacts/12_manifests/metric_artifacts.csv` hash changed from
`6ec3185620d921e1f81b8464e850249613deb823988187d58794b3471303f4e8` to
`7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43`.
The current shared manifest carries the reopened arithmetic-mean one-minute
ratio definition, but no targeted H06_daily repinning instruction has yet been
received.

All other pinned temporal-pilot inputs still match, including the exact
30-minute model-data frame, temporal provenance, context diaries, H02 sources,
and author transition. The temporal report therefore records this as a
qualified upstream manifest change and continues only its MDER-independent
work. H06_daily has not altered or repinned the shared manifest and will not
resume MDER-specific analysis until the requested targeted instructions
arrive.

## 2026-08-11 L10 numerical zero-mass classification request

The approved bounded non-MDER daily AR repair pilot found that the frozen and
current near-eye L10 frames are analytically identical, but the exact-zero
split has a consequential numerical edge case. Among 784 work/free-day rows,
104 values are exactly zero and three additional values are strictly positive
but equal to `4.163336342344337e-17` lx. They occur for:

- KNUST_S001 on 2024-10-13;
- KNUST_S005 on 2024-11-08; and
- KNUST_S010 on 2024-12-14.

Under the approved exact comparison `L10 > 0`, these three rows enter the
positive-magnitude component and become -16.381 after `log10()` transformation.
They are the extreme lower tail of a component whose next-smallest value is
`2.806e-05` lx. The resulting Gaussian positive-magnitude model fails its
distributional gate. H06_daily has not thresholded, rounded, deleted, or
reclassified any value.

The author decided on 2026-08-11 that these values are numerical zeros,
plausibly introduced by averaging over the 10-hour window. The coordinating
preparation/metric owner should verify that provenance in R and implement a
shared, unit-aware numerical-zero rule tied to algorithmic precision rather
than to a fitted model or an arbitrary post hoc cutoff. Preserve the source
values and produce row-level evidence for every reclassification.

Please audit the same mechanism across placements, gap variants, metrics, and
hypotheses; rebuild every affected metric/model-data artifact; enumerate all
changed cells, samples, response-family decisions, multiplicity families, and
downstream reports; and provide current manifests plus targeted repinning
instructions. A reclassified zero remains in any zero-capable one-part model
and in the occurrence component of a two-part model. It is excluded only from
the strictly positive magnitude component by definition; the participant-day
must not be discarded merely to satisfy a positive-only family. This issue
blocks final L10 family selection but does not alter the completed MDER result.

### Coordinator interim implementation state

The coordinator confirmed the upstream asymmetry: an equivalent tiny negative
back-transform error was already clamped to zero, whereas a tiny positive
roundoff remnant was retained. The candidate shared repair uses a strict
provenance rule rather than a fitted-model threshold: a tiny positive value is
reset to zero only when it lies within the specified machine-precision
tolerance **and every contributing source minute is exactly zero**. Focused
tests pass for eight proven roundoff cells; genuinely low positive exposures
remain unchanged.

The canonical shared rebuild and final manifest sealing are still in progress.
The coordinator's current downstream inventory identifies H01, H05, H07, H08,
H09, H10, and H06_daily as potentially L10-dependent. H02, H03, H04, and the
approved hourly main-H06 analysis are scientifically unaffected. H06_daily
therefore retains its L10 hold: it will not read, refit, repin, adjust the L10
BH slot, or revise an L10 claim until the coordinator supplies the final shared
hashes and targeted repinning scope.

### 2026-08-12 METRIC-011 delivery and H06_daily resolution

The coordinator subsequently finalized, implemented, and independently
verified METRIC-011. The controlling decision SHA-256 is
`23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797`
and the evidence-manifest SHA-256 is
`a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb`.
Exactly eight primary L10 cells changed to exact zero (three near eye and five
chest); every non-L10 scientific value and every gap-timing-unaware L10
scientific value is unchanged.

H06_daily pinned the current metric, site/context, base, placement, and gap
identities; verified all 13 direct inputs; and completed only its authorized
L10 branch in task-owned paths. Exact zeros were retained in occurrence and
excluded only from strictly positive magnitude. The gap frames were exactly
invariant and were fitted only to complete the previously held branch because
no accepted production L10 components existed.

This closes the shared L10 numerical-zero implementation request. The bounded
downstream result is stopped at **H06-D-G2P-L10-METRIC011** because the
prespecified fixed-site occurrence components are separated and all primary
joint L10 slots are non-estimable. That downstream estimability result does
not request another shared preparation change. Any later change to the primary
occurrence model would require a separate author amendment, not a preparation
repair.

## 2026-08-11 post-pilot base-manifest drift qualification

The bounded repair pilot pinned and verified the controlling PREP06-BASE-002
base-model-data manifest SHA-256
`6cfbfb18a2f6b1e31613e3fba803c3fbf64eb63e37155ae4fffd437a213b3ad0`
at fit time. During the subsequent no-refit Quarto report render, the same
shared path had changed to
`b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09`.
The file timestamp was 2026-08-11 16:54:41 CEST.

The current direct near-eye participant-day input remains byte-identical at
SHA-256
`fb04a84f49a410f3474cc64ef97e91183db413197f5815f5dd83805a7d40b06e`,
and the current metric manifest remains
`7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43`.
The two fitted H06_daily repair frames are task-owned, hash-pinned, and were
already verified analytically identical to their frozen pre-rebuild frames.
No model was refitted after the broad manifest changed.

The current broad manifest records base input-bundle SHA-256
`168f25e18b6e494aa7a0272923041ad8249e25adb9ff3742d22e2f4cacf1bdf8`,
whereas PREP06-BASE-002 still identifies
`1161f46fb0c63e0b578a2f2435cd5c8a4ffd566a4ec910be87c8bc7fb54b58df`
as controlling. The preparation coordinator should reconcile these identities
and issue targeted downstream repinning instructions if the newer broad
manifest is now approved. H06_daily will display this one current-provenance
mismatch explicitly, will not rewrite its fit-time manifest, and will not fit
another model until the reconciliation is received.

The same post-gate check also found that two frozen gap-timing-unaware MDER
benchmark inputs changed at their shared paths after H06-D-G2-MDER approval:

- `artifacts/12_manifests/manuscript_prepared_data_artifacts.csv` changed from
  `97c8315afab1c50350754eecb00f69d4fe6923a6c005ecbc0d29a40b7b855a4e`
  to `4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935`;
  and
- `artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds`
  changed from
  `8fe2ea8968e902de214a319fa4d2ca57ce12c2d58b85b23a1c52dc6d91fb2f9f`
  to `7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1`.

These paths were written at 16:52 CEST, before the broad base manifest at
16:54 CEST. They do not change the frozen primary near-eye MDER source or the
already approved fit-time outputs, but they mean the approved
gap-timing-unaware comparison cannot be described as rerun against the current
shared comparator. H06_daily has not rerun or repinned it. Please include
these two paths in the same targeted reconciliation and state whether the
current comparator requires a later bounded refresh.

**Resolution:** the later corrected-gap delivery supplied those targeted
instructions and current identities. The MDER-specific base/gap request is
closed by the bounded refresh described above; this historical fit-time note is
retained only to explain why the refresh was necessary.

## 2026-08-12 H06-D-014 gap clock-unit construct failure

Status: **open; no repair or refit authorized; H06-D-G2A author/coordinator
decision required**.

The no-refit H01-aligned hard-gate replay exposed a task-local unit defect in
the frozen H06_daily gap-timing-unaware timing branch. This is not a change to
the shared prepared values. The pinned gap participant-day artifact supplies
the five clock outcomes in clock hours, as required by its audited contract.
The H06_daily adapter treated those hour values as clock minutes and applied
the registered minute-to-hour response transform a second time.

### Exact affected scope

The five affected outcomes are:

1. M10 midpoint (slot 9);
2. L10 midpoint (slot 10);
3. mean timing above 250 lx melEDI (slot 11);
4. first timing above 250 lx melEDI (slot 12); and
5. last timing above 250 lx melEDI (slot 13).

The frozen affected grid contains exactly 90 cells:

- gap-timing-unaware dataset only;
- near-eye and chest placements;
- all-available, paired/common, and dataset-common samples;
- work/free day, activity status, and previous-night sleep duration; and
- five outcomes x two placements x three sample roles x three predictors.

All 234 primary-dataset cells are unaffected, including near-eye, chest,
paired/common, and dataset-common branches. All 144 gap-timing-unaware cells
for the other eight non-L10 outcomes are also unaffected. These exact 378
unaffected cells remain frozen. L10 mean slot 3, MDER slot 15, the temporal
GAMM, pre-sleep no-nugget sensitivity, and hourly main H06 are outside the
defect.

The 90 invalid cells contribute five raw slots to each of the three gap
association families and the three gap site-heterogeneity families. Therefore
all six gap 15-slot BH families are contaminated. Even q-values for unaffected
gap outcomes cannot be interpreted until those families are rebuilt. No raw
p-value, rank, BH value, or BH decision has been changed under H06-D-014.

### Reproduced source and adapter evidence

R 4.6.1 verification established all of the following:

- primary source columns are explicitly named `*_clock_minute` and contain
  minute-scale values;
- the gap source values satisfy the audited clock-hour contract (including
  the declared signed L10 representation);
- the accepted H01 gap adapter calls
  `h01_clock_hour_to_minute(manuscript_prepared_value)` before its downstream
  minute-scale contract;
- H06_daily `h06d_nl_transform_response(..., "clock_hours")` divides its
  input by 60 without a dataset-specific normalization; and
- in every one of the 90 affected frozen cells, the stored model response
  extrema equal the gap source extrema divided by 60 exactly within the sealed
  `1e-10` audit tolerance.

The resulting values are clock hours divided by 60, not clock hours. Under
H06-D-014 this is `FAIL_MAJOR_GATE` with reason
`TIMING_CONSTRUCT_UNIT_DOUBLE_CONVERSION`. It is scientifically distinct from
the visual residual review: no cell received `FAIL_GROSS`; ordinary residual
departures remain `REVIEW_LIMITATION`.

### Relevant sealed identities

- H06-D-014 decision:
  `64be7a03f6982d175e4372d8488d84ed3e427a9bd38e1eddbc55f0ce1c49375e`.
- H06_daily source adapter:
  `scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_data.R`,
  SHA-256 `42893a9bd8b5ccdd38bb44ed22893e6b6d2e58e69d428ed161d38d05c31e86b1`.
- Audited H01 gap adapter:
  `scripts/pipeline/h01_manuscript_prepared_adapter.R`,
  SHA-256 `18abff5938b2b7253602347e02643135e72c730dc623c41c13505f3b195a6672`.
- Gap participant-day source:
  SHA-256 `7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1`.
- Primary near-eye source:
  SHA-256 `b469fa8f0a743de1cbb1075f78879b84ab602c74cc44fb97da45dee596681f42`.
- Primary chest source:
  SHA-256 `10aebeb5dabb53e8f3ee0747b62c31707da344e11b7068261c2ada2a0b7badc9`.
- Ten-row placement x metric unit audit:
  `artifacts/08_diagnostics/H06_daily/H06_daily_h01_timing_unit_contract_audit.csv`,
  SHA-256 `1490c1ebcb67d9fae288d9516124c619bc6a80c833f63847c568f416e4445465`.
- Six-family impact audit:
  `artifacts/08_diagnostics/H06_daily/H06_daily_h01_timing_unit_family_impact.csv`,
  SHA-256 `1053ae74617f523cd68dcd907b6108771bac6927ce2a5ac7c711d4cbfb742946`.
- 468-cell derived H01 classification:
  SHA-256 `a404a2652fa2b2c23b61c5a77953fdf93d5c9b6fb39e4ae84c1264f96197cd99`.
- 180-row derived claim table with frozen p/FDR fields:
  SHA-256 `4916a264d626f6fc77a33ae0d060b37ab7a31c222791b137e7a7cc90b8d5d1c9`.

The final H06-D-G2A manifest and focused-test identities will supersede this
intermediate list only for the newly created amendment files; all frozen input
identities above must remain unchanged.

### Prospective minimal repair execution contract

No repair is authorized by this request. If the author and coordinator choose
to retain the gap sensitivity, the smallest defensible later amendment is:

1. make a task-owned, dataset-explicit timing normalization that converts the
   gap clock-hour values to the registered minute-scale frame contract exactly
   once (or equivalently bypasses the later minute-to-hour division), while
   leaving the shared prepared artifact unchanged;
2. rebuild and identity-check only the 90 gap timing frames, retaining the
   exact participant-days, sites, predictor coding, response definitions,
   timing cutpoints, and accepted model routes;
3. refit only the affected reduced/additive/interaction models and their
   already-prespecified Student-t, AR, and participant/site deletion sidecars;
4. rerun the visual/hard-gate review for those 90 corrected cells with new
   plot/source identities;
5. replace only the 30 corrected primary-gap raw timing tests and recompute
   the mathematically dependent ranks/q-values/decisions in the six complete
   gap 15-slot families; preserve every primary raw/FDR field, all non-timing
   gap raw model results, L10 slot 3, and MDER raw/model outputs;
6. prove all 378 unaffected non-L10 cells and every other protected branch
   byte-identical before and after; and
7. publish the correction only in a new task-owned amendment/report and stop
   at a new author gate. Do not overwrite the historical H06-D-G2 or
   H06-D-G2A records.

The repair should run serially and checkpointed. A bounded production-code
pilot and runtime estimate are required if the renewed deletion work is
expected to be computationally heavy. Shared preparation, central ledgers,
Stage 3/4, main H06, commit, and push remain outside this request.
