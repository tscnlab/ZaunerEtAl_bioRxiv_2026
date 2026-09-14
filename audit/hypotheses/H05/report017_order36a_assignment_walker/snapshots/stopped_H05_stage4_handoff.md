# H05 Stage 4 handoff

Status: **Stage 4 preparation/provenance companion independently verified and centrally closed for METRIC-011 under H05-005**

## Authorization and scope

The controlling amendment is
`audit/decisions/mder_mean_of_viable_ratios.md` (`METRIC-010`; SHA-256
`1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de`).
The companion continues to implement REPORT-007 and the applicable shared
display rules. The coordinator-owned decisions, ledgers, and Quarto
configuration remained read-only.

This update uses the accepted current MDER outputs and stored non-MDER H05
artifacts. Rendering recalculates only file identities, schema/key checks, and
lightweight descriptive summaries. It does not fit or refit a model, calculate
predictions or residual diagnostics, rerun leave-one-site-out analyses,
bootstrap, or simulate data. The approved bounded scientific updater was run
separately and only for MDER; the other 16 metrics remain frozen.

## Completed deliverables

- Authoring source:
  `audit/hypotheses/H05/H05_analysis_preparation.qmd`
- Nature Health HTML:
  `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.html`
- Byte-identical website source copy:
  `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.qmd`
- Descriptive source-data builder:
  `scripts/hypotheses/H05/build_h05_preparation_artifacts.R`
- REPORT-011 QA builder:
  `scripts/hypotheses/H05/build_h05_figure_readability_qa.R`
- Non-circular provenance builder:
  `scripts/hypotheses/H05/build_h05_preparation_report_manifest.R`
- H05-scoped verification:
  `tests/hypotheses/H05/test_h05_preparation_report.R`
- Preparation-report manifest:
  `artifacts/12_manifests/H05/H05_preparation_report_manifest.csv`

The shared-profile render completed all 55 chunks successfully. The page has
21 readable `gt` tables, three preparation figures with captions and
alternative text, reciprocal links to the H05 results report, and adjacent
website navigation. The H05 task did not edit `_quarto-nathealth.yml`.

## MDER construction and provenance

The companion now describes the accepted MDER estimand plainly and exactly:

- place MEDI and LIGHT on a complete 1,440-minute local wall-clock grid;
- average fall-back duplicate local minutes channel-wise before forming a
  ratio and leave spring-forward absent minutes missing;
- retain a minute only when both channels are finite and strictly positive;
- calculate the arithmetic mean of the viable one-minute MEDI/LIGHT ratios;
- require at least 720 viable minute ratios, inclusively; and
- apply no time-profile weighting, gating, scaling, or ratio of daily
  integrals.

The provenance map records the approved current primary and repaired
gap-timing-unaware MDER inputs, the bounded updater
`refresh_h05_mder_metric010.R`, the finalizer
`finalize_h05_metric010_reconciliation.R`, the gap-only reseal
`reseal_h05_gap_mder_metric010.R`, and every affected output. It distinguishes
scientific fitting from the report-only builders.

The current all-available MDER support is visible: 702 near-eye
participant-days from 137 participants at nine sites and 732 chest
participant-days from 152 participants at eight sites. The companion also
records the exact primary paired MDER sample of 489 days from 107 participants
at eight sites and the repaired gap-timing-unaware samples of 687 near-eye
days from 137 participants and 723 chest days from 152 participants. The
repaired gap paired/common sample contains 478 days from 107 participants at
eight sites.

## Diagnostics, influence, and preservation boundary

The new MDER diagnostic/provenance table combines the exact fitted samples,
current upper-tail screen, and bounded influence summary. One near-eye and
three chest days exceed the Tukey outer fence. All 44 day- and participant-
deletion refits pass; 40 of 44 sensitivity intervals contain zero. The four
exceptions are the near-eye F5 intervals, which remain below zero consistently
with its unadjusted primary interval. All chest sensitivity intervals contain
zero, although the very small chest coefficients are more upper-tail-
sensitive. No observation was removed from the primary result.

The 20-row METRIC-010 reconciliation passes in full. It proves that the other
16 metric frames, fitted models, raw estimates, intervals, tests, diagnostics,
and sensitivities remain byte- or value-identical as applicable. Only the
MDER-dependent rows and complete-family BH ranks/adjusted p-values genuinely
affected by those rows changed. All three 68-test families still retain zero
associations.

The subsequent 16-check gap reseal confirms that only four repaired gap MDER
frames and four H05-F3 MDER bundles were replaced. No primary or non-MDER
model was refitted. Replacing the four MDER slots necessarily changed 27
non-MDER adjusted p-values and 26 ranks in H05-F3, while every non-MDER raw
test and fitted object remained frozen. The repaired gap branch also has 44
successful bounded influence refits; 40 intervals contain zero, and its
zero-of-68 conclusion is unchanged.

The earlier profile-support and anomalous-device-day sensitivities are marked
as non-transferable to the current estimand rather than being silently reused.
Only current-estimand upper-tail/influence checks and the applicable
gap-timing-unaware comparator are interpreted.

## Other reader-facing requirements retained

- All-available near eye remains primary and all-available chest
  complementary; exact paired/common placement and gap-timing-unaware results
  remain clearly labelled sensitivities.
- The exact six evaluated Wilkinson formulas remain a compact table.
- The complete 68-test BH family and zero-of-68 conclusion remain explicit.
- The two leading non-MDER F2 estimates remain unchanged, stable, and not
  multiplicity-retained.
- The four sleep-environment models remain prominently **unfit for H05
  inference**, with the explicit qualification that this does not preclude
  analysing the underlying metric under another hypothesis, response, or
  model structure.
- The fixed-site primary versus random-site sensitivity decision, including
  15 unstable random-site cells, remains fully documented.
- The exact longest-period identifiability sensitivity continues to use
  “period,” not “bout.”
- Raw and adjusted p-values follow the independent REPORT-008 display rules.

## Source data and figure QA

Preparation source data retain their stable row contracts:

| Source file | Rows |
|---|---:|
| `H05_preparation_sample_support.csv` | 34 |
| `H05_preparation_leba_score_distribution.csv` | 72 |
| `H05_preparation_site_support.csv` | 1,122 |
| `H05_preparation_site_support_summary.csv` | 17 |

All ten H05 reader-facing figures pass the renewed physical-size inspection.
The two diagnostic figures now contain four readable facets including MDER;
the MDER effect-matrix rows, exact paired sample annotation, and preparation
sample-support figure were also revalidated. No clipping, overlap, distorted
text, awkward central wrapping, or indistinguishable mark was found.

QA evidence:

- `audit/hypotheses/H05/H05_figure_readability_qa.md`
- `artifacts/12_manifests/H05/H05_figure_readability_qa.csv`
- `artifacts/12_manifests/H05/H05_figure_A4_proofs.pdf`

## Verification and non-circular manifest chain

The focused preparation test passes with 21 `gt` tables, required figure,
caption, and alt-text structure, 129 manifest identities, adjacent navigation,
reciprocal links, exact current MDER samples, the separate 44-refit primary
and repaired-gap influence contracts,
source-data contracts, prohibited-call audit, REPORT-011 QA, and a byte-
identical website source copy.

The Stage 3 manifest contains 165 identities and excludes itself and the Stage
3 handoff. The preparation manifest contains 129 identities, includes the
final Stage 3 handoff and Stage 3 manifest, and excludes itself and this Stage
4 handoff. This preserves a non-circular chain.

## Final identities

| File | SHA-256 |
|---|---|
| `audit/hypotheses/H05/H05_analysis_preparation.qmd` | `ac8fb91708c6b6d9fbc4dfb9b49f1c966e8a5f03848390727eeda5e337d45e44` |
| `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.qmd` | `ac8fb91708c6b6d9fbc4dfb9b49f1c966e8a5f03848390727eeda5e337d45e44` |
| `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.html` | `c95ce926f047e69e7a9887825188c05b359c92aec9a935f1fa4bcb2a16fc6912` |
| `notebooks/hypotheses/H05.qmd` | `342c5cf2f00141de355ec1fad2b5a3443bc9af383afe6d909ed3daf8a7f69e0a` |
| `_build/nathealth/notebooks/hypotheses/H05.html` | `6941fb0874af3ab4febe64dec2e28978e3954c081f609a9318646bd75e62f367` |
| `scripts/hypotheses/H05/build_h05_preparation_artifacts.R` | `ed7fb94f86f9df393ae5f5ccfb8ff8d7c58ae33d759b022537c4764269829820` |
| `scripts/hypotheses/H05/build_h05_preparation_report_manifest.R` | `0b6efa1cc6af31cb41c9fb613172a8fad2bdb2fec03c26daab53dbfa7e55b963` |
| `scripts/hypotheses/H05/build_h05_figure_readability_qa.R` | `fe3af63034ee9bf9b7dae35b2c6391e008b6a9d64431ccc7c3d7fee281de54bb` |
| `tests/hypotheses/H05/test_h05_preparation_report.R` | `509dccb96d6cb0e2e7dc2f35011053690b1df6ff8edfc97e0835d4941e9561b6` |
| `audit/hypotheses/H05/H05_figure_readability_qa.md` | `5d528d6ef66d56f1483d7f50fabea918c22fe84535c764e5b244390f2101476f` |
| `artifacts/12_manifests/H05/H05_figure_readability_qa.csv` | `24997c8e299c8fe8f98e4a296c14d898d8b396e5c34a343dff978848cd63189e` |
| `artifacts/12_manifests/H05/H05_figure_A4_proofs.pdf` | `a05a9ba964b53740c829345814efa16861e33fccf08a06124c053b4a677b0246` |
| `artifacts/12_manifests/H05/H05_stage3_artifacts.csv` | `1522951144720bc2fb2c13ceb18cc25c7ad3c7e43af5f735fb5684c16e68bead` |
| `audit/handoffs/H05_stage3_handoff.md` | `dd79a4ec1959a4924d77d5ee59ebc0e86d202e920641fd16c5af5a383ae16021` |
| `artifacts/12_manifests/H05/H05_preparation_report_manifest.csv` | `50b9e4a3455e0640b414edc873c6a263893fa7a61a991155850a24784d50ec71` |
| `artifacts/12_manifests/H05/H05_metric010_reconciliation.csv` | `3cccc74a2dbd62a3bc70bca21b833c319bfc6467862785ff11b55b608ce9f223` |
| `artifacts/12_manifests/H05/H05_metric010_gap_reseal_reconciliation.csv` | `0211e9524837c860007f02824084bc6564972a952e09507cbfa5f0dcb01976ca` |

## Disposition

The coordinator independently verified this preparation/provenance amendment
and closed the repaired-gap reconciliation in
`audit/decisions/h05_metric010_gap_reseal_closure.md` (`H05-004`, recorded as
`CHG-103`). The existing four-stage H05 closure remains in force.
No commit, push, upload, central-ledger edit by the H05 task, configuration
edit, or manuscript change was made.

## METRIC-011 bounded provenance reseal (2026-08-12)

The preparation companion now records the approved numerical-zero rule, the
independent upstream evidence manifest, all five new shared input pins, and
the exact H05 bounded execution boundary. Three primary near-eye and five
primary chest L10-mean participant-days were normalized from the positive
floating-point residual `4.163336342344337e-17` lx to exact zero only because
every finite source minute was zero. Missing source minutes remained missing.
No fitted sample, gap L10 value or fit, non-L10 fit, accepted MDER output,
hourly/30-minute value, participant-level value, or site/daylight-context
value changed.

The companion visibly documents four affected primary frames, 16 refreshed
factor-model cells, eight inferential bundles, eight registered random-site
sensitivities, 36 primary L10 leave-one-site-out refits, and zero gap L10 or
non-L10 refits. The 22-row reconciliation passes. Seven inferential raw
p-values and two adjusted p-values changed at full precision, no family rank
changed, and every complete 68-test family still retains zero associations.
The input, frame, result-change, family, execution-environment, package, and
artifact-update records are linked from the report.

The shared-profile companion render completed 57 chunks and now contains 22
readable `gt` tables plus the three preparation figures. The focused R 4.6.1
test passes with 141 non-circular manifest identities and a byte-identical
website source copy. Renewed REPORT-011 QA and direct visual inspection found
no clipping, overlap, distortion, awkward central wrapping, compressed
important text, or indistinguishable marks in any of the ten H05 figures.
This section supersedes the earlier pre-METRIC-011 hash table above.

| Current file | SHA-256 |
|---|---|
| `audit/hypotheses/H05/H05_analysis_preparation.qmd` | `f8087740def5e4e75e5bf5eff82d9f58acf1865954a16919719a7280f3447bfc` |
| `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.qmd` | `f8087740def5e4e75e5bf5eff82d9f58acf1865954a16919719a7280f3447bfc` |
| `_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation.html` | `c44f4f77f4e2295f6b265ed9505c3c560361a7280562dd9ce1afce73149d5866` |
| `tests/hypotheses/H05/test_h05_preparation_report.R` | `ec738f56fb8b3cf94755fd5055d128d1a22bcc31a435554568aaa15acf78890e` |
| `artifacts/12_manifests/H05/H05_preparation_report_manifest.csv` | `bd4ae8ac8516e961d1c4a37b1c18d3262376cd27ba0ed9611b7b60d167059c36` |
| `artifacts/12_manifests/H05/H05_stage3_artifacts.csv` | `9dabc70a0ab6554a0b4d9dbc175cd4009b1f57a57c975cb4677b45ead2620100` |
| `audit/handoffs/H05_stage3_handoff.md` | `883d6303f01ea29e0e5ac8945befb650468f6681873bbb13fc3b7ed4abcc7849` |
| `artifacts/12_manifests/H05/H05_stage2_artifacts.csv` | `09363abf0557646870d0752f08b00f42013deec471a1ea97067c2333a1a811cc` |
| `audit/handoffs/H05_stage2_handoff.md` | `db5f7e47cf75bd53dc0f5489303baca46b0b3b253a8f4802e67a5629711edfb2` |
| `artifacts/12_manifests/H05/H05_metric011_artifact_update_manifest.csv` | `37974044361e8301c2750361c7080b8b12630c4ceb6a0208518b100e99aa690f` |
| `artifacts/12_manifests/H05/H05_metric011_reconciliation.csv` | `fc55f42f90b5b1269b88ee7fbfdd5409afa6f13876c3c2e271e757edc42536f9` |

The coordinator independently verified the 29 artifact-update identities, 22
preservation rows, exact p-value and rank change counts, permitted L10 scope,
and all three zero-of-68 conclusions before recording `H05-005` / `CHG-112`.
The controlling closure decision is
`audit/decisions/h05_metric011_l10_reseal_closure.md` (SHA-256
`61507d2965481a987f70db91adda17e67cf8ec2b0d53be523ad69f31eedb97b1`).
This checksum-only refresh absorbs the settled central change-log snapshot
through the Stage 3 and dependent preparation-manifest chain. It did not
rerender or change any scientific or reader-facing artifact, and the Stage 2
manifest remains
`09363abf0557646870d0752f08b00f42013deec471a1ea97067c2333a1a811cc`.
No commit or push was requested or performed.

## REPORT-014/017 consolidated source-only harmonization (order 36)

Status: **assembled for independent source acceptance; the H05 result and
companion render hold remains in force**

Order 36 rewrites only the two H05 reader QMD sources. It preserves the closed
scientific analysis and reorganizes the result page around the primary
near-eye finding, complementary non-ocular chest evidence, visible
model-check boundaries, MDER evidence, sensitivity interpretation, and a late
detailed analysis record. The companion now opens with its computation
boundary and uses reader-facing verification, study-site, FDR, and provenance
labels. Both sources enable figure lightboxes without changing a stored
figure.

### Final source identities

| Source | SHA-256 | Bytes |
|---|---|---:|
| `notebooks/hypotheses/H05.qmd` | `7c20e16629729de433d1ab400038e9d32c73aeb25c95ecd44d581b876755d5e0` | 74,309 |
| `audit/hypotheses/H05/H05_analysis_preparation.qmd` | `0a5296442b46c8b9e43773d97eb979ffbbf3512faabe6f4399da2214d38cb81c` | 75,630 |

The reciprocal dynamic links are exactly
`../../audit/hypotheses/H05/H05_analysis_preparation.qmd` from the result and
`../../../notebooks/hypotheses/H05.qmd` from the companion. The companion
links to the result anchor
`../../../notebooks/hypotheses/H05.qmd#h05-preregistration-deviations`.
The result retains the nine current and resolved-history registration links
and the destination anchor `h05-preregistration-deviations`.

### Scientific and display boundaries preserved

- Near-eye measurements remain primary and measure light close to the eyes.
  Chest measurements remain complementary, non-ocular evidence.
- Each inferential family remains the complete four-factor by 17-metric set of
  68 tests, with zero FDR-supported associations.
- The four sleep-environment cells remain in the family and remain unfit for
  H05 inference. This disposition does not disqualify the metric for another
  response, estimand, model structure, or hypothesis.
- Fixed study-site effects remain primary. The registered random-site model,
  common-sample placement comparison, leave-one-site-out analysis,
  gap-timing-unaware dataset, exact-period analysis, and descriptive rank
  correlations retain their accepted sensitivity roles.
- MDER remains the arithmetic mean of viable one-minute ratios under the
  accepted positivity and support rule. All accepted METRIC-010 and
  METRIC-011 scientific outputs remain frozen.
- The common-sample placement display continues to assess concordance of
  separately fitted matched estimands. It is not an equivalence analysis or a
  direct placement-effect test.

The provisional main outputs remain `fig-h05-near-effects` and the continued
`tbl-h05-near-results-a` plus `tbl-h05-near-results-b` table. The near-eye
model-check figure and paired-placement figure remain supplemental. Static
inspection found no stored-figure label that requires refresh before the
later authorized render.

### Source-only verification and preservation

The one prescribed source-only command is:

```bash
H05_ORDER36_PRE_DIR=/private/tmp/h05-report017-order36.pdKad8 Rscript --vanilla tests/hypotheses/H05/test_h05_report017_source_harmonization.R
```

Source-only verification result: **PASS**. The source-only test covers both
QMDs without executing them, verifies all
endpoint and link contracts, parses every R chunk without execution, audits
the protected scientific and display identities, reconstructs the sealed
pre-edit sources from the exact reverse diffs, and audits the new non-circular
order-36 source manifest. Its consolidated result is recorded under
`audit/hypotheses/H05/report017_order36/`.

The three existing H05 tests and all three existing H05 report manifests are
preserved byte-for-byte at their order-36 preflight identities. The existing
result and companion HTML files remain the exact stale render context and are
not claimed to correspond to these revised sources. The Nature Health profile,
central registration page, site registry, output catalog, scientific
artifacts, figures, source-data files, and reader-figure builder are unchanged.

No Quarto render, QMD execution, model fit or refit, prediction, simulation,
bootstrap, resampling, FDR recomputation, diagnostic rerun, leave-one-site-out
rerun, artifact regeneration, configuration edit, ledger edit, commit, or
push is part of this source-only harmonization. H05 remains scientifically
closed and held for the later serial REPORT-017 result-and-companion render
gate.
