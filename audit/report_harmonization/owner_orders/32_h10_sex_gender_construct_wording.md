# Deferred H10 source-only order: biological sex and gender wording

Date prepared: 2026-08-14  
Intended owner task: `019fdc1b-b77b-7972-aed0-784da328e115`  
Finding: `RH-REP-001`  
Status: **prepared and held; do not dispatch before the H10 serial safe point**

## Purpose and serial boundary

Correct a confirmed reader-reporting defect without changing the accepted H10
analysis. Biological sex and gender were recorded as separate variables. The
accepted analyses used biological sex, coded Female or Male. Gender was not
analysed.

This order must not interrupt H01 or release H10 early. Before eventual
dispatch, read the then-current H10 handoff completely, verify that the H10
task remains the scientific/report owner, and recheck all source and test
identities. Any drift requires a refreshed order rather than assumption.

Planning-time identities are:

| Item | SHA-256 |
|---|---|
| `notebooks/hypotheses/H10.qmd` | `3c8d6891854a298e4fad69d1d7499c4d45a7d7c522f50e920b6b6aa1e4abac3f` |
| `audit/hypotheses/H10/H10_analysis_preparation.qmd` | `c46d6ae965daba94750220e6eeaf95aa01b5cff4bc929117848f72090b7583f1` |
| `tests/hypotheses/H10/test_h10_stage3_reader_report.R` | `9f683babf2fd036bf33acf71ce5ef694d4a78a2893b5c6d4b54df9b9c01a1c3c` |
| `tests/hypotheses/H10/test_h10_preparation_report.R` | `836a6b48250946375c512895d05a50c77e6472ccccf987510675a33235cdcb22` |

These are planning references only. Record exact accepted dispatch pins when
the order is released.

## Controlling evidence

The coordinator's R 4.6.1 read-only audit established:

- the normalized demographics RDS at SHA-256
  `a11d0ff6615b51dbaa0be8c0790c1ea550750d9f1d4d7e8893609803f269dadf`
  has separate, nonidentical `sex` and `gender` columns for 191 records;
- the 68 accepted H10 model frames at SHA-256
  `2d1c9119409c908f6890062c46827698aff19b12c3bcc93ce15cb37b28b8a6e7`
  contain `biological_sex` and no `gender` model term;
- the H10 model manifest at SHA-256
  `9ce9c4153d38122398c259ed9bec013ac91afd99a8f90b70a919390321c3baae`
  contains biological-sex formulas and no gender term; and
- the accepted Stage 1 source at SHA-256
  `cc3faa888ba932a7346e89463435b55608529045ad33111be6a5b57a6480cac4`
  records the same construct boundary.

The writer request is
`audit/handoffs/nature_health_manuscript_shared_change_request.md` at
`202330fbc562a8012be449d1d16a2921beb52d8f5b4c0416e9a0bfc4fc332f1a`.
The harmonizer's confirmed defect record is
`audit/report_harmonization/reporting_defects.md`.

## Exact result-source corrections

Edit only `notebooks/hypotheses/H10.qmd` at these two locations.

1. In the opening scientific-question paragraph, replace only the false
   statement that gender identity was neither measured nor inferred. Preserve
   the quoted preregistered hypothesis and the surrounding melEDI explanation.
   The corrected logical sequence must read:

   > Biological sex and gender were recorded as separate variables; the
   > accepted analyses used biological sex, coded Female or Male; gender was
   > not analysed. The confirmatory question evaluated here is whether age or
   > measured biological sex is associated with personal light-exposure
   > metrics.

2. Change only the caption of `fig-h10-sex-associations` to:

   ```text
   Site-adjusted Female-minus-Male contrasts for measured biological sex;
   gender was recorded separately but not analysed.
   ```

Preserve the figure path, source data, panel content, estimates, intervals,
FDR decisions, figure label, alt text, dimensions, and every other caption.

Keep this current limitation byte-for-byte unless only line wrapping changes:

> Biological sex was the construct actually recorded, and the analysis
> provides no inference about gender identity.

Do not replace biological-sex terminology with gender, do not imply that the
constructs are interchangeable, and do not extend the fitted associations to
gender identity.

## Exact companion corrections

Edit only `audit/hypotheses/H10/H10_analysis_preparation.qmd` at these two
locations.

1. Replace the false statement near the preregistered hypothesis with:

   > Biological sex and gender were recorded as separate variables. The
   > accepted analyses used biological sex, coded Female or Male; gender was
   > not analysed.

   Preserve the following age, estimand, interaction, and site statements.

2. Replace only “No gender field or unsupported predictor entered a model”
   with:

   > The gender variable and unsupported predictors did not enter any model.

Preserve all input identities, sample construction, formulas, model-entry
fields, site cells, figure/table endpoints, provenance qualifications,
commands, manifests, and scientific boundaries.

## Focused test reconciliation

Edit only the dependent construct-wording assertions in:

- `tests/hypotheses/H10/test_h10_stage3_reader_report.R`;
- `tests/hypotheses/H10/test_h10_preparation_report.R`.

For the result-source test, replace the stale required source phrase
`Gender identity was neither substituted` with positive source assertions for
all of these meanings:

- biological sex and gender were recorded as separate variables;
- the accepted analyses used biological sex, coded Female or Male;
- gender was not analysed; and
- the analysis provides no inference about gender identity.

For the companion-source test, replace the stale
`gender was neither substituted` assertion with the same positive construct
boundary and an assertion that the gender variable did not enter any model.

In both tests, add source-side prohibitions for the false phrases
`neither measured nor inferred` and `No gender field`. Do not require the
unrendered corrected wording in the existing HTML during this source-only
pass. Preserve every analytical value, formula, frame, sample, artifact,
manifest, figure/table, link, site, environment, no-execution, and rendered-
HTML gate outside these construct assertions. If a full existing test exposes
an unrelated stale assertion, stop and report it rather than broadening this
order.

## Scientific and execution boundary

This is a source/test wording correction only. Do not edit data, normalized
demographics, model frames, formulas, fits, samples, estimates, intervals,
p-values, diagnostics, multiplicity decisions, figure data, scientific
claims, artifacts, manifests, rendered HTML, shared configuration, central
ledgers, lockfiles, or manuscript files. Do not run a model, prediction,
simulation, bootstrap, builder, artifact regeneration, Quarto render, commit,
or push.

## Required source-only return

Use R 4.6.1 and return:

1. exact pre-edit and post-edit SHA-256 identities and byte counts for the two
   QMDs and two tests;
2. a zero-context line map and exact diff proving only the four named reader
   passages and dependent test assertions changed;
3. reverse-substitution proof reproducing every dispatch identity;
4. R parse success for every R chunk in both QMDs and both tests, without
   executing report chunks;
5. positive source checks for the complete corrected construct boundary and
   negative checks for both false phrases;
6. exact preservation of the result limitation that the analysis provides no
   inference about gender identity;
7. identical sets of QMD chunk labels, table and figure identifiers, formulas,
   artifact references, source-data links, numeric tokens, and executable R
   code outside the approved display string;
8. hashes proving the three controlling evidence artifacts, accepted Stage 1
   source, model outputs, result figures/tables, existing HTML, profile, and
   all non-owned files remain unchanged;
9. scoped ownership and `git diff --check` evidence; and
10. explicit confirmation that no R analysis, Quarto render, artifact
    regeneration, commit, or push occurred.

Stop on any scientific mismatch or scope drift. Return the source-only seal
for independent harmonizer acceptance. H10 remains unrendered until its later
REPORT-017 serial release.
