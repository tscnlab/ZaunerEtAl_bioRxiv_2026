# H06-D-G3 revised Stage 3 author gate

- Date: 2026-08-13
- Status: awaiting explicit author decision
- Controlling transition: H06-D-015 / CHG-133
- Revision authority: direct author requests in the H06_daily task

## Completed bounded revision

The standalone complementary report is now available at
`notebooks/hypotheses/H06_daily.html`. Its source is
`notebooks/hypotheses/H06_daily.qmd`.

The revision now does eight things requested by the author:

1. changed **Answer in brief** to a simple note callout with no icon;
2. exposed all ten primary FDR-supported predictor-by-site interaction blocks,
   including the equal-site contrast and all nine site deviations with
   pointwise 95% intervals;
3. reorganized the results so that the primary near-eye batch, complementary
   placement analyses, gap-timing-unaware sensitivity, exploratory mutually
   adjusted daily models, and exploratory temporal GAMM are separate;
4. added an exploratory common-sample daily analysis containing day type,
   activity, and previous-night sleep together; and
5. added the accepted 30-minute temporal GAMM and an explicit comparison with
   the selected main hourly H06 analysis;
6. uses the interaction model in the main-H06 comparison whenever the relevant
   global predictor-by-site interaction meets its FDR rule, and otherwise uses
   the additive common contrast; and
7. gives every site mention a filled dot in the submitted site colour, reports
   pointwise 95% CIs for sites compatible with the null as well as those
   excluding it, and distinguishes full fitted contrasts from interaction-only
   multipliers; and
8. decomposes Table 4 into an equal-site comparison/reference ratio and
   multiplicative site adjustment factors, and adds a faceted site-deviation
   figure with paired source data and alt text.

No accepted Stage 2 primary or gap model, estimate, interval, raw p-value,
FDR value, decision, diagnostic classification, L10 result, or MDER result was
changed. Main H06 was read only.

## Primary site interactions now reported

Ten global interaction blocks met their separate 15-slot FDR rule. Table 4 now
shows the equal-site comparison/reference ratio from each complete interaction
model. For these multiplicative outcomes, that is the geometric mean of the
nine full site-specific ratios. Each site entry is an adjustment factor equal
to the full site-specific ratio divided by the equal-site ratio. A factor below
1 indicates a lower ratio than the equal-site pattern and a factor above 1 a
higher ratio. Multiplying the equal-site ratio by the site factor recovers the
full site-specific ratio.

Across the 90 adjustment factors, 13 pointwise intervals were below 1, 11 were
above 1, and 66 included 1. These intervals are descriptive localizations after
a globally FDR-supported interaction. They are not separately multiplicity
adjusted and do not test one site against another. All site mentions retain
their submitted-colour filled dots. The new ten-panel forest plot shows the
same 90 factors and pointwise 95% CIs on a common log scale, with a paired
90-row source-data CSV and complete alt text.

For mean melEDI, the equal-site Free/Work ratio was 0.70 (95% CI 0.63 to
0.78). Delft was pointwise above that equal-site pattern, adjustment factor
1.36 (1.01 to 1.83), while Madrid, 0.71 (0.56 to 0.90), and Kumasi, 0.57
(0.43 to 0.76), were pointwise below it. The remaining six intervals included
1. The corresponding full Delft ratio is 0.70 × 1.36 = 0.95, apart from
rounding.

## Exploratory joint-context amendment

The common-sample association model contains fixed site, day type, daily
activity status, previous-night sleep duration, and the established
participant dependence structure. Each metric uses the same complete-case
rows for its predictor-specific comparator and joint model.

Site heterogeneity is evaluated one context block at a time while the other
two contexts remain additive. This lower-dimensional implementation retains
all three main context terms without conditioning each interaction on two
other high-dimensional interaction blocks.

The amendment contributes six separate exploratory 15-slot BH families. Slot
3 remains the named L10 result with missing p and q values. Fourteen metrics
are estimable per family. Activity was stable for all 14 estimable metrics.
Three sleep and four work/free estimates shifted by 1 to less than 2
common-sample standard errors. One work/free estimate, time below 1 lx melEDI
during sleep, reversed and shifted by more than 3 standard errors. These
stability classifications are limitations, not causal findings.

Mean melEDI remained lower on Free days after joint adjustment. The additive
association model gave a ratio of 0.75, 95% CI 0.68 to 0.82, exploratory FDR
q < 0.001. Because its site interaction was also supported, the comparison
table now displays the interaction model's equal-site full contrast, 0.73
(0.66 to 0.81), with full site-specific ratios from 0.44 to 1.00. Five
work/free interaction blocks remained conditionally FDR-supported. A sixth
numerical MDER block is shown only as descriptive because its accepted
heavy-tail and site-influence limitation remains.

## Temporal GAMM now reported

The report displays the accepted primary near-eye 30-minute GAMM from stored
artifacts. The response is `log10(Y + 0.1 lx)`, where `Y` is the 30-minute
arithmetic mean melEDI. The model contains the cyclic global clock smooth,
noncyclic factor and site departures, separate within-participant and
between-participant sleep functions, participant and participant-day terms,
and its frame-specific AR(1) working correction.

All four whole-function tests met their exploratory four-test FDR rule. The
Free/Work ratio ranged from 0.20 to 1.84, Active/Sedentary from 0.96 to 1.62,
within-participant sleep from 0.76 to 1.05, and between-participant sleep from
0.61 to 0.97. The figure and summaries use pointwise intervals only. The
stored GAMM diagnostic limitations, including the unavailable paired-chest
residual extraction and absence of deletion influence analysis, remain
visible.

## Comparison with main H06

The report states that the selected hourly H06 and complementary daily metric
analysis are not numerically interchangeable. Hourly H06 weights supported
participant-hours and jointly models the hourly outcome. H06_daily gives each
admissible participant-day one row for each metric. The table now selects an
interaction-model contrast whenever the corresponding global heterogeneity
test is supported. Thus the displayed Free/Work equal-site full contrasts are
1.15 (95% CI 0.93 to 1.44) for main hourly H06, 0.70 (0.63 to 0.78) for the
predictor-specific daily mean, and 0.73 (0.66 to 0.81) for the mutually
adjusted daily mean. The underlying site-specific ranges are 0.53 to 2.44,
0.40 to 0.95, and 0.44 to 1.00, respectively. The daily predictor-specific
activity interaction is also supported and is displayed as an equal-site full
contrast of 1.22 (1.08 to 1.39), rather than the additive 1.16 contrast. All
other mean-melEDI comparison cells use their additive models. This is
presented as an estimand and weighting difference, not a failed replication.

## Verification

- R 4.6.1 joint-context test: PASS, covering 14 estimable metrics, six fixed
  15-slot families, 90 tests, 378 conditional site contrasts, and all 14
  visual residual classifications.
- R 4.6.1 revised reader test: PASS, covering unchanged accepted inference,
  ten primary site blocks, four temporal estimands, three main-H06 comparison
  rows, 90 site-to-equal-site adjustments, 14 tables, and five paired-source
  accessible figures.
- Rendered-DOM QA: 17 PASS and one disclosed limitation. The local in-app
  browser blocked automated `file://` inspection. No workaround was used.
- Original-resolution figure QA: five of five PASS. The new site-deviation
  figure was inspected at original resolution for all ten strips, 90 points
  and intervals, site labels, submitted colours, null lines, and caption
  wrapping.

## Author decisions requested

Please decide whether to:

1. accept the revised note callout and batch-separated table organization;
2. accept the primary global interaction reporting as an equal-site contrast
   plus site adjustment factors, including submitted-colour dots, pointwise
   CIs, and the new site-deviation figure;
3. accept the exploratory joint-context implementation, six separate BH
   families, and all stated covariate-stability limitations;
4. accept the temporal GAMM presentation with pointwise intervals and its
   diagnostic limitations;
5. accept the comparison with the selected main hourly H06 analysis, using
   interaction-model contrasts wherever global site heterogeneity is
   supported; and
6. close H06-D-G3 or request another bounded reader-report revision.

Stage 4 remains a separate lean preparation and provenance companion. It is
not authorized until this Stage 3 gate is explicitly accepted. Website or
shared configuration changes, main-H06 changes, manuscript edits, further
scientific computation, commit, and push remain outside scope.
