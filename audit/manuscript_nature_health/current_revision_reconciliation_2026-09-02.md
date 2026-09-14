# Nature Health current-revision reconciliation

Date: 2026-09-02  
Status: source-only editorial checkpoint; strict validation passed; no manuscript render run  
Scope: manuscript-owned files only

Current identities after all SCI-01 through SCI-14 dispositions, the H06 eligibility sensitivity and Brown Order 65c integrations:

- main QMD: `a723b037b5b03b439486cbe0bf180af718e45036ffab69e29d6dc1166b89e334`
- Supplementary Information QMD: `f438f912da5287e4bd687255b7d17661ff91593aee4cce975e4a23c4ae34f1b0`
- manuscript display CSS: `5974136901a8325e831e932a3999382532acfcf94508f428b23bc8f5de3ffc98`
- Brown participant-profile SVG derivative: `200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653`
- current validation script: `a8cf0585508396b5c41ffb7d102c6288df048a44373ec2b82ace07b557a0cdb2`

## Implemented without changing accepted scientific meaning

- Merged `bibliography.bib`, `references_additional.bib`, and the three verified additions into `manuscript/R0_NatHealth/references_merged.bib`. The generated bibliography contains 114 unique keys; 91 are cited in the current manuscript and Supplementary Information.
- Added a calibrated non-communicable-disease and exposome bridge using Vineis (2018) and Vermeulen et al. (2020).
- Added the verified Gemici et al. (2026) ActLumus field-validation preprint without introducing unsupported 10 lx or 1 lx performance breakpoints.
- Made the global-coverage limitation explicit and positioned the harmonised protocol as a framework that additional sites can adopt.
- Replaced Brown reader-facing `state-period` wording with `recommendation-window period` in the manuscript-owned Table 2 derivative and its caption.
- Harmonised the three Table 3 level-metric definitions while preserving every numeric cell.
- Removed the complementary daily H06 analysis from the manuscript and Supplementary Information and added the accepted site-specific participant-hour interaction figure.
- Reordered supplementary displays to follow the main narrative: study support and definitions, recommendation adherence, daily architecture, geography and photoperiod, immediate environments and routines, hourly routines, person-level findings, and measurement-position boundaries.
- Standardised included `gt` table body and header text to 12 px, preserved wider horizontal layouts with scrolling, expanded the full metric-dictionary stub, reduced Supplementary Figure S3 display size, and left-aligned the main Table 1 caption.
- Added direct main-text links to the relevant supplementary displays.
- Retained the complete CRediT contribution-role list from the accepted author information.
- Lowercased recommendation-window, day-type and activity labels in running prose except where sentence position or ordinary grammar requires capitalization. Plot and table labels were left unchanged as requested.
- Replaced the directional skew claim for sleep-category exposure with the accepted description of many low or zero observations and occasional high stray-light readings.
- Presented the fitted sleep-category mean and the pooled-minute sleep adherence as distinct, complementary summaries rather than allowing either estimand to negate the other.
- Retained the author's current SCI-14 conclusion, which describes the paper as a nine-site reference and uses non-causal language for the temporal, contextual and positional information it provides.
- Recast the H03 and H04 Shapley comparisons as allocations of model-fit credit, including the author-requested 28.6% and 36.9% shares within the paired time-plus-context allocations.
- Restored the accepted H03 exact-zero model-check qualification after it was inadvertently omitted during paragraph revision.
- Replaced the cross-analysis strict ranking with the author-approved qualitative synthesis in P-D01.
- Added the approved model-specific comparison showing that recorded light source and activity were more informative than participant-specific patterns while explicitly declining a causal explanation of the cross-window adherence association.
- Defined the chest position as a separate environmental measurement evaluated as a potential ocular proxy in paired common-sample analyses, without assuming equivalence.
- Recast the exploratory cross-window paragraph so unresolved temporal dependence withholds the within-participant claim, while the accepted inverse between-participant associations retain their direction and non-causal interpretation.
- Completed a final meaning-preserving editorial condensation of the Introduction, Results and Discussion. The pass removed repeated framing and estimand reminders, tightened transitions and parallel lists, and retained every protected scientific token and author-approved SCI sentence.

## Protected-content checks

- R version: 4.6.1.
- The abstract contains 146 words. The Introduction, Results and Discussion contain 4,496 words after excluding display captions, within the author's 4,500-word ceiling.
- The current validation resolves all 91 cited keys against the 114-entry merged bibliography.
- All non-pending internal links, includes and image paths resolve.
- H06_daily and `main hourly` wording is absent from the current sources.
- Table 2 retains all 155 ordered protected numeric tokens from its accepted planning fragment.
- Table 3 retains all 1,510 ordered protected numeric tokens from its accepted harmonizer fragment.
- The 537 ordered scientific numeric tokens outside the explicitly revised SCI-03, SCI-06, SCI-07 and SCI-11 paragraphs match the author-edited source snapshot after excluding reference labels and the documented approved additions. The revised paragraphs have separate exact wording and numeric assertions.
- The academic-writing protected-token comparison from the final author-edited baseline (`dad0e046be2f683d438c5b1d31dec7460b51ffd1f5e138f0752550c15d048fcf`) to the condensed source found no additions, removals or sequence changes in protected numbers, units, citations, cross-references or abbreviations.

## Subsequent accepted scientific/display integrations

1. Brown Order 65c was independently accepted under `audit/report_harmonization/report018_brown_order65c_acceptance.md` (SHA-256 `b61761f18297304d1f7f04a454d17725f2744d0990819238c42d13e5fb954793`). The accepted source SVG and the manuscript-owned derivative are byte-identical at SHA-256 `200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653` and 108,600 bytes. It is integrated as Supplementary Figure S6 and remains anonymous, descriptive and non-ranking.
2. The author-accepted H06 employment-eligibility sensitivity is integrated in Results and Methods. It is near-eye only, excludes participants recorded as not employed or marginally employed, retains students and trainees, and does not apply an age-above-65 exclusion.
3. The source-only editorial pass is complete. No render has been run because the coordinator's shared navigation build remains under serial hold; the manuscript-only render and visual QA remain pending that release.

## Scientific wording decisions

The author directly revised several passages. The following issues are therefore held rather than silently rewritten.

Author dispositions received after this checkpoint:

- `SCI-01` approved and implemented: the coverage sensitivity now states that it required at least 80% valid data coverage.
- `SCI-02` approved and implemented using the author's exact response-scale comparison wording.
- `SCI-08` approved and implemented using a zero-heavy, occasional-high-value description rather than a directional skew label.
- `SCI-10` approved and implemented by presenting the fitted sleep-category mean and pooled-minute adherence together as distinct estimands.
- `SCI-13` resolved through the accepted anonymous, non-ranking participant-profile display.
- `SCI-14` resolved from the author's newly saved P-D09 wording. The earlier candidate text is no longer current.
- `SCI-04` and `SCI-05` closed by explicit author direction to retain the current wording; the recorded interpretive qualifications remain available for final review.
- `SCI-06` and `SCI-07` integrated with model-fit-credit terminology. The accepted H03 zero-mass mismatch was retained.
- `SCI-09`, `SCI-11` and `SCI-12` approved and integrated.
- `SCI-03` approved and integrated. The within-participant estimates are reported without a day-level claim, and the between-participant direction is stated as lower pre-sleep and sleep adherence, consistent with higher evening and nighttime light exposure.

| ID | Current scientific issue | Reason for holding | Proposed direction |
|---|---|---|---|
| SCI-01 | Resolved. P-R04B had said the Brown sensitivity used `≤80% coverage`. | The accepted sensitivity required at least 80% coverage. | Implemented as `required at least 80% valid data coverage`.
| SCI-02 | Resolved. P-R04C had described site as about twice as important as participants. | Multiplying site's 4.7556% Shapley weight by the 58.437% fixed-predictor share gives 2.779 response-scale percentage points, on the same denominator as the 2.190-point participant-intercept increment. | Implemented the author's exact comparison: 2.8 points for site, 2.2 for the participant intercept and 0.7 for day type; site is about 1.3 times the participant increment and about four times the day-type allocation.
| SCI-03 | Resolved. | P-R04D reports the within-participant estimates descriptively, states that unresolved temporal dependence precludes a day-level claim, and preserves the accepted inverse between-participant associations. | Implemented with the author's explicit approval.
| SCI-04 | Closed by author decision. P-R09 and P-R09A retain the current cross-model relational wording. | The differing supported metric subsets remain a qualification for final interpretation. | No source change requested.
| SCI-05 | Closed by author decision. P-R09B and P-D03 retain the current photoperiod wording. | The derivative-defined result and observational boundary remain documented elsewhere in the paragraph. | No source change requested.
| SCI-06 | Resolved. | The revised paragraph distinguishes the robust population-mean analysis, descriptive mixed model and exploratory time-of-day decomposition. Residual correlation and exact-zero mismatch remain explicit. | Implemented with exact model-fit-credit language and the 28.6% combined-component share.
| SCI-07 | Resolved. | The revised wording describes model-fit allocation rather than partitioning an activity effect. | Implemented with the 36.9% combined-component share.
| SCI-08 | Resolved. P-R11 had called a stray-light-sensitive category `left-skewed`. | Accepted H04 documentation instead supports a zero-heavy distribution with occasional high stray-light readings. | Implemented without a directional skew label.
| SCI-09 | Resolved. | P-D01 now synthesises the model-specific patterns qualitatively and explicitly declines a single quantitative ranking. | Implemented from the author's suggested synthesis.
| SCI-10 | Resolved. P-D02 had said an above-limit fitted sleep mean `is not an issue overall` because adherence is high. | Mean exposure and the percentage of minutes within the upper limit are different estimands; one does not invalidate the other. | Implemented by presenting the elevated mean and 87.7% pooled-minute adherence together as complementary distributional summaries.
| SCI-11 | Resolved. | P-D02B now says that light source and activity received more in-sample model-fit credit than participant-specific patterns, while stating that this is not a causal explanation for the adherence association. | Implemented with the author's requested causal boundary.
| SCI-12 | Resolved. | P-M04 now defines chest as a separate environmental measurement evaluated, rather than assumed, as a potential ocular proxy. | Implemented without pooling, equivalence or universal-correction language.
| SCI-13 | Resolved through accepted Brown Order 65c. The requested participant raincloud had been described as a ranking. | The three recommendation windows use different thresholds and therefore do not form a common performance scale. The accepted display is an anonymous descriptive profile only. | Implemented with connected participant profiles and an explicit statement that horizontal displacement does not rank or identify participants.
| SCI-14 | Resolved from the author's newly saved P-D09. | The current conclusion calls the paper a nine-site reference, identifies information for future cohorts and avoids a causal `determinants` claim. | Retain the newly saved wording unless the author requests a later editorial change.

All SCI-01 through SCI-14 dispositions are now closed. Any later meaning-changing revision requires a new explicit author decision.
