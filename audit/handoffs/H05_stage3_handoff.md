# H05 Stage 3 handoff

Status: **Stage 3 remains author-approved; bounded METRIC-011 primary L10 reseal independently verified and centrally closed under H05-005**

## Authorization and scope

The controlling amendment is
`audit/decisions/mder_mean_of_viable_ratios.md` (`METRIC-010`; SHA-256
`1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de`).
It reopens only the MDER-dependent portion of the accepted 17-metric H05
analysis. The other 16 metrics remain frozen, except for complete-family BH
ranks and adjusted p-values that necessarily depend on the current four MDER
raw p-values.

The prior gate decisions remain the historical authority for the four-stage
workflow: `H05-001`, `H05-002`, and `H05-003`. The coordinator-owned decision
files, central ledgers, and `_quarto-nathealth.yml` remained read-only. This
task did not modify shared preparation, another hypothesis, or a manuscript
file. It did not run a full 17-metric analysis, bootstrap, simulation, or
heavy resampling.

## Completed reader-facing deliverable

- Source: `notebooks/hypotheses/H05.qmd`
- Nature Health HTML: `_build/nathealth/notebooks/hypotheses/H05.html`
- Reader-artifact builder:
  `scripts/hypotheses/H05/build_h05_reader_artifacts.R`
- Figure-QA builder:
  `scripts/hypotheses/H05/build_h05_figure_readability_qa.R`
- Focused verification:
  `tests/hypotheses/H05/test_h05_stage3_reader_report.R`
- Provenance seal: `artifacts/12_manifests/H05/H05_stage3_artifacts.csv`

The shared Nature Health profile rendered all 79 chunks successfully. The
result page contains 30 bounded `gt` tables and seven accessible figures,
retains reciprocal navigation to the H05 preparation companion, and avoids
internal comparison-history or gate terminology.

## MDER estimand and bounded computation

MDER is the arithmetic mean of viable one-minute MEDI/LIGHT ratios. Both
channels must be finite and strictly positive. The computation uses a complete
1,440-minute local wall-clock grid: fall-back duplicate local minutes are
averaged channel-wise before forming the ratio, and spring-forward absent
minutes remain missing. A daily MDER is retained with at least 720 viable
minute ratios. It uses no time-profile weighting, gating, or scaling and is
not a ratio of daily integrals.

The initial amendment rebuilt 32 MDER fixed-site cells across the eight
accepted H05 scenarios, 36 primary MDER leave-one-site-out refits, and eight
MDER random-site fits. The repaired shared gap input was then integrated by a
separate bounded reseal: only four gap MDER frames and four H05-F3 MDER model
bundles were replaced (16 factor-model cells), followed by 44 gap-only bounded
influence refits and exact matched-placement reconstruction. No primary or
non-MDER model was refitted in that reseal. The H05-F3 BH vector now combines
64 unchanged non-MDER raw p-values with four repaired MDER p-values; 27
non-MDER adjusted p-values and 26 ranks consequently changed, while their raw
tests and fitted objects remained frozen. The initial 20-check reconciliation
and final 16-check gap reseal both pass.

## Updated MDER results

The all-available primary near-eye MDER sample contains 702 participant-days,
137 participants, and nine sites. The complementary chest sample contains 732
participant-days, 152 participants, and eight sites.

| Placement | Factor | MDER difference per LEBA SD (95% CI) | Raw p | BH-adjusted p |
|---|---:|---:|---:|---:|
| Near eye | F2 | +0.0041 (-0.0113 to +0.0194) | 0.586 | 0.747 |
| Near eye | F3 | -0.0039 (-0.0186 to +0.0109) | 0.593 | 0.747 |
| Near eye | F4 | -0.0104 (-0.0256 to +0.0047) | 0.162 | 0.380 |
| Near eye | F5 | -0.0197 (-0.0351 to -0.0043) | 0.010 | 0.169 |
| Chest | F2 | -0.0016 (-0.0409 to +0.0377) | 0.938 | 0.981 |
| Chest | F3 | -0.0132 (-0.0502 to +0.0238) | 0.471 | 0.761 |
| Chest | F4 | -0.0183 (-0.0559 to +0.0193) | 0.327 | 0.761 |
| Chest | F5 | -0.0166 (-0.0555 to +0.0222) | 0.387 | 0.761 |

No MDER association is BH-retained. The primary near-eye F5 interval excludes
zero before multiplicity adjustment, but its BH-adjusted p = 0.169 does not
support a multiplicity-retained claim. The all-available MDER models retain
the specified ordinary Gaussian residual limitation.

The exact primary paired/common MDER sample contains 489 participant-days from 107
participants at eight sites. All four near-eye and chest directions agree and
their component 95% confidence intervals overlap; this is concordance, not an
equivalence test. The repaired gap-timing-unaware MDER samples contain 687
near-eye participant-days from 137 participants and 723 chest participant-days
from 152 participants. Their exact paired/common sample contains 478 days from
107 participants at eight sites. None of those MDER associations is
BH-retained, and all four gap-timing-unaware near-eye directions agree with the
primary result.

## Current-estimand upper tail and influence

Because a mean of momentary ratios can be influenced by small positive
photopic denominators, the current MDER upper tail was screened without
automatically excluding observations. One near-eye day exceeded the Tukey
outer fence of approximately 1.25 (maximum 1.857); three chest days exceeded
the fence of approximately 1.28 (maximum 3.574).

All 44 bounded day- and participant-deletion refits passed. Forty of 44
sensitivity intervals contain zero. The four exceptions are the near-eye F5
deletion intervals, which remain below zero consistently with its unadjusted
primary interval. The near-eye coefficients changed by at most 0.234
full-model standard errors and did not reverse direction. At the chest, all
sensitivity intervals contain zero; the F2 and F4 coefficients changed by at
most 0.823 and 0.828 standard errors, and the already near-zero F2 coefficient
reversed direction once. The small complementary chest coefficients are
therefore upper-tail-sensitive, but none of these checks changes the
multiplicity-adjusted conclusion.

All 44 repaired-gap deletion refits also passed; 40 intervals contain zero.
Near-eye coefficients changed by at most 0.233 standard errors without a
direction reversal. All chest intervals contain zero; F2 and F4 changed by at
most 0.823 and 0.841 standard errors, and F2 reversed direction twice. The
four near-eye F5 intervals remain below zero before multiplicity correction,
but H05-F3 retains zero of 68.

The earlier profile-support and anomalous-device-day batteries are not
presented as transferable to this estimand. Only the current-estimand upper
tail/influence checks and the applicable gap-timing-unaware comparison are
used.

## Preserved H05 conclusion and other sensitivities

The complete primary family still retains **zero of 68 associations**. The
two leading non-MDER F2 estimates remain unchanged and are described as stable
but not multiplicity-retained:

| Primary near-eye metric | Ratio per participant SD (95% CI) | Raw p | BH-adjusted p |
|---|---:|---:|---:|
| Time above 1,000 lx melEDI | 1.234 (1.084 to 1.405) | 0.002 | 0.124 |
| Corrected melEDI dose | 1.278 (1.079 to 1.514) | 0.004 | 0.124 |

The complementary chest and gap-timing-unaware families also retain zero of
68. All 612 primary leave-one-site-out refits pass: 20 associations are
stable, 27 are direction-stable but magnitude-sensitive, and 21 are
direction-unstable. The two leading F2 associations remain stable. The
random-site sensitivity still contains 121 passing and 15 unstable cells.

The four sleep-environment models remain prominently marked **unfit for H05
inference** because of material response-support and simulated-residual
limitations. That finding is specific to this H05 response and model
structure; it does not determine whether the metric can be analysed in a
different hypothesis with another response or model.

## Figure readability and accessibility

All ten reader-facing H05 figures passed the REPORT-011 final-size inspection.
At this amendment, the two near-eye diagnostic figures expanded from three to
four facets to include MDER and from 9 x 7.5 to 9 x 9 inches. The MDER rows in
the effect matrices, the exact paired-sample annotation, and MDER support in
the preparation figure were revalidated. The paired plot retains near eye on
x, chest on y, equal axis geometry, identity and null lines, matched estimands,
accessible caption/alt text, and paired source data. No clipping, overlap,
distorted text, or unreadable central annotation was found.

QA evidence:

- `audit/hypotheses/H05/H05_figure_readability_qa.md`
- `artifacts/12_manifests/H05/H05_figure_readability_qa.csv`
- `artifacts/12_manifests/H05/H05_figure_A4_proofs.pdf`

## Verification and provenance

R 4.6.1 and the project `renv` library were used. The focused reader test
passes with 68 near-eye and 68 chest cells, zero retained primary
associations, 30 tables, seven figures, exact current MDER samples and
estimates, the separate 44-refit primary and repaired-gap influence contracts,
and all material diagnostic qualifications. The Stage 3 manifest contains 165
non-circular identities and
first verifies every Stage 2 identity. It excludes itself and this handoff by
design.

| File | SHA-256 |
|---|---|
| `notebooks/hypotheses/H05.qmd` | `342c5cf2f00141de355ec1fad2b5a3443bc9af383afe6d909ed3daf8a7f69e0a` |
| `_build/nathealth/notebooks/hypotheses/H05.html` | `6941fb0874af3ab4febe64dec2e28978e3954c081f609a9318646bd75e62f367` |
| `scripts/hypotheses/H05/build_h05_reader_artifacts.R` | `7cecc2ec14b23085c50da300f04a1506f161df755e21ff636ed92ac1a84a6177` |
| `scripts/hypotheses/H05/build_h05_figure_readability_qa.R` | `fe3af63034ee9bf9b7dae35b2c6391e008b6a9d64431ccc7c3d7fee281de54bb` |
| `scripts/hypotheses/H05/build_h05_stage3_manifest.R` | `115a6873370e50ff6037e191936c5a39920737beb65f1127fee3afb39cee72b0` |
| `tests/hypotheses/H05/test_h05_stage3_reader_report.R` | `215b9638d7b3e48f650fe5b84e01bad6c88608aaa59bdb45e2745b1dde01e621` |
| `audit/hypotheses/H05/H05_figure_readability_qa.md` | `5d528d6ef66d56f1483d7f50fabea918c22fe84535c764e5b244390f2101476f` |
| `artifacts/12_manifests/H05/H05_figure_readability_qa.csv` | `24997c8e299c8fe8f98e4a296c14d898d8b396e5c34a343dff978848cd63189e` |
| `artifacts/12_manifests/H05/H05_figure_A4_proofs.pdf` | `a05a9ba964b53740c829345814efa16861e33fccf08a06124c053b4a677b0246` |
| `artifacts/12_manifests/H05/H05_stage2_artifacts.csv` | `b09869afe6431ea27c189151535a7d605b2cca944c69184cd3f970e76f156d1f` |
| `artifacts/12_manifests/H05/H05_stage3_artifacts.csv` | `1522951144720bc2fb2c13ceb18cc25c7ad3c7e43af5f735fb5684c16e68bead` |
| `artifacts/12_manifests/H05/H05_metric010_reconciliation.csv` | `3cccc74a2dbd62a3bc70bca21b833c319bfc6467862785ff11b55b608ce9f223` |
| `artifacts/12_manifests/H05/H05_metric010_gap_reseal_reconciliation.csv` | `0211e9524837c860007f02824084bc6564972a952e09507cbfa5f0dcb01976ca` |

## Disposition

The coordinator independently verified the reader-facing amendment and closed
the repaired-gap reconciliation in
`audit/decisions/h05_metric010_gap_reseal_closure.md` (`H05-004`, recorded as
`CHG-103`). The unchanged 16-metric result, zero-of-68 conclusions,
prior Stage 3 author approval, and completed four-stage H05 closure remain in
force. No commit, push, upload, or manuscript change was made by this task.

## METRIC-011 bounded reader-report reseal (2026-08-12)

The controlling numerical-zero rule is
`audit/decisions/l10_numerical_zero_normalization.md` (SHA-256
`23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797`),
with independently verified upstream evidence in
`audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv`
(SHA-256
`a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb`).
The reader report now explains that a geometric-mean back-transformation
residual is set to exact zero only within the unit-aware tolerance and only
when every finite source minute is exactly zero; missing minutes remain
missing.

Three primary near-eye and five primary chest L10-mean participant-days
changed from `4.163336342344337e-17` lx to zero. Four primary L10 frames and
16 factor-model cells were refreshed, together with their diagnostics,
bounded sensitivities, primary paired/common comparison, and complete-family
BH derivatives. No sample, gap L10 fit, non-L10 fit, or accepted MDER result
changed. Seven inferential raw p-values and two adjusted p-values changed at
full precision, but the adjusted changes are below the three-decimal display
precision; no family rank changed. Primary near eye, complementary chest, and
gap-timing-unaware near eye each still retain zero of 68 associations.

The visible L10 values in the result matrices and paired/common plot were
refreshed from the exact stored outputs. The matched plot retains near eye on
the x-axis, chest on the y-axis, identical estimands and samples, identity and
null lines, equal geometry, accessible caption/alt text, and no equivalence
claim. All ten reader-facing figures passed renewed REPORT-011 calculation
and visual inspection with no clipping, overlap, distortion, compressed
central text, or indistinguishable marks.

The focused R 4.6.1 reader test passes. The Stage 3 manifest contains 177
non-circular identities and first verifies all 77 frozen Stage 2 identities.
This section supersedes the earlier pre-METRIC-011 hash table above.

| Current file | SHA-256 |
|---|---|
| `notebooks/hypotheses/H05.qmd` | `3aab2f527d1024a05422bba061e9f8f27a5c9a2a316e439b7c6f535627ca476c` |
| `_build/nathealth/notebooks/hypotheses/H05.html` | `58be9b4da8bb67a4322af7096472de1bf97c47d17c79f39078692577a2788b96` |
| `tests/hypotheses/H05/test_h05_stage3_reader_report.R` | `982162ccbd55def924beff3fbb0e98d31a94884aeb8cc683f817189e1171d4f4` |
| `artifacts/12_manifests/H05/H05_figure_readability_qa.csv` | `24997c8e299c8fe8f98e4a296c14d898d8b396e5c34a343dff978848cd63189e` |
| `artifacts/12_manifests/H05/H05_figure_A4_proofs.pdf` | `dd60825ab366be759ddd93efc2dbfd498a019ddcb9fe71dba2a87b5f9cdb4bac` |
| `artifacts/12_manifests/H05/H05_stage2_artifacts.csv` | `09363abf0557646870d0752f08b00f42013deec471a1ea97067c2333a1a811cc` |
| `artifacts/12_manifests/H05/H05_stage3_artifacts.csv` | `9dabc70a0ab6554a0b4d9dbc175cd4009b1f57a57c975cb4677b45ead2620100` |
| `artifacts/12_manifests/H05/H05_metric011_artifact_update_manifest.csv` | `37974044361e8301c2750361c7080b8b12630c4ceb6a0208518b100e99aa690f` |
| `artifacts/12_manifests/H05/H05_metric011_reconciliation.csv` | `fc55f42f90b5b1269b88ee7fbfdd5409afa6f13876c3c2e271e757edc42536f9` |

The coordinator independently verified the bounded amendment and recorded its
closure as `H05-005` / `CHG-112` in
`audit/decisions/h05_metric011_l10_reseal_closure.md` (SHA-256
`61507d2965481a987f70db91adda17e67cf8ec2b0d53be523ad69f31eedb97b1`).
The settled central decision register and change log have SHA-256 identities
`bd0dc6c93fbec259c8a3d4df55a23968566854ba731900e469d4bc0dc9726676`
and
`02f1f0d983e2d37efe70dcadda72df16cee734eafcdf0b77bc969eb98ba4d942`,
respectively. The manifest refresh above absorbs the final `CHG-112`
change-log snapshot only. No scientific artifact, rendered report, or Stage 2
identity changed during this checksum closure.
