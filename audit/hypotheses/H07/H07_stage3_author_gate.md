# H07 Stage 3 author gate

Date: 2026-08-07
Branch: `rewrite/NH`
Stage: 3 — standalone reader-facing report
Status: **ready for author review; stop before Stage 4**

## Authorization implemented

Decision `H07-003` approved `H07-S2R-001` through `H07-S2R-008` and
authorized Stage 3. The report implements the accepted descriptive
positive-derivative-to-sustained-zero-compatible rule without reinstating a
pooled-support or leave-one-site-out eligibility gate. No model was refitted,
no new simulation was run, and no production computation was required.

## Reader conclusion

The standalone report concludes that a **derivative-defined plateau pattern**
is visible for six of nine primary near-eye metrics and seven of nine
complementary chest metrics. It presents the paired fitted-value and derivative
panels for all nine metrics at each placement, exact transition brackets, and
endpoint derivative estimates with pointwise 95% confidence intervals.

The report does not treat pointwise non-significance as equivalence. It states
that the patterns do not establish an asymptote, mechanistic or physiological
ceiling, causal photoperiod effect, distinct latitude effect, health or
clinical consequence, or placement equivalence. Absolute latitude remains
inseparable from site. Site, collection period, incomplete photoperiod
overlap, repeated participant-days, extreme participant-smooth concurvity,
model form, and site influence remain explicit limitations.

## Reader deliverables

- source: `notebooks/hypotheses/H07.qmd`;
- Nature Health render:
  `_build/nathealth/notebooks/hypotheses/H07.html`;
- primary paired figure:
  `artifacts/08_figures/H07/H07_revised_smooth_derivative_pairs_near_eye.png`;
- complementary paired figure:
  `artifacts/08_figures/H07/H07_revised_smooth_derivative_pairs_chest.png`;
- figure source rows:
  `artifacts/09_tables/H07/H07_main_curve_points.csv` and
  `artifacts/09_tables/H07/H07_revised_derivative_points.csv`;
- figure settings:
  `artifacts/09_tables/H07/H07_revised_paired_figure_settings.csv`; and
- focused verification:
  `tests/hypotheses/H07/test_h07_stage3_reader_report.R`.

The report uses R 4.6.1 and the existing project library. The bounded Nature
Health render completed all 33 blocks. The focused R verification passes the
scientific classifications, samples, sensitivities, model-form checks,
distributional pilot, formula, terminology, accessible alt text, source-data
links, and 11 rendered `gt` tables.

Current SHA-256 identities are:

| Artifact | SHA-256 |
|---|---|
| `notebooks/hypotheses/H07.qmd` | `4d29002567fbabc46a30a5156b4d6bb94fa0f5770b03c3bedadb4b6d0ff14a1e` |
| `_build/nathealth/notebooks/hypotheses/H07.html` | `ae88f7a4722067d4521991d632ae6bf13719a6423534bf3e7be883fbe2bec95b` |
| `tests/hypotheses/H07/test_h07_stage3_reader_report.R` | `84e96a523bf1d9051be8abe3cabbef9837dfe98ab978a30bd846d0f2d728cd17` |
| near-eye paired figure | `a2e04ef58a451622a381c48326058a74dc26bd79d3bd52035560ef3b311c8c8a` |
| chest paired figure | `1540adc63bf6f5fda7712ebd09b0a7e3ef2930a8ce01a022fb2713f2c6d07c92` |

## Exact samples and displayed sensitivities

- Primary near eye: 139–141 participants, 655–816 participant-days and
  observations, nine sites.
- Complementary chest: 153–154 participants, 743–902 participant-days and
  observations, eight sites.
- Paired/common placement sensitivity: 110–112 participants, 505–643
  participant-days and observations, eight sites.
- Exactly identified longest-period sensitivity: 132 participants and 500
  participant-days near eye; 150 participants and 564 participant-days at the
  chest.
- Observed/corrected dose common rows: 141 participants and 761
  participant-days near eye; 154 participants and 851 participant-days at the
  chest.

The gap-timing-unaware dataset reproduces nine of nine near-eye and eight of
nine chest classifications. The paired/common analysis reproduces four of
nine near-eye and six of nine chest classifications. The broader-basis and
fixed-site models each change one evaluable classification per affected
placement, and the near-eye broader-basis longest-period fit fails its Hessian
check. Leave-one-site-out results are displayed for every metric and limit the
site-general interpretation.

## Diagnostic disposition

All 18 reported GAMs converge with positive Hessian minima. The maximum
absolute pooled consecutive-day residual lag-1 correlation is 0.229 near eye
and 0.154 at the chest. Four basis checks are flagged across the 18 fits and
are interpreted through the broader-basis sensitivity.

Estimated target/participant-smooth concurvity is approximately
0.9985–0.9988. Smooth-term p-values remain withheld. The Tweedie check for
time below 1 lx melEDI during sleep fails at both placements: four zeros are
observed, fewer than 0.0001 are expected, and none occurs in 100 pilot
simulations. The reader report therefore identifies the complementary chest
sleep low-light pattern as particularly weak evidence. No larger simulation
is proposed because it cannot repair the response-distribution mismatch.

## Reporting-policy disposition

- The preregistered hypothesis is quoted exactly.
- The first use of “gap-timing-unaware dataset” includes the accepted
  explanation and the primary dataset is subsequently named simply.
- Near-eye results are primary and chest results are complementary.
- Both placements show the fitted metric-value smooth beside its first
  derivative for all nine metrics.
- Figure captions and non-empty descriptive alternative text are present;
  final-size inspection found no clipping, title collision, unreadable text,
  or panel imbalance in the source figures or rendered tables.
- Every displayed figure links to CSV source rows and settings.
- No historical implementation, gate, or construction language appears in
  the reader-facing report.
- No inferential p-value is displayed; the reason for withholding smooth-term
  p-values is stated.

## Proposed coordinator-owned ledger entries

1. `H07-STAGE2-APPROVED` — decision `H07-003` approved
   `H07-S2R-001` through `H07-S2R-008` and authorized Stage 3.
2. `H07-STAGE3-READER` — standalone reader report rendered and verified;
   derivative-defined patterns reported for six of nine primary near-eye and
   seven of nine complementary chest metrics.
3. `H07-STAGE3-DIAGNOSTICS` — extreme participant-smooth concurvity, failed
   sleep low-light zero-mass check, model-form changes, and site influence
   retained as explicit limitations.
4. `H07-STAGE3-NO-PRODUCTION` — no production simulation or bootstrap is
   scientifically required for the accepted descriptive estimand.
5. `H07-STAGE3-AUTHOR-GATE` — Stage 3 ready for author review; Stage 4 remains
   unauthorized.

## Decision requested

Please approve or revise the following Stage 3 author gates:

- `H07-S3-001`: accept the reader-facing definition and six-of-nine near-eye /
  seven-of-nine chest conclusion;
- `H07-S3-002`: accept the exact samples, paired smooth/derivative figures,
  endpoint 95% intervals, and accessible source-data links;
- `H07-S3-003`: accept the diagnostic, sensitivity, model-form, and
  leave-one-site-out limitations as presented;
- `H07-S3-004`: accept the decision not to run production simulation or
  bootstrap computation;
- `H07-S3-005`: accept the reader terminology and prohibited-claim boundary;
  and
- `H07-S3-006`: authorize Stage 4 creation of
  `audit/hypotheses/H07/H07_analysis_preparation.qmd` under the accepted
  bounded-render rules.

No Stage 4 file should be created until these decisions are explicit.
