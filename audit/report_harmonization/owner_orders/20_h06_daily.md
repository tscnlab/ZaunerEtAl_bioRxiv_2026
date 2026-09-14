# REPORT-014 source-only order 20: complementary H06 daily report pair

Date: 2026-08-13

Owner task: `019fec6a-20d3-7710-ab9b-a035e0874182`

## Dispatch identities and scope

The author-accepted H06 daily baseline is sealed at commit
`442ddd1b592374440f1446c26234c5d6e12cce92`.

Edit only:

1. `notebooks/hypotheses/H06_daily.qmd`
   (`0318fd6cf874380631296d35095486b9de7f987a9779e4dc5d59c5a635a8c3dc`)
2. `audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`
   (`fdfe94cf96e16ecfff3455c3e2427bd94c6419ee62350211a724821870058c0e`)

This is a source-only, display-only harmonization pass. Do not render either
page, run an R chunk, execute a builder, fit or refit a model, predict,
simulate, bootstrap, rerun a sensitivity or Shapley analysis, regenerate an
asset, edit a stored output, or change shared configuration. Keep H06 daily
outside the active REPORT-017 render queue. Do not commit or push this
harmonization pass.

The selected hourly H06 analysis remains the main H06 result. The daily report
is complementary. Preserve this hierarchy everywhere, and do not reopen or
edit either main-hourly H06 source.

## Required result-report changes

Keep the accepted scientific question, Answer in brief, estimates, intervals,
samples, FDR decisions, diagnostic qualifications, sensitivities, figures,
tables, source data, and limitations unchanged.

Apply these reader-facing changes only:

1. Add a reciprocal dynamic source link near the opening reader guidance:
   `../../audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd`.
   Retain the existing dynamic link to the selected main hourly H06 report.
2. State plainly at first use that the selected hourly H06 analysis is the
   main H06 result and that this daily-metric analysis is complementary.
3. Replace visible `equal-site` wording with `site-average estimate`,
   `site-average ratio`, or `site-average contrast`, as appropriate. At first
   use, explain that this is an average across sites that gives every site
   equal weight. Internal object and column names may remain unchanged in
   code.
4. Replace visible `heterogeneity` shorthand with `predictor-by-site
   interaction` or `variation in the association across sites`. At first use,
   explain that the association is allowed to differ by study site. Preserve
   technical object names in code and every accepted test result.
5. Replace `submitted site colours` with reader language such as `consistent
   study-site colors`. State that color identifies site and does not encode
   significance. Use the project spelling convention consistently within the
   page.
6. Give every literal study-site name its country code, using
   `config/site_display_registry.csv`: Borås (SE), Delft (NL), Dortmund (DE),
   Tübingen (DE), Munich (DE), Madrid (ES), Izmir (TR), San José (CR), and
   Kumasi (GH). Apply the same rule to prose, captions, alt text, and
   visible table labels. Statically inspect the stored PNGs and return a baked
   label refresh list if any site name lacks its code. Do not regenerate a PNG
   in this order.
7. Introduce the exploratory method as a `nonlinear generalized additive
   mixed model (GAMM) analysis`, explained as allowing context associations to
   vary smoothly over clock time while accounting for repeated measurements.
   `GAMM` is acceptable thereafter. Keep `mgcv::bam()` and engine settings in
   technical detail rather than leading the reader section.
8. At first use, explain the working first-order autoregressive structure as
   allowing adjacent residuals within a participant-day to be correlated,
   then use `AR(1)` thereafter.
9. Use `false-discovery-rate (FDR) adjustment` at first use and `FDR`
   thereafter. Do not show `BH` in prose, captions, alt text, or table output.
   The full Benjamini-Hochberg method name may remain once in subordinate
   reproducibility detail. Internal `*_bh_*` names may remain in code.
10. Explain the response transformation and the reported or back-transformed
    quantity, including the reader-facing unit, before using transformed-scale
    shorthand. Preserve the exact accepted transformation and all values.
11. Explain `pointwise 95% confidence interval (95% CI)` at first use and make
    clear that it is not a simultaneous band. Use `95% CI` thereafter.
12. Explain a participant random intercept, if it remains in the main reader
    flow, as allowing each participant a different baseline. Explain any
    common-sample label before abbreviating it, using the exact participants
    and participant-days shared by the compared analyses.
13. Keep `model checks` as the reader-facing umbrella term. `Model
    diagnostics` may appear in parentheses at first use where technically
    useful.
14. Add a compact glossary callout only because this page uses several of the
    recurring specialist concepts above. Keep it short and place it after the
    analysis overview, before the primary results. Do not duplicate definitions
    throughout the report.
15. Retain the exact dynamic preregistration links to DEV-015, DEV-030,
    DEV-031, and DEV-032. Every deviation statement must remain linked to its
    exact entry in `../preregistration_deviations.qmd#<lower-case-id>`.

Do not substantially restructure the accepted result narrative. The current
order is an approved H06-daily-specific departure: question and Answer in
brief, data and analysis, primary near-eye result, predictor-by-site
interactions, complementary placement evidence, gap sensitivity, exploratory
daily and clock-time analyses, comparison with main H06, model checks and
limitations, then preregistration context and source data.

## Required preparation and provenance changes

1. Replace the hard-coded result link
   `../../../notebooks/hypotheses/H06_daily.html` with the dynamic source link
   `../../../notebooks/hypotheses/H06_daily.qmd`. Keep the report and companion
   reciprocal.
2. Preserve the accepted analysis-path diagram and the present scientific and
   provenance hierarchy. Keep reader explanation first and technical
   reproduction details subordinate.
3. Apply the same approved vocabulary and first-use explanations as the result
   report. In particular, repair visible `equal-site`, `heterogeneity`, `BH`,
   GAMM, `bam()`, AR(1), transformation, confidence-interval, random-effect,
   common-sample, and model-check language. Do not rename executable objects,
   variables, formulas, or stored artifacts merely to change reader wording.
4. Convert visible table headings and notes such as `Heterogeneity` and
   `Predictor-by-site heterogeneity` to `Predictor-by-site interaction` through
   display labels only. Do not change the backing data or formula strings.
5. Apply country-coded site names in all visible prose, captions, alt text, and
   table output, using the registry. Leave paths and code identifiers alone.
6. Explain `symlog` at first reader-facing use as a symmetric logarithmic
   display scale that retains zero and uses a linear region near zero. Preserve
   its accepted base-10 and 1 lx threshold definition and do not change a
   model response or plotted value.
7. Keep detailed formulas, engine settings, file paths, hashes, execution order,
   and stored-output trace in the technical provenance portion. Remove task,
   gate, production-stage, submitted-version, and artifact-construction
   vocabulary only where it leaks into the main reader flow and is not needed
   for reproducibility.

## Complementary output roles for the first adjustment

No H06 daily output becomes the main H06 output. The provisional lead
complementary outputs are:

- Figure: `fig-h06-daily-fdr-overview`, sourced from
  `artifacts/10_figures/H06_daily/H06_daily_stage3_fdr_overview.png`.
- Table: `tbl-h06-daily-primary-matrix`, built from the accepted stored Stage 3
  summary object already used by the report.

Keep the other four figures and thirteen result tables as complementary or
supplementary candidates. For this source-only pass, limit changes to captions,
alt text, site labels, term definitions, table title and footnote hierarchy,
FDR notation, and the role statement. Do not redesign, recompute, or regenerate
an output. Return any baked-label or final-size display issue for the later
serial render and author visual review. The shortlist and appearance remain
provisional.

## Evidence to return

Return one bounded handoff containing:

- pre-edit and post-edit SHA-256 for both QMDs, with the dispatch hashes above
  reproduced before editing;
- an exact diff hunk map and confirmation that only the two owned QMDs changed;
- byte-identical executable R-chunk source where possible, or a precise list of
  display-label-only R changes with proof that prepared objects, formulas,
  values, row order, and scientific computations are unchanged;
- unchanged sets of chunk labels, figure and table identifiers, artifact
  references, source-data links, formulas, and accepted numeric tokens;
- static R syntax parsing without execution;
- proof that every internal page link targets a relative `.qmd` source and that
  all targets and anchors resolve;
- exact checks for the four deviation links, reciprocal result/companion links,
  main-hourly H06 link, country-coded literal site names, zero reader-facing
  `BH`, zero reader-facing `equal-site`, zero unexplained `heterogeneity`, zero
  hard-coded internal `.html`, `_build`, `file://`, or absolute local paths;
- the stored-PNG baked-label refresh list, which may be empty only after static
  visual inspection;
- `git diff --check` for the two QMDs; and
- explicit confirmation that no render, R execution, scientific recomputation,
  artifact regeneration, shared edit, commit, or push occurred.

Stop and return a scoped scientific discrepancy instead of resolving it
editorially if any requested wording would change an estimate, estimand,
sample, model, multiplicity decision, diagnostic qualification, sensitivity,
or claim.
